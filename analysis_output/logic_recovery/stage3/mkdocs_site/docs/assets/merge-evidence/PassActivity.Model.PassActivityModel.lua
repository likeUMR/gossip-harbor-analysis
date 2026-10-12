PassActivityEventType = {StateChanged = 1}
PassActivityTicketState = {
  None = 0,
  Normal = 1,
  Super = 2
}
PassActivityBuyTicketScene = {
  EnergyWindow = "EnergyWnd",
  BuyTicketPopupWindow = "BuyTicketPopupWindow",
  ActivityWindow = "ActivityWnd"
}
PassActivityModel = setmetatable({AllowRestoreOnEnd = true}, BaseActivityModel)
PassActivityModel.__index = PassActivityModel
PassActivityModel.TimelimitTaskOrderKey = "TimelimitTaskOrder"
PassActivityModel.TimelimitTaskFinishedCountKey = "TimelimitTaskFinishedCount%d"
PassActivityModel.TimelimitTaskFinishedKey = "TimelimitTaskFinished%d"
PassActivityModel.BonusTaskIndexKey = "BonusTaskIndex"
PassActivityModel.BonusTaskPreviewedKey = "BonusTaskPreviewed"
PassActivityModel.CycleTaskFinishedCountKey = "CycleTaskFinishedCount"
PassActivityModel.TokenNumberKey = "TokenNumber"
PassActivityModel.TicketStateKey = "TicketState"
PassActivityModel.TicketRewardStateKey = "TicketRewardState"
PassActivityModel.UnlimitedRewardUnlockedTokenNumberKey = "UnlimitedRewardUnlockedTokenNumber"
PassActivityModel.UnlimitedRewardTakenLevelKey = "UnlimitedRewardTakenLevel"
PassActivityModel.RewardTakenKey = "RewardTaken%d_%d"
PassActivityModel.FinishedLevelKey = "FinishedLevel"
PassActivityModel.LastBuyTicketPopupWindowDayKey = "LastBuyTicketPopupWindowDay"
PassActivityModel.BuyTicketPopupWindowOpenedStateEndedKey = "BuyTicketPopupWindowOpenedStateEnded"
PassActivityModel.RewardEffectKey = "RewardEffect%d_%d"
PassActivityModel.ProgressEffectKey = "ProgressEffect_%d"
PassActivityModel.TicketBonusRewardTakenKey = "TicketBonusRewardTaken"
PassActivityModel.DailyTaskRewardsKey = "DailyTaskRewards"
PassActivityModel.LastDailyTaskFinished = "LastDailyTaskFinished"
PassActivityModel.CycleTaskCount = 100
PassActivityModel.CycleTaskReward = 100
PassActivityModel.BattleScoreOrderId = 0

function PassActivityModel:Init(activityType, virtualDBTable)
  self.m_activityDefinition = PassActivityDefinition[activityType]
  BaseActivityModel.Init(self, activityType, virtualDBTable)
  if self.m_activityDefinition.IapTypeSet == 0 then
    self.m_ticketIapType = EIAPType.shoppingpassticket
    self.m_superTicketIapType = EIAPType.battlepassticket_super
    self.m_upgradeTicketIapType = EIAPType.battlepassticket_upgrade
  elseif self.m_activityDefinition.IapTypeSet == 2 then
    self.m_ticketIapType = EIAPType.shoppingpassticket_2
    self.m_superTicketIapType = EIAPType.battlepassticket_super_2
    self.m_upgradeTicketIapType = EIAPType.battlepassticket_upgrade_2
  else
    self.m_ticketIapType = EIAPType.shoppingpassticket_1
    self.m_superTicketIapType = EIAPType.battlepassticket_super_1
    self.m_upgradeTicketIapType = EIAPType.battlepassticket_upgrade_1
  end
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
  EventDispatcher.AddListener(EEventType.GoldScoreAcquired, self, self._OnGoldScoreAcquired)
  EventDispatcher.AddListener(EEventType.PropertyConsumed, self, self._OnPropertyConsumed)
end

function PassActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function PassActivityModel:_LoadOtherServerConfig(config)
  self.m_levelTokenSum = 0
  self.m_config.levelConfigs = {}
  for _, lConfig in ipairs(config.battlePassReward) do
    self.m_levelTokenSum = self.m_levelTokenSum + lConfig.require
    local item = {
      require = lConfig.require,
      rewards = ConfigUtil.GetCurrencyFromArrStr(lConfig.reward),
      vipRewards = ConfigUtil.GetCurrencyFromArrStr(lConfig.golden_reward)
    }
    self.m_config.levelConfigs[lConfig.level] = item
  end
  self.m_config.timelimitTasks = {}
  local taskConfig = {}
  if not Table.IsEmpty(config.battlePassMoreTask) then
    taskConfig = Table.DeepCopy(config.battlePassMoreTask)
  else
    taskConfig = Table.DeepCopy(config.battlePassDailyTask)
  end
  for _, tConfig in ipairs(taskConfig) do
    local tasks = {}
    local index = 1
    while self:_TryAddTask(tasks, tConfig, "task" .. index, false) do
      index = index + 1
    end
    if not Table.IsEmpty(config.battlePassMoreTask) then
      self:_TryAddTask(tasks, tConfig, "spTask1", true)
      self:_TryAddTask(tasks, tConfig, "spTask2", true)
    end
    local reward = tConfig.reward_1
    local taskSet = {
      time = tConfig.order,
      tasks = tasks,
      extraReward = reward
    }
    self.m_config.timelimitTasks[tConfig.order] = taskSet
  end
  local reader = MiscConfigReader.Create(config)
  local svipFreeToken = reader:GetInteger("bp_svip_token_free")
  if svipFreeToken ~= nil then
    self.m_config.superTicketConfig = {
      FreeToken = svipFreeToken,
      MultipleFactor = reader:GetNumber("bp_svip_token_multiple")
    }
    self.m_config.superTicketConfig.UnlimitedRewardConfig = config.battlePassExtraReward
    table.sort(self.m_config.superTicketConfig.UnlimitedRewardConfig, function(a, b)
      return a.id < b.id
    end)
  end
  local type = reader:GetString("bp_task") == "new" and "energy" or "merge"
  self.m_config.cycleTask = PassActivityTask.Create(PassActivityTaskType.Cycle, false, 1, type, PassActivityModel.CycleTaskCount, PassActivityModel.CycleTaskReward)
  self.m_config.vipExtraBonus = reader:GetReward("extra_bonus")
  if GameConfig.IsTestMode() and self.m_config.vipExtraBonus ~= nil and self.m_config.vipExtraBonus[1] ~= nil and self.m_config.vipExtraBonus[1][PROPERTY_TYPE] ~= EPropertyType.Energy then
    Log.Error("[BP]VIP\232\180\173\228\185\176\233\162\157\229\164\150\229\165\150\229\138\177\231\177\187\229\158\139\228\184\141\230\152\175\232\131\189\233\135\143\239\188\140\232\191\157\232\131\140\228\186\134\228\184\154\230\172\163\229\144\140\229\173\166\229\156\1682024\229\185\1807\230\156\13629\230\151\165\232\175\180\231\154\132\229\143\170\233\133\141\232\131\189\233\135\143\231\154\132\232\167\132\229\136\153")
  end
end

function PassActivityModel:_TryAddTask(taskList, taskConfig, key, isBonus)
  local taskString = taskConfig[key]
  if taskString == nil then
    return false
  end
  local parts = StringUtil.Split(taskString, "-")
  local task = PassActivityTask.Create(PassActivityTaskType.Timelimit, isBonus, #taskList + 1, parts[1], tonumber(parts[2]), tonumber(parts[3]))
  table.insert(taskList, task)
  return true
end

function PassActivityModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:GetState() == ActivityState.Started then
    self:_UpdateShouldRefreshTimelimitTasks()
  end
end

function PassActivityModel:_OnStateChanged()
  if self:GetState() == ActivityState.Started and self.m_dbTable:GetValue(PassActivityModel.CycleTaskFinishedCountKey, "value") == nil then
    self.m_dbTable:Set(PassActivityModel.CycleTaskFinishedCountKey, "value", 0)
    self:RefreshTimelimitTasks()
  end
  if self:GetState() ~= ActivityState.Released then
    local currentTokenLevel = self:GetCurrentLevel()
    EventDispatcher.DispatchEvent(EEventType.PassActivityLevelUp, {
      num = currentTokenLevel,
      atype = self:GetType()
    })
  end
  self.event:Call(PassActivityEventType.StateChanged)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
end

function PassActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function PassActivityModel:GetBoardEntryShowConfig()
  return {
    statusChangeName = self.m_activityDefinition.StateChangedEvent,
    bubbleName = "m_" .. self.m_type .. "Bubble",
    bubbleNodeName = "m_passActivityBubbleNode",
    entryPrefabName = self.m_activityDefinition.BoardEntryPrefabName,
    bubbleCountName = "m_passActivityBubbleCount",
    activityType = self:GetType(),
    checkFun = function()
      return self:GetState() == ActivityState.Started
    end
  }
end

function PassActivityModel:GetHudEntryShowConfig()
  return {
    Type = "passActivity",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent
    },
    EntryPrefabConfigName = UIPrefabConfigName.HudActivityEntry,
    CheckFunc = function()
      return self:GetState() == ActivityState.Started
    end,
    HudSideBarType = EHudSideBarType.Right,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = self.m_activityDefinition.EntryIconName,
    OnClickedFunc = function()
      if not self:HasDailyReward() then
        GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType(), true)
      else
        GM.UIManager:OpenView(self.m_activityDefinition.MainWindowNewPrefabName, self:GetType(), true)
      end
    end,
    RedPointType = EntryRedPointType.Num,
    GetRedPointNumFunc = function()
      return self:GetCanFinishTaskTimes() + #self:GetCanTakeRewards()
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.CanFinishTaskTimesChangedEvent,
      self.m_activityDefinition.CanTakeRewardNumberChangedEvent
    }
  }
