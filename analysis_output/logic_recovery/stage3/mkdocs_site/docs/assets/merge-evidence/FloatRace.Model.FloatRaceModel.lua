EFloatRaceAddScoreScene = {Merge = "Merge", Order = "Order"}
EFloatRaceDifficultyMode = {
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
FloatRaceModel = setmetatable({}, BaseActivityModel)
FloatRaceModel.__index = FloatRaceModel

function FloatRaceModel:Init(virtualDBTable)
  BaseActivityModel.Init(self, ActivityType.FloatRace, virtualDBTable)
  self:LoadLocalConfig()
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
end

function FloatRaceModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(EEventType.FloatRaceStateChanged)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function FloatRaceModel:GetResourceLabels()
  return {
    AddressableLabel.FloatRace
  }
end

function FloatRaceModel:_DropData()
  self.m_currentInfo = nil
  self.m_selectWindowPop = nil
  BaseActivityModel._DropData(self)
end

function FloatRaceModel:LogActivity(scene, action, isFinalReward)
  local round = self:GetRound()
  if isFinalReward then
    round = round - 1
  end
  local biType = self.m_type .. "_" .. round
  GM.BIManager:LogActivity(biType, self:GetId(), scene, action)
end

function FloatRaceModel:LoadLocalConfig()
  local strInfo = self.m_dbTable:GetValue(EStrDBKeys.CurrentInfo, "value")
  if strInfo ~= nil then
    self.m_currentInfo = json.decode(strInfo)
    if self.m_currentInfo.showIconFrameList == nil then
      self.m_currentInfo.showIconFrameList = UIHelper.GetRandomAvatarIconFrame(#self.m_currentInfo.showIconList)
    end
  end
end

function FloatRaceModel:_LoadOtherServerConfig(config)
  local mergeConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_config.mergeItemScoreConfig = {}
  for _, data in ipairs(mergeConfig) do
    self.m_config.mergeItemScoreConfig[data.item_id] = data
  end
  self.m_config.finishOrderScoreConfig = {}
  local isUseDiff = false
  for _, cfg in pairs(config.eventOrderScore) do
    table.insert(self.m_config.finishOrderScoreConfig, Table.DeepCopy(cfg, true))
    if not isUseDiff and IsNumber(cfg.diff_score_min) then
      isUseDiff = true
    end
  end
  self.m_bUseDiff = isUseDiff
  if isUseDiff then
    table.sort(self.m_config.finishOrderScoreConfig, function(a, b)
      return a.diff_score_min < b.diff_score_min
    end)
  else
    table.sort(self.m_config.finishOrderScoreConfig, function(a, b)
      return a.gold_min < b.gold_min
    end)
  end
  if config.floatRaceConfig[1].isDifficultySelect == 0 then
    self.m_bDifficultySelect = false
  elseif config.floatRaceConfig[1].isDifficultySelect == 1 then
    self.m_bDifficultySelect = true
  end
  self.m_config.roundCount = config.floatRaceConfig[1].round
  
  local function sortFunc(a, b)
    if a.difficultyMode == b.difficultyMode then
      return a.raceLevel < b.raceLevel
    else
      return a.difficultyMode < b.difficultyMode
    end
  end
  
  self.m_config.rewardConfigs = {}
  local rewardConfigs = Table.DeepCopy(config.floatRaceReward, true)
  if self.m_bDifficultySelect then
    table.sort(rewardConfigs, sortFunc)
  end
  for _, cfg in ipairs(rewardConfigs) do
    if cfg.difficultyMode == nil then
      cfg.difficultyMode = EFloatRaceDifficultyMode.None
    end
    if self.m_config.rewardConfigs[cfg.difficultyMode] == nil then
      self.m_config.rewardConfigs[cfg.difficultyMode] = {}
    end
    local rewardConfig = {
      target = cfg.target,
      rewards = cfg.rewards
    }
    self.m_config.rewardConfigs[cfg.difficultyMode][cfg.raceLevel] = rewardConfig
  end
  self.m_config.robotConfigs = {}
  local robotConfigs = Table.DeepCopy(config.floatRaceRobot, true)
  if self.m_bDifficultySelect then
    table.sort(robotConfigs, sortFunc)
  end
  for _, cfg in ipairs(robotConfigs) do
    if cfg.difficultyMode == nil then
      cfg.difficultyMode = 0
    end
    if self.m_config.robotConfigs[cfg.difficultyMode] == nil then
      self.m_config.robotConfigs[cfg.difficultyMode] = {}
    end
    local robotConfig = {
      upgradeSlotsNum = cfg.upgradeSlotsNum,
      maxRobotArriveTime = cfg.maxRobotArriveTime,
      robotSpeed = {}
    }
    for _, spCfg in ipairs(cfg.robotSpeed) do
      local spConfig = StringUtil.Split(spCfg, ",")
      if tonumber(spConfig[1]) == 0 or tonumber(spConfig[2]) == 0 or spConfig[1] >= spConfig[2] then
        GM.BIManager:LogErrorInfo(EBIType.FloatRaceRobotConfigError, string.format("robot config: min=%s, max=%s", spConfig[1], spConfig[2]))
      end
      local speed = {
        minTime = spConfig[1] * cfg.maxRobotArriveTime,
        maxTime = spConfig[2] * cfg.maxRobotArriveTime,
        num = spConfig[3]
      }
      table.insert(robotConfig.robotSpeed, speed)
    end
    self.m_config.robotConfigs[cfg.difficultyMode][cfg.raceLevel] = robotConfig
  end
end

function FloatRaceModel:CanAddScore()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_currentInfo == nil then
    return false
  end
  if self:GetRound() > self.m_config.roundCount then
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

function FloatRaceModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddMergeScore(message.Source)
  end
end

function FloatRaceModel:_TryAddMergeScore(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_config.mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_config.mergeItemScoreConfig[itemType].merge_score
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, EFloatRaceAddScoreScene.Merge, itemModel)
  end
end

function FloatRaceModel:GetAddScoreByOrder(order)
  if not self:CanAddScore() then
    return
  end
  local selectedIdx, score
  if self.m_bUseDiff then
    local diffScore = order:GetDiffScore()
    if diffScore == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_config.finishOrderScoreConfig, diffScore, "diff_score_min", "diff_score_max")
    score = diffScore
  else
    local price = order:GetPrice()
    if price == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_config.finishOrderScoreConfig, price, "gold_min", "gold_max")
    score = price
  end
  if selectedIdx == nil then
    return
  end
  local selected = self.m_config.finishOrderScoreConfig[selectedIdx]
  local count = selected.reward_num_percentage and math.floor(score * selected.reward_num_percentage / 10000) or selected.reward_num_fix
  if count <= 0 then
    return
  end
  return {
    [PROPERTY_TYPE] = EPropertyType.FloatRaceScore,
    [PROPERTY_COUNT] = count
  }
