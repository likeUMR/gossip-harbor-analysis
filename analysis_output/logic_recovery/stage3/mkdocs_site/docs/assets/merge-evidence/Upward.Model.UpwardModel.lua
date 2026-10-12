EUpwardAddScoreScene = {Merge = "Merge", Order = "Order"}
EUpwardDifficultyMode = {
  None = 0,
  Easy = 1,
  Normal = 2,
  Hard = 3
}
local EStrDBKeys = {
  Round = "Round",
  Level = "Level",
  Score = "Score",
  Difficulty = "Difficulty",
  CurrentInfo = "CurrentInfo",
  LastScore = "LastScore",
  LastLevel = "LastLevel",
  LevelFinishTime = "LevelFinishTime",
  FinishWindowPop = "FinishWindowPop",
  EndWindowPop = "EndWindowPop",
  HalfTopTipPop = "HalfTopTipPop",
  FiveTopTipPop = "FiveTopTipPop",
  OneTopTipPop = "OneTopTipPop",
  CurLevelTryTimes = "CurLevelTryTimes",
  FailWindowPop = "FailWindowPop",
  Rank = "Rank",
  RecoverRewardsLevel = "RecoverRewardsLevel"
}
UpwardModel = setmetatable({}, BaseActivityModel)
UpwardModel.__index = UpwardModel
local DBColumnValue = "value"

function UpwardModel:Init(activityType, dbTable)
  self.m_definition = UpwardDefinition[activityType]
  BaseActivityModel.Init(self, activityType, dbTable)
  self:LoadLocalConfig()
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
end

function UpwardModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_definition.Event_StateChanged)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function UpwardModel:GetResourceLabels()
  return {
    AddressableLabel.UnderseaUpward
  }
end

function UpwardModel:_DropData()
  self.m_currentInfo = nil
  self.m_selectWindowPop = nil
  BaseActivityModel._DropData(self)
end

function UpwardModel:LogActivity(scene, action, isFinalReward)
  local round = self:GetRound()
  if isFinalReward then
    round = round - 1
  end
  local biType = self.m_type .. "_" .. round
  GM.BIManager:LogActivity(biType, self:GetId(), scene, action)
end

