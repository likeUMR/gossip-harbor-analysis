ScoreRaceModel = setmetatable({
  RequestFullRankDataApiFuncName = "GetScoreRaceRank",
  HeartBeatReqGroupIdKey = "scoreGroupId",
  HeartBeatReqTokenKey = "scoreToken",
  HeartBeatRespRankKey = "scoreRank",
  HeartBeatRespAckTokenKey = "ackScoreToken",
  HeartBeatRespReachNumKey = "scoreReachedNum"
}, BaseActivityModel)
ScoreRaceModel.__index = ScoreRaceModel
EScoreRaceAddScoreScene = {Merge = "merge", Order = "order"}
local rankTrackMap = {
  [1] = 2,
  [2] = 4,
  [3] = 1,
  [4] = 5
}
ScoreRaceModel.Round = "round"
ScoreRaceModel.Score = "score"
ScoreRaceModel.GroupId = "groupId"
ScoreRaceModel.RankList = "rankList"
ScoreRaceModel.LastRankData = "lastRankData"
ScoreRaceModel.ReqStop = "reqStop"
ScoreRaceModel.HasPopReady = "hasPopReady"
ScoreRaceModel.NewRoundFirstOpen = "NewRoundFirstOpen"
ScoreRaceModel.RoundEntryTime = "roundEntryTime"
ScoreRaceModel.PopEndWindow = "PopEndWindow"
ScoreRaceModel.RequestLog = "RequestLog"
ScoreRaceModel.NextRequestTime = "NextRequestTime"
ScoreRaceModel.AlreadyDefeat = "AlreadyDefeat"
ScoreRaceModel.DefeatTimes = "DefeatTimes"
ScoreRaceModel.ArrRomanNumbers = {
  "I",
  "II",
  "III",
  "IV",
  "V",
  "VI",
  "VII",
  "VIII",
  "IX",
  "X",
  "XI",
  "XII",
  "XIII",
  "XIV",
  "XV",
  "XVI",
  "XVII",
  "XVIII",
  "XIX",
  "XX"
}

function ScoreRaceModel:Init(dbTable)
  BaseActivityModel.Init(self, ActivityType.ScoreRace, dbTable)
  self.m_fullRankData = json.decode(self.m_dbTable:GetValue(ScoreRaceModel.LastRankData, "value") or "") or {}
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
end

function ScoreRaceModel:_LoadOtherServerConfig(config)
  self.m_config.m_playertype = config.scoreRacePlayer
  table.sort(self.m_config.m_playertype, function(A, B)
    return A.round < B.round
  end)
  self.m_config.m_rewards = config.scoreRaceReward
  table.sort(self.m_config.m_rewards, function(A, B)
    return A.round < B.round
  end)
  local mergeItemConfig = require("Data.Config.MergeItemScoreConfig")
  self.m_config.mergeItemScore = {}
  for _, data in ipairs(mergeItemConfig) do
    self.m_config.mergeItemScore[data.item_id] = data
  end
  self.m_config.m_orderScore = {}
  local isUseDiff = false
  for _, cfg in pairs(config.eventOrderScore) do
    table.insert(self.m_config.m_orderScore, Table.DeepCopy(cfg, true))
    if not isUseDiff and IsNumber(cfg.diff_score_min) then
      isUseDiff = true
    end
  end
  self.m_addScoreUseDiff = isUseDiff
  if isUseDiff then
    table.sort(self.m_config.m_orderScore, function(a, b)
      return a.diff_score_min < b.diff_score_min
    end)
  else
    table.sort(self.m_config.m_orderScore, function(a, b)
      return a.gold_min < b.gold_min
    end)
  end
end

function ScoreRaceModel:_OnItemMerged(item)
  if not (self.m_config ~= nil and self:CheckOpen()) or not self:IsInGroup() then
    return
  end
  return self:_TryAddMergeScore(item)
end

function ScoreRaceModel:_TryAddMergeScore(itemModel)
  local itemType = itemModel:GetType()
  if self.m_config.mergeItemScore[itemType] == nil then
    return
  end
  local mergeScore = self.m_config.mergeItemScore[itemType].merge_score_race
  if mergeScore ~= nil then
    self:_AddScore(mergeScore, EScoreRaceAddScoreScene.Merge, itemModel)
  end
  return mergeScore
end

