AvenueAddScoreScene = {
  merge = "merge",
  bubble = "bubble",
  shop = "shop",
  order = "order"
}
local DBKey = {
  Score = "score",
  LastDisplayedLevel = "lastDisplayedLevel",
  LastDisplayedScore = "lastDisplayedScore",
  LastDisplayedStage = "lastDisplayedStage"
}
local DBColumnValue = "value"
AvenueModel = setmetatable({}, BaseActivityModel)
AvenueModel.__index = AvenueModel

function AvenueModel:Init(activityType, dbTable)
  self.m_definition = AvenueDefinition[activityType]
  BaseActivityModel.Init(self, activityType, dbTable)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
  EventDispatcher.AddListener(EEventType.BubbleBroken, self, self._OnBubbleBroken)
  EventDispatcher.AddListener(EEventType.ShopItemBaught, self, self._OnShopItemBaught)
end

function AvenueModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function AvenueModel:_DropData()
  BaseActivityModel._DropData(self)
  self:UpdateContent()
end

function AvenueModel:_LoadOtherServerConfig(config)
  local mergeConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_mergeItemScoreConfig = {}
  for _, data in ipairs(mergeConfig) do
    self.m_mergeItemScoreConfig[data.item_id] = data
  end
  self.m_config.nonLoopAvenueRewards = {}
  self.m_config.loopAvenueRewards = {}
  for _, data in ipairs(config.avenueReward) do
    if data.isCyclic == 0 then
      table.insert(self.m_config.nonLoopAvenueRewards, data)
    else
      table.insert(self.m_config.loopAvenueRewards, data)
    end
  end
  table.sort(self.m_config.nonLoopAvenueRewards, function(a, b)
    return a.round < b.round
  end)
  if not Table.IsEmpty(self.m_config.loopAvenueRewards) then
    table.sort(self.m_config.loopAvenueRewards, function(a, b)
      return a.round < b.round
    end)
  end
  self.m_config.finishOrderAddScoreConfig = {}
  for _, data in ipairs(config.merge_order_score) do
    table.insert(self.m_config.finishOrderAddScoreConfig, Table.ShallowCopy(data))
  end
  self.m_totalRequiredLevel = 0
  if not Table.IsEmpty(config.avenueStageReward) then
    table.sort(config.avenueStageReward, function(a, b)
      return a.stage < b.stage
    end)
    self.m_config.avenueStageReward = {}
    for _, data in ipairs(config.avenueStageReward) do
      table.insert(self.m_config.avenueStageReward, data)
      self.m_totalRequiredLevel = data.num
    end
  end
  self:UpdateContent()
  if self:IsStageRewardMode() then
    self:SetLastDisplayedStage(self:GetCurrStage())
  end
end

function AvenueModel:GetStageConfigGroupId()
  if self.m_config.avenueStageReward then
    return self.m_config.avenueStageReward[1].groupId
  end
end

function AvenueModel:UpdateContent()
  self.m_currentStep = 0
  self.m_currentScore = 0
  self.m_cacheState = nil
  if self.m_config == nil then
    return
  end
  local score = self:GetTotalScore()
  local tmpScore = 0
  for _, rewardConfig in ipairs(self.m_config.nonLoopAvenueRewards) do
    tmpScore = tmpScore + rewardConfig.score
    self.m_currentStep = self.m_currentStep + 1
    if score < tmpScore then
      self.m_currentScore = score - (tmpScore - rewardConfig.score)
      break
    end
  end
  if score >= tmpScore then
    if not Table.IsEmpty(self.m_config.loopAvenueRewards) then
      while score >= tmpScore do
        for _, rewardConfig in ipairs(self.m_config.loopAvenueRewards) do
          tmpScore = tmpScore + rewardConfig.score
          self.m_currentStep = self.m_currentStep + 1
          if score < tmpScore then
            self.m_currentScore = score - (tmpScore - rewardConfig.score)
            break
          end
        end
      end
    else
      self.m_cacheState = ActivityState.Ended
      self.m_currentScore = score - tmpScore
      self.m_currentStep = self.m_currentStep + 1
    end
  end
  self.m_currStage = 0
  if self:IsStageRewardMode() then
    for i = 1, self:GetMaxStage() do
      if self:GetStageData(i).num <= self.m_currentStep - 1 then
        self.m_currStage = i
      else
        if self:GetStageData(i).num <= self.m_currentStep and score >= tmpScore then
          self.m_currStage = i
        end
        break
      end
    end
  end
end

function AvenueModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_definition.StateChangedEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function AvenueModel:IsLoopAvenue()
  return not Table.IsEmpty(self.m_config.loopAvenueRewards)
end

function AvenueModel:CanAddScore()
  return self:GetState() == ActivityState.Started and self.m_cacheState ~= ActivityState.Ended
end

function AvenueModel:_TryAddMergeScore(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_mergeItemScoreConfig[itemType].merge_score
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, AvenueAddScoreScene.merge, itemModel)
  end
end

function AvenueModel:_TryAddBubbleBroken(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local bubbleScore = self.m_mergeItemScoreConfig[itemType].bubble_score
  if bubbleScore ~= nil then
    self:_AddScore(bubbleScore, AvenueAddScoreScene.bubble, itemModel)
  end
end

function AvenueModel:_TryAddBuyShopItemScore(itemCode)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemCode
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_mergeItemScoreConfig[itemType].shop_score
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, AvenueAddScoreScene.shop, itemType)
  end
end

function AvenueModel:GetAddScoreByOrder(order)
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

function AvenueModel:GetStageData(stage)
  if self:IsStageRewardMode() then
    return self.m_config.avenueStageReward[stage]
  end
end

function AvenueModel:GetCurrStage()
  return self.m_currStage
end

function AvenueModel:IsStageRewardMode()
  return not Table.IsEmpty(self.m_config) and not Table.IsEmpty(self.m_config.avenueStageReward)
end

function AvenueModel:GetMaxStage()
  if self:IsStageRewardMode() then
    return Table.MapSize(self.m_config.avenueStageReward)
  end
end

function AvenueModel:GetTotalRequiredLevel()
  return self.m_totalRequiredLevel
end

function AvenueModel:IsFinishedStageReward()
  if self:IsStageRewardMode() then
    return self.m_currStage >= self:GetMaxStage()
  else
    return false
  end
end

function AvenueModel:CalStageByLevel(level)
  if self:IsStageRewardMode() then
    local stage = 0
    for i = 1, self:GetMaxStage() do
      if level >= self:GetStageData(i).num then
        stage = i
      end
    end
    return stage
  end
end

function AvenueModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddMergeScore(message.Source)
  end
end

