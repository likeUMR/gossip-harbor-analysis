EnergyType = {Main = "1"}
EnergyModel = {}
EnergyModel.__index = EnergyModel
EnergyModel.EnergyColumn = "energyValue"
EnergyModel.GenerateTimeColumn = "generateTime"
EnergyModel.InfiniteTimeColumn = "infiniteTime"
EnergyModel.DefaultMaxEnergy = 100
EnergyModel.DefaultRecoveryDuration = 120
local COST_ENERGY_THRESHHOLD = 64
local UPLOAD_ENERGY_THRESHHOLD = 8

function EnergyModel:Init()
  self.m_dbTable = GM.DBTableManager:GetTable(EDBTableConfigs.Energy)
  self.m_propertyEnergyTypeMapping = {
    [EPropertyType.Energy] = EnergyType.Main
  }
  self.m_propertyInfiniteEnergyTypeMapping = {
    [EPropertyType.EnergyInfiniteTime] = EnergyType.Main
  }
  self.m_mapEnergyCostSinceLastUpload = {}
end

function EnergyModel:LoadServerConfig(config)
  self:UpdatePerSecond()
end

function EnergyModel:LateInit()
  self.m_lateInited = true
  self:_CheckDefaultValue()
  self:_RestoreEnergy()
  EventDispatcher.AddListener(EEventType.LoginFinished, self, self._RestoreEnergy)
end

function EnergyModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function EnergyModel:UpdatePerSecond()
  if not self.m_lateInited then
    return
  end
  self:_RestoreEnergy()
end

function EnergyModel:GetData()
  return self.m_dbTable
end

function EnergyModel:FromSyncData(dataArr)
  self.m_dbTable:FromArr(dataArr)
end

function EnergyModel:PropertyTypeToEnergyType(type)
  return self.m_propertyEnergyTypeMapping[type]
end

function EnergyModel:EnergyTypeToPropertyType(type)
  return Table.GetKey(self.m_propertyEnergyTypeMapping, type)
end

function EnergyModel:PropertyTypeToInfiniteEnergyType(type)
  return self.m_propertyInfiniteEnergyTypeMapping[type]
end

function EnergyModel:GetEnergy(type)
  return self.m_dbTable:GetValue(type, EnergyModel.EnergyColumn) or 0
end

function EnergyModel:SetEnergy(type, energy)
  self.popupBundleEnergyWindowForLackingEnergy = false
  local lastEnergy = self:GetEnergy(type)
  self:GetData():Set(type, EnergyModel.EnergyColumn, energy)
  EventDispatcher.DispatchEvent(EEventType.EnergyChanged, {type = type, prevEnergy = lastEnergy})
end

function EnergyModel:GetGenerationTime(type)
  return self.m_dbTable:GetValue(type, EnergyModel.GenerateTimeColumn) or 0
end

function EnergyModel:SetGenerationTime(type, time)
  self:GetData():Set(type, EnergyModel.GenerateTimeColumn, time)
end

function EnergyModel:GetEnergyInfiniteTime(type)
  return self.m_dbTable:GetValue(type, EnergyModel.InfiniteTimeColumn)
end

function EnergyModel:AddEnergyInfiniteTime(type, delta)
  if delta <= 0 then
    GM.BIManager:LogErrorInfo(EBIType.AddInfiniteEnergyError, {t = type, d = delta})
    return
  end
  local currentTime = math.max(self:GetEnergyInfiniteTime(type) or 0, GM.GameModel:GetServerTime())
  GM.BIManager:LogAction(EBIType.AddInfiniteEnergy, {t = type, d = delta})
  self.m_dbTable:Set(type, EnergyModel.InfiniteTimeColumn, currentTime + delta)
end

function EnergyModel:IsEnergyFull(type)
  return self:GetEnergy(type) >= self:GetMaxEnergy(type) or not self:CanRestoreEnergy(type)
end

function EnergyModel:IsEnergyInfinite(type)
  return (self:GetEnergyInfiniteTime(type) or 0) > GM.GameModel:GetServerTime()
end

function EnergyModel:HasEnoughEnergy(type, count)
  return self:IsEnergyInfinite(type) or count <= self:GetEnergy(type)
end

function EnergyModel:GetRestoreOneRestDuration(type)
  return self:GetGenerationTime(type) + self:_GetRecoveryDuration(type) - GM.GameModel:GetServerTime()
end

function EnergyModel:GetEnergyFullDuration(type)
  if self:IsEnergyFull(type) then
    return nil
  end
  local currentEnergy = self:GetEnergy(type)
  local maxEnergy = self:GetMaxEnergy(type)
  local recoveryDuration = self:_GetRecoveryDuration(type)
  return self:GetRestoreOneRestDuration(type) + (maxEnergy - currentEnergy - 1) * recoveryDuration
end

function EnergyModel:SubtractEnergy(type, cost)
  if cost < 0 then
    Log.Error("SubtractEnergy cost < 0")
    return false
  end
  if self:IsEnergyInfinite(type) then
    return true, 0
  end
  local currentEnergy = self:GetEnergy(type)
  if cost > currentEnergy then
    return false
  end
  local newEnergy = currentEnergy - cost
  self:SetEnergy(type, newEnergy)
  if newEnergy == 0 then
    CSPlatform:SDK_TrackEvent("energy_depleted", "")
  end
  if self:CheckEnergyUploadEnabled() then
    self:CheckEnergyUpload(type, cost)
  end
  local maxEnergy = self:GetMaxEnergy(type)
  if currentEnergy >= maxEnergy and newEnergy < maxEnergy then
    self:SetGenerationTime(type, GM.GameModel:GetServerTime())
  end
  if GameConfig.IsTestMode() and type == EnergyType.Main then
    GM.UserModel:ChangeNumber(EPropertyTestKey.EnergyConsume, cost)
  end
  return true, cost
