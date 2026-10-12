local Sec2Day = _ENV.Sec2Day
local DBColumnValue = "value"
local ItemDBKeyTotalLeftSpreadCountPrefix = "tl_"
local ItemDBKeyLuckyLeftSpreadCountPrefix = "ll_"
local SpreadSmartWeightKey = "Weight_Smart"
local mapCachedTotalLeftSpreadCountKey = {}
local mapCachedLuckyLeftSpreadCountKey = {}
local MiscConfKey = {
  LuckyProduceSmart = "lucky_produce_smart"
}
local EnergyBoostRatioAdjustDataMaxCount = 4
local DBKey = {
  EnergyCostResetTimeStamp = "ecrt",
  EnergyCostCount = "ecc",
  FreeLuckyProduceEnergyCostCount = "elpec",
  ContiLuckyProduceItemType = "clpit",
  ContiLuckyProduceMaxCount = "clpmc",
  ContiLuckyProduceCount = "clpc",
  ContiLuckyProduceExpiredTimeStamp = "clpeet"
}
LuckyProduceModel = setmetatable({}, BaseActivityModel)
LuckyProduceModel.__index = LuckyProduceModel
LuckyProduceModel.ContiLuckyProduceLastDuration = 10

function LuckyProduceModel:Init(virtualDBTable)
  BaseActivityModel.Init(self, ActivityType.LuckyProduce, virtualDBTable)
  self:_LoadFileConfig()
  self:_InitEnergyBoostRatioAdjustData()
  EventDispatcher.AddListener(EEventType.PropertyConsumed, self, self._OnPropertyConsumed)
end

