RandomGenerateCodeHelper = {}
RandomGenerateCodeHelper.__index = RandomGenerateCodeHelper

function RandomGenerateCodeHelper.GenerateChestCustomCodeRule(scoreNum, testNum, applyOptimization)
  local testStr = ""
  local codeCountMap = Table.DeepCopy(GM.MainBoardModel:GetCodeCountMap(true, false, true))
  local orderItemConfig = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
  local listLackItem = {}
  for _, order in pairs(GM.MainBoardModel:GetOrders()) do
    if order:GetState() ~= OrderState.Finished then
      local ele = {}
      ele.order = order
      ele.diffScore = 0
      for _, requirement in ipairs(order:GetRequirements()) do
        if orderItemConfig[requirement] ~= nil then
          local count = codeCountMap[requirement] or 0
          if 0 < count then
            codeCountMap[requirement] = count - 1
          else
            if ele.ListCode == nil then
              ele.ListCode = {}
            end
            table.insert(ele.ListCode, {code = requirement})
            ele.diffScore = ele.diffScore + orderItemConfig[requirement].DiffScore
          end
        end
      end
      if ele.diffScore > 0 then
        table.insert(listLackItem, ele)
      end
    end
  end
  table.sort(listLackItem, function(a, b)
    return a.diffScore < b.diffScore
  end)
  local targetItems = {}
  if GameConfig.IsTestMode() then
    testStr = testStr .. "\230\175\143\228\184\170\232\174\162\229\141\149\231\188\186\229\176\145\230\163\139\229\173\144\231\154\132\228\191\161\230\129\175\228\187\165\229\143\138\233\154\190\229\186\166\229\136\134: \n"
    for _, info in ipairs(listLackItem) do
      testStr = testStr .. "\230\167\189\228\189\141\239\188\154" .. tostring(info.order:GetSlot()) .. " \231\188\186\229\176\145\230\163\139\229\173\144: "
      for _, info in ipairs(info.ListCode) do
        testStr = testStr .. tostring(info.code) .. " "
      end
      testStr = testStr .. " \233\154\190\229\186\166\229\136\134: " .. tostring(info.diffScore) .. "\n"
    end
    testStr = testStr .. "\n"
  end
  local testCurNum = 0
  local mapItemLackNum
  for index, info in ipairs(listLackItem) do
    if scoreNum <= 0 then
      break
    end
    local listCodes = Table.DeepCopy(info.ListCode)
    if scoreNum + 10 >= info.diffScore then
      for _, codeInfo in ipairs(listCodes) do
        table.insert(targetItems, codeInfo.code)
      end
      scoreNum = scoreNum - info.diffScore
      if GameConfig.IsTestMode() and (testNum == nil or testNum > testCurNum) then
        testStr = testStr .. "\229\136\134\230\149\176+10\231\155\180\230\142\165\230\187\161\232\182\179\232\174\162\229\141\149\230\167\189\228\189\141\239\188\154" .. tostring(info.order:GetSlot()) .. ", \229\165\150\229\138\177: "
        for _, codeInfo in ipairs(listCodes) do
          testStr = testStr .. tostring(codeInfo.code) .. "(" .. tostring(orderItemConfig[codeInfo.code].DiffScore) .. ") "
        end
        testStr = testStr .. ", \230\128\187\229\136\134\230\149\176: " .. tostring(info.diffScore) .. ", \229\137\169\228\189\153\229\136\134\230\149\176: " .. tostring(scoreNum) .. "\n"
      end
    else
      table.sort(listCodes, function(a, b)
        return orderItemConfig[a.code].DiffScore < orderItemConfig[b.code].DiffScore
      end)
      if GameConfig.IsTestMode() and (testNum == nil or testNum > testCurNum) then
        testStr = testStr .. "\229\136\134\230\149\176+10\228\184\141\230\187\161\232\182\179\230\167\189\228\189\141\233\156\128\230\177\130\239\188\154" .. tostring(info.order:GetSlot()) .. "\n"
      end
      if applyOptimization and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.RewardStockCount) and mapItemLackNum == nil then
        mapItemLackNum, testStr = RandomGenerateCodeHelper._GetItemLackMap(testStr)
      end
      for _, codeInfo in ipairs(listCodes) do
        if scoreNum <= 0 then
          break
        end
        local targetCode = codeInfo.code
        if scoreNum >= orderItemConfig[targetCode].DiffScore then
          table.insert(targetItems, targetCode)
          scoreNum = scoreNum - orderItemConfig[targetCode].DiffScore
          if applyOptimization and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.RewardStockCount) then
            local level = GM.ItemDataModel:GetChainLevel(targetCode)
            local num = MathUtil.IntPow(2, level - 1)
            if mapItemLackNum[targetCode] ~= nil then
              mapItemLackNum[targetCode] = math.max(mapItemLackNum[targetCode] - num, 0)
            end
          end
          if GameConfig.IsTestMode() and (testNum == nil or testNum > testCurNum) then
            testStr = testStr .. "\229\136\134\230\149\176\230\187\161\232\182\179: " .. tostring(targetCode) .. ":" .. tostring(orderItemConfig[targetCode].DiffScore) .. " \n"
          end
        elseif applyOptimization and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.RewardStockCount) then
          scoreNum, testStr = RandomGenerateCodeHelper._PickItems_new(codeInfo, orderItemConfig, scoreNum, targetItems, testNum, testCurNum, testStr, mapItemLackNum)
        else
          scoreNum, testStr = RandomGenerateCodeHelper._PickItems_old(codeInfo, orderItemConfig, scoreNum, targetItems, testNum, testCurNum, testStr)
        end
      end
    end
    testCurNum = testCurNum + 1
  end
  if GameConfig.IsTestMode() and testNum == nil then
    testStr = testStr .. "\231\173\155\233\128\137\232\174\162\229\141\149\229\137\169\228\189\153\230\163\139\229\173\144\229\144\142\229\137\169\228\189\153\229\136\134\230\149\176: " .. tostring(scoreNum) .. "\n"
    testStr = testStr .. "\232\174\162\229\141\149\230\163\139\229\173\144\231\154\132\229\165\150\229\138\177\239\188\154"
    local allScore = 0
    for _, itemType in ipairs(targetItems) do
      testStr = testStr .. itemType .. "\229\136\134\230\149\176:" .. tostring(orderItemConfig[itemType].DiffScore) .. " "
      allScore = allScore + orderItemConfig[itemType].DiffScore
    end
    testStr = testStr .. ", \230\128\187\229\136\134\230\149\176: " .. tostring(allScore) .. "\n"
  end
  if 0 < scoreNum then
    local fiveItemConfig = {}
    for itemType, itemConfig in pairs(orderItemConfig) do
      if itemConfig.UnlockLevel <= GM.LevelModel:GetCurrentLevel() then
        local bUnLockGenerator = false
        local chainId = GM.ItemDataModel:GetChainId(itemType)
        local generators = GM.ItemDataModel:GetChainGenerators(chainId)
        local curLevel = GM.ItemDataModel:GetChainLevel(itemType)
        for _, generator in ipairs(generators) do
          if GM.ItemDataModel:IsUnlocked(generator) then
            bUnLockGenerator = true
            break
          end
        end
        if bUnLockGenerator and curLevel == 5 then
          table.insert(fiveItemConfig, itemType)
        end
      end
    end
    if Table.IsEmpty(fiveItemConfig) then
      table.insert(fiveItemConfig, "205")
    end
    if GameConfig.IsTestMode() and (testNum == nil or testNum > testCurNum) then
      testStr = testStr .. "\229\143\175\233\128\137\231\154\132\233\154\143\230\156\1865\231\186\167\230\163\139\229\173\144\239\188\154"
      for _, itemType in ipairs(fiveItemConfig) do
        testStr = testStr .. itemType .. " "
      end
      testStr = testStr .. "\n"
      testStr = testStr .. "\233\154\143\230\156\1865\231\186\167\230\163\139\229\173\144\231\154\132\229\165\150\229\138\177\239\188\154"
    end
    while 0 < scoreNum do
      local itemType = Table.ListRandomSelectOne(fiveItemConfig)
      table.insert(targetItems, itemType)
      scoreNum = scoreNum - orderItemConfig[itemType].DiffScore
      if GameConfig.IsTestMode() and (testNum == nil or testNum > testCurNum) then
        testStr = testStr .. itemType .. " "
        testCurNum = testCurNum + 1
      end
    end
    if GameConfig.IsTestMode() then
      testStr = testStr .. "\n"
    end
  end
  return targetItems, testStr
