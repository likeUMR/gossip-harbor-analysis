BattleActivityModel = setmetatable({}, BaseActivityModel)
BattleActivityModel.__index = BattleActivityModel
local DBKeys = {
  CurRound = "CurRound",
  CurScore = "CurScore",
  RobotUserData = "RobotUserData",
  RobotScoreData = "RobotScoreData",
  SignUpTime = "SignUpTime",
  LastViewScore = "LastViewScore",
  RobotLastViewScore = "RobotLastViewScore",
  PopEndWindow = "PopEndWindow",
  LastTopTipTime = "LastTopTipTime",
  LastTopTipScore = "LastTopTipScore",
  LastRound = "LastRound",
  RaceResult = "RaceResult",
  SignUpCount = "SignUpCount",
  FirstOpenMainWindow = "FirstOpenMainWindow"
}
BattleActivityModel.EAddScoreScene = {
  Merge = "merge",
  Order = "order",
  Buy = "buy"
}
BattleActivityModel.ERaceState = {
  InRace = "0",
  Win = "1",
  Fail = "2",
  CanStart = "3"
}

function BattleActivityModel:Init(activityType, activityDataTable)
  self.m_activityDefinition = BattleActivityDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
end

function BattleActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
end

function BattleActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function BattleActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_robotUserData = nil
  self.m_robotScoreData = nil
  self.m_bRaceEndWindowPop = nil
  self:ClearCacheReward(true)
end

function BattleActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function BattleActivityModel:_LoadOtherServerConfig(config)
  self.m_rewardConfig = config.battleRewardConfig
  table.sort(self.m_rewardConfig, function(a, b)
    return a.round < b.round
  end)
  self.m_eventOrderScore = config.eventOrderScore
  self:LoadLocalConfig()
end

function BattleActivityModel:LoadLocalConfig()
  local mergeConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.MergeItemScoreConfig)
  self.m_mergeItemScoreConfig = {}
  for _, data in ipairs(mergeConfig) do
    self.m_mergeItemScoreConfig[data.item_id] = data
  end
  local originRobotConfig = Table.DeepCopy(GM.ConfigModel:GetLocalConfig(LocalConfigKey.BattleRobot))
  local groupId = self:GetServerConfigGroupId()
  self.m_robotConfig = {}
  for _, data in ipairs(originRobotConfig) do
    if data.groupId == groupId then
      if self.m_robotConfig[data.round] == nil then
        self.m_robotConfig[data.round] = {}
      end
      local speed = {}
      for _, speedData in ipairs(data.speed) do
        local splitSpeed = StringUtil.Split(speedData, "-")
        local speedConfig = {
          time = tonumber(splitSpeed[1]),
          score = tonumber(splitSpeed[2]),
          type = tonumber(splitSpeed[3])
        }
        if speedConfig.type ~= 0 and speedConfig.type ~= 1 and speedConfig.type ~= 2 then
          Log.Error("BattleActivityModel:LoadLocalConfig invalid robot speed type: " .. data.id .. " type: " .. tostring(speedConfig.type), LogTag.ConfigCheck)
        end
        table.insert(speed, speedConfig)
      end
      data.speed = speed
      table.sort(data.speed, function(a, b)
        return a.time < b.time
      end)
      for i = 2, #data.speed do
        if data.speed[i].score <= data.speed[i - 1].score then
          Log.Error("BattleActivityModel:LoadLocalConfig invalid robot speed score : " .. data.id .. " " .. tostring(data.speed[i].score) .. " <= " .. tostring(data.speed[i - 1].score), LogTag.ConfigCheck)
        end
      end
      table.insert(self.m_robotConfig[data.round], data)
    end
  end
  self.m_robotUserData = json.decode(self.m_dbTable:GetValue(DBKeys.RobotUserData, "value") or "{}")
  self.m_robotScoreData = json.decode(self.m_dbTable:GetValue(DBKeys.RobotScoreData, "value") or "{}")
end

function BattleActivityModel:GetServerConfigGroupId()
  return self.m_rewardConfig[1].groupId
end