function LuckyProduceModel:_LoadFileConfig(boostConfig)
  self.m_spreadConfigs = boostConfig and boostConfig or GM.ConfigModel:GetLocalConfig(LocalConfigKey.LuckyProduce)
  self.m_mapGeneratorType2Config = {}
  for _, config in ipairs(self.m_spreadConfigs) do
    for _, itemType in ipairs(config.generator) do
      if self.m_mapGeneratorType2Config[itemType] == nil then
        self.m_mapGeneratorType2Config[itemType] = {}
      end
      self.m_mapGeneratorType2Config[itemType][#self.m_mapGeneratorType2Config[itemType] + 1] = config
    end
  end
end

function LuckyProduceModel:CalculateItemChainMap()
  local itemDataModel = GM.ItemDataModel
  for _, config in ipairs(self.m_spreadConfigs) do
    if config.lucky_items[1].Item ~= nil then
      return
    end
    config.itemChainMap = {}
    for i, dataStr in ipairs(config.lucky_items) do
      local splitDatas = StringUtil.Split(dataStr, "-")
      config.lucky_items[i] = {
        Item = splitDatas[1],
        Weight = tonumber(splitDatas[2])
      }
      local weightInfo = config.lucky_items[i]
      if itemDataModel:GetModelConfig(weightInfo.Item, true) ~= nil then
        weightInfo.ItemChainLevel = itemDataModel:GetChainLevel(weightInfo.Item)
        local chainId = itemDataModel:GetChainId(weightInfo.Item)
        if config.itemChainMap[chainId] == nil then
          config.itemChainMap[chainId] = {}
        end
        config.itemChainMap[chainId][#config.itemChainMap[chainId] + 1] = weightInfo
      end
    end
  end
end

function LuckyProduceModel:_LoadOtherServerConfig(config)
  local miscConfigReader = MiscConfigReader.Create(config)
  self.m_smartProduceRatio = miscConfigReader:GetInteger(MiscConfKey.LuckyProduceSmart)
  self.m_arrLuckyProduceConfig = {}
  local arrLuckyProduceConfig = config.luckyProduceConfig
  if arrLuckyProduceConfig ~= nil then
    for _, config in ipairs(arrLuckyProduceConfig) do
      self.m_arrLuckyProduceConfig[#self.m_arrLuckyProduceConfig + 1] = config
    end
    table.sort(self.m_arrLuckyProduceConfig, function(a, b)
      return a.energy_cost.range_entry[1] < b.energy_cost.range_entry[1]
    end)
  end
end

function LuckyProduceModel:_OnStateChanged()
  BaseActivityModel._OnStateChanged(self)
  if self.m_state == ActivityState.Started then
    self:_UpdateSpecialModeData()
  end
end

function LuckyProduceModel:LateInit()
  self:CalculateItemChainMap()
end

function LuckyProduceModel:_DropData()
  BaseActivityModel._DropData(self)
  self:_ClearSpecialModeData()
end

function LuckyProduceModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  self:_CheckIfNeedResetEnergyCost()
end

function LuckyProduceModel:_OnPropertyConsumed(msg)
  if msg.property[PROPERTY_TYPE] == EPropertyType.Energy then
    self:_AddEnergyCostCount(msg.property[PROPERTY_COUNT])
  end
end

function LuckyProduceModel:GetGeneratorBoostConfig()
  local generatorBoost = GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition)
  if generatorBoost ~= nil then
    local config = generatorBoost:GetLuckyProduceConfig()
    if config then
      return config
    end
  end
end

function LuckyProduceModel:ReloadFileConfig(boostConfig, bUpdate)
  self:_LoadFileConfig(boostConfig)
  self:CalculateItemChainMap()
  if bUpdate then
    for _, config in ipairs(self.m_spreadConfigs) do
      for _, itemType in ipairs(config.generator) do
        self:_ClearLuckyLeftSpreadCount(itemType)
        self:_ClearTotalLeftSpreadCount(itemType)
      end
    end
  end
end

local LastProduceLuckyItemInfo

function LuckyProduceModel:Try2ProduceLuckyItem(sourceItemModel)
  LastProduceLuckyItemInfo = "\230\151\160\229\185\184\232\191\144\229\150\183\229\143\145"
  if self:GetState(true) ~= ActivityState.Started then
    return nil
  end
  local sourceItemType = sourceItemModel:GetType()
  local config = self:_GetLevelFitConfig(sourceItemType)
  if config == nil then
    return nil
  end
  if self:_CanContiLuckyProduce(sourceItemType) then
    local customSpreadType = self:_PostProcessOnContiLuckyProduce()
    if customSpreadType == BoardSpreadType.DoubleLucky then
      LastProduceLuckyItemInfo = "\228\186\140\232\191\158\229\185\184\232\191\144\229\150\183\229\143\145:"
    elseif customSpreadType == BoardSpreadType.TripleLucky1 then
      LastProduceLuckyItemInfo = "\228\184\137\232\191\158\229\185\184\232\191\144\229\150\183\229\143\145\231\172\172\228\184\128\232\191\158:"
    elseif customSpreadType == BoardSpreadType.TripleLucky2 then
      LastProduceLuckyItemInfo = "\228\184\137\232\191\158\229\185\184\232\191\144\229\150\183\229\143\145\231\172\172\228\186\140\232\191\158:"
    end
    return self:_GetGenerateLuckyItem(sourceItemType, config, false, customSpreadType)
  end
  local generatorBoost = GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition)
  if generatorBoost ~= nil then
    local bHave, bCan = generatorBoost:HaveAndCanExtraLuckyProduce(true)
    if bHave then
      if bCan then
        self:_Try2TriggerContiLuckyProduce(sourceItemType)
        return self:_GetGenerateLuckyItem(sourceItemType, config)
      end
      LastProduceLuckyItemInfo = "[\231\169\186\230\163\139\230\160\188\228\184\141\232\182\179\232\167\166\229\143\145\229\143\140\229\128\141\229\185\184\232\191\144\229\150\183\229\143\145\239\188\140\231\187\167\231\187\173\231\188\147\229\173\152]"
      return nil
    end
  end
  local totalLeftSpreadCount = self:_GetTotalLeftSpreadCount(sourceItemType) or 0
  local luckyLeftSpreadCount = self:_GetLuckyLeftSpreadCount(sourceItemType)
  if totalLeftSpreadCount == 0 then
    totalLeftSpreadCount = config.lucky_chance[1]
    luckyLeftSpreadCount = config.lucky_chance[2]
    self:_SetLuckyLeftSpreadCount(sourceItemType, luckyLeftSpreadCount)
  end
  local index = MathUtil.Random(totalLeftSpreadCount)
  local luckyProduce = luckyLeftSpreadCount >= index or GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestLuckyProduce, 0) == 1
  local freeLuckyProduce = false
  if not luckyProduce then
    if self:_CanFreeLuckyProduce() then
      LastProduceLuckyItemInfo = "\229\133\141\232\180\185\229\185\184\232\191\144\229\150\183\229\143\145:"
      luckyProduce = true
      freeLuckyProduce = true
      self:_PostProcessOnFreeLuckyProduce()
    end
  else
    luckyLeftSpreadCount = luckyLeftSpreadCount - 1
    self:_SetLuckyLeftSpreadCount(sourceItemType, luckyLeftSpreadCount)
    LastProduceLuckyItemInfo = "\230\153\174\233\128\154\229\185\184\232\191\144\229\150\183\229\143\145:"
  end
  if not freeLuckyProduce then
    totalLeftSpreadCount = totalLeftSpreadCount - 1
    self:_SetTotalLeftSpreadCount(sourceItemType, totalLeftSpreadCount)
  end
  if luckyProduce then
    if generatorBoost ~= nil then
      local bHave, bCan = generatorBoost:HaveAndCanExtraLuckyProduce(false)
      if bHave then
        if bCan then
          self:_Try2TriggerContiLuckyProduce(sourceItemType)
          return self:_GetGenerateLuckyItem(sourceItemType, config, freeLuckyProduce)
        end
        LastProduceLuckyItemInfo = "[\231\169\186\230\163\139\230\160\188\228\184\141\232\182\179\232\167\166\229\143\145\229\143\140\229\128\141\229\185\184\232\191\144\229\150\183\229\143\145\239\188\140\229\183\178\231\188\147\229\173\152]"
        return nil
      end
    end
    self:_Try2TriggerContiLuckyProduce(sourceItemType)
    return self:_GetGenerateLuckyItem(sourceItemType, config, freeLuckyProduce)
  end
  return nil
