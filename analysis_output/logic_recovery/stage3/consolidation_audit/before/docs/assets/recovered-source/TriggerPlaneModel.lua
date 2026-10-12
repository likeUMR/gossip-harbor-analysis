TriggerPlaneModel = setmetatable({}, BaseActivityModel)
TriggerPlaneModel.__index = TriggerPlaneModel
local TriggerPlaneConfigKey = {
  triggerPlaneConfig = "triggerPlaneConfig",
  triggerPlaneReward = "triggerPlaneReward",
  ItemGenerateScore = "ItemGenerateScore"
}
local DBKey = {
  Score = "score",
  Level = "level",
  RefreshTime = "refreshTime",
  EnergyConsumed = "energyConsumed",
  EndWindowOpened = "endWindowOpened",
  MainWindowDailyOpened = "mainWindowDailyOpened",
  LastShownScore = "lastShownScore",
  TimeLimit = "timeLimit",
  DailyStatus = "dailyStatus",
  IsMaxOut = "isMaxOut"
}
local MiscConfKey = {
  TriggerPlaneNewBoardEntry = "trigger_plane_icon"
}
TriggerPlaneDailyStatus = {
  NotActivated = 1,
  Activated = 2,
  TimeOut = 3,
  MaxOut = 4
}
local DBColumnValue = "value"
local ALL_DAY_SECONDS = 86400

function TriggerPlaneModel:Init(dbTable)
  BaseActivityModel.Init(self, ActivityType.TriggerPlane, dbTable)
  self:_LoadLocalConfig()
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
  EventDispatcher.AddListener(EEventType.EnergyChanged, self, self._OnEnergyChanged)
  self:SetLastShownScore(self:GetCurScore())
  self.m_bTestSkipAcquireReward = false
end

function TriggerPlaneModel:DailyResetData()
  self.m_dbTable:Set(DBKey.Score, DBColumnValue, 0)
  self.m_dbTable:Set(DBKey.Level, DBColumnValue, 0)
  self.m_dbTable:Set(DBKey.EnergyConsumed, DBColumnValue, 0)
  self.m_dbTable:Set(DBKey.MainWindowDailyOpened, DBColumnValue, false)
  self.m_dbTable:Set(DBKey.EndWindowOpened, DBColumnValue, false)
  self.m_dbTable:Set(DBKey.IsMaxOut, DBColumnValue, false)
  self:SetWindowReopen()
  self:SetDailyStatus(1)
  self:SetLastShownScore(0)
end

function TriggerPlaneModel:_LoadOtherServerConfig(config)
  self.m_triggerPlaneConfig = config[TriggerPlaneConfigKey.triggerPlaneConfig][1]
  self.m_triggerPlaneReward = config[TriggerPlaneConfigKey.triggerPlaneReward]
  table.sort(self.m_triggerPlaneReward, function(a, b)
    return a.round < b.round
  end)
  local miscConfigReader = MiscConfigReader.Create(config)
  self.m_currentBoardEntryNewType = miscConfigReader:GetInteger(MiscConfKey.TriggerPlaneNewBoardEntry)
end

function TriggerPlaneModel:_LoadLocalConfig()
  local config = require("Data.Config." .. TriggerPlaneConfigKey.ItemGenerateScore)
  self.m_ItemGenerateScoreConfig = {}
  for itemType, score in pairs(config) do
    local itemChain = GM.ItemDataModel:GetChainId(itemType)
    local level = GM.ItemDataModel:GetChainLevel(itemType)
    if itemChain and level then
      self.m_ItemGenerateScoreConfig[itemChain] = {Level = level, BaseScore = score}
    end
  end
end

function TriggerPlaneModel:IsTriggerPlaneBoardEntryNewType()
  if self.m_bBoardEntryNewType == nil then
    self.m_bBoardEntryNewType = self.m_currentBoardEntryNewType == 1
  end
  return self.m_bBoardEntryNewType
end