function BattleActivityModel:_OnStateChanged()
  local state = self:GetState(false)
  if state == ActivityState.Started and self.m_eventOrderScore ~= nil then
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty, self, self.m_eventOrderScore, self.m_activityDefinition.TokenProperty, function(num, scene)
      self:AddScore(num, scene == EBIType.FinishOrder and BattleActivityModel.EAddScoreScene.Order or BattleActivityModel.EAddScoreScene.Buy)
    end, function()
      return self:CanAddScore()
    end, nil, true)
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function BattleActivityModel:_OnItemMerged(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel then
    self:_TryAddMergeScore(message.Source)
  end
end

function BattleActivityModel:_TryAddMergeScore(itemModel)
  if not self:CanAddScore() then
    return
  end
  local itemType = itemModel:GetType()
  if self.m_mergeItemScoreConfig[itemType] == nil then
    return
  end
  local mergeScore = self.m_mergeItemScoreConfig[itemType].merge_score_race
  if mergeScore ~= nil then
    self:AddScore(mergeScore, BattleActivityModel.EAddScoreScene.Merge, itemModel)
  end
end

function BattleActivityModel:AddScore(addScore, scene, itemModel)
  local targetScore = self:GetTargetScore()
  if targetScore == nil then
    return
  end
  local curScore = self:GetCurScore()
  if targetScore <= curScore then
    return
  end
  local newScore = math.min(curScore + addScore, targetScore)
  self:SetCurScore(newScore)
  self:TryPopTopTip(curScore, newScore, true)
  self:LogActivity(EBIType.ActivityAddScore, GM.BIManager:TableToString({
    r = self:GetCurRound(),
    c = self:GetSignUpCount(),
    s = addScore,
    t = scene
  }))
  EventDispatcher.DispatchEvent(self.m_activityDefinition.ScoreChangedEvent, {
    Scene = scene,
    Source = itemModel,
    TokenScore = addScore
  })
  if newScore == targetScore then
    if self:GetRaceState() ~= BattleActivityModel.ERaceState.InRace then
      return
    end
    self:RaceEnd(BattleActivityModel.ERaceState.Win)
  end
end

function BattleActivityModel:CanAddScore()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self:IsAllRoundFinished() then
    return false
  end
  if self:GetRaceState() == BattleActivityModel.ERaceState.InRace then
    return true
  end
end

function BattleActivityModel:IsAllRoundFinished()
  local curRound = self:GetCurRound()
  return self.m_rewardConfig ~= nil and curRound > #self.m_rewardConfig
end

function BattleActivityModel:CanSignUp()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self:IsAllRoundFinished() then
    return false
  end
  if self:GetRaceState() == nil or self:GetRaceState() == BattleActivityModel.ERaceState.CanStart then
    return true
  end
end

function BattleActivityModel:TrySignUp(callback)
  if not self:CanSignUp() then
    return
  end
  if self:GetRaceState() == BattleActivityModel.ERaceState.CanStart then
    self:RefreshData()
  end
  local curRound = self:GetCurRound()
  if self.m_robotConfig[curRound] == nil then
    Log.Error("BattleActivityModel:TrySignUp no config for round " .. tostring(curRound))
    return
  end
  ApiMessage.GetRobotNameList(1, function(success, resp)
    if not success or resp.rcode == 1 then
      callback(false)
      return
    end
    local robotList = resp.robot_names
    if Table.IsEmpty(robotList) or #robotList ~= 1 then
      callback(false)
      if GameConfig.IsTestMode() then
        Log.Error("[\231\167\175\229\136\1341v1]\230\138\165\229\144\141\232\142\183\229\143\150\229\129\135\228\186\186\229\144\141\229\173\151\228\184\186\231\169\186\230\136\150\230\149\176\233\135\143\228\184\141\229\175\185\239\188\140\230\149\176\233\135\143\239\188\154" .. tostring(#robotList))
      end
      return
    end
    self:StartRace(robotList[1])
    callback(true)
  end)
end

function BattleActivityModel:StartRace(name)
  local curRound = self:GetCurRound()
  local selectRobotConfig = Table.DeepCopy(Table.ListRandomSelectOne(self.m_robotConfig[curRound]))
  local lastTime, lastScore = 0, 0
  for i = 1, #selectRobotConfig.speed do
    if selectRobotConfig.speed[i].type == 1 then
      local scoreCountMap = {}
      local duration = selectRobotConfig.speed[i].time - lastTime
      local score = selectRobotConfig.speed[i].score - lastScore
      if duration > score then
        table.insert(scoreCountMap, {
          score = 0,
          count = duration - score
        })
        table.insert(scoreCountMap, {score = 1, count = score})
        if GameConfig.IsTestMode() then
          Log.Error("BattleActivityModel:TrySignUp \229\129\135\228\186\186id: " .. selectRobotConfig.id .. " \231\172\172" .. i .. "\230\157\161\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\230\151\182\233\151\180\233\151\180\233\154\148\229\164\167\228\186\142\229\162\158\229\138\160\229\138\160\229\136\134\239\188\140\233\151\180\233\154\148:" .. tostring(duration) .. " \229\136\134\230\149\176:" .. tostring(score))
        end
      elseif score > 2 * duration then
        table.insert(scoreCountMap, {
          score = 1,
          count = duration - 1
        })
        table.insert(scoreCountMap, {
          score = score - (duration - 1),
          count = 1
        })
        if GameConfig.IsTestMode() then
          Log.Error("BattleActivityModel:TrySignUp \229\129\135\228\186\186id: " .. selectRobotConfig.id .. " \231\172\172" .. i .. "\230\157\161\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\229\162\158\229\138\160\229\136\134\230\149\176\229\164\167\228\186\1422\229\128\141\230\151\182\233\151\180\233\151\180\233\154\148\239\188\140\233\151\180\233\154\148:" .. tostring(duration) .. " \229\136\134\230\149\176:" .. tostring(score))
        end
      else
        local count1 = duration - score + duration
        if 0 < count1 then
          table.insert(scoreCountMap, {score = 1, count = count1})
        end
        local count2 = score - duration
        if 0 < count2 then
          table.insert(scoreCountMap, {score = 2, count = count2})
        end
      end
      selectRobotConfig.speed[i].scoreCountMap = scoreCountMap
    end
    lastScore = selectRobotConfig.speed[i].score
    lastTime = selectRobotConfig.speed[i].time
  end
  local robotAvatar = UIHelper.GetRandomAvatarIcon(1)[1]
  local robotAvatarFrame = UIHelper.GetRandomAvatarIconFrame(1)[1]
  self.m_robotUserData = {
    Name = name,
    Avatar = robotAvatar,
    AvatarFrame = robotAvatarFrame
  }
  self.m_robotScoreData = {Config = selectRobotConfig, Score = 0}
  self:SaveRobotUserData()
  self:SaveRobotScoreData()
  self:SetSignUpTime()
  local singUpCount = self:GetSignUpCount() + 1
  self:SetSignUpCount(singUpCount)
  self:SetRaceState(BattleActivityModel.ERaceState.InRace)
  GM.BIManager:LogAction(self.m_activityDefinition.SignUpBIType, {
    r = curRound,
    c = singUpCount,
    g = self:GetServerConfigGroupId()
  })
  EventDispatcher.DispatchEvent(self.m_activityDefinition.SignUpEvent)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function BattleActivityModel:RaceEnd(raceResult)
  if raceResult == BattleActivityModel.ERaceState.Fail then
    EventDispatcher.DispatchEvent(self.m_activityDefinition.RaceEndEvent)
  end
  self:SetPopRaceEndWindow(true)
  local biAction = {
    r = self:GetCurRound(),
    c = self:GetSignUpCount(),
    ss = self:GetCurScore(),
    rs = self.m_robotScoreData.Score,
    rank = raceResult,
    st = self:GetSignUpTime(),
    et = GM.GameModel:GetServerTime(),
    id = self:GetId(),
    g = self:GetServerConfigGroupId()
  }
  GM.BIManager:LogAction(self.m_activityDefinition.RaceEndBIType, biAction)
  if not ApplicationManager.Instance.isNetworkConnected then
    self:SetRaceState(raceResult)
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
    return
  end
  self:SetRaceState(BattleActivityModel.ERaceState.CanStart)
  if raceResult == BattleActivityModel.ERaceState.Win then
    local curRound = self:GetCurRound()
    local roundReward = self:GetRoundReward(curRound)
    self.m_cacheRewards = {roundReward}
    RewardApi.AcquireRewardsLogic(roundReward, EPropertySource.Give, self.m_activityDefinition.GetRoundRewardBIType, EGameMode.Main, CacheItemType.Type2)
    local stageReward = self:GetCurStageRewardsByRound(curRound)
    if stageReward ~= nil then
      RewardApi.AcquireRewardsLogic(stageReward, EPropertySource.Give, self.m_activityDefinition.GetStageRewardBIType, EGameMode.Main, CacheItemType.Type2)
      table.insert(self.m_cacheRewards, stageReward)
      GM.BIManager:LogAction(self.m_activityDefinition.GetStageRewardBIType, {
        r = curRound,
        g = self:GetServerConfigGroupId()
      })
    end
    self:SetCurRound(curRound + 1)
    self:SetSignUpCount(0)
    self:LogActivity(EBIType.ActivityRankUp, curRound)
    self:LogActivity(EBIType.ActivityGetRewards, curRound)
  end
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function BattleActivityModel:ClearCacheReward(bRewardInView)
  if not Table.IsEmpty(self.m_cacheRewards) then
    if bRewardInView then
      RewardApi.AcquireRewardsInView(self.m_cacheRewards)
    end
    self.m_cacheRewards = {}
  end
end

function BattleActivityModel:RefreshData()
  self:SetCurScore(0)
  self:ClearRobotUserData()
  self:ClearRobotScoreData()
  self:ClearSignUpTime()
  self:ClearLastViewData()
  self:SaveLastTopTipScore()
end

local testScoreShow = ""

function BattleActivityModel:TryUpdateRobotScore()
  local curTime = GM.GameModel:GetServerTime()
  local startTime = self:GetSignUpTime()
  local elapsedTime = curTime - startTime
  local speedConfig = self.m_robotScoreData.Config.speed
  local curScore = self.m_robotScoreData.Score
  if elapsedTime >= speedConfig[#speedConfig].time then
    self.m_robotScoreData.Score = speedConfig[#speedConfig].score
    if curScore ~= self.m_robotScoreData.Score then
      self:_UpdateToScore(curScore)
      if GameConfig.IsTestMode() then
        Log.Info("[\231\167\175\229\136\1341v1] \229\129\135\228\186\186\229\189\147\229\137\141\231\187\143\232\191\135\230\151\182\233\151\180: " .. elapsedTime .. ", \231\167\175\229\136\134\229\143\152\229\140\150\239\188\154" .. self.m_robotScoreData.Score)
      end
    end
    return
  end
  for i = #speedConfig, 1, -1 do
    local speedData = speedConfig[i]
    local lastStageTime = i == 1 and 0 or speedConfig[i - 1].time
    local deltaTime = speedData.time - lastStageTime
    if elapsedTime <= speedData.time and elapsedTime > lastStageTime then
      local lastStageScore = i == 1 and 0 or speedConfig[i - 1].score
      if lastStageScore > self.m_robotScoreData.Score then
        self.m_robotScoreData.Score = lastStageScore
        if GameConfig.IsTestMode() then
          Log.Info("[\231\167\175\229\136\1341v1] \229\129\135\228\186\186\229\189\147\229\137\141\231\187\143\232\191\135\230\151\182\233\151\180: " .. elapsedTime .. ", \231\167\175\229\136\134\232\183\179\229\136\176\239\188\154" .. self.m_robotScoreData.Score)
        end
      end
      if speedData.type == 0 then
        local deltaScore = speedData.score - lastStageScore
        self.m_robotScoreData.Score = math.ceil(EaseUtil.GetInterpolatedValue(lastStageScore, speedData.score, deltaTime, elapsedTime - lastStageTime, Ease.InOutQuart))
        if GameConfig.IsTestMode() then
          testScoreShow = ""
          local t = (elapsedTime - lastStageTime) / deltaTime
          local ease = string.format("%.5f", EaseUtil.InOutQuart(t))
          local res = lastStageScore + (speedData.score - lastStageScore) * ease
          testScoreShow = testScoreShow .. "t = " .. elapsedTime - lastStageTime .. "/" .. deltaTime .. "\n"
          testScoreShow = testScoreShow .. "ease = " .. ease .. "\n"
          testScoreShow = testScoreShow .. lastStageScore .. " + (" .. speedData.score .. " - " .. lastStageScore .. ") * " .. ease .. " = " .. res
        end
      elseif speedData.type == 2 then
        if elapsedTime == speedData.time then
          self.m_robotScoreData.Score = speedData.score
        end
      elseif speedData.type == 1 then
        local restCount = 0
        for _, v in ipairs(speedData.scoreCountMap) do
          restCount = restCount + v.count
        end
        local num = elapsedTime - speedData.time + restCount
        local addScore = 0
        for i = 1, num do
          local selected = Table.ListRandomSelectOne(speedData.scoreCountMap)
          selected.count = selected.count - 1
          addScore = addScore + selected.score
          if 0 >= selected.count then
            Table.ListRemove(speedData.scoreCountMap, selected)
          end
        end
        self.m_robotScoreData.Score = self.m_robotScoreData.Score + addScore
      end
      if self.m_robotScoreData.Score ~= curScore then
        self:_UpdateToScore(curScore)
        if GameConfig.IsTestMode() then
          Log.Info("[\231\167\175\229\136\1341v1] \229\129\135\228\186\186\229\189\147\229\137\141\231\187\143\232\191\135\230\151\182\233\151\180: " .. elapsedTime .. ", \230\155\180\230\150\176\231\177\187\229\158\139: " .. speedData.type .. ", \231\167\175\229\136\134\230\155\180\230\150\176\228\184\186\239\188\154" .. self.m_robotScoreData.Score)
        end
      end
      break
    end
  end
end

function BattleActivityModel:_UpdateToScore(preScore)
  self.m_dbTable:Set(DBKeys.RobotScoreData, "value", json.encode(self.m_robotScoreData))
  EventDispatcher.DispatchEvent(self.m_activityDefinition.RobotScoreChangedEvent, self.m_robotScoreData.Score == self:GetTargetScore())
  self:TryPopTopTip(preScore, self.m_robotScoreData.Score, false)
  if self.m_robotScoreData.Score == self:GetTargetScore() then
    if self:GetRaceState() ~= BattleActivityModel.ERaceState.InRace then
      return
    end
    self:RaceEnd(BattleActivityModel.ERaceState.Fail)
  end
end

function BattleActivityModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self:GetRaceState() == BattleActivityModel.ERaceState.InRace then
    self:TryUpdateRobotScore()
  end
  if ApplicationManager.Instance.isNetworkConnected then
    local result = self:GetRaceState()
    if result == BattleActivityModel.ERaceState.Win or result == BattleActivityModel.ERaceState.Fail then
      self:RaceEnd(result)
    end
  end
end

function BattleActivityModel:TryPopTopTip(curScore, newScore, isPlayer)
  local compareScore = isPlayer and self.m_robotScoreData.Score or self:GetCurScore()
  local targetScore = self:GetTargetScore()
  local lastTopTipTime = GM.GameModel:GetServerTime() - self:GetLastTopTipTime()
  if lastTopTipTime <= 20 then
    return
  end
  local canPop = false
  local targetScore50 = targetScore * 0.5
  if 20 < lastTopTipTime and curScore < compareScore and newScore > compareScore then
    local targetScore85 = targetScore * 0.85
    local leadingScore = newScore - compareScore
    if compareScore > targetScore85 and compareScore < targetScore then
      canPop = true
      if GameConfig.IsTestMode() then
        Log.Info("[\231\167\175\229\136\1341v1] \230\181\174\231\170\151\230\131\133\229\134\181\228\184\137\232\167\166\229\143\145")
      end
    end
    if 60 < lastTopTipTime and (compareScore <= targetScore50 and 10 <= leadingScore or compareScore > targetScore50 and compareScore <= targetScore85 and 3 <= leadingScore) then
      canPop = true
      if GameConfig.IsTestMode() then
        if compareScore <= targetScore50 and 10 <= leadingScore then
          Log.Info("[\231\167\175\229\136\1341v1] \230\181\174\231\170\151\230\131\133\229\134\181\228\184\128\232\167\166\229\143\145")
        else
          Log.Info("[\231\167\175\229\136\1341v1] \230\181\174\231\170\151\230\131\133\229\134\181\228\186\140\232\167\166\229\143\145")
        end
      end
    end
  end
  if 60 < lastTopTipTime and curScore < targetScore50 and newScore >= targetScore50 and curScore > compareScore then
    canPop = true
    if GameConfig.IsTestMode() then
      Log.Info("[\231\167\175\229\136\1341v1] \230\181\174\231\170\151\230\131\133\229\134\181\229\155\155\232\167\166\229\143\145")
    end
  end
  if canPop then
    TopSliderManager.TrySlide(SliderType.Battle, self.m_activityDefinition.TopTipPrefabName, function(go)
      if self:GetState() ~= ActivityState.Started or self:GetRaceState() ~= BattleActivityModel.ERaceState.InRace or GM.UIManager:GetOpenedViewByName(self.m_activityDefinition.MainWindowPrefabName) then
        AddressableLoader.Destroy(go)
        return
      end
      self:SetTopTipTime()
      go:GetLuaTable():Init(self)
      TopSliderManager.Appear(go, function()
        go:GetLuaTable():UpdateScores(function()
          TopSliderManager.Disappear(go)
        end)
      end, 1)
    end)
  end
end

function BattleActivityModel:GetTargetScore(round)
  local round = round or self:GetCurRound()
  if self.m_rewardConfig and self.m_rewardConfig[round] then
    return self.m_rewardConfig[round].target
  end
end

function BattleActivityModel:GetRoundReward(round)
  local round = round or self:GetCurRound()
  if self.m_rewardConfig and self.m_rewardConfig[round] then
    return self.m_rewardConfig[round].reward_1
  end
end

function BattleActivityModel:GetTotalRound()
  if self.m_rewardConfig then
    return #self.m_rewardConfig
  end
end

function BattleActivityModel:GetStageRewards()
  local results = {}
  for _, data in ipairs(self.m_rewardConfig) do
    if data.reward_2 ~= nil then
      table.insert(results, {
        round = data.round,
        reward = data.reward_2
      })
    end
  end
  return results
end

function BattleActivityModel:GetCurStageRewardsByRound(round)
  if self.m_rewardConfig and self.m_rewardConfig[round] then
    return self.m_rewardConfig[round].reward_2
  end
end

function BattleActivityModel:CanPopRaceEndWindow()
  return self.m_bRaceEndWindowPop
end

function BattleActivityModel:SetPopRaceEndWindow(bCanPop)
  self.m_bRaceEndWindowPop = bCanPop
end

function BattleActivityModel:SetCurScore(num)
  self.m_dbTable:Set(DBKeys.CurScore, "value", num)
end

function BattleActivityModel:GetCurScore()
  return self.m_dbTable:GetValue(DBKeys.CurScore, "value") or 0
end

function BattleActivityModel:SetCurRound(num)
  self.m_dbTable:Set(DBKeys.CurRound, "value", num)
end

function BattleActivityModel:GetCurRound()
  return self.m_dbTable:GetValue(DBKeys.CurRound, "value") or 1
end

function BattleActivityModel:SetPopEndWindow()
  self.m_dbTable:Set(DBKeys.PopEndWindow, "value", "1")
end

function BattleActivityModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(DBKeys.PopEndWindow, "value") ~= "1"
end

function BattleActivityModel:SetTopTipTime()
  self.m_dbTable:Set(DBKeys.LastTopTipTime, "value", GM.GameModel:GetServerTime())
end

function BattleActivityModel:GetLastTopTipTime()
  return self.m_dbTable:GetValue(DBKeys.LastTopTipTime, "value") or 0
end

function BattleActivityModel:SaveRobotUserData()
  self.m_dbTable:Set(DBKeys.RobotUserData, "value", json.encode(self.m_robotUserData))
end

function BattleActivityModel:ClearRobotUserData()
  self.m_robotUserData = nil
  self.m_dbTable:Remove(DBKeys.RobotUserData, "value")
end

function BattleActivityModel:SaveRobotScoreData()
  self.m_dbTable:Set(DBKeys.RobotScoreData, "value", json.encode(self.m_robotScoreData))
end

function BattleActivityModel:ClearRobotScoreData()
  self.m_robotScoreData = nil
  self.m_dbTable:Remove(DBKeys.RobotScoreData, "value")
end

function BattleActivityModel:GetRobotCurScore()
  if self.m_robotScoreData then
    return self.m_robotScoreData.Score
  end
end

function BattleActivityModel:SetSignUpTime()
  self.m_dbTable:Set(DBKeys.SignUpTime, "value", GM.GameModel:GetServerTime())
end

function BattleActivityModel:GetSignUpTime()
  return self.m_dbTable:GetValue(DBKeys.SignUpTime, "value")
end

function BattleActivityModel:ClearSignUpTime()
  self.m_dbTable:Remove(DBKeys.SignUpTime, "value")
end

function BattleActivityModel:SetRaceState(state)
  if not state then
    self.m_dbTable:Remove(DBKeys.RaceResult, "value")
  else
    self.m_dbTable:Set(DBKeys.RaceResult, "value", state)
  end
end

function BattleActivityModel:GetRaceState(state)
  return self.m_dbTable:GetValue(DBKeys.RaceResult, "value") or nil
end

function BattleActivityModel:SetSignUpCount(num)
  self.m_dbTable:Set(DBKeys.SignUpCount, "value", num)
end

function BattleActivityModel:GetSignUpCount()
  return self.m_dbTable:GetValue(DBKeys.SignUpCount, "value") or 0
end

function BattleActivityModel:GetLastRound()
  return self.m_dbTable:GetValue(DBKeys.LastRound, "value") or 1
end

function BattleActivityModel:GetLastScore()
  return self.m_dbTable:GetValue(DBKeys.LastViewScore, "value") or 0
end

function BattleActivityModel:SetLastRobotScore()
  self.m_dbTable:Set(DBKeys.RobotLastViewScore, "value", self.m_robotScoreData.Score)
end

function BattleActivityModel:GetLastRobotScore()
  return self.m_dbTable:GetValue(DBKeys.RobotLastViewScore, "value") or 0
end

function BattleActivityModel:GetLastPlayerData()
  local targetScore = self:GetTargetScore(self:GetLastRound())
  local selfData = {
    Name = GM.GameTextModel:GetText("event_user_you"),
    Avatar = GM.UserProfileModel:GetIcon(),
    AvatarFrame = GM.UserProfileModel:GetAvatarFrame(),
    Info = {
      score = self:GetLastScore(),
      targetScore = targetScore
    }
  }
  local robotData = {
    Name = self.m_robotUserData.Name,
    Avatar = self.m_robotUserData.Avatar,
    AvatarFrame = self.m_robotUserData.AvatarFrame,
    Info = {
      score = self:GetLastRobotScore(),
      targetScore = targetScore
    }
  }
  return selfData, robotData
end

function BattleActivityModel:GetRobotName()
  if self.m_robotUserData == nil then
    return ""
  end
  return self.m_robotUserData.Name
end

function BattleActivityModel:SetLastViewData()
  self.m_dbTable:Set(DBKeys.LastViewScore, "value", self:GetCurScore())
  self:SetLastRobotScore()
  self.m_dbTable:Set(DBKeys.LastRound, "value", self:GetCurRound())
end

function BattleActivityModel:ClearLastViewData()
  self.m_dbTable:Remove(DBKeys.LastViewScore, "value")
  self.m_dbTable:Remove(DBKeys.RobotLastViewScore, "value")
  self.m_dbTable:Remove(DBKeys.FirstOpenMainWindow, "value")
  self.m_dbTable:Set(DBKeys.LastRound, "value", self:GetCurRound())
end

function BattleActivityModel:MainWindowOpened()
  self.m_dbTable:Set(DBKeys.FirstOpenMainWindow, "value", "1")
end

function BattleActivityModel:IsFirstPopMainWindow()
  return self.m_dbTable:GetValue(DBKeys.FirstOpenMainWindow, "value") ~= "1"
end

function BattleActivityModel:SaveLastTopTipScore(selfScore, robotScore)
  if selfScore == nil then
    self.m_dbTable:Remove(DBKeys.LastTopTipScore, "value")
    return
  end
  local str = tostring(selfScore) .. "-" .. tostring(robotScore)
  self.m_dbTable:Set(DBKeys.LastTopTipScore, "value", str)
end

function BattleActivityModel:GetLastTopTipScore()
  local str = self.m_dbTable:GetValue(DBKeys.LastTopTipScore, "value")
  if str ~= nil then
    local arr = StringUtil.Split(str, "-")
    return tonumber(arr[1]) or 0, tonumber(arr[2]) or 0
  end
  return 0, 0
end

function BattleActivityModel:GetHudEntryShowConfig()
  return {
    Type = "BattleActivity",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.FinishedAllEvent
    },
    EntryPrefabConfigName = self.m_activityDefinition.HudEntryPrefabName,
    CheckFunc = function()
      return self:GetState() == ActivityState.Started and not self:IsAllRoundFinished()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = self.m_activityDefinition.EntryImageName,
    OnClickedFunc = function()
      if not ApplicationManager.Instance.isNetworkConnected then
        GM.UIManager:OpenView(UIPrefabConfigName.NetworkErrorWindow)
        return
      end
      if self:CanSignUp() and not self:CanPopRaceEndWindow() then
        if self:GetCurRound() == 1 and self:GetSignUpCount() == 0 then
          GM.UIManager:OpenView(self.m_activityDefinition.ReadyWindowPrefabName, self.m_type)
        else
          GM.UIManager:OpenView(self.m_activityDefinition.SignUpWindowPrefabName, self.m_type)
        end
      else
        GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self.m_type)
      end
    end,
    RedPointType = EntryRedPointType.Exc,
    GetRedPointNumFunc = function()
      return self:CanSignUp() and 1 or 0
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.ScoreChangedEvent,
      self.m_activityDefinition.RobotScoreChangedEvent,
      self.m_activityDefinition.SignUpEvent,
      self.m_activityDefinition.WaitForSignUpEvent
    }
  }
end

function BattleActivityModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.FinishedAllEvent
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_BattlectivityBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_BattlectivityBubbleCount",
    scrollToFunName = "ScrollToBattlectivity",
    activityType = self:GetType(),
    checkFun = function()
      return self:GetState() == ActivityState.Started and not self:IsAllRoundFinished()
    end
  }
end

function BattleActivityModel:TestRestartCurRound()
  self:SetCurRound(1)
  self:RefreshData()
  self:SetRaceState(nil)
  self:SetSignUpCount(0)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.WaitForSignUpEvent)
  GM.UIManager:OpenView(self.m_activityDefinition.ReadyWindowPrefabName, self:GetType())