function ScoreRaceModel:AcquireActivityScore(num)
  self:_AddScore(num, EScoreRaceAddScoreScene.Order)
end

function ScoreRaceModel:GetGenerateItemByOrder(order)
  if not (self.m_config ~= nil and self:CheckOpen()) or not self:IsInGroup() then
    return
  end
  local selectedIdx, score
  if self.m_addScoreUseDiff then
    local diffScore = order:GetDiffScore()
    if diffScore == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_config.m_orderScore, diffScore, "diff_score_min", "diff_score_max")
    score = diffScore
  else
    local price = order:GetPrice()
    if price == 0 then
      return
    end
    selectedIdx = Table.BinarySearch(self.m_config.m_orderScore, price, "gold_min", "gold_max")
    score = price
  end
  if selectedIdx == nil then
    return
  end
  local selected = self.m_config.m_orderScore[selectedIdx]
  local count = selected.reward_num_percentage and math.floor(score * selected.reward_num_percentage / 10000) or selected.reward_num_fix
  if count <= 0 then
    return
  end
  return {
    [PROPERTY_TYPE] = EPropertyType.ScoreRaceScore,
    [PROPERTY_COUNT] = count
  }
end

function ScoreRaceModel:_OnOrderFinished(msg)
  local score = self:GetGenerateItemByOrder(msg.order)
  if score == nil then
    return
  end
  RewardApi.AcquireRewardsLogic({score}, EPropertySource.Give, EBIType.ScoreRaceFinishOrder, EGameMode.Main, CacheItemType.Type2)
  local message = {
    Order = msg.order,
    Number = score[PROPERTY_COUNT]
  }
  GM.MainBoardModel.event:Call(BoardEventType.CollectScoreRaceToken, message)
end

function ScoreRaceModel:_AddScore(addScore, scene, itemModel)
  if self:GetScore() >= self:GetTargetScore() then
    return
  end
  self:_OnTokenChanged(addScore, self:GetScore() + addScore < self:GetTargetScore() and scene == EScoreRaceAddScoreScene.Merge)
  EventDispatcher.DispatchEvent(EEventType.ScoreRaceScoreChanged, {
    Score = addScore,
    Scene = scene,
    Source = itemModel
  })
  local biInfo = {
    score = addScore,
    round = self:GetRound(),
    stime = self:GetRoundEntryTime(),
    scene = scene
  }
  self:LogActivity(EBIType.ActivityAddScore, GM.BIManager:TableToString(biInfo))
  if self:GetScore() >= self:GetTargetScore() and not self:HasViewController() then
    local viewController = self:GetNewViewController()
    viewController:State0()
  end
end

function ScoreRaceModel:GetRewards(rk)
  if 3 < rk or rk < 1 then
    if GameConfig.IsTestMode() then
      local info = "\231\167\175\229\136\134\231\171\158\233\128\159\231\187\147\231\174\151\230\142\146\229\144\141\228\184\141\229\175\185:" .. rk .. "???"
      GM.UIManager:ShowPrompt(info)
      Log.Info(info)
    end
    return nil
  end
  return self.m_config.m_rewards[self:GetRound()]["reward_" .. rk]
end

function ScoreRaceModel:IsAllRoundFinished()
  return self:GetRound() > #self.m_config.m_rewards
end

function ScoreRaceModel:IsInGroup()
  return self:GetScore() ~= -1 and self:GetGroupId() ~= 0
end

function ScoreRaceModel:CheckOpen()
  if self.m_config == nil then
    return false
  end
  return self:GetState() == ActivityState.Started and not self:IsAllRoundFinished() and not self:IsReqStop()
end

function ScoreRaceModel:GetHudEntryShowConfig()
  return {
    Type = "ScoreRace",
    ArrCheckShowEvent = {
      EEventType.ScoreRaceAllRoundFinished,
      EEventType.ScoreRaceStateChanged,
      EEventType.ScoreRaceDefeated
    },
    EntryPrefabConfigName = UIPrefabConfigName.ScoreRaceEntry,
    CheckFunc = function()
      local model = GM.ActivityManager:GetModel(ActivityType.ScoreRace)
      return model:GetState() == ActivityState.Preparing or model:CheckOpen()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = ESceneViewHudButtonKey.ScoreRace,
    EntryIconName = ImageFileConfigName.icon_scorerace,
    OnClickedFunc = nil,
    ArrUpdateEntryContentEvent = {
      EEventType.ScoreRaceUpdateRank,
      EEventType.ScoreRaceScoreChanged,
      EEventType.ScoreRaceStateChanged
    }
  }
