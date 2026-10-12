ScoreRushBotUpdateTypeToEaseType = {
  [1] = Ease.InQuart,
  [2] = Ease.OutQuart,
  [3] = Ease.InOutQuart,
  [4] = Ease.OutQuad
}
ScoreRushRobotScoreUpdateType = {FixedDuration = 1, RandomDuration = 2}
local ROBOT_SCORE_UPDATE_FIX_DURATION = 15
local ROBOT_SCORE_UPDATE_RANDOM_RANGE = 30
local SCORE_RUSH_MAX_GRADE = 5
local SCORE_RUSH_RESULT_WIN = "1"
local SCORE_RUSH_RESULT_LOSE = "0"
ScoreRushModel = setmetatable({}, BaseActivityModel)
ScoreRushModel.__index = ScoreRushModel
local DBKey = {
  CurUseEnergy = "CurUseEnergy",
  StartTime = "StartTime",
  RobotData = "RobotData",
  CurScore = "CurScore",
  IsFinished = "IsFinished",
  PopEndWindow = "PopEndWindow",
  CacheGrade = "CacheGrade"
}

function ScoreRushModel:Init(activityType, activityDataTable)
  self:ResetVar()
  self.m_activityDefinition = ScoreRushDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.EnergyChanged, self, self._OnEnergyChanged)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
  self:SetRobotScoreUpdateType(ScoreRushRobotScoreUpdateType.FixedDuration)
end

function ScoreRushModel:LateInit()
  self:_LoadLocalConfig()
end

function ScoreRushModel:_LoadOtherServerConfig(config)
  self.m_baseConfig = {}
  if config.scoreRushConfig and config.scoreRushConfig[1] then
    self.m_baseConfig = Table.DeepCopy(config.scoreRushConfig[1], true)
    self.m_baseConfig.duration = self.m_baseConfig.duration * 60
  end
  self.m_playerConfig = {}
  if config.scoreRushPlayer and config.scoreRushPlayer[1] then
    self.m_playerConfig = Table.DeepCopy(config.scoreRushPlayer[1], true)
  end
  self.m_botUpdateConfig = {}
  if config.scoreRushBotUpdate then
    for _, v in pairs(config.scoreRushBotUpdate) do
      if not self.m_botUpdateConfig[v.grade] then
        self.m_botUpdateConfig[v.grade] = {}
      end
      table.insert(self.m_botUpdateConfig[v.grade], Table.DeepCopy(v, true))
    end
  end
  for _, v in pairs(self.m_botUpdateConfig) do
    table.sort(v, function(a, b)
      return a.index < b.index
    end)
  end
  self.m_rewardConfig = {}
  if config.scoreRushReward then
    for _, v in pairs(config.scoreRushReward) do
      if not self.m_rewardConfig[v.grade] then
        self.m_rewardConfig[v.grade] = {}
      end
      self.m_rewardConfig[v.grade][v.rank] = Table.DeepCopy(v.rewards, true)
    end
  end
end

function ScoreRushModel:_LoadLocalConfig()
  local config = require("Data.Config." .. self.m_activityDefinition.ScoreConfigFileName)
  self.m_itemChainScoreConfig = {}
  for itemType, baseScore in pairs(config) do
    local itemChain = GM.ItemDataModel:GetChainId(itemType)
    local level = GM.ItemDataModel:GetChainLevel(itemType)
    if itemChain and level then
      self.m_itemChainScoreConfig[itemChain] = {level = level, baseScore = baseScore}
    else
      Log.Error("[ScoreRushModel]\230\137\190\228\184\141\229\136\176Item ChainId\239\188\154" .. itemType)
    end
  end
end

function ScoreRushModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
end

function ScoreRushModel:_DropData()
  self:ResetVar()
  BaseActivityModel._DropData(self)
end

function ScoreRushModel:ResetVar()
  self.m_scoreMap = nil
  self.m_rankList = nil
  self.m_rank = nil
  self.m_robotDataMap = nil
  self.m_signUpWindowOpened = nil
end

function ScoreRushModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:IsInRace() then
    self:UpdateRank()
  end
  self:TryFinishRace()
end