end

function PassActivityModel:GetLevelConfigs()
  return self.m_config.levelConfigs
end

function PassActivityModel:GetSuperTicketConfig()
  return self.m_config.superTicketConfig
end

function PassActivityModel:CanOpenBuyTicketPopupWindow()
  if self:GetTicketState() ~= PassActivityTicketState.None then
    return false
  end
  if self:GetState() == ActivityState.Started then
    local tokenLevel = self:GetCurrentLevel()
    if tokenLevel ~= #self.m_config.levelConfigs then
      return false
    end
    local lastDay = self.m_dbTable:GetValue(PassActivityModel.LastBuyTicketPopupWindowDayKey, "value") or 0
    local currentDay = (GM.GameModel:GetServerTime() - self.m_config.sTime) // 86400
    return lastDay < currentDay
  elseif self:GetState() == ActivityState.Ended then
    return self.m_dbTable:GetValue(PassActivityModel.BuyTicketPopupWindowOpenedStateEndedKey, "value") ~= 1
  end
  return false
end

function PassActivityModel:SetBuyTicketPopupWindowOpened()
  if self:GetState() == ActivityState.Started then
    local day = (GM.GameModel:GetServerTime() - self.m_config.sTime) // 86400
    self.m_dbTable:Set(PassActivityModel.LastBuyTicketPopupWindowDayKey, "value", day)
  else
    self.m_dbTable:Set(PassActivityModel.BuyTicketPopupWindowOpenedStateEndedKey, "value", 1)
  end
end

function PassActivityModel:_OnItemMerged(message)
  self:_OnTaskTargetReached(message.New:GetCode(), 1)
  self:_OnTaskTargetReached("merge", 1)
end

function PassActivityModel:_OnOrderFinished(message)
  self:_OnTaskTargetReached("customer", 1)
end

function PassActivityModel:_OnGoldScoreAcquired(message)
  self:_OnTaskTargetReached("gold", message.count)
end

function PassActivityModel:_OnPropertyConsumed(message)
  if message.property[PROPERTY_TYPE] == EPropertyType.Gem then
    self:_OnTaskTargetReached("gem", message.property[PROPERTY_COUNT])
  elseif message.property[PROPERTY_TYPE] == EPropertyType.Energy then
    self:_OnTaskTargetReached("energy", message.ext.origin)
  end
end

function PassActivityModel:_OnTaskTargetReached(target, count)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self:GetTicketState() ~= PassActivityTicketState.Super and self:GetCurrentLevel() == #self.m_config.levelConfigs then
    return
  end
  local tasks = self:GetActiveTasks()
  for _, task in ipairs(tasks) do
    if task.Target == target then
      self:_AddFinishedCount(task, count)
    end
  end
end

function PassActivityModel:_UpdateShouldRefreshTimelimitTasks()
  local shouldRefresh = GM.GameModel:GetServerTime() >= self:GetTaskRefreshTime()
  if shouldRefresh and self:GetTicketState() ~= PassActivityTicketState.Super then
    local currentTokenLevel = self:GetCurrentLevel()
    if currentTokenLevel == #self.m_config.levelConfigs then
      shouldRefresh = false
    end
  end
  if not self.m_shouldRefreshTimelimitTasks and shouldRefresh then
    self.m_shouldRefreshTimelimitTasks = true
    EventDispatcher.DispatchEvent(self.m_activityDefinition.ShouldRefreshTimelimitTasksEvent)
  end
end

function PassActivityModel:ShouldRefreshTimelimitTasks()
  return self.m_shouldRefreshTimelimitTasks
end

function PassActivityModel:TestFinishNextTask()
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local tasks = self.m_config.timelimitTasks[timelimitTaskOrder].tasks
  for _, task in ipairs(tasks) do
    local finishedCountKey = self:_GetFinishedCountKey(task.Type, task.Index)
    local currentCount = self.m_dbTable:GetValue(finishedCountKey, "value")
    if currentCount ~= task.Count then
      self:_AddFinishedCount(task, task.Count)
      break
    end
  end
end

function PassActivityModel:TestFinishAllTask()
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local tasks = self.m_config.timelimitTasks[timelimitTaskOrder].tasks
  for _, task in ipairs(tasks) do
    self:_AddFinishedCount(task, task.Count)
  end
end

