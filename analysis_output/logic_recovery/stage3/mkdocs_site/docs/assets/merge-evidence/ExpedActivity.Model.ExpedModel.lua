EExpedAddScoreScene = {
  Order = "Order",
  Buy = "Buy",
  Merge = "Merge"
}
local EStrDBKeys = {
  Period = "Period",
  Level = "Level",
  Score = "Score",
  Tokens = "Tokens",
  Round = "Round",
  CurrentInfo = "CurrentInfo",
  LastPeriod = "LastPeriod",
  LastScore = "LastScore",
  LastLevel = "LastLevel",
  LastTokens = "LastTokens",
  LastRound = "LastRound",
  LevelFinishTime = "LevelFinishTime",
  FinishWindowPop = "FinishWindowPop",
  HasPopedMainWindow = "HasPopedMainWindow",
  HasPopedOverallWindow = "HasPopedOverallWindow",
  EndWindowPop = "EndWindowPop",
  HalfTopTipPop = "HalfTopTipPop",
  FiveTopTipPop = "FiveTopTipPop",
  OneTopTipPop = "OneTopTipPop",
  CurLevelTryTimes = "CurLevelTryTimes",
  FailWindowPop = "FailWindowPop",
  Rank = "Rank",
  RecoverRewardsLevel = "RecoverRewardsLevel"
}
ExpedModel = setmetatable({}, BaseActivityModel)
ExpedModel.__index = ExpedModel
ExpedModel.TotalPeriodNum = 4
local DBColumnValue = "value"

function ExpedModel:Init(activityType, dbTable)
  self.m_definition = ExpedDefinition[activityType]
  BaseActivityModel.Init(self, activityType, dbTable)
  self:LoadLocalConfig()
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
end

function ExpedModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_definition.Event_StateChanged)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  if self:GetState(false) == ActivityState.Started and self.m_eventOrderScore then
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty, self, self.m_eventOrderScore, self.m_definition.ScorePropertyType, function(num, scene)
      local addScoreScene = scene == EBIType.FinishOrder and EExpedAddScoreScene.Order or EExpedAddScoreScene.Buy
      self:_AddScore(num, addScoreScene, nil)
    end, function()
      return self:CanAddScore()
    end, nil, true)
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.LogicAcquireReward, self, {
      [self.m_definition.TokenPropertyType] = function(num, scene)
        self:_AcquireStarTokenHandle(num, scene)
      end
    })
  end
end

function ExpedModel:GetServerConfigGroupId()
  return self.m_expedRewardConfig[1][1].groupId
end

function ExpedModel:GetResourceLabels()
  return self.m_definition.ResourceLabels
end

function ExpedModel:_DropData()
  self.m_currentInfo = nil
  BaseActivityModel._DropData(self)
end

