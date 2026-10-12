FarmboardActivityActivateAnimalResult = {
  Success = 0,
  NoItem = 1,
  AnimalActive = 2
}
FarmboardActivityUpdateLevelFrom = {MergeItem = 1, BlockProduce = 2}
FarmboardActivityBlockMaxCount = 4
FarmboardActivityModel = setmetatable({}, BaseActivityModel)
FarmboardActivityModel.__index = FarmboardActivityModel
FarmboardActivityModel.TokenNumberKey = "TokenNumber"
FarmboardActivityModel.BoardEverFulledKey = "BoardEverFulled"
FarmboardActivityModel.LevelKey = "Level"
FarmboardActivityModel.BlockProduceMultipleRateKey = "BlockRate"
FarmboardActivityModel.PopEndWindow = "PopEndWindow"
local unlockRateItemLevel = 10

function FarmboardActivityModel:Init(activityType, activityDataTable, itemDataTable, itemLayerDataTable, itemCacheDataTable, boardDataTable)
  self.m_itemDataTable = itemDataTable
  self.m_itemLayerDataTable = itemLayerDataTable
  self.m_itemCacheDataTable = itemCacheDataTable
  self.m_boardDataTable = boardDataTable
  self.m_activityDefinition = FarmboardActivityDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
end

function FarmboardActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
end

function FarmboardActivityModel:OnDestroy()
  EventDispatcher.RemoveTarget(self)
end

function FarmboardActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function FarmboardActivityModel:_LoadOtherServerConfig(config)
  self.m_config.OrderScore = EventOrderScoreConfig.Create(config, self.m_activityDefinition.TokenProperty)
  local blockConifg = {}
  for _, item in ipairs(config.farmboardProduceConfig) do
    table.insert(blockConifg, {
      Index = item.index,
      RoundClickNumber = item.chance[1],
      RoundSpreadNumber = item.chance[2],
      SpreadWeight = self:_ToCodeWeightPairList(item.item)
    })
  end
  table.sort(blockConifg, function(a, b)
    return a.Index < b.Index
  end)
  self.m_config.Block = blockConifg
  local animalConfig = {}
  for _, item in ipairs(config.farmboardAnimalConfig) do
    table.insert(animalConfig, self:_ToCodeWeightPairList(item.item))
  end
  self.m_config.Animal = animalConfig
  local itemConfig = {}
  for _, item in ipairs(config.farmboardItems) do
    itemConfig[item.index] = item.itemID
  end
  self.m_config.Item = itemConfig
  local miscConfigReader = MiscConfigReader.Create(config)
  self.m_config.BlockBoostEnabled = miscConfigReader:GetInteger("farm_tool_boost") == 1
  self.m_itemBookConifg = config.eventBookContents
  if GameConfig.IsTestMode() and #config.farmboardItems ~= #itemConfig then
    Log.Error("FarmboardActivityModel:Init() farmboardItems\233\133\141\231\189\174index\228\184\141\232\191\158\231\187\173")
  end
end

function FarmboardActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  if self.m_boardModel ~= nil then
    self.m_boardModel:DropData(self.m_lateInit)
    self.m_boardModel = nil
    self.m_blockModel = nil
    self.m_animalModel = nil
  else
    self.m_itemDataTable:Drop()
    self.m_itemLayerDataTable:Drop()
    self.m_itemCacheDataTable:Drop()
    self.m_boardDataTable:Drop()
  end
end