end

function BattleActivityModel:TestRaceInfo()
  if Table.IsEmpty(self.m_robotScoreData) then
    return
  end
  local str = ""
  local startTime = self:GetSignUpTime()
  str = str .. "\228\187\152\232\180\185\229\136\134\231\187\132: " .. self.m_robotScoreData.Config.groupId .. "\n"
  str = str .. "\229\188\128\229\167\139\230\151\182\233\151\180: " .. TimeUtil.ToDate(startTime, ETimeFormat.UTCYMDHMS) .. "\n"
  str = str .. "\229\189\147\229\137\141\230\151\182\233\151\180: " .. TimeUtil.ToDate(GM.GameModel:GetServerTime(), ETimeFormat.UTCYMDHMS) .. "(" .. GM.GameModel:GetServerTime() - startTime .. [[
s)

]]
  str = str .. "\229\129\135\228\186\186id: " .. self.m_robotScoreData.Config.id .. "\n"
  str = str .. "\229\129\135\228\186\186\231\167\175\229\136\134\233\133\141\231\189\174: \n"
  for i, speedData in ipairs(self.m_robotScoreData.Config.speed) do
    TimeUtil.ToDate(speedData.time + startTime, ETimeFormat.UTCYMDHMS)
    str = str .. i .. " \230\151\182\233\151\180: " .. TimeUtil.ToDate(speedData.time + startTime, ETimeFormat.UTCYMDHMS) .. " (" .. speedData.time .. "s)" .. ", " .. speedData.score .. ", type: " .. speedData.type .. "\n"
    if speedData.type == 1 then
      str = str .. "\229\136\134\230\149\176-\230\172\161\230\149\176:     "
      for _, map in ipairs(speedData.scoreCountMap) do
        str = str .. "\229\136\134\230\149\176: " .. map.score .. ", \229\137\169\228\189\153\230\172\161\230\149\176: " .. map.count .. "\239\188\155"
      end
      str = str .. "\n"
    end
    if speedData.type == 0 then
      str = str .. "\230\155\178\231\186\191\232\174\161\231\174\151\231\187\134\232\138\130: \n" .. testScoreShow .. "\n"
    end
  end
  str = str .. "\n\229\189\147\229\137\141\229\129\135\228\186\186\231\167\175\229\136\134: " .. self.m_robotScoreData.Score .. "\n"
  return str
