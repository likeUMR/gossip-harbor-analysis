AdventureActivityModel = setmetatable({}, BaseActivityModel)
AdventureActivityModel.__index = AdventureActivityModel
AdventureActivityEventType = {
  StateChanged = 1,
  BundleRefresh = 2,
  RefreshGiftRedPoint = 3
}
AdventureActivityModel.GenItemFromType = {Energy = 1, Order = 2}
AdventureActivityModel.PopUnlockWindowLevel = 6
local DBKeys = {
  CurrentMergeLevel = "CurrentMergeLevel",
  InitialItemGiven = "InitialItemGiven",
  GenerateRoundTotalCountKey = "generateRoundTotalCount",
  GenerateRoundValidCountKey = "generateRoundValidCount",
  EverFulledKey = "EverFulled",
  PopEndWindow = "PopEndWindow"
}

function AdventureActivityModel:Init(activityType, activityDataTable, itemDataTable, itemLayerDataTable, itemCacheDataTable, boardDataTable)
  self.m_itemDataTable = itemDataTable
  self.m_itemLayerDataTable = itemLayerDataTable
  self.m_itemCacheDataTable = itemCacheDataTable
  self.m_boardDataTable = boardDataTable
  self.m_activityDefinition = AdventureActivityDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
  EventDispatcher.AddListener(EEventType.ItemTransform, self, self._OnItemTransform)
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
end

function AdventureActivityModel:GetDefinition()
  return self.m_activityDefinition
end

function AdventureActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
end

function AdventureActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function AdventureActivityModel:_LoadOtherServerConfig(config)
  self.arrMergeLine = {}
  if not Table.IsEmpty(config.adventure_items) then
    local cnt = 0
    for _, data in pairs(config.adventure_items) do
      self.arrMergeLine[data.index] = data.item
      cnt = cnt + 1
    end
    if cnt ~= #self.arrMergeLine then
      Log.Error("AdventureActivityModel config error: adventure_items not continuous")
    end
  end
  self.m_genByCostEnergyCfg = nil
  if not Table.IsEmpty(config.adventure_energy_chance) and config.adventure_energy_chance[1] then
    local cfg = config.adventure_energy_chance[1]
    Log.Assert(cfg.chance[1] and cfg.chance[2] and cfg.item, "AdventureActivityModel config error: adventure_energy_chance")
    self.m_genByCostEnergyCfg = {}
    self.m_genByCostEnergyCfg.chance = cfg.chance[1]
    self.m_genByCostEnergyCfg.genNum = cfg.chance[2]
    self.m_genByCostEnergyCfg.items = Table.DeepCopy(cfg.item, true)
  end
  self.m_genByFinishOrderCfg = nil
  self.m_genByFinishOrderUseDiff = false
  if not Table.IsEmpty(config.adventure_order_score) then
    self.m_genByFinishOrderCfg = {}
    local isUseDiff = false
    for _, cfg in pairs(config.adventure_order_score) do
      table.insert(self.m_genByFinishOrderCfg, Table.DeepCopy(cfg, true))
      if not isUseDiff and IsNumber(cfg.diff_score_min) then
        isUseDiff = true
      end
    end
    self.m_genByFinishOrderUseDiff = isUseDiff
    if isUseDiff then
      table.sort(self.m_genByFinishOrderCfg, function(a, b)
        return a.diff_score_min < b.diff_score_min
      end)
    else
      table.sort(self.m_genByFinishOrderCfg, function(a, b)
        return a.gold_min < b.gold_min
      end)
    end
  end
  self.m_illustratedBook = config.eventBookContents
  self.m_eventOrderScoreConfig = config.eventOrderScore
end

function AdventureActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  if self.m_boardModel ~= nil then
    self.m_boardModel:DropData(self.m_lateInit)
    self.m_boardModel = nil
  else
    self.m_itemDataTable:Drop()
    self.m_itemLayerDataTable:Drop()
    self.m_itemCacheDataTable:Drop()
    self.m_boardDataTable:Drop()
  end
end

