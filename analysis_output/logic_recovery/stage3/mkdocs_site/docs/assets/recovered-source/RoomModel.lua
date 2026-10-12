RoomModel = setmetatable({}, BaseActivityModel)
RoomModel.__index = RoomModel
RoomModel.RoomItemToScore = {
  roomItem_n_1 = 5,
  roomItem_n_2 = 10,
  roomItem_r_1 = 20,
  roomItem_r_2 = 30,
  roomItem_sr_1 = 50,
  roomItem_ssr_1 = 100
}
local strSecretKey = "roomSecretItem"
local strDBKeys = {
  curActivityKey = "curActivityKey",
  activityToken = "activityToken",
  ExpriedReward = "ExpriedReward",
  preShowKey = "preShowKey",
  shownUnlock = "shownUnlock",
  PlayFirstRewardTutorial = "PlayFirstRewardTutorial"
}
RoomModel.eventKey = {AddlockStateScore = 1, AddUnlockStateScore = 2}

function RoomModel:IsCanPlayFirstRewardTutorial()
  return self.m_dbTable:GetValue(strDBKeys.PlayFirstRewardTutorial, "value") ~= "1"
end

function RoomModel:SetPlayFirstRewardTutorial()
  self.m_dbTable:Set(strDBKeys.PlayFirstRewardTutorial, "value", "1")
end

function RoomModel:TestClearFirstRewardTutorial()
  self.m_dbTable:Remove(strDBKeys.PlayFirstRewardTutorial, "value")
end

function RoomModel:SetUnlockMark()
  self.m_dbTable:Set(strDBKeys.shownUnlock, "value", "1")
end

function RoomModel:ClearUnlockMark()
  self.m_dbTable:Remove(strDBKeys.shownUnlock)
end

function RoomModel:NeedShowUnlock()
  return self.m_dbTable:GetValue(strDBKeys.shownUnlock, "value") == "1"
end

function RoomModel:Init(activityType, dbTable)
  self:LoadCacheData(dbTable)
  self.m_activityDefinition = RoomDefinition[activityType]
  BaseActivityModel.Init(self, activityType, dbTable)
  self.m_expireReward = json.decode(self.m_dbTable:GetValue(strDBKeys.ExpriedReward, "value") or "")
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
  EventDispatcher.AddListener(EEventType.ItemTransform, self, self._OnItemTransform)
end

function RoomModel:LateInit()
  self.m_bLateInit = true
  self:TryInitActivityData()
  if self:GetState() == ActivityState.Ended and self.m_expireReward == nil then
    self:ExchangeReward()
  end
end

function RoomModel:LoadCacheData(dbTable)
  self.m_curInfo = json.decode(dbTable:GetValue(strDBKeys.curActivityKey, "value") or "")
end

function RoomModel:_LoadOtherServerConfig(config)
  self.m_activateConfig = Table.ShallowCopy(config.roomActivate)
  table.sort(self.m_activateConfig, function(a, b)
    return a.round < b.round
  end)
  self.m_getToolConfig = {}
  for _, info in pairs(config.roomGetTool) do
    self.m_getToolConfig[info.round] = info
  end
  self.m_levelConfig = {}
  self.m_mxlevel = 0
  self.m_mncyclic = 99999999
  for _, info in pairs(config.roomLevel) do
    local temp = Table.DeepCopy(info)
    temp.draw = {}
    for _, Pr in ipairs(info.draw) do
      temp.draw[Pr.Index] = Pr.Weight
    end
    self.m_levelConfig[info.level] = temp
    self.m_mxlevel = math.max(self.m_mxlevel, info.level)
    if info.isCyclic == 1 then
      self.m_mncyclic = math.min(self.m_mncyclic, info.level)
    end
  end
  self.m_roomSecretItemsConfig = {}
  for _, info in pairs(config.roomReward) do
    if string.find(info.item_id, strSecretKey) ~= nil then
      table.insert(self.m_roomSecretItemsConfig, info)
    end
  end
  table.sort(self.m_roomSecretItemsConfig, function(a, b)
    return a.round < b.round
  end)
  self.m_stageRoundScoreReward = {}
  for _, info in pairs(config.roomScoreReward) do
    local mapStageInfo
    for _, eleInfo in ipairs(self.m_stageRoundScoreReward) do
      if eleInfo.stage == info.stage then
        mapStageInfo = eleInfo
        break
      end
    end
    if mapStageInfo == nil then
      mapStageInfo = {
        stage = info.stage,
        ListRoundInfo = {}
      }
      table.insert(self.m_stageRoundScoreReward, mapStageInfo)
    end
    mapStageInfo.ListRoundInfo[info.round] = info
  end
  table.sort(self.m_stageRoundScoreReward, function(a, b)
    return a.stage < b.stage
  end)
