TeamActivityModel = setmetatable({}, BaseActivityModel)
TeamActivityModel.__index = TeamActivityModel
local DBColumnValue = "value"
TeamActivityState = {
  Waiting = "Waiting",
  HasTeamMate = "HasTeamMate",
  HasRival = "HasRival",
  OnGoing = "OnGoing"
}
TeamActivityAddScoreScene = {
  Merge = "merge",
  Order = "order",
  Buy = "buy"
}
TeamActivityRank = {
  Leading = "Leading",
  Lagging = "Lagging",
  Tied = "Tied"
}
local DBKeys = {
  PopEndWindow = "PopEndWindow",
  PopMatchWindow = "PopMatchWindow",
  PopMainWindowWhenConnect = "PopMainWindowWhenConnect",
  ClosedDueToNetworkUnconnected = "ClosedDueToNetworkUnconnected",
  RobotAllData = "RobotAllData",
  CurRoundStartTime = "CurRoundStartTime",
  Round = "Round",
  CurState = "CurState",
  CurScore = "CurScore",
  Token = "Token",
  LastShownScores = "LastShownScores",
  LastShownToken = "LastShownToken",
  LastShownRound = "LastShownRound",
  RecordedScore_player = "RecordedScore_player",
  RecordedScore_rival = "RecordedScore_rival",
  RecordedRank = "RecordedRank",
  CurRoundNum = "CurRoundNum"
}

function TeamActivityModel:Init(activityType, activityDataTable)
  self.m_activityDefinition = TeamActivityDefinition[activityType]
  self.m_robotAllData = {}
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
end

function TeamActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
end

function TeamActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function TeamActivityModel:_LoadOtherServerConfig(config)
  if config.teamConfig == nil or config.teamRewardConfig == nil then
    return
  end
  self.m_teamRewardConfig = config.teamRewardConfig
  table.sort(self.m_teamRewardConfig, function(a, b)
    return a.stage < b.stage
  end)
  self.m_groupId = self.m_teamRewardConfig[1].groupId
  self.m_teamConfigArr = config.teamConfig
  table.sort(self.m_teamConfigArr, function(a, b)
    return a.round < b.round
  end)
  self.m_eventOrderScore = config.eventOrderScore
  self:LoadLocalConfig()
end

function TeamActivityModel:LoadLocalConfig()
  local mergeConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_mergeItemScoreConfig = {}
  for _, data in ipairs(mergeConfig) do
    self.m_mergeItemScoreConfig[data.item_id] = data
  end
  local originRobotConfig = Table.DeepCopy(GM.ConfigModel:GetLocalConfig(LocalConfigKey.TeamRobot))
  self.m_robotConfig = {}
  for _, robot in ipairs(originRobotConfig) do
    if self.m_robotConfig[robot.groupId] == nil then
      self.m_robotConfig[robot.groupId] = {}
    end
    table.insert(self.m_robotConfig[robot.groupId], {
      id = robot.id,
      speed = robot.speed
    })
  end
end

function TeamActivityModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and self:CanAddScore() then
    local itemType = message.Source:GetType()
    if self.m_mergeItemScoreConfig[itemType] then
      local score = self.m_mergeItemScoreConfig[itemType].merge_score_race
      if score then
        self:AddScore(score, TeamActivityAddScoreScene.Merge, message.Source)
      end
    end
  end
end

function TeamActivityModel:AddScore(score, scene, itemModel)
  if 0 < score and self:CanAddScore() then
    local targetScore = self:GetTargetScore()
    if targetScore <= self.m_robotAllData.TeamMate.TeamScore then
      return
    end
    if targetScore <= self.m_robotAllData.RivalA.TeamScore then
      return
    end
    self:SetCurScore(self:GetCurScore() + score)
    local stage = self:GetCurStage()
    self:LogActivity(EBIType.ActivityAddScore, GM.BIManager:TableToString({
      stage = self:GetCurStage(),
      n = score,
      s = scene
    }))
    self:CalculateCurScores({
      TokenScore = score,
      Scene = scene,
      Source = itemModel
    })
  end
end

function TeamActivityModel:GetCurStage()
  local tokenNum = self:GetToken()
  local stageRewards = self:GetStageRewards()
  local stage = 0
  for i, reward in ipairs(stageRewards) do
    if tokenNum >= reward.score then
      stage = reward.stage
    else
      break
    end
  end
  return stage
end

function TeamActivityModel:CanAddScore()
  if self:GetState(false) == ActivityState.Started and self:GetCurState() == TeamActivityState.OnGoing and self.m_robotAllData.TeamMate.TeamScore < self:GetTargetScore() and self.m_robotAllData.RivalA.TeamScore < self:GetTargetScore() then
    return true
  end
  return false
end

function TeamActivityModel:OnCheckResourcesFinished()
  self.m_resourceAllReady = true
end

function TeamActivityModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if MINIGAME then
    self.m_resourceAllReady = true
  end
  if self:GetState(true) == ActivityState.Started and self.m_resourceAllReady then
    if self:GetCurState() == TeamActivityState.OnGoing then
      self:CalculateCurScores()
    end
    if ApplicationManager.Instance.isNetworkConnected and self:GetClosedDueToNetworkUnconnected() and self:GetCurState() == TeamActivityState.HasRival then
      self:SetClosedDueToNetworkUnconnected(false)
      self:SetCurState(TeamActivityState.OnGoing)
      GM.TutorialModel:SetTutorialFinished("tutorial_team_window")
    end
  end
end

function TeamActivityModel:CanPopRaceEndWindow()
  return self.m_bRaceEndWindowPop
end

function TeamActivityModel:SetPopRaceEndWindow(bCanPop)
  self.m_bRaceEndWindowPop = bCanPop
end

