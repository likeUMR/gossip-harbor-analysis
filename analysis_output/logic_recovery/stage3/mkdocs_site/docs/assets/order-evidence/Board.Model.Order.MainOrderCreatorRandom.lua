local DBColumnValue = "value"
local DBColumnRandomBaselineLastGenerateTimer = "RandomBaselineLastGenerateTimer"

local function ForceCreateOrder(slot)
  local orderBooostModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  if orderBooostModel:GetAddSmileScoreBySlot(slot) > 0 then
    return true
  end
  local puzzleModel = GM.ActivityManager:GetModel(ActivityType.Puzzle)
  if 0 < puzzleModel:GetSlotTokenNumber(slot) then
    return true
  end
  local butterflyModel = GM.ActivityManager:GetStartedButterflyActivity()
  if butterflyModel and butterflyModel:GetForceCreateSlot() == slot then
    return true
  end
  if GM.CustomerUpgradeRewardModel:CanFillChestCustomerOrder() then
    return true
  end
  if GameConfig.IsTestMode() and TestCreateOrderWindow ~= nil and TestCreateOrderWindow.CanCreateTmpOrder(slot) then
    return true
  end
  return false
end

RepeatWeightDecreaseHelper = {}

function RepeatWeightDecreaseHelper.CanSupportDecreaseRule(InnerType)
  if InnerType == MainOrderType.Random1 or InnerType == MainOrderType.Random2 or InnerType == MainOrderType.Random3 or InnerType == MainOrderType.Random4 or InnerType == MainOrderType.Random5New or InnerType == MainOrderType.Contiorder then
    return true
  end
  return false
end

function RepeatWeightDecreaseHelper.InitMapInfo(innerType, orderModel)
  if RepeatWeightDecreaseHelper.CanSupportDecreaseRule(innerType) then
    local info = {}
    info.mapChainRepeatWeight = orderModel:GetRepeatWeightDecrease()
    info.SelectedSynthesisLine = {}
    info.TestLogInfo = {}
    return info
  else
    return nil
  end
end

function RepeatWeightDecreaseHelper.DecreaseItemWeight(availableItems, mapRepeatWeightDecreaseInfo, orderModel)
  if mapRepeatWeightDecreaseInfo ~= nil then
    mapRepeatWeightDecreaseInfo.TestLogInfo = {}
    local itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
    for _, itemInfo in ipairs(availableItems) do
      local mapChainRepeatWeight = mapRepeatWeightDecreaseInfo.mapChainRepeatWeight
      local itemCode = itemInfo.Code
      local chainId = GM.ItemDataModel:GetChainId(itemCode)
      local itemConfig = itemCodeConfigMap[itemCode]
      if mapChainRepeatWeight[chainId] ~= nil and itemConfig.RepeatWeightDecrease ~= nil then
        local oldWeight = itemInfo.Weight
        itemInfo.Weight = itemInfo.Weight / itemConfig.RepeatWeightDecrease
        mapRepeatWeightDecreaseInfo.SelectedSynthesisLine[chainId] = true
        if GameConfig.IsTestMode() then
          mapRepeatWeightDecreaseInfo.TestLogInfo[itemCode] = {}
          mapRepeatWeightDecreaseInfo.TestLogInfo[itemCode].Weight = oldWeight
          mapRepeatWeightDecreaseInfo.TestLogInfo[itemCode].repeatWeightDecrease = itemConfig.RepeatWeightDecrease
          mapRepeatWeightDecreaseInfo.TestLogInfo[itemCode].CurWeight = itemInfo.Weight
        end
      end
    end
  end
end

function RepeatWeightDecreaseHelper.MarkSelectedLine(selectedItem, mapRepeatWeightDecreaseInfo, orderModel)
  if mapRepeatWeightDecreaseInfo and orderModel:GetItemCodeConfigMap()[selectedItem].RepeatWeightDecrease ~= nil then
    local chainID = GM.ItemDataModel:GetChainId(selectedItem)
    if mapRepeatWeightDecreaseInfo.mapChainRepeatWeight[chainID] then
      mapRepeatWeightDecreaseInfo.SelectedSynthesisLine[chainID] = false
    end
  end
end

function RepeatWeightDecreaseHelper.UpdateMapInfo(mapRepeatWeightDecreaseInfo, orderModel)
  if mapRepeatWeightDecreaseInfo ~= nil then
    orderModel:UpdateRepeatWeightDecrease(mapRepeatWeightDecreaseInfo.SelectedSynthesisLine)
  end
end

RandomOrderHelper = {}

function RandomOrderHelper.CanCreate(orderModel, dbColumnStartTimer, randomConfig)
  local metaData = orderModel:GetMetaData()
  local startTimer = metaData:GetValue(dbColumnStartTimer, DBColumnValue)
  startTimer = startTimer and tonumber(startTimer)
  local point = randomConfig.Point or 1
  local orderPoints = 0
  if startTimer == 0 then
    local tmpPt = metaData:GetValue(MainOrderDBRandomPoint[randomConfig.Type], DBColumnValue)
    if tmpPt == nil or tmpPt == "" then
      tmpPt = point
    end
    orderPoints = tonumber(tmpPt)
    if orderPoints == 0 then
      startTimer = GM.GameModel:GetServerTime()
      metaData:Set(dbColumnStartTimer, DBColumnValue, tostring(startTimer))
      if GameConfig.IsTestMode() then
        local slot = Table.GetKey(MainOrderDBColumnRandomStartTimer, dbColumnStartTimer) or dbColumnStartTimer
        Log.Info("[\233\154\143\230\156\186\232\174\162\229\141\149][Slot/Timer:" .. slot .. "]\232\174\162\229\141\149CanCreate\239\188\140\232\174\190\231\189\174\229\189\147\229\137\141\230\151\182\233\151\180\228\184\186StartTimer")
      end
    end
  elseif startTimer == nil or GM.GameModel:GetServerTime() - startTimer >= randomConfig.RefreshTime then
    orderPoints = point
    metaData:Set(dbColumnStartTimer, DBColumnValue, "0")
    if GameConfig.IsTestMode() then
      local slot = Table.GetKey(MainOrderDBColumnRandomStartTimer, dbColumnStartTimer) or dbColumnStartTimer
      Log.Info("[\233\154\143\230\156\186\232\174\162\229\141\149][Slot/Timer:" .. slot .. "]CD\231\187\147\230\157\159, \229\143\175\228\187\165\229\136\155\229\187\186\230\150\176\233\154\143\230\156\186\232\174\162\229\141\149")
    end
  end
  if orderPoints == 0 then
    local slot = Table.GetKey(MainOrderDBColumnRandomStartTimer, dbColumnStartTimer) or dbColumnStartTimer
    if ForceCreateOrder(slot) then
      startTimer = GM.GameModel:GetServerTime()
      metaData:Set(dbColumnStartTimer, DBColumnValue, "0")
      metaData:Set(MainOrderDBRandomPoint[randomConfig.Type], DBColumnValue, "0")
      return true
    end
    return false
  end
  orderPoints = orderPoints - 1
  metaData:Set(MainOrderDBRandomPoint[randomConfig.Type], DBColumnValue, tostring(orderPoints))
  return true
