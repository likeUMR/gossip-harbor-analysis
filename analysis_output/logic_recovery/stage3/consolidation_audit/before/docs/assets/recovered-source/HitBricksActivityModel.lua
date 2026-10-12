HitBricksActivityModel = setmetatable({}, BaseActivityModel)
HitBricksActivityModel.__index = HitBricksActivityModel
local HitBricksDBKeys = {
  CurOrderIndex = "HitBricksActivityCurOrderIndex",
  GenerateRoundTotalCountKey = "HitBricksGenerateRoundTotalCountKey",
  GenerateRoundValidCountKey = "HitBricksGenerateRoundValidCountKey",
  CurHitBricksNum = "HitBricksCurHitBricksNum",
  FirstOpenMainWindow = "HitBricksFirstOpenMainWindow",
  PopFinishWindow = "HitBricksPopFinishWindow",
  ExpriedReward = "HitBricksExpriedReward",
  GiveHammer = "HitBricksGiveHammer",
  FireworksProgress = "CurFireworkProgress",
  FireworksNum = "FireworksNum",
  FireworksRound = "FireworksRound"
}

function HitBricksActivityModel:Init(activityType, dbTable, boarddbTable)
  self.m_activityDefinition = HitBricksActivityDefinition[activityType]
  self.m_boardModel = HitBricksActivityBoardModel.Create(self, boarddbTable)
  BaseActivityModel.Init(self, activityType, dbTable)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
  EventDispatcher.AddListener(EEventType.ItemTransform, self, self._OnItemTransform)
  self:LoadDefaultConfig()
end

function HitBricksActivityModel:LoadDefaultConfig()
  self.m_expireReward = json.decode(self.m_dbTable:GetValue(HitBricksDBKeys.ExpriedReward, "value") or "")
end

function HitBricksActivityModel:LateInit()
  self.m_bLateInit = true
  if self:GetState() == ActivityState.Ended and self.m_expireReward == nil then
    self:ExchangeReward()
  end
end

function HitBricksActivityModel:_LoadOtherServerConfig(config)
  self.m_HitBricksConfig = Table.DeepCopy(config.hitBricks_search_item)
  table.sort(self.m_HitBricksConfig, function(a, b)
    return a.round < b.round
  end)
  self.m_totalround = #self.m_HitBricksConfig
  
  local function dealRangeEntryData(data)
    if data == nil then
      return nil
    end
    local midValue = data
    data = {}
    data[1] = midValue.range_entry[1]
    data[2] = midValue.range_entry[2]
    return data
  end
  
  local function dealStringData(data)
    if data == nil then
      return nil
    end
    local aList = StringUtil.Split(data, ",")
    local target = {}
    target[1] = tonumber(aList[1])
    target[2] = tonumber(aList[2])
    return target
  end
  
  for _, v in pairs(self.m_HitBricksConfig) do
    v.board = dealRangeEntryData(v.board)
    if v.position ~= nil then
      for index, ele in ipairs(v.position) do
        v.position[index] = dealRangeEntryData(v.position[index])
      end
    end
    if v.hardbrickpos ~= nil then
      for index, ele in ipairs(v.hardbrickpos) do
        v.hardbrickpos[index] = dealRangeEntryData(v.hardbrickpos[index])
      end
    end
    if v.bombpos ~= nil then
      for index, ele in ipairs(v.bombpos) do
        v.bombpos[index] = dealRangeEntryData(v.bombpos[index])
      end
    end
  end
  self.m_HitItemsConfig = {}
  local ServeItemData = Table.DeepCopy(config.hitBricks_item_config)
  for _, v in pairs(ServeItemData) do
    v.size = dealRangeEntryData(v.size)
    if v.spin == 1 then
      local t = v.size[1]
      v.size[1] = v.size[2]
      v.size[2] = t
    end
    self.m_HitItemsConfig[v.item] = v
  end
  self.m_ruleType = 0
  if config.misc_conf_new ~= nil then
    self.m_ruleType = Table.ListSelect(config.misc_conf_new, function(data)
      return data.confType == "search_type"
    end)[1].param_int
  end
  if self.m_ruleType == 0 then
    self.m_GenerateConfig = config.hitBricks_hammer_chance[1]
  else
    self.m_hammerOrderConfig = config.hitBricks_order_hammer
  end
  self.bOpenFireworks = false
  self.m_fireworksConfig = config.hitBricks_firework_config
  if not Table.IsEmpty(self.m_fireworksConfig) then
    self.bOpenFireworks = true
  end
