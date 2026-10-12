TempItemNewRuleType = {
  DiffMoreBetterAndSameNoInterval = 1,
  DiffLessBetterAndSameNoInterval = 2,
  DiffMoreBetterAndAlwaysWithInterval = 3,
  DiffLessBetterAndAlwaysWithInterval = 4
}
TempItemModel = setmetatable({}, BaseActivityModel)
TempItemModel.__index = TempItemModel
TempItemModel.LastRoundEndTimeKey = "LastRoundEndTime"
TempItemModel.TargetTypeKey = "TargetType"
TempItemModel.StartTimerKey = "StartTimer"
TempItemModel.StartRecordedKey = "StartRecorded"
TempItemModel.LastTempItemChainId = "LastTempItemChainId"

function TempItemModel:Init(virtualDBTable)
  BaseActivityModel.Init(self, ActivityType.TempItem, virtualDBTable)
end

function TempItemModel:_LoadOtherServerConfig(config)
  local generalConfig = {
    RoundInterval = config.temp_item_general_config[1].interval * 60,
    TransferItem = config.temp_item_general_config[1].transfer_item,
    TriggerEnergy = config.temp_item_general_config[1].trigger_energy,
    TriggerGem = config.temp_item_general_config[1].trigger_gem,
    MainItemLevelOneCountDiffMin = config.temp_item_general_config[1].trigger_main_item_min,
    SubItemLevelOneCountDiffMin = config.temp_item_general_config[1].trigger_side_item_min,
    NewModeTriggerType = config.temp_item_general_config[1].trigger_type
  }
  self.m_config.General = generalConfig
  local ruleConfig = {}
  for _, data in ipairs(config.temp_item_rule_config) do
    ruleConfig[data.order_item] = self:_SortAndCheckTempItems(data.temp_items)
  end
  self.m_config.Rule = ruleConfig
  local durationConfig = {}
  local levelOneItemCountThresholdConfig = {}
  for _, data in ipairs(config.temp_item_duration) do
    durationConfig[data.temp_item] = data.duration
    levelOneItemCountThresholdConfig[data.temp_item] = data.trigger_item_min
  end
  self.m_config.Duration = durationConfig
  self.m_config.LevelOneItemCountThreshold = levelOneItemCountThresholdConfig
  self.m_config.NewMode = generalConfig.NewModeTriggerType ~= nil and generalConfig.MainItemLevelOneCountDiffMin ~= nil and generalConfig.SubItemLevelOneCountDiffMin ~= nil
end

function TempItemModel:_OnStateChanged()
  BaseActivityModel._OnStateChanged(self)
  EventDispatcher.DispatchEvent(EEventType.TempStateChanged)
  if self:GetState() == ActivityState.Started and self.m_dbTable:GetValue(TempItemModel.StartRecordedKey, "value") == nil then
    self:LogActivity(EBIType.ActivityStarted, "")
    self.m_dbTable:Set(TempItemModel.StartRecordedKey, "value", true)
  end
end

function TempItemModel:LateInit()
  self.m_lateInited = true
  self:_TryDeleteItems()
end

function TempItemModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_needDeleteItems = true
  self:_TryDeleteItems()
end

function TempItemModel:GetResourceLabels()
  return {
    AddressableLabel.TempItem
  }
end

function TempItemModel:_SortAndCheckTempItems(tempItems)
  local results = Table.ShallowCopy(tempItems)
  table.sort(results, function(a, b)
    local levelA = GM.ItemDataModel:GetChainLevel(a)
    local levelB = GM.ItemDataModel:GetChainLevel(b)
    return levelA < levelB
  end)
  for i = 1, #tempItems do
    if results[i] ~= tempItems[i] then
      GM.BIManager:LogErrorInfo(EBIType.TempCheckConfig, "temp_items order error")
      break
    end
  end
  return results
end

function TempItemModel:GetTransformTargetType()
  return self.m_config.General.TransferItem
end

function TempItemModel:GetItemStartTimer()
  local startTimer = self.m_dbTable:GetValue(TempItemModel.StartTimerKey, "value")
  assert(startTimer ~= 0)
  return startTimer
end

function TempItemModel:GetItemDuration(innerType)
  return self.m_config.Duration[innerType] or 60
end