function TriggerPlaneModel:GetSmallIconEntryShowConfig()
  return {
    HudButtonKey = ESceneViewHudButtonKey.TriggerPlane,
    prefab = UIPrefabConfigName.TriggerPlaneBoardEntryNew,
    listener = {
      EEventType.TriggerPlaneStateChanged,
      EEventType.TriggerPlaneDailyStatusChanged
    },
    checkfunc = function()
      if self:GetState() == ActivityState.Started and self:GetDailyStatus() == TriggerPlaneDailyStatus.Activated then
        return true
      else
        return false
      end
    end
  }
end

function TriggerPlaneModel:GetBoardEntryShowConfig()
  if self:IsTriggerPlaneBoardEntryNewType() then
    return Table.Empty
  end
  return {
    listeners = {
      EEventType.TriggerPlaneStateChanged,
      EEventType.TriggerPlaneDailyStatusChanged
    },
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_TriggerPlaneBubbleNode",
    entryPrefabName = UIPrefabConfigName.TriggerPlaneBoardEntry,
    getBubbleFunName = "GetTriggerPlaneBubble",
    bubbleCountName = "m_TriggerPlaneBubbleCount",
    activityType = self:GetType(),
    checkFun = function()
      if self:GetState() == ActivityState.Started and self:GetDailyStatus() == TriggerPlaneDailyStatus.Activated then
        return true
      else
        return false
      end
    end
  }
end

function TriggerPlaneModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self.m_triggerPlaneConfig == nil or self.m_triggerPlaneReward == nil or self.m_ItemGenerateScoreConfig == nil then
    return
  end
  local timeSatisfied = self:CheckTime()
  local isMaxOut = self:GetIsMaxOut()
  if timeSatisfied and self:CheckEnergy() and self:CheckRemainEnergy() and self:CheckBuyEnergyGemCost() and not isMaxOut then
    if self:GetDailyStatus() ~= TriggerPlaneDailyStatus.Activated then
      self:SetTimeLimit(GM.GameModel:GetServerTime() + self.m_triggerPlaneConfig.duration * 60)
      self:SetDailyStatus(TriggerPlaneDailyStatus.Activated)
    end
  elseif self:GetDailyStatus() == TriggerPlaneDailyStatus.Activated then
    if isMaxOut then
      self:SetDailyStatus(TriggerPlaneDailyStatus.MaxOut)
    elseif not timeSatisfied then
      self:SetDailyStatus(TriggerPlaneDailyStatus.TimeOut)
    end
  end
end

function TriggerPlaneModel:CheckTime()
  local curTime = GM.GameModel:GetServerTime()
  local refreshTime = self:GetRefreshTime()
  local timeNeeded = self.m_triggerPlaneConfig.duration * 60
  if curTime > refreshTime then
    refreshTime = TimeUtil.ToCur24ClockTimestamp(curTime)
    self:SetRefreshTime(refreshTime)
    self:DailyResetData()
  end
  if refreshTime > curTime + ALL_DAY_SECONDS then
    refreshTime = TimeUtil.ToCur24ClockTimestamp(curTime)
    self:SetRefreshTime(refreshTime)
    self:DailyResetData()
  end
  if self:GetDailyStatus() == TriggerPlaneDailyStatus.NotActivated then
    local condition1 = timeNeeded <= refreshTime - curTime
    local condition2 = timeNeeded <= self.m_config.eTime - curTime
    return condition1 and condition2
  elseif self:GetDailyStatus() == TriggerPlaneDailyStatus.Activated then
    return self:GetTimeLimit() - curTime > 0
  else
    return false
  end
end

function TriggerPlaneModel:CheckEnergy()
  local energyConsumed = self:GetEnergyConsumed()
  local energyNeeded = self.m_triggerPlaneConfig.energy
  return energyConsumed >= energyNeeded
end

function TriggerPlaneModel:CheckRemainEnergy()
  local remainEnergy = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy)
  return self.m_triggerPlaneConfig.trigger_energy and remainEnergy <= self.m_triggerPlaneConfig.trigger_energy
end