end

function HitBricksActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_boardModel:_DropData()
end

function HitBricksActivityModel:IsActivityOpen()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self:GetCurOrderIndex() > #self.m_HitBricksConfig then
    return false
  end
  return true
end

function HitBricksActivityModel:_OnItemSpread(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy and self.m_ruleType == 0 then
    self:_TryGenerateItem(message.Source, message.EnergyBoostRatio)
  end
end

function HitBricksActivityModel:_OnItemTransform(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy and self.m_ruleType == 0 then
    self:_TryGenerateItem(message.Source, 0)
  end
end

function HitBricksActivityModel:GetAddScoreByOrder(order)
  if self.m_boardModel:GetBoardData() == nil then
    return nil
  end
  if self.m_ruleType == 0 then
    return nil
  end
  if order:GetInnerType() == MainOrderType.Special then
    return nil
  end
  local diffscore = order:GetDiffScore()
  local gold = order:GetPrice()
  local targetConfig
  for _, config in ipairs(self.m_hammerOrderConfig) do
    if config.gold_min ~= nil and config.gold_max ~= nil and gold >= config.gold_min and gold <= config.gold_max then
      targetConfig = config
      break
    end
    if config.diff_score_min ~= nil and config.diff_score_max ~= nil and diffscore >= config.diff_score_min and diffscore <= config.diff_score_max then
      targetConfig = config
      break
    end
  end
  if targetConfig == nil then
    return nil
  end
  local score = 0
  if targetConfig.reward_num_fix ~= nil then
    score = targetConfig.reward_num_fix
  elseif targetConfig.reward_num_percentage ~= nil then
    if targetConfig.gold_min ~= nil and targetConfig.gold_max ~= nil then
      score = math.ceil(gold * targetConfig.reward_num_percentage)
    else
      score = math.ceil(diffscore * targetConfig.reward_num_percentage)
    end
  end
  return {
    [PROPERTY_TYPE] = self.m_activityDefinition.coinToken,
    [PROPERTY_COUNT] = score
  }
end

function HitBricksActivityModel:_TryGenerateItem(sourceItem, energyBoostRatio)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  local i32Num = self:_GenerateItemType(energyBoostRatio)
  if i32Num == nil then
    return
  end
  self:SetHitBricksNum(self:GetHitBricksNum() + i32Num)
  GM.BIManager:LogAcquire("hitbricksHammer", i32Num, self.m_activityDefinition.BIGetHammer, true)
  if 0 < i32Num then
    EventDispatcher.DispatchEvent(self.m_activityDefinition.HammerGeneratedEvent, {
      sourceItem = sourceItem,
      num = i32Num,
      energyBoostRatio = energyBoostRatio
    })
  end
end

function HitBricksActivityModel:_GenerateItemType(energyBoostRatio)
  if GM.SceneManager:GetGameMode() ~= EGameMode.Main then
    return nil
  end
  if not self:IsActivityOpen() then
    return nil
  end
  local roundTotalCount = self.m_dbTable:GetValue(HitBricksDBKeys.GenerateRoundTotalCountKey, "value") or 0
  local roundValidCount = self.m_dbTable:GetValue(HitBricksDBKeys.GenerateRoundValidCountKey, "value") or 0
  if roundTotalCount == 0 then
    roundTotalCount = self.m_GenerateConfig.chance_new[1]
    roundValidCount = self.m_GenerateConfig.chance_new[2]
    self.m_dbTable:Set(HitBricksDBKeys.GenerateRoundValidCountKey, "value", roundValidCount)
  end
  local index = MathUtil.Random(roundTotalCount)
  roundTotalCount = roundTotalCount - 1
  self.m_dbTable:Set(HitBricksDBKeys.GenerateRoundTotalCountKey, "value", roundTotalCount)
  if roundValidCount < index then
    return nil
  end
  roundValidCount = roundValidCount - 1
  self.m_dbTable:Set(HitBricksDBKeys.GenerateRoundValidCountKey, "value", roundValidCount)
  local num = 1
  if energyBoostRatio ~= nil and 0 < energyBoostRatio then
    for i = 1, energyBoostRatio do
      num = num * 2
    end
  end
  return num
end

function HitBricksActivityModel:GetBoardEntryShowConfig()
  return {
    statusChangeName = self.m_activityDefinition.StateChangedEvent,
    listener2 = self.m_activityDefinition.LevelUpEvent,
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_hitBricksBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_hitBricksBubbleCount",
    activityType = self:GetType(),
    checkFun = function()
      return self:IsActivityOpen()
    end
  }
end

function HitBricksActivityModel:GetHudEntryShowConfig()
  return {
    Type = "hitBricks",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.LevelUpEvent
    },
    EntryPrefabConfigName = UIPrefabConfigName.HudActivityEntry,
    CheckFunc = function()
      return self:GetState() == ActivityState.Preparing or self:IsActivityOpen()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = self.m_activityDefinition.EntryIconName,
    OnClickedFunc = function()
      local state = self:GetState()
      if state == ActivityState.Preparing then
        GM.UIManager:OpenView(self.m_activityDefinition.NoticeWindowPrefabName, self:GetType())
      elseif state == ActivityState.Started then
        GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType(), true, true)
      end
    end,
    RedPointType = EntryRedPointType.Num,
    GetRedPointNumFunc = function()
      return self:GetHitBricksNum()
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.HammerNumChangedEvent
    },
    ArrUpdateEntryContentModelEvent = nil
  }