end

function ScoreRaceModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      EEventType.ScoreRaceAllRoundFinished,
      EEventType.ScoreRaceStateChanged,
      EEventType.ScoreRaceDefeated
    },
    bubbleName = "m_scoreRaceBubble",
    bubbleNodeName = "m_ScoreRaceBubbleNode",
    entryPrefabName = UIPrefabConfigName.ScoreRaceBoardEntry,
    bubbleCountName = "m_ScoreRaceBubbleCount",
    scrollToFunName = "ScrollToScoreRaceBoardEntry",
    activityType = self:GetType(),
    checkFun = function()
      local model = GM.ActivityManager:GetModel(ActivityType.ScoreRace)
      return model:CheckOpen()
    end
  }
end

function ScoreRaceModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
end

function ScoreRaceModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(EEventType.ScoreRaceStateChanged)
  if self.m_lateInit then
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  end
end

function ScoreRaceModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_fullRankData = nil
  self.m_alreadyReset = nil
  self.m_defeatpreRankData = nil
  self.m_tempRank = 0
  EventDispatcher.DispatchEvent(EEventType.ScoreRaceUpdateRank)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function ScoreRaceModel:DropGroup()
  self.m_dbTable:Set(ScoreRaceModel.Round, "value", self:GetRound() == 1 and 2 or 1)
end

function ScoreRaceModel:GetResourceLabels()
  return {
    AddressableLabel.ScoreRace
  }
end

function ScoreRaceModel:SetRoundEntryTime(time)
  self.m_dbTable:Set(ScoreRaceModel.RoundEntryTime, "value", time)
end

function ScoreRaceModel:GetRoundEntryTime()
  return self.m_dbTable:GetValue(ScoreRaceModel.RoundEntryTime, "value") or 0
end

function ScoreRaceModel:GetScore()
  return self.m_dbTable:GetValue(ScoreRaceModel.Score, "value") or -1
end

function ScoreRaceModel:GetRound()
  return self.m_dbTable:GetValue(ScoreRaceModel.Round, "value") or 1
end

function ScoreRaceModel:GetRankList()
  return self.m_dbTable:GetValue(ScoreRaceModel.RankList, "value") or 0
end

function ScoreRaceModel:GetMaxRound()
  return #self.m_config.m_rewards
end

function ScoreRaceModel:GetRoundReward()
  local curRound = self:GetRound()
  local rewards = {
    self.m_config.m_rewards[curRound].reward_1,
    self.m_config.m_rewards[curRound].reward_2,
    self.m_config.m_rewards[curRound].reward_3
  }
  return rewards
end

function ScoreRaceModel:GetTargetScore()
  if self:IsAllRoundFinished() then
    return 0
  end
  return self.m_config.m_rewards[self:GetRound()].target
end

function ScoreRaceModel:GetGroupId()
  return self.m_dbTable:GetValue(ScoreRaceModel.GroupId, "value") or 0
end

function ScoreRaceModel:GetRank()
  return self.m_tempRank or 0
end

function ScoreRaceModel:UpdateRank(rank)
  if self.m_tempRank ~= rank then
    self.m_tempRank = rank
    EventDispatcher.DispatchEvent(EEventType.ScoreRaceUpdateRank)
  end
end

function ScoreRaceModel:ClearRankData()
  self.m_fullRankData = nil
  self.m_dbTable:Remove(ScoreRaceModel.LastRankData)
end

function ScoreRaceModel:SaveRankData()
  self.m_dbTable:Set(ScoreRaceModel.LastRankData, "value", json.encode(self.m_fullRankData))
end

function ScoreRaceModel:GetPlayerType()
  local rd = self:GetRound()
  if rd > self:GetMaxRound() then
    return -1
  end
  return self.m_config.m_playertype[rd].type
end

function ScoreRaceModel:IsReqStop()
  return self.m_dbTable:GetValue(ScoreRaceModel.ReqStop, "value") == "1"
end

