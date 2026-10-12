TriggerProgressActivityModel = setmetatable({}, BaseActivityModel)
TriggerProgressActivityModel.__index = TriggerProgressActivityModel
TriggerProgressActivityModel.ScoreType = {energy = "energy", chance = "chance"}
local DBKeys = {
  Score = "Score",
  TriggerDays = "TriggerDays",
  CostEnergyNum = "CostEnergyNum",
  CostEnergyDays = "CostEnergyDays",
  TriggerTime = "TriggerTime",
  TriggerEndTime = "TriggerEndTime",
  RemainClickNum = "RemainClickNum",
  RemainGetScoreNum = "RemainGetScoreNum",
  MainWindowOpened = "MainWindowOpened",
  CompleteWindowOpened = "CompleteWindowOpened",
  LastDisplayedLevel = "lastDisplayedLevel",
  LastDisplayedScore = "lastDisplayedScore",
  UseEnergyNum = "UseEnergyNum"
}
local TriggerState = {
  UnTrigger = 1,
  TriggerOnGoing = 2,
  Completed = 3,
  Ended = 4
}
local DBColumnValue = "value"

function TriggerProgressActivityModel:Init(activityType, activityDataTable)
  self.m_activityDefinition = TriggerProgressActivityDefinition[activityType]
  self.m_bSync = false
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.EnergyChanged, self, self._OnEnergyChanged)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
end

function TriggerProgressActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
end

function TriggerProgressActivityModel:_LoadOtherServerConfig(config)
  self.m_config.m_arrTriggerProgressRwdCfg = config.triggerProgressRewardConfig
  table.sort(self.m_config.m_arrTriggerProgressRwdCfg, function(a, b)
    return a.level < b.level
  end)
  self.m_config.m_triggerProgressCfg = config.triggerProgressConfig[1]
  if self.m_config.m_triggerProgressCfg.score_type == TriggerProgressActivityModel.ScoreType.chance then
    Log.Assert(self.m_config.m_triggerProgressCfg.chance[1] >= self.m_config.m_triggerProgressCfg.chance[2], "\232\175\183\230\163\128\230\159\165\233\133\141\231\189\174\239\188\154triggerProgressConfig->chance")
  end
  self:UpdateContent()
end

function TriggerProgressActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  self:UpdateContent()
end

function TriggerProgressActivityModel:GetServerConfigGroupId()
  return self.m_config.m_triggerProgressCfg.groupId
end

function TriggerProgressActivityModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  self:TryTriggerProgress()
end

function TriggerProgressActivityModel:_UpdateState()
  BaseActivityModel._UpdateState(self)
  self:_UpdateTriggerState()
end

function TriggerProgressActivityModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
end

function TriggerProgressActivityModel:_UpdateTriggerState()
  local lastTriggerState = self.m_triggerState
  self.m_triggerState = self:_CalcTriggerState()
  if self.m_triggerState ~= lastTriggerState then
    EventDispatcher.DispatchEvent(self.m_activityDefinition.DailyStateChangedEvent)
  end
end

function TriggerProgressActivityModel:_CalcTriggerState()
  if self:GetState(false) ~= ActivityState.Started then
    return
  end
  local serverTime = GM.GameModel:GetServerTime()
  local endTime = self:GetTriggerEndTime()
  if serverTime < endTime then
    if self.m_currentLevel > #self.m_config.m_arrTriggerProgressRwdCfg then
      return TriggerState.Completed
    end
    return TriggerState.TriggerOnGoing
  end
  if self:GetTriggerDays() >= GM.GameModel:GetServerTime() // Sec2Day then
    return TriggerState.Ended
  else
    return TriggerState.UnTrigger
  end
end