function TeamActivityModel:AcquireToken()
  local lastTokenNum = self:GetToken()
  local stageRewards = self:GetStageRewards()
  local maxTokenNum = stageRewards[#stageRewards].score
  if lastTokenNum >= maxTokenNum then
    return
  end
  self.m_rewardCache = {}
  local reward1, reward2 = self:GetTokenRewards(self:GetRound())
  RewardApi.AcquireRewardsLogic(reward1, EPropertySource.Give, self.m_activityDefinition.AcquireRewardBIType, EGameMode.Main, CacheItemType.Type2)
  table.insert(self.m_rewardCache, reward1)
  if self:GetCurScore() >= self.m_robotAllData.TeamMate.CurScore then
    RewardApi.AcquireRewardsLogic(reward2, EPropertySource.Give, self.m_activityDefinition.AcquireRewardBIType, EGameMode.Main, CacheItemType.Type2)
    table.insert(self.m_rewardCache, reward2)
  end
  local tokenNum = self:GetToken()
  local lastStage = 0
  local stage = 0
  for i, reward in ipairs(stageRewards) do
    if lastTokenNum >= reward.score then
      lastStage = reward.stage
    end
    if tokenNum >= reward.score then
      stage = reward.stage
    else
      break
    end
  end
  if lastStage ~= stage then
    for i = lastStage + 1, stage do
      local reward = stageRewards[i].reward
      self:LogActivity(EBIType.ActivityRankUp, i)
      RewardApi.AcquireRewardsLogic(reward, EPropertySource.Give, self.m_activityDefinition.AcquireRewardBIType, EGameMode.Main, CacheItemType.Type2)
      table.insert(self.m_rewardCache, reward)
      self:LogActivity(EBIType.ActivityGetRewards, i)
    end
  end
end

function TeamActivityModel:ClearCacheReward(bRewardInView)
  if self.m_rewardCache and not Table.IsEmpty(self.m_rewardCache) then
    if bRewardInView then
      RewardApi.AcquireRewardsInView(self.m_rewardCache, {simpleCollect = true})
    end
    self.m_rewardCache = {}
  end
end

function TeamActivityModel:GetTimeScore(data, relativeT)
  data.StartingScore = data.StartingScore or 0
  if relativeT == 0 then
    data.CurTime = 0
    data.CurScore = 0
    return 0
  end
  local speed = data.Speed
  relativeT = MathUtil.Clamp(relativeT, data.Speed[#data.Speed].Time, 1)
  local curStage = 1
  for i = 1, #speed do
    if relativeT <= speed[i].Time and relativeT > (1 < i and speed[i - 1].Time or 0) then
      curStage = i
      break
    end
  end
  if GameConfig.IsTestMode() then
    self.m_testInfo = self.m_testInfo .. [[
 -------------------
ID = ]] .. data.ID .. "\n"
    for i, sp in ipairs(speed) do
      if i == curStage then
        self.m_testInfo = self.m_testInfo .. "["
      end
      self.m_testInfo = self.m_testInfo .. sp.Time .. "-" .. sp.Score .. "-" .. sp.Type
      if i == curStage then
        self.m_testInfo = self.m_testInfo .. "]"
      end
      self.m_testInfo = self.m_testInfo .. " / "
    end
    self.m_testInfo = self.m_testInfo .. "\n"
  end
  local endScore = speed[curStage].Score
  local endTime = speed[curStage].Time
  local startScore = 1 < curStage and speed[curStage - 1].Score or data.StartingScore
  local startTime = 1 < curStage and speed[curStage - 1].Time or 0
  local deltaT = relativeT - startTime
  local spanT = endTime - startTime
  local spanS = endScore - startScore
  if GameConfig.IsTestMode() then
    self.m_testInfo = self.m_testInfo .. "\229\136\134\230\149\176\229\140\186\233\151\180:" .. startScore .. "-" .. endScore .. ", \230\151\182\233\151\180\229\140\186\233\151\180 " .. startTime .. "-" .. endTime
    self.m_testInfo = self.m_testInfo .. ", \231\171\158\232\181\155\229\188\128\229\167\139\229\144\142\232\174\161\230\151\182: " .. relativeT .. ", \231\155\184\229\175\185\230\156\172\233\152\182\230\174\181\229\188\128\229\167\139\232\174\161\230\151\182: " .. deltaT
    self.m_testInfo = self.m_testInfo .. ", \229\136\134\230\149\176\232\183\168\229\186\166: " .. spanS .. ", \230\151\182\233\151\180\232\183\168\229\186\166: " .. spanT .. "\n"
  end
  local res = data.CurScore or 0
  local lastS = data.CurScore or 0
  local lastT = data.CurTime or 0
  if data.CurScore and startScore > data.CurScore then
    res = startScore
    lastS = startScore
    lastT = startTime
    if GameConfig.IsTestMode() then
      self.m_testInfo = self.m_testInfo .. "\230\151\182\233\151\180\228\184\142\229\136\134\230\149\176\229\183\178\230\160\161\230\173\163, "
    end
  end
  if GameConfig.IsTestMode() then
    self.m_testInfo = self.m_testInfo .. "\228\184\138\230\172\161\232\174\176\229\189\149\231\154\132\230\151\182\233\151\180&\229\136\134\230\149\176: " .. lastT .. " " .. lastS .. "\n"
  end
  if speed[curStage].Type == 0 then
    local temp = EaseUtil.GetInterpolatedValue(startScore, endScore, spanT, deltaT, Ease.InOutQuart)
    res = math.ceil(temp)
    if GameConfig.IsTestMode() then
      self.m_testInfo = self.m_testInfo .. "InOutQuart \229\136\134\230\149\176\229\140\186\233\151\180\239\188\154" .. startScore .. "-" .. endScore .. ", \230\151\182\233\151\180\229\140\186\233\151\180: " .. spanT .. ", \229\189\147\229\137\141\230\151\182\233\151\180: " .. deltaT .. "\n"
      self.m_testInfo = self.m_testInfo .. "\229\136\134\230\149\176\231\178\190\231\161\174\229\128\188: " .. temp .. "\n"
    end
  elseif speed[curStage].Type == 2 then
    res = deltaT == spanT and endScore or startScore
    if GameConfig.IsTestMode() then
      self.m_testInfo = self.m_testInfo .. "\230\156\128\229\144\142\228\184\128\231\167\146\229\138\160\229\136\134 \230\156\128\229\144\142\228\184\128\231\167\146\239\188\154" .. endTime .. "\239\188\140 \229\189\147\229\137\141\231\167\146\239\188\154" .. relativeT .. "\n"
    end
  elseif speed[curStage].Type == 1 then
    if spanS > spanT * 2 then
      if GameConfig.IsTestMode() then
        self.m_testInfo = self.m_testInfo .. "b > 2a" .. "\n"
      end
      if lastS - startScore > lastT - startTime then
        res = lastS + relativeT - lastT
        if GameConfig.IsTestMode() then
          self.m_testInfo = self.m_testInfo .. "\231\170\129\229\143\152\229\136\134\230\149\176" .. spanS - spanT + 1 .. "\229\183\178\229\138\160\232\191\135\239\188\140\230\142\165\228\184\139\230\157\165\230\175\143\231\167\146\229\138\1601\229\136\134\n"
        end
      else
        local randomList = MathUtil.RandomN(endTime - lastT, 1)
        if GameConfig.IsTestMode() then
          self.m_testInfo = self.m_testInfo .. "trying to find 1 abnormal score out of " .. endTime - lastT .. "\n"
        end
        for i = 1, relativeT - lastT do
          if Table.Contain(randomList, i) then
            res = res + (spanS - spanT + 1)
            if GameConfig.IsTestMode() then
              self.m_testInfo = self.m_testInfo .. "found 1\n"
            end
          else
            res = res + 1
          end
        end
      end
    elseif spanT <= spanS then
      if GameConfig.IsTestMode() then
        self.m_testInfo = self.m_testInfo .. "2a >= b > a" .. "\n"
      end
      local already2 = lastS - startScore - (lastT - startTime)
      local left2 = spanS - spanT - already2
      if left2 <= 0 then
        res = lastS + relativeT - lastT
        if GameConfig.IsTestMode() then
          self.m_testInfo = self.m_testInfo .. "\230\137\128\230\156\1372\229\136\134\229\183\178\230\183\187\229\138\160\232\191\135.\n"
        end
      else
        local randomList = MathUtil.RandomN(endTime - lastT, left2)
        if GameConfig.IsTestMode() then
          self.m_testInfo = self.m_testInfo .. "trying to find " .. left2 .. " abnormal score out of " .. endTime - lastT .. "\n"
        end
        for i = 1, relativeT - lastT do
          if Table.Contain(randomList, i) then
            res = res + 2
            if GameConfig.IsTestMode() then
              self.m_testInfo = self.m_testInfo .. "found 1\n"
            end
          else
            res = res + 1
          end
        end
      end
    else
      if GameConfig.IsTestMode() then
        self.m_testInfo = self.m_testInfo .. "b < a" .. "\n"
      end
      local already0 = lastT - startTime - (lastS - startScore)
      local left0 = spanT - spanS - already0
      if left0 <= 0 then
        res = lastS + relativeT - lastT
        if GameConfig.IsTestMode() then
          self.m_testInfo = self.m_testInfo .. "\230\137\128\230\156\1370\229\136\134\229\183\178\229\138\160\232\191\135.\n"
        end
      else
        local randomList = MathUtil.RandomN(endTime - lastT, left0)
        if GameConfig.IsTestMode() then
          self.m_testInfo = self.m_testInfo .. "trying to find " .. left0 .. " abnormal score out of " .. endTime - lastT .. "\n"
        end
        for i = 1, relativeT - lastT do
          if Table.Contain(randomList, i) then
            res = res + 0
            if GameConfig.IsTestMode() then
              self.m_testInfo = self.m_testInfo .. "found 1\n"
            end
          else
            res = res + 1
          end
        end
      end
    end
  end
  data.CurTime = relativeT
  if GameConfig.IsTestMode() then
    self.m_testInfo = self.m_testInfo .. "\229\189\147\229\137\141\230\151\182\233\151\180&\229\136\134\230\149\176: " .. data.CurTime .. " " .. res .. "\n"
  end
  return res
end

function TeamActivityModel:CalculateCurScores(message)
  if self:GetCurState() == TeamActivityState.OnGoing then
    local startTime = self:GetCurRoundStartTime()
    local timeElapsed = math.ceil(GM.GameModel:GetServerTime() - startTime)
    if message and message.TokenScore == nil and self.m_robotAllData.TeamMate.CurTime and self.m_robotAllData.TeamMate.CurTime == timeElapsed then
      return
    end
    if GameConfig.IsTestMode() then
      self.m_testInfo = "[2v2]" .. timeElapsed .. "\n"
    end
    local playerScore = self:GetCurScore()
    local teamMateScore = self:GetPopMainWindowWhenConnect() and (self.m_robotAllData.TeamMate.CurScore or 0) or self:GetTimeScore(self.m_robotAllData.TeamMate, GM.GameModel:GetServerTime() - startTime)
    message = message or {}
    message.TokenScore = message.TokenScore or 0
    message.TeamMateScoreAddition = teamMateScore - (self.m_robotAllData.TeamMate.CurScore or 0)
    message.RivalScoreAddition = 0
    self.m_robotAllData.TeamMate.CurScore = teamMateScore
    self.m_robotAllData.TeamMate.TeamScore = playerScore + teamMateScore
    self.m_playerTeamScore = self.m_robotAllData.TeamMate.TeamScore
    if self.m_playerTeamScore >= self:GetTargetScore() then
      self.m_rank = TeamActivityRank.Leading
      if ApplicationManager.Instance.isNetworkConnected then
        self:AcquireToken()
        self:LogRaceEnd(true)
        self:SetRound(self:GetRound() + 1)
        self:SetCurRoundNum(1)
        self:SetCurState(TeamActivityState.HasTeamMate)
        if GM.SceneManager:GetGameMode() == EGameMode.Map or GM.SceneManager:GetGameMode() == EGameMode.Loading or self:GetPopMainWindowWhenConnect() then
          self:SetPopRaceEndWindow(true)
          EventDispatcher.DispatchEvent(EEventType.TeamRaceEnd)
        end
      elseif not self:GetPopMainWindowWhenConnect() and GM.SceneManager:GetGameMode() == EGameMode.Map then
        self:SetPopRaceEndWindow(true)
        EventDispatcher.DispatchEvent(EEventType.TeamRaceEnd)
      end
      EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
    else
      local rivalAScore = self:GetPopMainWindowWhenConnect() and (self.m_robotAllData.RivalA.CurScore or 0) or self:GetTimeScore(self.m_robotAllData.RivalA, GM.GameModel:GetServerTime() - startTime)
      local rivalBScore = self:GetPopMainWindowWhenConnect() and (self.m_robotAllData.RivalB.CurScore or 0) or self:GetTimeScore(self.m_robotAllData.RivalB, GM.GameModel:GetServerTime() - startTime)
      message.RivalScoreAddition = rivalAScore + rivalBScore - (self.m_robotAllData.RivalA.CurScore or 0) - (self.m_robotAllData.RivalB.CurScore or 0)
      self.m_robotAllData.RivalA.CurScore = rivalAScore
      self.m_robotAllData.RivalB.CurScore = rivalBScore
      self.m_robotAllData.RivalA.TeamScore = rivalAScore + rivalBScore
      self.m_robotAllData.RivalB.TeamScore = rivalAScore + rivalBScore
      self.m_rivalTeamScore = self.m_robotAllData.RivalA.TeamScore
      if self.m_playerTeamScore > self.m_rivalTeamScore then
        self.m_rank = TeamActivityRank.Leading
      elseif self.m_playerTeamScore < self.m_rivalTeamScore then
        self.m_rank = TeamActivityRank.Lagging
      else
        self.m_rank = TeamActivityRank.Tied
      end
      if self.m_rivalTeamScore >= self:GetTargetScore() then
        if ApplicationManager.Instance.isNetworkConnected then
          self:LogRaceEnd(false)
          self:SetCurRoundNum(self:GetCurRoundNum() + 1)
          self:SetCurState(TeamActivityState.HasTeamMate)
          self:SetPopRaceEndWindow(true)
          EventDispatcher.DispatchEvent(EEventType.TeamRaceEnd)
        elseif not self:GetPopMainWindowWhenConnect() then
          self:SetPopRaceEndWindow(true)
          EventDispatcher.DispatchEvent(EEventType.TeamRaceEnd)
        end
        EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
      else
        self:TryPopTopTip()
      end
    end
    self:SaveRobotAllData()
    if message.TokenScore > 0 or 0 < message.TeamMateScoreAddition or 0 < message.RivalScoreAddition then
      EventDispatcher.DispatchEvent(self.m_activityDefinition.ScoreChangedEvent, message)
    end
  end
end

function TeamActivityModel:LogRaceEnd(bWin)
  local round = self:GetRound()
  local score = self:GetCurScore()
  GM.BIManager:LogAction(self.m_activityDefinition.RaceEndBIType, {
    g = self:GetServerConfigGroupId(),
    r = round,
    n = self:GetCurRoundNum(),
    s_n = self:GetTargetScore(round),
    s_pteam = self.m_playerTeamScore,
    s_rteam = self.m_rivalTeamScore,
    s_i = score,
    s_p = self.m_robotAllData.TeamMate.CurScore,
    s_r1 = self.m_robotAllData.RivalA.CurScore,
    s_r2 = self.m_robotAllData.RivalB.CurScore,
    win = bWin and 1 or 0,
    mvp = bWin and score >= self.m_robotAllData.TeamMate.CurScore and 1 or 0,
    t = GM.GameModel:GetServerTime() - self:GetCurRoundStartTime()
  })
end

function TeamActivityModel:BILogAction(scene)
  GM.BIManager:LogAction(scene, {
    g = self:GetServerConfigGroupId(),
    r = self:GetRound(),
    n = self:GetCurRoundNum()
  })
end

function TeamActivityModel:TryPopTopTip()
  local lastRank = self:GetRecordedRank()
  if lastRank and lastRank == TeamActivityRank.Lagging and self.m_rank == TeamActivityRank.Leading then
    self.m_increase = true
    self.m_decrease = false
  elseif lastRank and lastRank == TeamActivityRank.Leading and self.m_rank == TeamActivityRank.Lagging then
    self.m_increase = false
    self.m_decrease = true
  else
    self.m_increase = false
    self.m_decrease = false
  end
  if self.m_rank ~= TeamActivityRank.Tied then
    self:SetRecordedRank(self.m_rank)
  end
  local lastScore_player = self:GetRecordedScore_player()
  local lastScore_rival = self:GetRecordedScore_rival()
  if self.m_playerTeamScore >= self:GetTargetScore() * 0.5 and lastScore_player and lastScore_player < self:GetTargetScore() * 0.5 and self.m_rank == TeamActivityRank.Leading then
    self.m_topTipCondition4 = true
  elseif self.m_rivalTeamScore >= self:GetTargetScore() * 0.5 and lastScore_rival and lastScore_rival < self:GetTargetScore() * 0.5 and self.m_rank == TeamActivityRank.Lagging then
    self.m_topTipCondition4 = true
  else
    self.m_topTipCondition4 = false
  end
  self:SetRecordedScore_player(self.m_playerTeamScore)
  self:SetRecordedScore_rival(self.m_rivalTeamScore)
  if self:CanShowTopTip() then
    TopSliderManager.TrySlide(SliderType.Team, self.m_activityDefinition.TopTipPrefabName, function(go)
      local model = GM.ActivityManager:GetModel(self:GetType())
      if model == nil or model:GetState() ~= ActivityState.Started or model:GetCurState() ~= TeamActivityState.OnGoing or GM.UIManager:GetOpenedViewByName(self.m_activityDefinition.MainWindowPrefabName) then
        GameObject.Destroy(go)
        return
      end
      local topTip = go:GetLuaTable()
      topTip:Init(self)
      TopSliderManager.Appear(go, function()
        self.m_lastTopTipTime = GM.GameModel:GetServerTime() + 2
        DelayExecuteFunc(function()
          TopSliderManager.Disappear(go)
        end, 2.0)
      end)
    end)
  end
end

function TeamActivityModel:CanShowTopTip()
  if GM.SceneManager:GetGameMode() ~= EGameMode.Main then
    return false
  end
  if self:GetCurState() ~= TeamActivityState.OnGoing then
    return false
  end
  if self:ScoreInPercentRange(self.m_playerTeamScore, 0, 0.5) and self.m_decrease and self.m_rivalTeamScore - self.m_playerTeamScore >= 10 and self:TopTipHasCoolenDown(60) then
    Log.Info("[2v2] \230\181\174\231\170\151 condition 1, rival win")
    return true
  end
  if self:ScoreInPercentRange(self.m_rivalTeamScore, 0, 0.5) and self.m_increase and self.m_playerTeamScore - self.m_rivalTeamScore >= 10 and self:TopTipHasCoolenDown(60) then
    Log.Info("[2v2] \230\181\174\231\170\151 condition 1, player win")
    return true
  end
  if self:ScoreInPercentRange(self.m_playerTeamScore, 0.5, 0.85) and self.m_decrease and self.m_rivalTeamScore - self.m_playerTeamScore >= 3 and self:TopTipHasCoolenDown(60) then
    Log.Info("[2v2] \230\181\174\231\170\151 condition 2, rival win")
    return true
  end
  if self:ScoreInPercentRange(self.m_rivalTeamScore, 0.5, 0.85) and self.m_increase and self.m_playerTeamScore - self.m_rivalTeamScore >= 3 and self:TopTipHasCoolenDown(60) then
    Log.Info("[2v2] \230\181\174\231\170\151 condition 1, player win")
    return true
  end
  if self:ScoreInPercentRange(self.m_playerTeamScore, 0.85, 1) and self.m_decrease and self:TopTipHasCoolenDown(20) then
    Log.Info("[2v2] \230\181\174\231\170\151 condition 1, rival win")
    return true
  elseif self:ScoreInPercentRange(self.m_rivalTeamScore, 0.85, 1) and self.m_increase and self:TopTipHasCoolenDown(20) then
    Log.Info("[2v2] \230\181\174\231\170\151 condition 1, player win")
    return true
  end
  if self.m_topTipCondition4 and self:TopTipHasCoolenDown(60) then
    Log.Info("[2v2] \230\181\174\231\170\151 condition 4")
    return true
  end
end

function TeamActivityModel:ScoreInPercentRange(score, min, max)
  local targetScore = self:GetTargetScore()
  if score > self:GetTargetScore() * min and score <= self:GetTargetScore() * max then
    return true
  else
    return false
  end
end

function TeamActivityModel:TopTipHasCoolenDown(time)
  if self.m_lastTopTipTime == nil then
    return true
  end
  if GM.GameModel:GetServerTime() > self.m_lastTopTipTime + time then
    return true
  end
  return false
end

function TeamActivityModel:ChooseRobot_TeamMate(instantSwitchState)
  self:ClearAllCache()
  self:ResetLastShownScoreStruct()
  self:SetCurScore(0)
  self:ResetRobotAllData()
  if self:GetRound() > #self.m_teamConfigArr then
    return
  end
  local robots = self.m_teamConfigArr[self:GetRound()].teamRobot
  local robotStrings = Table.ListWeightSelectOne(robots).Items
  local robot = Table.DeepCopy(Table.ListRandomSelectOne(self.m_robotConfig[robotStrings[1]]))
  self:ConvertRobotSpeed(robot)
  self.m_robotAllData.TeamMate.Speed = robot.speed
  self.m_robotAllData.TeamMate.ID = robot.id
  self:SaveRobotAllData()
  if instantSwitchState then
    self:SetCurState(TeamActivityState.HasTeamMate)
  end
end

function TeamActivityModel:ChooseRobot_Rival(instantSwitchState)
  self:BILogAction(self.m_activityDefinition.MatchRivalBIType)
  if self:GetRound() > #self.m_teamConfigArr then
    return
  end
  local robots = self.m_teamConfigArr[self:GetRound()].rivalRobot
  local robotStrings = Table.ListWeightSelectOne(robots).Items
  local robotA = Table.DeepCopy(Table.ListRandomSelectOne(self.m_robotConfig[robotStrings[1]]))
  while self.m_robotAllData.TeamMate.ID and self.m_robotAllData.TeamMate.ID == robotA.id or self.m_robotAllData.RivalB.ID and self.m_robotAllData.RivalB.ID == robotA.id do
    robotA = Table.DeepCopy(Table.ListRandomSelectOne(self.m_robotConfig[robotStrings[1]]))
  end
  self:ConvertRobotSpeed(robotA)
  self.m_robotAllData.RivalA.Speed = robotA.speed
  self.m_robotAllData.RivalA.ID = robotA.id
  local robotB = Table.DeepCopy(Table.ListRandomSelectOne(self.m_robotConfig[robotStrings[2]]))
  while self.m_robotAllData.TeamMate.ID and self.m_robotAllData.TeamMate.ID == robotB.id or self.m_robotAllData.RivalA.ID and self.m_robotAllData.RivalA.ID == robotB.id do
    robotB = Table.DeepCopy(Table.ListRandomSelectOne(self.m_robotConfig[robotStrings[2]]))
  end
  self:ConvertRobotSpeed(robotB)
  self.m_robotAllData.RivalB.Speed = robotB.speed
  self.m_robotAllData.RivalB.ID = robotB.id
  self:SaveRobotAllData()
  if instantSwitchState then
    self:SetCurState(TeamActivityState.HasRival)
  end
end

function TeamActivityModel:ConvertRobotSpeed(robot)
  for i, data in ipairs(robot.speed) do
    local arr = StringUtil.Split(data, "-")
    robot.speed[i] = {
      Time = tonumber(arr[1]),
      Score = tonumber(arr[2]),
      Type = tonumber(arr[3])
    }
  end
  table.sort(robot.speed, function(a, b)
    return a.Time < b.Time
  end)
end

function TeamActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  self:ClearAllCache()
  self:ClearCacheReward(true)
end

function TeamActivityModel:ClearAllCache()
  self.m_rivalTeamScore = nil
  self.m_playerTeamScore = nil
  self.m_rank = nil
  self.m_increase = nil
  self.m_decrease = nil
  self.m_topTipCondition4 = nil
  self.m_lastTopTipTime = nil
  self.m_bRaceEndWindowPop = nil
end

function TeamActivityModel:_OnStateChanged()
  local state = self:GetState(false)
  if state == ActivityState.Started and self.m_eventOrderScore ~= nil then
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty, self, self.m_eventOrderScore, self.m_activityDefinition.ScoreProperty, function(num, scene)
      local addScoreScene = scene == EBIType.FinishOrder and TeamActivityAddScoreScene.Order or TeamActivityAddScoreScene.Buy
      self:AddScore(num, addScoreScene, nil)
    end, function()
      return self:CanAddScore()
    end, nil, true)
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.LogicAcquireReward, self, {
      [self.m_activityDefinition.TokenProperty] = function(num, scene)
        local maxTokenNum = self:GetStageRewards()[#self:GetStageRewards()].score
        self:SetToken(math.min(num + self:GetToken(), maxTokenNum))
      end
    })
    self:SetLastShownRound(self:GetRound())
    self:SetLastShownToken(self:GetToken())
    self.m_robotAllData = self:_LoadRobotAllData()
    if self:GetCurState() == TeamActivityState.HasTeamMate then
      if self.m_robotAllData.RivalA.ID ~= nil then
        self:ChooseRobot_TeamMate(true)
      end
    elseif self:GetCurState() == TeamActivityState.HasRival and GM.TutorialModel:IsTutorialFinished("tutorial_team_window") then
      self:SetCurState(TeamActivityState.OnGoing)
    end
  end
  if state == ActivityState.Ended then
    self:SetCurState(TeamActivityState.HasTeamMate)
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function TeamActivityModel:GetStageRewards()
  return self.m_teamRewardConfig
end

function TeamActivityModel:GetTokenRewards(round)
  return self.m_teamConfigArr[round].reward_1, self.m_teamConfigArr[round].reward_2
end

function TeamActivityModel:PickAvatarAndName(num, callback)
  local avatars = UIHelper.GetRandomAvatarIcon(num, true)
  local frames = UIHelper.GetRandomAvatarIconFrame(num, true)
  ApiMessage.GetRobotNameList(num, function(success, resp)
    if not success or resp.rcode == 1 then
      return
    end
    local names = resp.robot_names
    if Table.IsEmpty(names) or #names ~= num then
      if GameConfig.IsTestMode() then
        Log.Error("[2v2]\230\138\165\229\144\141\232\142\183\229\143\150\229\129\135\228\186\186\229\144\141\229\173\151\228\184\186\231\169\186\230\136\150\230\149\176\233\135\143\228\184\141\229\175\185\239\188\140\230\149\176\233\135\143\239\188\154" .. tostring(#names))
      end
      return
    end
    if num == 1 then
      self.m_robotAllData.TeamMate.Avatar = avatars[1]
      self.m_robotAllData.TeamMate.Frame = frames[1]
      self.m_robotAllData.TeamMate.Name = names[1]
    elseif num == 2 then
      self.m_robotAllData.RivalA.Avatar = avatars[1]
      self.m_robotAllData.RivalA.Frame = frames[1]
      self.m_robotAllData.RivalA.Name = names[1]
      self.m_robotAllData.RivalB.Avatar = avatars[2]
      self.m_robotAllData.RivalB.Frame = frames[2]
      self.m_robotAllData.RivalB.Name = names[2]
    end
    self:SaveRobotAllData()
    if callback then
      callback()
    end
  end)
end

function TeamActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function TeamActivityModel:SetPopEndWindow()
  self.m_dbTable:Set(DBKeys.PopEndWindow, DBColumnValue, "1")
end

function TeamActivityModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(DBKeys.PopEndWindow, DBColumnValue) ~= "1"
end

function TeamActivityModel:IsFinishedAll()
  if self.m_teamRewardConfig and self.m_teamConfigArr then
    return self:GetToken() >= self.m_teamRewardConfig[#self.m_teamRewardConfig].score
  end
end

function TeamActivityModel:GetHudEntryShowConfig()
  return {
    Type = "TeamActivity",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.FinishedAllRoundEvent
    },
    EntryPrefabConfigName = self.m_activityDefinition.HudEntryPrefabName,
    CheckFunc = function()
      return (self:GetState(false) == ActivityState.Started or self:GetState(false) == ActivityState.Preparing) and not self:IsFinishedAll()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = nil,
    OnClickedFunc = function()
      if self:GetState(false) == ActivityState.Preparing then
        GM.UIManager:OpenView(self.m_activityDefinition.NoticeWindowPrefabName, self:GetType(), false)
      else
        if not ApplicationManager.Instance.isNetworkConnected then
          GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
          return
        end
        GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType(), false)
      end
    end,
    RedPointType = EntryRedPointType.Exc,
    GetRedPointNumFunc = function()
      return self:GetCurState() == TeamActivityState.OnGoing and 0 or 1
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.CompetitionStateChangedEvent,
      self.m_activityDefinition.ScoreChangedEvent
    }
  }
end

function TeamActivityModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.FinishedAllRoundEvent
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_TeamctivityBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_TeamctivityBubbleCount",
    scrollToFunName = "ScrollToTeamctivity",
    activityType = self:GetType(),
    checkFun = function()
      return self:GetState(false) == ActivityState.Started and not self:IsFinishedAll()
    end
  }
end

function TeamActivityModel:HasRobotData()
  return self.m_robotAllData.TeamMate.CurScore ~= nil and self.m_robotAllData.RivalA.CurScore ~= nil and self.m_robotAllData.RivalB.CurScore ~= nil
end

function TeamActivityModel:GetServerConfigGroupId()
  return self.m_groupId
end

function TeamActivityModel:SetCurRoundStartTime(time)
  self.m_dbTable:Set(DBKeys.CurRoundStartTime, DBColumnValue, time)
end

function TeamActivityModel:GetCurRoundStartTime()
  return self.m_dbTable:GetValue(DBKeys.CurRoundStartTime, DBColumnValue) or -1
end

function TeamActivityModel:SetRound(round)
  self.m_dbTable:Set(DBKeys.Round, DBColumnValue, round)
end

function TeamActivityModel:GetRound()
  return self.m_dbTable:GetValue(DBKeys.Round, DBColumnValue) or 1
end

function TeamActivityModel:SetCurRoundNum(count)
  self.m_dbTable:Set(DBKeys.CurRoundNum, DBColumnValue, count)
end

function TeamActivityModel:GetCurRoundNum()
  return self.m_dbTable:GetValue(DBKeys.CurRoundNum, DBColumnValue) or 1
end

function TeamActivityModel:SetLastShownRound(round)
  self.m_dbTable:Set(DBKeys.LastShownRound, DBColumnValue, round)
end

function TeamActivityModel:GetLastShownRound()
  return self.m_dbTable:GetValue(DBKeys.LastShownRound, DBColumnValue) or 1
end

function TeamActivityModel:SetToken(num)
  self.m_dbTable:Set(DBKeys.Token, DBColumnValue, num)
end

function TeamActivityModel:GetToken()
  return self.m_dbTable:GetValue(DBKeys.Token, DBColumnValue) or 0
end

function TeamActivityModel:SetLastShownToken(num)
  self.m_dbTable:Set(DBKeys.LastShownToken, DBColumnValue, num)
end

function TeamActivityModel:GetLastShownToken()
  return self.m_dbTable:GetValue(DBKeys.LastShownToken, DBColumnValue) or 0
end

function TeamActivityModel:SetCurState(state)
  self.m_dbTable:Set(DBKeys.CurState, DBColumnValue, state)
  if state == TeamActivityState.OnGoing then
    self:BILogAction(self.m_activityDefinition.RaceStartBIType)
    self:SetCurRoundStartTime(GM.GameModel:GetServerTime())
    self:CalculateCurScores()
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.CompetitionStateChangedEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function TeamActivityModel:GetCurState()
  return self.m_dbTable:GetValue(DBKeys.CurState, DBColumnValue) or TeamActivityState.Waiting
end

function TeamActivityModel:SetCurScore(score)
  self.m_dbTable:Set(DBKeys.CurScore, DBColumnValue, score)
end

function TeamActivityModel:GetCurScore()
  return self.m_dbTable:GetValue(DBKeys.CurScore, DBColumnValue) or 0
end

function TeamActivityModel:ResetRobotAllData()
  local avatar = self.m_robotAllData.TeamMate and self.m_robotAllData.TeamMate.Avatar or ""
  local frame = self.m_robotAllData.TeamMate and self.m_robotAllData.TeamMate.Frame or ""
  local name = self.m_robotAllData.TeamMate and self.m_robotAllData.TeamMate.Name or ""
  self.m_robotAllData.TeamMate = {
    Avatar = avatar,
    Frame = frame,
    Name = name
  }
  self.m_robotAllData.RivalA = {}
  self.m_robotAllData.RivalB = {}
  self:SaveRobotAllData()
end

function TeamActivityModel:SaveRobotAllData()
  self.m_dbTable:Set(DBKeys.RobotAllData, DBColumnValue, json.encode(self.m_robotAllData))
end

function TeamActivityModel:_LoadRobotAllData()
  return json.decode(self.m_dbTable:GetValue(DBKeys.RobotAllData, DBColumnValue) or "") or {}
end

function TeamActivityModel:GetRobotAllData()
  return self.m_robotAllData
end

function TeamActivityModel:GetRank()
  return self.m_rank
end

function TeamActivityModel:GetTargetScore(round)
  round = round or self:GetRound()
  return self.m_teamConfigArr[round].score
end

function TeamActivityModel:GetCakeType(round)
  return self.m_teamConfigArr[round].type
end

function TeamActivityModel:SetLastShownScoreStruct(scoreStruct)
  self.m_dbTable:Set(DBKeys.LastShownScores, DBColumnValue, json.encode(scoreStruct))
end

function TeamActivityModel:GetLastShownScoreStruct()
  return json.decode(self.m_dbTable:GetValue(DBKeys.LastShownScores, DBColumnValue) or "") or {
    player_window = 0,
    teammate_window = 0,
    rivalA_window = 0,
    rivalB_window = 0,
    playerTeam_tip = 0,
    rivalTeam_tip = 0
  }
end

function TeamActivityModel:ResetLastShownScoreStruct()
  local temp = {
    player_window = 0,
    teammate_window = 0,
    rivalA_window = 0,
    rivalB_window = 0,
    playerTeam_tip = 0,
    rivalTeam_tip = 0
  }
  self:SetLastShownScoreStruct(temp)
end

function TeamActivityModel:SetRecordedScore_player(score)
  self.m_dbTable:Set(DBKeys.RecordedScore_player, DBColumnValue, score)
end

function TeamActivityModel:GetRecordedScore_player()
  return self.m_dbTable:GetValue(DBKeys.RecordedScore_player, DBColumnValue)
end

function TeamActivityModel:SetRecordedScore_rival(score)
  self.m_dbTable:Set(DBKeys.RecordedScore_rival, DBColumnValue, score)
end

function TeamActivityModel:GetRecordedScore_rival()
  return self.m_dbTable:GetValue(DBKeys.RecordedScore_rival, DBColumnValue)
end

function TeamActivityModel:SetRecordedRank(rank)
  self.m_dbTable:Set(DBKeys.RecordedRank, DBColumnValue, rank)
end

function TeamActivityModel:GetRecordedRank()
  return self.m_dbTable:GetValue(DBKeys.RecordedRank, DBColumnValue)
end

function TeamActivityModel:SetPopMatchWindow()
  self.m_dbTable:Set(DBKeys.PopMatchWindow, DBColumnValue, "1")
end

function TeamActivityModel:CanPopMatchWindow()
  return self.m_dbTable:GetValue(DBKeys.PopMatchWindow, DBColumnValue) ~= "1"
end

function TeamActivityModel:GetActivityDefinition()
  return self.m_activityDefinition
end

function TeamActivityModel:SetPopMainWindowWhenConnect(status)
  self.m_dbTable:Set(DBKeys.PopMainWindowWhenConnect, DBColumnValue, status)
end

function TeamActivityModel:GetPopMainWindowWhenConnect()
  return self.m_dbTable:GetValue(DBKeys.PopMainWindowWhenConnect, DBColumnValue) or false
end

function TeamActivityModel:SetClosedDueToNetworkUnconnected(status)
  self.m_dbTable:Set(DBKeys.ClosedDueToNetworkUnconnected, DBColumnValue, status)
end

function TeamActivityModel:GetClosedDueToNetworkUnconnected()
  return self.m_dbTable:GetValue(DBKeys.ClosedDueToNetworkUnconnected, DBColumnValue) or false
end

function TeamActivityModel:TestRestart()
  self:ClearAllCache()
  self:SetCurScore(0)
  self:SetCurState(TeamActivityState.Waiting)
  self:SetCurRoundStartTime(0)
  self:SetToken(0)
  self:SetRound(1)
  self:ResetLastShownScoreStruct()
  self:SetLastShownToken(0)
  self:SetLastShownRound(1)
  self:SetPopMainWindowWhenConnect(false)
  self.m_dbTable:Remove(DBKeys.RecordedRank, DBColumnValue)
  self.m_dbTable:Remove(DBKeys.RecordedScore_player, DBColumnValue)
  self.m_dbTable:Remove(DBKeys.RecordedScore_rival, DBColumnValue)
end

function TeamActivityModel:TestRival50()
  self.m_robotAllData.RivalA.StartingScore = self.m_robotAllData.RivalA.StartingScore or 0
  self.m_robotAllData.RivalA.StartingScore = self.m_robotAllData.RivalA.StartingScore + 25
  for i = 1, #self.m_robotAllData.RivalA.Speed do
    self.m_robotAllData.RivalA.Speed[i].Score = self.m_robotAllData.RivalA.Speed[i].Score + 25
  end
  self.m_robotAllData.RivalB.StartingScore = self.m_robotAllData.RivalB.StartingScore or 0
  self.m_robotAllData.RivalB.StartingScore = self.m_robotAllData.RivalB.StartingScore + 25
  for i = 1, #self.m_robotAllData.RivalB.Speed do
    self.m_robotAllData.RivalB.Speed[i].Score = self.m_robotAllData.RivalB.Speed[i].Score + 25
  end
end

function TeamActivityModel:TestTeamate50()
  self.m_robotAllData.TeamMate.StartingScore = self.m_robotAllData.TeamMate.StartingScore or 0
  self.m_robotAllData.TeamMate.StartingScore = self.m_robotAllData.TeamMate.StartingScore + 50
  for i = 1, #self.m_robotAllData.TeamMate.Speed do
    self.m_robotAllData.TeamMate.Speed[i].Score = self.m_robotAllData.TeamMate.Speed[i].Score + 50
  end
end

function TeamActivityModel:GetTestPopupWindowConfig()
  return {
    CheckFunc = function()
      return self:GetState(false) ~= ActivityState.Released
    end,
    config = {
      GroupName = "2v2\230\180\187\229\138\168(Team)",
      WindowList = {
        {
          BtnName = "\233\162\132\229\145\138",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.NoticeWindowPrefabName, self:GetType())
          end
        },
        {
          BtnName = "\229\188\128\229\167\139",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.ReadyWindowPrefabName, self:GetType())
          end
        },
        {
          BtnName = "\231\187\147\230\157\159/\229\174\140\230\136\144",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.EndWindowPrefabName, self:GetType())
          end
        },
        {
          BtnName = "\229\184\174\229\138\169",
          BtnClickFunc = function()
            GM.UIManager:OpenView(self.m_activityDefinition.HelpWindowPrefabName, self:GetType())
          end
        },
        {
          BtnName = "MVP",
          BtnClickFunc = function()
            if not self.m_robotAllData.TeamMate then
              GM.UIManager:ShowPrompt("\230\178\161\230\156\137\233\152\159\229\143\139")
              return
            end
            local mainWindow = GM.UIManager:GetOpenedViewByName(self.m_activityDefinition.MainWindowPrefabName)
            if mainWindow then
              GM.UIManager:OpenView(self.m_activityDefinition.MVPWindowPrefabName, self:GetType(), mainWindow, self:GetCurScore(), self.m_robotAllData.TeamMate.CurScore)
            else
              GM.UIManager:ShowPrompt("\229\133\136\230\137\147\229\188\128\228\184\187\233\161\181\233\157\162")
            end
          end
        }
      }
    }
  }