function ExpedModel:LoadLocalConfig()
  local strInfo = self.m_dbTable:GetValue(EStrDBKeys.CurrentInfo, DBColumnValue)
  if strInfo ~= nil then
    self.m_currentInfo = json.decode(strInfo)
    if self.m_currentInfo.showIconFrameList == nil then
      self.m_currentInfo.showIconFrameList = UIHelper.GetRandomAvatarIconFrame(#self.m_currentInfo.showIconList)
    end
  end
  local mergeConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_mergeItemScoreConfig = {}
  for _, data in ipairs(mergeConfig) do
    self.m_mergeItemScoreConfig[data.item_id] = data
  end
end

function ExpedModel:_LoadOtherServerConfig(config)
  self.m_robotConfigs = {}
  local robotConfigs = Table.DeepCopy(config.galaxyExped_robot, true)
  for _, cfg in ipairs(robotConfigs) do
    local robotConfig = {
      upgradeSlotsNum = cfg.upgradeSlotsNum,
      maxRobotArriveTime = cfg.maxRobotArriveTime,
      period = cfg.period,
      raceLevel = cfg.raceLevel,
      robotSpeed = {}
    }
    for _, spCfg in ipairs(cfg.robotSpeed) do
      local spConfig = spCfg.values
      local speed = {
        minTime = spConfig[1] * cfg.maxRobotArriveTime * 0.01,
        maxTime = spConfig[2] * cfg.maxRobotArriveTime * 0.01,
        num = spConfig[3]
      }
      table.insert(robotConfig.robotSpeed, speed)
    end
    if self.m_robotConfigs[cfg.period] == nil then
      self.m_robotConfigs[cfg.period] = {}
    end
    self.m_robotConfigs[cfg.period][cfg.raceLevel] = robotConfig
  end
  self.m_extraProgressConfig = {}
  local extraProgressConfig = Table.DeepCopy(config.galaxyExped_extra_progress, true)
  for i, exCfg in ipairs(extraProgressConfig) do
    local cfgItem = {
      round = exCfg.round,
      scoreNum = exCfg.scoreNum,
      reward = exCfg.reward
    }
    table.insert(self.m_extraProgressConfig, cfgItem)
  end
  
  local function progressCfgCompareFunc(aCfg, bCfg)
    return aCfg.round < bCfg.round
  end
  
  table.sort(self.m_extraProgressConfig, progressCfgCompareFunc)
  self.m_expedRewardConfig = {}
  local expedRewardConfig = Table.DeepCopy(config.galaxyExped_reward, true)
  for i, exCfg in ipairs(expedRewardConfig) do
    local cfgItem = {
      period = exCfg.period,
      raceLevel = exCfg.raceLevel,
      target = exCfg.target,
      ifGetScore = exCfg.ifGetScore,
      rewards = exCfg.rewards,
      groupId = exCfg.groupId
    }
    if not self.m_expedRewardConfig[cfgItem.period] then
      self.m_expedRewardConfig[cfgItem.period] = {}
    end
    self.m_expedRewardConfig[cfgItem.period][cfgItem.raceLevel] = cfgItem
  end
  for period = 1, #self.m_expedRewardConfig do
    for level = 1, #self.m_expedRewardConfig[period] - 1 do
      self.m_expedRewardConfig[period][level].rewards = nil
    end
  end
  self.m_eventOrderScore = config.eventOrderScore
end

function ExpedModel:CanAddScore()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_currentInfo == nil then
    return false
  end
  if self:IsAllPeriodFinished() then
    return false
  end
  if self:GetLevel() > self:GetMaxLevel() then
    return false
  end
  if self:GetLevel() > self:GetLastLevel() then
    return false
  end
  if self:GetLevelFinishTime() ~= nil then
    return false
  end
  return true
end

function ExpedModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddMergeScore(message.Source)
  end
end

function ExpedModel:_TryAddMergeScore(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_mergeItemScoreConfig[itemType].merge_score
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, EExpedAddScoreScene.Merge, itemModel)
  end
end

function ExpedModel:IsScoreProperty(propertyType)
  return propertyType == self.m_definition.ScorePropertyType
end

function ExpedModel:_AddScore(addScore, scene, item)
  local level = self:GetLevel()
  local rewardConfig = self:GetRewardConfigByLevel(level, self:GetLastPeriod())
  if rewardConfig == nil then
    return
  end
  if self:GetScore() >= rewardConfig.target then
    return
  end
  local score = math.min(self:GetScore() + addScore, rewardConfig.target)
  self:SetScore(score)
  self:LogActivity(EBIType.ActivityAddScore, GM.BIManager:TableToString({num = addScore, type = scene}))
  EventDispatcher.DispatchEvent(self.m_definition.Event_ScoreChanged, {
    Scene = scene,
    Source = item,
    TokenScore = addScore
  })
  if score >= rewardConfig.target then
    if not ApplicationManager.Instance.isNetworkConnected then
      self:SetLevelFinishTime(GM.GameModel:GetServerTime())
      EventDispatcher.DispatchEvent(self.m_definition.Event_FullScoreWithoutNet)
      return
    end
    self:_LevelUp(level)
  end
end

function ExpedModel:_AcquireStarTokenHandle(num, scene)
  local tarScore = self.m_extraProgressConfig[self:GetRound()].scoreNum
  self:SetTokens(math.min(num + self:GetTokens(), tarScore))
  local biAction = {
    id = self:GetId(),
    round = self:GetRound(),
    getNum = num,
    curNum = self:GetTokens()
  }
  GM.BIManager:LogAction(self.m_definition.GetExtraStarBIType, biAction)
  if self:GetTokens() == tarScore then
    local biAction = {
      id = self:GetId(),
      round = self:GetRound(),
      rwd = self.m_extraProgressConfig[self:GetRound()].reward
    }
    GM.BIManager:LogAction(self.m_definition.GetExtraRewardsBIType, biAction)
    RewardApi.AcquireRewardsLogic(self.m_extraProgressConfig[self:GetRound()].reward, EPropertySource.Give, self.m_definition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
    self:SetRound(self:GetRound() + 1)
    self:SetTokens(0)
  end
end

function ExpedModel:IsAllRoundFinished()
  if self:GetRound() > #self.m_extraProgressConfig then
    return true
  end
  return false
end

function ExpedModel:_LevelUp(level)
  local rank = self.m_currentInfo.finishAliveNum - self.m_currentInfo.curAliveNum + 1
  self:SetRank(rank)
  self:LogLevelEnd(true)
  self:SetLevel(level + 1)
  self:SetRecoverRewardsLevel(level)
  self:RandomDeleteAvatar()
  self.m_currentInfo.arriveTimeList = nil
  self:SaveCurrentInfo()
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  if self:GetLevel() > self:GetMaxLevel() then
    self:LogActivity(EBIType.ActivityRankUp, self:GetPeriod())
    self:SetPeriod(self:GetPeriod() + 1)
  end
  if self:IsAllPeriodFinished() then
    EventDispatcher.DispatchEvent(self.m_definition.Event_FinishedAll)
  end
end

function ExpedModel:LogLevelEnd(bSuccess)
  local biAction = {
    id = self:GetId(),
    r = self:GetPeriod(),
    lv = self:GetLevel(),
    tryNum = self:GetCurLevelTryTimes(),
    isSuccess = bSuccess,
    score = self:GetScore(),
    groupId = self:GetServerConfigGroupId()
  }
  if bSuccess then
    biAction.rank = self:GetRank()
  else
  end
  GM.BIManager:LogAction(self.m_definition.LevelEndBIType, biAction)
end

function ExpedModel:LevelFail()
  self.m_currentInfo = nil
  self:SaveCurrentInfo()
  self:SetScore(0)
  EventDispatcher.DispatchEvent(self.m_definition.Event_Fail)
  self:SetFailWindowPop()
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  self:LogLevelEnd(false)
end

function ExpedModel:SetFailWindowPop()
  self.m_dbTable:Set(EStrDBKeys.FailWindowPop, DBColumnValue, "1")
end

function ExpedModel:CanFailWindowPop()
  return self.m_dbTable:GetValue(EStrDBKeys.FailWindowPop, DBColumnValue) == "1"
end

function ExpedModel:ClearFailWindowPop()
  self.m_dbTable:Set(EStrDBKeys.FailWindowPop, DBColumnValue, "0")
end

function ExpedModel:AcquireRewardsLogic(level, period, isFinalReward)
  self:SetRecoverRewardsLevel(0)
  local conf = self:GetRewardConfigByLevel(level, period)
  local rewards = {}
  if not Table.IsEmpty(conf.rewards) then
    for _, rwd in ipairs(conf.rewards) do
      table.insert(rewards, rwd)
    end
  end
  if conf.ifGetScore == 1 then
    table.insert(rewards, {
      [PROPERTY_COUNT] = 1,
      [PROPERTY_TYPE] = self.m_definition.TokenPropertyType
    })
  end
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_definition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
  if isFinalReward then
    local biAction = {
      id = self:GetId(),
      r = self:GetLastPeriod(),
      rwd = rewards,
      groupId = self:GetServerConfigGroupId()
    }
    GM.BIManager:LogAction(self.m_definition.GetPeriodRewardBIType, biAction)
  end
end

function ExpedModel:GetRecoverRewards()
  local level = self.m_dbTable:GetValue(EStrDBKeys.RecoverRewardsLevel, DBColumnValue)
  if level == nil or level == "0" then
    return nil
  else
    local rewardConfig = self:GetRewardConfigByLevel(level, self:GetLastPeriod())
    if rewardConfig ~= nil then
      if rewardConfig.rewards then
        return rewardConfig.rewards
      end
      if rewardConfig.ifGetScore == 1 and self.m_extraProgressConfig[self:GetLastRound()] then
        local tarScore = self.m_extraProgressConfig[self:GetLastRound()].scoreNum
        self:SetTokens(math.min(1 + self:GetTokens(), tarScore))
        if self:GetTokens() == tarScore then
          return self.m_extraProgressConfig[self:GetLastRound()].reward
        end
      end
    end
  end
end

function ExpedModel:SetRecoverRewardsLevel(level)
  self.m_dbTable:Set(EStrDBKeys.RecoverRewardsLevel, DBColumnValue, level)
end

function ExpedModel:GetRewardConfigByLevel(level, period)
  if Table.IsEmpty(self.m_expedRewardConfig) then
    return
  end
  period = period or self:GetPeriod()
  local rewardConfig = self.m_expedRewardConfig
  if not Table.IsEmpty(rewardConfig) then
    return rewardConfig[period][level]
  end
end

function ExpedModel:GetLastRewardOfPeriod(period)
  if Table.IsEmpty(self.m_expedRewardConfig) then
    return nil
  end
  local rewardConfig = self.m_expedRewardConfig
  return rewardConfig[period][#rewardConfig[period]].rewards
end

function ExpedModel:CanSignUp()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self:IsAllPeriodFinished() then
    return false
  end
  if self.m_currentInfo ~= nil then
    return false
  end
  return true
end

function ExpedModel:GetRobotConfigByLevel(level, period)
  local curPeriod = period
  curPeriod = curPeriod or self:GetPeriod()
  return self.m_robotConfigs[curPeriod][level]
end

function ExpedModel:TrySignUp()
  if self:GetLevel() == 1 then
    self:SignUp(true)
  end
end

function ExpedModel:SignUp(bNewPeriod)
  self:ClearTopTipState()
  local biAction = {
    id = self:GetId(),
    r = self:GetPeriod()
  }
  local level = self:GetLevel()
  if level == 1 then
    GM.BIManager:LogAction(self.m_definition.NewPeriodBIType, biAction)
  end
  self:SetScore(0)
  biAction.lv = level
  biAction.trynum = self:GetCurLevelTryTimes()
  biAction.groupId = self:GetServerConfigGroupId()
  GM.BIManager:LogAction(self.m_definition.LevelStartBIType, biAction)
  local robotConfig = self:GetRobotConfigByLevel(level)
  self.m_currentInfo = {}
  self.m_currentInfo.finishAliveNum = robotConfig.upgradeSlotsNum
  local half = math.ceil(self.m_currentInfo.finishAliveNum * 0.5)
  if half - 1 <= 5 then
    self:PopTopTip(EStrDBKeys.HalfTopTipPop)
  end
  self.m_currentInfo.curAliveNum = self.m_currentInfo.finishAliveNum
  self.m_currentInfo.arriveTimeList = {}
  local time = GM.GameModel:GetServerTime()
  self.m_currentInfo.levelStartTime = time
  for _, cfg in ipairs(robotConfig.robotSpeed) do
    for i = 1, cfg.num do
      local arriveTime = time + math.random(cfg.minTime * 60, cfg.maxTime * 60 - 1)
      table.insert(self.m_currentInfo.arriveTimeList, arriveTime)
    end
  end
  table.sort(self.m_currentInfo.arriveTimeList, function(a, b)
    return b < a
  end)
  self.m_currentInfo.showIconList = {}
  local randomAvatars = {}
  for _, eleAvatad in ipairs(AVATAR_IMAGE) do
    table.insert(randomAvatars, eleAvatad)
  end
  for _, eleAvatar in ipairs(ACTIVITY_AVATAR_IMAGE) do
    table.insert(randomAvatars, eleAvatar)
  end
  self.m_currentInfo.showIconList = Table.ListRandomSelectN(randomAvatars, 6)
  self.m_currentInfo.showIconFrameList = UIHelper.GetRandomAvatarIconFrame(6)
  self:SaveCurrentInfo()
  EventDispatcher.DispatchEvent(self.m_definition.Event_SignUp)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function ExpedModel:RandomDeleteAvatar()
  if self.m_currentInfo.showIconList then
    if self:GetRank() == 1 then
      self.m_currentInfo.deleteIconIndex = {
        6,
        5,
        4,
        3,
        2,
        1
      }
    else
      local upNum = math.random(1, 2)
      self.m_currentInfo.deleteIconIndex = MathUtil.RandomN(#self.m_currentInfo.showIconList, 6 - upNum)
      table.sort(self.m_currentInfo.deleteIconIndex, function(a, b)
        return b < a
      end)
    end
    self:SaveCurrentInfo()
  end
end

function ExpedModel:ClearTopTipState()
  self.m_dbTable:Remove(EStrDBKeys.OneTopTipPop, DBColumnValue)
  self.m_dbTable:Remove(EStrDBKeys.FiveTopTipPop, DBColumnValue)
  self.m_dbTable:Remove(EStrDBKeys.HalfTopTipPop, DBColumnValue)
end

function ExpedModel:PopTopTip(type)
  self.m_dbTable:Set(type, DBColumnValue, "1")
end

function ExpedModel:CanPopTopTip(type)
  return self.m_dbTable:GetValue(type, DBColumnValue) ~= "1"
end

function ExpedModel:CheckTopTip()
  if self.m_currentInfo.curAliveNum <= 0 then
    return
  end
  local half = math.floor(self.m_currentInfo.finishAliveNum * 0.5)
  local tipType, textKey, callBack
  if self.m_currentInfo.curAliveNum <= 1 then
    tipType = EStrDBKeys.OneTopTipPop
    textKey = "galaxyExped_notice_3"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.OneTopTipPop)
      self:PopTopTip(EStrDBKeys.FiveTopTipPop)
    end
  elseif self:GetFinishAliveNum() > 5 and self.m_currentInfo.curAliveNum <= 5 then
    tipType = EStrDBKeys.FiveTopTipPop
    textKey = "galaxyExped_notice_2"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.FiveTopTipPop)
    end
  elseif half > self.m_currentInfo.curAliveNum then
    tipType = EStrDBKeys.HalfTopTipPop
    textKey = "galaxyExped_notice_1"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.HalfTopTipPop)
    end
  end
  if tipType ~= nil and self:CanPopTopTip(tipType) then
    TopSliderManager.TrySlide(SliderType.Exped, self.m_definition.TopTipPrefabName, function(go)
      local model = GM.ActivityManager:GetModel(self:GetType())
      if model == nil or model:GetState() ~= ActivityState.Started or model:GetAliveNum() == nil then
        GameObject.Destroy(go)
        return
      end
      go:GetLuaTable():Init(self:GetType(), textKey)
      TopSliderManager.Appear(go, function()
        callBack()
        DelayExecuteFunc(function()
          TopSliderManager.Disappear(go)
        end, 2.0)
      end)
    end)
  end
end

function ExpedModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self.m_currentInfo == nil then
    return
  end
  if not ApplicationManager.Instance.isNetworkConnected then
    return
  end
  local finishTime = self:GetLevelFinishTime()
  if finishTime ~= nil and not Table.IsEmpty(self.m_currentInfo.arriveTimeList) then
    self.m_dbTable:Remove(EStrDBKeys.LevelFinishTime, DBColumnValue)
    for i = #self.m_currentInfo.arriveTimeList, 1, -1 do
      if finishTime > self.m_currentInfo.arriveTimeList[i] then
        table.remove(self.m_currentInfo.arriveTimeList, i)
        self.m_currentInfo.curAliveNum = self.m_currentInfo.curAliveNum - 1
        if self.m_currentInfo.curAliveNum <= 0 then
          self:LevelFail()
          return
        end
      end
    end
    local level = self:GetLevel()
    self:_LevelUp(level)
    EventDispatcher.DispatchEvent(self.m_definition.Event_LevelUp)
  end
  if not Table.IsEmpty(self.m_currentInfo.arriveTimeList) then
    local time = GM.GameModel:GetServerTime()
    local removeList = {}
    for i = #self.m_currentInfo.arriveTimeList, 1, -1 do
      if time >= self.m_currentInfo.arriveTimeList[i] then
        table.remove(self.m_currentInfo.arriveTimeList, i)
        self.m_currentInfo.curAliveNum = self.m_currentInfo.curAliveNum - 1
        EventDispatcher.DispatchEvent(self.m_definition.Event_RobotArrive)
        if self.m_currentInfo.curAliveNum <= 0 then
          self:LevelFail()
          return
        end
      else
        self:SaveCurrentInfo()
        break
      end
    end
    self:CheckTopTip()
  end
end

function ExpedModel:IsTokenProperty(token)
  for _, def in pairs(ExpedDefinition) do
    if def.ScorePropertyType == token then
      return true
    end
  end
  return false
end

function ExpedModel:GetMaxLevel(period)
  if Table.IsEmpty(self.m_expedRewardConfig) then
    return
  end
  period = period or self:GetLastPeriod()
  return #self.m_expedRewardConfig[period]
end

function ExpedModel:SetPeriod(num)
  self.m_dbTable:Set(EStrDBKeys.Period, DBColumnValue, num)
end

function ExpedModel:GetPeriod()
  return self.m_dbTable:GetValue(EStrDBKeys.Period, DBColumnValue) or 1
end

function ExpedModel:SetLastPeriod(num)
  self.m_dbTable:Set(EStrDBKeys.LastPeriod, DBColumnValue, num)
end

function ExpedModel:GetLastPeriod()
  return self.m_dbTable:GetValue(EStrDBKeys.LastPeriod, DBColumnValue) or 1
end

function ExpedModel:GetLevel()
  return self.m_dbTable:GetValue(EStrDBKeys.Level, DBColumnValue) or 1
end

function ExpedModel:SetLevel(num)
  self.m_dbTable:Set(EStrDBKeys.Level, DBColumnValue, num)
end

function ExpedModel:GetScore()
  return self.m_dbTable:GetValue(EStrDBKeys.Score, DBColumnValue) or 0
end

function ExpedModel:SetScore(num)
  self.m_dbTable:Set(EStrDBKeys.Score, DBColumnValue, num)
end

function ExpedModel:GetLastScore()
  return self.m_dbTable:GetValue(EStrDBKeys.LastScore, DBColumnValue) or 0
end

function ExpedModel:SetLastScore(num)
  self.m_dbTable:Set(EStrDBKeys.LastScore, DBColumnValue, num)
end

function ExpedModel:GetLastLevel()
  return self.m_dbTable:GetValue(EStrDBKeys.LastLevel, DBColumnValue) or 1
end

function ExpedModel:SetLastLevel(num)
  self.m_dbTable:Set(EStrDBKeys.LastLevel, DBColumnValue, num)
end

function ExpedModel:IsAllPeriodFinished()
  return self:GetPeriod() > ExpedModel.TotalPeriodNum
end

function ExpedModel:GetCurrentInfo()
  return Table.ShallowCopy(self.m_currentInfo)
end

function ExpedModel:SaveCurrentInfo()
  if self.m_currentInfo == nil then
    self.m_dbTable:Remove(EStrDBKeys.CurrentInfo, DBColumnValue)
  else
    self.m_dbTable:Set(EStrDBKeys.CurrentInfo, DBColumnValue, json.encode(self.m_currentInfo))
  end
end

function ExpedModel:SetLevelFinishTime(time)
  self.m_dbTable:Set(EStrDBKeys.LevelFinishTime, DBColumnValue, time)
end

function ExpedModel:GetLevelFinishTime()
  return self.m_dbTable:GetValue(EStrDBKeys.LevelFinishTime, DBColumnValue)
end

function ExpedModel:GetAliveNum()
  return self.m_currentInfo and self.m_currentInfo.curAliveNum or nil
end

function ExpedModel:GetFinishAliveNum()
  if self.m_currentInfo ~= nil then
    return self.m_currentInfo.finishAliveNum
  else
    local robotConfig = self:GetRobotConfigByLevel(self:GetLevel())
    return robotConfig.upgradeSlotsNum
  end
end

function ExpedModel:GetBigReward(period)
  if Table.IsEmpty(self.m_expedRewardConfig) then
    return
  end
  local rewardConfig = self.m_expedRewardConfig
  local curPeriod = period
  curPeriod = curPeriod or self:GetPeriod()
  return rewardConfig[curPeriod][#rewardConfig[curPeriod]].rewards
end

function ExpedModel:WaitingBanner(isWaiting)
  self.m_isWaitingBanner = isWaiting
end

function ExpedModel:IfWaitingBanner()
  return self.m_isWaitingBanner
end

function ExpedModel:GetExtraProgressData(round)
  return self.m_extraProgressConfig[round]
end

function ExpedModel:GetRank()
  return self.m_dbTable:GetValue(EStrDBKeys.Rank, DBColumnValue)
end

function ExpedModel:SetRank(rank)
  self.m_dbTable:Set(EStrDBKeys.Rank, DBColumnValue, rank)
end

function ExpedModel:SetRound(round)
  self.m_dbTable:Set(EStrDBKeys.Round, DBColumnValue, round)
end

function ExpedModel:GetRound()
  return self.m_dbTable:GetValue(EStrDBKeys.Round, DBColumnValue) or 1
end

function ExpedModel:GetTokens()
  return self.m_dbTable:GetValue(EStrDBKeys.Tokens, DBColumnValue) or 0
end

function ExpedModel:SetTokens(tokenNum)
  self.m_dbTable:Set(EStrDBKeys.Tokens, DBColumnValue, tokenNum)
end

function ExpedModel:GetLastRound()
  return self.m_dbTable:GetValue(EStrDBKeys.LastRound, DBColumnValue) or 1
end

function ExpedModel:SetLastRound(lastRound)
  self.m_dbTable:Set(EStrDBKeys.LastRound, DBColumnValue, lastRound)
end

function ExpedModel:GetLastTokens()
  return self.m_dbTable:GetValue(EStrDBKeys.LastTokens, DBColumnValue) or 0
end

function ExpedModel:SetLastTokens(LastTokens)
  self.m_dbTable:Set(EStrDBKeys.LastTokens, DBColumnValue, LastTokens)
end

function ExpedModel:GetDeleteAvatarIndexes()
  return self.m_currentInfo and self.m_currentInfo.deleteIconIndex or nil
end

function ExpedModel:ClearCurrentPlayState()
  self:SetLastLevel(self:GetLevel())
  self:SetLastScore(0)
  self:SetScore(0)
  self:SetLastRound(self:GetRound())
  self:SetLastTokens(self:GetTokens())
  self.m_currentInfo = nil
  self:SaveCurrentInfo()
  if self:GetPeriod() > self:GetLastPeriod() then
    self:SetLevel(1)
    self:SetLastLevel(1)
  end
end

function ExpedModel:CanPopOverallWindow()
  if not self:IsAllPeriodFinished() and self:HasWindowOpenedOnce(ActivityState.Started) and self:GetLastPeriod() ~= self:GetPeriod() then
    return true
  end
  if not self:HasPopedOverallWindow() then
    return true
  end
  return false
end

function ExpedModel:PopFinishWindow()
  self.m_dbTable:Set(EStrDBKeys.FinishWindowPop, DBColumnValue, "1")
end

function ExpedModel:CanPopFinishWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.FinishWindowPop, DBColumnValue) ~= "1"
end

function ExpedModel:PopEndWindow()
  self.m_dbTable:Set(EStrDBKeys.EndWindowPop, DBColumnValue, "1")
end

function ExpedModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.EndWindowPop, DBColumnValue) ~= "1"
end