end

function HitBricksActivityModel:_OnStateChanged()
  if self:GetState() == ActivityState.Started then
    self.m_boardModel:OnSyncDataFinished()
    self:TryLevelUp()
    if self.m_dbTable:GetValue(HitBricksDBKeys.GiveHammer, "value") ~= "1" then
      self.m_dbTable:Set(HitBricksDBKeys.GiveHammer, "value", "1")
      RewardApi.AcquireRewardsLogic({
        {
          [PROPERTY_TYPE] = self.m_activityDefinition.coinToken,
          [PROPERTY_COUNT] = 3
        }
      }, EPropertySource.Give, self.m_activityDefinition.BIGetRewards)
    end
  elseif self:GetState() == ActivityState.Ended and self.m_expireReward == nil and self.m_bLateInit then
    self:ExchangeReward()
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function HitBricksActivityModel:CanLevelUp()
  if not self:IsActivityOpen() then
    return false
  end
  if Table.IsEmpty(self.m_boardModel:GetBoardData().m_BottomData) then
    return true
  end
  return false
end

function HitBricksActivityModel:TryLevelUp()
  if not self:CanLevelUp() then
    return
  end
  local curData = self:GetCurRoundConfig()
  RewardApi.AcquireRewardsLogic(curData.reward, EPropertySource.Give, self.m_activityDefinition.BIFinishOrder, EGameMode.Main, CacheItemType.Type2)
  if curData.reward_finish ~= nil then
    RewardApi.AcquireRewardsLogic({
      curData.reward_finish
    }, EPropertySource.Give, self.m_activityDefinition.BIFinishEndOrder, EGameMode.Main, CacheItemType.Type2)
  end
  self:LogActivity(EBIType.ActivityGetRewards, self:GetCurOrderIndex())
  self:LogActivity(EBIType.ActivityRankUp, self:GetCurOrderIndex() + 1)
  self:SetCurOrderIndex(self:GetCurOrderIndex() + 1)
  self.m_boardModel:TryCreateNewBoardInfo()
  if self:GetBoardModel():GetBoardData() == nil and self.m_expireReward == nil then
    self:ExchangeReward()
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.LevelUpEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function HitBricksActivityModel:SetPopFinishWindow()
  self.m_dbTable:Set(HitBricksDBKeys.PopFinishWindow, "value", "1")
