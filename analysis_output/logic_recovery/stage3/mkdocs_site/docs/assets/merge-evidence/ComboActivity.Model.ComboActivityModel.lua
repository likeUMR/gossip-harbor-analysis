ComboActivityModel = setmetatable({}, BaseActivityModel)
ComboActivityModel.__index = ComboActivityModel
local DBKeys = {
  PopEndWindow = "PopEndWindow",
  Score = "score",
  LastDisplayedLevel = "lastDisplayedLevel",
  LastDisplayedScore = "lastDisplayedScore",
  MyInfo = "myInfo",
  Stage = "stage",
  LastMultiNum = "lastMultiNum",
  StayNum = "stayNum",
  RobotDatas = "robotDatas",
  EntryTime = "entryTime",
  LastToken = "lastToken",
  LastRank = "lastRank",
  GameTimes = "gameTimes",
  FirstShowInRound = "firstShowInRound",
  SimNetwork = "simNetwork",
  FirstReadyInRound = "firstReadyInRound"
}
local DBColumnValue = "value"
ComboActivityModel.MyId = 1
ComboTaskState = {
  WaitSignUp = 0,
  Doing = 1,
  Fail = 2,
  Win = 3
}
ComboActivityModel.AddTokenScene = {Merge = "merge", Order = "order"}

function ComboActivityModel:Init(activityType, activityDataTable)
  self.m_activityDefinition = ComboActivityDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  self:_InitPlayer(activityDataTable)
  self.m_lastNetState = self:HasNetwork()
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
end

function ComboActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self:UpdateScoreContent()
  self.m_lateInit = true
end