function ExpedModel:SetPopedMainWindow(hasOpened)
  self.m_dbTable:Set(EStrDBKeys.HasPopedMainWindow, DBColumnValue, hasOpened and "1" or "0")
end

function ExpedModel:IfPopedMainWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.HasPopedMainWindow, DBColumnValue) == "1"
end

function ExpedModel:SetPopedOverallWindow(status)
  self.m_dbTable:Set(EStrDBKeys.HasPopedOverallWindow, DBColumnValue, status)
end

function ExpedModel:HasPopedOverallWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.HasPopedOverallWindow, DBColumnValue) or false
end

function ExpedModel:SetCurLevelTryTimes(num)
  self.m_dbTable:Set(EStrDBKeys.CurLevelTryTimes, DBColumnValue, num)
end

function ExpedModel:GetCurLevelTryTimes()
  return self.m_dbTable:GetValue(EStrDBKeys.CurLevelTryTimes, DBColumnValue) or 1
end

function ExpedModel:CanShowRedPoint()
  return self:CanSignUp() or self:GetLevelFinishTime() ~= nil
end

function ExpedModel:GetHudEntryShowConfig()
  return {
    Type = "exped",
    ArrCheckShowEvent = {
      self.m_definition.Event_StateChanged,
      self.m_definition.Event_FinishedAll
    },
    EntryPrefabConfigName = self.m_definition.HudEntryPrefabName,
    CheckFunc = function()
      return self:GetState() == ActivityState.Started and not self:IsAllPeriodFinished()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_definition.EntryButtonKey,
    EntryIconName = self.m_definition.EntryIconName,
    OnClickedFunc = function()
      if not ApplicationManager.Instance.isNetworkConnected then
        GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
        return
      end
      local state = self:GetState()
      local currentInfo = self:GetCurrentInfo()
      if state == ActivityState.Started then
        if self:GetLevelFinishTime() then
          GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
          if GameConfig.IsTestMode() then
            Log.Info("\232\191\158\233\151\175\239\188\154\229\129\135\228\186\186\232\191\152\230\156\170\229\136\183\230\150\176\239\188\140\230\151\160\230\179\149\230\137\147\229\188\128\228\184\187\231\149\140\233\157\162")
          end
          return
        end
        GM.UIManager:OpenView(self.m_definition.MainWindowPrefabName, self:GetType(), false)
      end
    end,
    RedPointType = EntryRedPointType.Exc,
    GetRedPointNumFunc = function()
      return self:CanShowRedPoint() and 1 or 0
    end,
    ArrUpdateEntryContentEvent = {
      self.m_definition.Event_SignUp,
      self.m_definition.Event_ScoreChanged,
      self.m_definition.Event_WaitSignUp,
      self.m_definition.Event_RobotArrive,
      self.m_definition.Event_Fail,
      self.m_definition.Event_FullScoreWithoutNet
    }
  }