function PassActivityModel:GetActiveTasks()
  local activeTasks = {}
  
  local function tryAppendTimelimitTask(task)
    local finishedKey = string.format(PassActivityModel.TimelimitTaskFinishedKey, task.Index)
    if self.m_dbTable:GetValue(finishedKey, "value") ~= 1 then
      table.insert(activeTasks, task)
    end
  end
  
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local tasks = self.m_config.timelimitTasks[timelimitTaskOrder].tasks
  for _, task in ipairs(tasks) do
    if not task.IsBonus then
      tryAppendTimelimitTask(task)
    end
  end
  local bonusTaskIndex = self:_GetBonusTaskIndex()
  if bonusTaskIndex ~= nil then
    tryAppendTimelimitTask(tasks[bonusTaskIndex])
  end
  table.insert(activeTasks, self.m_config.cycleTask)
  return activeTasks
end

function PassActivityModel:GetFinishedCount(task)
  local finishedCountKey = self:_GetFinishedCountKey(task.Type, task.Index)
  return self.m_dbTable:GetValue(finishedCountKey, "value")
end

function PassActivityModel:_AddFinishedCount(task, count)
  local finishedCountKey = self:_GetFinishedCountKey(task.Type, task.Index)
  local currentCount = self.m_dbTable:GetValue(finishedCountKey, "value")
  if currentCount == task.Count and task.Type == PassActivityTaskType.Timelimit then
    return
  end
  local lastTimes = currentCount // task.Count
  currentCount = currentCount + count
  if task.Type == PassActivityTaskType.Timelimit then
    currentCount = math.min(currentCount, task.Count)
  end
  self.m_dbTable:Set(finishedCountKey, "value", currentCount)
  local currentTimes = currentCount // task.Count
  if lastTimes ~= currentTimes then
    EventDispatcher.DispatchEvent(self.m_activityDefinition.TaskProgressChangedEvent, {Task = task})
    EventDispatcher.DispatchEvent(self.m_activityDefinition.CanFinishTaskTimesChangedEvent)
  end
end

function PassActivityModel:GetTaskRefreshTime()
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local taskSet = self.m_config.timelimitTasks[timelimitTaskOrder]
  return self.m_config.sTime + taskSet.time * 86400
end

function PassActivityModel:SupportBonusTask()
  local tasks = self.m_config.timelimitTasks[1].tasks
  for _, task in ipairs(tasks) do
    if task.IsBonus then
      return true
    end
  end
  return false
end

function PassActivityModel:SetBattleScoreOrder()
  PassActivityModel.BattleScoreOrderId = PassActivityModel.BattleScoreOrderId + 1
  self.m_aquireRewardOrderId = PassActivityModel.BattleScoreOrderId
end

function PassActivityModel:GetBattleScoreOrder()
  return self.m_aquireRewardOrderId
end

function PassActivityModel:_GetBonusTaskIndex()
  return self.m_dbTable:GetValue(PassActivityModel.BonusTaskIndexKey, "value")
end

function PassActivityModel:IsBonusTaskPreviewed()
  return self.m_dbTable:GetValue(PassActivityModel.BonusTaskPreviewedKey, "value") == 1
end

function PassActivityModel:SetBonusTaskPreviewed()
  self.m_dbTable:Set(PassActivityModel.BonusTaskPreviewedKey, "value", 1)
end

function PassActivityModel:GetCanFinishTasks()
  local canFinishTasks = {}
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local tasks = self.m_config.timelimitTasks[timelimitTaskOrder].tasks
  for index = 1, #tasks do
    local finishedKey = string.format(PassActivityModel.TimelimitTaskFinishedKey, index)
    if self.m_dbTable:GetValue(finishedKey, "value") ~= 1 then
      local task = tasks[index]
      if self:GetFinishedCount(task) == task.Count then
        table.insert(canFinishTasks, task)
      end
    end
  end
  local task = self.m_config.cycleTask
  if self:GetFinishedCount(task) >= task.Count then
    table.insert(canFinishTasks, task)
  end
  return canFinishTasks
end

function PassActivityModel:GetCanFinishTaskTimes()
  local number = 0
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local tasks = self.m_config.timelimitTasks[timelimitTaskOrder].tasks
  for index = 1, #tasks do
    local finishedKey = string.format(PassActivityModel.TimelimitTaskFinishedKey, index)
    if self.m_dbTable:GetValue(finishedKey, "value") ~= 1 then
      local task = tasks[index]
      if self:GetFinishedCount(task) == task.Count then
        number = number + 1
      end
    end
  end
  local task = self.m_config.cycleTask
  local finishedCount = self:GetFinishedCount(task)
  number = number + finishedCount // task.Count
  return number
end

function PassActivityModel:HasDailyReward()
  if self.m_config == nil then
    return false
  end
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local taskSetConfig = self.m_config.timelimitTasks[timelimitTaskOrder]
  return not Table.IsEmpty(taskSetConfig.extraReward)
end