function ComboActivityModel:_InitPlayer(virtualDBTable)
  local players = virtualDBTable:GetValue(DBKeys.RobotDatas, DBColumnValue)
  if IsNil(players) then
    self.m_taskState = ComboTaskState.WaitSignUp
    return
  end
  local arr = json.decode(players)
  self.m_arrPlayerData = {}
  for _, value in ipairs(arr) do
    local lastToken = self:GetLastToken(value.id)
    local lastRank = self:GetLastRank(value.id)
    local player = ComboPlayerData.Create(value, self)
    player:SetLastToken(lastToken)
    player:SetLastRank(lastRank)
    self.m_arrPlayerData[#self.m_arrPlayerData + 1] = player
  end
  local myTrack = #self.m_arrPlayerData == 4 and 3 or 2
  self:_AddMySelf(myTrack)
  self:UpdateContent()
end

function ComboActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function ComboActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_arrPlayerData = {}
  self.m_taskState = nil
  self:UpdateScoreContent()
  self.m_robotConfig = self:_GetUseConfig()
end

function ComboActivityModel:_LoadOtherServerConfig(config)
  local miscConfigReader = MiscConfigReader.Create(config)
  self.m_bLoseReturnLast = miscConfigReader:GetInteger("combo_lose_multi_return") == 2
  self.m_config.arrComboLevel = {}
  local mapComboLevel = {}
  for _, data in ipairs(config.comboLevelConfig) do
    local multiNum = tostring(data.multi_num)
    mapComboLevel[multiNum] = mapComboLevel[multiNum] or {}
    table.insert(mapComboLevel[multiNum], data)
  end
  for multi, data in pairs(mapComboLevel) do
    if 1 < #data then
      table.sort(data, function(a, b)
        return a.stay_round < b.stay_round
      end)
    end
    table.insert(self.m_config.arrComboLevel, {
      multiNum = tonumber(multi),
      data = data
    })
  end
  Log.Assert(#self.m_config.arrComboLevel == 4, "ComboActivityModel:_LoadOtherServerConfig, arrComboLevel length is not 4")
  table.sort(self.m_config.arrComboLevel, function(a, b)
    return a.multiNum < b.multiNum
  end)
  self.m_config.mapComboRobot = {}
  for _, data in ipairs(config.comboRobotConfig) do
    local arr = {}
    for k, spConfig in ipairs(data.speed) do
      local arrSp = StringUtil.Split(spConfig, ",")
      local sp = {
        timeWeight = tonumber(arrSp[1]),
        tokenWeight = tonumber(arrSp[2])
      }
      table.insert(arr, sp)
    end
    table.sort(arr, function(a, b)
      return a.timeWeight < b.timeWeight
    end)
    data.sp = arr
    local strCode = tostring(data.code)
    self.m_config.mapComboRobot[strCode] = self.m_config.mapComboRobot[strCode] or {}
    table.insert(self.m_config.mapComboRobot[strCode], data)
  end
  self.m_config.comboRewards = config.comboPrgReward
  table.sort(self.m_config.comboRewards, function(a, b)
    return a.round < b.round
  end)
  local mergeItemConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_config.mergeItemScore = {}
  for _, data in ipairs(mergeItemConfig) do
    self.m_config.mergeItemScore[data.item_id] = data
  end
  self.m_config.orderScore = {}
  local isUseDiff = false
  for _, cfg in pairs(config.eventOrderScore) do
    table.insert(self.m_config.orderScore, Table.DeepCopy(cfg, true))
    if not isUseDiff and IsNumber(cfg.diff_score_min) then
      isUseDiff = true
    end
  end
  self.m_addScoreUseDiff = isUseDiff
  if isUseDiff then
    table.sort(self.m_config.orderScore, function(a, b)
      return a.diff_score_min < b.diff_score_min
    end)
  else
    table.sort(self.m_config.orderScore, function(a, b)
      return a.gold_min < b.gold_min
    end)
  end
  self.m_robotConfig = self:_GetUseConfig()
end

function ComboActivityModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function ComboActivityModel:IsActivityOpen()
  local state = self:GetState()
  if state ~= ActivityState.Preparing and state ~= ActivityState.Started or self.m_cacheState == ActivityState.Ended then
    return false
  end
  return true
end

function ComboActivityModel:CanShowBoardEntry()
  return self:GetState() == ActivityState.Started and self.m_cacheState ~= ActivityState.Ended
end

function ComboActivityModel:IsLostReturnLast()
  return self.m_bLoseReturnLast
end

function ComboActivityModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  self:UpdateContent()
  local curNetState = self:HasNetwork()
  if curNetState and (self.m_taskState == ComboTaskState.Fail or self.m_taskState == ComboTaskState.Win and not self.m_lastNetState) and GM.UIManager:GetOpenedViewByName(self.m_activityDefinition.MainWindowPrefabName) == nil then
    EventDispatcher.DispatchEvent(EEventType.ScheduleOpenComboMainWindow, true)
  end
  local curRank = self:GetMyRank()
  if self.m_lastNetState ~= curNetState or curNetState and self.m_lastMyRank ~= curRank then
    EventDispatcher.DispatchEvent(EEventType.ComboRefreshEntry)
    self.m_lastNetState = curNetState
    self.m_lastMyRank = curRank
  end
end

function ComboActivityModel:GetGapTime()
  if self.m_taskState == ComboTaskState.Doing then
    local entryTime = self:GetEntryTime()
    return GM.GameModel:GetServerTime() - entryTime
  end
  return self.m_maxGapTime or 0
end

function ComboActivityModel:UpdateContent()
  if Table.IsEmpty(self.m_arrPlayerData) then
    self.m_taskState = ComboTaskState.WaitSignUp
    return
  end
  if self.m_taskState == ComboTaskState.Win or self.m_taskState == ComboTaskState.Fail then
    return
  end
  local entryTime = self:GetEntryTime()
  local gapTime = GM.GameModel:GetServerTime() - entryTime
  self:SortPlayer(gapTime)
  local myRank = 0
  for index, value in ipairs(self.m_arrPlayerData) do
    value:SetRank(index)
    if value:IsMySelf() then
      myRank = index
    end
  end
  local myToken = self:GetMyToken()
  local lastRank = #self.m_arrPlayerData == 3 and 1 or 3
  if myToken >= self.m_robotConfig.token_num and myRank <= lastRank or self.m_arrPlayerData[lastRank].token >= self.m_robotConfig.token_num then
    if myToken >= self.m_robotConfig.token_num and myRank <= lastRank then
      self.m_taskState = ComboTaskState.Win
      self.m_maxGapTime = self.m_arrPlayerData[myRank].seconds
    else
      self.m_taskState = ComboTaskState.Fail
      self.m_maxGapTime = self.m_arrPlayerData[lastRank].seconds
    end
  else
    self.m_taskState = ComboTaskState.Doing
  end
end

function ComboActivityModel:UpdateScoreContent()
  self.m_currentStep = 0
  self.m_currentScore = 0
  self.m_cacheState = nil
  if self.m_config == nil then
    return
  end
  local score = self:GetTotalScore()
  local tmpScore = 0
  for _, rewardConfig in ipairs(self.m_config.comboRewards) do
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
  if not self.m_bSync then
    self.m_bSync = true
    self:SetLastDisplayedLevelAndScore(self.m_currentStep, self.m_currentScore)
  end
end

function ComboActivityModel:SortPlayer(gapTime)
  for _, v in ipairs(self.m_arrPlayerData) do
    v:UpdateContent(gapTime)
  end
  table.sort(self.m_arrPlayerData, function(a, b)
    if a.token ~= b.token then
      return a.token > b.token
    elseif a.token ~= 0 and a.seconds ~= b.seconds then
      return a.seconds < b.seconds
    else
      return a.id < b.id
    end
  end)
end

function ComboActivityModel:GetMaxLevel()
  return #self.m_config.comboRewards
end

function ComboActivityModel:GetTargetToken()
  if self.m_robotConfig == nil then
    return 0
  end
  return self.m_robotConfig.token_num or 0
end

function ComboActivityModel:ClearWhenWinOrFail()
  if self.m_taskState ~= ComboTaskState.Win and self.m_taskState ~= ComboTaskState.Fail then
    return
  end
  self:LogActionWhenFinish()
  self.m_dbTable:Remove(DBKeys.MyInfo)
  self.m_dbTable:Remove(DBKeys.LastToken)
  self.m_dbTable:Remove(DBKeys.LastRank)
  self.m_dbTable:Remove(DBKeys.RobotDatas)
  self.m_dbTable:Remove(DBKeys.FirstReadyInRound)
  self.m_arrPlayerData = {}
  self:UpdateContent()
  self:UpdateScoreContent()
  self:SetFirstShowInRound(true)
  self.m_robotConfig = self:_GetUseConfig()
  EventDispatcher.DispatchEvent(EEventType.ComboRefreshEntry)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function ComboActivityModel:LogActionWhenFinish()
  if Table.IsEmpty(self.m_arrPlayerData) then
    return
  end
  local entryTime = self:GetEntryTime()
  local gameGapTime = self:GetGapTime()
  local score = 0
  if self.m_taskState == ComboTaskState.Win then
    score = self.m_robotConfig.score_rwd * self.m_robotConfig.multi_num
  end
  local lowestRank = #self.m_arrPlayerData == 5 and 3 or 1
  local tbPlayer = {}
  for _, data in ipairs(self.m_arrPlayerData) do
    if not data:IsMySelf() then
      local token, _ = data:GetTokenAndSeconds(gameGapTime)
      local rank = data:GetRank()
      local tb = {
        userId = data:GetId(),
        token = token,
        rank = rank,
        isWin = token >= self.m_robotConfig.token_num and lowestRank >= rank,
        type = data:GetType()
      }
      table.insert(tbPlayer, tb)
    end
  end
  local eAct = {
    round = self:GetGameTimes(),
    multi = self:GetCurMultiNum() .. "_" .. self.m_robotConfig.stay_round,
    id = self:GetId(),
    token = self:GetMyToken(),
    addScore = score,
    totalScore = self:GetTotalScore(),
    isWin = self.m_taskState == ComboTaskState.Win,
    rank = self:GetMyRank(),
    stime = entryTime,
    etime = entryTime + gameGapTime,
    g = self:GetServerConfigGroupId(),
    player = tbPlayer
  }
  self:_UpdateMultiByState(self.m_taskState)
  local isChangeMulti = self:GetStayNum() == 1
  eAct.changeMulti = isChangeMulti
  GM.BIManager:LogAction(self.m_activityDefinition.RoundFinish, eAct)
end

function ComboActivityModel:CanSignUp()
  return self:GetState() == ActivityState.Started and self.m_cacheState ~= ActivityState.Ended and (self.m_taskState == nil or self.m_taskState == ComboTaskState.WaitSignUp)
end

function ComboActivityModel:GetTaskState()
  return self.m_taskState
end

function ComboActivityModel:SignUp()
  if not self:CanSignUp() then
    return false
  end
  self:SetEntryTime(GM.GameModel:GetServerTime() + 2)
  local gameTimes = self:GetGameTimes()
  self:SetGameTimes(gameTimes + 1)
  self.m_robotConfig = self:_GetUseConfig()
  local arrRobot = {}
  for _, data in ipairs(self.m_robotConfig.robot_code) do
    local arrTmp = Table.DeepCopy(self.m_config.mapComboRobot[tostring(data.RobotCode)])
    local arr = Table.ListRandomSelectN(arrTmp, data.RobotNum)
    Table.ListAppend(arrRobot, arr)
  end
  local arrAvatar = UIHelper.GetRandomAvatarIcon(#arrRobot)
  local arrAvatarFrame = UIHelper.GetRandomAvatarIconFrame(#arrRobot)
  local arrTrack = #arrRobot == 2 and {1, 3} or {
    2,
    4,
    1,
    5
  }
  self.m_arrPlayerData = {}
  local targetToken = self.m_robotConfig.token_num
  for i = 1, #arrRobot do
    local robotData = {}
    local lastMaxSecond = 0
    local lastMaxToken = 0
    local arrSpeed = {}
    local totalTime = math.random(arrRobot[i].time_min, arrRobot[i].time_max)
    for k, speed in ipairs(arrRobot[i].sp) do
      local maxSecond = math.floor(totalTime * speed.timeWeight / 1000)
      local sd = speed.timeWeight == 1000 and totalTime or math.random(lastMaxSecond, maxSecond)
      local maxToken = math.floor(targetToken * speed.tokenWeight / 100)
      local tk = maxToken + math.random(-10, 10)
      tk = math.max(lastMaxToken, tk)
      tk = math.min(maxToken, tk)
      if speed.tokenWeight == 100 then
        tk = targetToken
      end
      local token = {seconds = sd, token = tk}
      lastMaxSecond = maxSecond
      lastMaxToken = maxToken
      table.insert(arrSpeed, token)
    end
    robotData.id = i + 1
    robotData.speed = arrSpeed
    robotData.icon = arrAvatar[i]
    robotData.iconFrame = arrAvatarFrame[i]
    robotData.lastToken = 0
    robotData.lastRank = 0
    robotData.track = arrTrack[i]
    robotData.type = arrRobot[i].code .. "_" .. arrRobot[i].index
    local pd = ComboPlayerData.Create(robotData, self)
    table.insert(self.m_arrPlayerData, pd)
  end
  self:SaveRobotDatas()
  local myTrack = #arrRobot == 4 and 3 or 2
  self:_AddMySelf(myTrack)
  self:UpdateContent()
  self:UpdateScoreContent()
  EventDispatcher.DispatchEvent(EEventType.ComboRefreshEntry)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  local eAct = {
    round = self:GetGameTimes(),
    multi = self:GetCurMultiNum() .. "_" .. self.m_robotConfig.stay_round,
    id = self:GetId(),
    stime = self:GetEntryTime(),
    groupId = self:GetServerConfigGroupId()
  }
  GM.BIManager:LogAction(self.m_activityDefinition.SignUpSuccess, eAct)
  return true
end

function ComboActivityModel:GetAllPlayerData()
  return self.m_arrPlayerData
end

function ComboActivityModel:_CanAddToken()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_taskState == ComboTaskState.Doing then
    return true
  elseif self:GetMyToken() < self:GetTargetToken() and not self:HasNetwork() then
    return true
  end
  return false
end

function ComboActivityModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() ~= GM.MainBoardModel then
    return
  end
  if not self:_CanAddToken() then
    return
  end
  self:_TryAddMergeToken(message.Source)
end

function ComboActivityModel:_TryAddMergeToken(itemModel)
  local itemType = itemModel:GetType()
  if self.m_config.mergeItemScore[itemType] == nil then
    return
  end
  local tokenNum = self.m_config.mergeItemScore[itemType].merge_score
  if tokenNum ~= nil then
    self:_AddToken(tokenNum, ComboActivityModel.AddTokenScene.Merge, itemModel)
  end
end

function ComboActivityModel:GetAddScoreByOrder(order)
  if not self:_CanAddToken() then
    return
  end
  local selectedIdx, score
  if self.m_addScoreUseDiff then
    local diffScore = order:GetDiffScore()
    if diffScore == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_config.orderScore, diffScore, "diff_score_min", "diff_score_max")
    score = diffScore
  else
    local price = order:GetPrice()
    if price == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_config.orderScore, price, "gold_min", "gold_max")
    score = price
  end
  if selectedIdx == nil then
    return
  end
  local selected = self.m_config.orderScore[selectedIdx]
  local count = selected.reward_num_percentage and math.floor(score * selected.reward_num_percentage / 10000) or selected.reward_num_fix
  if count <= 0 then
    return
  end
  return {
    [PROPERTY_TYPE] = self.m_activityDefinition.ActivityTokenPropertyType,
    [PROPERTY_COUNT] = count
  }
end

function ComboActivityModel:AcquireActivityToken(num)
  self:_AddToken(num, ComboActivityModel.AddTokenScene.Order)
end

function ComboActivityModel:_AddToken(num, scene, itemModel)
  if not self:_CanAddToken() then
    return false
  end
  local myToken = self:GetMyToken()
  local targetToken = self:GetTargetToken()
  if myToken >= targetToken then
    return false
  end
  local tokenNum = math.min(myToken + num, targetToken)
  local serTime = GM.GameModel:GetServerTime()
  local entryTime = self:GetEntryTime()
  local data = {
    [DBKeys.MyInfo] = {
      seconds = serTime - entryTime,
      token = tokenNum
    }
  }
  self.m_dbTable:BatchSet(data)
  local addToken = tokenNum - myToken
  EventDispatcher.DispatchEvent(self.m_activityDefinition.TokenChangedEvent, {
    Token = addToken,
    Scene = scene,
    Source = itemModel
  })
  local biInfo = {
    token = addToken,
    Source = scene,
    id = self:GetId(),
    groupId = self:GetServerConfigGroupId()
  }
  GM.BIManager:LogAction(self.m_activityDefinition.GodToken, biInfo)
  return true
end

function ComboActivityModel:_UpdateMultiByState(taskState)
  if taskState ~= ComboTaskState.Win and taskState ~= ComboTaskState.Fail then
    return
  end
  local stage = self:GetStage()
  local loseStage = self.m_bLoseReturnLast and stage - 1 or 1
  local rsStage = taskState == ComboTaskState.Win and stage + 1 or loseStage
  self:SetLastStage(stage)
  self:SetStage(rsStage)
  if stage == self:GetStage() then
    self:SetStayNum(self:GetStayNum() + 1)
  else
    self:SetStayNum(1)
  end
end

function ComboActivityModel:ClearCacheReward(bRewardInView)
  if not Table.IsEmpty(self.m_cacheRewards) then
    if bRewardInView then
      RewardApi.AcquireRewardsInView(self.m_cacheRewards, {})
    end
    self.m_cacheRewards = {}
  end
end

function ComboActivityModel:AddScore()
  local addScore = self.m_robotConfig.score_rwd * self.m_robotConfig.multi_num
  local lastStep = self.m_currentStep
  local score = self:GetTotalScore() + addScore
  self.m_dbTable:Set(DBKeys.Score, DBColumnValue, score)
  self:LogActivity(EBIType.ActivityAddScore, addScore)
  self:UpdateScoreContent()
  local step = 0
  local rewards = {}
  if lastStep < self.m_currentStep then
    for _, rewardConfig in ipairs(self.m_config.comboRewards) do
      step = step + 1
      if lastStep <= step and step < self.m_currentStep then
        Table.ListAppend(rewards, {
          rewardConfig.rewards
        })
        self:LogActivity(EBIType.ActivityRankUp, step)
      end
    end
    if not Table.IsEmpty(rewards) then
      RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_activityDefinition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
    end
    self.m_cacheRewards = rewards
  end
  if self.m_cacheState == ActivityState.Ended then
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
    EventDispatcher.DispatchEvent(self.m_activityDefinition.ScoreChangedEvent)
  end
  return rewards
end

function ComboActivityModel:SaveRobotDatas()
  if Table.IsEmpty(self.m_arrPlayerData) then
    return
  end
  local arr = {}
  for _, v in ipairs(self.m_arrPlayerData) do
    if not v:IsMySelf() then
      table.insert(arr, v:GetData())
    end
  end
  self.m_dbTable:Set(DBKeys.RobotDatas, DBColumnValue, json.encode(arr))
end

function ComboActivityModel:_GetUseConfig()
  if self.m_config == nil then
    return
  end
  local stage = self:GetStage()
  local stayNum = math.min(self:GetStayNum(), #self.m_config.arrComboLevel[stage].data)
  local robotCfg = self.m_config.arrComboLevel[stage].data[stayNum]
  return robotCfg
end

function ComboActivityModel:_AddMySelf(track)
  self.m_arrPlayerData = self.m_arrPlayerData or {}
  local data = {
    id = ComboActivityModel.MyId,
    track = track,
    lastToken = self:GetLastToken(ComboActivityModel.MyId),
    lastRank = self:GetLastRank(ComboActivityModel.MyId)
  }
  local pd = ComboPlayerData.Create(data, self)
  table.insert(self.m_arrPlayerData, pd)
end

function ComboActivityModel:GetCurScoreRwd()
  return self.m_robotConfig.score_rwd
end

function ComboActivityModel:GetCurMultiNum()
  return self.m_robotConfig.multi_num
end

function ComboActivityModel:GetMultiNumbers()
  local arr = {}
  for _, data in ipairs(self.m_config.arrComboLevel) do
    table.insert(arr, data.multiNum)
  end
  return arr
end

function ComboActivityModel:GetMyRank()
  if Table.IsEmpty(self.m_arrPlayerData) then
    return 0
  end
  for _, v in ipairs(self.m_arrPlayerData) do
    if v:IsMySelf() then
      return v:GetRank()
    end
  end
end

function ComboActivityModel:GetTotalScore()
  return self.m_dbTable:GetValue(DBKeys.Score, DBColumnValue) or 0
end

function ComboActivityModel:GetScore()
  return self.m_currentScore
end

function ComboActivityModel:GetLevel()
  return self.m_currentStep
end

function ComboActivityModel:IsWin()
  return self.m_taskState == ComboTaskState.Win
end

function ComboActivityModel:GetCurRewardScoreAndMulti()
  return self.m_robotConfig.score_rwd, self.m_robotConfig.multi_num
end

function ComboActivityModel:GetServerConfigGroupId()
  return self.m_robotConfig.groupId
end

function ComboActivityModel:GetLastDisplayedLevelAndScore()
  local lastDisplayedLevel = self.m_dbTable:GetValue(DBKeys.LastDisplayedLevel, DBColumnValue) or 1
  local lastDisplayedScore = self.m_dbTable:GetValue(DBKeys.LastDisplayedScore, DBColumnValue) or 0
  return lastDisplayedLevel, lastDisplayedScore
end

function ComboActivityModel:SetLastDisplayedLevelAndScore(lastDisplayedLevel, lastDisplayedScore)
  self.m_dbTable:Set(DBKeys.LastDisplayedLevel, DBColumnValue, lastDisplayedLevel)
  self.m_dbTable:Set(DBKeys.LastDisplayedScore, DBColumnValue, lastDisplayedScore)
end

function ComboActivityModel:GetAvenueRewardConfig()
  return self.m_config.comboRewards
end

function ComboActivityModel:GetAvenueLevelConfig(level)
  return self.m_config.comboRewards[level]
end

function ComboActivityModel:SetPopEndWindow()
  self.m_dbTable:Set(DBKeys.PopEndWindow, "value", "1")
end

function ComboActivityModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(DBKeys.PopEndWindow, "value") ~= "1"
end

function ComboActivityModel:GetStage()
  return self.m_dbTable:GetValue(DBKeys.Stage, DBColumnValue) or 1
end

function ComboActivityModel:SetStage(num)
  if 0 < num and num <= 4 then
    self.m_dbTable:Set(DBKeys.Stage, DBColumnValue, num)
  end
end

function ComboActivityModel:GetLastStage()
  return self.m_dbTable:GetValue(DBKeys.LastMultiNum, DBColumnValue) or 0
end

function ComboActivityModel:SetLastStage(stage)
  self.m_dbTable:Set(DBKeys.LastMultiNum, DBColumnValue, stage)
end

function ComboActivityModel:GetMyToken()
  return self.m_dbTable:GetValue(DBKeys.MyInfo, "token") or 0
end

function ComboActivityModel:GetMySecond()
  return self.m_dbTable:GetValue(DBKeys.MyInfo, "seconds") or 0
end

function ComboActivityModel:GetStayNum()
  return self.m_dbTable:GetValue(DBKeys.StayNum, DBColumnValue) or 1
end

function ComboActivityModel:SetStayNum(num)
  self.m_dbTable:Set(DBKeys.StayNum, DBColumnValue, num)
end

function ComboActivityModel:GetGameTimes()
  return self.m_dbTable:GetValue(DBKeys.GameTimes, DBColumnValue) or 0
end

function ComboActivityModel:SetGameTimes(num)
  self.m_dbTable:Set(DBKeys.GameTimes, DBColumnValue, num)
end

function ComboActivityModel:SetFirstShowInRound(status)
  self.m_dbTable:Set(DBKeys.FirstShowInRound, DBColumnValue, status)
end

function ComboActivityModel:GetFirstShowInRound()
  return self.m_dbTable:GetValue(DBKeys.FirstShowInRound, DBColumnValue)
end

function ComboActivityModel:SetFirstReadyInRound(status)
  self.m_dbTable:Set(DBKeys.FirstReadyInRound, DBColumnValue, status)
end

function ComboActivityModel:GetFirstReadyInRound()
  return self.m_dbTable:GetValue(DBKeys.FirstReadyInRound, DBColumnValue) == nil
end

function ComboActivityModel:SaveLastToken()
  if Table.IsEmpty(self.m_arrPlayerData) then
    self.m_dbTable.Remove(DBKeys.LastToken)
    return
  end
  local tb = {}
  for _, v in ipairs(self.m_arrPlayerData) do
    tb[tostring(v.id)] = v.lastToken or 0
  end
  self.m_dbTable:Set(DBKeys.LastToken, DBColumnValue, json.encode(tb))
end

function ComboActivityModel:GetLastToken(id)
  local str = self.m_dbTable:GetValue(DBKeys.LastToken, DBColumnValue)
  if StringUtil.IsNilOrEmpty(str) then
    return 0
  end
  local map = json.decode(str)
  return map[tostring(id)] or 0
end

function ComboActivityModel:SaveLastRank()
  if Table.IsEmpty(self.m_arrPlayerData) then
    self.m_dbTable.Remove(DBKeys.LastRank)
    return
  end
  local tb = {}
  for _, v in ipairs(self.m_arrPlayerData) do
    tb[tostring(v.id)] = v.lastRank or 0
  end
  self.m_dbTable:Set(DBKeys.LastRank, DBColumnValue, json.encode(tb))
end

function ComboActivityModel:GetLastRank(id)
  local str = self.m_dbTable:GetValue(DBKeys.LastRank, DBColumnValue)
  if StringUtil.IsNilOrEmpty(str) then
    return 0
  end
  local map = json.decode(str)
  return map[tostring(id)] or 0
end

function ComboActivityModel:GetSimNetworkState()
  return self.m_dbTable:GetValue(DBKeys.SimNetwork, DBColumnValue) or false
end

function ComboActivityModel:SetSimNetworkState(state)
  self.m_dbTable:Set(DBKeys.SimNetwork, DBColumnValue, state)
end

function ComboActivityModel:SaveLastTokenAndRank()
  self:SaveLastToken()
  self:SaveLastRank()
end

function ComboActivityModel:SetEntryTime(time)
  self.m_dbTable:Set(DBKeys.EntryTime, DBColumnValue, time)
end

function ComboActivityModel:GetEntryTime()
  return self.m_dbTable:GetValue(DBKeys.EntryTime, DBColumnValue) or 0
end

function ComboActivityModel:GetEndRewards()
  if self.m_taskState == ComboTaskState.Win then
    local addScore = self.m_robotConfig.score_rwd * self.m_robotConfig.multi_num
    local lastStep = self.m_currentStep
    local tmpStep = 0
    local score = self:GetTotalScore() + addScore
    local tmpScore = 0
    for _, rewardConfig in ipairs(self.m_config.comboRewards) do
      tmpScore = tmpScore + rewardConfig.score
      tmpStep = tmpStep + 1
      if score < tmpScore then
        break
      end
    end
    if score >= tmpScore then
      tmpStep = tmpStep + 1
    end
    local step = 0
    local rewards = {}
    if lastStep < tmpStep then
      for _, rewardConfig in ipairs(self.m_config.comboRewards) do
        step = step + 1
        if lastStep <= step and tmpStep > step then
          Table.ListAppend(rewards, {
            rewardConfig.rewards
          })
        end
      end
    end
    return rewards
  end
  return {}
end

function ComboActivityModel:IsTokenProperty(propertyType)
  return propertyType == self.m_activityDefinition.ActivityTokenPropertyType
end

function ComboActivityModel:GetTokenPropertyType()
  return self.m_definition.ActivityTokenPropertyType
end

function ComboActivityModel:GetRedPointNum()
  if not self:HasNetwork() then
    return 1
  end
  if self.m_taskState == nil or self.m_taskState == ComboTaskState.WaitSignUp then
    return 1
  end
  return 0
end

function ComboActivityModel:OnEntryClicked()
  if not self:HasNetwork() then
    GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
  elseif self:CanSignUp() then
    GM.UIManager:OpenView(self.m_activityDefinition.ComboSignUpPrefabName, self:GetType(), false)
  else
    GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType(), false)
  end
end

function ComboActivityModel:HasNetwork()
  if not GameConfig.IsTestMode() then
    return ApplicationManager.Instance.isNetworkConnected
  end
  if self:GetSimNetworkState() then
    return false
  end
  return ApplicationManager.Instance.isNetworkConnected
end

function ComboActivityModel:UpdateSimNetwork()
  local bSim = self:GetSimNetworkState()
  bSim = not bSim
  self:SetSimNetworkState(bSim)
  local tip = bSim and "\230\151\160\231\189\145\230\168\161\230\139\159" or "\230\129\162\229\164\141\230\156\137\231\189\145"
  GM.UIManager:ShowPrompt(tip)
end

function ComboActivityModel:SetHudEntryRank(rank)
  self.m_cacheHudEntryRank = rank
end

function ComboActivityModel:GetHudEntryRank()
  return self.m_cacheHudEntryRank
end

function ComboActivityModel:GetHudEntryShowConfig()
  return {
    Type = "ComboActivity",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.ScoreChangedEvent
    },
    EntryPrefabConfigName = UIPrefabConfigName.DrillComboHudEntry,
    CheckFunc = function()
      return self:IsActivityOpen()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = self.m_activityDefinition.EntryImageName,
    OnClickedFunc = function()
      if self:GetState() == ActivityState.Preparing then
        GM.UIManager:OpenView(self.m_activityDefinition.ComboNoticePrefabName, self:GetType(), false)
        return
      end
      self:OnEntryClicked()
    end,
    RedPointType = EntryRedPointType.Exc,
    GetRedPointNumFunc = function()
      return self:GetRedPointNum()
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.StateChangedEvent,
      EEventType.ComboRankChanged,
      EEventType.ComboRefreshEntry
    }
  }