end

function TeamActivityModel:TestGetRaceInfo()
  return self.m_testInfo
end

function TeamActivityModel:TestClearTopTipTime()
  self.m_lastTopTipTime = 0
end

function TeamActivityModel:TestCheckRobotConfig()
  local originRobotConfig = Table.DeepCopy(GM.ConfigModel:GetLocalConfig(LocalConfigKey.TeamRobot))
  for _, config in pairs(originRobotConfig) do
    self:ConvertRobotSpeed(config)
    local lastTime, lastScore = 0, 0
    for i = 1, #config.speed do
      if config.speed[i].Type == 1 then
        local duration = config.speed[i].Time - lastTime
        local score = config.speed[i].Score - lastScore
        if duration > score then
          Log.Error("[2v2]: \229\129\135\228\186\186id: " .. tostring(config.id) .. " \231\172\172" .. i .. "\230\157\161\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\230\151\182\233\151\180\233\151\180\233\154\148\229\164\167\228\186\142\229\162\158\229\138\160\229\136\134\230\149\176\239\188\140\233\151\180\233\154\148:" .. tostring(duration) .. " \229\136\134\230\149\176:" .. tostring(score))
        elseif score > 2 * duration then
          Log.Error("[2v2]: \229\129\135\228\186\186id: " .. tostring(config.id) .. " \231\172\172" .. i .. "\230\157\161\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\229\162\158\229\138\160\229\136\134\230\149\176\229\164\167\228\186\1422\229\128\141\230\151\182\233\151\180\233\151\180\233\154\148\239\188\140\233\151\180\233\154\148:" .. tostring(duration) .. " \229\136\134\230\149\176:" .. tostring(score))
        end
      end
      lastScore = config.speed[i].Score
      lastTime = config.speed[i].Time
      if 1 < i and config.speed[i].Score <= config.speed[i - 1].Score then
        Log.Error("[2v2]: \229\129\135\228\186\186id: " .. config.id .. " " .. tostring(config.speed[i].Score) .. " <= " .. tostring(config.speed[i - 1].Score))
      end
    end
  end
end