function ScoreRaceModel:_OnTokenChanged(count, canWait)
  if self:IsInGroup() then
    self.m_dbTable:Set(ScoreRaceModel.Score, "value", math.min(self:GetTargetScore(), self:GetScore() + count))
    if canWait then
      if not self.m_waiting then
        self.m_waiting = true
        Scheduler.Schedule(function()
          if self.m_waiting then
            GM.HeartBeatManager:HeartBeatOnNextFrame(false)
            self.m_waiting = false
          end
        end, self, 20, 1)
      end
    else
      GM.HeartBeatManager:HeartBeatOnNextFrame(false)
      self.m_waiting = false
    end
  end
end

function ScoreRaceModel:EndReq()
  self.m_dbTable:Set(ScoreRaceModel.ReqStop, "value", "1")
  self:UpdateRank(0)
  EventDispatcher.DispatchEvent(EEventType.ScoreRaceUpdateRank)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function ScoreRaceModel:CanHeartBeat()
  return self:IsInGroup() and self:CheckOpen() and self:GetScore() ~= self:GetTargetScore()
end

function ScoreRaceModel:ToHeartBeat(request)
  if self:CanHeartBeat() then
    request[self.HeartBeatReqGroupIdKey] = self:GetGroupId()
    request[self.HeartBeatReqTokenKey] = self:GetScore()
  else
    request[self.HeartBeatReqGroupIdKey] = 0
    request[self.HeartBeatReqTokenKey] = 0
  end
end

function ScoreRaceModel:FromHeartBeat(response)
  if not self:CanHeartBeat() then
    return
  end
  if self:HasViewController() then
    return
  end
  if response[self.HeartBeatRespReachNumKey] >= 3 then
    if not self:IsDefeated() then
      self:SetDefeated(true)
      EventDispatcher.DispatchEvent(EEventType.ScoreRaceDefeated)
      self:UpdatePerSecond()
    end
    return
  end
  local rk = self:GetRank()
  self:UpdateRank(response[self.HeartBeatRespRankKey])
  if 0 < rk and rk < self:GetRank() and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ScoreRaceHint) then
    TopSliderManager.TrySlide(ActivityType.ScoreRace, UIPrefabConfigName.ScoreRaceFallBehindTip, function(go)
      if GM.SceneManager:GetGameMode() ~= EGameMode.Main then
        GameObject.Destroy(go)
        return
      end
      TopSliderManager.Appear(go, function()
        DelayExecuteFunc(function()
          TopSliderManager.Disappear(go)
        end, 0.5)
      end)
    end)
  end
end

function ScoreRaceModel:ResetAndRequestAgain(response, callback, info)
  self:RecordResp(true, false, response, info)
  if self.m_alreadyReset then
    self:EndReq()
    callback(false)
    if GameConfig.IsTestMode() then
      local info = "\231\167\175\229\136\134\231\171\158\233\128\159\232\175\183\230\177\130\228\184\141\228\184\128\232\135\180" .. response.rcode .. "\239\188\140\232\175\183\230\177\130\232\191\155\229\133\165\229\190\170\231\142\175\239\188\140\231\187\136\230\173\162\229\144\142\231\187\173\232\175\183\230\177\130"
      GM.UIManager:ShowPrompt(info)
      Log.Info(info)
    end
    return
  else
    self.m_alreadyReset = true
  end
  if GameConfig.IsTestMode() then
    local info = "\231\167\175\229\136\134\231\171\158\233\128\159\232\175\183\230\177\130\228\184\141\228\184\128\232\135\180" .. response.rcode
    GM.UIManager:ShowPrompt(info)
    Log.Info(info)
  end
  self.m_dbTable:Set(ScoreRaceModel.GroupId, "value", 0)
  self.m_dbTable:Set(ScoreRaceModel.Score, "value", 0)
  self:UpdateRank(0)
  EventDispatcher.DispatchEvent(EEventType.ScoreRaceUpdateRank)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  self.m_fullRankData = nil
  self:SaveRankData()
  self:RequestFullRankData(callback)
end

ScoreRaceModel.ErrorStatus = {
  VALID_STATUS = 0,
  EXPIRED_JOINTIME = 1,
  ROLLED_ROUND = 2,
  INVALID_CONFIG = 3,
  UNMATCH_GROUPID = 4,
  LOCKCHANNEL_FAILED = 5,
  UNMATCH_TYPE = 6,
  GROUPRESULT_INVALID = 7,
  CHEAT_USER = 16,
  OTHER_ERROR = 17
}