end

function RoomModel:TryInitActivityData()
  if self:GetState() == ActivityState.Started and self.m_curInfo == nil and self.m_bLateInit == true then
    self:InitActivityData()
  end
end

function RoomModel:_CalculateState()
  if self.m_config == nil then
    return ActivityState.Released, nil
  end
  local eTime = self.m_config.eTime
  if self.m_curInfo ~= nil and self.m_curInfo.roomState == 1 then
    eTime = math.max(eTime, self.m_curInfo.roomUnLockInfo.llEtime)
  end
  local serverTime = GM.GameModel:GetServerTime()
  if serverTime < self.m_config.sTime then
    return ActivityState.Preparing, self.m_config.sTime
  elseif eTime > serverTime then
    return ActivityState.Started, eTime
  elseif serverTime < self.m_config.rTime then
    return ActivityState.Ended, self.m_config.rTime
  else
    return ActivityState.Released, nil
  end
end

function RoomModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  self:TryInitActivityData()
  if self:GetState() == ActivityState.Ended and self.m_expireReward == nil then
    self:ExchangeReward()
  end
end

function RoomModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_curInfo = nil
  self.m_expireReward = nil
end

function RoomModel:GetExpiredReward()
  return self.m_expireReward
end

function RoomModel:SaveExpireReward()
  local jsonData = ""
  if self.m_expireReward ~= nil then
    jsonData = json.encode(self.m_expireReward)
    self.m_dbTable:Set(strDBKeys.ExpriedReward, "value", jsonData)
  end
end

function RoomModel:GetCurRoomActivateByRound(round)
  local target
  for _, info in ipairs(self.m_activateConfig) do
    if round >= info.round then
      target = info
    end
  end
  return target
end

function RoomModel:GetSecretItemConfig(round)
  for _, info in pairs(self.m_roomSecretItemsConfig) do
    if info.round == round then
      return info
    end
  end
  return self.m_roomSecretItemsConfig[#self.m_roomSecretItemsConfig]
end

function RoomModel:GetRoomGetToolConfig(round)
  if self.m_getToolConfig[round] ~= nil then
    return self.m_getToolConfig[round]
  end
  local num = 0
  for _, info in ipairs(self.m_getToolConfig) do
    if info.isCyclic == 1 then
      num = num + 1
    end
  end
  local newRound = round - #self.m_getToolConfig
  local curNum = (newRound - 1) % num + 1
  local index = 0
  for _, info in ipairs(self.m_getToolConfig) do
    if info.isCyclic == 1 then
      index = index + 1
      if index == curNum then
        return info
      end
    end
  end
  return nil
end

function RoomModel:InitActivityData()
  self.m_curInfo = {}
  self.m_curInfo.round = 1
  self.m_curInfo.roomState = 0
  self.m_curInfo.roomLockInfo = {}
  self.m_curInfo.roomLockInfo.curNum = 0
  local target = self:GetCurRoomActivateByRound(1)
  self.m_curInfo.roomLockInfo.maxNum = target.token
  self.m_curInfo.roomLockInfo.chance = target.chance
  self.m_curInfo.roomLockInfo.curAddScoreNum = target.chance[2]
  self.m_curInfo.roomLockInfo.curClickNum = target.chance[1]
  GM.BIManager:LogAction(self.m_activityDefinition.BINewRound, {
    round = self.m_curInfo.round
  })
  self.m_curInfo.roomUnLockInfo = {}
  self.m_curInfo.roomUnLockInfo.curScore = 0
  self.m_curInfo.roomUnLockInfo.itemMapInfo = {}
  self:UpdateRoomTool(1)
  self:InitSecretItemConifg()
  self:InitLevelInfo(1)
  self:SaveActivityData()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.GameStateChanged)
end

