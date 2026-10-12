GeneratorBoostActivityModel = setmetatable({}, BaseActivityModel)
GeneratorBoostActivityModel.__index = GeneratorBoostActivityModel
local DBKeys = {
  CurProgress = "CurProgress",
  LastShowProgress = "LastShowProgress",
  ActiveBuffLevel = "ActiveBuffLevel",
  FirstPopMainWindow = "FirstPopMainWindow",
  ExtraProduceTotalSpreadCount = "ExtraProduceTotalSpreadCount",
  ExtraProduceLeftSpreadCount = "ExtraProduceLeftSpreadCount",
  ExtraProduceCached = "ExtraProduceCached",
  ExtraLuckyProduceCached = "ExtraLuckyProduceCached",
  LastGeneratorBoostLuckyConfig = "LastGeneratorBoostLuckyConfig",
  RefreshTime = "RefreshTime",
  RoundNum = "RoundNum"
}
EGeneratorBoostBuffType = {
  NoCD = "nocd",
  SmartProduce = "smartProduce",
  ExtraProduce = "extraProduce",
  MoreLuckyProduce = "moreLuckyProduce",
  ExtraLuckyProduce = "extraLuckyProduce"
}

function GeneratorBoostActivityModel:Init(activityType, activityDataTable)
  self.m_activityType = activityType
  self.m_activityDefinition = GeneratorBoostActivityDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
end

function GeneratorBoostActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
  local itemModelConfig = self:GetItemModelConfig()
  if itemModelConfig then
    self:ReloadItemModelConfig()
  end
  local luckyProduceConfig = self:GetLuckyProduceConfig()
  if luckyProduceConfig then
    self:ReloadLuckyProduceConfig()
  end
end

function GeneratorBoostActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function GeneratorBoostActivityModel:_LoadOtherServerConfig(config)
  self.m_taskConfig = config.generatorBoostTask
  table.sort(self.m_taskConfig, function(a, b)
    return a.index < b.index
  end)
  self.m_buffConfig = config.generatorBoostBuff
  table.sort(self.m_buffConfig, function(a, b)
    return a.index < b.index
  end)
  for _, buff in ipairs(self.m_buffConfig) do
    if buff.buffType == EGeneratorBoostBuffType.ExtraProduce then
      self.m_extraProduceChance = buff.param
    end
  end
  self.m_curProgress = json.decode(self.m_dbTable:GetValue(DBKeys.CurProgress, "value") or "") or {
    0,
    0,
    0,
    0
  }
  self.m_lastShowProgress = json.decode(self.m_dbTable:GetValue(DBKeys.LastShowProgress, "value") or "") or {
    0,
    0,
    0,
    0
  }
  if self:GetRefreshTime() == nil then
    self:SetRefreshTime()
  end
end

function GeneratorBoostActivityModel:GetServerConfigGroupId()
  return self.m_taskConfig and self.m_taskConfig[1].groupId
end

function GeneratorBoostActivityModel:_DropData()
  self:ClearBuff()
  BaseActivityModel._DropData(self)
  self.m_lastShowProgress = {
    0,
    0,
    0,
    0
  }
  self.m_curProgress = {
    0,
    0,
    0,
    0
  }
  self.m_configChangedItemTypeMap = nil
  self:SetActiveSpread(false)
end

function GeneratorBoostActivityModel:_OnStateChanged()
  local checkResState = self:GetState()
  local notCheckResState = self:GetState(false)
  if checkResState == ActivityState.Started then
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.TaskEventProgressGain, self)
  elseif checkResState == ActivityState.Ended or checkResState == ActivityState.Released then
    GM.ActivityModuleManager:RemoveRegister(ActivityModuleManager.ModuleType.TaskEventProgressGain, self)
  end
  if notCheckResState == ActivityState.Ended or notCheckResState == ActivityState.Released then
    self:ClearBuff()
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
end

function GeneratorBoostActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function GeneratorBoostActivityModel:SetWindowOpened()
  if self.m_state == ActivityState.Started and not self:HasWindowOpenedOnce(self.m_state) then
    self:LogActivity(EBIType.ActivityStarted, "")
    GM.BIManager:LogAction(self.m_activityDefinition.BIStartRound, {
      r = self:GetRoundNum(),
      g = self:GetServerConfigGroupId()
    })
  end
  local key = "windowOpened" .. self.m_state
  self.m_dbTable:Set(key, "value", 1)
end

function GeneratorBoostActivityModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  local curTime = GM.GameModel:GetServerTime()
  if curTime >= self:GetRefreshTime() then
    self:ClearState()
    self:SetRefreshTime()
    EventDispatcher.DispatchEvent(self.m_activityDefinition.RefreshEvent)
    self:SetFirstPopMainWindow(false)
    self:SetPopMainWindow(true)
    self:AddRoundNum()
  end
end

function GeneratorBoostActivityModel:_OnProgressGain(message)
  if message.operation ~= TaskEventProgressGainModule.TaskOper.Add then
    return
  end
  local finishedCount = self:GetFinishedTaskCount()
  for _, task in ipairs(self.m_taskConfig) do
    if task.taskType == message.type then
      local continue = false
      if message.type == TaskEventType.OrderFinish and message.order ~= nil and message.order.GetInnerType and message.order:GetInnerType() == MainOrderType.Special then
        continue = true
      end
      local curValue = self.m_curProgress[task.index] or 0
      if curValue >= task.num then
        continue = true
      end
      if not continue then
        curValue = math.min(curValue + message.num, task.num)
        self.m_curProgress[task.index] = curValue
        self:SetCurProgress()
        if curValue == task.num then
          local biAction = {
            index = task.index,
            type = task.taskType,
            num = finishedCount + 1,
            round = self:GetRoundNum(),
            g = self:GetServerConfigGroupId()
          }
          GM.BIManager:LogAction(self.m_activityDefinition.BIFinishTask, biAction)
          EventDispatcher.DispatchEvent(self.m_activityDefinition.TaskFinishedEvent)
          if 1 <= finishedCount then
            self:BuffLevelUp()
          end
        end
      end
    end
  end
end

function GeneratorBoostActivityModel:GetFinishedTaskCount()
  local count = 0
  for _, task in ipairs(self.m_taskConfig) do
    if self.m_curProgress[task.index] == task.num then
      count = count + 1
    end
  end
  return count
end

function GeneratorBoostActivityModel:CanActiveSpread()
  return self.m_activeSpread
end

function GeneratorBoostActivityModel:SetActiveSpread(bActive)
  self.m_activeSpread = bActive
end

function GeneratorBoostActivityModel:BuffLevelUp()
  local curLevel = self:GetBuffLevel()
  local nextLevel = curLevel + 1
  if self.m_buffConfig[nextLevel] then
    self.m_dbTable:Set(DBKeys.ActiveBuffLevel, "value", nextLevel)
    local biAction = {
      index = self.m_buffConfig[nextLevel].index,
      type = self.m_buffConfig[nextLevel].buffType,
      round = self:GetRoundNum(),
      g = self:GetServerConfigGroupId()
    }
    GM.BIManager:LogAction(self.m_activityDefinition.BIActiveBuff, biAction)
    if self.m_buffConfig[nextLevel].buffType == EGeneratorBoostBuffType.MoreLuckyProduce or self.m_buffConfig[nextLevel].buffType == EGeneratorBoostBuffType.ExtraLuckyProduce then
      self:ReloadLuckyProduceConfig()
      self:ReloadItemModelConfig()
    elseif self.m_buffConfig[nextLevel].buffType == EGeneratorBoostBuffType.ExtraProduce then
      self:ReloadItemModelConfig()
    elseif self.m_buffConfig[nextLevel].buffType == EGeneratorBoostBuffType.NoCD then
      EventDispatcher.DispatchEvent(EEventType.GeneratorBoostBuffActiveLogic)
    end
  end
  self:SetPopMainWindow(true)
  self:SetActiveSpread(true)
end