function TempItemModel:GetLevelOneCountThreshold(itemType)
  if self.m_config.LevelOneItemCountThreshold[itemType] ~= nil then
    return self.m_config.LevelOneItemCountThreshold[itemType]
  else
    return MapItemSubChain[GM.ItemDataModel:GetChainId(itemType)] ~= nil and self.m_config.General.SubItemLevelOneCountDiffMin or self.m_config.General.MainItemLevelOneCountDiffMin
  end
end

function TempItemModel:GenerateType(mergedItemType)
  if not self:_CanGenerateTempItem() then
    return nil
  end
  local generateType, needUpload
  if self.m_config.NewMode then
    generateType, needUpload = self:_GenerateTypeNew(mergedItemType)
  else
    generateType, needUpload = self:_GenerateTypeOld(mergedItemType)
  end
  if generateType ~= nil then
    self.m_dbTable:Set(TempItemModel.StartTimerKey, "value", GM.GameModel:GetServerTime())
    self.m_dbTable:Set(TempItemModel.LastTempItemChainId, "value", GM.ItemDataModel:GetChainId(generateType))
    if needUpload then
      GM.SyncModel:CheckMoreUpload(nil, true)
    end
  end
  return generateType
end

function TempItemModel:_GenerateTypeOld(mergedItemType)
  if not self:_CheckLastRoundEndTime() then
    return nil
  end
  local targetType = self.m_dbTable:GetValue(TempItemModel.TargetTypeKey, "value")
  if targetType == nil then
    if not self:_CanTrigger2GenerateTempItem() then
      return nil
    end
    targetType = self:_GenerateTargetTypeOld(mergedItemType)
    if targetType == nil then
      return nil
    end
    self.m_dbTable:Set(TempItemModel.TargetTypeKey, "value", targetType)
  end
  local mergedItemChain = GM.ItemDataModel:GetChainId(mergedItemType)
  local targetChain = GM.ItemDataModel:GetChainId(targetType)
  if mergedItemChain ~= targetChain then
    return nil
  end
  local innerType
  local mergedItemLevel = GM.ItemDataModel:GetChainLevel(mergedItemType)
  local innerTypes = self.m_config.Rule[targetType]
  local isTopTempItem = false
  for index, type in ipairs(innerTypes) do
    local level = GM.ItemDataModel:GetChainLevel(type)
    if mergedItemLevel < level then
      innerType = type
      if index == #innerTypes then
        isTopTempItem = true
      end
      break
    end
  end
  if innerType == nil then
    self:MarkRoundEnd()
    return nil
  end
  return innerType, isTopTempItem
end

function TempItemModel:_GenerateTargetTypeOld(mergedItemType)
  local mergedItemChain = GM.ItemDataModel:GetChainId(mergedItemType)
  local mergedItemLevel = GM.ItemDataModel:GetChainLevel(mergedItemType)
  local codeCountMap = GM.MainBoardModel:GetCodeCountMap(true, false, true)
  local lackCodeCountMap = GM.MainBoardModel:GetOrderCodeLackCountMap()
  local targetLevel
  for itemType, _ in pairs(lackCodeCountMap) do
    if self:_IsTargetTypeValidOld(itemType, mergedItemChain, mergedItemLevel, codeCountMap) then
      local level = GM.ItemDataModel:GetChainLevel(itemType)
      if targetLevel == nil or targetLevel > level then
        targetLevel = level
      end
    end
  end
  if targetLevel == nil then
    return nil
  end
  return GM.ItemDataModel:GetTypeByChainAndLevel(mergedItemChain, targetLevel)
end

local TestTargetTypeInvalidReason = {
  ChainIdNotMatch = 0,
  NotInTriggerRule = 1,
  LevelOneCountNotMatch = 2,
  HasPreviosLevel1 = 3,
  HasPreviosLevel2 = 4,
  MergedLevelTooHigh = 5
}