end

function FloatRaceModel:AcquireActivityToken(num)
  self:_AddScore(num, EFloatRaceAddScoreScene.Order, nil)
end

function FloatRaceModel:_AddScore(addScore, scene, item)
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
  EventDispatcher.DispatchEvent(EEventType.FloatRaceScoreChanged, {
    Scene = scene,
    Source = item,
    TokenScore = addScore
  })
  if score >= rewardConfig.target then
    if not ApplicationManager.Instance.isNetworkConnected then
      self:SetLevelFinishTime(GM.GameModel:GetServerTime())
      EventDispatcher.DispatchEvent(EEventType.FloatRaceFullScoreWithoutNet)
      return
    end
    self:_LevelUp(level)
  end
end

function FloatRaceModel:_LevelUp(level)
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
  if self:GetRound() > self.m_config.roundCount then
    EventDispatcher.DispatchEvent(EEventType.FloatRaceFinishedAll)
  end
end

function FloatRaceModel:LogLevelEnd(bSuccess)
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
  GM.BIManager:LogAction(EBIType.FloatRaceLevelEnd, biAction)
end

function FloatRaceModel:LevelFail()
  self:LogLevelEnd(false)
  self.m_currentInfo = nil
  self:SaveCurrentInfo()
  self:SetScore(0)
  EventDispatcher.DispatchEvent(EEventType.FloatRaceFail)
  self.m_dbTable:Set(EStrDBKeys.FailWindowPop, "value", "1")
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function FloatRaceModel:CanFailWindowPop()
  return self.m_dbTable:GetValue(EStrDBKeys.FailWindowPop, "value") == "1"