function AdventureActivityModel:_OnStateChanged()
  local state = self:GetState(false)
  if state == ActivityState.Started or state == ActivityState.Ended then
    if self.m_boardModel == nil then
      local energyConfig
      if self.m_eventOrderScoreConfig ~= nil then
        energyConfig = require("Data.Config." .. self.m_type .. "BoostUnlock")
      end
      local args = {
        itemDataTable = self.m_itemDataTable,
        itemLayerDataTable = self.m_itemLayerDataTable,
        itemCacheDataTable = self.m_itemCacheDataTable,
        boardDataTable = self.m_boardDataTable,
        boardInitFileName = self.m_activityDefinition.BoardModelConfigName,
        itemIllustrated = self.m_illustratedBook,
        activityDBTable = self.m_dbTable,
        activityType = self:GetType(),
        obstacleConfigFileName = self.m_activityDefinition.BoardObstacleConfigName,
        listEnergyMultiUnlockConfig = energyConfig,
        fogConfigFileName = self.m_activityDefinition.FogConfigName
      }
      self.m_boardModel = AdventureActivityBoardModel.Create(args)
      self:InitUpdateLevel()
    end
    if state == ActivityState.Started then
      self:_TryGiveInitialItems()
    end
  else
    self.m_boardModel = nil
  end
  local state = self:GetState(false)
  if state ~= ActivityState.Released and self.m_eventOrderScoreConfig ~= nil then
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty, self, self.m_eventOrderScoreConfig, EPropertyType.AdventureEnergy, function(num, scene)
      self.m_boardModel:GetEnergyModel():AddCurEnergy(num, scene)
    end, function()
      return self:GetState() == ActivityState.Started
    end, function()
      local mainWindow = GM.UIManager:GetOpenedViewByName(self.m_activityDefinition.MainWindowPrefabName)
      if mainWindow ~= nil then
        local boardView = GM.ModeViewController:GetAdventureActivityBoardView()
        local _, pos = boardView:GetBoardEntryBtnAndPos()
        local energyView = boardView:GetEnergyViewInfo()
        return energyView, pos
      end
    end, true)
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.GetRewardIconNameAndNativeSize, self, {
      [EPropertyType.AdventureEnergy] = {
        GetBigIconFunc = function()
          return GM.ItemDataModel:GetSpriteName(self:GetItemCodeByLevel(1)), true
        end,
        GetIconFunc = function()
          return GM.ItemDataModel:GetSpriteName(self:GetItemCodeByLevel(1)), true
        end
      }
    })
  end
  GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.ConvertDynamicReward, self, {
    [EPropertyType.AdventureEnergy] = function(reward, needBI)
      if GM.ActivityManager:GetStartedAdventure() == nil or not GM.ActivityManager:GetStartedAdventure():GetBoardModel():IsEnergyModuleOpen() then
        local newReward = {}
        newReward[PROPERTY_TYPE] = EPropertyType.Energy
        newReward[PROPERTY_COUNT] = reward[PROPERTY_COUNT]
        return newReward
      end
      return reward
    end
  })
  self.event:Call(AdventureActivityEventType.StateChanged)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  if self.m_lateInit then
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  end
end

function AdventureActivityModel:_OnItemSpread(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:_TryGenerateItemByEnergy(message.Source, message.EnergyBoostRatio)
  end
end

function AdventureActivityModel:_OnItemTransform(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:_TryGenerateItemByEnergy(message.Source, 0)
  end
end

function AdventureActivityModel:_OnOrderFinished(msg)
  local item = self:GetGenerateItemByOrder(msg.order)
  if item == nil then
    return
  end
  local list = {}
  for i = 1, item[PROPERTY_COUNT] do
    table.insert(list, item[PROPERTY_TYPE])
  end
  self:CacheItems(list)
  GM.BIManager:LogAcquire(item[PROPERTY_TYPE], item[PROPERTY_COUNT], self.m_activityDefinition.AcquireItemByOrderBIType, true)
  local message = {
    FromType = AdventureActivityModel.GenItemFromType.Order,
    Source = msg.order,
    AdventureActivityItem = item[PROPERTY_TYPE],
    AdventureActivityItemCount = item[PROPERTY_COUNT]
  }
  GM.MainBoardModel.event:Call(BoardEventType.AddAdventureActivityItem, message)
end

function AdventureActivityModel:GetGenerateItemByOrder(order)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self.m_genByFinishOrderCfg == nil then
    return
  end
  local selectedIdx, score
  if self.m_genByFinishOrderUseDiff then
    local diffScore = order:GetDiffScore()
    if diffScore == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_genByFinishOrderCfg, diffScore, "diff_score_min", "diff_score_max")
    score = diffScore
  else
    local price = order:GetPrice()
    if price == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_genByFinishOrderCfg, price, "gold_min", "gold_max")
    score = price
  end
  if selectedIdx == nil then
    return
  end
  local selected = self.m_genByFinishOrderCfg[selectedIdx]
  local newItemType = selected.item
  if newItemType == nil then
    Log.Error("AdventureActivityModel: _OnOrderFinished, itemCode is nil")
    return
  end
  local count = selected.reward_num_percentage and math.floor(score * selected.reward_num_percentage) or selected.reward_num_fix
  if count <= 0 then
    local str = tostring(selected.reward_num_percentage) .. " " .. tostring(score) .. " " .. tostring(selected.reward_num_fix) .. " " .. tostring(count) .. " " .. tostring(selectedIdx) .. " " .. tostring(json.encode(self.m_genByFinishOrderCfg))
    if selected.reward_num_percentage then
      str = str .. " " .. tostring(score * selected.reward_num_percentage) .. " " .. tostring(math.floor(score * selected.reward_num_percentage))
    end
    Log.Error("AdventureActivityModel: _OnOrderFinished, gen item count is 0!" .. str)
    return
  end
  return {
    [PROPERTY_TYPE] = newItemType,
    [PROPERTY_COUNT] = count
  }