function TriggerProgressActivityModel:UpdateContent()
  self.m_currentLevel = 1
  self.m_currentScore = 0
  if self.m_config == nil then
    return
  end
  local score = self:GetTotalScore()
  local tmpScore = 0
  for _, rewardConfig in ipairs(self.m_config.m_arrTriggerProgressRwdCfg) do
    tmpScore = tmpScore + rewardConfig.score
    if score < tmpScore then
      self.m_currentScore = score - (tmpScore - rewardConfig.score)
      self.m_currentLevel = rewardConfig.level
      break
    end
  end
  if score >= tmpScore then
    self.m_currentScore = self.m_config.m_arrTriggerProgressRwdCfg[#self.m_config.m_arrTriggerProgressRwdCfg].score
    self.m_currentLevel = #self.m_config.m_arrTriggerProgressRwdCfg + 1
  end
  if not self.m_bSync then
    self.m_bSync = true
    self:SetLastDisplayedLevelAndScore(self.m_currentLevel, self.m_currentScore)
  end
end

function TriggerProgressActivityModel:IsTriggerOnGoing()
  if self:GetState(false) ~= ActivityState.Started then
    return false
  end
  return self.m_triggerState == TriggerState.TriggerOnGoing
end

function TriggerProgressActivityModel:IsCompleted()
  return self.m_triggerState == TriggerState.Completed
end

function TriggerProgressActivityModel:_CanTrigger()
  if self:GetState(false) ~= ActivityState.Started then
    return false
  end
  if self:GetTriggerDays() >= GM.GameModel:GetServerTime() // Sec2Day then
    return false
  end
  return true
end

function TriggerProgressActivityModel:TryTriggerProgress()
  if not self:_CanTrigger() then
    return
  end
  local serverTime = GM.GameModel:GetServerTime()
  local curDays = serverTime // Sec2Day
  if self:GetCostEnergyNum() < self.m_config.m_triggerProgressCfg.energy then
    return
  end
  if GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy) > self.m_config.m_triggerProgressCfg.trigger_energy then
    return
  end
  local curGem = GM.ShopModel:GetEnergyCostExcludeFree()
  if curGem < self.m_config.m_triggerProgressCfg.trigger_gem then
    return
  end
  local durationTime = math.min(Sec2Day - serverTime % Sec2Day - 1, self.m_config.eTime - GM.GameModel:GetServerTime())
  if durationTime < self.m_config.m_triggerProgressCfg.duration_min * 60 then
    return
  end
  durationTime = math.min(durationTime, self.m_config.m_triggerProgressCfg.duration_max * 60)
  durationTime = math.min(durationTime, self.m_config.eTime - serverTime)
  GM.BIManager:LogAction("tp_debug", {
    etime = self.m_config.eTime,
    serTime = serverTime,
    curDays = curDays
  })
  local endTime = serverTime + durationTime
  self:SetTriggerEndTime(endTime)
  self:SetTriggerTime(serverTime)
  self:SetTriggerDays(curDays)
  self:SetUseEnergyNum(0)
  self:SetTotalScore(0)
  self:SetCostEnergyNum(0)
  self:SetRemainClickNum(0)
  self:SetRemainGetScoreNum(0)
  self:SetLastDisplayedLevelAndScore(1, 0)
  self:SetMainWindowReopen()
  self:SetCompleteWindowReopen()
  self:UpdateContent()
  self:_UpdateTriggerState()
  self:LogAction(self.m_activityDefinition.StartBIType, {dt = durationTime})
end

function TriggerProgressActivityModel:LogAction(biType, params)
  local action = {
    id = self:GetId(),
    gid = self:GetServerConfigGroupId(),
    st = TimeUtil.ToDate(self:GetTriggerTime(), ETimeFormat.YMD)
  }
  if params then
    for k, v in pairs(params) do
      action[k] = v
    end
  end
  GM.BIManager:LogAction(biType, action)
end

function TriggerProgressActivityModel:_AddScore(score, scene, source)
  local lastLevel = self.m_currentLevel
  self:SetTotalScore(self:GetTotalScore() + score)
  self:LogAction(self.m_activityDefinition.GetScoreBIType, {s = score})
  self:UpdateContent()
  self:_UpdateTriggerState()
  local bUpgrade = lastLevel < self.m_currentLevel
  EventDispatcher.DispatchEvent(self.m_activityDefinition.ScoreChangedEvent, {
    Scene = scene,
    Source = source,
    Score = score,
    bUpgrade = bUpgrade
  })
  if bUpgrade then
    local rewards = {}
    for i = lastLevel, self.m_currentLevel - 1 do
      local reward = self.m_config.m_arrTriggerProgressRwdCfg[i].reward
      Table.ListAppend(rewards, {reward})
      self:LogAction(self.m_activityDefinition.LevelUpBIType, {
        lv = i,
        energy = self:GetUseEnergyNum()
      })
    end
    if not Table.IsEmpty(rewards) then
      RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_activityDefinition.GetRewardBIType, EGameMode.Main, CacheItemType.Type2)
    end
    if self:IsCompleted() then
      EventDispatcher.DispatchEvent(self.m_activityDefinition.LevelUpEvent, true)
      EventDispatcher.DispatchEvent(self.m_activityDefinition.CompleteEvent)
    end
    self.cacheRewards = rewards
  end
end