end

function FloatRaceModel:ClearFailWindowPop()
  self.m_dbTable:Set(EStrDBKeys.FailWindowPop, "value", "0")
end

function FloatRaceModel:AcquireRewardsLogic(level, isFinalReward)
  self:SetRecoverRewardsLevel(0)
  RewardApi.AcquireRewardsLogic(self:GetRewardCongfigByLevel(level).rewards, EPropertySource.Give, EBIType.FloatRaceGetRewards, EGameMode.Main, CacheItemType.Type2)
  self:LogActivity(EBIType.ActivityGetRewards, level == self:GetMaxLevel() and 0 or level, isFinalReward)
end

function FloatRaceModel:GetRecoverRewards()
  local level = self.m_dbTable:GetValue(EStrDBKeys.RecoverRewardsLevel, "value")
  if level == nil or level == "0" then
    return nil
  else
    local rewardConfig = self:GetRewardCongfigByLevel(level)
    if rewardConfig ~= nil then
      return rewardConfig.rewards
    end
  end
end

function FloatRaceModel:SetRecoverRewardsLevel(level)
  self.m_dbTable:Set(EStrDBKeys.RecoverRewardsLevel, "value", level)
end

function FloatRaceModel:GetRewardCongfigByLevel(level)
  if Table.IsEmpty(self.m_config.rewardConfigs) then
    return
  end
  local selectedDif = self:GetDifficultyMode()
  local rewardConfig = self.m_config.rewardConfigs[selectedDif]
  if not Table.IsEmpty(rewardConfig) then
    return rewardConfig[level]
  end
end

function FloatRaceModel:CanSignUp()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self:GetRound() > self.m_config.roundCount then
    return false
  end
  if self.m_currentInfo == nil then
    return true
  end
end

function FloatRaceModel:CanSelectDifficulty()
  return self.m_bDifficultySelect
end

function FloatRaceModel:GetRobotConfigByDiffAndLevel(diff, level)
  return self.m_config.robotConfigs[diff][level]
end

function FloatRaceModel:TrySignUp()
  if not self.m_bDifficultySelect and self:GetLevel() == 1 and self:GetRound() == 1 then
    self:SignUp(true)
  end
end

function FloatRaceModel:SignUp(bNewRound, difficultyMode)
  self:ClearTopTipState()
  local diff
  if bNewRound then
    diff = difficultyMode ~= nil and difficultyMode or EFloatRaceDifficultyMode.None
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
    GM.BIManager:LogAction(EBIType.FloatRaceNewRound, biAction)
  end
  self:SetScore(0)
  biAction.lv = level
  biAction.trynum = self:GetCurLevelTryTimes()
  GM.BIManager:LogAction(EBIType.FloatRaceLevelStart, biAction)
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
        GM.BIManager:LogErrorInfo(EBIType.FloatRaceRobotConfigError, string.format("robot sign up: min=%s, max=%s", cfg.minTime, cfg.maxTime))
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
  EventDispatcher.DispatchEvent(EEventType.FloatRaceSignUp)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function FloatRaceModel:RandomDeleteAvatar()
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

function FloatRaceModel:ClearTopTipState()
  self.m_dbTable:Remove(EStrDBKeys.OneTopTipPop, "value")
  self.m_dbTable:Remove(EStrDBKeys.FiveTopTipPop, "value")
  self.m_dbTable:Remove(EStrDBKeys.HalfTopTipPop, "value")
end

function FloatRaceModel:PopTopTip(type)
  self.m_dbTable:Set(type, "value", "1")
end

function FloatRaceModel:CanPopTopTip(type)
  return self.m_dbTable:GetValue(type, "value") ~= "1"