function RoomModel:InitSecretItemConifg()
  self.m_curInfo.roomUnLockInfo.secretIteminfo = {}
  self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretNum = 0
  self.m_curInfo.roomUnLockInfo.secretIteminfo.SercetItemRound = 1
  local SecretItemConfig = self:GetSecretItemConfig(1)
  self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretMaxNum = SecretItemConfig.num
  self.m_curInfo.roomUnLockInfo.secretIteminfo.rewards = SecretItemConfig.rewards
  self.m_curInfo.roomUnLockInfo.secretIteminfo.reward_icon = SecretItemConfig.reward_icon
end

function RoomModel:UpdateRoomTool(round)
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo = {}
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.curEnergy = 0
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.round = round
  local getToolConfig = self:GetRoomGetToolConfig(round)
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.energy = getToolConfig.energy
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.reward = getToolConfig.tools
end

function RoomModel:SaveActivityData()
  self.m_dbTable:Set(strDBKeys.curActivityKey, "value", json.encode(self.m_curInfo))
end

function RoomModel:SetTokenNum(num)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.TokenNumberChangedEvent, num - self:GetTokenNum())
  self.m_dbTable:Set(strDBKeys.activityToken, "value", num)
end

function RoomModel:GetTokenNum()
  local num = tonumber(self.m_dbTable:GetValue(strDBKeys.activityToken, "value") or "")
  if num == nil then
    num = 0
  end
  return num
end

function RoomModel:GetServerConfigGroupId()
  if self.m_stageRoundScoreReward ~= nil and self.m_stageRoundScoreReward[1] ~= nil and self.m_stageRoundScoreReward[1].ListRoundInfo[1] ~= nil then
    return self.m_stageRoundScoreReward[1].ListRoundInfo[1].groupId
  end
  return nil
end

function RoomModel:AcquireToken(num, source)
  self:SetTokenNum(num + self:GetTokenNum())
  if source ~= nil then
    self:LogActivity(EBIType.ActivityAddScore, "s : " .. source .. ";num : " .. tostring(num))
  end
end

function RoomModel:AcquireKey(num, source, itemCode)
  local bStateChanged = self:AddLockScore(num)
  GM.BIManager:LogAction(self.m_activityDefinition.BIAcquireKey, {
    source = source,
    num = num,
    itemCode = itemCode or "gift"
  })
  return bStateChanged
end

function RoomModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self.m_curInfo ~= nil and self.m_curInfo.roomState == 1 and self.m_curInfo.roomUnLockInfo.llEtime <= GM.GameModel:GetServerTime() then
    self:SetLockState()
  end
end