function PassActivityModel:GetCurrentFinishedLimitTaskProgress()
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local taskSetConfig = self.m_config.timelimitTasks[timelimitTaskOrder]
  if Table.IsEmpty(taskSetConfig.extraReward) then
    return nil
  end
  local num = 0
  for index = 1, #taskSetConfig.tasks do
    local finishedKey = string.format(PassActivityModel.TimelimitTaskFinishedKey, index)
    if self.m_dbTable:GetValue(finishedKey, "value") == 1 then
      num = num + 1
    end
  end
  return num, #taskSetConfig.tasks
end

function PassActivityModel:FinishTasks(tasks)
  for _, task in ipairs(tasks) do
    if task.Type == PassActivityTaskType.Timelimit then
      self:_FinishTaskOnce(task)
    else
      local finishedCount = self:GetFinishedCount(task)
      for i = 1, finishedCount // task.Count do
        self:_FinishTaskOnce(task)
      end
    end
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.CanFinishTaskTimesChangedEvent)
end

function PassActivityModel:_FinishTaskOnce(task)
  local taskId
  if task.Type == PassActivityTaskType.Timelimit then
    local finishedKey = string.format(PassActivityModel.TimelimitTaskFinishedKey, task.Index)
    local isNewFinish = self.m_dbTable:GetValue(finishedKey, "value") ~= 1
    self.m_dbTable:Set(finishedKey, "value", 1)
    local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
    taskId = timelimitTaskOrder .. "_" .. task.Index
    local tasknum, tasktarget = self:GetCurrentFinishedLimitTaskProgress()
    if tasknum ~= nil and isNewFinish then
      GM.BIManager:LogAction(self.m_activityDefinition.AddDailyTaskScoreBIType, {
        activityType = self.m_type,
        activityId = self:GetId(),
        taskDay = timelimitTaskOrder,
        taskIndex = task.Index,
        addScore = 1,
        taskScore = tasknum
      })
    end
    if tasknum ~= nil and tasknum == tasktarget then
      self:SaveDailyReward()
      GM.BIManager:LogAction(self.m_activityDefinition.FinishDailyTaskBIType, {
        activityType = self.m_type,
        activityId = self:GetId(),
        taskDay = timelimitTaskOrder
      })
    end
    if task.Index == 11 and task.IsBonus then
      GM.BIManager:LogAction(self.m_activityDefinition.FinishSpTask2BIType, {
        activityType = self.m_type,
        activityId = self:GetId(),
        taskDay = timelimitTaskOrder
      })
    end
    self:_RefreshBonusTask()
  else
    local finishedCount = self:GetFinishedCount(task)
    finishedCount = finishedCount - task.Count
    self.m_dbTable:Set(PassActivityModel.CycleTaskFinishedCountKey, "value", finishedCount)
    taskId = tostring(task.Index)
  end
  self:_AcquireToken(task.Reward, true)
  GM.BIManager:LogPassActivityTask(taskId, task)
end

function PassActivityModel:SaveDailyReward()
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local taskSetConfig = self.m_config.timelimitTasks[timelimitTaskOrder]
  local savedDailyRewards = json.decode(self.m_dbTable:GetValue(PassActivityModel.DailyTaskRewardsKey, "value") or "") or {}
  savedDailyRewards = RewardApi.MergeRewards(savedDailyRewards, {
    taskSetConfig.extraReward
  })
  self.m_dbTable:Set(PassActivityModel.DailyTaskRewardsKey, "value", json.encode(savedDailyRewards))
end

function PassActivityModel:GetSavedDailyRewards()
  local savedDailyRewards = json.decode(self.m_dbTable:GetValue(PassActivityModel.DailyTaskRewardsKey, "value") or "") or {}
  return savedDailyRewards
end

function PassActivityModel:AquireSavedDailyRewards(onlyLogic)
  local savedDailyRewards = json.decode(self.m_dbTable:GetValue(PassActivityModel.DailyTaskRewardsKey, "value") or "") or {}
  local temp = Table.DeepCopy(savedDailyRewards)
  self:SetBattleScoreOrder()
  RewardApi.AcquireRewardsLogic(temp, EPropertySource.Give, self.m_activityDefinition.TakeDailyTaskRewardBIType, EGameMode.Main, CacheItemType.Type2)
  if not onlyLogic then
    local rewardWindowArgs = {
      arrRewards = temp,
      playRewardAnim = true,
      highlightHudArgs = {duration = 3}
    }
    GM.UIManager:OpenView(UIPrefabConfigName.RewardWindow, rewardWindowArgs)
  end
  self.m_dbTable:Remove(PassActivityModel.DailyTaskRewardsKey, "value")
end