function ScoreRushModel:_OnItemSpread(message)
  if self:IsFinished() then
    return
  end
  if not self:IsInRace() then
    return
  end
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    local itemType = message.New:GetType()
    local itemChain = GM.ItemDataModel:GetChainId(itemType)
    local config = self.m_itemChainScoreConfig[itemChain]
    if config then
      local level = GM.ItemDataModel:GetChainLevel(itemType)
      if level >= config.level then
        local score = math.floor(config.baseScore * 2 ^ (level - config.level))
        self:_SetCurScore(self:_GetCurScore() + score)
        self:LogActivity(EBIType.ActivityAddScore, GM.BIManager:TableToString({
          a = score,
          g = self:GetCacheGrade(),
          t = itemType
        }))
        EventDispatcher.DispatchEvent(self.m_activityDefinition.MyScoreChangedEvent, {
          Score = score,
          New = message.New
        })
        if GameConfig.IsTestMode() then
          Log.Debug("[ScoreRushModel]\231\167\175\229\136\134\229\162\158\229\138\160\239\188\154" .. score .. ", \229\159\186\229\135\134\239\188\154Lv" .. config.level .. "-" .. config.baseScore .. ", \229\174\158\233\153\133\239\188\154Lv" .. level .. "-" .. score)
        end
      end
    end
  end
end

function ScoreRushModel:_OnEnergyChanged(args)
  if not self:IsOpen() then
    return
  end
  if self:IsTriggerRace() then
    return
  end
  if self:IsFinished() then
    return
  end
  local preEnergy = args.prevEnergy
  local curEnergy = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy)
  local useEnergy = preEnergy - curEnergy
  if 0 < useEnergy then
    self:_SetCurUseEnergy(self:_GetCurUseEnergy() + useEnergy)
  end
  if self:_GetCurUseEnergy() >= self.m_baseConfig.trigger_energy then
    if not self:IsSignUpWindowOpened() then
      local baseSceneView = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView)
      if baseSceneView then
        local helper = baseSceneView:GetPopupChain():GetHelper(EPopupHelper.ScoreRushStart)
        if helper ~= nil then
          helper:SetNeedCheckPopup(true)
        end
      end
    end
    if GameConfig.IsTestMode() then
      Log.Debug("[ScoreRushModel]\232\167\166\229\143\145\230\175\148\232\181\155\239\188\140\229\143\175\228\187\165\230\138\165\229\144\141")
    end
    EventDispatcher.DispatchEvent(self.m_activityDefinition.CanShowIconEvent)
  end
end

function ScoreRushModel:IsOpen()
  return self:GetState() == ActivityState.Started
end

function ScoreRushModel:TryStartRace(callback)
  local robotMap, totalNum = self:_GenerateRobotData()
  if Table.IsEmpty(robotMap) then
    callback(false)
    return
  end
  ApiMessage.GetRobotNameList(totalNum, function(success, resp)
    if not success or resp.rcode == 1 then
      callback(false)
      return
    end
    local robotList = resp.robot_names
    if Table.IsEmpty(robotList) or #robotList ~= totalNum then
      callback(false)
      return
    end
    local icons = UIHelper.GetRandomAvatarIcon(totalNum, true)
    local iconFrames = UIHelper.GetRandomAvatarIconFrame(totalNum)
    for i, name in ipairs(robotList) do
      robotMap[i].name = name
      robotMap[i].icon = icons[i]
      robotMap[i].iconFrame = iconFrames[i]
    end
    self:_SetStartTime(GM.GameModel:GetServerTime())
    self:_SetRobotData(robotMap)
    self:_FillRankList()
    self:UpdateRank(true)
    self:SetCacheGrade(self:GetLatestGrade())
    GM.BIManager:LogAction(self.m_activityDefinition.RaceStartedBIType, {
      id = self:GetId(),
      g = self:GetCacheGrade()
    })
    callback(true)
  end)
end