end

function ComboActivityModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.ScoreChangedEvent,
      EEventType.ComboRankChanged
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_comboBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_comboBubbleCount",
    scrollToFunName = "ScrollToComboBoardEntry",
    activityType = self:GetType(),
    checkFun = function()
      return self:CanShowBoardEntry()
    end
  }
end

function ComboActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function ComboActivityModel:GetTestPopupWindowConfig()
  return {
    CheckFunc = function()
      return self:IsActivityOpen()
    end,
    config = {
      GroupName = "\228\186\148\228\186\186\232\191\158\232\131\156(Combo)",
      WindowList = {
        {
          BtnName = "\228\184\187\231\149\140\233\157\162",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, ActivityType.DrillCombo, false)
          end
        },
        {
          BtnName = "\233\162\132\229\145\138",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.ComboNoticePrefabName, self:GetType())
          end
        },
        {
          BtnName = "\230\138\165\229\144\141",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.ComboSignUpPrefabName, self:GetType(), false)
          end
        },
        {
          BtnName = "\229\165\150\229\138\177",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.ComboAvenuePrefabName, self:GetType())
          end
        },
        {
          BtnName = "\231\187\147\230\157\159",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.ComboEndPrefabName, self:GetType())
          end
        },
        {
          BtnName = "\229\184\174\229\138\169",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.ComboHelpPrefabName, self:GetType())
          end
        },
        {
          BtnName = "\230\150\173\231\189\145\230\168\161\230\139\159",
          BtnClickFunc = function()
            self:UpdateSimNetwork()
          end
        },
        {
          BtnName = "\231\142\169\229\174\182\230\149\176\230\141\174\230\151\165\229\191\151",
          BtnClickFunc = function()
            if Table.IsEmpty(self.m_arrPlayerData) then
              return
            end
            local arr = {}
            for _, v in ipairs(self.m_arrPlayerData) do
              if not v:IsMySelf() then
                table.insert(arr, v:GetData())
              end
            end
            Log.Info("Combo Player data: " .. json.encode(arr))
          end
        }
      }
    }
  }