function GeneratorBoostActivityModel:IsBuffActive(Type)
  if self:GetState(false) ~= ActivityState.Started then
    return false
  end
  local buffLevel = self:GetBuffLevel()
  if buffLevel <= 0 then
    return false
  end
  for level = 1, buffLevel do
    local buffConfig = self.m_buffConfig[level]
    if buffConfig.buffType == Type then
      return true
    end
  end
end

function GeneratorBoostActivityModel:GetActivedBuffString()
  if self.m_buffConfig ~= nil then
    local buffLevel = self:GetBuffLevel()
    if buffLevel <= 0 then
      return nil
    end
    local str = ""
    for i = 1, buffLevel do
      local buffConfig = self.m_buffConfig[i]
      if buffConfig ~= nil then
        if 1 < i then
          str = str .. ","
        end
        str = str .. buffConfig.buffType
      end
    end
    return str
  end
end

function GeneratorBoostActivityModel:IsNoCDActive()
  return self:IsBuffActive(EGeneratorBoostBuffType.NoCD)
end

function GeneratorBoostActivityModel:IsCurrentLevelNoCDBuff()
  local buffLevel = self:GetBuffLevel()
  if buffLevel <= 0 then
    return false
  end
  local buffConfig = self.m_buffConfig[buffLevel]
  if buffConfig.buffType == EGeneratorBoostBuffType.NoCD then
    return true
  end
  return false
end

function GeneratorBoostActivityModel:ReloadItemModelConfig()
  local itemModelConfig = self:GetItemModelConfig()
  if itemModelConfig ~= nil then
    self.m_configChangedItemTypeMap = {}
    for _, config in ipairs(itemModelConfig) do
      self.m_configChangedItemTypeMap[config.Type] = true
    end
  end
  GM.ItemDataModel:ReloadFileConfig(itemModelConfig)
end

function GeneratorBoostActivityModel:GetConfigChangedItemType()
  return self.m_configChangedItemTypeMap
end

function GeneratorBoostActivityModel:GetItemModelConfig()
  local config = GM.ConfigModel:GetLocalConfig(LocalConfigKey.GeneratorBoostItemModel)
  if self:IsBuffActive(EGeneratorBoostBuffType.MoreLuckyProduce) then
    return config.MoreLuckyProduce
  elseif self:IsBuffActive(EGeneratorBoostBuffType.ExtraLuckyProduce) then
    return config.ExtraLuckyProduce
  elseif self:IsBuffActive(EGeneratorBoostBuffType.ExtraProduce) then
    return config.ExtraProduce
  end
end

function GeneratorBoostActivityModel:ReloadLuckyProduceConfig()
  local luckyProduceModel = GM.ActivityManager:GetModel(ActivityType.LuckyProduce)
  if luckyProduceModel == nil or luckyProduceModel:GetState(true) ~= ActivityState.Started then
    return
  end
  local config = self:GetLuckyProduceConfig()
  local isLastConfigGenerator = self:IsLastGeneratorBoostLuckyConfig()
  local isCurrentConfigGenerator = config ~= nil
  local bUpdate = isLastConfigGenerator ~= isCurrentConfigGenerator
  self:SetLastGeneratorBoostLuckyConfig(isCurrentConfigGenerator)
  luckyProduceModel:ReloadFileConfig(config, bUpdate)
end

function GeneratorBoostActivityModel:GetLuckyProduceConfig()
  local config = GM.ConfigModel:GetLocalConfig(LocalConfigKey.GeneratorBoostLuckyProduce)
  if self:IsBuffActive(EGeneratorBoostBuffType.MoreLuckyProduce) then
    return config.MoreLuckyProduce
  elseif self:IsBuffActive(EGeneratorBoostBuffType.ExtraLuckyProduce) then
    return config.ExtraLuckyProduce
  end
end

local LastProduceLuckyItemInfo