function RoomModel:_OnItemSpread(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:_TryGenerateItem(message.Source, message.EnergyBoostRatio)
  end
end

function RoomModel:_OnItemTransform(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:_TryGenerateItem(message.Source, 0)
  end
end

function RoomModel:_TryGenerateItem(sourceItem, energyBoostRatio)
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_curInfo == nil then
    Log.Error("\229\175\134\229\174\164\229\164\132\231\144\134\233\148\153\232\175\175\239\188\140 \229\164\177\229\142\187curInfo\228\191\161\230\129\175")
    return false
  end
  if self.m_curInfo.roomState == 0 then
    self:TryLockStartAddScore(sourceItem, energyBoostRatio)
  elseif self.m_curInfo.roomState == 1 then
    self:TryUnlockActivityToken(sourceItem, energyBoostRatio)
  end
end

function RoomModel:TryLockStartAddScore(sourceItem, energyBoostRatio)
  if self.m_curInfo.roomLockInfo.curClickNum <= 0 then
    self.m_curInfo.roomLockInfo.curClickNum = self.m_curInfo.roomLockInfo.chance[1]
    self.m_curInfo.roomLockInfo.curAddScoreNum = self.m_curInfo.roomLockInfo.chance[2]
  end
  local totalCount = self.m_curInfo.roomLockInfo.curClickNum
  local vailCount = self.m_curInfo.roomLockInfo.curAddScoreNum
  local radomIndex = math.random(totalCount)
  if vailCount < radomIndex then
    self.m_curInfo.roomLockInfo.curClickNum = self.m_curInfo.roomLockInfo.curClickNum - 1
    self:SaveActivityData()
    return
  end
  self.m_curInfo.roomLockInfo.curAddScoreNum = self.m_curInfo.roomLockInfo.curAddScoreNum - 1
  local num = math.ceil(2 ^ energyBoostRatio)
  local bStateChanged = self:AcquireKey(num, 2, sourceItem:GetType())
  self.event:Call(self.eventKey.AddlockStateScore, {
    score = num,
    stateChanged = bStateChanged,
    sourceItem = sourceItem,
    energyBoostRatio = energyBoostRatio
  })
  self:SaveActivityData()
end

function RoomModel:AddLockScore(score)
  self.m_curInfo.roomLockInfo.curNum = self.m_curInfo.roomLockInfo.curNum + score
  local bStateChanged = false
  if self.m_curInfo.roomLockInfo.curNum >= self.m_curInfo.roomLockInfo.maxNum then
    self.m_curInfo.roomLockInfo.curNum = self.m_curInfo.roomLockInfo.maxNum
    bStateChanged = true
    local activieConifg = self:GetCurRoomActivateByRound(self.m_curInfo.round)
    self:SetUnLockState(activieConifg)
  end
  self:SaveActivityData()
  return bStateChanged
end

function RoomModel:SetpreShow()
  self.m_dbTable:Set(strDBKeys.preShowKey, "value", self.m_curInfo.roomLockInfo.curNum)
end

function RoomModel:GetpreShow()
  return self.m_dbTable:GetValue(strDBKeys.preShowKey, "value") or 0
end

function RoomModel:TestAddLockScore(num)
  self.m_curInfo.roomLockInfo.curNum = self.m_curInfo.roomLockInfo.curNum + num
  local bStateChanged = false
  if self.m_curInfo.roomLockInfo.curNum >= self.m_curInfo.roomLockInfo.maxNum then
    self.m_curInfo.roomLockInfo.curNum = self.m_curInfo.roomLockInfo.maxNum
    bStateChanged = true
    local activieConifg = self:GetCurRoomActivateByRound(self.m_curInfo.round)
    self:SetUnLockState(activieConifg)
  end
  self:SaveActivityData()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.GameStateChanged)
end

function RoomModel:TestClearLockScore()
  self.m_curInfo.roomLockInfo.curNum = 0
  self:SaveActivityData()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.GameStateChanged)
end

function RoomModel:OnTestSetLockState()
  self.m_curInfo.roomUnLockInfo.llEtime = GM.GameModel:GetServerTime() + 1
  self:SaveActivityData()
end

function RoomModel:SetLockState()
  self.m_curInfo.roomState = 0
  self.m_curInfo.round = self.m_curInfo.round + 1
  local activieConifg = self:GetCurRoomActivateByRound(self.m_curInfo.round)
  self.m_curInfo.roomLockInfo.curNum = 0
  self.m_curInfo.roomLockInfo.chance = activieConifg.chance
  self.m_curInfo.roomLockInfo.maxNum = activieConifg.token
  self.m_curInfo.roomLockInfo.curAddScoreNum = activieConifg.chance[2]
  self.m_curInfo.roomLockInfo.curClickNum = activieConifg.chance[1]
  self:ClearUnlockMark()
  EventDispatcher.DispatchEvent(self.m_activityDefinition.GameStateChanged, {isLock = true})
  GM.BIManager:LogAction(self.m_activityDefinition.BINewRound, {
    round = self.m_curInfo.round
  })
  GM.BIManager:LogAction(self.m_activityDefinition.BIJoinLockState, {
    round = self.m_curInfo.round,
    secretNum = self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretNum,
    secretRound = self.m_curInfo.roomUnLockInfo.secretIteminfo.SercetItemRound,
    secretMaxNum = self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretMaxNum
  })
  self:SaveActivityData()
  EventDispatcher.DispatchEvent(EEventType.BundleDataRefreshed)
  self.m_bWaitPopup = 0
end

function RoomModel:SetUnLockState(activieConifg)
  self.m_bJustSetLockState = true
  self.m_curInfo.roomState = 1
  self.m_curInfo.roomUnLockInfo.curScore = 0
  local energyRound = self:GetRoomGetToolConfig(1)
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.curEnergy = 0
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.energy = energyRound.energy
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.round = 1
  self.m_curInfo.roomUnLockInfo.acuqireTokenInfo.reward = energyRound.tools
  self.m_curInfo.roomUnLockInfo.llEtime = GM.GameModel:GetServerTime() + activieConifg.time * 60 * 60
  self:SetUnlockMark()
  self:AcquireToken(2, 3)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.GameStateChanged, {isLock = false})
  GM.BIManager:LogAction(self.m_activityDefinition.BIJoinUnLockState, {
    round = self.m_curInfo.round,
    secretNum = self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretNum,
    secretRound = self.m_curInfo.roomUnLockInfo.secretIteminfo.SercetItemRound,
    secretMaxNum = self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretMaxNum
  })
  EventDispatcher.DispatchEvent(EEventType.BundleDataRefreshed)
  self:SaveActivityData()
  self.m_bWaitPopup = 1