end

function RandomOrderHelper.Create(ParamInfo)
  local orderModel = ParamInfo.orderModel
  local slot = ParamInfo.slot
  local innerType = ParamInfo.innerType
  local firstSelectedItem = ParamInfo.firstSelectedItem
  local secondSelectedItem = ParamInfo.secondSelectedItem
  local thirdSelectedItem = ParamInfo.thirdSelectedItem
  local avatarId = ParamInfo.avatarId
  local diffRange = ParamInfo.diffRange
  local mapRepeatWeightDecreaseInfo = ParamInfo.mapRepeatWeightDecreaseInfo
  local weightConfig
  local randomConfig = ParamInfo.randomConfig
  Log.Assert(randomConfig ~= nil, "\232\174\162\229\141\149\232\167\132\229\136\153randomOrderConfig\230\178\161\230\156\137\230\137\190\229\136\176 : " .. tostring(innerType))
  if randomConfig ~= nil and randomConfig.ItemAmounts ~= nil then
    weightConfig = randomConfig.ItemAmounts
  end
  
  local function funcCheckKey(weightConfig, key)
    if weightConfig[key] == nil then
      weightConfig[key] = 0
      return false
    end
    return true
  end
  
  if not Table.IsEmpty(weightConfig) then
    local bCheckFinish = funcCheckKey(weightConfig, "OneItemWeight")
    bCheckFinish = funcCheckKey(weightConfig, "TwoItemsWeight") or bCheckFinish
    bCheckFinish = funcCheckKey(weightConfig, "ThreeItemsWeight") or bCheckFinish
    if bCheckFinish == false then
      weightConfig = nil
      Log.Error("create random item num weight error!!!")
    end
  end
  local itemNumberWeightConfig = orderModel:GetItemNumberWeightConfig()
  local level = GM.LevelModel:GetCurrentLevel()
  if Table.IsEmpty(weightConfig) then
    for i = #itemNumberWeightConfig, 1, -1 do
      local config = itemNumberWeightConfig[i]
      if level >= config.Level then
        weightConfig = config
        break
      end
    end
  end
  Log.Assert(weightConfig ~= nil, "RandomOrderHelper.Create")
  local countWeightList = {}
  if firstSelectedItem ~= nil then
    table.insert(countWeightList, {
      Count = 1,
      Weight = weightConfig.OneItemWeight
    })
    if secondSelectedItem ~= nil then
      table.insert(countWeightList, {
        Count = 2,
        Weight = weightConfig.TwoItemsWeight
      })
      if thirdSelectedItem ~= nil then
        table.insert(countWeightList, {
          Count = 3,
          Weight = weightConfig.ThreeItemsWeight
        })
      end
    end
  elseif GameConfig.IsTestMode() then
    Log.Info("[\233\154\143\230\156\186\232\174\162\229\141\149][Slot:" .. slot .. "][InnerType:" .. innerType .. "]\231\172\172\228\184\128\228\184\170\233\156\128\230\177\130\230\163\139\229\173\144\229\143\175\233\128\137\229\136\151\232\161\168\228\184\186\231\169\186\239\188\140\230\151\160\230\179\149\229\136\155\229\187\186\232\174\162\229\141\149\239\188\140\232\175\183\230\159\165\231\156\139OrderRandomConfig\231\154\132Filters\233\133\141\231\189\174")
  end
  if #countWeightList == 0 then
    if GameConfig.IsTestMode() then
      TestOrderLogInfo.TestPrintOrderChosenItemsInfo({
        innerType = innerType,
        weightConfig = weightConfig,
        firstSelectedItem = firstSelectedItem,
        secondSelectedItem = secondSelectedItem,
        thirdSelectedItem = thirdSelectedItem,
        requirements = {},
        slot = slot,
        orderModel = orderModel,
        randomConfig = randomConfig
      })
    end
    return nil
  end
  local count = Table.ListWeightSelectOne(countWeightList).Count
  local requirements = {}
  table.insert(requirements, firstSelectedItem)
  if 2 <= count then
    table.insert(requirements, secondSelectedItem)
    if 3 <= count then
      table.insert(requirements, thirdSelectedItem)
    end
  end
  if GameConfig.IsTestMode() then
    TestOrderLogInfo.TestPrintOrderChosenItemsInfo({
      innerType = innerType,
      weightConfig = weightConfig,
      firstSelectedItem = firstSelectedItem,
      secondSelectedItem = secondSelectedItem,
      thirdSelectedItem = thirdSelectedItem,
      requirements = requirements,
      slot = slot,
      orderModel = orderModel,
      randomConfig = randomConfig,
      mapRepeatWeightDecreaseInfo = mapRepeatWeightDecreaseInfo
    })
  end
  avatarId = avatarId or orderModel:GetAvatarId()
  if ParamInfo.chestCustomModel ~= nil then
    avatarId = ParamInfo.chestCustomModel:CreateNewChestCustomerOrder(innerType, slot)
  end
  RepeatWeightDecreaseHelper.UpdateMapInfo(mapRepeatWeightDecreaseInfo, orderModel)
  return MainOrder.Create(orderModel, slot, nil, requirements, innerType, avatarId, nil, nil, diffRange)
end

function RandomOrderHelper.TryLuckyRandom(orderModel, slot, firstAvailableItems, secondAvailableItems, thirdAvailableItems)
  local targetLuckItems = {}
  local itemCodeNumByMapAndInventory = orderModel:GetCodeCountMap()
  local itemOrderRequireCode = {}
  for _, order in pairs(orderModel:GetOrders()) do
    local bFind = true
    if GameConfig.IsTestMode() and order.GetSlot and order:GetSlot() == slot then
      bFind = false
    end
    if bFind then
      local orderRequirements = order:GetRequirements()
      for k, itemCode in pairs(orderRequirements) do
        itemOrderRequireCode[itemCode] = true
      end
    end
  end
  
  local function GetAvailAbleItems(listItems)
    local target = {}
    for _, ele in pairs(listItems) do
      local code = ele.Code
      local weight = ele.Weight
      if 0 < weight and itemCodeNumByMapAndInventory[code] ~= nil and itemOrderRequireCode[code] == nil then
        table.insert(target, {
          Code = ele.Code,
          Weight = ele.Weight,
          CurNum = itemCodeNumByMapAndInventory[code]
        })
      end
    end
    return target
  end
  
  local newFirstAItems = GetAvailAbleItems(firstAvailableItems)
  local newSecondAItems = GetAvailAbleItems(secondAvailableItems)
  local newThirdIAItems = GetAvailAbleItems(thirdAvailableItems)
  if Table.IsEmpty(newFirstAItems) then
    return nil
  end
  targetLuckItems.firstAvailableItems = newFirstAItems
  targetLuckItems.secondAvailableItems = newSecondAItems
  targetLuckItems.thirdAvailableItems = newThirdIAItems
  return targetLuckItems