function GeneratorBoostActivityModel:_OnItemSpread(message)
  local itemSpread = message.Source:GetComponent(ItemSpread)
  if itemSpread and itemSpread:CanSupportGeneratorBoost() then
    if message.BoardSpreadType == BoardSpreadType.GeneratorBoostExtraNormal or message.BoardSpreadType == BoardSpreadType.GeneratorBoostExtraSmart then
      self:_ExtraProduceItemSpread(message)
    elseif message.BoardSpreadType == BoardSpreadType.Lucky or message.BoardSpreadType == BoardSpreadType.SuperLucky or message.BoardSpreadType == BoardSpreadType.FreeLucky or message.BoardSpreadType == BoardSpreadType.FreeSuperLucky then
      if GameConfig.IsTestMode() then
        LastProduceLuckyItemInfo = message.New:GetType()
      end
      self:TryExtraLuckyProduceItem(message)
    end
  end
end

function GeneratorBoostActivityModel:TryExtraProduceItem(sourceItem)
  if not self:IsBuffActive(EGeneratorBoostBuffType.ExtraProduce) or self.m_extraProduceChance == nil then
    return nil
  end
  if self:IsCachedExtraProduce() then
    return self:_ExtraProduceItem(sourceItem, true)
  end
  if self:_CanExtraProduceItem() or GameConfig.IsTestMode() and self:IsTestMustExtraProduce() then
    return self:_ExtraProduceItem(sourceItem, false)
  end
end

function GeneratorBoostActivityModel:_ExtraProduceItem(sourceItem, bCached)
  local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrderWithNum(sourceItem:GetPosition(), nil, 2, true)
  if targetPos and 2 <= #targetPos then
    if bCached then
      self:RemoveExtraProduceCache()
    end
    return true
  else
    if not bCached then
      self:CacheExtraProduce()
    end
    if GameConfig.IsTestMode() then
      Log.Info("[\230\175\141\228\189\147\230\163\139\229\173\144\229\138\169\229\138\155]\232\167\166\229\143\145\229\143\140\229\128\141\229\150\183\229\143\145 \230\163\139\231\155\152\230\178\161\231\169\186\228\186\134\239\188\140\231\188\147\229\173\152\232\181\183\230\157\165")
    end
    return false
  end
end

function GeneratorBoostActivityModel:_ExtraProduceItemSpread(message)
  local newType = message.New:GetType()
  local targetPos
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ItemLandOpt) then
    targetPos = GM.MainBoardModel:FindEmptySpreadPosition(newType, message.Source:GetPosition())
  else
    targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrder(message.Source:GetPosition())
  end
  if targetPos then
    local args = {
      logSpread = true,
      energyBoostRatio = message.EnergyBoostRatio,
      costEnergy = false,
      spreadType = BoardSpreadType.GeneratorBoostExtra
    }
    GM.MainBoardModel:SpreadItem(message.Source, targetPos, newType, args)
    if GameConfig.IsTestMode() then
      Log.Info("[\230\175\141\228\189\147\230\163\139\229\173\144\229\138\169\229\138\155]\232\167\166\229\143\145\229\143\140\229\128\141\229\150\183\229\143\145\239\188\154" .. newType)
    end
  end
end

function GeneratorBoostActivityModel:_CanExtraProduceItem()
  local totalCount = self.m_dbTable:GetValue(DBKeys.ExtraProduceTotalSpreadCount, "value") or 0
  local leftCount = self.m_dbTable:GetValue(DBKeys.ExtraProduceLeftSpreadCount, "value") or 0
  if totalCount == 0 then
    totalCount = self.m_extraProduceChance[1]
    leftCount = self.m_extraProduceChance[2]
    self:SetExtraProduceLeftSpreadCount(leftCount)
  end
  local index = MathUtil.Random(totalCount)
  totalCount = totalCount - 1
  self:SetExtraProduceTotalSpreadCount(totalCount)
  if leftCount < index then
    return false
  end
  leftCount = leftCount - 1
  self:SetExtraProduceLeftSpreadCount(leftCount)
  return true
end

function GeneratorBoostActivityModel:SetExtraProduceLeftSpreadCount(count)
  self.m_dbTable:Set(DBKeys.ExtraProduceLeftSpreadCount, "value", count)
end

function GeneratorBoostActivityModel:SetExtraProduceTotalSpreadCount(count)
  self.m_dbTable:Set(DBKeys.ExtraProduceTotalSpreadCount, "value", count)
end