function FarmboardActivityModel:_OnStateChanged()
  BaseActivityModel._OnStateChanged(self)
  local state = self:GetState(false)
  if state == ActivityState.Started and self.m_dbTable:GetValue(FarmboardActivityModel.TokenNumberKey, "value") == nil then
    self:_ChangeTokenNumber(1, self.m_activityDefinition.BIAddTokenFree)
    GM.BIManager:LogAcquire(self.m_activityDefinition.TokenProperty, 1, self.m_activityDefinition.BIAddTokenFree, true)
  end
  if state == ActivityState.Started or state == ActivityState.Ended then
    if self.m_boardModel == nil then
      local args = {
        itemDataTable = self.m_itemDataTable,
        itemLayerDataTable = self.m_itemLayerDataTable,
        itemCacheDataTable = self.m_itemCacheDataTable,
        boardDataTable = self.m_boardDataTable,
        boardInitFileName = self.m_activityDefinition.BoardModelConfigName,
        fogConfigFileName = self.m_activityDefinition.FogConfigName,
        activityLevel = self:GetLevel(),
        activityDBTable = self.m_dbTable,
        itemIllustrated = self.m_itemBookConifg,
        activityType = self:GetType(),
        obstacleConfigFileName = self.m_activityDefinition.BoardObstacleConfigName
      }
      self.m_boardModel = FarmboardActivityBoardModel.Create(args)
      self.m_blockModel = FarmboardActivityBlockModel.Create(self.m_dbTable, self.m_config.Block)
      self.m_animalModel = FarmboardActivityAnimalModel.Create(self.m_dbTable, self.m_config.Animal)
      self.m_bookModel = self.m_boardModel:GetItemIllustratedBook()
      AddHandlerAndRecordMap(self.m_bookModel:GetEvent(), BaseUIItemIllustratedBookModel.EventType.AddCacheItem, {
        obj = self,
        method = self.OnAddCacheItem
      })
    end
  else
    self.m_boardModel = nil
    self.m_blockModel = nil
    self.m_animalModel = nil
    self.m_bookModel = nil
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  if self.m_lateInit then
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  end
end

function FarmboardActivityModel:GetHudEntryShowConfig()
  return {
    Type = "farmboardActivity",
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
      return self:GetTokenNumber()
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.TokenNumberChangedEvent
    }
  }
end

function FarmboardActivityModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_activityDefinition.StateChangedEvent
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_farmboardActivityBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_farmboardActivityBubbleCount",
    activityType = self.m_type,
    checkFun = function()
      return self:GetState() == ActivityState.Started
    end
  }
end

function FarmboardActivityModel:GetGenerateItemByOrder(order)
  if self:GetState() ~= ActivityState.Started then
    return nil
  end
  return self.m_config.OrderScore:TryGenerateRewardItem(order)
end

function FarmboardActivityModel:_OnOrderFinished(message)
  local rewardItem = self:GetGenerateItemByOrder(message.order)
  if rewardItem == nil then
    return
  end
  self:_ChangeTokenNumber(rewardItem[PROPERTY_COUNT])
  GM.BIManager:LogAcquire(self.m_activityDefinition.TokenProperty, rewardItem[PROPERTY_COUNT], self.m_activityDefinition.BIAddTokenOrder, true)
  local eventMessage = {
    ActivityType = self.m_type,
    Order = message.order,
    RewardItem = rewardItem
  }
  GM.MainBoardModel.event:Call(BoardEventType.CollectFarmboardToken, eventMessage)
end

function FarmboardActivityModel:_OnItemMerged(message)
  if self.m_state == ActivityState.Started then
    self:_UpdateLevel(message.New:GetType(), FarmboardActivityUpdateLevelFrom.MergeItem, message.New)
  end
end

function FarmboardActivityModel:GetDefinition()
  return self.m_activityDefinition
end

function FarmboardActivityModel:GetTokenNumber()
  return self.m_dbTable:GetValue(FarmboardActivityModel.TokenNumberKey, "value") or 0
end

function FarmboardActivityModel:SetPopEndWindow()
  self.m_dbTable:Set(FarmboardActivityModel.PopEndWindow, "value", "1")
end

function FarmboardActivityModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(FarmboardActivityModel.PopEndWindow, "value") ~= "1"
end

function FarmboardActivityModel:_ChangeTokenNumber(delta)
  local tokenNumber = self:GetTokenNumber()
  self.m_dbTable:Set(FarmboardActivityModel.TokenNumberKey, "value", tokenNumber + delta)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.TokenNumberChangedEvent)
end

function FarmboardActivityModel:AcquireToken(count)
  self:_ChangeTokenNumber(count)
end

