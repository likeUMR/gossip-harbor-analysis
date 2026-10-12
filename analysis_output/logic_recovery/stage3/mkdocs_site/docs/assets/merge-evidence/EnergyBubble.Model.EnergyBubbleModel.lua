local EStrDBKeys = {
  TriggerTime = "TriggerTime",
  StartBIRecord = "StartBIRecord",
  GroupId = "GroupId"
}
EnergyBubbleModel = setmetatable({}, BaseActivityModel)
EnergyBubbleModel.__index = EnergyBubbleModel

function EnergyBubbleModel:Init(virtualDBTable)
  BaseActivityModel.Init(self, ActivityType.EnergyBubble, virtualDBTable)
end

function EnergyBubbleModel:_OnStateChanged()
  BaseActivityModel._OnStateChanged(self)
  EventDispatcher.DispatchEvent(EEventType.EnergyBubbleStateChanged)
  if self:GetState() == ActivityState.Started and self.m_dbTable:GetValue(EStrDBKeys.StartBIRecord, "value") == nil then
    self:LogActivity(EBIType.ActivityStarted, "")
    self.m_dbTable:Set(EStrDBKeys.StartBIRecord, "value", true)
  end
end

function EnergyBubbleModel:GetServerConfigGroupId()
  if self.m_energyBubbleConfig ~= nil then
    return self.m_energyBubbleConfig[1].groupId
  end
end

function EnergyBubbleModel:_LoadOtherServerConfig(config)
  self.m_energyBubbleConfig = config.energyBubbleConfig
  table.sort(self.m_energyBubbleConfig, function(a, b)
    if a.trigger_energy == b.trigger_energy then
      return a.trigger_gem > b.trigger_gem
    else
      return a.trigger_energy < b.trigger_energy
    end
  end)
end

function EnergyBubbleModel:GetTriggerConfig()
  for _, cfg in ipairs(self.m_energyBubbleConfig) do
    if GM.EnergyModel:GetEnergy(EnergyType.Main) <= cfg.trigger_energy then
      local cost
      if GM.ShopModel:IsChainEnergyOpen() then
        local configList = GM.ShopModel:GetChainEnergyConfig()
        local curStep = GM.ShopModel:GetCurChainEnergyStep()
        cost = configList[curStep].price
        while cost == 0 do
          curStep = curStep + 1
          if curStep > #configList then
            break
          end
          cost = configList[curStep].price
        end
      else
        cost = GM.ShopModel:GetEnergyData(EnergyType.Main).costNum
      end
      if cost >= cfg.trigger_gem then
        return cfg
      end
    end
  end
end

function EnergyBubbleModel:CanSpreadEnergyBubble()
  if self:GetState() == ActivityState.Started and GM.GameModel:GetServerTime() > self:GetTriggerTime() then
    return true
  end
  return false
end

function EnergyBubbleModel:GetBubbleInfo()
  local selectConfig = self:GetTriggerConfig()
  if Table.IsEmpty(selectConfig) then
    return nil
  end
  local bubbleInfo = {
    Code = ItemCodePrefix.PropertyBubble .. EPropertyType.Energy .. "-" .. selectConfig.energy .. "-" .. selectConfig.gem,
    Group = selectConfig.groupId
  }
  self:SetTriggerTime(selectConfig.interval)
  self:SetGroupId(selectConfig.groupId)
  return bubbleInfo
end

function EnergyBubbleModel:SetTriggerTime(interval)
  local time = GM.GameModel:GetServerTime() + interval * 60
  self.m_dbTable:Set(EStrDBKeys.TriggerTime, "value", time)
end

function EnergyBubbleModel:GetTriggerTime()
  return self.m_dbTable:GetValue(EStrDBKeys.TriggerTime, "value") or 0
end

function EnergyBubbleModel:SetGroupId(id)
  self.m_dbTable:Set(EStrDBKeys.GroupId, "value", id)
end

function EnergyBubbleModel:GetGroupId()
  return self.m_dbTable:GetValue(EStrDBKeys.GroupId, "value")
end

function EnergyBubbleModel:RemoveGroupId()
  self.m_dbTable:Remove(EStrDBKeys.GroupId, "value")
end

function EnergyBubbleModel:GetTestInfo()
  local bOpen = self.m_state == ActivityState.Started
  local str = "\230\180\187\229\138\168\230\152\175\229\144\166\230\156\137\230\149\136:" .. tostring(bOpen)
  if not bOpen then
    return str
  end
  local energy, gem
  if not Table.IsEmpty(self.m_energyBubbleConfig) then
    for _, cfg in ipairs(self.m_energyBubbleConfig) do
      if GM.EnergyModel:GetEnergy(EnergyType.Main) <= cfg.trigger_energy then
        energy = cfg.trigger_energy
        local cost
        if GM.ShopModel:IsChainEnergyOpen() then
          local configList = GM.ShopModel:GetChainEnergyConfig()
          local curStep = GM.ShopModel:GetCurChainEnergyStep()
          cost = configList[curStep].price
          while cost == 0 do
            curStep = curStep + 1
            if curStep > #configList then
              break
            end
            cost = configList[curStep].price
          end
        else
          cost = GM.ShopModel:GetEnergyData(EnergyType.Main).costNum
        end
        if cost >= cfg.trigger_gem then
          gem = cfg.trigger_gem
          break
        end
      end
    end
  end
  if bOpen then
    local countdown = ""
    if self:GetNextStateTime() ~= nil then
      local delta = self:GetNextStateTime() - GM.GameModel:GetServerTime()
      countdown = TimeUtil.ParseTimeDescription(delta, 2, false, false)
    end
    str = str .. "\n\230\187\161\232\182\179\231\154\132\232\167\166\229\143\145\228\189\147\229\138\155:" .. tostring(energy) .. "\n\230\187\161\232\182\179\231\154\132\232\167\166\229\143\145\233\146\187\231\159\179\230\161\163\228\189\141: " .. tostring(gem) .. "\n\229\134\183\229\141\180\230\129\162\229\164\141\230\151\182\233\151\180\231\130\185UTC:" .. TimeUtil.ToDate(self:GetTriggerTime(), ETimeFormat.UTCYMDHMS) .. "\n\229\128\146\232\174\161\230\151\182:" .. countdown
  end
  return str
end