end

function RandomGenerateCodeHelper._PickItems_old(codeInfo, orderItemConfig, scoreNum, targetItems, testNum, testCurNum, testStr)
  local code = codeInfo.code
  local itemChain = GM.ItemDataModel:GetChainId(code)
  local curLevel = GM.ItemDataModel:GetChainLevel(code)
  local chosenCode = code
  for level = curLevel, 1, -1 do
    local curItemType = GM.ItemDataModel:GetTypeByChainAndLevel(itemChain, level)
    if orderItemConfig[curItemType] ~= nil then
      local diffScore = orderItemConfig[curItemType].DiffScore
      chosenCode = curItemType
      if diffScore <= 21 then
        break
      end
    end
  end
  local num = math.ceil(scoreNum / orderItemConfig[chosenCode].DiffScore)
  for i = 1, num do
    scoreNum = scoreNum - orderItemConfig[chosenCode].DiffScore
    table.insert(targetItems, chosenCode)
  end
  if GameConfig.IsTestMode() and (testNum == nil or testCurNum < testNum) then
    testStr = testStr .. "\229\136\134\230\149\176\228\184\141\232\182\179\228\187\165\231\155\180\230\142\165\229\143\145\230\148\190\230\137\128\233\156\128\230\163\139\229\173\144\227\128\130\229\143\145\230\148\190\230\149\176\233\135\143:" .. tostring(num) .. " \229\165\150\229\138\177:" .. tostring(chosenCode) .. "(" .. tostring(orderItemConfig[chosenCode].DiffScore) .. ")\n"
  end
  return scoreNum, testStr