function TempItemModel:_IsTargetTypeValidOld(targetType, mergedItemChain, mergedItemLevel, codeCountMap)
  if mergedItemChain ~= GM.ItemDataModel:GetChainId(targetType) then
    return false, TestTargetTypeInvalidReason.ChainIdNotMatch
  end
  local tempItemTypes = self.m_config.Rule[targetType]
  if tempItemTypes == nil then
    return false, TestTargetTypeInvalidReason.NotInTriggerRule
  end
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.TempItemTriggerAdvanced) then
    if not self:_CheckMergedMaxLevelOld(codeCountMap, targetType) then
      return false, TestTargetTypeInvalidReason.LevelOneCountNotMatch
    end
  else
    local targetLevel = GM.ItemDataModel:GetChainLevel(targetType)
    local previousLevelItemType = GM.ItemDataModel:GetTypeByChainAndLevel(mergedItemChain, targetLevel - 1)
    if codeCountMap[previousLevelItemType] ~= nil then
      return false, TestTargetTypeInvalidReason.HasPreviosLevel1
    end
    if 2 < targetLevel then
      previousLevelItemType = GM.ItemDataModel:GetTypeByChainAndLevel(mergedItemChain, targetLevel - 2)
      if codeCountMap[previousLevelItemType] ~= nil then
        return false, TestTargetTypeInvalidReason.HasPreviosLevel2
      end
    end
  end
  for _, type in ipairs(tempItemTypes) do
    local level = GM.ItemDataModel:GetChainLevel(type)
    if mergedItemLevel < level then
      return true
    end
  end
  return false, TestTargetTypeInvalidReason.MergedLevelTooHigh
end

function TempItemModel:_CheckMergedMaxLevelOld(codeCountMap, targetType)
  return self:_GetLevelOneCount(codeCountMap, targetType) < self:_GetCheckLevelOneCountOld(targetType)
end

function TempItemModel:_GetCheckLevelOneCountOld(targetType)
  local chainLevel = GM.ItemDataModel:GetChainLevel(targetType)
  return math.floor(2 ^ math.max(chainLevel - 3, 0))
end

function TempItemModel:_GenerateTypeNew(mergedItemType)
  local targetType = self.m_dbTable:GetValue(TempItemModel.TargetTypeKey, "value")
  if targetType ~= nil then
    self:_ClearTargetType()
  end
  if not self:_CanTrigger2GenerateTempItem() then
    return nil
  end
  local chainId = GM.ItemDataModel:GetChainId(mergedItemType)
  if not self:_CheckInTriggerType(chainId) then
    return nil
  end
  local targetType = self:_GenerateTargetTypeNew(mergedItemType)
  if targetType ~= nil then
    self.m_dbTable:Set(TempItemModel.TargetTypeKey, "value", targetType)
  end
  return targetType, targetType ~= nil
end

function TempItemModel:_GenerateTargetTypeNew(mergedItemType, customCodeCountMap)
  local chainId = GM.ItemDataModel:GetChainId(mergedItemType)
  local chainLevel = GM.ItemDataModel:GetChainLevel(mergedItemType)
  local codeCountMap = customCodeCountMap or GM.MainBoardModel:GetCodeCountMap(true, false, true)
  local lackCodeCountMap = GM.MainBoardModel:GetOrderCodeLackCountMap()
  local diffs, types = self:_GetLevelOneCountDiffs(chainId, codeCountMap)
  local availableMaxChainLevel = 0
  for itemType, _ in pairs(lackCodeCountMap) do
    local checkChainId = GM.ItemDataModel:GetChainId(itemType)
    if checkChainId == chainId and self.m_config.Rule[itemType] ~= nil then
      local checkChainLevel = GM.ItemDataModel:GetChainLevel(itemType)
      if diffs[checkChainLevel] > self:GetLevelOneCountThreshold(itemType) and availableMaxChainLevel < checkChainLevel then
        availableMaxChainLevel = checkChainLevel
      end
    end
  end
  if availableMaxChainLevel == 0 then
    return nil
  end
  local selectedLevel = 0
  local bDiffMoreBetter = self:_IsDiffMoreBetterMode()
  for i = chainLevel + 1, availableMaxChainLevel - 1 do
    if diffs[i] > self:GetLevelOneCountThreshold(types[i]) and (selectedLevel == 0 or bDiffMoreBetter and diffs[i] >= diffs[selectedLevel] or not bDiffMoreBetter and diffs[i] <= diffs[selectedLevel]) then
      selectedLevel = i
    end
  end
  if selectedLevel == 0 then
    for i = 1, math.min(chainLevel, availableMaxChainLevel - 1) do
      if diffs[i] > self:GetLevelOneCountThreshold(types[i]) and (selectedLevel == 0 or bDiffMoreBetter and diffs[i] >= diffs[selectedLevel] or not bDiffMoreBetter and diffs[i] <= diffs[selectedLevel]) then
        selectedLevel = i
      end
    end
  end
  if selectedLevel == 0 then
    return nil
  end
  return GM.ItemDataModel:GetTypeByChainAndLevel(chainId, selectedLevel)