end

function BattleActivityModel:TestAddScore(num)
  if self:CanAddScore() then
    self:AddScore(num, "Test")
  end
end

function BattleActivityModel:TestClearSetTopTipTime()
  self.m_dbTable:Remove(DBKeys.LastTopTipTime, "value")
end

function BattleActivityModel:TestCheckRobotConfig()
  for round, configList in pairs(self.m_robotConfig) do
    local targetScore = self:GetTargetScore(round)
    for _, config in ipairs(configList) do
      local lastTime, lastScore = 0, 0
      for i = 1, #config.speed do
        if config.speed[i].type == 1 then
          local duration = config.speed[i].time - lastTime
          local score = config.speed[i].score - lastScore
          if duration > score then
            Log.Error("[\231\167\175\229\136\1341v1]: \229\129\135\228\186\186id: " .. tostring(config.id) .. " \231\172\172" .. i .. "\230\157\161\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\230\151\182\233\151\180\233\151\180\233\154\148\229\164\167\228\186\142\229\162\158\229\138\160\229\136\134\230\149\176\239\188\140\233\151\180\233\154\148:" .. tostring(duration) .. " \229\136\134\230\149\176:" .. tostring(score))
          elseif score > 2 * duration then
            Log.Error("[\231\167\175\229\136\1341v1]: \229\129\135\228\186\186id: " .. tostring(config.id) .. " \231\172\172" .. i .. "\230\157\161\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\229\162\158\229\138\160\229\136\134\230\149\176\229\164\167\228\186\1422\229\128\141\230\151\182\233\151\180\233\151\180\233\154\148\239\188\140\233\151\180\233\154\148:" .. tostring(duration) .. " \229\136\134\230\149\176:" .. tostring(score))
          end
        end
        if targetScore < config.speed[i].score then
          Log.Error("[\231\167\175\229\136\1341v1]: \229\129\135\228\186\186id: " .. tostring(config.id) .. " \231\172\172" .. i .. "\230\157\161\233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\229\136\134\230\149\176:" .. tostring(config.speed[i].score) .. " \232\182\133\232\191\135\230\156\172\232\189\174\231\155\174\230\160\135\229\136\134\230\149\176:" .. tostring(targetScore))
        end
        lastScore = config.speed[i].score
        lastTime = config.speed[i].time
      end
      if lastScore ~= targetScore then
        Log.Error("[\231\167\175\229\136\1341v1]: \229\129\135\228\186\186id: " .. tostring(config.id) .. " \233\133\141\231\189\174\229\188\130\229\184\184\239\188\140\230\156\128\231\187\136\229\136\134\230\149\176:" .. tostring(lastScore) .. " \228\184\141\231\173\137\228\186\142\230\156\172\232\189\174\231\155\174\230\160\135\229\136\134\230\149\176:" .. tostring(targetScore))
      end
    end
  end
end