end

function RandomGenerateCodeHelper._PickItems_new(codeInfo, orderItemConfig, scoreNum, targetItems, testNum, testCurNum, testStr, mapItemLackNum)
  local code = codeInfo.code
  if mapItemLackNum[code] ~= nil and 0 < mapItemLackNum[code] then
    local itemChain = GM.ItemDataModel:GetChainId(code)
    local curLevel = GM.ItemDataModel:GetChainLevel(code)
    local chosenCode = code
    for level = curLevel, 1, -1 do
      local curItemType = GM.ItemDataModel:GetTypeByChainAndLevel(itemChain, level)
      if orderItemConfig[curItemType] ~= nil then
        local diffScore = orderItemConfig[curItemType].DiffScore
        chosenCode = curItemType
        if diffScore <= 21 then
          break
        end
      end
    end
    if orderItemConfig[chosenCode] == nil or orderItemConfig[chosenCode].DiffScore > 21 then
      if GameConfig.IsTestMode() then
        testStr = testStr .. "\230\178\161\230\156\137\230\137\190\229\136\176\230\156\137\230\149\136\230\163\139\229\173\144\239\188\140\233\128\128\229\135\186\230\156\172\230\172\161\230\144\156\231\180\162\n"
      end
      return scoreNum, testStr
    end
    if GameConfig.IsTestMode() then
      testStr = testStr .. "--------\229\143\145\230\148\190" .. code .. "\229\175\185\229\186\148\230\163\139\229\173\144--------\n"
      testStr = testStr .. "\233\128\137\229\143\150" .. chosenCode .. ":" .. orderItemConfig[chosenCode].DiffScore .. " "
    end
    local num = 0
    while true do
      num = num + 1
      scoreNum = scoreNum - orderItemConfig[chosenCode].DiffScore
      table.insert(targetItems, chosenCode)
      local level = GM.ItemDataModel:GetChainLevel(chosenCode)
      mapItemLackNum[code] = mapItemLackNum[code] - MathUtil.IntPow(2, level - 1)
      if GameConfig.IsTestMode() then
        testStr = testStr .. code .. " \229\137\169\228\189\153\231\188\186\229\164\177 " .. mapItemLackNum[code] .. ", \229\137\169\228\189\153\229\165\150\229\138\177\229\136\134" .. scoreNum .. "\n"
      end
      if mapItemLackNum[code] <= 0 or scoreNum <= 0 then
        break
      end
    end
    if GameConfig.IsTestMode() and (testNum == nil or testCurNum < testNum) then
      testStr = testStr .. "\230\150\176\232\167\132\229\136\153\231\148\159\230\149\136, \229\143\145\230\148\190 " .. tostring(num) .. "\228\184\170 code:" .. tostring(chosenCode) .. ":" .. tostring(orderItemConfig[chosenCode].DiffScore) .. " \231\155\174\230\160\135\229\144\136\230\136\144\230\163\139\229\173\144 " .. code .. ", \229\137\169\228\189\153\229\165\150\229\138\177\229\136\134 " .. scoreNum .. " \n"
    end
    return scoreNum, testStr
  else
    testStr = testStr .. "code " .. code .. " \229\156\168\229\144\136\230\136\144\229\136\164\230\150\173\230\179\149\229\136\153\228\184\139\230\151\160\231\188\186\229\164\177\239\188\140\232\183\179\232\191\135\232\175\165\230\163\139\229\173\144\227\128\130 \n"
    return scoreNum, testStr
  end