end

function LuckyProduceModel:_GetGenerateLuckyItem(sourceItemType, config, isFree, customSpreadType)
  local luckyItems
  if self:_UseSmartProduce() then
    self:_UpdateSpreadConfigSmartWeight(sourceItemType, config)
    luckyItems = Table.ListWeightSelectOne(config.lucky_items, SpreadSmartWeightKey)
  else
    luckyItems = Table.ListWeightSelectOne(config.lucky_items)
  end
  if GameConfig.IsTestMode() then
    LastProduceLuckyItemInfo = LastProduceLuckyItemInfo .. "\n" .. sourceItemType .. "->" .. luckyItems.Item .. "(\229\142\159\231\148\159)"
  end
  local spreadType = customSpreadType
  if spreadType == nil then
    if isFree then
      spreadType = Table.ListContain(config.super_items, luckyItems.Item) and BoardSpreadType.FreeSuperLucky or BoardSpreadType.FreeLucky
    else
      spreadType = Table.ListContain(config.super_items, luckyItems.Item) and BoardSpreadType.SuperLucky or BoardSpreadType.Lucky
    end
  end
  return luckyItems.Item, spreadType
end

function LuckyProduceModel:_GetLevelFitConfig(itemType)
  if self.m_mapGeneratorType2Config[itemType] == nil then
    return nil
  end
  local level = GM.LevelModel:GetCurrentLevel()
  for _, config in ipairs(self.m_mapGeneratorType2Config[itemType]) do
    if (config.level_max == nil or level <= config.level_max) and (config.level_min == nil or level >= config.level_min) then
      return config
    end
  end
  return nil
end

function LuckyProduceModel:IsSuperLuckyProduce(sourceItemType, spreadItemType)
  local config = self:_GetLevelFitConfig(sourceItemType)
  if config == nil then
    return false
  end
  return Table.ListContain(config.super_items, spreadItemType)
end

function LuckyProduceModel:_GetTotalLeftSpreadCount(itemType)
  if mapCachedTotalLeftSpreadCountKey[itemType] == nil then
    mapCachedTotalLeftSpreadCountKey[itemType] = ItemDBKeyTotalLeftSpreadCountPrefix .. tostring(itemType)
  end
  return self.m_dbTable:GetValue(mapCachedTotalLeftSpreadCountKey[itemType], DBColumnValue)
end

function LuckyProduceModel:_SetTotalLeftSpreadCount(itemType, count)
  if mapCachedTotalLeftSpreadCountKey[itemType] == nil then
    mapCachedTotalLeftSpreadCountKey[itemType] = ItemDBKeyTotalLeftSpreadCountPrefix .. tostring(itemType)
  end
  self.m_dbTable:Set(mapCachedTotalLeftSpreadCountKey[itemType], DBColumnValue, count)
end

function LuckyProduceModel:_GetLuckyLeftSpreadCount(itemType)
  if mapCachedLuckyLeftSpreadCountKey[itemType] == nil then
    mapCachedLuckyLeftSpreadCountKey[itemType] = ItemDBKeyLuckyLeftSpreadCountPrefix .. tostring(itemType)
  end
  return self.m_dbTable:GetValue(mapCachedLuckyLeftSpreadCountKey[itemType], DBColumnValue)
end