function FarmboardActivityModel:GetLevel()
  return self.m_dbTable:GetValue(FarmboardActivityModel.LevelKey, "value") or 0
end

function FarmboardActivityModel:_UpdateLevel(itemCode, from, itemModel)
  local currentLevel = self:GetLevel()
  local targetLevel = 0
  for level, code in ipairs(self.m_config.Item) do
    if itemCode == code then
      targetLevel = level
      break
    end
  end
  if currentLevel >= targetLevel then
    return
  end
  self.m_dbTable:Set(FarmboardActivityModel.LevelKey, "value", targetLevel)
  self:LogActivity(EBIType.ActivityRankUp, targetLevel)
  local unlockedFog = self.m_boardModel:TryUnlockFogByLevel(targetLevel, itemModel)
  local message = {
    UnlockedFog = unlockedFog,
    Code = itemCode,
    Level = targetLevel,
    From = from
  }
  EventDispatcher.DispatchEvent(self.m_activityDefinition.LevelChangedEvent, message)
end

function FarmboardActivityModel:GetMaxLevel()
  return #self.m_config.Item
end

function FarmboardActivityModel:GetItemCodeByLevel(level)
  return self.m_config.Item[level]
end

function FarmboardActivityModel:GetBoardModel()
  return self.m_boardModel
end

function FarmboardActivityModel:HasBoardEverFulled()
  return self.m_dbTable:GetValue(FarmboardActivityModel.BoardEverFulledKey, "value") or false
end

function FarmboardActivityModel:SetBoardFulled()
  self.m_dbTable:Set(FarmboardActivityModel.BoardEverFulledKey, "value", true)
end

function FarmboardActivityModel:GetMinFogLevel()
  local fogModel = self.m_boardModel:GetFogModel()
  local fogId = fogModel:GetMinLevelFogId()
  if not fogId then
    return -1
  end
  local config = fogModel:GetFogConfigById(fogId)
  return config.unlockByLevel
end

function FarmboardActivityModel:GetUnlockedBlockCount()
  return self.m_blockModel:GetUnlockedCount()
end

function FarmboardActivityModel:SetNeedPlayChangeTextAni(needPlay)
  self.m_needPlayChangeTextAni = needPlay
end

function FarmboardActivityModel:GetNeedPlayChangeTextAni()
  return self.m_needPlayChangeTextAni
end

function FarmboardActivityModel:UnlockBlock(item)
  if self:GetUnlockedBlockCount() >= FarmboardActivityBlockMaxCount then
    Log.Error("[\229\134\156\229\156\186\230\163\139\231\155\152]\229\183\178\232\190\190\229\136\176\229\156\176\229\157\151\230\156\128\229\164\167\232\167\163\233\148\129\230\149\176\233\135\143\239\188\140\232\175\183\230\163\128\230\159\165\232\175\165\231\167\141\229\173\144\230\163\139\229\173\144\230\157\165\230\186\144")
    return
  end
  local prevUnlockMultiple = self:GetUnlockProduceMultipleRate()
  self.m_boardModel:RemoveItem(item)
  self.m_blockModel:Unlock()
  GM.BIManager:LogAction(self.m_activityDefinition.BIBlockUnlock, self:GetUnlockedBlockCount())
  local curUnlockMultiple = self:GetUnlockProduceMultipleRate()
  if prevUnlockMultiple ~= curUnlockMultiple then
    GM.BIManager:LogAction(self.m_activityDefinition.BIBlockMultipleShow, {
      id = self:GetId(),
      rate = MathUtil.IntPow(2, self:GetUnlockProduceMultipleRate())
    })
  end
  local message = {Source = item}
  EventDispatcher.DispatchEvent(self.m_activityDefinition.BlockUnlockedEvent, message)
end