end

function RandomGenerateCodeHelper._GetItemLackMap(testStr)
  local mapItemLackNum = GM.MainBoardModel:CalculateOrderCodeLackNumMap(false, true, false)
  if GameConfig.IsTestMode() then
    testStr = testStr .. "\229\189\147\229\137\141\231\188\186\229\176\145\230\163\139\229\173\144\229\175\185\229\186\148\231\154\1321\231\186\167\230\163\139\229\173\144\230\149\176\233\135\143:\n"
    for code, lackNum in pairs(mapItemLackNum) do
      testStr = testStr .. code .. " : " .. lackNum .. " / "
    end
    testStr = testStr .. "\n"
  end
  return mapItemLackNum, testStr
end

function RandomGenerateCodeHelper.TrySmartProduceItem(sourceItemModel)
  local chainId = GM.ItemDataModel:GetChainId(sourceItemModel:GetType())
  for id, _ in pairs(ItemSubChain) do
    if id == chainId then
      return RandomGenerateCodeHelper._GetSmartProduceItem(sourceItemModel)
    end
  end
  return nil
end

function RandomGenerateCodeHelper.GetSpliteCodeWeightMapSubAndMain(codeMap, subChainId, mainChainId)
  local subCodeMap = {}
  local mainCodeMap = {}
  for code, count in pairs(codeMap) do
    local chainId = GM.ItemDataModel:GetChainId(code)
    if chainId == subChainId then
      subCodeMap[code] = count
    end
    if chainId == mainChainId then
      mainCodeMap[code] = count
    end
  end
  return subCodeMap, mainCodeMap
end

function RandomGenerateCodeHelper._GetSmartProduceItem(sourceItemModel)
  local itemSpread = sourceItemModel:GetComponent(ItemSpread)
  local codeWeightPairs = itemSpread:GetCodeWeightPairs()
  local chainId = GM.ItemDataModel:GetChainId(sourceItemModel:GetType())
  local subChainCodeWeightPairs = {}
  local mainChainCodeWeightPairs = {}
  local subChainId, mainChainId
  for _, pair in pairs(codeWeightPairs) do
    if GM.ItemDataModel:GetModelConfig(pair.Code, true) ~= nil then
      local spreadChainId = GM.ItemDataModel:GetChainId(pair.Code)
      if ItemSubChain[chainId] == spreadChainId then
        table.insert(subChainCodeWeightPairs, pair)
        subChainId = spreadChainId
      else
        table.insert(mainChainCodeWeightPairs, pair)
        mainChainId = spreadChainId
      end
    end
  end
  if subChainId == nil then
    return nil
  end
  local lackCountMap = GM.MainBoardModel:GetOrderCodeLackCountMap()
  local lackCountMapSub, lackCountMapgMain = RandomGenerateCodeHelper.GetSpliteCodeWeightMapSubAndMain(lackCountMap, subChainId, mainChainId)
  if Table.IsEmpty(lackCountMapSub) and Table.IsEmpty(lackCountMapgMain) then
    return nil
  end
  local codeCountMap = Table.DeepCopy(GM.MainBoardModel:GetCodeCountMap(true, false, true))
  local listLackSubItem = false
  local listLackMainItem = false
  for _, order in pairs(GM.MainBoardModel:GetOrders()) do
    if order:GetState() ~= OrderState.Finished then
      for _, requirement in ipairs(order:GetRequirements()) do
        local chainId = GM.ItemDataModel:GetChainId(requirement)
        local bLack = BoardModelHelper.CalculateLackNumForMergeRequire(requirement, codeCountMap) ~= 0
        if bLack then
          if chainId == subChainId then
            listLackSubItem = true
            break
          elseif chainId == mainChainId then
            listLackMainItem = true
          end
        end
      end
    end
  end
  local item
  if listLackSubItem then
    item = Table.ListWeightSelectOne(subChainCodeWeightPairs)
  elseif listLackMainItem then
    item = Table.ListWeightSelectOne(mainChainCodeWeightPairs)
  end
  if item then
    if GameConfig.IsTestMode() then
      Log.Info("[\230\175\141\228\189\147\230\163\139\229\173\144\229\138\169\229\138\155]\232\167\166\229\143\145\230\153\186\232\131\189\229\150\183\229\143\145 " .. (listLackSubItem and "\229\137\175\229\144\136\230\136\144\231\186\191 " or "\228\184\187\229\144\136\230\136\144\231\186\191 ") .. item.Code)
    end
    return item.Code
  else
    return nil
  end