function ScoreRushModel:TryFinishRace()
  if not self:IsTriggerRace() then
    return
  end
  if self:IsFinished() then
    return
  end
  if GM.GameModel:GetServerTime() - self:GetStartTime() <= self.m_baseConfig.duration then
    return
  end
  self:UpdateRank(true)
  local rewards = self.m_rewardConfig[self:GetCacheGrade()][self.m_rank]
  local isWin = false
  if not Table.IsEmpty(rewards) then
    isWin = true
  end
  self:SetFinished()
  self:_SetRaceResult(isWin)
  local deltaGrade = self:_TryUpdateGrade()
  GM.BIManager:LogAction(self.m_activityDefinition.RaceEndedBIType, {
    id = self:GetId(),
    g = self:GetCacheGrade(),
    a = self:GetMyRank(),
    s = self:GetScore(GM.UserModel:GetUserId()),
    n = #self:GetRankList() - 1,
    w = isWin and 1 or 0,
    ng = deltaGrade
  })
  EventDispatcher.DispatchEvent(self.m_activityDefinition.CanShowIconEvent)
  EventDispatcher.DispatchEvent(EEventType.ScoreRushFinishRace)
end

function ScoreRushModel:GetRankRewards(rank)
  return self.m_rewardConfig[self:GetCacheGrade()][rank]
end

function ScoreRushModel:GetDuration()
  return self.m_baseConfig.duration
end

function ScoreRushModel:CanShowIcon()
  if self:IsFinished() then
    return false
  end
  if self:CanTriggerRace() then
    return true
  end
  if self:IsInRace() then
    return true
  end
  return false
end

function ScoreRushModel:IsInRace()
  if not self:IsOpen() and self:GetState() ~= ActivityState.Ended then
    return false
  end
  if not self:IsTriggerRace() then
    return false
  end
  if self:IsFinished() then
    return false
  end
  return true
end

function ScoreRushModel:CanTriggerRace()
  if not self:IsOpen() then
    return false
  end
  if self:IsTriggerRace() then
    return false
  end
  return self:_GetCurUseEnergy() >= self.m_baseConfig.trigger_energy
end

function ScoreRushModel:IsTriggerRace()
  return self:GetStartTime() ~= 0
end

function ScoreRushModel:UpdateRank(force)
  if not self:IsTriggerRace() then
    return
  end
  if Table.IsEmpty(self.m_rankList) then
    self:_FillRankList()
  end
  if not self.m_scoreMap then
    self.m_scoreMap = {}
  end
  local hasUpdate = false
  local updateScoreMap = {}
  local myId = GM.UserModel:GetUserId()
  for _, id in ipairs(self.m_rankList) do
    if id == myId then
      local score = self:_GetCurScore()
      if score ~= self.m_scoreMap[id] then
        hasUpdate = true
        updateScoreMap[id] = score - (self.m_scoreMap[id] or 0)
      end
      self.m_scoreMap[id] = score
    else
      local score, update = self:_CalculateRobotScore(id, force)
      self.m_scoreMap[id] = self.m_scoreMap[id] or 0
      local deltaScore = score - self.m_scoreMap[id]
      if update then
        hasUpdate = true
        updateScoreMap[id] = deltaScore
        self.m_scoreMap[id] = score
      end
    end
  end
  if not hasUpdate then
    return
  end
  table.sort(self.m_rankList, function(a, b)
    if self.m_scoreMap[a] == self.m_scoreMap[b] then
      return b < a
    end
    return self.m_scoreMap[a] > self.m_scoreMap[b]
  end)
  local myRank
  for i, id in ipairs(self.m_rankList) do
    if id == GM.UserModel:GetUserId() then
      myRank = i
      break
    end
  end
  local lastRank = self.m_rank
  self.m_rank = myRank
  EventDispatcher.DispatchEvent(self.m_activityDefinition.AnyScoreChangedEvent, updateScoreMap)
  if lastRank ~= myRank then
    EventDispatcher.DispatchEvent(self.m_activityDefinition.RankChangedEvent, {last = lastRank, cur = myRank})
  end
end

function ScoreRushModel:GetRankList()
  return self.m_rankList
end

function ScoreRushModel:GetMyRank()
  return self.m_rank
end

function ScoreRushModel:GetScore(userId)
  return self.m_scoreMap[userId]
end

function ScoreRushModel:_FillRankList()
  local robotDataMap = self:_GetRobotDataMap()
  self.m_rankList = {}
  if Table.IsEmpty(robotDataMap) then
    Log.Error("[ScoreRushModel]\232\142\183\229\143\150\229\129\135\228\186\186\230\142\146\229\144\141\229\164\177\232\180\165\239\188\140\230\137\190\228\184\141\229\136\176\229\129\135\228\186\186\230\149\176\230\141\174")
    return
  end
  table.insert(self.m_rankList, GM.UserModel:GetUserId())
  for id, _ in pairs(self.m_robotDataMap) do
    table.insert(self.m_rankList, id)
  end
