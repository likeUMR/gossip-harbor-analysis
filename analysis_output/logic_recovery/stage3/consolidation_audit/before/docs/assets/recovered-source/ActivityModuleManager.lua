ActivityModuleManager = {}
ActivityModuleManager.__index = ActivityModuleManager
local nStart = 0

local function autoIncrease()
  nStart = nStart + 1
  return nStart
end

ActivityModuleManager.ModuleType = {
  ClickAcquireProperty = autoIncrease(),
  EventScoreConfigAcquireProperty = autoIncrease(),
  TaskEventProgressGain = autoIncrease(),
  LogicAcquireReward = autoIncrease(),
  FlyIconPropertyReward = autoIncrease(),
  ConvertDynamicReward = autoIncrease(),
  SmallChessboardProgress = autoIncrease(),
  RewardItemTipButton = autoIncrease(),
  GetRewardIconNameAndNativeSize = autoIncrease()
}

function ActivityModuleManager:Init()
  self.m_mapTypeModule = {
    [ActivityModuleManager.ModuleType.ClickAcquireProperty] = ItemClickAcquireModule.Create(),
    [ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty] = EventOrderScoreModule.Create(),
    [ActivityModuleManager.ModuleType.TaskEventProgressGain] = TaskEventProgressGainModule.Create(),
    [ActivityModuleManager.ModuleType.LogicAcquireReward] = ActivityAcquirePropertyLogicModule.Create(),
    [ActivityModuleManager.ModuleType.FlyIconPropertyReward] = ActivityAcquirePropertyFlyIconViewModule.Create(),
    [ActivityModuleManager.ModuleType.ConvertDynamicReward] = ConvertDynamicRewardModule.Create(),
    [ActivityModuleManager.ModuleType.SmallChessboardProgress] = ActivitySmallBoardItemProgressModule.Create(),
    [ActivityModuleManager.ModuleType.RewardItemTipButton] = ActivityRewardItemTipButtonModule.Create(),
    [ActivityModuleManager.ModuleType.GetRewardIconNameAndNativeSize] = ActivityGetPropertyIconNameAndNativeModule.Create()
  }
end

function ActivityModuleManager:Update()
end

function ActivityModuleManager:UpdatePerSecond()
end

function ActivityModuleManager:AddRegister(module, model, ...)
  if self.m_mapTypeModule[module] ~= nil then
    self.m_mapTypeModule[module]:AddRegister(model, ...)
  end
end

function ActivityModuleManager:RemoveRegister(module, model)
  if self.m_mapTypeModule[module] ~= nil then
    self.m_mapTypeModule[module]:RemoveRegister(model)
  end
end

function ActivityModuleManager:RemoveAllRegister(model)
  for _, Module in pairs(self.m_mapTypeModule) do
    Module:RemoveRegister(model)
  end
end

function ActivityModuleManager:GetRewardsByOrder(order)
  local target = {}
  for _, model in pairs(self.m_mapTypeModule) do
    if model.GetRewardsByOrder then
      local rewards = model:GetRewardsByOrder(order)
      if not Table.IsEmpty(rewards) then
        Table.ListAppend(target, rewards)
      end
    end
  end
  return target
end

function ActivityModuleManager:IsOrderSpecialReward(type)
  for _, state in pairs(ActivityModuleManager.ModuleType) do
    if self.m_mapTypeModule[state].IsOrderSpecialReward and self.m_mapTypeModule[state]:IsOrderSpecialReward(type) then
      return true
    end
  end
end

function ActivityModuleManager:IsActivityModuleLogicReward(type)
  for _, state in pairs(ActivityModuleManager.ModuleType) do
    if self.m_mapTypeModule[state].IsActivityModuleLogicReward and self.m_mapTypeModule[state]:IsActivityModuleLogicReward(type) then
      return true
    end
  end
end

function ActivityModuleManager:IsActivityModuleViewReward(type)
  for _, state in pairs(ActivityModuleManager.ModuleType) do
    if self.m_mapTypeModule[state].IsActivityModuleViewReward and self.m_mapTypeModule[state]:IsActivityModuleViewReward(type) then
      return true
    end
  end
end

function ActivityModuleManager:ConvertDynamicReward(reward, needBI)
  local ConvertDynamicRewardModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.ConvertDynamicReward]
  if ConvertDynamicRewardModule then
    return ConvertDynamicRewardModule:GetConvertDynamicFunction(reward, needBI)
  end
end

function ActivityModuleManager:AcquireModuleLogicReward(type, count, scene)
  local EventOrderScoreModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty]
  EventOrderScoreModule:AcquireModuleLogicReward(type, count, scene)
  local logicScoreModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.LogicAcquireReward]
  logicScoreModule:AcquireModuleLogicReward(type, count, scene)
end

function ActivityModuleManager:GetActivityEntryByType(type)
  local ListSupportOrderModule = {
    ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty,
    ActivityModuleManager.ModuleType.FlyIconPropertyReward
  }
  for _, state in ipairs(ListSupportOrderModule) do
    local windowbutton, activityType, flyEndPos = self.m_mapTypeModule[state]:GetActivityEntryByType(type)
    if windowbutton ~= nil or activityType ~= nil then
      return windowbutton, activityType, flyEndPos
    end
  end
  return nil
end

function ActivityModuleManager:GetActivityModelByType(type)
  local ListSupportOrderModule = {
    ActivityModuleManager.ModuleType.EventScoreConfigAcquireProperty
  }
  for _, state in ipairs(ListSupportOrderModule) do
    local model = self.m_mapTypeModule[state]:GetActivityModelByType(type)
    if model ~= nil then
      return model
    end
  end
  return nil
end

function ActivityModuleManager:IsFlyScoreAnimationByType(type)
  for _, state in pairs(ActivityModuleManager.ModuleType) do
    if self.m_mapTypeModule[state].IsFlyScoreAnimationByType and self.m_mapTypeModule[state]:IsFlyScoreAnimationByType(type) then
      return true
    end
  end
end

function ActivityModuleManager:CanShowTipButton(rewardType)
  local showTipModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.RewardItemTipButton]
  return showTipModule:CanShowTipButton(rewardType)
end

function ActivityModuleManager:OnItemTipButton(rewardType, defaultArgs)
  local showTipModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.RewardItemTipButton]
  return showTipModule:OnItemTipButton(rewardType, defaultArgs)
end

function ActivityModuleManager:IsShowBoardAreaEntryReward(rewardType, showArgs)
  local flyIconModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.FlyIconPropertyReward]
  return flyIconModule:IsShowBoardAreaEntryReward(rewardType, showArgs)
end

function ActivityModuleManager:InViewHandle(rewardData, showArgs)
  local flyIconModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.FlyIconPropertyReward]
  return flyIconModule:InViewHandle(rewardData, showArgs)
end

function ActivityModuleManager:GetRewardBigIconNameAndNativeSize(rewardType)
  local GetRewardIconNameModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.GetRewardIconNameAndNativeSize]
  return GetRewardIconNameModule:GetRewardBigIconNameAndNativeSize(rewardType)
end

function ActivityModuleManager:GetRewardIconNameAndNativeSize(rewardType)
  local GetRewardIconNameModule = self.m_mapTypeModule[ActivityModuleManager.ModuleType.GetRewardIconNameAndNativeSize]
  return GetRewardIconNameModule:GetRewardIconNameAndNativeSize(rewardType)
end