end

function RoomModel:GetWaitPopup()
  return self.m_bWaitPopup
end

function RoomModel:ClearWaitPopup()
  self.m_bWaitPopup = nil
end

function RoomModel:IsJustSetLockState()
  return self.m_bJustSetLockState
end

function RoomModel:SetjustSetLockState(b)
  self.m_bJustSetLockState = b
end

function RoomModel:TryUnlockActivityToken(sourceItem, energyBoostRatio)
  local addScore = math.ceil(2 ^ energyBoostRatio)
  local rewards
  local acquireInfo = self.m_curInfo.roomUnLockInfo.acuqireTokenInfo
  acquireInfo.curEnergy = acquireInfo.curEnergy + addScore
  if acquireInfo.curEnergy >= acquireInfo.energy then
    acquireInfo.curEnergy = acquireInfo.curEnergy - acquireInfo.energy
    rewards = acquireInfo.reward
    RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_activityDefinition.BIGetReward, EGameMode.Main, CacheItemType.Type2)
    acquireInfo.round = acquireInfo.round + 1
    local energyRound = self:GetRoomGetToolConfig(acquireInfo.round)
    acquireInfo.energy = energyRound.energy
    acquireInfo.reward = energyRound.tools
  end
  self.event:Call(self.eventKey.AddUnlockStateScore, {
    score = addScore,
    rewards = rewards,
    sourceItem = sourceItem,
    energyBoostRatio = energyBoostRatio
  })
  self:SaveActivityData()
end

function RoomModel:GetUnlockETime()
  if self.m_curInfo == nil then
    return nil
  end
  return self.m_curInfo.roomUnLockInfo.llEtime
end

function RoomModel:GetSecretTreasureInfo()
  return self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretNum, self.m_curInfo.roomUnLockInfo.secretIteminfo.SecretMaxNum, self.m_curInfo.roomUnLockInfo.secretIteminfo.reward_icon
end

function RoomModel:GetItemInfo()
  return self.m_curInfo.roomUnLockInfo.itemMapInfo
end

function RoomModel:GetStageConfig(stage)
  local target
  for _, info in ipairs(self.m_stageRoundScoreReward) do
    if stage < info.stage then
      return target
    else
      target = info
    end
  end
  return target
end