function GeneratorBoostActivityModel:CacheExtraProduce()
  self.m_dbTable:Set(DBKeys.ExtraProduceCached, "value", "1")
end

function GeneratorBoostActivityModel:IsCachedExtraProduce()
  return self.m_dbTable:GetValue(DBKeys.ExtraProduceCached, "value") == "1"
end

function GeneratorBoostActivityModel:RemoveExtraProduceCache()
  self.m_dbTable:Remove(DBKeys.ExtraProduceCached)
end

function GeneratorBoostActivityModel:TryExtraLuckyProduceItem(message)
  if not self:IsBuffActive(EGeneratorBoostBuffType.ExtraLuckyProduce) then
    return nil
  end
  local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrder(message.Source:GetPosition())
  if targetPos then
    local args = {
      logSpread = true,
      energyBoostRatio = message.EnergyBoostRatio,
      costEnergy = false,
      spreadType = BoardSpreadType.GeneratorBoostExtraLucky
    }
    GM.MainBoardModel:SpreadItem(message.Source, targetPos, message.New:GetType(), args)
    if GameConfig.IsTestMode() then
      Log.Info("[\230\175\141\228\189\147\230\163\139\229\173\144\229\138\169\229\138\155]\232\167\166\229\143\145\229\143\140\229\128\141\229\185\184\232\191\144\229\150\183\229\143\145")
    end
  end
end

function GeneratorBoostActivityModel:HaveAndCanExtraLuckyProduce(bCached)
  if not self:IsBuffActive(EGeneratorBoostBuffType.ExtraLuckyProduce) then
    return false, false
  end
  local boarNewPos = BoardPosition.Create(1, 1)
  local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrderWithNum(boarNewPos, nil, 2, true)
  local bCan = targetPos and 2 <= #targetPos
  local bHave = false
  if bCached then
    if self:IsCachedExtraLuckyProduce() then
      bHave = true
      if bCan then
        self:RemoveExtraLuckyProduceCache()
      end
    end
    return bHave, bCan
  elseif not bCan then
    self:CacheExtraLuckyProduce()
  end
  bHave = true
  return bHave, bCan
end

function GeneratorBoostActivityModel:CacheExtraLuckyProduce()
  self.m_dbTable:Set(DBKeys.ExtraLuckyProduceCached, "value", "1")
end

function GeneratorBoostActivityModel:IsCachedExtraLuckyProduce()
  return self.m_dbTable:GetValue(DBKeys.ExtraLuckyProduceCached, "value") == "1"
end

function GeneratorBoostActivityModel:RemoveExtraLuckyProduceCache()
  self.m_dbTable:Remove(DBKeys.ExtraLuckyProduceCached)
end

function GeneratorBoostActivityModel:ClearState()
  self.m_curProgress = {
    0,
    0,
    0,
    0
  }
  self.m_lastShowProgress = {
    0,
    0,
    0,
    0
  }
  self:SetCurProgress()
  self:SetLastShowProgress()
  self:ClearBuff()
end

function GeneratorBoostActivityModel:SetCurProgress()
  self.m_dbTable:Set(DBKeys.CurProgress, "value", json.encode(Table.ShallowCopy(self.m_curProgress)))
end

function GeneratorBoostActivityModel:SetLastShowProgress()
  self.m_lastShowProgress = Table.DeepCopy(self.m_curProgress, true)
  self.m_dbTable:Set(DBKeys.LastShowProgress, "value", json.encode(Table.ShallowCopy(self.m_lastShowProgress)))
end

function GeneratorBoostActivityModel:GetBuffLevel()
  return self.m_dbTable:GetValue(DBKeys.ActiveBuffLevel, "value") or 0
end

function GeneratorBoostActivityModel:ClearBuff()
  if self:GetBuffLevel() == 0 then
    return
  end
  self.m_dbTable:Remove(DBKeys.ActiveBuffLevel)
  self.m_dbTable:Remove(DBKeys.ExtraProduceTotalSpreadCount)
  self.m_dbTable:Remove(DBKeys.ExtraProduceLeftSpreadCount)
  self:RemoveExtraProduceCache()
  self:RemoveExtraLuckyProduceCache()
  self:ReloadItemModelConfig()
  self:ReloadLuckyProduceConfig()
  self:SetActiveSpread(false)
  EventDispatcher.DispatchEvent(EEventType.GeneratorBoostBuffCleared)