end

function AdventureActivityModel:_TryGenerateItemByEnergy(sourceItem, energyBoostRatio)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self.m_genByCostEnergyCfg == nil then
    return
  end
  if self.m_genByCostEnergyCfg.genNum == 0 then
    return
  end
  local roundTotalCount = self.m_dbTable:GetValue(DBKeys.GenerateRoundTotalCountKey, "value") or 0
  local roundValidCount = self.m_dbTable:GetValue(DBKeys.GenerateRoundValidCountKey, "value") or 0
  if roundTotalCount == 0 then
    roundTotalCount = self.m_genByCostEnergyCfg.chance
    roundValidCount = self.m_genByCostEnergyCfg.genNum
    self.m_dbTable:Set(DBKeys.GenerateRoundValidCountKey, "value", roundValidCount)
  end
  local index = MathUtil.Random(roundTotalCount)
  roundTotalCount = roundTotalCount - 1
  self.m_dbTable:Set(DBKeys.GenerateRoundTotalCountKey, "value", roundTotalCount)
  if roundValidCount < index then
    return
  end
  roundValidCount = roundValidCount - 1
  self.m_dbTable:Set(DBKeys.GenerateRoundValidCountKey, "value", roundValidCount)
  local newItemType = Table.ListWeightSelectOne(self.m_genByCostEnergyCfg.items).Item
  if energyBoostRatio ~= nil and 0 < energyBoostRatio then
    for i = 1, energyBoostRatio do
      newItemType = GM.ItemDataModel:GetModelConfig(newItemType).MergedType or newItemType
    end
  end
  self:CacheItems({newItemType})
  GM.BIManager:LogAcquire(newItemType, 1, self.m_activityDefinition.AcquireItemByEnergyBIType, true)
  local message = {
    FromType = AdventureActivityModel.GenItemFromType.Energy,
    Source = sourceItem,
    EnergyBoost = energyBoostRatio ~= nil and 0 < energyBoostRatio,
    AdventureActivityItem = newItemType,
    AdventureActivityItemCount = 1
  }
  GM.MainBoardModel.event:Call(BoardEventType.AddAdventureActivityItem, message)
end

function AdventureActivityModel:GetBoardModel()
  return self.m_boardModel
end

function AdventureActivityModel:CacheItems(cachedItemCodes)
  if Table.IsEmpty(cachedItemCodes) or self.m_boardModel == nil then
    return
  end
  self.m_boardModel:CacheItems(cachedItemCodes)
end

function AdventureActivityModel:_TryGiveInitialItems()
  if self:HasInitialItemGiven() then
    return
  end
  if self.m_boardModel:IsEnergyModuleOpen() then
    self.m_boardModel:GetEnergyModel():AddCurEnergy(5)
    GM.BIManager:LogAcquire(EPropertyType.AdventureEnergy, 5, self.m_activityDefinition.AcquireItemByStart, true)
  else
    local itemType = GM.ItemDataModel:GetTypeByChainAndLevel(self.m_activityDefinition.ToolItemChain, 1)
    local cacheItems = {}
    for i = 1, 5 do
      table.insert(cacheItems, itemType)
    end
    self:CacheItems(cacheItems)
    GM.BIManager:LogAcquire(itemType, 5, self.m_activityDefinition.AcquireItemByStart, true)
  end
  self:SetInitialItemGiven()
end

function AdventureActivityModel:GetRedPointNum()
  if self.m_boardModel == nil then
    return 0
  end
  if self.m_boardModel:GetEnergyModel() ~= nil then
    return self.m_boardModel:GetEnergyModel():GetCurEnergy()
  else
    return self:GetCacheCount()
  end
end

function AdventureActivityModel:GetCacheCount()
  if self.m_boardModel == nil then
    return 0
  end
  return self.m_boardModel:GetCachedItemCount()
end

function AdventureActivityModel:GetMergeLength()
  return #self.arrMergeLine
end

function AdventureActivityModel:GetItemTypeByIndex(index)
  return self.arrMergeLine[index]
end

function AdventureActivityModel:SetLevel(level)
  self.m_dbTable:Set(DBKeys.CurrentMergeLevel, "value", level)
  self:LogActivity(EBIType.ActivityRankUp, level)
  self.m_boardModel:TryUpdateMultiLevel()