end

function FloatRaceModel:CheckTopTip()
  if self.m_currentInfo.curAliveNum <= 0 then
    return
  end
  local half = math.floor(self.m_currentInfo.finishAliveNum * 0.5)
  local tipType, textKey, callBack
  if self.m_currentInfo.curAliveNum <= 1 then
    tipType = EStrDBKeys.OneTopTipPop
    textKey = "floatRace_notice_3"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.OneTopTipPop)
      self:PopTopTip(EStrDBKeys.FiveTopTipPop)
    end
  elseif self.m_currentInfo.curAliveNum <= 5 then
    tipType = EStrDBKeys.FiveTopTipPop
    textKey = "floatRace_notice_2"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.FiveTopTipPop)
    end
  elseif half > self.m_currentInfo.curAliveNum then
    tipType = EStrDBKeys.HalfTopTipPop
    textKey = "floatRace_notice_1"
    
    function callBack()
      self:PopTopTip(EStrDBKeys.HalfTopTipPop)
    end
  end
  if tipType ~= nil and self:CanPopTopTip(tipType) then
    TopSliderManager.TrySlide(ActivityType.FloatRace, UIPrefabConfigName.FloatRaceTopTip, function(go)
      local model = GM.ActivityManager:GetModel(ActivityType.FloatRace)
      if model == nil or model:GetState() ~= ActivityState.Started or model:GetAliveNum() == nil then
        GameObject.Destroy(go)
        return
      end
      go:GetLuaTable():Init(textKey)
      TopSliderManager.Appear(go, function()
        callBack()
        DelayExecuteFunc(function()
          TopSliderManager.Disappear(go)
        end, 2.0)
      end)
    end)
  end
end

function FloatRaceModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self.m_currentInfo == nil then
    return
  end
  if not ApplicationManager.Instance.isNetworkConnected then
    return
  end
  local finishTime = self:GetLevelFinishTime()
  if finishTime ~= nil and not Table.IsEmpty(self.m_currentInfo.arriveTimeList) then
    self.m_dbTable:Remove(EStrDBKeys.LevelFinishTime, "value")
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
    EventDispatcher.DispatchEvent(EEventType.FloatRaceLevelUp)
  end
  if not Table.IsEmpty(self.m_currentInfo.arriveTimeList) then
    local time = GM.GameModel:GetServerTime()
    local removeList = {}
    for i = #self.m_currentInfo.arriveTimeList, 1, -1 do
      if time >= self.m_currentInfo.arriveTimeList[i] then
        table.remove(self.m_currentInfo.arriveTimeList, i)
        self.m_currentInfo.curAliveNum = self.m_currentInfo.curAliveNum - 1
        EventDispatcher.DispatchEvent(EEventType.FloatRaceRobotArrive)
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

function FloatRaceModel:GetMaxLevel()
  if Table.IsEmpty(self.m_config.rewardConfigs) then
    return
  end
  local selectedDif = self:GetDifficultyMode()
  return #self.m_config.rewardConfigs[selectedDif]
end

function FloatRaceModel:SetRound(num)
  self.m_dbTable:Set(EStrDBKeys.Round, "value", num)
end

function FloatRaceModel:GetRound()
  return self.m_dbTable:GetValue(EStrDBKeys.Round, "value") or 1
end

function FloatRaceModel:GetLevel()
  return self.m_dbTable:GetValue(EStrDBKeys.Level, "value") or 1
end

function FloatRaceModel:SetLevel(num)
  self.m_dbTable:Set(EStrDBKeys.Level, "value", num)
end

function FloatRaceModel:GetScore()
  return self.m_dbTable:GetValue(EStrDBKeys.Score, "value") or 0
end

function FloatRaceModel:SetScore(num)
  self.m_dbTable:Set(EStrDBKeys.Score, "value", num)
end

function FloatRaceModel:SetDifficultyMode(mode)
  self.m_dbTable:Set(EStrDBKeys.Difficulty, "value", mode)
end