function ScoreRaceModel:IsDefeatedRankData(RankData)
  local num = 0
  local rk = 0
  if not Table.IsEmpty(RankData) then
    local userId = GM.UserModel:GetUserId()
    local targetscore = self:GetTargetScore()
    for _, player in pairs(RankData) do
      if player.UserId ~= userId and targetscore <= player.Score then
        num = num + 1
      end
      if player.UserId == userId then
        rk = player.Rank
      end
    end
  end
  return 3 <= num and 4 <= rk
end

function ScoreRaceModel:RequestFullRankData(callback)
  if self:IsReqStop() then
    callback(false)
    return
  end
  if self.m_requestId == nil then
    self.m_requestId = 1
  else
    self.m_requestId = self.m_requestId + 1
  end
  local curRequestId = self.m_requestId
  
  local function wrapper(success, response)
    if not success or curRequestId < self.m_requestId then
      self:RecordResp(false)
      callback(false)
      return
    end
    local info
    if response.rcode == ScoreRaceModel.ErrorStatus.INVALID_CONFIG or response.rcode == ScoreRaceModel.ErrorStatus.UNMATCH_TYPE then
      self:EndReq()
      info = "\231\167\175\229\136\134\231\171\158\233\128\159\233\133\141\231\189\174\229\135\186\233\148\153\239\188\140\231\187\136\230\173\162\229\144\142\231\187\173\232\175\183\230\177\130" .. response.rcode
    elseif response.rcode == ScoreRaceModel.ErrorStatus.CHEAT_USER then
      self:EndReq()
      info = "\231\167\175\229\136\134\231\171\158\233\128\159\228\189\156\229\188\138\231\142\169\229\174\182\239\188\140\231\187\136\230\173\162\229\144\142\231\187\173\232\175\183\230\177\130" .. response.rcode
    elseif response.rcode == ScoreRaceModel.ErrorStatus.EXPIRED_JOINTIME or response.rcode == ScoreRaceModel.ErrorStatus.LOCKCHANNEL_FAILED then
      info = "\231\167\175\229\136\134\231\171\158\233\128\159\232\175\183\230\177\130\229\164\177\232\180\165" .. response.rcode
    elseif response.rcode == ScoreRaceModel.ErrorStatus.UNMATCH_GROUPID or response.rcode == ScoreRaceModel.ErrorStatus.ROLLED_ROUND or response.rcode == ScoreRaceModel.ErrorStatus.OTHER_ERROR then
      self:ResetAndRequestAgain(response, callback, "\231\167\175\229\136\134\231\171\158\233\128\159rcode\229\188\130\229\184\184")
      return
    elseif response.rcode == ScoreRaceModel.ErrorStatus.GROUPRESULT_INVALID then
      self:EndReq()
      info = "\231\167\175\229\136\134\231\171\158\233\128\159\230\156\141\229\138\161\229\153\168\230\151\182\233\151\180\229\183\178\231\187\147\230\157\159\230\180\187\229\138\168\239\188\140\231\187\136\230\173\162\229\144\142\231\187\173\232\175\183\230\177\130" .. response.rcode
    end
    if #response.ranks > 5 then
      info = "\231\167\175\229\136\134\231\171\158\233\128\159\232\191\155\231\187\132\228\186\186\230\149\176\232\182\133\232\191\1355\239\188\159" .. #response.ranks
    end
    if info ~= nil then
      if GameConfig.IsTestMode() then
        GM.UIManager:ShowPrompt(info)
        Log.Info(info)
      end
      self:RecordResp(true, false, response, info)
      callback(false)
      return
    end
    if not self:IsInGroup() then
      if response.group_id == 0 then
        self:ResetAndRequestAgain(response, callback, "\231\167\175\229\136\134\231\171\158\233\128\159\231\187\132id\232\191\148\228\186\1340")
        return
      end
      self:SetRoundEntryTime(GM.GameModel:GetServerTime())
      self.m_dbTable:Set(ScoreRaceModel.GroupId, "value", response.group_id)
      self.m_dbTable:Set(ScoreRaceModel.Score, "value", 0)
      GM.BIManager:LogAction(EBIType.ScoreRaceNewRound, {
        rd = self:GetRound(),
        times = self:GetDefeatTimes() + 1,
        type = self:GetPlayerType()
      })
      self.m_fullRankData = nil
      self:SaveRankData()
      GM.HeartBeatManager:TrySchedule()
      self:SetRequestTime()
      self:SetDefeated(false)
      if GameConfig.IsTestMode() then
        local info = "\231\167\175\229\136\134\231\171\158\233\128\159\232\191\155\231\187\132\230\136\144\229\138\159"
        GM.UIManager:ShowPrompt(info)
        Log.Info(info)
      end
      EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
    end
    local userId = GM.UserModel:GetUserId()
    local num = 0
    local preTrack = {}
    if not Table.IsEmpty(self.m_fullRankData) then
      for _, player in pairs(self.m_fullRankData) do
        if player.Track ~= nil then
          preTrack[player.UserId] = player.Track
          if player.UserId ~= userId then
            num = num + 1
          end
        end
      end
    end
    for _, data in ipairs(response.ranks) do
      if data.userid == userId and data.score ~= self:GetScore() then
        callback(false)
        return
      end
    end
    local temp = Table.DeepCopy(self.m_fullRankData)
    self.m_fullRankData = {}
    self.m_allZero = true
    local targetscore = self:GetTargetScore()
    for _, data in ipairs(response.ranks) do
      local rankData = {
        UserId = data.userid,
        Rank = data.rank,
        Name = data.name,
        Icon = data.icon,
        IconFrame = data.icon_frame,
        Score = math.min(data.score, targetscore)
      }
      if 0 < data.score then
        self.m_allZero = false
      end
      if preTrack[data.userid] ~= nil then
        rankData.Track = preTrack[data.userid]
      elseif data.userid ~= userId then
        num = num + 1
        rankData.Track = rankTrackMap[num]
      else
        rankData.Track = 3
      end
      table.insert(self.m_fullRankData, rankData)
      if data.userid == userId then
        self:UpdateRank(data.rank)
      end
    end
    self:SortRank(self.m_fullRankData)
    self:SaveRankData()
    local reset = false
    if self.m_alreadyReset then
      reset = true
      self.m_alreadyReset = false
    end
    self:RecordResp(true, true, response, self.m_fullRankData)
    if self:IsDefeatedRankData(self.m_fullRankData) then
      self:SetDefeated(true)
      self.m_defeatpreRankData = temp
      EventDispatcher.DispatchEvent(EEventType.ScoreRaceDefeated)
    end
    callback(true, reset)
  end
  
  ApiMessage[self.RequestFullRankDataApiFuncName](self:GetId(), self.m_type, self:GetGroupId(), self:GetScore(), self:GetPlayerType(), self:GetRound(), wrapper)