end

function EnergyModel:AddEnergy(type, value, allowOverfull)
  local currentEnergy = self:GetEnergy(type)
  local newEnergy = currentEnergy + value
  if not allowOverfull then
    newEnergy = math.min(newEnergy, self:GetMaxEnergy(type))
  end
  self:SetEnergy(type, newEnergy)
end

function EnergyModel:ResetEnergy(type)
  self:SetEnergy(type, self:GetMaxEnergy(type))
end

function EnergyModel:GetMaxEnergy(type)
  return EnergyModel.DefaultMaxEnergy
end

function EnergyModel:CanRestoreEnergy(type)
  return true
end

function EnergyModel:_GetRecoveryDuration(type)
  return EnergyModel.DefaultRecoveryDuration
end

function EnergyModel:_CheckDefaultValue()
  for _, type in pairs(EnergyType) do
    if not self.m_dbTable:HasRow(type) then
      self:ResetEnergy(type)
    end
  end
end

function EnergyModel:_RestoreEnergy(currentTime)
  local serverTimeFromLogin = tonumber(currentTime)
  currentTime = serverTimeFromLogin or GM.GameModel:GetServerTime()
  for key, type in pairs(EnergyType) do
    if self:CanRestoreEnergy(type) then
      local currentEnergy = self:GetEnergy(type)
      local maxEnergy = self:GetMaxEnergy(type)
      if currentEnergy < maxEnergy or serverTimeFromLogin then
        local recordTime = self:GetGenerationTime(type)
        local gapTime = currentTime - recordTime
        local recoveryDuration = self:_GetRecoveryDuration(type)
        local addedEnergy = gapTime // recoveryDuration
        local newEnergy = currentEnergy + math.max(0, addedEnergy)
        if serverTimeFromLogin then
          newEnergy = currentEnergy + addedEnergy
          newEnergy = math.max(0, newEnergy)
        end
        newEnergy = math.floor(math.min(newEnergy, maxEnergy))
        if addedEnergy < 0 and GameConfig.IsTestMode() then
          GM.UIManager:ShowPrompt("\228\189\147\229\138\155\231\177\187\229\158\139 " .. key .. " \230\151\182\233\151\180\229\155\158\233\128\128" .. gapTime .. "\231\167\146\239\188\140\228\189\147\229\138\155\231\155\184\229\133\179\230\149\176\229\128\188\228\191\174\230\173\163")
        end
        if addedEnergy ~= 0 then
          self:SetEnergy(type, newEnergy)
          local generationTime = recordTime + addedEnergy * recoveryDuration
          self:SetGenerationTime(type, generationTime)
          EventDispatcher.DispatchEvent(EEventType.EnergyRestored, {
            type = type,
            count = newEnergy - currentEnergy
          })
          GM.BIManager:LogAcquire(self:EnergyTypeToPropertyType(type), newEnergy - currentEnergy, EBIType.EnergyRestore, true)
          GM.PropertyDataManager:UpdateRecordUserProperties()
          CSPlatform:SDK_TrackEvent("virtual_resource_transaction", EPropertyType.Energy .. ":" .. newEnergy - currentEnergy)
        end
      end
    end
  end
end

function EnergyModel:ReCulculateEnergy(serverTime)
  if not serverTime or not self.m_lateInited then
    return
  end
  self:_RestoreEnergy(serverTime)
end

function EnergyModel:OnLackEnergy(type)
  if type == EnergyType.Main and not GM.TutorialModel:HasAnyStrongTutorialOngoing() then
    local iapEnabled = GM.ConfigModel:IsIAPEnabled()
    local bundleEnergyModel = GM.BundleManager:GetModel(EBundleType.EnergyBundle)
    if iapEnabled and bundleEnergyModel ~= nil then
      bundleEnergyModel:Try2TriggerEnergyBundle()
      if bundleEnergyModel:GetCurBundleConfigData() ~= nil and not bundleEnergyModel:IsBundleWindowPopupAfterEnergyWindow() then
        GM.UIManager:OpenView(UIPrefabConfigName.BundleEnergyWindow)
        return
      end
    end
  end
  GM.ShopModel:OpenEnergyWindow(type, true)
end

function EnergyModel:ResetEnergyCost()
  for key, type in pairs(EnergyType) do
    self.m_mapEnergyCostSinceLastUpload[type] = 0
  end
end

function EnergyModel:CheckEnergyUploadEnabled()
  return MINIGAME and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.EnergyUpload)
end

function EnergyModel:CheckEnergyUpload(energyType, cost)
  if not self.m_lateInited then
    return
  end
  if self.m_mapEnergyCostSinceLastUpload[energyType] == nil then
    self.m_mapEnergyCostSinceLastUpload[energyType] = 0
  end
  self.m_mapEnergyCostSinceLastUpload[energyType] = self.m_mapEnergyCostSinceLastUpload[energyType] + cost
  if self.m_mapEnergyCostSinceLastUpload[energyType] >= COST_ENERGY_THRESHHOLD then
    local currentEnergy = self:GetEnergy(energyType)
    if currentEnergy < UPLOAD_ENERGY_THRESHHOLD then
      self:ResetEnergyCost()
      Log.Debug("EnergyModel:UploadData")
      GM.BIManager:LogAction(EBIType.SyncModelAction.EnergyUpload)
      GM.SyncModel:MarkUploadThisFrame()
    end
  end
end