end

function RandomOrderHelper.LuckRandomRemoveCode(listItemCodes, Code)
  for i = #listItemCodes, 1, -1 do
    if listItemCodes[i].CurNum ~= nil and listItemCodes[i].Code == Code then
      listItemCodes[i].CurNum = listItemCodes[i].CurNum - 1
      if listItemCodes[i].CurNum == 0 then
        table.remove(listItemCodes, i)
      end
    end
  end
end

function RandomOrderHelper.GetSelectedFilterConfig(randomConfig, orderModel, slot, ignoreOutputInfo)
  local selectedFilter
  local level = GM.LevelModel:GetCurrentLevel()
  local diffScore = orderModel:GetTotalDiffScore()
  local monthPay = GM.GameModel:GetMonthPay()
  for _, filter in ipairs(randomConfig.Filters) do
    if (filter.PlayerMin == nil or level >= filter.PlayerMin) and (filter.PlayerMax == nil or level <= filter.PlayerMax) and (filter.DiffSumMin == nil or diffScore >= filter.DiffSumMin) and (filter.DiffSumMax == nil or diffScore <= filter.DiffSumMax) and (filter.sMonthPay == nil or monthPay >= filter.sMonthPay) and (filter.eMonthPay == nil or monthPay <= filter.eMonthPay) then
      selectedFilter = filter
      if not ignoreOutputInfo then
        local sMonthPayInfo = filter.sMonthPay and filter.sMonthPay or "nil"
        local eMonthPayInfo = filter.eMonthPay and filter.eMonthPay or "nil"
        local testInfo = "[\232\174\162\229\141\149][\228\187\152\232\180\185\229\136\134\230\161\163] \232\174\162\229\141\149slot " .. slot .. ", type " .. randomConfig.Type .. " \231\148\168\230\136\183\229\189\147\229\137\141\228\187\152\232\180\185 = " .. monthPay .. ", \229\175\185\229\186\148\233\133\141\231\189\174\230\140\161\228\189\141 = " .. sMonthPayInfo .. " - " .. eMonthPayInfo .. "\n"
        if GameConfig.IsTestMode() then
          TestOrderLogInfo.TestPrintMonthPayFilter(testInfo)
        end
      end
      break
    end
  end
  return selectedFilter
end

ItemsUsingDynamicLevel = {}

function RandomOrderHelper.CreateNormalRandomOrder(orderModel, slot, innerType, avatarId)
  if GameConfig.IsTestMode() and TestCreateOrderWindow ~= nil and TestCreateOrderWindow.CanCreateTmpOrder(slot) then
    local testRequirements = TestCreateOrderWindow.GetCreateTmpOrderRequirements(slot)
    local testDiffRange = "nil-nil"
    local testAvatarId = avatarId or orderModel:GetAvatarId()
    Log.Info("[\233\154\143\230\156\186\232\174\162\229\141\149][Slot:" .. slot .. "][InnerType:" .. innerType .. "]\230\181\139\232\175\149\231\142\175\229\162\131\239\188\140\229\136\183\230\150\176\230\140\135\229\174\154\230\163\139\229\173\144\232\174\162\229\141\149")
    return MainOrder.Create(orderModel, slot, nil, testRequirements, innerType, testAvatarId, nil, nil, testDiffRange)
  end
  local randomConfig = orderModel:GetRandomOrderConfig()[innerType]
  local chestCustomModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  if chestCustomModel:CheckCreateChestOrder(innerType) then
    randomConfig = orderModel:GetChestRandomOrderConfig()[innerType]
    if randomConfig == nil then
      Log.Error("ChestCustomerModel:CheckCreateChestOrder \230\137\190\228\184\141\229\136\176\229\175\185\229\186\148\232\174\162\229\141\149\233\133\141\231\189\174, \229\155\158\233\128\128\228\184\186\229\142\159\232\174\162\229\141\149")
      randomConfig = orderModel:GetRandomOrderConfig()[innerType]
      chestCustomModel = nil
    end
  else
    chestCustomModel = nil
  end
  local mapRepeatWeightDecreaseInfo = RepeatWeightDecreaseHelper.InitMapInfo(innerType, orderModel)
  ItemsUsingDynamicLevel[slot] = {}
  local selectedFilter = RandomOrderHelper.GetSelectedFilterConfig(randomConfig, orderModel, slot)
  local alreadyRequiredItems = {}
  
  local function selectItem(minLevelProperty, maxLevelProperty, dymamicMaxLevelProperty, isBack)
    local availableItems, backavailableItems = RandomOrderHelper.GetAvailableItems({
      orderModel = orderModel,
      slot = slot,
      alreadyRequiredItems = alreadyRequiredItems
    })
    local minLevel = selectedFilter[minLevelProperty]
    local maxLevel = selectedFilter[maxLevelProperty]
    local dynamicMaxLevel = selectedFilter[dymamicMaxLevelProperty]
    local dynamicLevelRes = RandomOrderHelper.GetDynamicMaxLevel(availableItems, minLevel, maxLevel, dynamicMaxLevel, alreadyRequiredItems, orderModel)
    availableItems = RandomOrderHelper.FilterByLevel(availableItems, minLevel, maxLevel, orderModel, dynamicLevelRes)
    if #availableItems == 0 and isBack then
      if backavailableItems ~= nil then
        dynamicLevelRes = RandomOrderHelper.GetDynamicMaxLevel(availableItems, minLevel, maxLevel, dynamicMaxLevel, alreadyRequiredItems, orderModel)
        availableItems = RandomOrderHelper.FilterByLevel(backavailableItems, minLevel, maxLevel, orderModel, dynamicLevelRes)
        backavailableItems = availableItems
      end
    else
      backavailableItems = nil
    end
    if #availableItems == 0 then
      return nil
    end
    RepeatWeightDecreaseHelper.DecreaseItemWeight(availableItems, mapRepeatWeightDecreaseInfo, orderModel)
    local selectedItem = Table.ListWeightSelectOne(availableItems).Code
    table.insert(alreadyRequiredItems, selectedItem)
    local tempLevel = orderModel:GetItemCodeConfigMap()[selectedItem].DifficultyLevel and orderModel:GetItemCodeConfigMap()[selectedItem].DifficultyLevel or GM.ItemDataModel:GetChainLevel(selectedItem)
    if maxLevel and maxLevel < tempLevel then
      table.insert(ItemsUsingDynamicLevel[slot], selectedItem)
    end
    if GameConfig.IsTestMode() then
      TestOrderLogInfo.TestPrintBackItemsInfo({
        slot = slot,
        availableItems = availableItems,
        backavailableItems = backavailableItems,
        selectedItem = selectedItem,
        minLevel = minLevel,
        maxLevel = maxLevel,
        dynamicMaxLevel = dynamicMaxLevel,
        mapRepeatWeightDecreaseInfo = mapRepeatWeightDecreaseInfo,
        dynamicLevelRes = dynamicLevelRes
      })
    end
    RepeatWeightDecreaseHelper.MarkSelectedLine(selectedItem, mapRepeatWeightDecreaseInfo, orderModel)
    return selectedItem
  end
  
  local firstSelectedItem = selectItem("FirstMin", "FirstMax", "DynamicFirstMax", true)
  local secondSelectedItem = firstSelectedItem and selectItem("SecondMin", "SecondMax", "DynamicSecondMax")
  local thirdSelectedItem = secondSelectedItem and selectItem("ThirdMin", "ThirdMax", "DynamicThirdMax")
  local diffRange
  if NormalOrderSlot[slot] == true then
    diffRange = tostring(selectedFilter.DiffSumMin) .. "-" .. tostring(selectedFilter.DiffSumMax)
  end
  return RandomOrderHelper.Create({
    orderModel = orderModel,
    slot = slot,
    innerType = innerType,
    firstSelectedItem = firstSelectedItem,
    secondSelectedItem = secondSelectedItem,
    thirdSelectedItem = thirdSelectedItem,
    avatarId = avatarId,
    diffRange = diffRange,
    randomConfig = randomConfig,
    chestCustomModel = chestCustomModel,
    mapRepeatWeightDecreaseInfo = mapRepeatWeightDecreaseInfo
  })