end

function RandomGenerateCodeHelper.GetCannonReward(rewardTimes, cannonScore)
  rewardTimes = rewardTimes or -1
  local infoStr = ""
  local currentOrders = GM.MainBoardModel:GetOrders()
  local codeCountMap1 = Table.DeepCopy(GM.MainBoardModel:GetCodeCountMap(true, false, true))
  local requiredItemList = {}
  for id, order in pairs(currentOrders) do
    if order:GetInnerType() ~= MainOrderType.Special then
      local requireItems = order:GetRequirements()
      for _, item in pairs(requireItems) do
        table.insert(requiredItemList, {orderid = id, code = item})
      end
    end
  end
  table.sort(requiredItemList, function(a, b)
    local levela = GM.ItemDataModel:GetChainLevel(a.code)
    local levelb = GM.ItemDataModel:GetChainLevel(b.code)
    if levela ~= levelb then
      return levela < levelb
    else
      return a.orderid < b.orderid
    end
  end)
  local lackItemList = {}
  for _, requiredItem in ipairs(requiredItemList) do
    local codeCountMaptemp = Table.DeepCopy(codeCountMap1)
    local bLack = BoardModelHelper.CalculateLackNumForMergeRequire(requiredItem.code, codeCountMaptemp) ~= 0
    if bLack then
      table.insert(lackItemList, requiredItem)
    else
      codeCountMap1 = codeCountMaptemp
    end
  end
  local codeCountMap2 = Table.DeepCopy(GM.MainBoardModel:GetCodeCountMap(true, false, false))
  for itemType, num in pairs(codeCountMap2) do
    codeCountMap2[itemType] = math.min(num, codeCountMap1[itemType])
  end
  local orderItemConfig = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
  
  local function getDiff(itemType)
    if orderItemConfig[itemType] ~= nil then
      return orderItemConfig[itemType].DiffScore
    else
      local curLevel = GM.ItemDataModel:GetChainLevel(itemType)
      return MathUtil.IntPow(2, curLevel - 1)
    end
  end
  
  local orderNeedDiffScoreTable = {}
  infoStr = infoStr .. "\232\174\162\229\141\149\231\188\186\231\154\132\230\163\139\229\173\144\233\152\159\229\136\151\229\140\185\233\133\141\230\163\139\231\155\152\228\184\138\230\163\139\229\173\144\239\188\154\n"
  for _, lackItem in ipairs(lackItemList) do
    local curLevel = GM.ItemDataModel:GetChainLevel(lackItem.code)
    local chainId = GM.ItemDataModel:GetChainId(lackItem.code)
    lackItem.needDiffScore = getDiff(lackItem.code)
    for level = curLevel, 1, -1 do
      local itemType = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, level)
      if codeCountMap2[itemType] ~= nil and 0 < codeCountMap2[itemType] then
        codeCountMap2[itemType] = codeCountMap2[itemType] - 1
        lackItem.pairItemType = itemType
        lackItem.needDiffScore = getDiff(lackItem.code) - getDiff(itemType)
        break
      end
    end
    orderNeedDiffScoreTable[lackItem.orderid] = (orderNeedDiffScoreTable[lackItem.orderid] or 0) + lackItem.needDiffScore
    if lackItem.pairItemType ~= nil then
      infoStr = infoStr .. "\232\174\162\229\141\149" .. lackItem.orderid .. "\231\188\186\231\154\132\230\163\139\229\173\144\239\188\154" .. lackItem.code .. "\239\188\140\229\140\185\233\133\141\228\184\138" .. lackItem.pairItemType .. "\239\188\140\229\137\169\228\189\153\229\136\134\230\149\176\228\184\186" .. lackItem.needDiffScore .. "\n"
    else
      infoStr = infoStr .. "\232\174\162\229\141\149" .. lackItem.orderid .. "\231\188\186\231\154\132\230\163\139\229\173\144\239\188\154" .. lackItem.code .. "\239\188\140\230\156\170\229\140\185\233\133\141\228\184\138\230\163\139\229\173\144\239\188\140\229\137\169\228\189\153\229\136\134\230\149\176\228\184\186" .. lackItem.needDiffScore .. "\n"
    end
  end
  infoStr = infoStr .. "\n\229\144\132\232\174\162\229\141\149\230\128\187\229\137\169\228\189\153\229\136\134\230\149\176\239\188\154\n"
  table.sort(lackItemList, function(a, b)
    if orderNeedDiffScoreTable[a.orderid] ~= orderNeedDiffScoreTable[b.orderid] then
      return orderNeedDiffScoreTable[a.orderid] < orderNeedDiffScoreTable[b.orderid]
    elseif a.orderid ~= b.orderid then
      return a.orderid < b.orderid
    else
      return a.needDiffScore < b.needDiffScore
    end
  end)
  for id, score in pairs(orderNeedDiffScoreTable) do
    infoStr = infoStr .. "\232\174\162\229\141\149" .. id .. "\239\188\154" .. score .. "\n"
  end
  local X = 8
  local FindItemsAndPos = {}
  cannonScore = cannonScore + X
  infoStr = infoStr .. "\n\229\164\167\231\130\174\229\165\150\229\138\177\229\136\134\230\149\176\239\188\154" .. cannonScore .. "\239\188\136\229\138\160\228\184\138\228\186\134\233\162\157\229\164\150\231\154\132" .. X .. "\229\136\134\239\188\137\n"
  local skipItemList = {}
  
  local function findLowerItem(lackItem, includeSelf)
    local needItemLevel = GM.ItemDataModel:GetChainLevel(lackItem.code)
    local chainId = GM.ItemDataModel:GetChainId(lackItem.code)
    for level = needItemLevel - (includeSelf and 0 or 1), 1, -1 do
      local itemType = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, level)
      if cannonScore >= getDiff(itemType) then
        lackItem.needDiffScore = getDiff(itemType)
        return itemType
      end
    end
  end
  
  infoStr = infoStr .. "\n\229\164\167\231\130\174\229\165\150\229\138\177\230\163\139\229\173\144\231\172\172\228\184\128\232\189\174\231\173\155\233\128\137\239\188\154\n"
  for _, lackItem in ipairs(lackItemList) do
    if lackItem.pairItemType ~= nil then
      local updateToItem
      if cannonScore >= lackItem.needDiffScore then
        updateToItem = lackItem.code
      else
        local needItemLevel = GM.ItemDataModel:GetChainLevel(lackItem.code)
        local pairItemLevel = GM.ItemDataModel:GetChainLevel(lackItem.pairItemType)
        local chainId = GM.ItemDataModel:GetChainId(lackItem.code)
        local pairItemDiffScore = getDiff(lackItem.pairItemType)
        for level = needItemLevel - 1, pairItemLevel + 1, -1 do
          local itemType = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, level)
          if cannonScore >= getDiff(itemType) - pairItemDiffScore then
            updateToItem = itemType
            lackItem.needDiffScore = getDiff(itemType) - pairItemDiffScore
            break
          end
        end
      end
      if updateToItem == nil then
        table.insert(skipItemList, lackItem)
      else
        local function filter(itemModel)
          return itemModel:GetType() == lackItem.pairItemType
        end
        
        local items = GM.MainBoardModel:FilterItems(filter)
        Log.Assert(0 < #items, "\229\140\185\233\133\141\229\136\176\229\143\175\228\187\165\229\141\135\231\186\167\231\154\132\230\163\139\229\173\144\239\188\140\229\141\180\229\156\168\230\163\139\231\155\152\228\184\138\230\137\190\228\184\141\229\136\176\233\130\163\228\184\170\230\163\139\229\173\144\239\188\154" .. lackItem.pairItemType)
        local tempId = 1
        for i = 2, #items do
          local x1 = 7 - items[i]:GetPosition():GetX()
          local y1 = items[i]:GetPosition():GetY() - 1
          local x2 = 7 - items[tempId]:GetPosition():GetX()
          local y2 = items[tempId]:GetPosition():GetY() - 1
          if math.max(x1, y1) < math.max(x2, y2) then
            tempId = i
          end
          if math.max(x1, y1) == math.max(x2, y2) and x1 < x2 then
            tempId = i
          end
          if math.max(x1, y1) == math.max(x2, y2) and x1 == x2 and y1 > y2 then
            tempId = i
          end
        end
        cannonScore = cannonScore - lackItem.needDiffScore
        local newItem = GM.MainBoardModel:ReplaceItem(items[tempId], updateToItem, true)
        GM.BIManager:LogAcquire(lackItem.pairItemType, 1, EBIType.OrderBoostCannonRewardItems, true, EBoardType.Main, updateToItem)
        GM.BIManager:LogAction(EBIType.OrderBoostCannonRewardItems, {
          times = rewardTimes,
          isUpgrade = true,
          oldItem = lackItem.pairItemType,
          newItem = updateToItem,
          pos = items[tempId]:GetPosition():GetKey(),
          costDiff = lackItem.needDiffScore
        })
        table.insert(FindItemsAndPos, {
          Pos = items[tempId]:GetPosition(),
          itemType = updateToItem,
          itemModel = items[tempId],
          isReplace = true,
          newItem = newItem
        })
        infoStr = infoStr .. "\229\141\135\231\186\167\230\163\139\229\173\144\239\188\140\228\189\141\231\189\174\228\184\186(" .. items[tempId]:GetPosition():GetX() .. "," .. items[tempId]:GetPosition():GetY() .. ")"
        infoStr = infoStr .. lackItem.pairItemType .. "\229\141\135\231\186\167\228\184\186" .. updateToItem .. "\239\188\140\230\182\136\232\128\151\239\188\154" .. lackItem.needDiffScore .. "\239\188\140\229\137\169\228\189\153" .. cannonScore .. "\229\136\134\n"
      end
    elseif GM.MainBoardModel:IsBoardFull() then
      table.insert(skipItemList, lackItem)
    else
      local addItem
      if cannonScore >= lackItem.needDiffScore then
        addItem = lackItem.code
      else
        addItem = findLowerItem(lackItem)
      end
      if addItem ~= nil then
        local boarNewPos = BoardPosition.Create(7, 1)
        local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrder(boarNewPos)
        cannonScore = cannonScore - lackItem.needDiffScore
        local newItem = GM.MainBoardModel:GenerateItem(targetPos, addItem)
        GM.BIManager:LogAcquire(addItem, 1, EBIType.OrderBoostCannonRewardItems, true, EBoardType.Main)
        GM.BIManager:LogAction(EBIType.OrderBoostCannonRewardItems, {
          times = rewardTimes,
          isUpgrade = false,
          newItem = addItem,
          pos = targetPos:GetKey(),
          costDiff = lackItem.needDiffScore
        })
        table.insert(FindItemsAndPos, {
          Pos = targetPos,
          itemType = addItem,
          itemModel = newItem,
          isReplace = false
        })
        infoStr = infoStr .. "\229\143\145\230\148\190\230\163\139\229\173\144\239\188\140\228\189\141\231\189\174\228\184\186(" .. targetPos:GetX() .. "," .. targetPos:GetY() .. ")"
        infoStr = infoStr .. "\229\143\145\230\148\190\228\186\134" .. addItem .. "\239\188\140\230\182\136\232\128\151\239\188\154" .. lackItem.needDiffScore .. "\239\188\140\229\137\169\228\189\153" .. cannonScore .. "\229\136\134\n"
      end
    end
    if X >= cannonScore then
      break
    end
  end
  infoStr = infoStr .. "\n\231\172\172\228\186\140\232\189\174\229\164\132\231\144\134\228\185\139\229\137\141\232\183\179\232\191\135\231\154\132\230\163\139\229\173\144\n"
  local cacheItems = {}
  for _, lackItem in ipairs(skipItemList) do
    if X >= cannonScore then
      break
    end
    local addItem = findLowerItem(lackItem, true)
    if addItem ~= nil then
      cannonScore = cannonScore - lackItem.needDiffScore
      if GM.MainBoardModel:IsBoardFull() then
        table.insert(cacheItems, addItem)
        GM.BIManager:LogAcquire(addItem, 1, EBIType.OrderBoostCannonRewardItems, true, EBoardType.Main)
        GM.BIManager:LogAction(EBIType.OrderBoostCannonRewardItems, {
          times = rewardTimes,
          isUpgrade = false,
          newItem = addItem,
          pos = "cache",
          costDiff = lackItem.needDiffScore
        })
        infoStr = infoStr .. "\229\143\145\230\148\190\228\186\134" .. addItem .. "\229\136\176\231\188\147\229\173\152\233\152\159\229\136\151\239\188\140\230\182\136\232\128\151\239\188\154" .. lackItem.needDiffScore .. "\239\188\140\229\137\169\228\189\153" .. cannonScore .. "\229\136\134\n"
      else
        local boarNewPos = BoardPosition.Create(7, 1)
        local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrder(boarNewPos)
        local newItem = GM.MainBoardModel:GenerateItem(targetPos, addItem)
        GM.BIManager:LogAcquire(addItem, 1, EBIType.OrderBoostCannonRewardItems, true, EBoardType.Main)
        GM.BIManager:LogAction(EBIType.OrderBoostCannonRewardItems, {
          times = rewardTimes,
          isUpgrade = false,
          newItem = addItem,
          pos = targetPos:GetKey(),
          costDiff = lackItem.needDiffScore
        })
        table.insert(FindItemsAndPos, {
          Pos = targetPos,
          itemType = addItem,
          itemModel = newItem,
          isReplace = false
        })
        infoStr = infoStr .. "\229\143\145\230\148\190\230\163\139\229\173\144\239\188\140\228\189\141\231\189\174\228\184\186(" .. targetPos:GetX() .. "," .. targetPos:GetY() .. ")"
        infoStr = infoStr .. "\229\143\145\230\148\190\228\186\134" .. addItem .. "\239\188\140\230\182\136\232\128\151\239\188\154" .. lackItem.needDiffScore .. "\239\188\140\229\137\169\228\189\153" .. cannonScore .. "\229\136\134\n"
      end
    end
  end
  infoStr = infoStr .. "\n\231\172\172\228\184\137\232\189\174\233\154\143\230\156\186\229\143\145\230\148\1905\231\186\167\230\163\139\229\173\144\n"
  local unlocklv5Items = {}
  local orderItemsConfig = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
  for itemCode, _ in pairs(orderItemsConfig) do
    if GM.ItemDataModel:GetChainLevel(itemCode) == 5 then
      local isUnLockProduct = false
      local chainId = GM.ItemDataModel:GetChainId(itemCode)
      local generators = GM.ItemDataModel:GetChainGenerators(chainId)
      for _, generator in ipairs(generators) do
        if GM.ItemDataModel:IsUnlocked(generator) then
          isUnLockProduct = true
          break
        end
      end
      if isUnLockProduct then
        table.insert(unlocklv5Items, itemCode)
      end
    end
  end
  while X < cannonScore do
    local lackItem = {
      code = Table.ListRandomSelectOne(unlocklv5Items)
    }
    local addItem
    if cannonScore > getDiff(lackItem.code) then
      addItem = lackItem.code
      lackItem.needDiffScore = getDiff(lackItem.code)
    else
      addItem = findLowerItem(lackItem)
    end
    if addItem ~= nil then
      cannonScore = cannonScore - lackItem.needDiffScore
      if GM.MainBoardModel:IsBoardFull() then
        table.insert(cacheItems, addItem)
        GM.BIManager:LogAcquire(addItem, 1, EBIType.OrderBoostCannonRewardItems, true, EBoardType.Main)
        GM.BIManager:LogAction(EBIType.OrderBoostCannonRewardItems, {
          times = rewardTimes,
          isUpgrade = false,
          newItem = addItem,
          pos = "cache",
          costDiff = lackItem.needDiffScore
        })
        infoStr = infoStr .. "\229\143\145\230\148\190\228\186\134" .. addItem .. "\229\136\176\231\188\147\229\173\152\233\152\159\229\136\151\239\188\140\230\182\136\232\128\151\239\188\154" .. lackItem.needDiffScore .. "\239\188\140\229\137\169\228\189\153" .. cannonScore .. "\229\136\134\n"
      else
        local boarNewPos = BoardPosition.Create(7, 1)
        local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrder(boarNewPos)
        local newItem = GM.MainBoardModel:GenerateItem(targetPos, addItem)
        GM.BIManager:LogAcquire(addItem, 1, EBIType.OrderBoostCannonRewardItems, true, EBoardType.Main)
        GM.BIManager:LogAction(EBIType.OrderBoostCannonRewardItems, {
          times = rewardTimes,
          isUpgrade = false,
          newItem = addItem,
          pos = targetPos:GetKey(),
          costDiff = lackItem.needDiffScore
        })
        table.insert(FindItemsAndPos, {
          Pos = targetPos,
          itemType = addItem,
          itemModel = newItem,
          isReplace = false
        })
        infoStr = infoStr .. "\229\143\145\230\148\190\230\163\139\229\173\144\239\188\140\228\189\141\231\189\174\228\184\186(" .. targetPos:GetX() .. "," .. targetPos:GetY() .. ")"
        infoStr = infoStr .. "\229\143\145\230\148\190\228\186\134" .. addItem .. "\239\188\140\230\182\136\232\128\151\239\188\154" .. lackItem.needDiffScore .. "\239\188\140\229\137\169\228\189\153" .. cannonScore .. "\229\136\134\n"
      end
    end
  end
  table.sort(cacheItems, function(a, b)
    return getDiff(a) < getDiff(b)
  end)
  for _, itemType in ipairs(cacheItems) do
    table.insert(FindItemsAndPos, {itemType = itemType})
  end
  GM.MainBoardModel:CacheItems(cacheItems, CacheItemType.Type2)
  Log.Info(infoStr)
  return FindItemsAndPos
end