function PassActivityModel:RefreshTimelimitTasks()
  local maxValidOrder = 0
  local serverTime = GM.GameModel:GetServerTime()
  for order, taskSet in ipairs(self.m_config.timelimitTasks) do
    local startTime = self.m_config.sTime + (taskSet.time - 1) * 86400
    if serverTime >= startTime then
      maxValidOrder = order
    end
  end
  self.m_dbTable:Set(PassActivityModel.LastDailyTaskFinished, "value", 0)
  local newTasks = self.m_config.timelimitTasks[maxValidOrder].tasks
  self.m_dbTable:Set(PassActivityModel.TimelimitTaskOrderKey, "value", maxValidOrder)
  for index = 1, #newTasks do
    local finishedCountKey = string.format(PassActivityModel.TimelimitTaskFinishedCountKey, index)
    self.m_dbTable:Set(finishedCountKey, "value", 0)
    local finishedKey = string.format(PassActivityModel.TimelimitTaskFinishedKey, index)
    self.m_dbTable:Set(finishedKey, "value", 0)
  end
  self.m_dbTable:Set(PassActivityModel.BonusTaskIndexKey, "value", nil)
  self.m_shouldRefreshTimelimitTasks = false
  EventDispatcher.DispatchEvent(self.m_activityDefinition.RefreshDailyTasksEvent)
  return newTasks
end

function PassActivityModel:GetLastFinished()
  return self.m_dbTable:GetValue(PassActivityModel.LastDailyTaskFinished, "value") or 0
end

function PassActivityModel:SetLastFinished(num)
  return self.m_dbTable:Set(PassActivityModel.LastDailyTaskFinished, "value", num)
end

function PassActivityModel:GetDailyReward()
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local taskSetConfig = self.m_config.timelimitTasks[timelimitTaskOrder]
  return taskSetConfig.extraReward
end

function PassActivityModel:IsLastTimelimitTaskGroup()
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  return timelimitTaskOrder == #self.m_config.timelimitTasks
end

function PassActivityModel:_RefreshBonusTask()
  local activeTasks = self:GetActiveTasks()
  
  local function filter(task)
    return task.Type == PassActivityTaskType.Timelimit
  end
  
  local timelimitTasks = Table.ListSelect(activeTasks, filter)
  if #timelimitTasks ~= 0 then
    return
  end
  local timelimitTaskOrder = self.m_dbTable:GetValue(PassActivityModel.TimelimitTaskOrderKey, "value")
  local tasks = self.m_config.timelimitTasks[timelimitTaskOrder].tasks
  local bonusTaskIndex = self:_GetBonusTaskIndex()
  for _, task in ipairs(tasks) do
    if task.IsBonus and (bonusTaskIndex == nil or bonusTaskIndex < task.Index) then
      self.m_dbTable:Set(PassActivityModel.BonusTaskIndexKey, "value", task.Index)
      self.m_dbTable:Set(PassActivityModel.BonusTaskPreviewedKey, "value", 0)
      break
    end
  end
end

function PassActivityModel:_GetFinishedCountKey(type, index)
  if type == PassActivityTaskType.Timelimit then
    return string.format(PassActivityModel.TimelimitTaskFinishedCountKey, index)
  else
    return PassActivityModel.CycleTaskFinishedCountKey
  end
end

function PassActivityModel:GetTokenNumber()
  return self.m_dbTable:GetValue(PassActivityModel.TokenNumberKey, "value") or 0
end

function PassActivityModel:_AcquireToken(count, useMultipleFactor)
  if useMultipleFactor and self:GetTicketState() == PassActivityTicketState.Super then
    count = math.ceil(count * self.m_config.superTicketConfig.MultipleFactor)
  end
  local tokenNumber = self:GetTokenNumber()
  self.m_dbTable:Set(PassActivityModel.TokenNumberKey, "value", tokenNumber + count)
  self:LogActivity(EBIType.ActivityAddScore, count)
  local finishedLevel = self.m_dbTable:GetValue(PassActivityModel.FinishedLevelKey, "value") or 1
  local currentTokenLevel = self:GetCurrentLevel()
  if finishedLevel < currentTokenLevel then
    self:LogActivity(EBIType.ActivityRankUp, currentTokenLevel)
    EventDispatcher.DispatchEvent(self.m_activityDefinition.CanTakeRewardNumberChangedEvent)
    EventDispatcher.DispatchEvent(EEventType.PassActivityLevelUp, {
      num = currentTokenLevel,
      atype = self:GetType()
    })
  end
  self.m_dbTable:Set(PassActivityModel.FinishedLevelKey, "value", currentTokenLevel)
end

function PassActivityModel:GetCurrentLevel(tokenNumber)
  local tokenNumber = tokenNumber or self:GetTokenNumber()
  local tokenLevel = 0
  for level, config in ipairs(self.m_config.levelConfigs) do
    if tokenNumber >= config.require then
      tokenLevel = level
      tokenNumber = tokenNumber - config.require
    else
      break
    end
  end
  return tokenLevel, tokenNumber
end

function PassActivityModel:GetTicketState()
  return self.m_dbTable:GetValue(PassActivityModel.TicketStateKey, "value") or PassActivityTicketState.None