function LuckyProduceModel:_SetLuckyLeftSpreadCount(itemType, count)
  if mapCachedLuckyLeftSpreadCountKey[itemType] == nil then
    mapCachedLuckyLeftSpreadCountKey[itemType] = ItemDBKeyLuckyLeftSpreadCountPrefix .. tostring(itemType)
  end
  self.m_dbTable:Set(mapCachedLuckyLeftSpreadCountKey[itemType], DBColumnValue, count)
end

function LuckyProduceModel:_ClearLuckyLeftSpreadCount(itemType)
  if mapCachedLuckyLeftSpreadCountKey[itemType] == nil then
    return
  end
  self.m_dbTable:Remove(mapCachedLuckyLeftSpreadCountKey[itemType])
end

function LuckyProduceModel:_ClearTotalLeftSpreadCount(itemType)
  if mapCachedTotalLeftSpreadCountKey[itemType] == nil then
    return
  end
  self.m_dbTable:Remove(mapCachedTotalLeftSpreadCountKey[itemType])
end

function LuckyProduceModel:_UseSmartProduce()
  return self.m_smartProduceRatio ~= nil and self.m_smartProduceRatio >= 1
end

function LuckyProduceModel:_UpdateSpreadConfigSmartWeight(type, config)
  if not self:_UseSmartProduce() then
    return
  end
  local multipleWeightInfo = {}
  local energyBoostRatio
  if GM.EnergyBoostModel:CanEnergyBoost(type) then
    energyBoostRatio = GM.EnergyBoostModel:GetEnergyBoostPowerRatio()
  else
    energyBoostRatio = 0
  end
  local itemDataModel = GM.ItemDataModel
  local lackItems = GM.MainBoardModel:GetOrderCodeLackCountMap()
  for itemType, _ in pairs(lackItems) do
    local chainId = itemDataModel:GetChainId(itemType)
    if config.itemChainMap[chainId] ~= nil then
      local chainLevel = itemDataModel:GetChainLevel(itemType)
      for _, weightInfo in ipairs(config.itemChainMap[chainId]) do
        if chainLevel >= weightInfo.ItemChainLevel + energyBoostRatio then
          multipleWeightInfo[weightInfo] = true
        end
      end
    end
  end
  for _, weightInfo in ipairs(config.lucky_items) do
    weightInfo[SpreadSmartWeightKey] = weightInfo.Weight * (multipleWeightInfo[weightInfo] ~= nil and self.m_smartProduceRatio or 1)
  end
end

function LuckyProduceModel:_InitEnergyBoostRatioAdjustData()
  local dataStr = PlayerPrefs.GetString(EPlayerPrefKey.LuckyProduceEnergyBoostRatioAdjustData, "")
  self.m_cachedBoostRatioAdjustData = StringUtil.SplitToNum(dataStr, ",")
end