function TriggerPlaneModel:CheckBuyEnergyGemCost()
  local buyEnergyGemCost = GM.ShopModel:GetEnergyCostExcludeFree()
  return self.m_triggerPlaneConfig.trigger_gem and buyEnergyGemCost >= self.m_triggerPlaneConfig.trigger_gem
end

function TriggerPlaneModel:AddScore(score, newItem)
  self:LogActivity(EBIType.ActivityAddScore, score)
  local preScore = self.m_dbTable:GetValue(DBKey.Score, DBColumnValue) or 0
  local curScore = preScore + score
  if curScore > self:GetScoreRange(3).lowerBound then
    curScore = self:GetScoreRange(3).lowerBound
    score = curScore - preScore
  end
  local levelInfo = self:GetLevelInfo(curScore)
  self.m_dbTable:Set(DBKey.Score, DBColumnValue, curScore)
  self.m_dbTable:Set(DBKey.Level, DBColumnValue, levelInfo.curLevel)
  local message = {NewItem = newItem, Score = score}
  EventDispatcher.DispatchEvent(EEventType.TriggerPlaneScoreChanged, message)
  if levelInfo.levelUp then
    self:LogActivity(EBIType.ActivityRankUp, levelInfo.curLevel)
    self:LogActivity(EBIType.ActivityGetRewards, levelInfo.curLevel)
    EventDispatcher.DispatchEvent(EEventType.TriggerPlaneUpgraded, levelInfo.curLevel)
    self:AcquireRewards(levelInfo.curLevel)
  end
  if levelInfo.maxOut then
    self:SetIsMaxOut(true)
    self:SetDailyStatus(TriggerPlaneDailyStatus.MaxOut)
  end
end

function TriggerPlaneModel:AcquireRewards(level)
  if GameConfig.IsTestMode() and self.m_bTestSkipAcquireReward then
    return
  end
  local curReward = self.m_triggerPlaneReward[level].reward
  RewardApi.AcquireRewardsLogic(curReward, EPropertySource.Give, EBIType.TriggerPlaneReward, EGameMode.Main, CacheItemType.Type2)
end

function TriggerPlaneModel:GetLevelInfo(curScore)
  local preLevel = self.m_dbTable:GetValue(DBKey.Level, DBColumnValue) or 0
  local curLevel = -1
  local maxOut = false
  for _, tuple in pairs(self.m_triggerPlaneReward) do
    if curScore < tuple.tokens then
      curLevel = tuple.round - 1
      break
    end
  end
  if curLevel == -1 then
    curLevel = #self.m_triggerPlaneReward
    maxOut = true
  end
  return {
    curLevel = curLevel,
    levelUp = preLevel < curLevel,
    maxOut = maxOut
  }
end

function TriggerPlaneModel:GetScoreRange(level)
  if level < 0 then
    return
  end
  local upperBound = 0
  local lowerBound = 0
  for _, tuple in pairs(self.m_triggerPlaneReward) do
    if level < tuple.round then
      upperBound = tuple.tokens
      break
    else
      lowerBound = tuple.tokens
    end
  end
  return {upperBound = upperBound, lowerBound = lowerBound}
end

function TriggerPlaneModel:GetResourceLabels()
  return {
    AddressableLabel.TriggerPlane
  }
end

function TriggerPlaneModel:GetLevelReward(level)
  if level < 0 then
    return
  end
  if level == #self.m_triggerPlaneReward then
    level = level - 1
  end
  return self.m_triggerPlaneReward[level + 1].reward
end

function TriggerPlaneModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_lastShownScore = nil
end

function TriggerPlaneModel:SetRefreshTime(time)
  self.m_dbTable:Set(DBKey.RefreshTime, "value", time)
end

function TriggerPlaneModel:GetRefreshTime()
  return self.m_dbTable:GetValue(DBKey.RefreshTime, "value") or 0
end

function TriggerPlaneModel:SetEnergyConsumed(energy)
  self.m_dbTable:Set(DBKey.EnergyConsumed, "value", energy)