function UpwardModel:LoadLocalConfig()
  local strInfo = self.m_dbTable:GetValue(EStrDBKeys.CurrentInfo, DBColumnValue)
  if strInfo ~= nil then
    self.m_currentInfo = json.decode(strInfo)
    if self.m_currentInfo.showIconFrameList == nil then
      self.m_currentInfo.showIconFrameList = UIHelper.GetRandomAvatarIconFrame(#self.m_currentInfo.showIconList)
    end
  end
end

function UpwardModel:_LoadOtherServerConfig(config)
  local mergeConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_mergeItemScoreConfig = {}
  for _, data in ipairs(mergeConfig) do
    self.m_mergeItemScoreConfig[data.item_id] = data
  end
  self.m_finishOrderScoreConfig = {}
  local isUseDiff = false
  for _, cfg in pairs(config.eventOrderScore) do
    table.insert(self.m_finishOrderScoreConfig, Table.DeepCopy(cfg, true))
    if not isUseDiff and IsNumber(cfg.diff_score_min) then
      isUseDiff = true
    end
  end
  self.m_bUseDiff = isUseDiff
  if isUseDiff then
    table.sort(self.m_finishOrderScoreConfig, function(a, b)
      return a.diff_score_min < b.diff_score_min
    end)
  else
    table.sort(self.m_finishOrderScoreConfig, function(a, b)
      return a.gold_min < b.gold_min
    end)
  end
  if config.floatRaceConfig[1].isDifficultySelect == 0 then
    self.m_bDifficultySelect = false
  elseif config.floatRaceConfig[1].isDifficultySelect == 1 then
    self.m_bDifficultySelect = true
  end
  self.m_roundCount = config.floatRaceConfig[1].round
  
  local function sortFunc(a, b)
    if a.difficultyMode == b.difficultyMode then
      return a.raceLevel < b.raceLevel
    else
      return a.difficultyMode < b.difficultyMode
    end
  end
  
  self.m_rewardConfigs = {}
  local rewardConfigs = Table.DeepCopy(config.floatRaceReward, true)
  if self.m_bDifficultySelect then
    table.sort(rewardConfigs, sortFunc)
  end
  for _, cfg in ipairs(rewardConfigs) do
    if cfg.difficultyMode == nil then
      cfg.difficultyMode = EUpwardDifficultyMode.None
    end
    if self.m_rewardConfigs[cfg.difficultyMode] == nil then
      self.m_rewardConfigs[cfg.difficultyMode] = {}
    end
    local rewardConfig = {
      target = cfg.target,
      rewards = cfg.rewards
    }
    self.m_rewardConfigs[cfg.difficultyMode][cfg.raceLevel] = rewardConfig
  end
  self.m_robotConfigs = {}
  local robotConfigs = Table.DeepCopy(config.floatRaceRobot, true)
  if self.m_bDifficultySelect then
    table.sort(robotConfigs, sortFunc)
  end
  for _, cfg in ipairs(robotConfigs) do
    if cfg.difficultyMode == nil then
      cfg.difficultyMode = 0
    end
    if self.m_robotConfigs[cfg.difficultyMode] == nil then
      self.m_robotConfigs[cfg.difficultyMode] = {}
    end
    local robotConfig = {
      upgradeSlotsNum = cfg.upgradeSlotsNum,
      maxRobotArriveTime = cfg.maxRobotArriveTime,
      robotSpeed = {}
    }
    for _, spCfg in ipairs(cfg.robotSpeed) do
      local spConfig = StringUtil.Split(spCfg, ",")
      if tonumber(spConfig[1]) == 0 or tonumber(spConfig[2]) == 0 or spConfig[1] >= spConfig[2] then
        GM.BIManager:LogErrorInfo(self.m_definition.RobotConfigErrorBIType, string.format("robot config: min=%s, max=%s", spConfig[1], spConfig[2]))
      end
      local speed = {
        minTime = spConfig[1] * cfg.maxRobotArriveTime,
        maxTime = spConfig[2] * cfg.maxRobotArriveTime,
        num = spConfig[3]
      }
      table.insert(robotConfig.robotSpeed, speed)
    end
    self.m_robotConfigs[cfg.difficultyMode][cfg.raceLevel] = robotConfig
  end
end

function UpwardModel:CanAddScore()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_currentInfo == nil then
    return false
  end
  if self:GetRound() > self.m_roundCount then
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

function UpwardModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddMergeScore(message.Source)
  end
end

function UpwardModel:_TryAddMergeScore(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_mergeItemScoreConfig[itemType].merge_score
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, EUpwardAddScoreScene.Merge, itemModel)
  end
end

function UpwardModel:GetAddScoreByOrder(order)
  if not self:CanAddScore() then
    return
  end
  local selectedIdx, score
  if self.m_bUseDiff then
    local diffScore = order:GetDiffScore()
    if diffScore == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_finishOrderScoreConfig, diffScore, "diff_score_min", "diff_score_max")
    score = diffScore
  else
    local price = order:GetPrice()
    if price == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_finishOrderScoreConfig, price, "gold_min", "gold_max")
    score = price
  end
  if selectedIdx == nil then
    return
  end
  local selected = self.m_finishOrderScoreConfig[selectedIdx]
  local count = selected.reward_num_percentage and math.floor(score * selected.reward_num_percentage / 10000) or selected.reward_num_fix
  if count <= 0 then
    return
  end
  return {
    [PROPERTY_TYPE] = self.m_definition.ActivityTokenPropertyType,
    [PROPERTY_COUNT] = count
  }
end

function UpwardModel:AcquireActivityToken(num)
  self:_AddScore(num, EUpwardAddScoreScene.Order, nil)
end

function UpwardModel:GetTokenPropertyType()
  return self.m_definition.ActivityTokenPropertyType
end

function UpwardModel:IsTokenProperty(propertyType)
  return propertyType == self.m_definition.ActivityTokenPropertyType