function RoomModel:GetRoundByStageScore(stage, Score)
  local StageScoreRewrads = self:GetStageConfig(stage)
  local maxScore = StageScoreRewrads.ListRoundInfo[#StageScoreRewrads.ListRoundInfo].points
  local startNum = Score // maxScore * #StageScoreRewrads.ListRoundInfo
  local curScore = Score % maxScore
  local finishIndex = 0
  for index, info in ipairs(StageScoreRewrads.ListRoundInfo) do
    if curScore < info.points then
      return startNum + finishIndex, startNum
    else
      finishIndex = finishIndex + 1
    end
  end
  return startNum + finishIndex, startNum
end

function RoomModel:GetRoundConfigByStageRound(stage, round)
  local target
  local stageScoreRewards = self:GetStageConfig(stage)
  return stageScoreRewards.ListRoundInfo[(round - 1) % #stageScoreRewards.ListRoundInfo + 1]
end

function RoomModel:AcquireActivityTreasure(strTreareName)
  local isSecret = false
  local isfirstTime = false
  local rewards
  local isPassAll = false
  local cur, tar
  if string.find(strTreareName, strSecretKey) then
    isSecret = true
    local secretTreasure = self.m_curInfo.roomUnLockInfo.secretIteminfo
    secretTreasure.SecretNum = secretTreasure.SecretNum + 1
    if secretTreasure.SecretNum >= secretTreasure.SecretMaxNum then
      rewards = secretTreasure.rewards
      RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_activityDefinition.BISecretPlus, EGameMode.Main, CacheItemType.Type2)
      self:LogActivity(EBIType.ActivityGetRewards, secretTreasure.SercetItemRound)
      self:LogActivity(EBIType.ActivityRankUp, secretTreasure.SercetItemRound)
      secretTreasure.SercetItemRound = secretTreasure.SercetItemRound + 1
      local newSecretTreasure = self:GetSecretItemConfig(secretTreasure.SercetItemRound)
      secretTreasure.rewards = newSecretTreasure.rewards
      secretTreasure.reward_icon = newSecretTreasure.reward_icon
      secretTreasure.SecretMaxNum = newSecretTreasure.num
      secretTreasure.SecretNum = 0
      if secretTreasure.SercetItemRound == #self.m_roomSecretItemsConfig then
        isPassAll = true
      end
    end
    cur = secretTreasure.SecretNum
    tar = secretTreasure.SecretMaxNum
  else
    local normalTreasureMapInfo = self.m_curInfo.roomUnLockInfo.itemMapInfo
    if normalTreasureMapInfo[strTreareName] == nil then
      isfirstTime = true
      normalTreasureMapInfo[strTreareName] = 0
    end
    normalTreasureMapInfo[strTreareName] = normalTreasureMapInfo[strTreareName] + 1
    local curStage = self.m_curInfo.round
    local oldScore = self.m_curInfo.roomUnLockInfo.curScore
    local addScore = RoomModel.RoomItemToScore[strTreareName] or 0
    local newScore = self.m_curInfo.roomUnLockInfo.curScore + addScore
    self.m_curInfo.roomUnLockInfo.curScore = newScore
    local oldRound, startNum = self:GetRoundByStageScore(curStage, oldScore)
    local newRound = self:GetRoundByStageScore(curStage, newScore)
    local stageScoreRewards = self:GetStageConfig(curStage)
    GM.BIManager:LogAction(self.m_activityDefinition.BIGetScore, {
      round = self.m_curInfo.round,
      itemId = strTreareName,
      score = addScore,
      curScore = newScore,
      groupId = self:GetServerConfigGroupId()
    })
    for i = oldRound + 1, newRound do
      local curIndex = (i - startNum - 1) % #stageScoreRewards.ListRoundInfo + 1
      RewardApi.AcquireRewardsLogic({
        self:GetRoundConfigByStageRound(curStage, i).reward
      }, EPropertySource.Give, self.m_activityDefinition.BIGetReward, EGameMode.Main, CacheItemType.Type2)
      GM.BIManager:LogAction(self.m_activityDefinition.BIGetProgReward, {
        round = self.m_curInfo.round,
        index = i,
        finishRoundScore = stageScoreRewards.ListRoundInfo[curIndex].points,
        reward = self:GetRoundConfigByStageRound(curStage, i).reward,
        groupId = self:GetRoundConfigByStageRound(curStage, i).groupId
      })
    end
  end
  self:SaveActivityData()
  return rewards, isfirstTime, isSecret, isPassAll, cur, tar
end

function RoomModel:ExchangeReward()
  if self.m_expireReward ~= nil then
    return
  end
  local maxnum = 50
  local cnt = self:GetTokenNum()
  local rewards = {
    {
      [PROPERTY_TYPE] = EPropertyType.Energy,
      [PROPERTY_COUNT] = math.min(maxnum, cnt * 5)
    }
  }
  if cnt == 0 then
    rewards[1][PROPERTY_COUNT] = 0
  end
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, self.m_activityDefinition.BITRewardRecover, EGameMode.Main, CacheItemType.Type2)
  self.m_expireReward = rewards
  GM.BIManager:LogAction(self.m_activityDefinition.BITRewardRecover, {
    re = self.m_expireReward[1],
    cnt = self:GetTokenNum()
  })
  self:SaveExpireReward()
  self.m_dbTable:Remove(strDBKeys.activityToken)
  return rewards
end

function RoomModel:canShowHudEntry()
  if self:GetState() ~= ActivityState.Started and self:GetState() ~= ActivityState.Preparing then
    return false
  end
  return true
end

function RoomModel:canShowBoardEntry()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  return true
end