end

function GeneratorBoostActivityModel:SetRefreshTime()
  local curTime = GM.GameModel:GetServerTime()
  local refreshTime = TimeUtil.ToCur24ClockTimestamp(curTime)
  self.m_dbTable:Set(DBKeys.RefreshTime, "value", refreshTime)
  return refreshTime
end

function GeneratorBoostActivityModel:GetRefreshTime()
  return self.m_dbTable:GetValue(DBKeys.RefreshTime, "value") or self:SetRefreshTime()
end

function GeneratorBoostActivityModel:IsLastGeneratorBoostLuckyConfig()
  return self.m_dbTable:GetValue(DBKeys.LastGeneratorBoostLuckyConfig, "value") == "1"
end

function GeneratorBoostActivityModel:SetLastGeneratorBoostLuckyConfig(bGeneratorBoost)
  self.m_dbTable:Set(DBKeys.LastGeneratorBoostLuckyConfig, "value", bGeneratorBoost and "1" or "0")
end

function GeneratorBoostActivityModel:GetRoundNum()
  return self.m_dbTable:GetValue(DBKeys.RoundNum, "value") or 1
end

function GeneratorBoostActivityModel:AddRoundNum()
  local roundNum = self:GetRoundNum() + 1
  self.m_dbTable:Set(DBKeys.RoundNum, "value", roundNum)
  GM.BIManager:LogAction(self.m_activityDefinition.BIStartRound, {
    r = self:GetRoundNum(),
    g = self:GetServerConfigGroupId()
  })
end

function GeneratorBoostActivityModel:SetFirstPopMainWindow(pop)
  self.m_dbTable:Set(DBKeys.FirstPopMainWindow, "value", pop)
end

function GeneratorBoostActivityModel:GetFirstPopMainWindow()
  return self.m_dbTable:GetValue(DBKeys.FirstPopMainWindow, "value") or false
end

function GeneratorBoostActivityModel:CanPopMainWindow()
  return self.m_popMainWindow
end

function GeneratorBoostActivityModel:SetPopMainWindow(bPop)
  self.m_popMainWindow = bPop
end

function GeneratorBoostActivityModel:GetSmallIconEntryShowConfig()
  return {
    HudButtonKey = ESceneViewHudButtonKey.GeneratorBoost,
    prefab = self.m_activityDefinition.BoardEntryPrefabName,
    listener = {
      self.m_activityDefinition.StateChangedEvent
    },
    checkfunc = function()
      return self:GetState() == ActivityState.Started
    end
  }
end

function GeneratorBoostActivityModel:GetTaskData(index)
  local missionData = {}
  missionData = {}
  missionData.taskType = self.m_taskConfig[index].taskType
  missionData.totalNum = self.m_taskConfig[index].num
  missionData.currNum = self.m_curProgress[index] or 0
  return missionData
end

function GeneratorBoostActivityModel:FinshedIndexTask(index)
  if self.m_curProgress[index] == self.m_taskConfig[index].num then
    return true
  end
  return false
end

function GeneratorBoostActivityModel:GetBuffType(index)
  if self.m_buffConfig[index] == nil then
    return nil
  end
  return self.m_buffConfig[index].buffType
end

function GeneratorBoostActivityModel:TestAddTaskScore(index, score)
  local message = {}
  message.type = self.m_taskConfig[index].taskType
  message.num = score
  message.operation = TaskEventProgressGainModule.TaskOper.Add
  self:_OnProgressGain(message)
end