end

function UpwardModel:_AddScore(addScore, scene, item)
  local level = self:GetLevel()
  local rewardConfig = self:GetRewardCongfigByLevel(level)
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

function UpwardModel:_LevelUp(level)
  local rank = self.m_currentInfo.finishAliveNum - self.m_currentInfo.curAliveNum + 1
  self:SetRank(rank)
  self:LogLevelEnd(true)
  self:SetLevel(level + 1)
  self:LogActivity(EBIType.ActivityRankUp, level == self:GetMaxLevel() and 0 or level)
  self:SetRecoverRewardsLevel(level)
  self:RandomDeleteAvatar()
  self.m_currentInfo.arriveTimeList = nil
  self:SaveCurrentInfo()
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  if level + 1 > self:GetMaxLevel() then
    self:SetRound(self:GetRound() + 1)
  end
  if self:GetRound() > self.m_roundCount then
    EventDispatcher.DispatchEvent(self.m_definition.Event_FinishedAll)
  end
end

function UpwardModel:LogLevelEnd(bSuccess)
  local biAction = {
    id = self:GetId(),
    r = self:GetRound(),
    lv = self:GetLevel(),
    diff = self:GetDifficultyMode(),
    tryNum = self:GetCurLevelTryTimes(),
    isSuccess = bSuccess,
    score = self:GetScore()
  }
  if bSuccess then
    biAction.rank = self:GetRank()
    self:SetCurLevelTryTimes(1)
  else
    self:SetCurLevelTryTimes(biAction.tryNum + 1)
  end
  GM.BIManager:LogAction(self.m_definition.LevelEndBIType, biAction)
end

function UpwardModel:LevelFail()
  self:LogLevelEnd(false)
  self.m_currentInfo = nil
  self:SaveCurrentInfo()
  self:SetScore(0)
  EventDispatcher.DispatchEvent(self.m_definition.Event_Fail)
  self.m_dbTable:Set(EStrDBKeys.FailWindowPop, DBColumnValue, "1")
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function UpwardModel:CanFailWindowPop()
  return self.m_dbTable:GetValue(EStrDBKeys.FailWindowPop, DBColumnValue) == "1"
end

function UpwardModel:ClearFailWindowPop()
  self.m_dbTable:Set(EStrDBKeys.FailWindowPop, DBColumnValue, "0")
end