end

function PassActivityModel:GetTicketRewardState()
  if self.m_config.superTicketConfig == nil then
    return self:GetTicketState()
  end
  return self.m_dbTable:GetValue(PassActivityModel.TicketRewardStateKey, "value") or PassActivityTicketState.None
end

function PassActivityModel:BuyTicket(iapType, openScene)
  local targetTicketState = self:_GetTargetTicketState(iapType)
  if self:GetTicketState() == targetTicketState then
    GM.BIManager:LogErrorInfo(EBIType.BPTicketRebuy, "")
    self:_OnBuyTicketSuccess(iapType, targetTicketState, openScene, false)
    return
  end
  GM.BIManager:LogAction(self.m_activityDefinition.BuyTicketStartedBIType, {openScene = openScene})
  
  local function purchaseCallback()
    self:_OnBuyTicketSuccess(iapType, targetTicketState, openScene, false)
  end
  
  GM.InAppPurchaseModel:StartPurchase(iapType, purchaseCallback, EBIType.ShopBuy)
end

function PassActivityModel:RestoreIapRewards(iapType)
  if self:GetTicketState() == PassActivityTicketState.Super then
    return false
  end
  local targetTicketState = self:_GetTargetTicketState(iapType)
  if targetTicketState ~= nil then
    self:_OnBuyTicketSuccess(iapType, targetTicketState, nil, true)
    return true
  end
  return false
end

function PassActivityModel:_OnBuyTicketSuccess(iapType, targetTicketState, openScene, restore)
  self.m_dbTable:Set(PassActivityModel.TicketStateKey, "value", targetTicketState)
  if targetTicketState == PassActivityTicketState.Super then
    local tokenNumber = self:GetTokenNumber()
    local unlimitedRewardUnlockedTokenNumber = math.max(tokenNumber, self.m_levelTokenSum)
    self.m_dbTable:Set(PassActivityModel.UnlimitedRewardUnlockedTokenNumberKey, "value", unlimitedRewardUnlockedTokenNumber)
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.CanTakeRewardNumberChangedEvent)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.BuyTicketSuccessEvent)
  local price = GM.InAppPurchaseModel:GetLocalizedPrice(iapType)
  local action = {price = price}
  if openScene then
    action.openScene = openScene
  end
  GM.BIManager:LogAction(self.m_activityDefinition.BuyTicketSuccessBIType, action)
end

function PassActivityModel:_GetTargetTicketState(iapType)
  if iapType == self.m_ticketIapType then
    return PassActivityTicketState.Normal
  elseif iapType == self.m_superTicketIapType or iapType == self.m_upgradeTicketIapType then
    return PassActivityTicketState.Super
  else
    return nil
  end
end

function PassActivityModel:GetCanTakeRewards()
  local rewards = {}
  local currentTokenLevel = self:GetCurrentLevel()
  local hasTicket = self:GetTicketState() ~= PassActivityTicketState.None
  for level, config in ipairs(self.m_config.levelConfigs) do
    if level > currentTokenLevel then
      break
    end
    if not self:IsRewardTaken(level, false) then
      table.insert(rewards, {
        Level = level,
        IsVip = false,
        Rewards = config.rewards
      })
    end
    if hasTicket and not self:IsRewardTaken(level, true) then
      table.insert(rewards, {
        Level = level,
        IsVip = true,
        Rewards = config.vipRewards
      })
    end
  end
  return rewards
end

function PassActivityModel:IsRewardTaken(level, isVip)
  local rewardTakenKey = string.format(PassActivityModel.RewardTakenKey, level, isVip and 1 or 0)
  return self.m_dbTable:GetValue(rewardTakenKey, "value") == 1
end

function PassActivityModel:TakeReward(level, isVip, rewards)
  local scene = self.m_state == ActivityState.Started and self.m_activityDefinition.TakeRewardBIType or self.m_activityDefinition.TakeRewardOnEndBIType
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Buy, scene, EGameMode.Main, CacheItemType.Type2)
  local rewardTakenKey = string.format(PassActivityModel.RewardTakenKey, level, isVip and 1 or 0)
  self.m_dbTable:Set(rewardTakenKey, "value", 1)
  local action = {
    level = level,
    vip = isVip and 1 or 0
  }
  local actionString = GM.BIManager:TableToString(action)
  self:LogActivity(EBIType.ActivityGetRewards, actionString)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.CanTakeRewardNumberChangedEvent)
end

function PassActivityModel:TakeTicketReward()
  local ticketState = self:GetTicketState()
  if ticketState == PassActivityTicketState.Super then
    self:_AcquireToken(self.m_config.superTicketConfig.FreeToken, false)
  end
  self.m_dbTable:Set(PassActivityModel.TicketRewardStateKey, "value", ticketState)
end

function PassActivityModel:GetTicketBonusReward()
  return self.m_config.vipExtraBonus
end