end

function ComboActivityModel:TestAddScore(addScore)
  if not GameConfig.IsTestMode() then
    return
  end
  local lastStep = self.m_currentStep
  local score = self:GetTotalScore() + addScore
  self.m_dbTable:Set(DBKeys.Score, DBColumnValue, score)
  self:LogActivity("testAdd", addScore)
  self:UpdateScoreContent()
  local step = 0
  local rewards = {}
  if lastStep < self.m_currentStep then
    for _, rewardConfig in ipairs(self.m_config.comboRewards) do
      step = step + 1
      if lastStep <= step and step < self.m_currentStep then
        Table.ListAppend(rewards, rewardConfig.rewards)
        self:LogActivity(EBIType.ActivityRankUp, step)
      end
    end
    if not Table.IsEmpty(rewards) then
      RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_definition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
    end
  end
  if self.m_cacheState == ActivityState.Ended then
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
    EventDispatcher.DispatchEvent(self.m_activityDefinition.ScoreChangedEvent)
  end
  return rewards
end

function ComboActivityModel:TestAddToken(addToken)
  if not GameConfig.IsTestMode() then
    return false
  end
  if self:_AddToken(addToken, "test") then
    EventDispatcher.DispatchEvent(EEventType.ComboRefreshEntry)
    return true
  end
  return false
end