end

function ExpedModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_definition.Event_FinishedAll,
      self.m_definition.Event_StateChanged
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_expedEntryNode",
    bubbleCountName = "m_expedBubbleCount",
    entryPrefabName = self.m_definition.BoardEntryPrefabName,
    scrollToFunName = "ScrollToExpedBoardEntry",
    activityType = self:GetType(),
    checkFun = function()
      return self:GetState() == ActivityState.Started and not self:IsAllPeriodFinished()
    end
  }
end

function ExpedModel:SwitchBanner(isOn)
  if isOn then
    self.m_BannerSwitch = true
  else
    self.m_BannerSwitch = false
    EventDispatcher.DispatchEvent(self.m_definition.Event_BannerDisappear)
  end
end

function ExpedModel:IfBannerOn()
  return self.m_BannerSwitch == true
end

function ExpedModel:TEST_Restart()
end

function ExpedModel:TestAddScore(num)
  self:_AddScore(num, "test")
end

function ExpedModel:TestLevelUp()
  local level = self:GetLevel()
  local rewardConfig = self:GetRewardConfigByLevel(level, self:GetLastPeriod())
  if rewardConfig == nil then
    return
  end
  self:_AddScore(rewardConfig.target, "test")
end

function ExpedModel:Test2LastLevel()
  local maxLevel = self:GetMaxLevel()
  self:SetLevel(maxLevel)
  self:SetLastLevel(maxLevel)
  self:SetScore(0)
  self:SetLastScore(0)
  self:SignUp(false)
end

function ExpedModel:TestFly2SpecPlanet(period)
  self:SetLevel(1)
  self:SetLastLevel(1)
  self:SetScore(0)
  self:SetLastScore(0)
  self:SetPeriod(period)
  self:SetLastPeriod(period)
  self.m_currentInfo = nil
  self:SaveCurrentInfo()
end

function ExpedModel:GetTestPopupWindowConfig()
  return {
    CheckFunc = function()
      return true
    end,
    config = {
      GroupName = "\230\152\159\233\153\133\232\191\156\229\190\129(Exped)",
      WindowList = {
        {
          BtnName = "end",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.EndWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "fail",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.FailWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "finish",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.FinishWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "help",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.HelpWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "overall",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.OverallWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "ready",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.ReadyWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "main",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.MainWindowPrefabName, self:GetType(), false)
          end
        }
      }
    }
  }
end