end

function ScoreRushModel:_GenerateRobotData()
  local robotDataMap = {}
  local grade = self:GetLatestGrade()
  local configs = self.m_botUpdateConfig[grade]
  if Table.IsEmpty(configs) then
    Log.Error("[ScoreRushModel]\231\148\159\230\136\144\229\129\135\228\186\186\230\149\176\230\141\174\229\164\177\232\180\165\239\188\140\230\137\190\228\184\141\229\136\176\229\175\185\229\186\148\230\161\163\228\189\141\231\154\132\233\133\141\231\189\174")
    return
  end
  local idx = 0
  for _, v in ipairs(configs) do
    for i = 1, v.num do
      idx = idx + 1
      local robotData = {
        time = GM.GameModel:GetServerTime(),
        updateType = Table.ListRandomSelectOne(v.update_type),
        endScore = MathUtil.Random(v.score_min, v.score_max)
      }
      robotDataMap[idx] = robotData
    end
  end
  return robotDataMap, idx
end

function ScoreRushModel:_CalculateRobotScore(robotId, force)
  local robotData = self:GetRobotData(robotId)
  if not robotData then
    Log.Error("[ScoreRushModel]\232\142\183\229\143\150\229\129\135\228\186\186\229\136\134\230\149\176\229\164\177\232\180\165\239\188\140\229\129\135\228\186\186id\239\188\154" .. robotId)
    return 0
  end
  if self:IsFinished() then
    return robotData.endScore, self.m_scoreMap[robotId] ~= robotData.endScore
  end
  if not self.m_robotScoreNextUpdateTimeMap then
    self.m_robotScoreNextUpdateTimeMap = {}
  end
  if not force and self.m_robotScoreNextUpdateTimeMap[robotId] and GM.GameModel:GetServerTime() < self.m_robotScoreNextUpdateTimeMap[robotId] then
    return self.m_scoreMap[robotId] or 0, false
  end
  if self.m_robotScoreUpdateType == ScoreRushRobotScoreUpdateType.FixedDuration then
    self.m_robotScoreNextUpdateTimeMap[robotId] = GM.GameModel:GetServerTime() + ROBOT_SCORE_UPDATE_FIX_DURATION
  else
    self.m_robotScoreNextUpdateTimeMap[robotId] = GM.GameModel:GetServerTime() + MathUtil.Random(1, ROBOT_SCORE_UPDATE_RANDOM_RANGE)
  end
  local easeType = ScoreRushBotUpdateTypeToEaseType[robotData.updateType]
  if easeType == nil then
    Log.Error("[ScoreRushModel]\232\142\183\229\143\150\229\129\135\228\186\186\229\136\134\230\149\176\230\155\178\231\186\191\231\177\187\229\158\139\233\148\153\232\175\175\239\188\140updateType\239\188\154" .. robotData.updateType)
    return self.m_scoreMap[robotId] or 0
  end
  local score = EaseHelper.GetInterpolatedValue(0, robotData.endScore, self.m_baseConfig.duration, GM.GameModel:GetServerTime() - robotData.time, easeType)
  if GameConfig.IsTestMode() then
    Log.Debug("[ScoreRushModel]\229\136\183\230\150\176\229\129\135\228\186\186[" .. robotId .. "]\229\136\134\230\149\176\239\188\140\229\136\134\230\149\176\239\188\154" .. math.floor(score) .. ", \230\152\175\229\144\166\229\188\186\229\136\183\229\136\134\230\149\176\239\188\154" .. (force and "\230\152\175" or "\229\144\166") .. "\n\229\136\183\230\150\176\231\177\187\229\158\139\239\188\154" .. (self.m_robotScoreUpdateType == ScoreRushRobotScoreUpdateType.FixedDuration and "\229\155\186\229\174\15415\231\167\146" or "\233\154\143\230\156\1861~30\231\167\146") .. "\n\229\136\183\230\150\176\230\155\178\231\186\191\239\188\154" .. easeType:ToString() .. "\n\229\189\147\229\137\141\229\183\178\231\187\143\232\191\135\230\151\182\233\151\180\239\188\154" .. GM.GameModel:GetServerTime() - robotData.time .. "\231\167\146" .. "\n\230\180\187\229\138\168\230\140\129\231\187\173\230\151\182\233\151\180\239\188\154" .. self.m_baseConfig.duration .. "\231\167\146" .. "\n\229\189\147\229\137\141\229\136\134\230\149\176\239\188\154" .. math.floor(score) .. "\n\231\187\147\230\157\159\229\136\134\230\149\176\239\188\154" .. robotData.endScore .. "\n\228\184\139\230\172\161\229\136\183\230\150\176\230\151\182\233\151\180\239\188\154" .. self.m_robotScoreNextUpdateTimeMap[robotId] - GM.GameModel:GetServerTime() .. "\231\167\146\229\144\142")
  end
  return math.floor(score), true