function GeneratorBoostActivityModel:TestFinishTask(index)
  if index ~= nil then
    local message = {}
    message.type = self.m_taskConfig[index].taskType
    message.num = self.m_taskConfig[index].num - (self.m_curProgress[index] or 0)
    message.operation = TaskEventProgressGainModule.TaskOper.Add
    self:_OnProgressGain(message)
  else
    local index = 0
    for i, curP in ipairs(self.m_taskConfig) do
      if not self.m_curProgress[i] or self.m_curProgress[i] < self.m_taskConfig[i].num then
        index = i
        break
      end
    end
    if index == 0 then
      return
    end
    local message = {}
    message.type = self.m_taskConfig[index].taskType
    message.num = self.m_taskConfig[index].num - (self.m_curProgress[index] or 0)
    message.operation = TaskEventProgressGainModule.TaskOper.Add
    self:_OnProgressGain(message)
  end
end

function GeneratorBoostActivityModel:GetLastFinishedTaskCount()
  local count = 0
  for _, task in ipairs(self.m_taskConfig) do
    if self.m_lastShowProgress[task.index] == task.num then
      count = count + 1
    end
  end
  return count
end

function GeneratorBoostActivityModel:GetLastShowPreogress()
  return self.m_lastShowProgress
end

function GeneratorBoostActivityModel:GetTestInfo()
  if self:GetState() ~= ActivityState.Started then
    return "\230\180\187\229\138\168\230\156\170\229\188\128\229\144\175"
  end
  local str = "\229\183\178\230\191\128\230\180\187\231\154\132buff\239\188\154"
  local bLuckyActive = false
  for level = 1, self:GetBuffLevel() do
    local buffConfig = self.m_buffConfig[level]
    str = str .. "\n\231\173\137\231\186\167" .. level .. ":" .. buffConfig.buffType
    if buffConfig.buffType == EGeneratorBoostBuffType.ExtraProduce then
      local totalCount = self.m_dbTable:GetValue(DBKeys.ExtraProduceTotalSpreadCount, "value") or 0
      local leftCount = self.m_dbTable:GetValue(DBKeys.ExtraProduceLeftSpreadCount, "value") or 0
      str = str .. "\n\229\137\169\228\189\153\229\150\183\229\143\145\230\172\161\230\149\176\239\188\154" .. totalCount .. "\n" .. "\229\143\175\229\143\140\229\128\141\230\172\161\230\149\176\239\188\154" .. leftCount
      str = str .. "\n\231\188\147\229\173\152\229\143\140\229\128\141\239\188\154" .. tostring(self:IsCachedExtraProduce())
    end
    if buffConfig.buffType == EGeneratorBoostBuffType.ExtraLuckyProduce then
      bLuckyActive = true
      str = str .. "\n\231\188\147\229\173\152\229\143\140\229\128\141\229\185\184\232\191\144\239\188\154" .. tostring(self:IsCachedExtraLuckyProduce())
    end
    if buffConfig.buffType == EGeneratorBoostBuffType.MoreLuckyProduce then
      bLuckyActive = true
    end
    str = str .. "\n"
  end
  local boardModel, boardView = BoardModelHelper.GetActiveModel()
  if boardView and boardView.GetSelectedItemModel then
    local itemModel = boardView:GetSelectedItemModel()
    if itemModel then
      local itemSpread = itemModel:GetComponent(ItemSpread)
      if itemSpread and itemSpread:CanSupportGeneratorBoost() then
        str = str .. "\n\n\229\185\184\232\191\144\229\150\183\229\143\145\228\191\161\230\129\175\239\188\154"
        local luckyProduceModel = GM.ActivityManager:GetModel(ActivityType.LuckyProduce)
        if luckyProduceModel == nil then
          return
        end
        str = str .. "\n" .. luckyProduceModel:GetTestInfo()
        if LastProduceLuckyItemInfo ~= nil then
          str = str .. "(" .. LastProduceLuckyItemInfo .. ")"
        end
        str = str .. "\n\n\230\175\141\228\189\147\230\163\139\229\173\144\230\157\131\233\135\141\228\191\161\230\129\175\239\188\154"
        str = str .. "\n" .. GM.ItemFixedSpreadModel:GetTestInfo()
      end
    end
  end
  return str
end

function GeneratorBoostActivityModel:TestMustExtraProduce()
  self.m_testMustExtraProduce = self.m_testMustExtraProduce ~= true
end

function GeneratorBoostActivityModel:IsTestMustExtraProduce()
  return self.m_testMustExtraProduce == true
end