function TriggerProgressActivityModel:ClearCacheRewards(bRewardInView)
  if Table.IsEmpty(self.cacheRewards) then
    return
  end
  if bRewardInView then
    RewardApi.AcquireRewardsInView(self.cacheRewards, {})
  end
  self.cacheRewards = {}
end

function TriggerProgressActivityModel:GetScore()
  return self.m_currentScore or 0
end

function TriggerProgressActivityModel:GetLevel()
  return self.m_currentLevel or 1
end

function TriggerProgressActivityModel:GetTriggerProgressRwdConfig()
  return self.m_config.m_arrTriggerProgressRwdCfg
end

function TriggerProgressActivityModel:GetLevelConfig(level)
  if level <= 0 then
    return
  end
  return self.m_config.m_arrTriggerProgressRwdCfg[level]
end

function TriggerProgressActivityModel:_OnEnergyChanged(info)
  local preEnergy = info.prevEnergy
  local curEnergy = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy)
  local useEnergy = preEnergy - curEnergy
  if useEnergy <= 0 then
    return
  end
  if self:IsTriggerOnGoing() then
    self:SetUseEnergyNum(self:GetUseEnergyNum() + useEnergy)
    if self.m_config.m_triggerProgressCfg.score_type == TriggerProgressActivityModel.ScoreType.energy then
      self:_AddScore(useEnergy, TriggerProgressActivityModel.ScoreType.energy)
    end
  elseif self:_CanTrigger() then
    self:AddCostEnergyNum(useEnergy)
  end
end

function TriggerProgressActivityModel:_OnItemSpread(message)
  if not self:IsTriggerOnGoing() then
    return
  end
  if self.m_config.m_triggerProgressCfg.score_type ~= TriggerProgressActivityModel.ScoreType.chance then
    return
  end
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    local clickLeft = self:GetRemainClickNum()
    local getScoreLeft = self:GetRemainGetScoreNum()
    if clickLeft <= 0 then
      clickLeft = self.m_config.m_triggerProgressCfg.chance[1]
      getScoreLeft = self.m_config.m_triggerProgressCfg.chance[2]
      self:SetRemainGetScoreNum(getScoreLeft)
    end
    local bScore = false
    if 0 < getScoreLeft then
      local roll = math.random(1, clickLeft)
      if getScoreLeft >= roll then
        bScore = true
        getScoreLeft = getScoreLeft - 1
        self:SetRemainGetScoreNum(getScoreLeft)
      end
    end
    clickLeft = clickLeft - 1
    self:SetRemainClickNum(clickLeft)
    if bScore then
      local addScore = MathUtil.IntPow(2, message.EnergyBoostRatio)
      self:_AddScore(addScore, TriggerProgressActivityModel.ScoreType.chance, message.Source)
    end
  end
end

function TriggerProgressActivityModel:GetMainDescKey()
  local descKey = "trigger_progress_energy_desc"
  if self.m_config.m_triggerProgressCfg.score_type == TriggerProgressActivityModel.ScoreType.chance then
    descKey = "trigger_progress_chance_desc"
  end
  return descKey
end

function TriggerProgressActivityModel:GetBubbleTextKey()
  local key = "trigger_progress_energy_bubble"
  if self.m_config.m_triggerProgressCfg.score_type == TriggerProgressActivityModel.ScoreType.chance then
    key = "trigger_progress_chance_bubble"
  end
  return key
end

function TriggerProgressActivityModel:GetProgressConfig()
  return self.m_config
end

function TriggerProgressActivityModel:SetTriggerWindowOpened()
  if self.m_triggerState == TriggerState.TriggerOnGoing then
    self:SetMainWindowOpened()
  elseif self.m_triggerState == TriggerState.Completed then
    self:SetCompleteWindowOpened()
  end
end

function TriggerProgressActivityModel:_UpdateCostEnergyNum()
  local curDays = GM.GameModel:GetServerTime() // Sec2Day
  local lastDays = self:GetCostEnergyDays()
  if lastDays ~= curDays then
    self.m_dbTable:Set(DBKeys.CostEnergyNum, DBColumnValue, 0)
    self:SetCostEnergyDays(curDays)
  end
end

function TriggerProgressActivityModel:SaveTriggerCache()
  self.m_dbTable:Set(DBKeys.TriggerCache, DBColumnValue, json.encode(self.m_canTriggerCache or "{}"))
end