end

function ScoreRushModel:GetNewGradeValue(historyResult, curGrade)
  local upgradeCondition = self.m_baseConfig.continuous_win_upgrade
  local degradeCondition = self.m_baseConfig.continuous_lose_degrade
  if upgradeCondition == 0 and degradeCondition == 0 then
    return self.m_playerConfig.grade
  end
  local lastResult = historyResult[#historyResult]
  if lastResult == SCORE_RUSH_RESULT_WIN then
    if upgradeCondition == 0 or upgradeCondition > #historyResult then
      return curGrade
    end
    local canUpgrade = true
    for i = 1, upgradeCondition do
      if historyResult[#historyResult - i + 1] == SCORE_RUSH_RESULT_LOSE then
        canUpgrade = false
      end
    end
    if canUpgrade then
      return math.min(curGrade + 1, 5)
    end
  elseif lastResult == SCORE_RUSH_RESULT_LOSE then
    if degradeCondition == 0 or degradeCondition > #historyResult then
      return curGrade
    end
    local canDegrade = true
    for i = 1, degradeCondition do
      if historyResult[#historyResult - i + 1] == SCORE_RUSH_RESULT_WIN then
        canDegrade = false
      end
    end
    if canDegrade then
      return math.max(curGrade - 1, 1)
    end
  end
  return curGrade
end

function ScoreRushModel:_GetCurUseEnergy()
  return self.m_dbTable:GetValue(DBKey.CurUseEnergy, "value") or 0
end

function ScoreRushModel:_SetCurUseEnergy(value)
  if GameConfig.IsTestMode() then
    Log.Debug("[ScoreRushModel]\229\189\147\229\137\141\230\182\136\232\128\151\232\131\189\233\135\143\239\188\154" .. value)
  end
  self.m_dbTable:Set(DBKey.CurUseEnergy, "value", value)
end

function ScoreRushModel:GetStartTime()
  return self.m_dbTable:GetValue(DBKey.StartTime, "value") or 0
end

function ScoreRushModel:_SetStartTime(value)
  self.m_dbTable:Set(DBKey.StartTime, "value", value)
end

function ScoreRushModel:_TryUpdateGrade()
  local oldGrade = self:GetLatestGrade()
  local newGrade = self:GetNewGradeValue(self:GetRaceResultList(), oldGrade)
  if newGrade ~= oldGrade then
    self:SetLatestGrade(newGrade)
  end
  return newGrade - oldGrade
end

function ScoreRushModel:GetLatestGrade()
  if self.m_baseConfig.continuous_win_upgrade == 0 and self.m_baseConfig.continuous_lose_degrade == 0 then
    return self.m_playerConfig.grade or 1
  end
  return tonumber(GM.MiscModel:GetScoreRushGrade()) or self.m_playerConfig.grade or 1
end

function ScoreRushModel:SetLatestGrade(value)
  if value < 1 then
    value = 1
  end
  if value > SCORE_RUSH_MAX_GRADE then
    value = SCORE_RUSH_MAX_GRADE
  end
  GM.MiscModel:SetScoreRushGrade(tostring(value))
  Log.Debug("[ScoreRushModel]\232\174\190\231\189\174\229\189\147\229\137\141\230\161\163\228\189\141\239\188\154" .. value)
end

function ScoreRushModel:GetCacheGrade()
  return self.m_dbTable:GetValue(DBKey.CacheGrade, "value") or 1
end

function ScoreRushModel:SetCacheGrade(value)
  self.m_dbTable:Set(DBKey.CacheGrade, "value", value)
end

function ScoreRushModel:SetFinished()
  self.m_dbTable:Set(DBKey.IsFinished, "value", "1")
end

function ScoreRushModel:IsFinished()
  return self.m_dbTable:GetValue(DBKey.IsFinished, "value") == "1"
end

function ScoreRushModel:SetPopEndWindow()
  self.m_dbTable:Set(DBKey.PopEndWindow, "value", "1")
end

function ScoreRushModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(DBKey.PopEndWindow, "value") ~= "1"
end

function ScoreRushModel:GetRaceResultList()
  local resultList = {}
  local resultStr = GM.MiscModel:GetScoreRushResult()
  if not StringUtil.IsNilOrEmpty(resultStr) then
    resultList = StringUtil.Split(resultStr, "@")
  end
  return resultList
end

function ScoreRushModel:_SetRaceResult(isWin)
  local resultList = self:GetRaceResultList()
  table.insert(resultList, isWin and SCORE_RUSH_RESULT_WIN or SCORE_RUSH_RESULT_LOSE)
  if #resultList > SCORE_RUSH_MAX_GRADE then
    table.remove(resultList, 1)
  end
  GM.MiscModel:SetScoreRushResult(table.concat(resultList, "@"))
end

function ScoreRushModel:SetRobotScoreUpdateType(updateType)
  self.m_robotScoreUpdateType = updateType
end

function ScoreRushModel:GetRobotData(robotId)
  local robotDataMap = self:_GetRobotDataMap()
  return robotDataMap[robotId]
end

function ScoreRushModel:_GetRobotDataMap()
  if self.m_robotDataMap == nil then
    local robotDataStr = self.m_dbTable:GetValue(DBKey.RobotData, "value") or ""
    if robotDataStr == "" then
      self.m_robotDataMap = {}
    else
      self.m_robotDataMap = json.decode(robotDataStr)
    end
  end
  return self.m_robotDataMap
end

function ScoreRushModel:_SetRobotData(robotData)
  self.m_robotDataMap = robotData
  self.m_dbTable:Set(DBKey.RobotData, "value", json.encode(robotData))
end

function ScoreRushModel:_GetCurScore()
  return self.m_dbTable:GetValue(DBKey.CurScore, "value") or 0
end

function ScoreRushModel:_SetCurScore(value)
  self.m_dbTable:Set(DBKey.CurScore, "value", value)
end

function ScoreRushModel:IsSignUpWindowOpened()
  return self.m_signUpWindowOpened
end

function ScoreRushModel:SetSignUpWindowOpened()
  self.m_signUpWindowOpened = true
end

function ScoreRushModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.CanShowIconEvent
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_scoreRushBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_scoreRushBubbleCount",
    activityType = self.m_type,
    scrollToFunName = "ScrollToScoreRushBoardEntry",
    checkFun = function()
      return self:CanShowIcon()
    end
  }
end

function ScoreRushModel:GetHudEntryShowConfig()
  return {
    Type = "scoreRush",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.CanShowIconEvent
    },
    EntryPrefabConfigName = self.m_activityDefinition.HudEntryPrefabName,
    CheckFunc = function()
      return self:CanShowIcon()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = self.m_activityDefinition.EntryImageName,
    OnClickedFunc = function()
      self:OpenWindow()
    end,
    RedPointType = EntryRedPointType.Exc,
    GetRedPointNumFunc = function()
      if self:CanTriggerRace() and not self:IsInRace() then
        return 1
      end
      return 0
    end
  }
end

function ScoreRushModel:OpenWindow()
  if self:IsFinished() then
    Log.Error("[ScoreRushModel]\230\137\147\229\188\128\231\170\151\229\143\163\229\164\177\232\180\165\239\188\140\230\175\148\232\181\155\229\183\178\231\187\147\230\157\159")
    return
  end
  if self:IsInRace() then
    if not ApplicationManager.Instance.isNetworkConnected then
      GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
      return
    end
    GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType(), false)
  else
    GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType(), false)
  end
end

function ScoreRushModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end