function UpwardModel:AcquireRewardsLogic(level, isFinalReward)
  self:SetRecoverRewardsLevel(0)
  RewardApi.AcquireRewardsLogic(self:GetRewardCongfigByLevel(level).rewards, EPropertySource.Give, self.m_definition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
  self:LogActivity(EBIType.ActivityGetRewards, level == self:GetMaxLevel() and 0 or level, isFinalReward)
end

function UpwardModel:GetRecoverRewards()
  local level = self.m_dbTable:GetValue(EStrDBKeys.RecoverRewardsLevel, DBColumnValue)
  if level == nil or level == "0" then
    return nil
  else
    local rewardConfig = self:GetRewardCongfigByLevel(level)
    if rewardConfig ~= nil then
      return rewardConfig.rewards
    end
  end
end

function UpwardModel:SetRecoverRewardsLevel(level)
  self.m_dbTable:Set(EStrDBKeys.RecoverRewardsLevel, DBColumnValue, level)
end

function UpwardModel:GetRewardCongfigByLevel(level)
  if Table.IsEmpty(self.m_rewardConfigs) then
    return
  end
  local selectedDif = self:GetDifficultyMode()
  local rewardConfig = self.m_rewardConfigs[selectedDif]
  if not Table.IsEmpty(rewardConfig) then
    return rewardConfig[level]
  end
end

function UpwardModel:CanSignUp()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self:GetRound() > self.m_roundCount then
    return false
  end
  if self.m_currentInfo == nil then
    return true
  end
end

function UpwardModel:CanSelectDifficulty()
  return self.m_bDifficultySelect
end

function UpwardModel:GetRobotConfigByDiffAndLevel(diff, level)
  return self.m_robotConfigs[diff][level]
end

function UpwardModel:TrySignUp()
  if not self.m_bDifficultySelect and self:GetLevel() == 1 and self:GetRound() == 1 then
    self:SignUp(true)
  end
end

function UpwardModel:SignUp(bNewRound, difficultyMode)
  self:ClearTopTipState()
  local diff
  if bNewRound then
    diff = difficultyMode ~= nil and difficultyMode or EUpwardDifficultyMode.None
    self:SetDifficultyMode(diff)
  else
    diff = self:GetDifficultyMode()
  end
  local biAction = {
    id = self:GetId(),
    r = self:GetRound(),
    diff = diff
  }
  local level = self:GetLevel()
  if level == 1 then
    GM.BIManager:LogAction(self.m_definition.NewRoundBIType, biAction)
  end
  self:SetScore(0)
  biAction.lv = level
  biAction.trynum = self:GetCurLevelTryTimes()
  GM.BIManager:LogAction(self.m_definition.LevelStartBIType, biAction)
  local robotConfig = self:GetRobotConfigByDiffAndLevel(diff, level)
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
      if cfg.minTime == 0 or cfg.minTime == 0 or cfg.minTime >= cfg.maxTime then
        GM.BIManager:LogErrorInfo(self.m_definition.RobotConfigErrorBIType, string.format("robot sign up: min=%s, max=%s", cfg.minTime, cfg.maxTime))
      end
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

function UpwardModel:RandomDeleteAvatar()
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

function UpwardModel:ClearTopTipState()
  self.m_dbTable:Remove(EStrDBKeys.OneTopTipPop, DBColumnValue)
  self.m_dbTable:Remove(EStrDBKeys.FiveTopTipPop, DBColumnValue)
  self.m_dbTable:Remove(EStrDBKeys.HalfTopTipPop, DBColumnValue)
end

function UpwardModel:PopTopTip(type)
  self.m_dbTable:Set(type, DBColumnValue, "1")
end

function UpwardModel:CanPopTopTip(type)
  return self.m_dbTable:GetValue(type, DBColumnValue) ~= "1"
end

function UpwardModel:CheckTopTip()
  if self.m_currentInfo.curAliveNum <= 0 then
    return
  end
  local half = math.floor(self.m_currentInfo.finishAliveNum * 0.5)
  local tipType, textKey, callBack
  if self.m_currentInfo.curAliveNum <= 1 then
    tipType = EStrDBKeys.OneTopTipPop
    textKey = "Upward_notice_3"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.OneTopTipPop)
      self:PopTopTip(EStrDBKeys.FiveTopTipPop)
    end
  elseif self.m_currentInfo.curAliveNum <= 5 then
    tipType = EStrDBKeys.FiveTopTipPop
    textKey = "Upward_notice_2"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.FiveTopTipPop)
    end
  elseif half > self.m_currentInfo.curAliveNum then
    tipType = EStrDBKeys.HalfTopTipPop
    textKey = "Upward_notice_1"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.HalfTopTipPop)
    end
  end
  if tipType ~= nil and self:CanPopTopTip(tipType) then
    TopSliderManager.TrySlide(self:GetType(), self.m_definition.TopTipPrefabName, function(go)
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

function UpwardModel:UpdatePerSecond()
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

function UpwardModel:GetMaxLevel()
  if Table.IsEmpty(self.m_rewardConfigs) then
    return
  end
  local selectedDif = self:GetDifficultyMode()
  return #self.m_rewardConfigs[selectedDif]
end

function UpwardModel:SetRound(num)
  self.m_dbTable:Set(EStrDBKeys.Round, DBColumnValue, num)
end

function UpwardModel:GetRound()
  return self.m_dbTable:GetValue(EStrDBKeys.Round, DBColumnValue) or 1
end

function UpwardModel:GetLevel()
  return self.m_dbTable:GetValue(EStrDBKeys.Level, DBColumnValue) or 1
end

function UpwardModel:SetLevel(num)
  self.m_dbTable:Set(EStrDBKeys.Level, DBColumnValue, num)
end

function UpwardModel:GetScore()
  return self.m_dbTable:GetValue(EStrDBKeys.Score, DBColumnValue) or 0
end

function UpwardModel:SetScore(num)
  self.m_dbTable:Set(EStrDBKeys.Score, DBColumnValue, num)
end

function UpwardModel:SetDifficultyMode(mode)
  self.m_dbTable:Set(EStrDBKeys.Difficulty, DBColumnValue, mode)
end

function UpwardModel:GetDifficultyMode()
  return self.m_dbTable:GetValue(EStrDBKeys.Difficulty, DBColumnValue) or EUpwardDifficultyMode.None
end

function UpwardModel:GetLastScore()
  return self.m_dbTable:GetValue(EStrDBKeys.LastScore, DBColumnValue) or 0
end

function UpwardModel:SetLastScore(num)
  self.m_dbTable:Set(EStrDBKeys.LastScore, DBColumnValue, num)
end

function UpwardModel:GetLastLevel()
  return self.m_dbTable:GetValue(EStrDBKeys.LastLevel, DBColumnValue) or 1
end

function UpwardModel:SetLastLevel(num)
  self.m_dbTable:Set(EStrDBKeys.LastLevel, DBColumnValue, num)
end

function UpwardModel:IsAllRoundFinished()
  if self.m_config == nil then
    return false
  else
    return self:GetRound() > self.m_roundCount
  end
end

function UpwardModel:GetCurrentInfo()
  return Table.ShallowCopy(self.m_currentInfo)
end

function UpwardModel:SaveCurrentInfo()
  if self.m_currentInfo == nil then
    self.m_dbTable:Remove(EStrDBKeys.CurrentInfo, DBColumnValue)
  else
    self.m_dbTable:Set(EStrDBKeys.CurrentInfo, DBColumnValue, json.encode(self.m_currentInfo))
  end
end

function UpwardModel:SetLevelFinishTime(time)
  self.m_dbTable:Set(EStrDBKeys.LevelFinishTime, DBColumnValue, time)
end

function UpwardModel:GetLevelFinishTime()
  return self.m_dbTable:GetValue(EStrDBKeys.LevelFinishTime, DBColumnValue)
end

function UpwardModel:GetAliveNum()
  return self.m_currentInfo and self.m_currentInfo.curAliveNum or nil
end

function UpwardModel:GetFinishAliveNum()
  if self.m_currentInfo ~= nil then
    return self.m_currentInfo.finishAliveNum
  else
    local robotConfig = self:GetRobotConfigByDiffAndLevel(self:GetDifficultyMode(), self:GetLevel())
    return robotConfig.upgradeSlotsNum
  end
end

function UpwardModel:GetBigRewardByDiff(diff)
  if Table.IsEmpty(self.m_rewardConfigs) then
    return
  end
  local rewardConfig = self.m_rewardConfigs[diff]
  if Table.IsEmpty(self.m_rewardConfigs) then
    return
  end
  return rewardConfig[#rewardConfig].rewards
end

function UpwardModel:GetRank()
  return self.m_dbTable:GetValue(EStrDBKeys.Rank, DBColumnValue)
end

function UpwardModel:SetRank(rank)
  self.m_dbTable:Set(EStrDBKeys.Rank, DBColumnValue, rank)
end

function UpwardModel:GetDeleteAvatarIndexs()
  return self.m_currentInfo and self.m_currentInfo.deleteIconIndex or nil
end

function UpwardModel:ClearCurrentPlayState()
  self:SetLastLevel(self:GetLevel())
  self:SetLastScore(0)
  self:SetScore(0)
  self.m_currentInfo = nil
  self:SaveCurrentInfo()
  if self:GetLevel() > self:GetMaxLevel() then
    self:SetDifficultyMode(EUpwardDifficultyMode.None)
    self:SetLevel(1)
    self:SetLastLevel(1)
  end
end

function UpwardModel:PopFinishWindow()
  self.m_dbTable:Set(EStrDBKeys.FinishWindowPop, DBColumnValue, "1")
end

function UpwardModel:CanPopFinishWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.FinishWindowPop, DBColumnValue) ~= "1"
end

function UpwardModel:PopEndWindow()
  self.m_dbTable:Set(EStrDBKeys.EndWindowPop, DBColumnValue, "1")
end

function UpwardModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.EndWindowPop, DBColumnValue) ~= "1"
end