end

function TriggerPlaneModel:GetEnergyConsumed()
  return self.m_dbTable:GetValue(DBKey.EnergyConsumed, "value") or 0
end

function TriggerPlaneModel:GetCurScore()
  return self.m_dbTable:GetValue(DBKey.Score, "value") or 0
end

function TriggerPlaneModel:GetCurLevel()
  return self.m_dbTable:GetValue(DBKey.Level, "value") or 0
end

function TriggerPlaneModel:GetServerConfigGroupId()
  return self.m_triggerPlaneConfig.groupId
end

function TriggerPlaneModel:GetEndWindowOpened()
  return self.m_dbTable:GetValue(DBKey.EndWindowOpened, "value") or false
end

function TriggerPlaneModel:SetEndWindowOpened(status)
  self.m_dbTable:Set(DBKey.EndWindowOpened, "value", status)
end

function TriggerPlaneModel:GetLastShownScore()
  return self.m_lastShownScore or 0
end

function TriggerPlaneModel:SetLastShownScore(value)
  self.m_lastShownScore = value
end

function TriggerPlaneModel:GetTimeLimit()
  return self.m_dbTable:GetValue(DBKey.TimeLimit, "value") or 0
end

function TriggerPlaneModel:SetTimeLimit(value)
  self.m_dbTable:Set(DBKey.TimeLimit, "value", value)
end

function TriggerPlaneModel:GetDailyStatus()
  return self.m_dbTable:GetValue(DBKey.DailyStatus, "value") or 1
end

function TriggerPlaneModel:SetDailyStatus(value)
  self.m_dbTable:Set(DBKey.DailyStatus, "value", value)
  EventDispatcher.DispatchEvent(EEventType.TriggerPlaneDailyStatusChanged)
end

function TriggerPlaneModel:GetPlaneRewardArray()
  local array = {}
  for _, v in ipairs(self.m_triggerPlaneReward) do
    table.insert(array, v.reward[PROPERTY_TYPE])
  end
  return array
end

function TriggerPlaneModel:GetMainWindowOpened()
  return self.m_dbTable:GetValue(DBKey.MainWindowDailyOpened, "value") or false
end

function TriggerPlaneModel:SetMainWindowOpened(status)
  self.m_dbTable:Set(DBKey.MainWindowDailyOpened, "value", true)
end

function TriggerPlaneModel:GetIsMaxOut()
  return self.m_dbTable:GetValue(DBKey.IsMaxOut, "value") or false
end

function TriggerPlaneModel:SetIsMaxOut(status)
  self.m_dbTable:Set(DBKey.IsMaxOut, "value", status)
end

function TriggerPlaneModel:_OnItemSpread(message)
  if self:GetDailyStatus() ~= TriggerPlaneDailyStatus.Activated or self:GetState() ~= ActivityState.Started then
    return
  end
  if not message.CostEnergy then
    return
  end
  local itemType = message.New:GetType()
  local itemChain = GM.ItemDataModel:GetChainId(itemType)
  local config = self.m_ItemGenerateScoreConfig[itemChain]
  if config == nil then
    return
  end
  local level = GM.ItemDataModel:GetChainLevel(itemType)
  if level < config.Level then
    return
  end
  local score = config.BaseScore * 2 ^ (level - config.Level)
  score = math.floor(score + 0.5)
  self:AddScore(score, message.New)
end

function TriggerPlaneModel:_OnEnergyChanged(info)
  local preEnergy = info.prevEnergy
  local curEnergy = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy)
  local useEnergy = preEnergy - curEnergy
  if 0 < useEnergy then
    self:SetEnergyConsumed(self:GetEnergyConsumed() + useEnergy)
  end
end

function TriggerPlaneModel:_OnStateChanged()
  if self:GetState(false) ~= ActivityState.Started then
    self:DailyResetData()
  end
  EventDispatcher.DispatchEvent(EEventType.TriggerPlaneStateChanged)
end