end

function RandomOrderHelper.CreateNormalRandomOrderWithChainIdFilter(orderModel, slot, innerType, chainIds)
  local randomConfig = orderModel:GetRandomOrderConfig()[innerType]
  local selectedFilter = RandomOrderHelper.GetSelectedFilterConfig(randomConfig, orderModel, slot)
  local alreadyRequiredItems = {}
  ItemsUsingDynamicLevel[slot] = {}
  
  local function selectItem(minLevelProperty, maxLevelProperty, dynamicMaxLevelProperty)
    local availableItems = RandomOrderHelper.GetAvailableItems({
      orderModel = orderModel,
      slot = slot,
      alreadyRequiredItems = alreadyRequiredItems
    })
    local minLevel = selectedFilter[minLevelProperty]
    local maxLevel = selectedFilter[maxLevelProperty]
    local dynamicMaxLevel = selectedFilter[dynamicMaxLevelProperty]
    local dynamicLevelRes = RandomOrderHelper.GetDynamicMaxLevel(availableItems, minLevel, maxLevel, dynamicMaxLevel, alreadyRequiredItems, orderModel)
    availableItems = RandomOrderHelper.FilterByLevel(availableItems, minLevel, maxLevel, orderModel, dynamicLevelRes)
    availableItems = RandomOrderHelper.FilterByChainId(availableItems, chainIds)
    if #availableItems == 0 then
      return nil
    end
    local selectedItem = Table.ListWeightSelectOne(availableItems).Code
    table.insert(alreadyRequiredItems, selectedItem)
    local tempLevel = orderModel:GetItemCodeConfigMap()[selectedItem].DifficultyLevel and orderModel:GetItemCodeConfigMap()[selectedItem].DifficultyLevel or GM.ItemDataModel:GetChainLevel(selectedItem)
    if maxLevel and maxLevel < tempLevel then
      table.insert(ItemsUsingDynamicLevel[slot], selectedItem)
    end
    return selectedItem
  end
  
  local firstSelectedItem = selectItem("FirstMin", "FirstMax", "DynamicFirstMax")
  local secondSelectedItem = firstSelectedItem and selectItem("SecondMin", "SecondMax", "DynamicSecondMax")
  local thirdSelectedItem = secondSelectedItem and selectItem("ThirdMin", "ThirdMax", "DynamicThirdMax")
  return RandomOrderHelper.Create({
    orderModel = orderModel,
    slot = slot,
    innerType = innerType,
    firstSelectedItem = firstSelectedItem,
    secondSelectedItem = secondSelectedItem,
    thirdSelectedItem = thirdSelectedItem,
    randomConfig = randomConfig
  })
end

local MainOrderAvailableItemGetterConfigDefault = {
  checkProgressUnlock = true,
  excludedByOtherOrder = true,
  excludedByLastOrder = true
}
local ItemMultiple = {
  RequiredAndEnoughToFinish = 100,
  NotRequiredBase = 1000,
  NotRequiredAndHasHigherLevel = 10000,
  Bonus = 10
}
RandomOrderHelper.ChooseItemType = {
  Pass = 0,
  ItemNoUnlockGenerator = 1,
  ItemLevelNotEnough = 2,
  ItemNoUnlockLast = 3,
  ItemNoCreateInSlot = 4,
  OnlyItemHasOtherOrder = 5,
  OnlyItemHasLastOrder = 6,
  ItemConfigWeightZero = 7
}
RandomOrderHelper.ChooseItemTypeStr = {
  [RandomOrderHelper.ChooseItemType.Pass] = "\233\128\154\232\191\135",
  [RandomOrderHelper.ChooseItemType.OnlyItemHasOtherOrder] = "\229\133\182\228\187\150\232\174\162\229\141\149\233\156\128\230\177\130",
  [RandomOrderHelper.ChooseItemType.OnlyItemHasLastOrder] = "\228\184\138\228\184\128\232\174\162\229\141\149\233\156\128\230\177\130",
  [RandomOrderHelper.ChooseItemType.ItemLevelNotEnough] = "\230\163\139\229\173\144\230\156\170\232\167\163\233\148\129",
  [RandomOrderHelper.ChooseItemType.ItemNoCreateInSlot] = "slot\228\184\141\231\172\166\229\144\136",
  [RandomOrderHelper.ChooseItemType.ItemNoUnlockGenerator] = "\230\175\141\228\189\147\230\163\139\229\173\144\230\156\170\232\167\163\233\148\129",
  [RandomOrderHelper.ChooseItemType.ItemNoUnlockLast] = "\228\184\138\228\184\128\231\186\167\230\163\139\229\173\144\230\156\170\232\167\163\233\148\129",
  [RandomOrderHelper.ChooseItemType.ItemConfigWeightZero] = "orderItemConfigWeight\230\152\1750"
}

local function GetItemTypeState(state)
  return 1 << state
end

local function CheckItemTypeState(state, ListState)
  local allState = 0
  for _, v in ipairs(ListState) do
    allState = allState | GetItemTypeState(v)
  end
  local otherState = ~allState
  local target = otherState & state
  if otherState & state ~= 0 then
    return false
  end
  return true
end