function PassActivityModel:HasTicketBonusRewardTaken()
  return self.m_dbTable:GetValue(PassActivityModel.TicketBonusRewardTakenKey, "value") == 1
end

function PassActivityModel:CanTakeTicketBonusReward()
  return self:GetTicketState() ~= PassActivityTicketState.None and not self:HasTicketBonusRewardTaken() and self:GetTicketBonusReward() ~= nil
end

function PassActivityModel:TakeTicketBonusReward()
  if self:CanTakeTicketBonusReward() then
    local scene = self.m_state == ActivityState.Started and self.m_activityDefinition.TakeRewardBIType or self.m_activityDefinition.TakeRewardOnEndBIType
    RewardApi.AcquireRewardsLogic(self:GetTicketBonusReward(), EPropertySource.Buy, scene, EGameMode.Main, CacheItemType.Type2)
    self.m_dbTable:Set(PassActivityModel.TicketBonusRewardTakenKey, "value", 1)
    return self:GetTicketBonusReward()
  end
  return nil
end

function PassActivityModel:GetTicketIapType()
  return self.m_ticketIapType
end

function PassActivityModel:GetSuperTicketIapType()
  return self.m_superTicketIapType
end

function PassActivityModel:GetUpgradeTicketIapType()
  return self.m_upgradeTicketIapType
end

function PassActivityModel:GetUnlimitedRewardConfig(level)
  level = (level - 1) % #self.m_config.superTicketConfig.UnlimitedRewardConfig + 1
  return self.m_config.superTicketConfig.UnlimitedRewardConfig[level]
end

function PassActivityModel:GetUnlimitedRewardLevel(number)
  local unlimitedRewardUnlockedTokenNumber = self.m_dbTable:GetValue(PassActivityModel.UnlimitedRewardUnlockedTokenNumberKey, "value")
  if unlimitedRewardUnlockedTokenNumber == nil then
    return 0, 0
  end
  local tokenNumber = (number or self:GetTokenNumber()) - unlimitedRewardUnlockedTokenNumber
  if tokenNumber < 0 then
    return 0, 0
  end
  local level = 0
  while true do
    local config = self:GetUnlimitedRewardConfig(level + 1)
    if tokenNumber >= config.require then
      level = level + 1
      tokenNumber = tokenNumber - config.require
    else
      break
    end
  end
  return level, tokenNumber
end

function PassActivityModel:GetCanTakeUnlimitedRewards(number)
  local rewards = {}
  local takenLevel = self:_GetUnlimitedRewardTakenLevel()
  local level = self:GetUnlimitedRewardLevel(number)
  for l = takenLevel + 1, level do
    local config = self:GetUnlimitedRewardConfig(l)
    table.insert(rewards, {
      Level = l,
      Rewards = config.reward
    })
  end
  return rewards
end

function PassActivityModel:TakeUnlimitedRewards(level, rewards)
  local scene = self.m_state == ActivityState.Started and self.m_activityDefinition.TakeUnlimitedRewardBIType or self.m_activityDefinition.TakeUnlimitedRewardOnEndBIType
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Buy, scene, EGameMode.Main, CacheItemType.Type2)
  local action = {
    rewardLevel = level,
    currentLevel = self:GetUnlimitedRewardLevel()
  }
  GM.BIManager:LogAction(scene, action)
  local takenLevel = self:_GetUnlimitedRewardTakenLevel()
  if level > takenLevel then
    self.m_dbTable:Set(PassActivityModel.UnlimitedRewardTakenLevelKey, "value", level)
  end
end

function PassActivityModel:_GetUnlimitedRewardTakenLevel()
  return self.m_dbTable:GetValue(PassActivityModel.UnlimitedRewardTakenLevelKey, "value") or 0
end

function PassActivityModel:HasShownRewardEffect(level, isVip)
  local rewardEffectKey = string.format(PassActivityModel.RewardEffectKey, level, isVip and 1 or 0)
  return self.m_dbTable:GetValue(rewardEffectKey, "value") == 1
end

function PassActivityModel:SetShownRewardEffect(level, isVip)
  local rewardEffectKey = string.format(PassActivityModel.RewardEffectKey, level, isVip and 1 or 0)
  self.m_dbTable:Set(rewardEffectKey, "value", 1)
end

function PassActivityModel:HasShownProgressEffect(level)
  local progressEffectKey = string.format(PassActivityModel.ProgressEffectKey, level)
  return self.m_dbTable:GetValue(progressEffectKey, "value") == 1
end

function PassActivityModel:SetShownProgressEffect(level)
  local progressEffectKey = string.format(PassActivityModel.ProgressEffectKey, level)
  self.m_dbTable:Set(progressEffectKey, "value", 1)
end

function PassActivityModel:GetMissionProgress()
  return self:GetCurrentLevel()
end

function PassActivityModel:GetActivityDefinition()
  return self.m_activityDefinition
end