end

function ScoreRaceModel:SortRank(rankInfos)
  local newRank = Table.DeepCopy(rankInfos)
  local trackWeightMap = {
    [3] = 1,
    [2] = 2,
    [4] = 3,
    [1] = 4,
    [5] = 5
  }
  table.sort(newRank, function(a, b)
    if a.Rank ~= b.Rank then
      return a.Rank < b.Rank
    else
      return trackWeightMap[a.Track] < trackWeightMap[b.Track]
    end
  end)
  for _, info in ipairs(rankInfos) do
    for i, newInfo in ipairs(newRank) do
      if info.UserId == newInfo.UserId then
        info.Rank = i
        break
      end
    end
  end
end

function ScoreRaceModel:GetFullRankData()
  return self.m_fullRankData
end

function ScoreRaceModel:GetNewViewController()
  self.m_conCnt = (self.m_conCnt or 0) + 1
  local viewController = ScoreRaceViewController.Create(self.m_conCnt)
  self.m_conArr = self.m_conArr or {}
  self.m_conArr[self.m_conCnt] = viewController
  return viewController
end

function ScoreRaceModel:ViewControllerFinished(id)
  self.m_conArr[id] = nil
end

function ScoreRaceModel:HasViewController()
  return not Table.IsEmpty(self.m_conArr)
end

function ScoreRaceModel:GetRanks()
  local res = self:GetRankList()
  local record = {}
  while res ~= 0 do
    table.insert(record, res % 4)
    res = res // 4
  end
  return record
end

function ScoreRaceModel:GetDefeatTimes()
  return self.m_dbTable:GetValue(ScoreRaceModel.DefeatTimes, "value") or 0
end