function RandomOrderHelper.GetAvailableItems(tableInfo)
  local orderModel = tableInfo.orderModel
  local slot = tableInfo.slot
  local alreadyRequiredItems = tableInfo.alreadyRequiredItems
  local config = tableInfo.config
  config = config or MainOrderAvailableItemGetterConfigDefault
  local itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
  local codeCountMap = orderModel:GetCodeCountMap()
  local orderCodeRequireCountMap, orderCodeLackCountMap = GM.MainBoardModel:CalculateOrderCodeCountData(codeCountMap, alreadyRequiredItems)
  local chainMultipleCodeListMap = {}
  local chainMultipleRequiredState = {}
  local chainMultipleRequiredLackState = {}
  local chainMultipleExistMinLevelMap = {}
  for itemCode, codeConfig in pairs(itemCodeConfigMap) do
    if codeConfig.WeightMultiple == 1 then
      local chainId = GM.ItemDataModel:GetChainId(itemCode)
      local level = GM.ItemDataModel:GetChainLevel(itemCode)
      if chainMultipleCodeListMap[chainId] == nil then
        chainMultipleCodeListMap[chainId] = {}
      end
      table.insert(chainMultipleCodeListMap[chainId], itemCode)
      if orderCodeRequireCountMap[itemCode] ~= nil then
        chainMultipleRequiredState[chainId] = true
        if orderCodeLackCountMap[itemCode] ~= nil then
          chainMultipleRequiredLackState[chainId] = true
        end
      end
      if codeCountMap[itemCode] ~= nil then
        if chainMultipleExistMinLevelMap[chainId] == nil then
          chainMultipleExistMinLevelMap[chainId] = level
        elseif level < chainMultipleExistMinLevelMap[chainId] then
          chainMultipleExistMinLevelMap[chainId] = level
        end
      end
    end
  end
  local itemChainMultiple = {}
  local itemCodeMultiple = {}
  for chainId, multipleCodeList in pairs(chainMultipleCodeListMap) do
    if chainMultipleRequiredState[chainId] then
      if not chainMultipleRequiredLackState[chainId] then
        itemChainMultiple[chainId] = ItemMultiple.RequiredAndEnoughToFinish
      end
    else
      itemChainMultiple[chainId] = ItemMultiple.NotRequiredBase
      for _, itemCode in ipairs(multipleCodeList) do
        local level = GM.ItemDataModel:GetChainLevel(itemCode)
        if chainMultipleExistMinLevelMap[chainId] ~= nil and level >= chainMultipleExistMinLevelMap[chainId] then
          itemCodeMultiple[itemCode] = ItemMultiple.NotRequiredAndHasHigherLevel
          if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.OrderDiffDynamic) then
            local ratio = 0
            for i = chainMultipleExistMinLevelMap[chainId], level - 1 do
              if codeCountMap[GM.ItemDataModel:GetTypeByChainAndLevel(chainId, i)] then
                ratio = ratio + 1
              end
            end
            itemCodeMultiple[itemCode] = ItemMultiple.NotRequiredAndHasHigherLevel * MathUtil.IntPow(10, ratio)
          end
        end
      end
    end
  end
  local lastFinishOrder = {}
  if orderModel.GetLastFinishOrder and orderModel:GetLastFinishOrder() ~= nil then
    lastFinishOrder = orderModel:GetLastFinishOrder()
  end
  local lastSlotOrder = lastFinishOrder[slot]
  local chainAvailability = {}
  local availableItems = {}
  local backAvailableItems = {}
  local OrderboostModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  local condition1 = OrderboostModel ~= nil and 0 < OrderboostModel:GetAddSmileScoreBySlot(slot)
  local condition2 = slot ~= MainOrderSlotDefinition.ContiorderSlot
  if not condition1 and condition2 then
    backAvailableItems = nil
  end
  for itemCode, itemConfig in pairs(itemCodeConfigMap) do
    local itemChooseType, info = RandomOrderHelper._CheckItemCode({
      itemCode = itemCode,
      itemConfig = itemConfig,
      chainAvailability = chainAvailability,
      orderCodeRequireCountMap = orderCodeRequireCountMap,
      itemChainMultiple = itemChainMultiple,
      itemCodeMultiple = itemCodeMultiple,
      slot = slot,
      lastSlotOrder = lastSlotOrder,
      config = config,
      orderModel = orderModel
    })
    if itemChooseType == RandomOrderHelper.ChooseItemType.Pass then
      table.insert(availableItems, {
        Code = itemCode,
        Weight = info.Weight
      })
    end
    if backAvailableItems and CheckItemTypeState(itemChooseType, {
      RandomOrderHelper.ChooseItemType.OnlyItemHasLastOrder,
      RandomOrderHelper.ChooseItemType.OnlyItemHasOtherOrder
    }) then
      table.insert(backAvailableItems, {
        Code = itemCode,
        Weight = info.Weight
      })
    end
  end
  if GameConfig.IsTestMode() then
    TestOrderLogInfo.TestPrintInterMediateLogs({
      slot = slot,
      alreadyRequiredItems = alreadyRequiredItems,
      lastSlotOrder = lastSlotOrder,
      codeCountMap = codeCountMap,
      orderCodeRequireCountMap = orderCodeRequireCountMap,
      chainMultipleRequiredState = chainMultipleRequiredState,
      chainMultipleRequiredLackState = chainMultipleRequiredLackState,
      chainMultipleExistMinLevelMap = chainMultipleExistMinLevelMap,
      itemChainMultiple = itemChainMultiple,
      itemCodeMultiple = itemCodeMultiple,
      orderModel = orderModel,
      availableItems = availableItems,
      orderCodeLackCountMap = orderCodeLackCountMap
    })
  end
  return availableItems, backAvailableItems
end