end

function HitBricksActivityModel:GetPopFinishWindow()
  return self.m_dbTable:GetValue(HitBricksDBKeys.PopFinishWindow, "value")
end

function HitBricksActivityModel:SetFirstOpenMainWindow()
  self.m_dbTable:Set(HitBricksDBKeys.FirstOpenMainWindow, "value", "1")
end

function HitBricksActivityModel:GetFirstOpenMainWindow()
  return self.m_dbTable:GetValue(HitBricksDBKeys.FirstOpenMainWindow, "value")
end

function HitBricksActivityModel:GetBoardModel()
  return self.m_boardModel
end

function HitBricksActivityModel:GetHitBricksNum()
  return tonumber(self.m_dbTable:GetValue(HitBricksDBKeys.CurHitBricksNum, "value") or "0")
end

function HitBricksActivityModel:SetHitBricksNum(i32Num)
  self.m_dbTable:Set(HitBricksDBKeys.CurHitBricksNum, "value", tostring(i32Num))
  EventDispatcher.DispatchEvent(self.m_activityDefinition.HammerNumChangedEvent)
end

function HitBricksActivityModel:ExchangeReward()
  if self.m_expireReward ~= nil then
    return
  end
  local maxnum = 100
  local cnt = self:GetHitBricksNum()
  local rewards = {
    {
      [PROPERTY_TYPE] = EPropertyType.Energy,
      [PROPERTY_COUNT] = math.min(maxnum, 10 + cnt // 2 * 5)
    }
  }
  if cnt == 0 then
    rewards[1][PROPERTY_COUNT] = 0
  end
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_activityDefinition.RewardRecoverBIType, EGameMode.Main, CacheItemType.Type2)
  self.m_expireReward = rewards
  GM.BIManager:LogAction(self.m_activityDefinition.RewardRecoverBIType, {
    re = self.m_expireReward[1],
    cnt = self:GetHitBricksNum()
  })
  self:SaveExpireReward()
  self:SetHitBricksNum(0)
  return rewards
end

function HitBricksActivityModel:GetExpiredReward()
  return self.m_expireReward
end

function HitBricksActivityModel:SaveExpireReward()
  local jsonData = ""
  if self.m_expireReward ~= nil then
    jsonData = json.encode(self.m_expireReward)
    self.m_dbTable:Set(HitBricksDBKeys.ExpriedReward, "value", jsonData)
  else
    self.m_dbTable:Remove(HitBricksDBKeys.ExpriedReward)
  end
end

function HitBricksActivityModel:GetCurOrderIndex()
  return tonumber(self.m_dbTable:GetValue(HitBricksDBKeys.CurOrderIndex, "value")) or 1
end

function HitBricksActivityModel:SetCurOrderIndex(index)
  self.m_dbTable:Set(HitBricksDBKeys.CurOrderIndex, "value", tostring(index))
end

function HitBricksActivityModel:GetOrderConfig()
  return self.m_HitBricksConfig
end

function HitBricksActivityModel:GetItemConfig()
  return self.m_HitItemsConfig
end

function HitBricksActivityModel:GetCurRoundConfig()
  return self:GetHitBricksConfigByIndex(self:GetCurOrderIndex())
end

function HitBricksActivityModel:GetTotalRound()
  return self.m_totalround
end

function HitBricksActivityModel:GetActivityDefinition()
  return self.m_activityDefinition
end

function HitBricksActivityModel:GetRuleType()
  return self.m_ruleType
end

function HitBricksActivityModel:GetHitBricksConfigByIndex(index)
  local orderConfigs = self:GetOrderConfig()
  local findOrder
  for _, v in pairs(orderConfigs) do
    if v.round == index then
      findOrder = v
      break
    end
  end
  return findOrder
end

function HitBricksActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function HitBricksActivityModel:GetTokenType()
  return self.m_activityDefinition.coinToken
end