function ScoreRaceModel:EndRound(rewards)
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, EBIType.ScoreRaceRankRewards, EGameMode.Main, CacheItemType.Type2)
  self:LogActivity(EBIType.ActivityRankUp, self:GetRound())
  self:LogActivity(EBIType.ActivityGetRewards, self:GetRound())
  GM.BIManager:LogAction(EBIType.ScoreRaceEndRound, {
    rd = self:GetRound(),
    times = self:GetDefeatTimes() + 1,
    rk = self:GetRank(),
    sc = self:GetScore(),
    res = "success",
    type = self:GetPlayerType()
  })
  self:RecordRank()
  self.m_dbTable:Set(ScoreRaceModel.Round, "value", self:GetRound() + 1)
  self.m_dbTable:Set(ScoreRaceModel.GroupId, "value", 0)
  self.m_dbTable:Set(ScoreRaceModel.Score, "value", -1)
  self.m_dbTable:Set(ScoreRaceModel.DefeatTimes, "value", 0)
  self:UpdateRank(0)
  EventDispatcher.DispatchEvent(EEventType.ScoreRaceUpdateRank)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  if self:IsAllRoundFinished() then
    EventDispatcher.DispatchEvent(EEventType.ScoreRaceAllRoundFinished)
  end
end

function ScoreRaceModel:RestartRound()
  GM.BIManager:LogAction(EBIType.ScoreRaceEndRound, {
    rd = self:GetRound(),
    times = self:GetDefeatTimes() + 1,
    rk = self:GetRank(),
    sc = self:GetScore(),
    res = "fail",
    type = self:GetPlayerType()
  })
  self.m_dbTable:Set(ScoreRaceModel.Round, "value", self:GetRound())
  self.m_dbTable:Set(ScoreRaceModel.GroupId, "value", 0)
  self.m_dbTable:Set(ScoreRaceModel.Score, "value", -1)
  self.m_dbTable:Set(ScoreRaceModel.DefeatTimes, "value", self:GetDefeatTimes() + 1)
  self:UpdateRank(0)
  EventDispatcher.DispatchEvent(EEventType.ScoreRaceUpdateRank)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  self:SetDefeated(false)
  self.m_defeatpreRankData = nil
end

function ScoreRaceModel:RecordRank()
  local res = self:GetRankList()
  res = res + (1 << self:GetRound() * 2 - 2) * self:GetRank()
  self.m_dbTable:Set(ScoreRaceModel.RankList, "value", res)
end

function ScoreRaceModel:GetTopPlayerInfo()
  local playersData = self:GetFullRankData()
  for i = 1, #playersData do
    if playersData[i].Rank == 1 then
      return playersData[i]
    end
  end
end

function ScoreRaceModel:CanPopReadyWindow()
  return self.m_dbTable:GetValue(ScoreRaceModel.HasPopReady, "value") ~= "1"
end

function ScoreRaceModel:SetCanPop()
  self.m_dbTable:Set(ScoreRaceModel.HasPopReady, "value", "")
end

function ScoreRaceModel:SetPoped()
  self.m_dbTable:Set(ScoreRaceModel.HasPopReady, "value", "1")
end

function ScoreRaceModel:IsRoundFirstOpen()
  return self.m_dbTable:GetValue(ScoreRaceModel.NewRoundFirstOpen, "value") ~= "1"
end

function ScoreRaceModel:SetRoundOpened(bOpened)
  self.m_dbTable:Set(ScoreRaceModel.NewRoundFirstOpen, "value", bOpened and "1" or "")
end

function ScoreRaceModel:CanApplyChoose()
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ScoreRaceForce) then
    return false
  end
  return self:GetRound() > 1 or not self:IsRoundFirstOpen()
end

function ScoreRaceModel:GetChangedPlayer(lastRankData, targetScore)
  local res = {}
  local bfinished = false
  local playersData = self:GetFullRankData()
  local mapTrack = {}
  for i = 1, #lastRankData do
    mapTrack[lastRankData[i].Track] = i
  end
  for i = 1, #playersData do
    if mapTrack[playersData[i].Track] == nil then
      local temp = Table.DeepCopy(playersData[i])
      temp.Score = 0
      table.insert(lastRankData, temp)
      mapTrack[playersData[i].Track] = #lastRankData
    end
    local xh = mapTrack[playersData[i].Track]
    if lastRankData[xh].Score ~= playersData[i].Score or lastRankData[xh].Rank ~= playersData[i].Rank then
      table.insert(res, playersData[i])
      if targetScore <= playersData[i].Score then
        bfinished = true
      end
    end
  end
  if bfinished then
    table.sort(res, function(a, b)
      return a.Rank < b.Rank
    end)
  end
  return bfinished, res