function RandomOrderHelper._CheckItemCode(infoTabale)
  local itemCode = infoTabale.itemCode
  local itemConfig = infoTabale.itemConfig
  local chainAvailability = infoTabale.chainAvailability
  local orderCodeRequireCountMap = infoTabale.orderCodeRequireCountMap
  local itemChainMultiple = infoTabale.itemChainMultiple
  local itemCodeMultiple = infoTabale.itemCodeMultiple
  local slot = infoTabale.slot
  local lastSlotOrder = infoTabale.lastSlotOrder
  local config = infoTabale.config
  local orderModel = infoTabale.orderModel
  
  local function AddTestWeightLog(itemCode, itemChooseType)
    if GameConfig.IsTestMode() then
      TestOrderLogInfo.AddItemCodeWeightZero(itemCode, itemChooseType)
    end
  end
  
  local itemChooseType = RandomOrderHelper.ChooseItemType.Pass
  if config.checkProgressUnlock and not orderModel:CheckItemCodeProgressUnlock(itemCode) then
    itemChooseType = itemChooseType | GetItemTypeState(RandomOrderHelper.ChooseItemType.ItemNoUnlockLast)
  end
  if config.excludedByLastOrder and lastSlotOrder then
    for _, lastOrderItemCode in ipairs(lastSlotOrder:GetRequirements()) do
      if lastOrderItemCode == itemCode then
        itemChooseType = itemChooseType | GetItemTypeState(RandomOrderHelper.ChooseItemType.OnlyItemHasLastOrder)
      end
    end
  end
  if config.excludedByOtherOrder and orderCodeRequireCountMap[itemCode] ~= nil then
    itemChooseType = itemChooseType | GetItemTypeState(RandomOrderHelper.ChooseItemType.OnlyItemHasOtherOrder)
  end
  if GM.LevelModel:GetCurrentLevel() < itemConfig.UnlockLevel then
    itemChooseType = itemChooseType | GetItemTypeState(RandomOrderHelper.ChooseItemType.ItemLevelNotEnough)
  end
  if not Table.IsEmpty(itemConfig.ForbiddenSlot) and Table.Contain(itemConfig.ForbiddenSlot, slot) then
    itemChooseType = itemChooseType | GetItemTypeState(RandomOrderHelper.ChooseItemType.ItemNoCreateInSlot)
  end
  local chainId = GM.ItemDataModel:GetChainId(itemCode)
  if chainAvailability[chainId] == nil then
    chainAvailability[chainId] = false
    local generators = GM.ItemDataModel:GetChainGenerators(chainId)
    for _, generator in ipairs(generators) do
      if GM.ItemDataModel:IsUnlocked(generator) then
        chainAvailability[chainId] = true
        break
      end
    end
  end
  if not chainAvailability[chainId] then
    itemChooseType = itemChooseType | GetItemTypeState(RandomOrderHelper.ChooseItemType.ItemNoUnlockGenerator)
  end
  if itemConfig.Weight <= 0 then
    itemChooseType = itemChooseType | GetItemTypeState(RandomOrderHelper.ChooseItemType.ItemConfigWeightZero)
  end
  local nMultiple = 1
  if itemCodeMultiple[itemCode] ~= nil then
    nMultiple = itemCodeMultiple[itemCode]
  elseif itemChainMultiple[chainId] ~= nil then
    nMultiple = itemChainMultiple[chainId]
  end
  if itemChooseType ~= RandomOrderHelper.ChooseItemType.Pass then
    AddTestWeightLog(itemCode, itemChooseType)
  end
  local Weight = itemConfig.Weight * nMultiple
  return itemChooseType, {Weight = Weight}
end

function RandomOrderHelper.GetBaselineAvailableItems(orderModel, slot)
  local orderCodeCountMap = {}
  for _, order in pairs(orderModel:GetOrders()) do
    for _, itemCode in ipairs(order:GetRequirements()) do
      if orderCodeCountMap[itemCode] == nil then
        orderCodeCountMap[itemCode] = 0
      end
      orderCodeCountMap[itemCode] = orderCodeCountMap[itemCode] + 1
    end
  end
  local availableItems = {}
  local itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
  for itemCode, count in pairs(orderModel:GetCodeCountMap()) do
    local config = itemCodeConfigMap[itemCode]
    if config ~= nil and config.RecommendedNumber ~= nil then
      local orderCount = orderCodeCountMap[itemCode] or 0
      if count - orderCount >= config.RecommendedNumber then
        table.insert(availableItems, {
          Code = itemCode,
          RecommendedNumber = config.RecommendedNumber
        })
      end
    end
  end
  return availableItems
end

function RandomOrderHelper.GetDynamicMaxLevel(availableItems, minLevel, maxLevel, dynamicMaxLevel, alreadyRequiredItems, orderModel)
  local itemCodeConfigMap = {}
  if orderModel ~= nil then
    itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
  end
  local res = {}
  res.Level = maxLevel
  res.Items = {}
  res.Chains = {}
  local testInfo = {}
  Table.ListAppend(testInfo, {
    "trying to get dynamic level, min/max/dnmcMax: ",
    minLevel or "nil",
    " ",
    maxLevel or "nil",
    " ",
    dynamicMaxLevel or "nil",
    "\n"
  })
  if dynamicMaxLevel and maxLevel and maxLevel < dynamicMaxLevel then
    local codeCountMap = GM.MainBoardModel:GetCodeCountMap(true, false, true)
    local orderCodeRequireCountMap = GM.MainBoardModel:CalculateOrderCodeCountData(codeCountMap, alreadyRequiredItems)
    local resMaxLevel = 0
    local resItems = {}
    for itemCode, count in pairs(codeCountMap) do
      if itemCodeConfigMap[itemCode] then
        Table.ListAppend(testInfo, {
          "\229\176\157\232\175\149\229\136\164\229\174\154",
          itemCode,
          "\n"
        })
        local useDynamicLevel = false
        local level = GM.ItemDataModel:GetChainLevel(itemCode)
        if itemCodeConfigMap[itemCode].DifficultyLevel ~= nil then
          level = itemCodeConfigMap[itemCode].DifficultyLevel
        end
        if maxLevel <= level and dynamicMaxLevel > level then
          Table.ListAppend(testInfo, {
            "-----\229\189\147\229\137\141\229\138\168\230\128\129\231\173\137\231\186\167\229\143\138\229\175\185\229\186\148\230\163\139\229\173\144: ",
            resMaxLevel,
            " | ",
            table.concat(resItems, ", "),
            "\n"
          })
          Table.ListAppend(testInfo, {
            "-----\229\189\147\229\137\141\230\163\139\229\173\144/\231\173\137\231\186\167/\233\133\141\231\189\174\230\156\128\229\164\167\231\173\137\231\186\167/\233\133\141\231\189\174\229\138\168\230\128\129\231\173\137\231\186\167: ",
            itemCode,
            " ",
            level,
            " ",
            maxLevel,
            " ",
            dynamicMaxLevel,
            "\n"
          })
          if resMaxLevel <= level then
            useDynamicLevel = true
            for requiredItem, requiredNum in pairs(orderCodeRequireCountMap) do
              if GM.ItemDataModel:GetChainId(requiredItem) == GM.ItemDataModel:GetChainId(itemCode) and GM.ItemDataModel:GetChainLevel(requiredItem) >= GM.ItemDataModel:GetChainLevel(itemCode) then
                Table.ListAppend(testInfo, {
                  "\229\144\140\229\144\136\230\136\144\231\186\191\230\155\180\233\171\152\231\186\167\230\163\139\229\173\144:",
                  requiredItem,
                  " \233\156\128\230\177\130\230\149\176\233\135\143",
                  requiredNum,
                  " \229\156\186\228\184\138\230\149\176\233\135\143:",
                  codeCountMap[requiredItem] or 0,
                  "\n"
                })
                if codeCountMap[requiredItem] and requiredNum < codeCountMap[requiredItem] then
                else
                  Table.ListAppend(testInfo, {
                    "\230\149\176\233\135\143\228\184\141\230\187\161\232\182\179\230\157\161\228\187\182",
                    "\n"
                  })
                  useDynamicLevel = false
                  break
                end
              end
            end
          else
            Table.ListAppend(testInfo, {
              "\231\186\167\229\136\171\228\189\142\228\186\142\229\189\147\229\137\141\229\138\168\230\128\129\230\156\128\229\164\167\231\173\137\231\186\167\239\188\140\232\183\179\232\191\135",
              "\n"
            })
          end
        else
          Table.ListAppend(testInfo, {
            "\231\173\137\231\186\167\228\184\141\230\187\161\232\182\179",
            "\n"
          })
        end
        if useDynamicLevel then
          if resMaxLevel < level then
            resMaxLevel = level
            resItems = {itemCode}
            Table.ListAppend(testInfo, {
              "\229\138\168\230\128\129\231\173\137\231\186\167\229\136\183\230\150\176\228\184\186 ",
              resMaxLevel,
              " | ",
              table.concat(resItems, ", "),
              "\n"
            })
          elseif level == resMaxLevel then
            table.insert(resItems, itemCode)
            Table.ListAppend(testInfo, {
              "\229\138\168\230\128\129\231\173\137\231\186\167\231\187\180\230\140\129\229\142\159\231\138\182\239\188\140\229\162\158\229\138\160\228\184\128\228\184\170\230\163\139\229\173\144 ",
              resMaxLevel,
              " | ",
              table.concat(resItems, ", "),
              "\n"
            })
          end
        end
      end
    end
    for _, item in ipairs(resItems) do
      local curLevel = GM.ItemDataModel:GetChainLevel(item)
      local curChain = GM.ItemDataModel:GetChainId(item)
      local higherItem = item
      if curLevel < GM.ItemDataModel:GetChainMaxLevel(curChain) then
        higherItem = GM.ItemDataModel:GetTypeByChainAndLevel(curChain, curLevel + 1)
      end
      local found = false
      for _, availableItem in ipairs(availableItems) do
        if availableItem.Code == higherItem then
          availableItem.Weight = availableItem.Weight * 50
          table.insert(res.Items, {
            Code = availableItem.Code,
            Weight = availableItem.Weight
          })
          table.insert(res.Chains, GM.ItemDataModel:GetChainId(availableItem.Code))
          Table.ListAppend(testInfo, {
            "\229\143\175\229\186\148\231\148\168\229\138\168\230\128\129\231\173\137\231\186\167 code ",
            availableItem.Code,
            " weight ",
            availableItem.Weight,
            " chain ",
            GM.ItemDataModel:GetChainId(availableItem.Code),
            "\n"
          })
          found = true
        end
      end
      if not found then
        Table.ListAppend(testInfo, {
          higherItem,
          "\228\184\141\229\156\168\229\143\175\233\128\137\230\163\139\229\173\144\229\136\151\232\161\168\228\184\173\239\188\140\230\151\160\230\179\149\229\186\148\231\148\168\229\138\168\230\128\129\231\173\137\231\186\167",
          "\n"
        })
      end
    end
    if #res.Items > 0 then
      res.Level = resMaxLevel + 1
    else
      res.Level = maxLevel
    end
    Table.ListAppend(testInfo, {
      "\230\156\128\231\187\136\229\138\168\230\128\129\231\173\137\231\186\167\239\188\154",
      res.Level,
      "\n"
    })
  end
  EventDispatcher.DispatchEvent(EEventType.TestOutputTableInfo, testInfo)
  return res