function FloatRaceModel:GetDifficultyMode()
  return self.m_dbTable:GetValue(EStrDBKeys.Difficulty, "value") or EFloatRaceDifficultyMode.None
end

function FloatRaceModel:GetLastScore()
  return self.m_dbTable:GetValue(EStrDBKeys.LastScore, "value") or 0
end

function FloatRaceModel:SetLastScore(num)
  self.m_dbTable:Set(EStrDBKeys.LastScore, "value", num)
end

function FloatRaceModel:GetLastLevel()
  return self.m_dbTable:GetValue(EStrDBKeys.LastLevel, "value") or 1
end

function FloatRaceModel:SetLastLevel(num)
  self.m_dbTable:Set(EStrDBKeys.LastLevel, "value", num)
end

function FloatRaceModel:IsAllRoundFinished()
  if self.m_config == nil then
    return false
  else
    return self:GetRound() > self.m_config.roundCount
  end
end

function FloatRaceModel:GetCurrentInfo()
  return Table.ShallowCopy(self.m_currentInfo)
end

function FloatRaceModel:SaveCurrentInfo()
  if self.m_currentInfo == nil then
    self.m_dbTable:Remove(EStrDBKeys.CurrentInfo, "value")
  else
    self.m_dbTable:Set(EStrDBKeys.CurrentInfo, "value", json.encode(self.m_currentInfo))
  end
end

function FloatRaceModel:SetLevelFinishTime(time)
  self.m_dbTable:Set(EStrDBKeys.LevelFinishTime, "value", time)
end

function FloatRaceModel:GetLevelFinishTime()
  return self.m_dbTable:GetValue(EStrDBKeys.LevelFinishTime, "value")
end

function FloatRaceModel:GetAliveNum()
  return self.m_currentInfo and self.m_currentInfo.curAliveNum or nil
end

function FloatRaceModel:GetFinishAliveNum()
  if self.m_currentInfo ~= nil then
    return self.m_currentInfo.finishAliveNum
  else
    local robotConfig = self:GetRobotConfigByDiffAndLevel(self:GetDifficultyMode(), self:GetLevel())
    return robotConfig.upgradeSlotsNum
  end
end

function FloatRaceModel:GetBigRewardByDiff(diff)
  if Table.IsEmpty(self.m_config.rewardConfigs) then
    return
  end
  local rewardConfig = self.m_config.rewardConfigs[diff]
  if Table.IsEmpty(self.m_config.rewardConfigs) then
    return
  end
  return rewardConfig[#rewardConfig].rewards
end

function FloatRaceModel:GetRank()
  return self.m_dbTable:GetValue(EStrDBKeys.Rank, "value")
end

function FloatRaceModel:SetRank(rank)
  self.m_dbTable:Set(EStrDBKeys.Rank, "value", rank)
end

function FloatRaceModel:GetDeleteAvatarIndexs()
  return self.m_currentInfo and self.m_currentInfo.deleteIconIndex or nil
end

function FloatRaceModel:ClearCurrentPlayState()
  self:SetLastLevel(self:GetLevel())
  self:SetLastScore(0)
  self:SetScore(0)
  self.m_currentInfo = nil
  self:SaveCurrentInfo()
  if self:GetLevel() > self:GetMaxLevel() then
    self:SetDifficultyMode(EFloatRaceDifficultyMode.None)
    self:SetLevel(1)
    self:SetLastLevel(1)
  end
end

function FloatRaceModel:PopFinishWindow()
  self.m_dbTable:Set(EStrDBKeys.FinishWindowPop, "value", "1")
end

function FloatRaceModel:CanPopFinishWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.FinishWindowPop, "value") ~= "1"
end

function FloatRaceModel:PopEndWindow()
  self.m_dbTable:Set(EStrDBKeys.EndWindowPop, "value", "1")
end

function FloatRaceModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(EStrDBKeys.EndWindowPop, "value") ~= "1"
end

function FloatRaceModel:CanPopSelectWindow()
  return self:CanSelectDifficulty() and self:GetDifficultyMode() == EFloatRaceDifficultyMode.None and self.m_selectWindowPop ~= true