function UpwardModel:CanPopSelectWindow()
  return self:CanSelectDifficulty() and self:GetDifficultyMode() == EUpwardDifficultyMode.None and self.m_selectWindowPop ~= true
end

function UpwardModel:PopSelectWindow()
  self.m_selectWindowPop = true
end

function UpwardModel:SetCurLevelTryTimes(num)
  self.m_dbTable:Set(EStrDBKeys.CurLevelTryTimes, DBColumnValue, num)
end

function UpwardModel:GetCurLevelTryTimes()
  return self.m_dbTable:GetValue(EStrDBKeys.CurLevelTryTimes, DBColumnValue) or 1
end

function UpwardModel:CanShowRedPoint()
  return self:CanSignUp() or self:GetLevelFinishTime() ~= nil
end

function UpwardModel:GetHudEntryShowConfig()
  return {
    Type = "upward",
    ArrCheckShowEvent = {
      self.m_definition.Event_StateChanged,
      self.m_definition.Event_FinishedAll
    },
    EntryPrefabConfigName = self.m_definition.HudEntryPrefabName,
    CheckFunc = function()
      return self:GetState() == ActivityState.Preparing or self:GetState() == ActivityState.Started and not self:IsAllRoundFinished()
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
      if state == ActivityState.Preparing then
        GM.UIManager:OpenView(self.m_definition.NoticeWindowPrefabName, self:GetType())
      end
      local currentInfo = self:GetCurrentInfo()
      if state == ActivityState.Started then
        if self:CanSelectDifficulty() and self:GetDifficultyMode() == EUpwardDifficultyMode.None then
          GM.UIManager:OpenView(self.m_definition.SelectWindowPrefabName, self:GetType(), false)
        else
          if self:GetLevelFinishTime() then
            GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
            if GameConfig.IsTestMode() then
              Log.Info("\232\191\158\233\151\175\239\188\154\229\129\135\228\186\186\232\191\152\230\156\170\229\136\183\230\150\176\239\188\140\230\151\160\230\179\149\230\137\147\229\188\128\228\184\187\231\149\140\233\157\162")
            end
            return
          end
          GM.UIManager:OpenView(self.m_definition.MainWindowPrefabName, self:GetType(), false)
        end
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

function UpwardModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_definition.Event_FinishedAll,
      self.m_definition.Event_StateChanged
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_upwardEntryNode",
    bubbleCountName = "m_upwardBubbleCount",
    entryPrefabName = self.m_definition.BoardEntryPrefabName,
    scrollToFunName = "ScrollToUpwardBoardEntry",
    activityType = self:GetType(),
    checkFun = function()
      return self:GetState() == ActivityState.Started and not self:IsAllRoundFinished()
    end
  }
end

function UpwardModel:TestAddScore(num)
  self:_AddScore(num, "test")
end

function UpwardModel:TestLevelUp()
  local level = self:GetLevel()
  local rewardConfig = self:GetRewardCongfigByLevel(level)
  if rewardConfig == nil then
    return
  end
  self:_AddScore(rewardConfig.target, "test")
end

function UpwardModel:Test2LastLevel()
  local maxLevel = self:GetMaxLevel()
  self:SetLevel(maxLevel)
  self:SetLastLevel(maxLevel)
  self:SetScore(0)
  self:SetLastScore(0)
  self:SignUp(false)
end

function UpwardModel:GetTestPopupWindowConfig()
  return {
    CheckFunc = function()
      return true
    end,
    config = {
      GroupName = "\230\181\183\229\186\149\232\191\158\233\151\175(Upward)",
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
          BtnName = "newround",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.NewRoundWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "notice",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.NoticeWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "ready",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.ReadyWindowPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "select",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_definition.SelectWindowPrefabName, self:GetType(), false)
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