function HitBricksActivityModel:AcquireActivityToken(count)
  self:SetHitBricksNum(self:GetHitBricksNum() + count)
end

function HitBricksActivityModel:SetTestOrder(level)
  self:SetCurOrderIndex(level)
  self.m_boardModel:TryCreateNewBoardInfo()
  self.m_dbTable:Set(HitBricksDBKeys.FirstOpenMainWindow, "value", "0")
end

function HitBricksActivityModel:GetTestData()
  return self.m_boardModel:GetTestData()
end

function HitBricksActivityModel:GetFireworksConfig()
  return self.m_fireworksConfig
end

function HitBricksActivityModel:GetCurFireworksRoundConfig()
  return self:GetFireWorksConfigByIndex(self:GetFireworksRound())
end

function HitBricksActivityModel:GetFireWorksConfigByIndex(index)
  local Configs = self:GetFireworksConfig()
  local selectConfig
  for _, config in pairs(Configs) do
    if index >= config.min and index <= config.max then
      selectConfig = config
      break
    end
  end
  return selectConfig
end

function HitBricksActivityModel:SetFireworksProgress(i32Num)
  self.m_dbTable:Set(HitBricksDBKeys.FireworksProgress, "value", i32Num)
end

function HitBricksActivityModel:GetFireworksProgress()
  return self.m_dbTable:GetValue(HitBricksDBKeys.FireworksProgress, "value") or 0
end

function HitBricksActivityModel:GetCurFireworksTotalTools()
  return self:GetCurFireworksRoundConfig().tools
end

function HitBricksActivityModel:SetFireworksNum(i32Num)
  self.m_dbTable:Set(HitBricksDBKeys.FireworksNum, "value", i32Num)
end

function HitBricksActivityModel:GetFireworksNum()
  return self.m_dbTable:GetValue(HitBricksDBKeys.FireworksNum, "value") or 0
end

function HitBricksActivityModel:AddFireworksRound(i32Num)
  self.m_dbTable:Set(HitBricksDBKeys.FireworksRound, "value", self:GetFireworksRound() + i32Num)
end

function HitBricksActivityModel:GetFireworksRound()
  return self.m_dbTable:GetValue(HitBricksDBKeys.FireworksRound, "value") or 1
end

function HitBricksActivityModel:AddFireworksProgress(i32Num)
  local fireworksPro = self:GetFireworksProgress() + i32Num
  local needTools = self:GetCurFireworksTotalTools()
  self:SetFireworksProgress(fireworksPro)
  if fireworksPro == needTools then
    self:AccquireFireworks()
    self:SetFireworksProgress(0)
  end
end

function HitBricksActivityModel:AccquireFireworks()
  local fireworksConfig = self:GetCurFireworksRoundConfig()
  self:SetFireworksNum(self:GetFireworksNum() + fireworksConfig.fireworks)
  GM.BIManager:LogAction(self.m_activityDefinition.BIAcquireFireworks, {
    round = self:GetFireworksRound(),
    num = fireworksConfig.fireworks
  })
  self:AddFireworksRound(1)
end

function HitBricksActivityModel:GetFireworksPos()
  local fireworksConfig = self:GetFireWorksConfigByIndex(self:GetFireworksRound() - 1)
  local bottomPosition, otherPosition = self.m_boardModel:GetBottomAndOtherPosition()
  local fireworksPos
  if fireworksConfig.fireworkpos == nil then
    Table.ListAppend(bottomPosition, otherPosition)
    fireworksPos = Table.ListRandomSelectOne(bottomPosition)
  elseif math.random() < fireworksConfig.fireworkpos or Table.IsEmpty(otherPosition) then
    fireworksPos = Table.ListRandomSelectOne(bottomPosition)
  else
    fireworksPos = Table.ListRandomSelectOne(otherPosition)
  end
  return fireworksPos
end

function HitBricksActivityModel:ReleaseFireworks(board)
  self.m_boardModel:TryReleaseFireworks(board)
end

function HitBricksActivityModel:IsFireworksOpen()
  return self.bOpenFireworks
end