function TriggerProgressActivityModel:GetTotalScore()
  return self.m_dbTable:GetValue(DBKeys.Score, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetTotalScore(score)
  self.m_dbTable:Set(DBKeys.Score, DBColumnValue, score)
end

function TriggerProgressActivityModel:GetCostEnergyNum()
  self:_UpdateCostEnergyNum()
  return self.m_dbTable:GetValue(DBKeys.CostEnergyNum, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetCostEnergyNum(num)
  self:_UpdateCostEnergyNum()
  self.m_dbTable:Set(DBKeys.CostEnergyNum, DBColumnValue, num)
end

function TriggerProgressActivityModel:AddCostEnergyNum(num)
  self:_UpdateCostEnergyNum()
  self.m_dbTable:Set(DBKeys.CostEnergyNum, DBColumnValue, self:GetCostEnergyNum() + num)
end

function TriggerProgressActivityModel:GetCostEnergyDays()
  return self.m_dbTable:GetValue(DBKeys.CostEnergyDays, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetCostEnergyDays(days)
  self.m_dbTable:Set(DBKeys.CostEnergyDays, DBColumnValue, days)
end

function TriggerProgressActivityModel:GetTriggerDays()
  return self.m_dbTable:GetValue(DBKeys.TriggerDays, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetTriggerDays(days)
  self.m_dbTable:Set(DBKeys.TriggerDays, DBColumnValue, days)
end

function TriggerProgressActivityModel:GetTriggerEndTime()
  return self.m_dbTable:GetValue(DBKeys.TriggerEndTime, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetTriggerEndTime(time)
  self.m_dbTable:Set(DBKeys.TriggerEndTime, DBColumnValue, time)
end

function TriggerProgressActivityModel:SetTriggerTime(time)
  self.m_dbTable:Set(DBKeys.TriggerTime, DBColumnValue, time)
end

function TriggerProgressActivityModel:GetTriggerTime()
  return self.m_dbTable:GetValue(DBKeys.TriggerTime, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetUseEnergyNum(num)
  self.m_dbTable:Set(DBKeys.UseEnergyNum, DBColumnValue, num)
end

function TriggerProgressActivityModel:GetUseEnergyNum()
  return self.m_dbTable:GetValue(DBKeys.UseEnergyNum, DBColumnValue) or 0
end

function TriggerProgressActivityModel:GetRemainClickNum()
  return self.m_dbTable:GetValue(DBKeys.RemainClickNum, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetRemainClickNum(num)
  self.m_dbTable:Set(DBKeys.RemainClickNum, DBColumnValue, num)
end

function TriggerProgressActivityModel:GetRemainGetScoreNum()
  return self.m_dbTable:GetValue(DBKeys.RemainGetScoreNum, DBColumnValue) or 0
end

function TriggerProgressActivityModel:SetRemainGetScoreNum(num)
  self.m_dbTable:Set(DBKeys.RemainGetScoreNum, DBColumnValue, num)
end

function TriggerProgressActivityModel:SetMainWindowOpened()
  self.m_dbTable:Set(DBKeys.MainWindowOpened, DBColumnValue, 1)
end

function TriggerProgressActivityModel:IsMainWindowOpened()
  return self.m_dbTable:GetValue(DBKeys.MainWindowOpened, DBColumnValue) == 1
end

function TriggerProgressActivityModel:SetMainWindowReopen()
  self.m_dbTable:Remove(DBKeys.MainWindowOpened, DBColumnValue)
end

function TriggerProgressActivityModel:SetCompleteWindowOpened()
  self.m_dbTable:Set(DBKeys.CompleteWindowOpened, DBColumnValue, 1)
end

function TriggerProgressActivityModel:IsCompleteWindowOpened()
  return self.m_dbTable:GetValue(DBKeys.CompleteWindowOpened, DBColumnValue) == 1
end

function TriggerProgressActivityModel:SetCompleteWindowReopen()
  self.m_dbTable:Remove(DBKeys.CompleteWindowOpened, DBColumnValue)
end

function TriggerProgressActivityModel:GetLastDisplayedLevelAndScore()
  local lastDisplayedLevel = self.m_dbTable:GetValue(DBKeys.LastDisplayedLevel, DBColumnValue) or 1
  local lastDisplayedScore = self.m_dbTable:GetValue(DBKeys.LastDisplayedScore, DBColumnValue) or 0
  return lastDisplayedLevel, lastDisplayedScore
end

function TriggerProgressActivityModel:SetLastDisplayedLevelAndScore(lastDisplayedLevel, lastDisplayedScore)
  self.m_dbTable:Set(DBKeys.LastDisplayedLevel, DBColumnValue, lastDisplayedLevel)
  self.m_dbTable:Set(DBKeys.LastDisplayedScore, DBColumnValue, lastDisplayedScore)
end

function TriggerProgressActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function TriggerProgressActivityModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.DailyStateChangedEvent
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_TriggerProgressActivityBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_TriggerProgressActivityBubbleCount",
    scrollToFunName = "ScrollToTriggerProgressActivity",
    activityType = self:GetType(),
    checkFun = function()
      if self:IsTriggerOnGoing() then
        return true
      end
    end
  }
end

function TriggerProgressActivityModel:GetTestPopupWindowConfig()
  return {
    CheckFunc = function()
      return self:IsTriggerOnGoing()
    end,
    config = {
      GroupName = "\232\167\166\229\143\145\229\188\143\232\191\155\229\186\166\230\157\161(TriggerProgress)",
      WindowList = {
        {
          BtnName = "\228\184\187\231\149\140\233\157\162",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self.m_type, false)
          end
        },
        {
          BtnName = "\231\187\147\230\157\159\231\149\140\233\157\162",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.CompleteWindowPrefabName, self.m_type, false)
          end
        }
      }
    }
  }
end

function TriggerProgressActivityModel:TestAddScore(score)
  if not GameConfig.IsTestMode() then
    return
  end
  self:_AddScore(score, TriggerProgressActivityModel.ScoreType.energy)
end

function TriggerProgressActivityModel:TestFinishOne()
  local levelConfig = self:GetLevelConfig(self:GetLevel())
  local addScore = levelConfig.score - self:GetScore()
  self:TestAddScore(addScore)
end

function TriggerProgressActivityModel:TestFinishAll()
  local sumScore = 0
  for level = self:GetLevel(), #self.m_config.m_arrTriggerProgressRwdCfg do
    local levelConfig = self:GetLevelConfig(level)
    sumScore = sumScore + levelConfig.score
  end
  self:TestAddScore(sumScore)
end

function TriggerProgressActivityModel:TestClearProgress()
  if not GameConfig.IsTestMode() then
    return
  end
  self:SetTotalScore(0)
  self:SetCostEnergyNum(0)
  self:SetRemainClickNum(0)
  self:SetRemainGetScoreNum(0)
  self:SetLastDisplayedLevelAndScore(1, 0)
  self:UpdateContent()
end

function TriggerProgressActivityModel:GetTestInfo()
  if self:GetState() ~= ActivityState.Started then
    return "\230\180\187\229\138\168\230\156\170\229\188\128\229\167\139"
  end
  if self:IsTriggerOnGoing() then
    local info = "\229\183\178\231\187\143\232\167\166\229\143\145" .. "\n"
    if self.m_config.m_triggerProgressCfg.score_type == TriggerProgressActivityModel.ScoreType.chance then
      local clickLeft = self:GetRemainClickNum()
      local getScoreLeft = self:GetRemainGetScoreNum()
      info = info .. StringUtil.Format("\231\130\185\229\135\187\230\172\161\230\149\176\239\188\154%d\239\188\140\232\142\183\229\143\150\231\167\175\229\136\134\230\172\161\230\149\176\239\188\154%d", clickLeft, getScoreLeft)
    end
    return info
  end
  if self:IsCompleted() then
    return "\230\180\187\229\138\168\229\183\178\229\174\140\230\136\144"
  end
  local testInfo = ""
  testInfo = testInfo .. "\232\167\166\229\143\145\230\157\161\228\187\182:" .. "\n"
  local curGem = GM.ShopModel:GetEnergyCostExcludeFree()
  local serverTime = GM.GameModel:GetServerTime()
  local durationTime = math.min(Sec2Day - serverTime % Sec2Day - 1, self.m_config.eTime - serverTime)
  testInfo = testInfo .. "\233\146\187\231\159\179\232\180\173\228\185\176\228\189\147\229\138\155\231\154\132\230\161\163\228\189\141" .. curGem .. " \\ " .. self.m_config.m_triggerProgressCfg.trigger_gem .. "\n"
  testInfo = testInfo .. "\230\182\136\232\128\151\228\189\147\229\138\155\231\154\132\230\149\176\233\135\143" .. self:GetCostEnergyNum() .. " \\ " .. self.m_config.m_triggerProgressCfg.energy .. "\n"
  testInfo = testInfo .. "\229\189\147\229\137\141\229\137\169\228\189\153\231\154\132\228\189\147\229\138\155" .. GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy) .. " \\ " .. self.m_config.m_triggerProgressCfg.trigger_energy .. "\n"
  testInfo = testInfo .. "\230\180\187\229\138\168\230\151\182\233\151\180" .. durationTime .. " \\ " .. self.m_config.m_triggerProgressCfg.duration_min * 60 .. "\n"
  return testInfo
end