function AvenueModel:_OnBubbleBroken(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddBubbleBroken(message.New)
  end
end

function AvenueModel:_OnShopItemBaught(message)
  if message.Data.shopType == EShopType.FlashSale then
    self:_TryAddBuyShopItemScore(message.Data.itemCode)
  end
end

function AvenueModel:AcquireActivityToken(num)
  self:_AddScore(num, AvenueAddScoreScene.order, nil)
end

function AvenueModel:ClearCacheStageReward()
  if not Table.IsEmpty(self.cacheStageRewards) then
    local viewData = {}
    RewardApi.AcquireRewardsInView(self.cacheStageRewards, viewData)
    self.cacheStageRewards = {}
  end
end

function AvenueModel:ClearCacheNormalRewards()
  if not Table.IsEmpty(self.cacheNormalRewards) then
    RewardApi.AcquireRewardsInView(self.cacheNormalRewards, {})
    self.cacheNormalRewards = {}
  end
end

function AvenueModel:_AddScore(addScore, scene, message)
  local lastStep = self.m_currentStep
  local lastStage = self.m_currStage or 0
  local score = self:GetTotalScore() + addScore
  self.m_dbTable:Set(DBKey.Score, DBColumnValue, score)
  self:LogActivity(EBIType.ActivityAddScore, addScore)
  GM.BIManager:LogAction(self.m_definition.GetScoreBIType, {
    score = addScore,
    scene = scene,
    level = lastStep
  })
  self:UpdateContent()
  if self:IsStageRewardMode() then
    GM.BIManager:LogAction(self.m_definition.CompleteStage, {
      id = self.m_currStage,
      groupid = self:GetStageConfigGroupId()
    })
  end
  local step = 0
  local rewards = {}
  if lastStep < self.m_currentStep then
    for _, rewardConfig in ipairs(self.m_config.nonLoopAvenueRewards) do
      step = step + 1
      if lastStep <= step and step < self.m_currentStep then
        Table.ListAppend(rewards, rewardConfig.rewards)
        self:LogActivity(EBIType.ActivityRankUp, step)
      end
    end
    if not Table.IsEmpty(self.m_config.loopAvenueRewards) then
      while step < self.m_currentStep do
        for _, rewardConfig in ipairs(self.m_config.loopAvenueRewards) do
          step = step + 1
          if lastStep <= step and step < self.m_currentStep then
            Table.ListAppend(rewards, rewardConfig.rewards)
          end
        end
      end
    end
    if not Table.IsEmpty(rewards) then
      RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_definition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
    end
    self.cacheNormalRewards = rewards
  end
  if self:IsStageRewardMode() then
    local stage = 0
    local stageRewards = {}
    if lastStage < self.m_currStage then
      for _, rewardConfig in ipairs(self.m_config.avenueStageReward) do
        stage = stage + 1
        if lastStage < stage and stage <= self.m_currStage then
          Table.ListAppend(stageRewards, {
            rewardConfig.reward
          })
          GM.BIManager:LogAction(self.m_definition.GetStageReward, {
            groupid = self:GetStageConfigGroupId(),
            id = stage
          })
        end
      end
      if not Table.IsEmpty(stageRewards) then
        RewardApi.AcquireRewardsLogic(stageRewards, EPropertySource.Give, self.m_definition.GetStageReward, EGameMode.Main, CacheItemType.Type2)
      end
      self.cacheStageRewards = stageRewards
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
  if msg.Scene ~= AvenueAddScoreScene.order or self.m_cacheState == ActivityState.Ended then
    EventDispatcher.DispatchEvent(self.m_definition.ScoreChangedEvent, msg)
  end
end

function AvenueModel:GetTotalScore()
  return self.m_dbTable:GetValue(DBKey.Score, DBColumnValue) or 0
end

function AvenueModel:GetScore()
  return self.m_currentScore
end

function AvenueModel:GetLevel()
  return self.m_currentStep
end

function AvenueModel:GetLastDipslayedLevelAndScore()
  local lastDisplayedLevel = self.m_dbTable:GetValue(DBKey.LastDisplayedLevel, DBColumnValue) or 1
  local lastDisplayedScore = self.m_dbTable:GetValue(DBKey.LastDisplayedScore, DBColumnValue) or 0
  return lastDisplayedLevel, lastDisplayedScore
end

function AvenueModel:SetLastDisplayedLevelAndScore(lastDisplayedLevel, lastDisplayedScore)
  self.m_dbTable:Set(DBKey.LastDisplayedLevel, DBColumnValue, lastDisplayedLevel)
  self.m_dbTable:Set(DBKey.LastDisplayedScore, DBColumnValue, lastDisplayedScore)
end

function AvenueModel:GetLastDisplayedStage()
  local LastDisplayedStage = self.m_dbTable:GetValue(DBKey.LastDisplayedStage, DBColumnValue) or 0
  return LastDisplayedStage
end

function AvenueModel:SetLastDisplayedStage(lastDisplayedStage)
  self.m_dbTable:Set(DBKey.LastDisplayedStage, DBColumnValue, lastDisplayedStage)
end

function AvenueModel:GetLevelConfig(level)
  if level <= 0 then
    return
  end
  if level <= #self.m_config.nonLoopAvenueRewards then
    return self.m_config.nonLoopAvenueRewards[level]
  end
  if not Table.IsEmpty(self.m_config.loopAvenueRewards) then
    local loopIdx = (level - #self.m_config.nonLoopAvenueRewards) % #self.m_config.loopAvenueRewards
    if loopIdx == 0 then
      loopIdx = #self.m_config.loopAvenueRewards
    end
    return self.m_config.loopAvenueRewards[loopIdx]
  end
end

function AvenueModel:GetNonLoopFinalLevelConfig()
  return self.m_config.nonLoopAvenueRewards[#self.m_config.nonLoopAvenueRewards]
end

function AvenueModel:IsTokenProperty(propertyType)
  return propertyType == self.m_definition.ActivityTokenPropertyType
end

function AvenueModel:GetTokenPropertyType()
  return self.m_definition.ActivityTokenPropertyType
end

function AvenueModel:GetHudEntryShowConfig()
  return {
    Type = "avenue",
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

function AvenueModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_definition.StateChangedEvent,
      self.m_definition.ScoreChangedEvent
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_avenueEntryNode",
    bubbleCountName = "m_avenueBubbleCount",
    entryPrefabName = self.m_definition.BoardEntryPrefabName,
    scrollToFunName = "ScrollToAvenueBoardEntry",
    activityType = self.m_type,
    checkFun = function()
      return self:CanAddScore()
    end
  }
end

function AvenueModel:GetResourceLabels()
  return self.m_definition.ResourceLabels
end

function AvenueModel:TestAddScore(num)
  self:_AddScore(num, AvenueAddScoreScene.shop, nil)
end