function FarmboardActivityModel:BlockProduce()
  local tokenCount = self:GetBlockProduceTokenCount()
  if tokenCount > self:GetTokenNumber() then
    return
  end
  self:_ChangeTokenNumber(-tokenCount)
  EventDispatcher.DispatchEvent(EEventType.FarmPropUsed, {num = tokenCount})
  local rate = self:GetBlockProduceMultipleRate()
  local rewards = self.m_blockModel:Produce(rate)
  local count = self:GetUnlockedBlockCount()
  GM.BIManager:LogAction(self.m_activityDefinition.BIUseToken, {
    u = tokenCount,
    b = count,
    r = rewards
  })
  local splitRewards = {}
  for _, reward in ipairs(rewards) do
    for i = 1, count do
      if splitRewards[i] == nil then
        splitRewards[i] = {}
      end
      table.insert(splitRewards[i], {
        [PROPERTY_TYPE] = reward[PROPERTY_TYPE],
        [PROPERTY_COUNT] = reward[PROPERTY_COUNT] // count
      })
    end
  end
  for blockIndex, rewardList in ipairs(splitRewards) do
    local itemIndex = 0
    for _, reward in ipairs(rewardList) do
      local code = reward[PROPERTY_TYPE]
      local firstItem
      for i = 1, reward[PROPERTY_COUNT] do
        local newItem = self.m_boardModel:BlockDispatchItem(code)
        itemIndex = itemIndex + 1
        if newItem then
          local message = {
            Pos = newItem:GetPosition(),
            ToCache = false,
            BlockIndex = blockIndex,
            Index = itemIndex,
            Source = newItem
          }
          EventDispatcher.DispatchEvent(EEventType.FarmboardBlockProduced, message)
          if firstItem == nil then
            firstItem = newItem
          end
        else
          local message = {
            ToCache = true,
            BlockIndex = blockIndex,
            Index = itemIndex,
            Source = code
          }
          EventDispatcher.DispatchEvent(EEventType.FarmboardBlockProduced, message)
        end
      end
      self:_UpdateLevel(code, FarmboardActivityUpdateLevelFrom.BlockProduce, firstItem)
    end
  end
end

function FarmboardActivityModel:GetBlockProduceMultipleRate()
  local unlockProduceMultipleRate = self:GetUnlockProduceMultipleRate()
  return math.min(unlockProduceMultipleRate, tonumber(self.m_dbTable:GetValue(FarmboardActivityModel.BlockProduceMultipleRateKey, "value")) or 0)
end

function FarmboardActivityModel:GetBlockProduceTokenCount()
  return MathUtil.IntPow(2, self:GetBlockProduceMultipleRate())
end

function FarmboardActivityModel:CanShowBlockProduceMultiple()
  return self:GetUnlockProduceMultipleRate() > 0
end

function FarmboardActivityModel:GetUnlockProduceMultipleRate()
  if not self.m_config.BlockBoostEnabled then
    return 0
  end
  local unlockCondition1 = self:GetUnlockedBlockCount() >= 3 and 1 or 0
  local unlockCondition2 = self.m_bookModel:CheckItemCodeNoLock(self:GetItemCodeByLevel(unlockRateItemLevel)) and 1 or 0
  return unlockCondition1 + unlockCondition2
end

function FarmboardActivityModel:SwitchBlockProduceMultipleRate()
  local rate = self:GetBlockProduceMultipleRate()
  local unlock = self:GetUnlockProduceMultipleRate()
  rate = (rate + 1) % (unlock + 1)
  self.m_dbTable:Set(FarmboardActivityModel.BlockProduceMultipleRateKey, "value", rate)
  GM.BIManager:LogAction(self.m_activityDefinition.BIBlockMultipleClick, self:GetBlockProduceTokenCount())
  EventDispatcher.DispatchEvent(EEventType.FarmboardSwitchBlockMultiple)
end

function FarmboardActivityModel:OnAddCacheItem(message)
  if message and message.itemCode == self:GetItemCodeByLevel(unlockRateItemLevel) then
    EventDispatcher.DispatchEvent(EEventType.FarmboardUnlockBlockMultiple)
    GM.BIManager:LogAction(self.m_activityDefinition.BIBlockMultipleShow, {
      id = self:GetId(),
      rate = MathUtil.IntPow(2, self:GetUnlockProduceMultipleRate())
    })
  end
end