end

function TempItemModel:_CheckInTriggerType(chainId)
  return self:_CheckLastRoundEndTime() or self:_IsSameChainIdWithNoIntervalAllowed() and self:_CheckLastTempItemChainId(chainId)
end

function TempItemModel:_IsSameChainIdWithNoIntervalAllowed()
  return self.m_config.General.NewModeTriggerType == TempItemNewRuleType.DiffMoreBetterAndSameNoInterval or self.m_config.General.NewModeTriggerType == TempItemNewRuleType.DiffLessBetterAndSameNoInterval
end

function TempItemModel:_IsDiffMoreBetterMode()
  return self.m_config.General.NewModeTriggerType == TempItemNewRuleType.DiffMoreBetterAndAlwaysWithInterval or self.m_config.General.NewModeTriggerType == TempItemNewRuleType.DiffMoreBetterAndSameNoInterval
end

function TempItemModel:_GetLevelOneCountDiffs(chainId, codeCountMap)
  local types = GM.ItemDataModel:GetChain(chainId)
  local diffs = {}
  local power2Ratio = 1
  local totalLevelOneCount = 0
  for _, type in ipairs(types) do
    totalLevelOneCount = totalLevelOneCount + (codeCountMap[type] or 0) * power2Ratio
    diffs[#diffs + 1] = power2Ratio - totalLevelOneCount
    power2Ratio = power2Ratio * 2
  end
  return diffs, types
end

function TempItemModel:_CanGenerateTempItem()
  return self:GetState() == ActivityState.Started and self:_CheckExistedTempItem()
end

function TempItemModel:_CheckExistedTempItem()
  if self.m_tempItemFilter == nil then
    function self.m_tempItemFilter(itemModel)
      return itemModel:GetComponent(ItemTemp) ~= nil
    end
  end
  return #GM.MainBoardModel:FilterItems(self.m_tempItemFilter) == 0
end

function TempItemModel:_CanTrigger2GenerateTempItem()
  return self:_CheckEnergy() and self:_CheckGem() and self:_CheckEnergyNotInfinite()
end

function TempItemModel:_CheckEnergy()
  return not self.m_config.General.TriggerEnergy or GM.EnergyModel:GetEnergy(EnergyType.Main) <= self.m_config.General.TriggerEnergy
end

function TempItemModel:_CheckGem()
  return not self.m_config.General.TriggerGem or GM.ShopModel:GetEnergyCostExcludeFree() >= self.m_config.General.TriggerGem
end

function TempItemModel:_CheckEnergyNotInfinite()
  return not GM.EnergyModel:IsEnergyInfinite(EnergyType.Main)
end

function TempItemModel:_CheckLastRoundEndTime()
  local lastRoundEndTime = self.m_dbTable:GetValue(TempItemModel.LastRoundEndTimeKey, "value") or 0
  return GM.GameModel:GetServerTime() - lastRoundEndTime > self.m_config.General.RoundInterval
end

function TempItemModel:_CheckLastTempItemChainId(chainId)
  return self.m_dbTable:GetValue(TempItemModel.LastTempItemChainId, "value") == chainId
end

function TempItemModel:_GetLevelOneCount(codeCountMap, targetType)
  local chainId = GM.ItemDataModel:GetChainId(targetType)
  local chainLevel = GM.ItemDataModel:GetChainLevel(targetType)
  local itemTypes = GM.ItemDataModel:GetChain(chainId)
  local levelOneCount = 0
  for itemLevel, itemType in pairs(itemTypes) do
    if itemLevel <= chainLevel and codeCountMap[itemType] ~= nil then
      levelOneCount = levelOneCount + codeCountMap[itemType] * math.floor(2 ^ (itemLevel - 1))
    end
  end
  return levelOneCount
end

function TempItemModel:MarkRoundEnd()
  self:_ClearTargetType()
  self.m_dbTable:Set(TempItemModel.LastTempItemChainId, "value", nil)
end

function TempItemModel:_ClearTargetType()
  self.m_dbTable:Set(TempItemModel.TargetTypeKey, "value", nil)
  self.m_dbTable:Set(TempItemModel.LastRoundEndTimeKey, "value", GM.GameModel:GetServerTime())
end

function TempItemModel:_TryDeleteItems()
  if self.m_lateInited and self.m_needDeleteItems then
    self.m_needDeleteItems = false
    GM.MainBoardModel:RemoveItemsInChainList({
      ItemChain.Temp
    })
  end
end

function TempItemModel:GetTestInfo()
  local cost = GM.ShopModel:GetEnergyCostExcludeFree()
  local bOpen = self.m_state == ActivityState.Started
  local str = "\229\164\132\228\186\142\229\188\128\229\144\175\230\151\182\233\151\180:" .. tostring(bOpen)
  if bOpen then
    str = str .. "\n\228\189\147\229\138\155:" .. tostring(self:_CheckEnergy()) .. " \233\146\187\231\159\179:" .. tostring(self:_CheckGem()) .. "\n\228\184\141\230\152\175\230\151\160\233\153\144\228\189\147\229\138\155:" .. tostring(self:_CheckEnergyNotInfinite()) .. "\n\229\134\183\229\141\180\230\151\182\233\151\180\239\188\154" .. tostring(self:_CheckLastRoundEndTime()) .. "\n\229\134\183\229\141\180\230\129\162\229\164\141\230\151\182\233\151\180\231\130\185:" .. TimeUtil.ToDate((self.m_dbTable:GetValue(TempItemModel.LastRoundEndTimeKey, "value") or 0) + self.m_config.General.RoundInterval, ETimeFormat.YMDHMS) .. "\n----\232\174\162\229\141\149\230\163\139\229\173\144\232\167\166\229\143\145\228\191\161\230\129\175----\n" .. tostring(self.m_config.NewMode and self:_TestGetChainIdsNew() or self:_TestGetChainIdsOld())
  end
  return str
end

local invalidReason2Text = {
  [TestTargetTypeInvalidReason.LevelOneCountNotMatch] = "(\229\144\136\230\136\144\229\144\142\230\163\139\229\173\144\228\184\141\230\187\161\232\182\179)",
  [TestTargetTypeInvalidReason.HasPreviosLevel1] = "(\229\173\152\229\156\168\228\184\138\231\186\167\230\163\139\229\173\144)",
  [TestTargetTypeInvalidReason.HasPreviosLevel2] = "(\229\173\152\229\156\168\228\184\138\228\184\138\231\186\167\230\163\139\229\173\144)"
}

function TempItemModel:_TestGetChainIdsOld()
  local printStr = "[\230\151\167\230\168\161\229\188\143]\n\229\188\128\229\144\175\228\188\152\229\140\150:" .. tostring(GM.ConfigModel:IsServerControlOpen(EGeneralConfType.TempItemTriggerAdvanced))
  local codeCountMap = GM.MainBoardModel:GetCodeCountMap(true, false, true)
  local lackCodeCountMap = GM.MainBoardModel:GetOrderCodeLackCountMap()
  for itemType, _ in pairs(lackCodeCountMap) do
    local singleStr = ""
    local valid, reason = self:_IsTargetTypeValidOld(itemType, GM.ItemDataModel:GetChainId(itemType), 1, codeCountMap)
    if valid then
      local levelOneInfo = ""
      if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.TempItemTriggerAdvanced) then
        levelOneInfo = "[" .. self:_GetLevelOneCount(codeCountMap, itemType) .. "/" .. self:_GetCheckLevelOneCountOld(itemType) .. "]"
      end
      singleStr = itemType .. ":" .. tostring(valid) .. levelOneInfo .. ", "
    elseif invalidReason2Text[reason] ~= nil then
      local levelOneInfo = ""
      if reason == TestTargetTypeInvalidReason.LevelOneCountNotMatch then
        levelOneInfo = "[" .. self:_GetLevelOneCount(codeCountMap, itemType) .. "/" .. self:_GetCheckLevelOneCountOld(itemType) .. "]"
      end
      singleStr = itemType .. ":" .. tostring(valid) .. " " .. invalidReason2Text[reason] .. levelOneInfo .. ", "
    end
    if not StringUtil.IsNilOrEmpty(singleStr) then
      printStr = printStr .. "\n" .. singleStr
    end
  end
  return printStr