function RoomModel:GetHudEntryShowConfig()
  return {
    Type = "room",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.PassAllStateChanged
    },
    EntryPrefabConfigName = self.m_activityDefinition.HudEntryPrefabName,
    CheckFunc = function()
      return self:canShowHudEntry()
    end,
    HudSideBarType = EHudSideBarType.Left,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    OnClickedFunc = function()
      if self:GetState() == ActivityState.Preparing then
        GM.UIManager:OpenView(self.m_activityDefinition.NoticeWindowPrefabName, self:GetType(), false)
      elseif self:GetState() == ActivityState.Started then
        if self:GetCurInfo().roomState == 0 then
          GM.UIManager:OpenView(self.m_activityDefinition.LockPrefabName, self:GetType())
        else
          GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType())
        end
      end
    end,
    RedPointType = EntryRedPointType.Num,
    GetRedPointNumFunc = function()
      if self.m_curInfo == nil then
        return
      end
      if self.m_curInfo.roomState == 1 then
        return self:GetTokenNum()
      end
      return 0
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.TokenNumberChangedEvent
    }
  }
end

function RoomModel:GetScorllFunName()
  return "ScorllToRoomBubble" .. tostring(self.m_type)
end

function RoomModel:GetBoardEntryShowConfig()
  return {
    listeners = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.PassAllStateChanged
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_roomBoardBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_roomBoardCountNum",
    scrollToFunName = self:GetScorllFunName(),
    activityType = self:GetType(),
    checkFun = function()
      return self:canShowBoardEntry()
    end
  }
end

function RoomModel:GetSecretItemConfigs()
  return self.m_roomSecretItemsConfig
end

function RoomModel:GetEvent()
  return self.event
end

function RoomModel:GetCurInfo()
  return self.m_curInfo
end

function RoomModel:GetCurLevel()
  return self.m_curInfo.levelInfo.curLevel
end

function RoomModel:InitLevelInfo(level)
  self.m_curInfo.levelInfo = {
    curLevel = level,
    boxState = (1 << self.m_levelConfig[level].boxnum) - 1,
    remainItems = Table.DeepCopy(self.m_levelConfig[level].items)
  }
end

function RoomModel:GetCurBg()
  return self.m_levelConfig[self.m_curInfo.levelInfo.curLevel].background:sub(-1)
end

function RoomModel:CalcPro()
  local cfg = self.m_levelConfig[self.m_curInfo.levelInfo.curLevel]
  local times = cfg.boxnum - #self.m_curInfo.levelInfo.remainItems
  local PspR = cfg.draw[times]
  local PList = {}
  local wtSum = 0
  for _, items in ipairs(self.m_curInfo.levelInfo.remainItems) do
    local rewardName = items[PROPERTY_TYPE]
    if PList[rewardName] == nil then
      PList[rewardName] = 0
    end
    PList[rewardName] = PList[rewardName] + items.Weight
    wtSum = wtSum + items.Weight
  end
  local all = 10000 - PspR
  local minItem
  for rewardName, wt in pairs(PList) do
    PList[rewardName] = math.floor(wt / wtSum * (10000 - PspR) + 0.5)
    if rewardName ~= "empty" and (minItem == nil or PList[rewardName] < PList[minItem]) then
      minItem = rewardName
    end
    all = all - PList[rewardName]
  end
  if minItem ~= nil then
    PList[minItem] = PList[minItem] + all
  end
  local prolist = {}
  for rewardName, wt in pairs(PList) do
    table.insert(prolist, {item = rewardName, pro = wt})
  end
  table.sort(prolist, function(a, b)
    return a.pro > b.pro
  end)
  return PspR, prolist
end

function RoomModel:SetTestNextSecret(bFlag)
  self.m_nextGolden = bFlag
end

function RoomModel:OnTestNoGoldenPressed(bFlag)
  self.m_nextNoGolden = bFlag
end

function RoomModel:OnTestAllOpenEmpty(bFlag)
  self.m_allOpenEmpty = bFlag
end