function TriggerPlaneModel:GetNotificationDelay()
  if self:GetDailyStatus() ~= TriggerPlaneDailyStatus.Activated then
    return 0
  end
  return self:GetTimeLimit() - GM.GameModel:GetServerTime() - 3600
end

function TriggerPlaneModel:GetTestInfo()
  if self:GetState() ~= ActivityState.Started then
    local info = "\229\174\140\229\133\168\230\178\161\229\188\128\229\167\139\n" .. self:GetState()
    return info
  end
  local energyConsumed = self:GetEnergyConsumed()
  local energyNeeded = self.m_triggerPlaneConfig.energy
  local timeLeft = self:GetRefreshTime() - GM.GameModel:GetServerTime()
  local timeNeeded = self.m_triggerPlaneConfig.duration * 60
  local info = "\230\182\136\232\128\151\228\189\147\229\138\155: " .. energyConsumed .. "/" .. energyNeeded .. ", " .. tostring(energyConsumed >= energyNeeded) .. "\n" .. "\230\151\182\233\151\180: " .. TimeUtil.ParseTimeDescription(timeLeft, 2, false, false) .. "/" .. TimeUtil.ParseTimeDescription(timeNeeded, 2, false, false) .. ", " .. tostring(timeLeft >= timeNeeded) .. "\n" .. "\230\152\175\229\144\166\230\187\161\231\186\167: " .. tostring(self:GetIsMaxOut()) .. "\n" .. "\230\175\143\230\151\165\231\138\182\230\128\129: " .. self:GetDailyStatus() .. "\n" .. "\230\180\187\229\138\168\231\138\182\230\128\129: " .. self:GetState() .. "\n" .. "\229\137\169\228\189\153\228\189\147\229\138\155: " .. GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy) .. "\n" .. "\228\189\147\229\138\155\232\180\173\228\185\176\228\187\183\230\160\188: " .. GM.ShopModel:GetEnergyCostExcludeFree() .. "\n" .. "\230\191\128\230\180\187\230\157\161\228\187\182\239\188\154\232\131\189\233\135\143true\239\188\140\230\151\182\233\151\180true\239\188\140\230\187\161\231\186\167false\239\188\140\230\175\143\230\151\1652\239\188\140\230\180\187\229\138\1682,\229\137\169\228\189\153\228\189\147\229\138\155" .. tostring(self.m_triggerPlaneConfig.trigger_energy) .. "\239\188\140\228\189\147\229\138\155\232\180\173\228\185\176\228\187\183\230\160\188" .. tostring(self.m_triggerPlaneConfig.trigger_gem)
  return info
end

function TriggerPlaneModel:GetTestPopupWindowConfig()
  return {
    CheckFunc = function()
      return true
    end,
    config = {
      GroupName = "\232\167\166\229\143\145\229\188\143\233\163\158\230\156\186\230\180\187\229\138\168(TriggerPlane)",
      WindowList = {
        {
          BtnName = "\228\184\187\231\149\140\233\157\162",
          BtnClickFunc = function()
            GM.UIManager:OpenView(UIPrefabConfigName.TriggerPlaneMainWindow, false)
          end
        },
        {
          BtnName = "\231\187\147\230\157\159",
          BtnClickFunc = function()
            GM.UIManager:OpenView(UIPrefabConfigName.TriggerPlaneEndWindow)
          end
        }
      }
    }
  }
end

function TriggerPlaneModel:ScoreMultiply50()
  if not GameConfig.IsTestMode() then
    return
  end
  for chain, config in pairs(self.m_ItemGenerateScoreConfig) do
    local tempScore = self.m_ItemGenerateScoreConfig[chain].BaseScore
    if tempScore < 10 then
      self.m_ItemGenerateScoreConfig[chain].BaseScore = tempScore * 50
    end
  end
end

function TriggerPlaneModel:ResetData()
  self:DailyResetData()
end

function TriggerPlaneModel:TestSwitchAcquireReward()
  self.m_bTestSkipAcquireReward = not self.m_bTestSkipAcquireReward
end