end

local greenColor = "#aafaaa"
local redColor = "#f2b3b3"
local yellowColor = "#f5f5b1"

function TempItemModel:_TestGetChainIdsNew()
  local printStr = "[\230\150\176\230\168\161\229\188\143]\n\228\184\138\228\184\128\230\172\161\228\184\180\230\151\182\230\163\139\229\173\144\229\144\136\230\136\144\233\147\190ID:" .. (self.m_dbTable:GetValue(TempItemModel.LastTempItemChainId, "value") or "\230\151\160")
  local ruleType = [[

trigger_type:]] .. tostring(self.m_config.General.NewModeTriggerType) .. (self:_IsDiffMoreBetterMode() and "\n\230\140\137\229\183\174\229\128\188\230\155\180\229\164\167\231\154\132\228\186\167\231\148\159" or "\n\230\140\137\229\183\174\229\128\188\230\155\180\229\176\143\231\154\132\228\186\167\231\148\159") .. (self:_IsSameChainIdWithNoIntervalAllowed() and "\n\229\133\129\232\174\184\230\151\160\233\151\180\233\154\148\231\148\159\230\136\144\229\144\140\229\144\136\230\136\144\231\186\191" or "\n\228\184\141\229\133\129\232\174\184\230\151\160\233\151\180\233\154\148\231\148\159\230\136\144\229\144\140\229\144\136\230\136\144\231\186\191")
  printStr = printStr .. ruleType
  local selectedItem = MainBoardView.GetInstance():GetSelectedItemModel()
  if selectedItem == nil then
    printStr = printStr .. "\n\233\128\137\228\184\173\230\163\139\229\173\144:\230\151\160"
    return printStr
  end
  if not self:_CanTrigger2GenerateTempItem() then
    printStr = printStr .. "\n\229\189\147\229\137\141\230\157\161\228\187\182\230\151\160\230\179\149\232\167\166\229\143\145\228\184\180\230\151\182\230\163\139\229\173\144"
    return printStr
  end
  local itemType = selectedItem:GetType()
  if itemType == ItemType.Temp then
    local itemTempComponent = selectedItem:GetComponent(ItemTemp)
    if itemTempComponent ~= nil then
      itemType = itemTempComponent:GetInnerItemCode()
    end
  end
  local chainId = GM.ItemDataModel:GetChainId(itemType)
  local chainLevel = GM.ItemDataModel:GetChainLevel(itemType)
  printStr = printStr .. "\n\230\152\175\229\144\166\230\151\160\232\167\134\229\134\183\229\141\180\230\151\182\233\151\180:" .. tostring(self:_IsSameChainIdWithNoIntervalAllowed() and self:_CheckLastTempItemChainId(chainId))
  if not self:_CheckInTriggerType(chainId) then
    printStr = printStr .. "\n\229\189\147\229\137\141\230\151\182\233\151\180\230\151\160\230\179\149\232\167\166\229\143\145\230\150\176\231\154\132\228\184\128\232\189\174\228\184\180\230\151\182\230\163\139\229\173\144"
    return printStr
  end
  local codeCountMap = GM.MainBoardModel:GetCodeCountMap(true, false, true)
  local lackCodeCountMap = GM.MainBoardModel:GetOrderCodeLackCountMap()
  local bTempItemExisted = not self:_CheckExistedTempItem()
  local tempItemInnerTypes = {}
  if bTempItemExisted then
    local tempItems = GM.MainBoardModel:FilterItems(self.m_tempItemFilter)
    for _, item in ipairs(tempItems) do
      local itemTempComponent = item:GetComponent(ItemTemp)
      if itemTempComponent ~= nil then
        local innerType = itemTempComponent:GetInnerItemCode()
        codeCountMap[innerType] = (codeCountMap[innerType] or 0) + 1
        tempItemInnerTypes[#tempItemInnerTypes + 1] = innerType
      end
    end
  end
  if codeCountMap[itemType] ~= nil and 2 <= codeCountMap[itemType] and chainLevel < GM.ItemDataModel:GetChainMaxLevel(chainId) then
    codeCountMap[itemType] = codeCountMap[itemType] - 2
    local nextItemType = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, chainLevel + 1)
    codeCountMap[nextItemType] = (codeCountMap[nextItemType] or 0) + 1
    printStr = printStr .. "\n\229\177\149\231\164\186\229\144\136\229\185\182\233\128\137\228\184\173\230\163\139\229\173\144\229\144\142\233\128\187\232\190\145:\n1\231\186\167\230\163\139\229\173\144\230\149\176\233\135\143\232\161\168(\229\144\171\229\156\186\228\184\138\228\184\180\230\151\182\230\163\139\229\173\144):\n\231\173\137\231\186\167:\233\152\136\229\128\188->\229\183\174\229\128\188(\231\142\1761-\229\186\147\229\173\152*1\231\186\167-\231\180\175\232\174\1611):\n"
  else
    printStr = printStr .. "\n\229\177\149\231\164\186\229\189\147\229\137\141\233\128\187\232\190\145:\n1\231\186\167\230\163\139\229\173\144\230\149\176\233\135\143\232\161\168(\229\144\171\229\156\186\228\184\138\228\184\180\230\151\182\230\163\139\229\173\144):\n\231\173\137\231\186\167:\233\152\136\229\128\188->\229\183\174\229\128\188(\231\142\1761-\229\186\147\229\173\152*1\231\186\167-\231\180\175\232\174\1611):\n"
  end
  local types = GM.ItemDataModel:GetChain(chainId)
  local diffs = {}
  local power2Ratio = 1
  local totalLevelOneCount = 0
  for i, type in ipairs(types) do
    local lastTotal = totalLevelOneCount
    totalLevelOneCount = totalLevelOneCount + (codeCountMap[type] or 0) * power2Ratio
    diffs[#diffs + 1] = power2Ratio - totalLevelOneCount
    local levelOneCountThreshold = self:GetLevelOneCountThreshold(type)
    local color = levelOneCountThreshold < diffs[i] and (chainLevel < i and greenColor or yellowColor) or redColor
    local tempItem = Table.ListContain(tempItemInnerTypes, type)
    local codeCountStr = tempItem and StringUtil.MakeColorFormat(tostring(codeCountMap[type] or 0), redColor) or tostring(codeCountMap[type] or 0)
    printStr = printStr .. tostring(i) .. ":" .. StringUtil.MakeColorFormat(tostring(levelOneCountThreshold) .. "->" .. tostring(diffs[i]), color) .. "(" .. tostring(power2Ratio) .. "-" .. codeCountStr .. "*" .. tostring(power2Ratio) .. "-" .. lastTotal .. ")\n"
    power2Ratio = power2Ratio * 2
  end
  printStr = printStr .. "\n\229\144\140\229\144\136\230\136\144\231\186\191\231\188\186\229\164\177\232\174\162\229\141\149\230\163\139\229\173\144\231\138\182\230\128\129:"
  local hasSameChainIdItem = false
  for itemType, _ in pairs(lackCodeCountMap) do
    local checkChainId = GM.ItemDataModel:GetChainId(itemType)
    if checkChainId == chainId then
      hasSameChainIdItem = true
      if self.m_config.Rule[itemType] == nil then
        printStr = printStr .. "\n" .. StringUtil.MakeColorFormat(itemType .. ":temp_item_rule_config\230\156\170\229\140\133\229\144\171", redColor)
      else
        local checkChainLevel = GM.ItemDataModel:GetChainLevel(itemType)
        if diffs[checkChainLevel] <= self:GetLevelOneCountThreshold(itemType) then
          printStr = printStr .. "\n" .. StringUtil.MakeColorFormat(itemType .. ":\229\144\140\229\144\136\230\136\144\231\186\191\232\174\162\229\141\149\230\163\139\229\173\144\229\183\174\229\128\188\229\176\143\228\186\142\233\152\136\229\128\188", redColor)
        else
          printStr = printStr .. "\n" .. StringUtil.MakeColorFormat(itemType .. ":\230\187\161\232\182\179\230\157\161\228\187\182", greenColor)
        end
      end
    end
  end
  if not hasSameChainIdItem then
    printStr = printStr .. "\n\230\151\160\229\175\185\229\186\148\230\163\139\229\173\144"
  end
  printStr = printStr .. "\n\230\163\139\229\173\144\233\128\137\230\139\169:" .. tostring(self:_GenerateTargetTypeNew(itemType, codeCountMap) or "\230\151\160")
  if bTempItemExisted then
    printStr = printStr .. "\n" .. StringUtil.MakeColorFormat("\229\189\147\229\137\141\229\183\178\230\156\137\228\184\180\230\151\182\230\163\139\229\173\144", redColor)
  end
  return printStr
end
