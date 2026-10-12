RoadAddScoreScene = {
  merge = "merge",
  bubble = "bubble",
  shop = "shop",
  order = "order"
}
local DBKey = {
  Score = "score",
  LastDisplayedLevel = "lastDisplayedLevel",
  LastDisplayedScore = "lastDisplayedScore"
}
local DBColumnValue = "value"
RoadModel = setmetatable({}, BaseActivityModel)
RoadModel.__index = RoadModel

function RoadModel:Init(activityType, virtualDBTable)
  self.m_definition = RoadDefinition[activityType]
  BaseActivityModel.Init(self, activityType, virtualDBTable)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
  EventDispatcher.AddListener(EEventType.BubbleBroken, self, self._OnBubbleBroken)
  EventDispatcher.AddListener(EEventType.ShopItemBaught, self, self._OnShopItemBought)
end

function RoadModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function RoadModel:_DropData()
  BaseActivityModel._DropData(self)
  self:UpdateContent()
end

function RoadModel:_LoadOtherServerConfig(config)
  local mergeConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_mergeItemScoreConfig = {}
  for _, data in ipairs(mergeConfig) do
    self.m_mergeItemScoreConfig[data.item_id] = data
  end
  self.m_eventTokenNum = 0
  self.m_config.roadRewards = {}
  for _, data in ipairs(config.roadReward) do
    table.insert(self.m_config.roadRewards, data)
    if data.reward[PROPERTY_TYPE] == EPropertyType.MainDecorGeneralToken then
      self.m_eventTokenNum = self.m_eventTokenNum + data.reward[PROPERTY_COUNT]
    end
  end
  table.sort(self.m_config.roadRewards, function(a, b)
    return a.round < b.round
  end)
  Log.Assert(#self.m_config.roadRewards == 10, "Road rewards config must have 10 items.")
  Log.Assert(self.m_config.roadRewards[10].reward[PROPERTY_TYPE] == EPropertyType.MainDecorGeneralToken, "The 10th road reward must be event token.")
  self.m_config.finishOrderAddScoreConfig = {}
  for _, data in ipairs(config.merge_order_score) do
    table.insert(self.m_config.finishOrderAddScoreConfig, Table.ShallowCopy(data))
  end
  self:UpdateContent()
end

function RoadModel:UpdateContent()
  self.m_currentStep = 0
  self.m_currentScore = 0
  self.m_cacheState = nil
  if self.m_config == nil then
    return
  end
  local score = self:GetTotalScore()
  local tmpScore = 0
  for _, rewardConfig in ipairs(self.m_config.roadRewards) do
    tmpScore = tmpScore + rewardConfig.score
    self.m_currentStep = self.m_currentStep + 1
    if score < tmpScore then
      self.m_currentScore = score - (tmpScore - rewardConfig.score)
      break
    end
  end
  if score >= tmpScore then
    self.m_cacheState = ActivityState.Ended
    self.m_currentScore = score - tmpScore
    self.m_currentStep = self.m_currentStep + 1
  end
end

function RoadModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_definition.StateChangedEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function RoadModel:CanAddScore()
  return self:GetState() == ActivityState.Started and self.m_cacheState ~= ActivityState.Ended
end

function RoadModel:GetEventTokenNum()
  return self.m_eventTokenNum
end

function RoadModel:_TryAddMergeScore(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_mergeItemScoreConfig[itemType].merge_score
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, RoadAddScoreScene.merge, itemModel)
  end
end

function RoadModel:_TryAddBubbleBroken(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local bubbleScore = self.m_mergeItemScoreConfig[itemType].bubble_score
  if bubbleScore ~= nil then
    self:_AddScore(bubbleScore, RoadAddScoreScene.bubble, itemModel)
  end
end

function RoadModel:_TryAddBuyShopItemScore(itemCode)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemCode
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_mergeItemScoreConfig[itemType].shop_score
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, RoadAddScoreScene.shop, itemType)
  end
end

function RoadModel:GetAddScoreByOrder(order)
  if not self:CanAddScore() then
    return 0
  end
  if order:GetInnerType() == MainOrderType.Special then
    return 0
  end
  local diffscore = order:GetDiffScore()
  local gold = order:GetPrice()
  local targetConfig
  for _, config in ipairs(self.m_config.finishOrderAddScoreConfig) do
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
    return 0
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
  return score
end

function RoadModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddMergeScore(message.Source)
  end
end

function RoadModel:_OnBubbleBroken(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddBubbleBroken(message.New)
  end
end

function RoadModel:_OnShopItemBought(message)
  if message.Data.shopType == EShopType.FlashSale then
    self:_TryAddBuyShopItemScore(message.Data.itemCode)
  end
end

function RoadModel:AcquireActivityToken(num)
  self:_AddScore(num, RoadAddScoreScene.order, nil)
end

function RoadModel:_AddScore(addScore, scene, message)
  local lastStep = self.m_currentStep
  local score = self:GetTotalScore() + addScore
  self.m_dbTable:Set(DBKey.Score, DBColumnValue, score)
  self:LogActivity(EBIType.ActivityAddScore, addScore)
  GM.BIManager:LogAction(self.m_definition.GetScoreBIType, {
    score = addScore,
    scene = scene,
    level = lastStep
  })
  self:UpdateContent()
  local step = 0
  local rewards = {}
  if lastStep < self.m_currentStep then
    for _, rewardConfig in ipairs(self.m_config.roadRewards) do
      step = step + 1
      if lastStep <= step and step < self.m_currentStep then
        Table.ListAppend(rewards, {
          rewardConfig.reward
        })
        self:LogActivity(EBIType.ActivityRankUp, step)
      end
    end
    if not Table.IsEmpty(rewards) then
      RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_definition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
    end
  end
  local msg = {
    Scene = scene,
    Source = message,
    TokenScore = addScore,
    Rewards = rewards,
    activityType = self:GetType()
  }
  if self.m_cacheState == ActivityState.Ended then
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  end
  if msg.Scene ~= RoadAddScoreScene.order or self.m_cacheState == ActivityState.Ended then
    EventDispatcher.DispatchEvent(self.m_definition.ScoreChangedEvent, msg)
  end
end

function RoadModel:GetTotalScore()
  return self.m_dbTable:GetValue(DBKey.Score, DBColumnValue) or 0
end

function RoadModel:GetScore()
  return self.m_currentScore
end

function RoadModel:GetLevel()
  return self.m_currentStep
end

function RoadModel:GetLastDisplayedLevelAndScore()
  local lastDisplayedLevel = self.m_dbTable:GetValue(DBKey.LastDisplayedLevel, DBColumnValue) or 1
  local lastDisplayedScore = self.m_dbTable:GetValue(DBKey.LastDisplayedScore, DBColumnValue) or 0
  return lastDisplayedLevel, lastDisplayedScore
end

function RoadModel:SetLastDisplayedLevelAndScore(lastDisplayedLevel, lastDisplayedScore)
  self.m_dbTable:Set(DBKey.LastDisplayedLevel, DBColumnValue, lastDisplayedLevel)
  self.m_dbTable:Set(DBKey.LastDisplayedScore, DBColumnValue, lastDisplayedScore)
end

function RoadModel:GetLevelConfig(level)
  if level <= 0 then
    return
  end
  return self.m_config.roadRewards[level]
end

function RoadModel:IsTokenProperty(propertyType)
  return propertyType == self.m_definition.ActivityTokenPropertyType
end

function RoadModel:GetTokenPropertyType()
  return self.m_definition.ActivityTokenPropertyType
end

function RoadModel:GetHudEntryShowConfig()
  return {
    Type = "road",
    ArrCheckShowEvent = {
      self.m_definition.StateChangedEvent,
      self.m_definition.ScoreChangedEvent
    },
    EntryPrefabConfigName = UIPrefabConfigName.HudActivityEntry,
    CheckFunc = function()
      return self:CanAddScore()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_definition.EntryButtonKey,
    EntryIconName = self.m_definition.EntryIconName,
    OnClickedFunc = function()
      GM.UIManager:OpenView(self.m_definition.MainWindowPrefabName, self.m_type, false, false)
    end,
    RedPointType = EntryRedPointType.None
  }
end

function RoadModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_definition.StateChangedEvent,
      self.m_definition.ScoreChangedEvent
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_roadEntryNode",
    bubbleCountName = "m_roadBubbleCount",
    entryPrefabName = self.m_definition.BoardEntryPrefabName,
    scrollToFunName = "ScrollToRoadBoardEntry",
    activityType = self.m_type,
    checkFun = function()
      return self:CanAddScore()
    end
  }
end

function RoadModel:GetResourceLabels()
  return self.m_definition.ResourceLabels
end

function RoadModel:TestAddScore(num)
  self:_AddScore(num, RoadAddScoreScene.shop, nil)
end
