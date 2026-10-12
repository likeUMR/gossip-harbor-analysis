SystemConfigKey = {
  SpreadCoinMinChainLevel = "SpreadCoinMinChainLevel",
  TaskSfxDelay = "TaskSfxDelay",
  StarterBundleOpenCd = "StarterBundleOpenCd",
  ShopShowGemOnlyMaxLevel = "ShopShowGemOnlyMaxLevel"
}
SystemConfigModel = {}
SystemConfigModel.__index = SystemConfigModel

function SystemConfigModel:LoadFileConfig()
  self.m_systemConfig = {}
  local config = GM.ConfigModel:GetLocalConfig(LocalConfigKey.System)
  for _, data in ipairs(config) do
    self.m_systemConfig[data.name] = tonumber(data.value)
  end
end

function SystemConfigModel:GetConfig(key)
  return self.m_systemConfig[key]
end