function LuckyProduceModel:GetAdjustedMaxEnergyBoostRatio(maxBoostRatio)
  if not GM.ConfigModel:IsServerControlOpen(EGeneralConfType.AdjustLuckyProduceBoostRatio) then
    return maxBoostRatio
  end
  if self.m_cachedBoostRatioAdjustData == nil or #self.m_cachedBoostRatioAdjustData == 0 then
    return maxBoostRatio
  end
  local result = 0
  for _, boostRatio in ipairs(self.m_cachedBoostRatioAdjustData) do
    result = result + boostRatio
  end
  return math.ceil(result / #self.m_cachedBoostRatioAdjustData)
end

function LuckyProduceModel:RecordBoostRatioAdjustData(newBoostRatio, spreadType, bCostEnergy, itemType)
  if not GM.ConfigModel:IsServerControlOpen(EGeneralConfType.AdjustLuckyProduceBoostRatio) then
    return
  end
  if not bCostEnergy or spreadType ~= BoardSpreadType.Normal and spreadType ~= BoardSpreadType.GeneratorBoostSmart or not GM.EnergyBoostModel:IsEnergyBoostTargetItemType(itemType) then
    return
  end
  if #self.m_cachedBoostRatioAdjustData >= EnergyBoostRatioAdjustDataMaxCount then
    table.remove(self.m_cachedBoostRatioAdjustData, 1)
  end
  self.m_cachedBoostRatioAdjustData[#self.m_cachedBoostRatioAdjustData + 1] = newBoostRatio
  PlayerPrefs.SetString(EPlayerPrefKey.LuckyProduceEnergyBoostRatioAdjustData, table.concat(self.m_cachedBoostRatioAdjustData, ","))
end

function LuckyProduceModel:_IsSpecialModeOn()
  return self.m_arrLuckyProduceConfig ~= nil and #self.m_arrLuckyProduceConfig > 0
end

function LuckyProduceModel:_UpdateSpecialModeData()
  if self.m_curLuckyProduceConfigIndex == nil then
    self.m_curLuckyProduceConfigIndex = self:_CalculateLuckyProduceConfigIndex()
  end
  local freeLuckyProduceEnergyCostCountStr = self.m_dbTable:GetValue(DBKey.FreeLuckyProduceEnergyCostCount, DBColumnValue)
  self.m_arrFreeLuckyProduceEnergyCostCount = StringUtil.SplitToNum(freeLuckyProduceEnergyCostCountStr, ",")
end

function LuckyProduceModel:_ClearSpecialModeData()
  self.m_arrFreeLuckyProduceEnergyCostCount = nil
  self.m_curLuckyProduceConfigIndex = nil
end

function LuckyProduceModel:_GetEnergyCostCount()
  return self.m_dbTable:GetValue(DBKey.EnergyCostCount, DBColumnValue) or 0
end

function LuckyProduceModel:_AddEnergyCostCount(count)
  if not self:_IsSpecialModeOn() then
    return
  end
  self.m_dbTable:Set(DBKey.EnergyCostCount, DBColumnValue, self:_GetEnergyCostCount() + count)
  self:_CheckLuckyProduceConfigIndex()
end

function LuckyProduceModel:_GetCurLuckyProduceConfigIndex()
  return self.m_curLuckyProduceConfigIndex
end

function LuckyProduceModel:_CalculateLuckyProduceConfigIndex()
  local costEnergy = self:_GetEnergyCostCount()
  local index = 0
  for i, config in ipairs(self.m_arrLuckyProduceConfig) do
    if costEnergy >= config.energy_cost.range_entry[1] and costEnergy <= config.energy_cost.range_entry[2] then
      index = i
      break
    end
  end
  return index
end

function LuckyProduceModel:_CheckLuckyProduceConfigIndex()
  local curIndex = self:_CalculateLuckyProduceConfigIndex()
  if self.m_curLuckyProduceConfigIndex ~= curIndex then
    self:_AddFreeLuckyProduceEnergyCostCount(self.m_curLuckyProduceConfigIndex + 1, curIndex == 0 and #self.m_arrLuckyProduceConfig or curIndex)
    self.m_curLuckyProduceConfigIndex = curIndex
  end
end

function LuckyProduceModel:_CheckIfNeedResetEnergyCost()
  if not self:_IsSpecialModeOn() then
    return
  end
  if GM.GameModel:GetServerTime() // Sec2Day ~= (self.m_dbTable:GetValue(DBKey.EnergyCostResetTimeStamp, DBColumnValue) or 0) // Sec2Day then
    self:_ResetEnergyCost()
  end
end

function LuckyProduceModel:_ResetEnergyCost()
  self.m_dbTable:Remove(DBKey.EnergyCostCount)
  self.m_dbTable:Remove(DBKey.FreeLuckyProduceEnergyCostCount)
  self.m_dbTable:Set(DBKey.EnergyCostResetTimeStamp, DBColumnValue, GM.GameModel:GetServerTime())
  self:_ClearSpecialModeData()
  self:_UpdateSpecialModeData()
end

function LuckyProduceModel:_AddFreeLuckyProduceEnergyCostCount(fromIndex, toIndex)
  for index = fromIndex, toIndex do
    local config = self.m_arrLuckyProduceConfig[index]
    local rangeSize = config.energy_cost.range_entry[2] - config.energy_cost.range_entry[1] + 1
    local randomN = MathUtil.RandomN(rangeSize, math.min(rangeSize, config.extra_lucky))
    table.sort(randomN, function(a, b)
      return a < b
    end)
    for _, rdn in ipairs(randomN) do
      self.m_arrFreeLuckyProduceEnergyCostCount[#self.m_arrFreeLuckyProduceEnergyCostCount + 1] = rdn + config.energy_cost.range_entry[1] - 1
    end
  end
  self.m_dbTable:Set(DBKey.FreeLuckyProduceEnergyCostCount, DBColumnValue, table.concat(self.m_arrFreeLuckyProduceEnergyCostCount, ","))
end

function LuckyProduceModel:_CanFreeLuckyProduce()
  return self.m_arrFreeLuckyProduceEnergyCostCount[1] ~= nil and self:_GetEnergyCostCount() >= self.m_arrFreeLuckyProduceEnergyCostCount[1]
end

function LuckyProduceModel:_PostProcessOnFreeLuckyProduce()
  table.remove(self.m_arrFreeLuckyProduceEnergyCostCount, 1)
  self.m_dbTable:Set(DBKey.FreeLuckyProduceEnergyCostCount, DBColumnValue, table.concat(self.m_arrFreeLuckyProduceEnergyCostCount, ","))
end

function LuckyProduceModel:_Try2TriggerContiLuckyProduce(sourceItemType)
  if not self:_IsSpecialModeOn() then
    return
  end
  local config = self.m_arrLuckyProduceConfig[self:_GetCurLuckyProduceConfigIndex()]
  if config == nil then
    return
  end
  if config.triple_lucky_chance >= MathUtil.Random(1, 10000) then
    self:_TriggerContiLuckyProduce(sourceItemType, 2)
    LastProduceLuckyItemInfo = "[\232\167\166\229\143\145\228\184\137\232\191\158\229\185\184\232\191\144\229\150\183\229\143\145]\n" .. LastProduceLuckyItemInfo
  elseif config.double_lucky_chance >= MathUtil.Random(1, 10000) then
    self:_TriggerContiLuckyProduce(sourceItemType, 1)
    LastProduceLuckyItemInfo = "[\232\167\166\229\143\145\228\186\140\232\191\158\229\185\184\232\191\144\229\150\183\229\143\145]\n" .. LastProduceLuckyItemInfo
  end
end

function LuckyProduceModel:_TriggerContiLuckyProduce(targetItemType, contiMaxNum)
  self.m_dbTable:Set(DBKey.ContiLuckyProduceItemType, DBColumnValue, tostring(targetItemType))
  self.m_dbTable:Set(DBKey.ContiLuckyProduceMaxCount, DBColumnValue, contiMaxNum)
  self.m_dbTable:Set(DBKey.ContiLuckyProduceCount, DBColumnValue, 0)
  self.m_dbTable:Set(DBKey.ContiLuckyProduceExpiredTimeStamp, DBColumnValue, GM.GameModel:GetServerTime() + LuckyProduceModel.ContiLuckyProduceLastDuration)
end

function LuckyProduceModel:_CLearContiLuckyProduceData()
  self.m_dbTable:Remove(DBKey.ContiLuckyProduceItemType)
  self.m_dbTable:Remove(DBKey.ContiLuckyProduceMaxCount)
  self.m_dbTable:Remove(DBKey.ContiLuckyProduceCount)
  self.m_dbTable:Remove(DBKey.ContiLuckyProduceExpiredTimeStamp)
end

function LuckyProduceModel:_CanContiLuckyProduce(targetItemType)
  if StringUtil.IsNilOrEmpty(self.m_dbTable:GetValue(DBKey.ContiLuckyProduceItemType, DBColumnValue)) then
    return false
  end
  if targetItemType ~= self.m_dbTable:GetValue(DBKey.ContiLuckyProduceItemType, DBColumnValue) or self.m_dbTable:GetValue(DBKey.ContiLuckyProduceMaxCount, DBColumnValue) <= self.m_dbTable:GetValue(DBKey.ContiLuckyProduceCount, DBColumnValue) or GM.GameModel:GetServerTime() > self.m_dbTable:GetValue(DBKey.ContiLuckyProduceExpiredTimeStamp, DBColumnValue) then
    self:_CLearContiLuckyProduceData()
    return false
  end
  return true
end

function LuckyProduceModel:_PostProcessOnContiLuckyProduce()
  local curContiCount = self.m_dbTable:GetValue(DBKey.ContiLuckyProduceCount, DBColumnValue)
  self.m_dbTable:Set(DBKey.ContiLuckyProduceCount, DBColumnValue, curContiCount + 1)
  self.m_dbTable:Set(DBKey.ContiLuckyProduceExpiredTimeStamp, DBColumnValue, GM.GameModel:GetServerTime() + LuckyProduceModel.ContiLuckyProduceLastDuration)
  local boardSpreadType = BoardSpreadType.DoubleLucky
  if self.m_dbTable:GetValue(DBKey.ContiLuckyProduceMaxCount, DBColumnValue) == 2 then
    boardSpreadType = curContiCount == 0 and BoardSpreadType.TripleLucky1 or BoardSpreadType.TripleLucky2
  end
  return boardSpreadType
end

local greenColor = "#aafaaa"
local whiteColor = "#ffffff"
local redColor = "#f2b3b3"
local ratioAdjustColor = "#fff68f"
local specialColor = "#f6a9ff"
local lastSpreadColor = "#8deafb"

function LuckyProduceModel:GetTestInfo()
  if self:GetState(true) ~= ActivityState.Started then
    return "\230\180\187\229\138\168\229\188\128\229\144\175:\230\151\160"
  end
  if MainBoardView.GetInstance() == nil then
    return "\230\180\187\229\138\168\229\188\128\229\144\175:\230\156\137\n\233\128\137\228\184\173\230\163\139\229\173\144:\230\151\160"
  end
  local text = "\230\180\187\229\138\168\229\188\128\229\144\175:\230\156\137\n\233\128\137\228\184\173\230\163\139\229\173\144:"
  local selectedItem = MainBoardView.GetInstance():GetSelectedItemModel()
  if selectedItem == nil then
    text = text .. "\230\151\160\n"
  else
    local type = selectedItem:GetType()
    text = text .. tostring(type) .. "\n\230\156\137\230\151\160\229\185\184\232\191\144\229\150\183\229\143\145:"
    if self.m_mapGeneratorType2Config[type] ~= nil then
      local config = self:_GetLevelFitConfig(type)
      if config ~= nil then
        text = text .. "\230\156\137\n\230\128\187\229\150\183\229\143\145\230\172\161\230\149\176:" .. (self:_GetTotalLeftSpreadCount(type) or config.lucky_chance[1]) .. "\n\229\185\184\232\191\144\229\150\183\229\143\145\230\172\161\230\149\176:" .. (self:_GetLuckyLeftSpreadCount(type) or config.lucky_chance[2])
        if self:_UseSmartProduce() then
          text = text .. "\n[\228\188\152\229\140\150\229\188\128-\230\157\131\233\135\141\229\136\151\232\161\168]: "
          self:_UpdateSpreadConfigSmartWeight(type, config)
          for i, weightInfo in ipairs(config.lucky_items) do
            text = text .. "\n" .. StringUtil.MakeColorFormat("->" .. weightInfo.Item .. ":\229\142\159" .. weightInfo.Weight .. ":\231\142\176" .. weightInfo[SpreadSmartWeightKey], weightInfo.Weight ~= weightInfo[SpreadSmartWeightKey] and greenColor or whiteColor)
          end
        end
      else
        text = text .. "\230\151\160\239\188\140\231\173\137\231\186\167\228\184\141\230\187\161\232\182\179\239\188\154\n\231\173\137\231\186\167\229\140\186\233\151\180:"
        for _, config in ipairs(self.m_mapGeneratorType2Config[type]) do
          text = text .. "[" .. tostring(config.level_min or "-\230\151\160\231\169\183") .. "," .. tostring(config.level_max or "+\230\151\160\231\169\183") .. "] "
        end
      end
    else
      text = text .. "\230\151\160\n"
    end
  end
  local ratioAdjustTextStr = ""
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.AdjustLuckyProduceBoostRatio) then
    local averageRatio = 0
    if 0 < #self.m_cachedBoostRatioAdjustData then
      for _, boostRatio in ipairs(self.m_cachedBoostRatioAdjustData) do
        averageRatio = averageRatio + boostRatio
      end
      averageRatio = averageRatio / #self.m_cachedBoostRatioAdjustData
    end
    ratioAdjustTextStr = "\n-----\229\128\141\231\142\135\232\176\131\230\149\180\229\188\128-----\n\229\128\141\231\142\135\230\149\176\230\141\174:" .. table.concat(self.m_cachedBoostRatioAdjustData, ",") .. "\n\232\176\131\230\149\180\229\144\142\229\128\141\231\142\135:x" .. MathUtil.IntPow(2, self:GetAdjustedMaxEnergyBoostRatio(GM.EnergyBoostModel:GetEnergyBoostPowerRatio())) .. (#self.m_cachedBoostRatioAdjustData == 0 and "\n" or "(" .. averageRatio .. ")\n")
  else
    ratioAdjustTextStr = "\n-----\229\128\141\231\142\135\232\176\131\230\149\180\229\133\179-----\n"
  end
  text = text .. StringUtil.MakeColorFormat(ratioAdjustTextStr, ratioAdjustColor)
  local specialTextStr = ""
  if self:_IsSpecialModeOn() then
    specialTextStr = "-----\231\137\185\230\174\138\230\168\161\229\188\143\229\188\128-----\n"
    local curEnergyCost = self:_GetEnergyCostCount()
    specialTextStr = specialTextStr .. "\229\189\147\229\137\141\230\182\136\232\128\151\232\131\189\233\135\143:" .. curEnergyCost .. "\n"
    local config = self.m_arrLuckyProduceConfig[self:_GetCurLuckyProduceConfigIndex()]
    if config == nil then
      specialTextStr = specialTextStr .. "\229\189\147\229\137\141\233\133\141\231\189\174\229\140\186\233\151\180:\230\151\160\n"
    else
      specialTextStr = specialTextStr .. "\229\189\147\229\137\141\233\133\141\231\189\174\229\140\186\233\151\180:[" .. table.concat(config.energy_cost.range_entry, ",") .. "]\n\228\186\140\232\191\158\230\166\130\231\142\135:" .. tostring(config.double_lucky_chance / 100) .. "%\n\228\184\137\232\191\158\230\166\130\231\142\135:" .. tostring(config.triple_lucky_chance / 100) .. "%\n"
    end
    local contiExpiredTimeStamp = self.m_dbTable:GetValue(DBKey.ContiLuckyProduceExpiredTimeStamp, DBColumnValue)
    local contiMaxCount = self.m_dbTable:GetValue(DBKey.ContiLuckyProduceMaxCount, DBColumnValue)
    local contiCurCount = self.m_dbTable:GetValue(DBKey.ContiLuckyProduceCount, DBColumnValue) or 0
    local curItemType = self.m_dbTable:GetValue(DBKey.ContiLuckyProduceItemType, DBColumnValue)
    local curServerTime = GM.GameModel:GetServerTime()
    if contiExpiredTimeStamp ~= nil and contiExpiredTimeStamp >= curServerTime and contiMaxCount > contiCurCount then
      specialTextStr = specialTextStr .. (contiMaxCount == 2 and "\229\189\147\229\137\141\229\164\132\228\186\142\228\184\137\232\191\158\229\185\184\232\191\144\229\150\183\229\143\145\228\184\173" or "\229\189\147\229\137\141\229\164\132\228\186\142\228\186\140\232\191\158\229\185\184\232\191\144\229\150\183\229\143\145\228\184\173") .. "\n" .. "\232\191\158\231\187\173\232\167\166\229\143\145\230\163\139\229\173\144\231\177\187\229\158\139:" .. tostring(curItemType) .. "\n" .. "\232\191\158\231\187\173\229\150\183\229\143\145\229\137\169\228\189\153\229\128\146\232\174\161\230\151\182:" .. tostring(math.max(0, contiExpiredTimeStamp - curServerTime)) .. "\231\167\146\n"
      if selectedItem ~= nil then
        local type = selectedItem:GetType()
        if type ~= curItemType then
          specialTextStr = specialTextStr .. StringUtil.MakeColorFormat("\229\189\147\229\137\141\230\163\139\229\173\144\228\184\141\229\143\175\232\167\166\229\143\145\232\191\158\231\187\173\229\185\184\232\191\144\n", redColor)
        else
          specialTextStr = specialTextStr .. StringUtil.MakeColorFormat("\229\189\147\229\137\141\230\163\139\229\173\144\229\143\175\232\167\166\229\143\145\232\191\158\231\187\173\229\185\184\232\191\144\n", greenColor)
        end
      end
    end
    specialTextStr = specialTextStr .. "\229\133\141\232\180\185\229\185\184\232\191\144\229\150\183\229\143\145[" .. table.concat(self.m_arrFreeLuckyProduceEnergyCostCount, ",") .. "]\n" .. (self:_CanFreeLuckyProduce() and StringUtil.MakeColorFormat("\229\143\175\232\167\166\229\143\145\229\133\141\232\180\185\229\185\184\232\191\144\229\150\183\229\143\145\n", greenColor) or StringUtil.MakeColorFormat("\228\184\141\229\143\175\232\167\166\229\143\145\229\133\141\232\180\185\229\185\184\232\191\144\229\150\183\229\143\145\n", redColor))
  else
    specialTextStr = "-----\231\137\185\230\174\138\230\168\161\229\188\143\229\133\179-----\n"
  end
  text = text .. StringUtil.MakeColorFormat(specialTextStr, specialColor)
  if LastProduceLuckyItemInfo ~= nil then
    text = text .. StringUtil.MakeColorFormat("---\228\184\138\228\184\128\230\172\161\229\150\183\229\143\145\228\191\161\230\129\175---\n" .. LastProduceLuckyItemInfo, lastSpreadColor)
  end
  return text
end