end

function RandomOrderHelper.FilterByLevel(items, minLevel, maxLevel, orderModel, dynamicLevelRes)
  local itemCodeConfigMap = {}
  if orderModel ~= nil then
    itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
  end
  
  local function filter(item)
    local level = GM.ItemDataModel:GetChainLevel(item.Code)
    if itemCodeConfigMap[item.Code] ~= nil and itemCodeConfigMap[item.Code].DifficultyLevel ~= nil then
      level = itemCodeConfigMap[item.Code].DifficultyLevel
    end
    if dynamicLevelRes and Table.Contain(dynamicLevelRes.Chains, GM.ItemDataModel:GetChainId(item.Code)) then
      if dynamicLevelRes.Level ~= nil and level > dynamicLevelRes.Level then
        return false
      end
    elseif maxLevel ~= nil and level > maxLevel then
      return false
    end
    if minLevel ~= nil and level < minLevel then
      return false
    end
    return true
  end
  
  return Table.ListSelect(items, filter)
end

function RandomOrderHelper.FilterByChainId(items, chainIdList)
  local function filter(item)
    local chainId = GM.ItemDataModel:GetChainId(item.Code)
    
    if Table.Contain(chainIdList, chainId) then
      return true
    end
    return false
  end
  
  return Table.ListSelect(items, filter)
end

local MainOrderCreatorRandom1 = {}