function RoomModel:RandomReward(boxId, isNoSecret)
  self.m_curInfo.levelInfo.boxState = self.m_curInfo.levelInfo.boxState - (1 << boxId)
  local cfg = self.m_levelConfig[self.m_curInfo.levelInfo.curLevel]
  local times = cfg.boxnum - #self.m_curInfo.levelInfo.remainItems
  local PspR = cfg.draw[times]
  local rewardName = ""
  local bTestNextNoSecret = false
  if GameConfig.IsTestMode() and self.m_nextNoGolden == true and self.m_nextGolden ~= true then
    bTestNextNoSecret = true
    self.m_nextNoGolden = false
  end
  if GameConfig.IsTestMode() and self.m_allOpenEmpty == true and self.m_nextGolden ~= true then
    rewardName = "empty"
    return rewardName
  end
  local bTestNextSecret = false
  if GameConfig.IsTestMode() and self.m_nextGolden == true then
    bTestNextSecret = true
    self.m_nextGolden = false
  end
  if self.m_curInfo.levelInfo.curLevel == 1 and times == 1 then
    local wtSum = 0
    for _, items in ipairs(self.m_curInfo.levelInfo.remainItems) do
      if items[PROPERTY_TYPE] ~= "empty" then
        wtSum = wtSum + items.Weight
      end
    end
    local res = math.random(wtSum)
    for index, items in ipairs(self.m_curInfo.levelInfo.remainItems) do
      if items[PROPERTY_TYPE] ~= "empty" then
        if res <= items.Weight then
          rewardName = items[PROPERTY_TYPE]
          table.remove(self.m_curInfo.levelInfo.remainItems, index)
          break
        end
        res = res - items.Weight
      end
    end
  elseif not (not (PspR >= math.random(10000)) or isNoSecret or bTestNextNoSecret) or bTestNextSecret then
    rewardName = strSecretKey
  else
    local wtSum = 0
    for _, items in ipairs(self.m_curInfo.levelInfo.remainItems) do
      wtSum = wtSum + items.Weight
    end
    local res = math.random(wtSum)
    for index, items in ipairs(self.m_curInfo.levelInfo.remainItems) do
      if res <= items.Weight then
        rewardName = items[PROPERTY_TYPE]
        table.remove(self.m_curInfo.levelInfo.remainItems, index)
        break
      end
      res = res - items.Weight
    end
  end
  return rewardName
end

function RoomModel:OpenBox(boxId, levelId)
  local num = self:GetTokenNum()
  if num == 0 or self.m_curInfo.levelInfo.boxState & 1 << boxId == 0 or self.m_curInfo.levelInfo.curLevel ~= levelId then
    return
  end
  local offsetNum = -1
  self:SetTokenNum(num + offsetNum)
  local rewardName = self:RandomReward(boxId)
  local finialRewardList = {}
  if rewardName == strSecretKey then
    for i = 0, self.m_levelConfig[self.m_curInfo.levelInfo.curLevel].boxnum - 1 do
      if self.m_curInfo.levelInfo.boxState & 1 << i ~= 0 then
        local rewardEndItem = self:RandomReward(i, true)
        self:AcquireActivityTreasure(rewardEndItem)
        table.insert(finialRewardList, {boxId = i, itemName = rewardEndItem})
      end
    end
    if GameConfig.IsTestMode() then
      self.m_allOpenEmpty = false
    end
    if self.m_curInfo.levelInfo.curLevel == self.m_mxlevel then
      self:InitLevelInfo(self.m_mncyclic)
    else
      self:InitLevelInfo(self.m_curInfo.levelInfo.curLevel + 1)
    end
  end
  local rewards, isfirstTime, isSecret, isPassAll, cur, tar = self:AcquireActivityTreasure(rewardName)
  GM.BIManager:LogAction(self.m_activityDefinition.BIOpenBox, {
    id = boxId,
    reward = rewards,
    treasureName = rewardName,
    isSecret = string.find(rewardName, strSecretKey) and 1 or 0,
    level = self.m_curInfo.levelInfo.curLevel
  })
  return rewardName, rewards, isfirstTime, isSecret, isPassAll, cur, tar, finialRewardList, offsetNum
end

function RoomModel:GetNewViewController()
  self.m_conCnt = (self.m_conCnt or 0) + 1
  local viewController = RoomViewController.Create(self:GetType(), self.m_conCnt)
  self.m_conArr = self.m_conArr or {}
  self.m_conArr[self.m_conCnt] = viewController
  return viewController
end

function RoomModel:ViewControllerFinished(id)
  self.m_conArr[id] = nil
end

function RoomModel:HasViewController()
  return not Table.IsEmpty(self.m_conArr)
end

function RoomModel:GetActivityDefinition()
  return self.m_activityDefinition
end

function RoomModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function RoomModel:SetGameTutorial(bFlag)
  self.m_gameTutorial = bFlag
end

function RoomModel:IsGameTutorial()
  return self.m_gameTutorial
end