end

function AdventureActivityModel:GetLevel()
  return self.m_dbTable:GetValue(DBKeys.CurrentMergeLevel, "value") or 0
end

function AdventureActivityModel:HasInitialItemGiven()
  return self.m_dbTable:GetValue(DBKeys.InitialItemGiven, "value") == 1
end

function AdventureActivityModel:SetInitialItemGiven()
  self.m_dbTable:Set(DBKeys.InitialItemGiven, "value", 1)
end

function AdventureActivityModel:HasBoardEverFulled()
  return self.m_dbTable:GetValue(DBKeys.EverFulledKey, "value") or false
end

function AdventureActivityModel:SetBoardFulled()
  self.m_dbTable:Set(DBKeys.EverFulledKey, "value", true)
end

function AdventureActivityModel:SetNeedPlayChangeTextAni(needPlay)
  self.m_needPlayChangeTextAni = needPlay
end

function AdventureActivityModel:GetNeedPlayChangeTextAni()
  return self.m_needPlayChangeTextAni
end

function AdventureActivityModel:UpdateLevel(itemCode, itemModel)
  local lvl = self:GetLevelByItemCode(itemCode)
  local curLvl = self:GetLevel()
  local unlockedFog = false
  if lvl > curLvl then
    self:SetLevel(lvl)
    if self.m_boardModel:GetFogModel() then
      local fogs = self.m_boardModel:TryUnlockFogByLevel(lvl, itemModel, lvl >= AdventureActivityModel.PopUnlockWindowLevel)
      if not Table.IsEmpty(fogs) then
        unlockedFog = true
      end
    end
    return true, unlockedFog
  end
  return false
end

function AdventureActivityModel:TryFogUnlockViewUpdate()
  local fogModel = self.m_boardModel:GetFogModel()
  if fogModel then
    return fogModel:UnlockViewUpdate()
  end
end

function AdventureActivityModel:InitUpdateLevel()
  if self.m_boardModel == nil then
    return
  end
  local curLvl = self:GetLevel()
  local lvl = 0
  local tempLvl = 0
  for item, _ in pairs(self.m_boardModel:GetAllBoardItems(true)) do
    local code = item:GetCode()
    tempLvl = self:GetLevelByItemCode(code)
    if lvl < tempLvl then
      lvl = tempLvl
    end
  end
  if curLvl < lvl then
    self:SetLevel(lvl)
  end
end

function AdventureActivityModel:GetLevelByItemCode(itemCode)
  for i, v in ipairs(self.arrMergeLine) do
    if v == itemCode then
      return i
    end
  end
  return 0
end

function AdventureActivityModel:GetItemCodeByLevel(lvl)
  return self.arrMergeLine[lvl]
end

function AdventureActivityModel:IsMaxLevel()
  local curLevel = self:GetLevel()
  local maxLevel = self:GetMergeLength()
  return curLevel == maxLevel
end

function AdventureActivityModel:SetPopEndWindow()
  self.m_dbTable:Set(DBKeys.PopEndWindow, "value", "1")
end

function AdventureActivityModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(DBKeys.PopEndWindow, "value") ~= "1"
end

function AdventureActivityModel:GetEndRewards()
  return self.m_boardModel:CollectCacheAndBoardPropertyRewardsWithoutConvert()
end

function AdventureActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function AdventureActivityModel:GetBoardEntryShowConfig()
  return {
    statusChangeName = self.m_activityDefinition.StateChangedEvent,
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_adventureActivityBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_adventureActivityBubbleCount",
    scrollToFunName = "ScrollToAdventureActivity",
    activityType = self:GetType(),
    checkFun = function()
      return self:GetState() == ActivityState.Started
    end
  }
end

function AdventureActivityModel:GetHudEntryShowConfig()
  return {
    Type = "adventureActivity",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent
    },
    EntryPrefabConfigName = UIPrefabConfigName.HudActivityEntry,
    CheckFunc = function()
      return self:GetState() == ActivityState.Preparing or self:GetState() == ActivityState.Started
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = self.m_activityDefinition.EntryImageName,
    OnClickedFunc = function()
      if self:GetState() == ActivityState.Preparing then
        GM.UIManager:OpenView(self.m_activityDefinition.NoticeWindowPrefabName, self:GetType())
      else
        GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType())
      end
    end,
    RedPointType = EntryRedPointType.Num,
    GetRedPointNumFunc = function()
      return self:GetRedPointNum()
    end,
    ArrUpdateEntryContentEvent = {
      EEventType.PopCachedItem,
      EEventType.ItemFlyTarget,
      EEventType.CacheItems,
      EEventType.UIBoardEnergyChanged
    }
  }
end