function FarmboardActivityModel:ActivateAnimal(item)
  item = item or self.m_boardModel:GetAnimalActivateItem()
  local result
  if item == nil then
    result = FarmboardActivityActivateAnimalResult.NoItem
  elseif self.m_animalModel:CanProduce() then
    result = FarmboardActivityActivateAnimalResult.AnimalActive
  else
    result = FarmboardActivityActivateAnimalResult.Success
    self.m_boardModel:RemoveItem(item)
    self.m_animalModel:Activate()
    GM.BIManager:LogAction(self.m_activityDefinition.BIAnimalActivate, item:GetType())
  end
  local message = {Result = result, Source = item}
  EventDispatcher.DispatchEvent(self.m_activityDefinition.AnimalActivatedEvent, message)
end

function FarmboardActivityModel:CanAnimalProduce()
  return self.m_animalModel:CanProduce()
end

function FarmboardActivityModel:AnimalProduce(boardPosition)
  local code = self.m_animalModel:Produce()
  GM.BIManager:LogAction(self.m_activityDefinition.BIAnimalProduce, {c = code, n = 1})
  local newItem = self.m_boardModel:GenerateItem(boardPosition, code, nil, nil, BaseUIBoardModel.EGenerateItemState.FarmBoardAnimal)
  local message = {
    Pos = boardPosition,
    ToCache = false,
    Index = 1,
    Source = newItem
  }
  EventDispatcher.DispatchEvent(EEventType.FarmboardAnimalProduced, message)
  return true
end

function FarmboardActivityModel:GetEndRewards()
  return self.m_boardModel:CollectCacheAndBoardPropertyRewardsWithoutConvert()
end

function FarmboardActivityModel.IsActivityTokenType(propertyType)
  for _, activityDefinition in pairs(FarmboardActivityDefinition) do
    if activityDefinition.TokenProperty == propertyType then
      return true
    end
  end
  return false
end

function FarmboardActivityModel:_ToCodeWeightPairList(itemWeightPairList)
  local codeWeightPairList = {}
  for _, pair in ipairs(itemWeightPairList) do
    table.insert(codeWeightPairList, {
      Code = pair.Item,
      Weight = pair.Weight
    })
  end
  return codeWeightPairList
end

function FarmboardActivityModel:GetTestInfo()
  if self:GetState(true) ~= ActivityState.Started then
    return "\230\180\187\229\138\168\229\188\128\229\144\175:\230\151\160"
  end
  local str = "\229\137\169\228\189\153\231\130\185\229\135\187\230\172\161\230\149\176-\229\137\169\228\189\153\229\150\183\229\143\145\230\172\161\230\149\176\n"
  str = str .. "\230\161\163\228\189\141:\228\184\128   \228\186\140   \229\155\155\n"
  str = str .. string.format("\228\184\187\231\186\191:%s  %s  %s\n", self:_GetTestBlockData(1, 0), self:_GetTestBlockData(1, 1), self:_GetTestBlockData(1, 2))
  str = str .. string.format("\229\137\175\231\186\191:%s  %s  %s\n", self:_GetTestBlockData(2, 0), self:_GetTestBlockData(2, 1), self:_GetTestBlockData(2, 2))
  return str
end

function FarmboardActivityModel:_GetTestBlockData(index, rate)
  local roundRestClickNumberKey = string.format(FarmboardActivityBlockModel.BlockRoundRestClickNumberKey, index, rate)
  local roundRestSpreadNumberKey = string.format(FarmboardActivityBlockModel.BlockRoundRestSpreadNumberKey, index, rate)
  local roundRestClickNumber = self.m_blockModel.m_dbTable:GetValue(roundRestClickNumberKey, "value")
  local roundRestSpreadNumber = self.m_blockModel.m_dbTable:GetValue(roundRestSpreadNumberKey, "value")
  if roundRestClickNumber == nil or roundRestClickNumber == 0 then
    roundRestClickNumber = self.m_blockModel.m_config[index].RoundClickNumber
    roundRestSpreadNumber = self.m_blockModel.m_config[index].RoundSpreadNumber
  end
  return tostring(roundRestClickNumber) .. "-" .. tostring(roundRestSpreadNumber)
end