end

function ScoreRaceModel:GetDataByTrack(track)
  local playersData = self:GetFullRankData()
  for i = 1, #playersData do
    if playersData[i].Track == track then
      return playersData[i]
    end
  end
end

function ScoreRaceModel:SetPopEndWindow()
  self.m_dbTable:Set(ScoreRaceModel.PopEndWindow, "value", "1")
end

function ScoreRaceModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(ScoreRaceModel.PopEndWindow, "value") ~= "1"
end

function ScoreRaceModel:RecordReq(request)
  if GameConfig.IsTestMode() then
    local str = self.m_dbTable:GetValue(ScoreRaceModel.RequestLog, "value") or ""
    str = str .. "req--" .. "gp:" .. request.scoreGroupId .. "-rd:" .. request.round .. "-sc:" .. request.scoreToken .. " \n"
    self.m_dbTable:Set(ScoreRaceModel.RequestLog, "value", str)
  end
end

function ScoreRaceModel:RecordResp(success, updated, response, info)
  if GameConfig.IsTestMode() then
    local str = self.m_dbTable:GetValue(ScoreRaceModel.RequestLog, "value") or ""
    if not success then
      str = str .. "resp--failed \n"
    elseif not updated then
      str = str .. "resp--" .. "-rc:" .. response.rcode .. "-if:" .. info .. " \n"
    else
      str = str .. "resp--" .. "-gp:" .. response.group_id .. "- \n"
      for _, data in pairs(info) do
        str = str .. "-" .. data.UserId .. "-" .. data.Rank .. "-" .. data.Score .. "-" .. data.Track .. "-" .. data.IconFrame .. "- \n"
      end
    end
    self.m_dbTable:Set(ScoreRaceModel.RequestLog, "value", str)
  end
end

function ScoreRaceModel:GetLog()
  if GameConfig.IsTestMode() then
    local str = self.m_dbTable:GetValue(ScoreRaceModel.RequestLog, "value") or ""
    self.m_dbTable:Set(ScoreRaceModel.RequestLog, "value", "")
    return str
  end
end

function ScoreRaceModel:SetRequesting(state)
  self.m_requesting = state
end

function ScoreRaceModel:GetRequesting()
  return self.m_requesting
end

function ScoreRaceModel:SetRequestTime()
  self.m_dbTable:Set(ScoreRaceModel.NextRequestTime, "value", GM.GameModel:GetServerTime() + 11)
end

function ScoreRaceModel:GetRequestTime()
  return self.m_dbTable:GetValue(ScoreRaceModel.NextRequestTime, "value") or -1
end

function ScoreRaceModel:SetDefeated(state)
  self.m_dbTable:Set(ScoreRaceModel.AlreadyDefeat, "value", state)
end

function ScoreRaceModel:IsDefeated()
  return self.m_dbTable:GetValue(ScoreRaceModel.AlreadyDefeat, "value") or false
end

function ScoreRaceModel:GetDefeatpreRankData()
  return self.m_defeatpreRankData
end

function ScoreRaceModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:GetRequesting() or self.m_autoUpdate then
    return
  end
  if self:IsDefeated() then
    if self.m_defeatpreRankData == nil then
      local temp = Table.DeepCopy(self.m_fullRankData)
      self:SetRequesting(true)
      self:RequestFullRankData(function(success, reset)
        self:SetRequesting(false)
        if success and not reset then
          self.m_defeatpreRankData = temp
          EventDispatcher.DispatchEvent(EEventType.ScoreRaceDefeated)
        end
      end)
    end
    self.m_dbTable:Set(ScoreRaceModel.NextRequestTime, "value", -1)
    return
  end
  local reqtim = self:GetRequestTime()
  if reqtim ~= -1 and reqtim <= GM.GameModel:GetServerTime() then
    if not self:IsInGroup() or self:GetScore() >= self:GetTargetScore() then
      self.m_dbTable:Set(ScoreRaceModel.NextRequestTime, "value", -1)
    else
      self.m_autoUpdate = true
      self:RequestFullRankData(function(success, reset)
        self.m_autoUpdate = false
        if success and not reset then
          self.m_dbTable:Set(ScoreRaceModel.NextRequestTime, "value", -1)
        end
      end)
    end
  end
end