function MainOrderCreatorRandom1.CanCreate(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.Slot1 and slot ~= MainOrderSlotDefinition.Slot2 then
    return false
  end
  local randomConfig = orderModel:GetRandomOrderConfig()[MainOrderType.Random1]
  if GM.LevelModel:GetCurrentLevel() < randomConfig.UnlockLevel then
    return false
  end
  local metaData = orderModel:GetMetaData()
  local startTimer = metaData:GetValue(MainOrderDBColumnRandomStartTimer[slot], DBColumnValue)
  startTimer = startTimer and tonumber(startTimer)
  local orderPoints = 0
  if startTimer == 0 then
    orderPoints = tonumber(metaData:GetValue(MainOrderDBRandomPoint[MainOrderType.Random1], DBColumnValue))
    if orderPoints == 0 then
      startTimer = GM.GameModel:GetServerTime()
      metaData:Set(MainOrderDBColumnRandomStartTimer[slot], DBColumnValue, tostring(startTimer))
    end
  elseif startTimer == nil or GM.GameModel:GetServerTime() - startTimer >= randomConfig.RefreshTime then
    local random1Count = 0
    local orders = orderModel:GetOrders()
    local slots = {
      MainOrderSlotDefinition.Slot1,
      MainOrderSlotDefinition.Slot2
    }
    for _, slot in ipairs(slots) do
      local order = orders[slot]
      if order ~= nil and order:GetState() ~= OrderState.Finished and order:GetInnerType() == MainOrderType.Random1 then
        random1Count = random1Count + 1
      end
    end
    orderPoints = randomConfig.Point - random1Count
    metaData:Set(MainOrderDBColumnRandomStartTimer[slot], DBColumnValue, "0")
  end
  if orderPoints == 0 then
    if ForceCreateOrder(slot) then
      startTimer = GM.GameModel:GetServerTime()
      metaData:Set(MainOrderDBColumnRandomStartTimer[slot], DBColumnValue, "0")
      metaData:Set(MainOrderDBRandomPoint[MainOrderType.Random1], DBColumnValue, "0")
      return true
    end
    return false
  end
  orderPoints = orderPoints - 1
  metaData:Set(MainOrderDBRandomPoint[MainOrderType.Random1], DBColumnValue, tostring(orderPoints))
  return true
end

function MainOrderCreatorRandom1.Create(orderModel, slot)
  return RandomOrderHelper.CreateNormalRandomOrder(orderModel, slot, MainOrderType.Random1)
end

local MainOrderCreatorRandom2 = {}

function MainOrderCreatorRandom2.CanCreate(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.Slot3 then
    return false
  end
  local randomConfig = orderModel:GetRandomOrderConfig()[MainOrderType.Random2]
  if GM.LevelModel:GetCurrentLevel() < randomConfig.UnlockLevel then
    return false
  end
  local excludeSlot = {
    MainOrderSlotDefinition.ContiorderSlot
  }
  local hasOtherOrder = false
  local orders = orderModel:GetOrders()
  for _, order in pairs(orders) do
    if not Table.ListContain(excludeSlot, order:GetSlot()) and order:GetState() ~= OrderState.Finished and not MainOrderSlot3IgnoreCheckInnerType[order:GetInnerType()] then
      hasOtherOrder = true
      break
    end
  end
  if not hasOtherOrder then
    local metaData = orderModel:GetMetaData()
    metaData:Set(MainOrderDBColumnRandomStartTimer[slot], DBColumnValue, "0")
    return true
  end
  return RandomOrderHelper.CanCreate(orderModel, MainOrderDBColumnRandomStartTimer[slot], randomConfig)
end

function MainOrderCreatorRandom2.Create(orderModel, slot)
  return RandomOrderHelper.CreateNormalRandomOrder(orderModel, slot, MainOrderType.Random2)
end

local function NormalRandomCreatorTemplate(checkSlot, mainOrderType)
  local creator = {}
  
  function creator.CanCreate(orderModel, slot)
    if slot ~= checkSlot then
      return false
    end
    local randomConfig = orderModel:GetRandomOrderConfig()[mainOrderType]
    if GM.LevelModel:GetCurrentLevel() < randomConfig.UnlockLevel then
      return false
    end
    local startTimerColumn = MainOrderDBColumnRandomStartTimer[checkSlot]
    return RandomOrderHelper.CanCreate(orderModel, startTimerColumn, randomConfig)
  end
  
  function creator.Create(orderModel, slot)
    return RandomOrderHelper.CreateNormalRandomOrder(orderModel, slot, mainOrderType)
  end
  
  return creator
end

local MainOrderCreatorRandom3 = NormalRandomCreatorTemplate(MainOrderSlotDefinition.Slot4, MainOrderType.Random3)
local MainOrderCreatorRandom4 = NormalRandomCreatorTemplate(MainOrderSlotDefinition.Slot5, MainOrderType.Random4)
local MainOrderCreatorRandom5 = NormalRandomCreatorTemplate(MainOrderSlotDefinition.Slot8, MainOrderType.Random5New)
local MainOrderCreatorRandomCharacterIntimacy = {}

function MainOrderCreatorRandomCharacterIntimacy.CanCreate(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.CharacterIntimacySlot then
    return false
  end
  if not GM.CharacterIntimacyModel:IsOpen() then
    return false
  end
  if not GM.CharacterIntimacyModel:IsRandomOrderOpen() then
    return
  end
  local randomConfig = orderModel:GetRandomOrderConfig()[MainOrderType.CharacterIntimacyRandom]
  Log.Assert(randomConfig, "OrderRandomConfig\230\178\161\230\156\137\233\133\141\231\189\174Type\228\184\186" .. MainOrderType.CharacterIntimacyRandom .. "\231\154\132\229\165\189\230\132\159\229\186\166\233\154\143\230\156\186\232\174\162\229\141\149\233\133\141\231\189\174")
  return RandomOrderHelper.CanCreate(orderModel, MainOrderDBColumnRandomStartTimer[slot], randomConfig)
end

function MainOrderCreatorRandomCharacterIntimacy.Create(orderModel, slot)
  return RandomOrderHelper.CreateNormalRandomOrder(orderModel, slot, MainOrderType.CharacterIntimacyRandom, CharacterIntimacyModel.OrderAvatarId)
end

local MainOrderCreatorRandomTimedOrder = {}

function MainOrderCreatorRandomTimedOrder.CanCreate(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.TimedOrderSlot then
    return false
  end
  local randomConfig = orderModel:GetRandomOrderConfig()[MainOrderType.TimedOrder]
  if GM.LevelModel:GetCurrentLevel() < randomConfig.UnlockLevel then
    return false
  end
  local model = GM.ActivityManager:GetModel(ActivityType.TimedOrder)
  return model ~= nil and model:CanCreateOrder(slot)
end

function MainOrderCreatorRandomTimedOrder.Create(orderModel, slot)
  local model = GM.ActivityManager:GetModel(ActivityType.TimedOrder)
  return model:CreateOrder(orderModel, slot)
end

local MainOrderCreatorRandomBaselineOrder = {}

function MainOrderCreatorRandomBaselineOrder.CanCreate(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.BaselineOrderSlot then
    return false
  end
  local metaData = orderModel:GetMetaData()
  local GenerateTime = tonumber(metaData:GetValue(DBColumnRandomBaselineLastGenerateTimer, DBColumnValue)) or 0
  local rec = GM.GameModel:GetServerTime()
  if GenerateTime == -1 then
    metaData:Set(DBColumnRandomBaselineLastGenerateTimer, DBColumnValue, tostring(rec))
    return false
  end
  if rec - GenerateTime < 60 then
    return false
  end
  local baselineAvailableItems = RandomOrderHelper.GetBaselineAvailableItems(orderModel, slot)
  if #baselineAvailableItems == 0 then
    return false
  end
  return true
end

function MainOrderCreatorRandomBaselineOrder.Create(orderModel, slot)
  local metaData = orderModel:GetMetaData()
  metaData:Set(DBColumnRandomBaselineLastGenerateTimer, DBColumnValue, "-1")
  local baselineAvailableItems = RandomOrderHelper.GetBaselineAvailableItems(orderModel, slot)
  local item = Table.ListRandomSelectOne(baselineAvailableItems)
  local requirements = Table.ListRep(item.Code, item.RecommendedNumber)
  local avatarId = orderModel:GetAvatarId()
  if GameConfig.IsTestMode() then
    TestOrderLogInfo.TestPrintBaseLineOrder(MainOrderType.BaselineOrder, slot)
  end
  return MainOrder.Create(orderModel, slot, nil, requirements, MainOrderType.BaselineOrder, avatarId, false, true)
end

return function(orderModel, slot)
  local randomCreators = {
    MainOrderCreatorRandom1,
    MainOrderCreatorRandom2,
    MainOrderCreatorRandom3,
    MainOrderCreatorRandom4,
    MainOrderCreatorRandom5,
    MainOrderCreatorRandomCharacterIntimacy,
    MainOrderCreatorRandomTimedOrder,
    MainOrderCreatorRandomBaselineOrder
  }
  local randomCreator
  for _, creator in ipairs(randomCreators) do
    if creator.CanCreate(orderModel, slot) then
      randomCreator = creator
      break
    end
  end
  if randomCreator == nil then
    return nil
  end
  local targetOrder = randomCreator.Create(orderModel, slot)
  if GameConfig.IsTestMode() then
    GM.TestModel:ShowTestOrderLog(targetOrder)
  end
  return targetOrder
end