end

function FloatRaceModel:PopSelectWindow()
  self.m_selectWindowPop = true
end

function FloatRaceModel:SetCurLevelTryTimes(num)
  self.m_dbTable:Set(EStrDBKeys.CurLevelTryTimes, "value", num)
end

function FloatRaceModel:GetCurLevelTryTimes()
  return self.m_dbTable:GetValue(EStrDBKeys.CurLevelTryTimes, "value") or 1
end

function FloatRaceModel:CanShowRedPoint()
  return self:CanSignUp() or self:GetLevelFinishTime() ~= nil
end

function FloatRaceModel:GetHudEntryShowConfig()
  return {
    Type = "floatRace",
    ArrCheckShowEvent = {
      EEventType.FloatRaceStateChanged,
      EEventType.FloatRaceFinishedAll
    },
    EntryPrefabConfigName = UIPrefabConfigName.FloatRaceHudEntry,
    CheckFunc = function()
      return self:GetState() == ActivityState.Preparing or self:GetState() == ActivityState.Started and not self:IsAllRoundFinished()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = ESceneViewHudButtonKey.FloatRace,
    EntryIconName = ImageFileConfigName.icon_floatRace,
    OnClickedFunc = function()
      if not ApplicationManager.Instance.isNetworkConnected then
        GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
        return
      end
      local state = self:GetState()
      if state == ActivityState.Preparing then
        GM.UIManager:OpenView(UIPrefabConfigName.FloatRaceNoticeWindow)
      end
      local currentInfo = self:GetCurrentInfo()
      if state == ActivityState.Started then
        if self:CanSelectDifficulty() and self:GetDifficultyMode() == EFloatRaceDifficultyMode.None then
          GM.UIManager:OpenView(UIPrefabConfigName.FloatRaceSelectWindow)
        else
          if self:GetLevelFinishTime() then
            GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
            if GameConfig.IsTestMode() then
              Log.Info("\232\191\158\233\151\175\239\188\154\229\129\135\228\186\186\232\191\152\230\156\170\229\136\183\230\150\176\239\188\140\230\151\160\230\179\149\230\137\147\229\188\128\228\184\187\231\149\140\233\157\162")
            end
            return
          end
          GM.UIManager:OpenView(UIPrefabConfigName.FloatRaceMainWindow)
        end
      end
    end,
    RedPointType = EntryRedPointType.Exc,
    GetRedPointNumFunc = function()
      return self:CanShowRedPoint() and 1 or 0
    end,
    ArrUpdateEntryContentEvent = {
      EEventType.FloatRaceSignUp,
      EEventType.FloatRaceScoreChanged,
      EEventType.FloatRaceWaitSignUp,
      EEventType.FloatRaceRobotArrive,
      EEventType.FloatRaceFail,
      EEventType.FloatRaceFullScoreWithoutNet
    }
  }
end

function FloatRaceModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      EEventType.FloatRaceFinishedAll,
      EEventType.FloatRaceStateChanged
    },
    bubbleName = "m_floatRaceBubble",
    bubbleNodeName = "m_floatRaceEntryNode",
    entryPrefabName = UIPrefabConfigName.FloatRaceBoardEntry,
    scrollToFunName = "ScrollToFloatRaceBoardEntry",
    activityType = self:GetType(),
    checkFun = function()
      return self:GetState() == ActivityState.Started and not self:IsAllRoundFinished()
    end
  }
end

function FloatRaceModel:TestAddScore(num)
  self:_AddScore(num, "test")
end

function FloatRaceModel:TestLevelUp()
  local level = self:GetLevel()
  local rewardConfig = self:GetRewardCongfigByLevel(level)
  if rewardConfig == nil then
    return
  end
  self:_AddScore(rewardConfig.target, "test")
end

function FloatRaceModel:Test2LastLevel()
  local maxLevel = self:GetMaxLevel()
  self:SetLevel(maxLevel)
  self:SetLastLevel(maxLevel)
  self:SetScore(0)
  self:SetLastScore(0)
  self:SignUp(false)
end
