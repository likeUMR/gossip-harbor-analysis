SmartRewardHelper = {}
SmartRewardHelper.__index = SmartRewardHelper
TESTINFO_SmtRwrd = {}
local slotSequence = {
  1,
  2,
  11,
  3,
  8,
  4,
  5,
  18,
  10,
  15
}
IntllgtRwrd_ItemHelpedToMerge = {}
IntllgtRwrd_ItemForOrder = {}

function SmartRewardHelper.InsertHelpedItem(code)
  table.insert(IntllgtRwrd_ItemHelpedToMerge, code)
end

function SmartRewardHelper.InsertItemForOrder(code, slot)
  if IntllgtRwrd_ItemForOrder[slot] == nil then
    IntllgtRwrd_ItemForOrder[slot] = {}
  end
  table.insert(IntllgtRwrd_ItemForOrder[slot], code)
end

function SmartRewardHelper.ClearIntllgtRwrdInfo()
  IntllgtRwrd_ItemHelpedToMerge = {}
  IntllgtRwrd_ItemForOrder = {}
  TESTINFO_SmtRwrd = {}
end

function SmartRewardHelper.GetCodesFor_ItemSpread(itemScoreMapCfg, totalScore, logLabel)
  local data = {}
  data.resultCount = 1
  data.isNeedUpFind = true
  return SmartRewardHelper.GetCodesForPlane(itemScoreMapCfg, totalScore, logLabel, data)
end

function SmartRewardHelper.GetCodesForOrderBoost(itemScoreMapCfg, itemWeightMapCfg, totalScore, logLabel, otherBIInfo)
  SmartRewardHelper.ClearIntllgtRwrdInfo()
  SmartRewardHelper.AppendTestInfo("\230\153\186\232\131\189\230\163\139\229\173\144\229\143\145\229\165\150", logLabel and " for " .. logLabel .. "\n" or "\n")
  SmartRewardHelper.AppendTestInfo("\230\128\187\229\136\134 ", totalScore, "\n")
  local codeCountMap = GM.MainBoardModel:GetCodeCountMap(true, false, true)
  local itemsUnfinished = {}
  local itemsFinished = {}
  SmartRewardHelper.MarkItemFinishedOrNot(itemsUnfinished, itemsFinished, {1, 2}, codeCountMap)
  SmartRewardHelper.SortItemsByLevelAndSlot(itemsUnfinished)
  SmartRewardHelper.TestPrintItemFinishedOrNot(itemsUnfinished, itemsFinished, {1, 2})
  SmartRewardHelper.CalculateLackNumForUnfinished(itemsUnfinished, codeCountMap)
  local codeSplitResMap = {}
  local slotArray = {}
  local slotLackItemMap = {}
  SmartRewardHelper.CalculateSupplyScoreForOrder(itemsUnfinished, itemScoreMapCfg, slotLackItemMap, slotArray, codeSplitResMap)
  SmartRewardHelper.SortOrderAndItem(slotArray, slotLackItemMap)
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\143\145\230\148\190\230\163\139\229\173\144\232\174\161\231\174\151\239\188\154\n")
  local skippedItems = {}
  local res = {}
  for _, slot in ipairs(slotArray) do
    if totalScore <= 0 then
      break
    end
    local data = slotLackItemMap[slot]
    local items = data.Items
    for _, item in ipairs(items) do
      if totalScore <= 0 then
        break
      end
      totalScore = SmartRewardHelper.TryCalculateRewardItems(res, item, slot, totalScore, skippedItems, itemScoreMapCfg, codeSplitResMap)
    end
  end
  local lackNum5, lackNum4, lackNum8
  if 0 < totalScore then
    SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\165\150\229\138\177\229\136\134\229\137\169\228\189\153", totalScore, ", \229\176\157\232\175\149\229\143\145\230\148\190slot5/4/8\230\163\139\229\173\144\239\188\154\n")
    local codeOne5, codeOne4, codeOne8
    local ordersRef = GM.MainBoardModel:GetOrders()
    for _, order in pairs(ordersRef) do
      if order:GetSlot() == 5 then
        codeOne5 = order:GetRequirements()[1]
      elseif order:GetSlot() == 4 then
        codeOne4 = order:GetRequirements()[1]
      elseif order:GetSlot() == 8 then
        codeOne8 = order:GetRequirements()[1]
      end
    end
    if codeOne5 then
      totalScore, lackNum5 = SmartRewardHelper.DeliverRandomItemByWeight(res, codeOne5, 5, totalScore, itemScoreMapCfg, itemWeightMapCfg, codeCountMap)
    end
    if 0 < totalScore and codeOne4 then
      totalScore, lackNum4 = SmartRewardHelper.DeliverRandomItemByWeight(res, codeOne4, 4, totalScore, itemScoreMapCfg, itemWeightMapCfg, codeCountMap)
    end
    if 0 < totalScore and codeOne8 then
      totalScore, lackNum8 = SmartRewardHelper.DeliverRandomItemByWeight(res, codeOne8, 8, totalScore, itemScoreMapCfg, itemWeightMapCfg, codeCountMap)
    end
  end
  if 0 < totalScore then
    SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\165\150\229\138\177\229\136\134\229\137\169\228\189\153", totalScore, ", \229\176\157\232\175\149\232\161\165\233\189\144\229\137\169\228\189\153\230\156\170\229\174\140\230\136\144\230\163\139\229\173\144\239\188\154\n")
    itemsUnfinished = {}
    for _, skippedItem in ipairs(skippedItems) do
      table.insert(itemsUnfinished, {
        Code = skippedItem.Code,
        Slot = skippedItem.Slot
      })
    end
    local ordersRef = GM.MainBoardModel:GetOrders()
    for i, order in pairs(ordersRef) do
      local reqs = order:GetRequirements()
      if order:GetSlot() == MainOrderSlotDefinition.SpecialSlot or order:GetSlot() == 1 or order:GetSlot() == 2 then
      else
        for i, req in ipairs(reqs) do
          if order:GetSlot() == 5 and i == 1 then
            if 0 < lackNum5 then
              table.insert(itemsUnfinished, {
                Code = req,
                Slot = order:GetSlot(),
                LackNum = lackNum5
              })
            end
          elseif order:GetSlot() == 4 and i == 1 then
            if 0 < lackNum4 then
              table.insert(itemsUnfinished, {
                Code = req,
                Slot = order:GetSlot(),
                LackNum = lackNum4
              })
            end
          elseif order:GetSlot() == 8 and i == 1 then
            if 0 < lackNum8 then
              table.insert(itemsUnfinished, {
                Code = req,
                Slot = order:GetSlot(),
                LackNum = lackNum8
              })
            end
          else
            table.insert(itemsUnfinished, {
              Code = req,
              Slot = order:GetSlot()
            })
          end
        end
      end
    end
    table.sort(itemsUnfinished, function(a, b)
      local levelA = GM.ItemDataModel:GetChainLevel(a.Code)
      local levelB = GM.ItemDataModel:GetChainLevel(b.Code)
      return levelA < levelB
    end)
    SmartRewardHelper.AppendTestInfo("\233\153\164Slot1/2\231\154\132\230\137\128\230\156\137\230\163\139\229\173\144 \229\146\140 Slot5/4/8\231\154\132\229\143\175\232\162\171\229\144\136\230\136\144\231\154\132\231\172\172\228\184\128\228\184\170\230\163\139\229\173\144 \228\187\165\229\164\150\239\188\140\229\133\182\228\189\153\231\154\132\230\163\139\229\173\144\239\188\154\n")
    for _, data in ipairs(itemsUnfinished) do
      SmartRewardHelper.AppendTestInfo(data.Code, ", slot ", data.Slot, "\n")
    end
    SmartRewardHelper.CalculateLackNumForUnfinished(itemsUnfinished, codeCountMap)
    SmartRewardHelper.CalculateSupplyScoreForUnfinished(itemsUnfinished, itemScoreMapCfg, codeSplitResMap)
    table.sort(itemsUnfinished, function(a, b)
      return a.SupplyScore < b.SupplyScore
    end)
    SmartRewardHelper.AppendTestInfo("\230\137\128\230\156\137\230\156\170\229\174\140\230\136\144\230\163\139\229\173\144\230\140\137\232\161\165\233\189\144\229\165\150\229\138\177\229\136\134\230\142\146\229\186\143\239\188\140\230\151\160\232\167\134\230\167\189\228\189\141\239\188\154\n")
    for _, data in ipairs(itemsUnfinished) do
      SmartRewardHelper.AppendTestInfo(data.Code, ", slot ", data.Slot, ", supplyScore ", data.SupplyScore, "\n")
    end
    SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\143\145\230\148\190\230\163\139\229\173\144\232\174\161\231\174\151\239\188\154\n")
    for _, item in ipairs(itemsUnfinished) do
      if totalScore <= 0 then
        break
      end
      totalScore = SmartRewardHelper.TryCalculateRewardItems(res, item, item.Slot, totalScore, skippedItems, itemScoreMapCfg, codeSplitResMap)
    end
  end
  totalScore = SmartRewardHelper.DeliverSkippedItems(res, skippedItems, itemScoreMapCfg, totalScore, itemsUnfinished)
  totalScore = SmartRewardHelper.DeliverRandom205_206(res, totalScore, itemScoreMapCfg)
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\230\156\128\231\187\136\229\165\150\229\138\177:\n")
  for _, code in ipairs(res) do
    SmartRewardHelper.AppendTestInfo(code, ", score ", itemScoreMapCfg[code], "\n")
  end
  SmartRewardHelper.AppendTestInfo("\229\165\150\229\138\177\229\136\134\229\137\169\228\189\153", totalScore, "\n")
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\184\174\229\138\169\229\174\140\230\136\144\231\154\132\230\163\139\229\173\144:\n")
  SmartRewardHelper.AppendTestInfo(table.concat(IntllgtRwrd_ItemHelpedToMerge, ", "), "\n")
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\143\145\230\148\190\231\154\132\230\163\139\229\173\144\229\143\138\229\175\185\229\186\148\230\167\189\228\189\141:\n")
  for slot, codes in pairs(IntllgtRwrd_ItemForOrder) do
    SmartRewardHelper.AppendTestInfo("slot ", slot, " : ", table.concat(codes, ", "), "\n")
  end
  EventDispatcher.DispatchEvent(EEventType.TestOutputTableInfo, TESTINFO_SmtRwrd)
  SmartRewardHelper.BILogHelpedItem(EBIType.SmartRewardOrderBoostItem, otherBIInfo)
  SmartRewardHelper.BILogItemForOrder(EBIType.SmartRewardOrderBoostItemSlot, otherBIInfo)
  return res
end

function SmartRewardHelper.GetCodesForPlane(itemScoreMapCfg, totalScore, logLabel, dataInfo)
  dataInfo = dataInfo or {}
  if dataInfo.resultCount == nil then
    dataInfo.resultCount = math.maxinteger
  end
  SmartRewardHelper.ClearIntllgtRwrdInfo()
  SmartRewardHelper.AppendTestInfo("\230\153\186\232\131\189\230\163\139\229\173\144\229\143\145\229\165\150", logLabel and " for " .. logLabel .. "\n" or "\n")
  SmartRewardHelper.AppendTestInfo("\230\128\187\229\136\134 ", totalScore .. "\n")
  local codeCountMap = GM.MainBoardModel:GetCodeCountMap(true, false, true)
  local itemsUnfinished = {}
  local itemsFinished = {}
  SmartRewardHelper.MarkItemFinishedOrNot(itemsUnfinished, itemsFinished, nil, codeCountMap)
  SmartRewardHelper.SortItemsByLevelAndSlot(itemsUnfinished)
  SmartRewardHelper.TestPrintItemFinishedOrNot(itemsUnfinished, itemsFinished, nil)
  SmartRewardHelper.CalculateLackNumForUnfinished(itemsUnfinished, codeCountMap)
  local codeSplitResMap = {}
  local slotArray = {}
  local slotLackItemMap = {}
  SmartRewardHelper.CalculateSupplyScoreForOrder(itemsUnfinished, itemScoreMapCfg, slotLackItemMap, slotArray, codeSplitResMap, dataInfo)
  SmartRewardHelper.SortOrderAndItem(slotArray, slotLackItemMap)
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\143\145\230\148\190\230\163\139\229\173\144\232\174\161\231\174\151\239\188\154\n")
  local skippedItems = {}
  local res = {}
  for _, slot in ipairs(slotArray) do
    if totalScore <= 0 then
      break
    end
    local data = slotLackItemMap[slot]
    local items = data.Items
    for _, item in ipairs(items) do
      if totalScore <= 0 or dataInfo.resultCount <= 0 then
        break
      end
      totalScore = SmartRewardHelper.TryCalculateRewardItems(res, item, slot, totalScore, skippedItems, itemScoreMapCfg, codeSplitResMap, dataInfo)
    end
  end
  totalScore = SmartRewardHelper.DeliverSkippedItems(res, skippedItems, itemScoreMapCfg, totalScore, itemsUnfinished, dataInfo)
  totalScore = SmartRewardHelper.DeliverRandom205_206(res, totalScore, itemScoreMapCfg, dataInfo)
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\230\156\128\231\187\136\229\165\150\229\138\177:\n")
  for _, code in ipairs(res) do
    SmartRewardHelper.AppendTestInfo(code, ", score ", itemScoreMapCfg[code], "\n")
  end
  SmartRewardHelper.AppendTestInfo("\229\165\150\229\138\177\229\136\134\229\137\169\228\189\153", totalScore, "\n")
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\229\184\174\229\138\169\229\174\140\230\136\144\231\154\132\230\163\139\229\173\144:\n")
  for _, code in ipairs(IntllgtRwrd_ItemHelpedToMerge) do
    SmartRewardHelper.AppendTestInfo(code, "\n")
  end
  EventDispatcher.DispatchEvent(EEventType.TestOutputTableInfo, TESTINFO_SmtRwrd)
  SmartRewardHelper.BILogHelpedItem(EBIType.SmartRewardPlaneItem)
  return res
end

function SmartRewardHelper.TryCalculateRewardItems(res, targetItem, slot, totalScore, skippedItems, itemScoreMapCfg, codeSplitResMap, data)
  if data == nil then
    data = {}
    data.resultCount = math.maxinteger
  end
  local code = targetItem.Code
  local lackNum = targetItem.LackNum
  local supplyScore = targetItem.SupplyScore
  local chain = GM.ItemDataModel:GetChainId(code)
  if supplyScore > totalScore + 10 then
    table.insert(skippedItems, {Code = code, Slot = slot})
    SmartRewardHelper.AppendTestInfo("\232\183\179\232\191\135 ", code, ", score ", supplyScore, ", \229\137\169\228\189\153\229\165\150\229\138\177\229\136\134 ", totalScore, "\n")
  elseif totalScore <= supplyScore then
    totalScore = SmartRewardHelper.CalculateRewardItems(res, lackNum, chain, totalScore, itemScoreMapCfg, codeSplitResMap, slot, data)
    SmartRewardHelper.InsertHelpedItem(code)
    if 0 < totalScore then
      SmartRewardHelper.AppendTestInfo("\229\137\169\228\189\153\229\165\150\229\138\177\229\136\134\226\137\164\232\161\165\233\189\144\229\165\150\229\138\177\229\136\134\226\137\164\229\137\169\228\189\153\229\165\150\229\138\177\229\136\134+10\239\188\140\228\189\134\229\143\145\230\148\190\229\144\142\229\137\169\228\189\153\229\165\150\229\138\177\229\136\134\228\187\141\228\184\186", totalScore, ", \231\150\145\228\188\188\230\156\137\233\148\153\n")
    end
  else
    totalScore = SmartRewardHelper.CalculateRewardItems(res, lackNum, chain, totalScore, itemScoreMapCfg, codeSplitResMap, slot, data)
    SmartRewardHelper.InsertHelpedItem(code)
  end
  return totalScore
end

function SmartRewardHelper.CalculateSupplyScoreForUnfinished(itemsUnfinished, itemScoreMapCfg, codeSplitResMap)
  for _, data in ipairs(itemsUnfinished) do
    local supplyScore = 0
    supplyScore = SmartRewardHelper.CalculateSupplyScoreForSingleCode(data.Code, data.LackNum, itemScoreMapCfg, codeSplitResMap, {})
    data.SupplyScore = supplyScore
  end
end

function SmartRewardHelper.DeliverRandomItemByWeight(res, code, slot, totalScore, itemScoreMapCfg, itemWeightMapCfg, codeCountMap)
  local lackNum = BoardModelHelper.CalculateLackNumForMergeRequire(code, codeCountMap)
  SmartRewardHelper.AppendTestInfo("----\230\140\137\230\157\131\233\135\141\233\154\143\230\156\186\229\143\145\230\148\190slot", slot, "\231\172\172\228\184\128\228\184\170\230\163\139\229\173\144", code, "\231\154\132\229\144\140\229\144\136\230\136\144\231\186\191\230\163\139\229\173\144\239\188\140\229\136\157\229\167\139\231\188\186\229\164\177\229\128\188", lackNum, "\n")
  if lackNum <= 0 then
    SmartRewardHelper.AppendTestInfo("\230\163\139\229\173\144\229\183\178\229\143\175\229\144\136\230\136\144\239\188\140\232\183\179\232\191\135\227\128\130\231\155\174\230\160\135\230\163\139\229\173\144\239\188\154", code, "\n")
    return totalScore, lackNum
  end
  local chainId = GM.ItemDataModel:GetChainId(code)
  local availableCodes = {}
  for _, pairCodeWeight in ipairs(itemWeightMapCfg) do
    if GM.ItemDataModel:GetChainId(pairCodeWeight.Code) == chainId and GM.ItemDataModel:GetChainLevel(pairCodeWeight.Code) >= 3 and itemScoreMapCfg[pairCodeWeight.Code] > 5 then
      SmartRewardHelper.AppendTestInfo("\229\143\175\233\128\137\230\163\139\229\173\144\239\188\154\230\157\131\233\135\141\239\188\154\229\136\134\230\149\176", pairCodeWeight.Code, ":", pairCodeWeight.Weight, ":", itemScoreMapCfg[pairCodeWeight.Code], "\n")
      table.insert(availableCodes, pairCodeWeight)
    end
  end
  if #availableCodes == 0 then
    SmartRewardHelper.AppendTestInfo("\230\151\160\230\179\149\230\137\190\229\136\176\231\173\137\231\186\167>=3\239\188\140\229\165\150\229\138\177\229\136\134>5\231\154\132\229\144\140\229\144\136\230\136\144\231\186\191\230\163\139\229\173\144\227\128\130\231\155\174\230\160\135\230\163\139\229\173\144\239\188\154", code)
    return totalScore, lackNum
  end
  local scoreLimit = 70
  while true do
    local r = Table.ListWeightSelectOne(availableCodes)
    local curCode = r.Code
    local curScore = itemScoreMapCfg[curCode]
    SmartRewardHelper.AppendToResult(res, curCode, slot)
    totalScore = totalScore - curScore
    scoreLimit = scoreLimit - curScore
    lackNum = lackNum - GM.ItemDataModel:GetEquivalentLevelOneItemCount(curCode)
    SmartRewardHelper.AppendTestInfo("\233\154\143\230\156\186\230\138\189\229\143\150\230\163\139\229\173\144\239\188\154\229\136\134\230\149\176", curCode, ":", curScore, ", \231\180\175\232\174\161", 70 - scoreLimit, "\n")
    if lackNum <= 0 then
      SmartRewardHelper.InsertHelpedItem(code)
      break
    elseif totalScore <= 0 or scoreLimit <= 0 then
      break
    end
  end
  SmartRewardHelper.AppendTestInfo("\229\174\140\230\136\144\230\140\137\230\157\131\233\135\141\233\154\143\230\156\186\229\143\145\230\148\190\239\188\140\231\155\174\230\160\135\229\144\136\230\136\144", code, ", \229\137\169\228\189\153\231\188\186\229\164\177\230\149\176\233\135\143", lackNum, ", \229\137\169\228\189\153\229\165\150\229\138\177\229\136\134", totalScore, ", \229\137\169\228\189\153\232\175\165\230\167\189\228\189\141\230\156\128\229\164\167\229\165\150\229\138\177\229\136\134", scoreLimit, "\n")
  return totalScore, lackNum
end

function SmartRewardHelper.DeliverHighestCodeForCode(res, code, slot, totalScore, itemScoreMapCfg, codeCountMap)
  local highestCode = SmartRewardHelper.GetHighestCodeInConfig(code, itemScoreMapCfg)
  local lackNum = BoardModelHelper.CalculateLackNumForMergeRequire(code, codeCountMap)
  local n1 = math.ceil(lackNum / GM.ItemDataModel:GetEquivalentLevelOneItemCount(highestCode))
  local n2 = math.ceil(totalScore / itemScoreMapCfg[highestCode])
  local n = math.min(n1, n2)
  for i = 1, n do
    SmartRewardHelper.AppendToResult(res, highestCode, slot)
    totalScore = totalScore - itemScoreMapCfg[highestCode]
  end
  if n == n1 and 0 < n then
    SmartRewardHelper.InsertHelpedItem(code)
  end
  SmartRewardHelper.AppendTestInfo("\229\143\145\230\148\190 ", n, " \228\184\170 ", highestCode, ", \229\137\169\228\189\153\229\165\150\229\138\177\229\136\134 ", totalScore, "\n")
  return totalScore
end

function SmartRewardHelper.MarkItemFinishedOrNot(itemsUnfinished, itemsFinished, priorSlots, codeCountMap)
  local ordersRefTemp = GM.MainBoardModel:GetOrders()
  local orderRef = {}
  for _, slot in ipairs(slotSequence) do
    if ordersRefTemp[slot] then
      table.insert(orderRef, ordersRefTemp[slot])
    end
  end
  for slot, order in pairs(ordersRefTemp) do
    if not Table.Contain(slotSequence, slot) then
      table.insert(orderRef, ordersRefTemp[slot])
    end
  end
  for i, order in pairs(orderRef) do
    local reqs = order:GetRequirements()
    if order:GetSlot() == MainOrderSlotDefinition.SpecialSlot or priorSlots and not Table.Contain(priorSlots, order:GetSlot()) then
    else
      local function FuncHasAllReqs(order, codeCountMap)
        local tempDeletedItems = {}
        
        local reqs = order:GetRequirements()
        for _, req in ipairs(reqs) do
          if codeCountMap[req] and 0 < codeCountMap[req] then
            codeCountMap[req] = codeCountMap[req] - 1
            if not tempDeletedItems[req] then
              tempDeletedItems[req] = 0
            end
            tempDeletedItems[req] = tempDeletedItems[req] + 1
          else
            for code, num in pairs(tempDeletedItems) do
              codeCountMap[code] = codeCountMap[code] + num
            end
            tempDeletedItems = {}
            return false
          end
        end
        return true
      end
      
      if (order:GetState() == OrderState.CanDeliver or order:GetState() == OrderState.Finished) and FuncHasAllReqs(order, codeCountMap) then
        for _, req in ipairs(reqs) do
          table.insert(itemsFinished, {
            Code = req,
            Slot = order:GetSlot()
          })
        end
      else
        for _, req in ipairs(reqs) do
          table.insert(itemsUnfinished, {
            Code = req,
            Slot = order:GetSlot()
          })
        end
      end
    end
  end
end

function SmartRewardHelper.TestPrintItemFinishedOrNot(itemsUnfinished, itemsFinished, priorSlots)
  if priorSlots then
    SmartRewardHelper.AppendTestInfo("\228\188\152\229\133\136\232\174\161\231\174\151\230\167\189\228\189\141: ")
    for _, prSt in ipairs(priorSlots) do
      SmartRewardHelper.AppendTestInfo(" ", prSt)
    end
    SmartRewardHelper.AppendTestInfo("\n")
  end
  SmartRewardHelper.AppendTestInfo("\229\136\157\231\173\155\230\156\170\229\174\140\230\136\144\232\174\162\229\141\149\228\184\138\231\154\132\230\163\139\229\173\144\n")
  for _, data in ipairs(itemsUnfinished) do
    SmartRewardHelper.AppendTestInfo(data.Code, ", slot ", data.Slot, "\n")
  end
  SmartRewardHelper.AppendTestInfo("\229\136\157\231\173\155\229\183\178\229\174\140\230\136\144\232\174\162\229\141\149\228\184\138\230\163\139\229\173\144\n")
  for _, data in ipairs(itemsFinished) do
    SmartRewardHelper.AppendTestInfo(data.Code, ", slot ", data.Slot, "\n")
  end
end

function SmartRewardHelper.SortItemsByLevelAndSlot(items)
  table.sort(items, function(a, b)
    local levelA = GM.ItemDataModel:GetChainLevel(a.Code)
    local levelB = GM.ItemDataModel:GetChainLevel(b.Code)
    if levelA ~= levelB then
      return levelA < levelB
    else
      local slotIndexA = 9999
      local slotIndexB = 9999
      for i, slot in ipairs(slotSequence) do
        if slot == a.Slot then
          slotIndexA = i
        end
        if slot == b.Slot then
          slotIndexB = i
        end
      end
      return slotIndexA < slotIndexB
    end
  end)
end

function SmartRewardHelper.CalculateLackNumForUnfinished(itemsUnfinished, codeCountMap)
  for _, data in ipairs(itemsUnfinished) do
    if data.LackNum == nil then
      local lackNum = BoardModelHelper.CalculateLackNumForMergeRequire(data.Code, codeCountMap)
      data.LackNum = lackNum
    end
  end
  for i = #itemsUnfinished, 1, -1 do
    if itemsUnfinished[i].LackNum == 0 then
      table.remove(itemsUnfinished, i)
    end
  end
  SmartRewardHelper.AppendTestInfo("\232\174\161\231\174\151\230\156\170\229\174\140\230\136\144\230\163\139\229\173\144\229\175\185\229\186\148\231\188\186\229\164\177\230\149\176\233\135\143\239\188\136\231\173\137\230\149\136\228\184\128\231\186\167\230\163\139\229\173\144\239\188\137\n")
  for _, data in ipairs(itemsUnfinished) do
    SmartRewardHelper.AppendTestInfo(data.Code, ", slot ", data.Slot, ", lackNum ", data.LackNum, ", bin ", MathUtil.Dec2BinStr(data.LackNum), " (", SmartRewardHelper.LackNum2Codes(data.LackNum, GM.ItemDataModel:GetChainId(data.Code)), ")", "\n")
  end
end

function SmartRewardHelper.CalculateRewardItems(res, lackNum, chainID, totalScore, itemScoreMapCfg, codeSplitResMap, slot, data)
  local cnt = 0
  while 0 < lackNum and not (totalScore <= 0) and not (0 >= data.resultCount) do
    if lackNum & 1 == 1 then
      local rewardCode = GM.ItemDataModel:GetTypeByChainAndLevel(chainID, cnt + 1)
      local rewardScore = itemScoreMapCfg[rewardCode]
      if rewardScore then
        SmartRewardHelper.AppendToResult(res, rewardCode, slot)
        totalScore = totalScore - rewardScore
        SmartRewardHelper.AppendTestInfo(rewardCode, " \233\133\141\231\189\174\229\173\152\229\156\168\239\188\140\231\155\180\230\142\165\229\143\145\230\148\190, \229\165\150\229\138\177\229\136\134 ", rewardScore, "\n")
        data.resultCount = data.resultCount - 1
      else
        local codeTemp, multi, scoreMulti = SmartRewardHelper.GetEquivalentCode(rewardCode, itemScoreMapCfg, codeSplitResMap)
        if codeTemp then
          local realNum = 0
          for j = 1, multi do
            SmartRewardHelper.AppendToResult(res, codeTemp, slot)
            data.resultCount = data.resultCount - 1
            realNum = realNum + 1
            if 0 >= data.resultCount then
              break
            end
          end
          totalScore = totalScore - realNum * itemScoreMapCfg[codeTemp]
          SmartRewardHelper.AppendTestInfo(rewardCode, " \229\136\134\232\167\163\228\184\186 ", codeTemp, " X ", realNum, " = ", realNum * itemScoreMapCfg[codeTemp], "\n")
        elseif data.isNeedUpFind then
          local nxtLevel = cnt + 2
          for i = nxtLevel, nxtLevel + 4 do
            local codeNxt = GM.ItemDataModel:GetTypeByChainAndLevel(GM.ItemDataModel:GetChainId(rewardCode), i)
            if itemScoreMapCfg[codeNxt] then
              totalScore = totalScore - itemScoreMapCfg[codeNxt]
              SmartRewardHelper.AppendToResult(res, codeNxt, slot)
              data.resultCount = data.resultCount - 1
              SmartRewardHelper.AppendTestInfo(rewardCode, "\229\144\145\228\184\138\232\161\165\229\133\133\229\165\150\229\138\177\230\163\139\229\173\144", codeNxt, " = ", itemScoreMapCfg[codeNxt], "\n")
              break
            end
          end
        else
          SmartRewardHelper.AppendTestInfo(rewardCode, "\233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\228\184\148\230\151\160\230\179\149\229\136\134\232\167\163\239\188\136\231\173\150\229\136\146\232\175\180\229\165\189\228\188\154\233\133\1411\231\186\167\230\163\139\229\173\144\231\154\132\239\188\137\n")
        end
      end
    end
    lackNum = lackNum >> 1
    cnt = cnt + 1
  end
  return totalScore
end

function SmartRewardHelper.CalculateSupplyScoreForSingleCode(code, lackNum, itemScoreMapCfg, codeSplitResMap, dataInfo)
  local supplyScore = 0
  local cnt = 0
  while 0 < lackNum do
    if lackNum & 1 == 1 then
      local codeSupply = GM.ItemDataModel:GetTypeByChainAndLevel(GM.ItemDataModel:GetChainId(code), cnt + 1)
      if itemScoreMapCfg[codeSupply] then
        supplyScore = supplyScore + itemScoreMapCfg[codeSupply]
        SmartRewardHelper.AppendTestInfo(codeSupply, "\233\133\141\231\189\174\232\161\168\228\184\173\229\173\152\229\156\168\239\188\140\229\165\150\229\138\177\229\136\134", itemScoreMapCfg[codeSupply], "\n")
      else
        local codeTemp, multi, scoreMulti = SmartRewardHelper.GetEquivalentCode(codeSupply, itemScoreMapCfg, codeSplitResMap)
        if codeTemp then
          supplyScore = supplyScore + scoreMulti
          SmartRewardHelper.AppendTestInfo(codeSupply, " \229\136\134\232\167\163\228\184\186 ", codeTemp, " X ", multi, " = ", scoreMulti, "\n")
        elseif dataInfo.isNeedUpFind then
          local nxtLevel = cnt + 2
          for i = nxtLevel, nxtLevel + 4 do
            local codeNxt = GM.ItemDataModel:GetTypeByChainAndLevel(GM.ItemDataModel:GetChainId(code), i)
            if itemScoreMapCfg[codeNxt] then
              supplyScore = supplyScore + itemScoreMapCfg[codeNxt]
              SmartRewardHelper.AppendTestInfo(codeSupply, "\229\144\145\228\184\138\232\161\165\229\133\133\229\165\150\229\138\177\230\163\139\229\173\144", codeNxt, " = ", itemScoreMapCfg[codeNxt], "\n")
              break
            end
          end
        else
          supplyScore = supplyScore + 0
          SmartRewardHelper.AppendTestInfo(codeSupply, " \233\133\141\231\189\174\228\184\141\229\173\152\229\156\168\228\184\148\230\151\160\230\179\149\229\136\134\232\167\163\227\128\130\232\181\139\229\128\188\232\161\165\233\189\144\229\165\150\229\138\177\229\136\134\228\184\1860\239\188\136\231\173\150\229\136\146\232\175\180\229\165\189\228\188\154\233\133\1411\231\186\167\230\163\139\229\173\144\231\154\132\239\188\137\n")
        end
      end
    end
    lackNum = lackNum >> 1
    cnt = cnt + 1
  end
  return supplyScore
end

function SmartRewardHelper.CalculateSupplyScoreForOrder(itemsUnfinished, itemScoreMapCfg, slotLackItemMap, slotArray, codeSplitResMap, dataInfo)
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\232\174\161\231\174\151\232\161\165\233\189\144\229\165\150\229\138\177\229\136\134\239\188\154\n")
  dataInfo = dataInfo or {}
  for _, data in ipairs(itemsUnfinished) do
    local supplyScore = 0
    supplyScore = SmartRewardHelper.CalculateSupplyScoreForSingleCode(data.Code, data.LackNum, itemScoreMapCfg, codeSplitResMap, dataInfo)
    local slot = data.Slot
    if slotLackItemMap[slot] == nil then
      slotLackItemMap[slot] = {
        SupplyScore = 0,
        Items = {}
      }
      table.insert(slotArray, slot)
    end
    slotLackItemMap[slot].SupplyScore = slotLackItemMap[slot].SupplyScore + supplyScore
    table.insert(slotLackItemMap[slot].Items, {
      Code = data.Code,
      SupplyScore = supplyScore,
      LackNum = data.LackNum
    })
  end
  return
end

function SmartRewardHelper.SortOrderAndItem(slotArray, slotLackItemMap)
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n\230\142\146\229\186\143\239\188\154\n")
  table.sort(slotArray, function(a, b)
    return slotLackItemMap[a].SupplyScore < slotLackItemMap[b].SupplyScore
  end)
  for _, slot in ipairs(slotArray) do
    local items = slotLackItemMap[slot].Items
    table.sort(items, function(a, b)
      return a.SupplyScore < b.SupplyScore
    end)
    SmartRewardHelper.AppendTestInfo("slot ", slot, ", score ", slotLackItemMap[slot].SupplyScore, [[

	]])
    for _, item in ipairs(items) do
      SmartRewardHelper.AppendTestInfo("/ ", item.Code, ", score ", item.SupplyScore, " ")
    end
    SmartRewardHelper.AppendTestInfo("\n")
  end
end

function SmartRewardHelper.DeliverSkippedItems(res, skippedItems, itemScoreMapCfg, totalScore, itemsUnfinished, data)
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n")
  SmartRewardHelper.AppendTestInfo("\229\165\150\229\138\177\229\136\134\229\137\169\228\189\153", totalScore, ", \232\161\165\229\143\145\232\162\171\232\183\179\232\191\135\231\154\132\230\163\139\229\173\144\n")
  if data == nil then
    data = {}
    data.resultCount = math.maxinteger
  end
  for _, tuple in ipairs(skippedItems) do
    if totalScore <= 0 or data.resultCount <= 0 then
      break
    end
    local chain = GM.ItemDataModel:GetChainId(tuple.Code)
    local level = GM.ItemDataModel:GetChainLevel(tuple.Code)
    local found = false
    SmartRewardHelper.AppendTestInfo("\229\176\157\232\175\149\232\161\165\229\143\145", tuple.Code, "\n")
    for i = level, 1, -1 do
      local codeTemp = GM.ItemDataModel:GetTypeByChainAndLevel(chain, i)
      local score = itemScoreMapCfg[codeTemp]
      if score and totalScore >= score then
        if 3 <= i then
          local n1 = 0
          for _, data in ipairs(itemsUnfinished) do
            if data.Code == tuple.Code then
              n1 = math.ceil(data.LackNum / GM.ItemDataModel:GetEquivalentLevelOneItemCount(codeTemp))
              break
            end
          end
          local n2 = math.ceil(totalScore / score)
          local num = math.min(n1, n2)
          num = math.min(num, data.resultCount)
          if num == n1 and 0 < num then
            SmartRewardHelper.InsertHelpedItem(tuple.Code)
          end
          SmartRewardHelper.AppendTestInfo("\230\140\137\231\188\186\229\164\177\230\149\176\233\135\143\232\161\165\229\143\145", n1, "\228\184\170\239\188\140\230\140\137\229\165\150\229\138\177\229\136\134\232\161\165\229\143\145", n2, "\228\184\170\239\188\140 \230\156\128\229\164\167\233\153\144\229\136\182\230\149\176\233\135\143", data.resultCount, "\228\184\170\239\188\140\229\143\150\232\190\131\229\176\143\229\128\188", "\n")
          for j = 1, num do
            SmartRewardHelper.AppendToResult(res, codeTemp, tuple.Slot)
            totalScore = totalScore - score
            data.resultCount = data.resultCount - 1
            SmartRewardHelper.AppendTestInfo("\229\143\145\230\148\190", codeTemp, ", score ", score, "\n")
            if data.resultCount <= 0 then
              break
            end
          end
        else
          local codeTo3 = GM.ItemDataModel:GetTypeByChainAndLevel(chain, 3)
          SmartRewardHelper.AppendToResult(res, codeTo3, tuple.Slot)
          totalScore = totalScore - itemScoreMapCfg[codeTo3]
          data.resultCount = data.resultCount - 1
          for _, data in ipairs(itemsUnfinished) do
            if data.Code == tuple.Code and data.LackNum <= GM.ItemDataModel:GetEquivalentLevelOneItemCount(codeTo3) then
              SmartRewardHelper.InsertHelpedItem(tuple.Code)
              break
            end
          end
          SmartRewardHelper.AppendTestInfo("\230\187\161\232\182\179\230\157\161\228\187\182\231\154\132\233\133\141\231\189\174\230\163\139\229\173\144\228\184\141\232\182\1793\231\186\167\239\188\140\230\143\144\233\171\152\229\136\1763\231\186\167\232\161\165\229\143\145\239\188\140\231\187\147\230\157\159\229\143\145\229\165\150\n")
          if data.resultCount <= 0 then
            break
          end
        end
        found = true
      end
      if found then
        break
      end
    end
    if not found then
      local codeTo3 = GM.ItemDataModel:GetTypeByChainAndLevel(chain, 3)
      SmartRewardHelper.AppendToResult(res, codeTo3, tuple.Slot)
      data.resultCount = data.resultCount - 1
      totalScore = totalScore - itemScoreMapCfg[codeTo3]
      for _, data in ipairs(itemsUnfinished) do
        if data.Code == tuple.Code and data.LackNum <= GM.ItemDataModel:GetEquivalentLevelOneItemCount(codeTo3) then
          SmartRewardHelper.InsertHelpedItem(tuple.Code)
          break
        end
      end
      SmartRewardHelper.AppendTestInfo("\233\133\141\231\189\174\230\163\139\229\173\144\229\165\150\229\138\177\229\136\134\229\157\135\233\171\152\228\186\142\229\137\169\228\189\153\229\165\150\229\138\177\229\136\134\239\188\140\232\161\165\229\143\1453\231\186\167\229\144\140\229\144\136\230\136\144\231\186\191\230\163\139\229\173\144\239\188\140\231\187\147\230\157\159\229\143\145\229\165\150\n")
    end
  end
  return totalScore
end

function SmartRewardHelper.GetHighestCodeInConfig(code, itemScoreMapCfg)
  local chain = GM.ItemDataModel:GetChainId(code)
  local level = -1
  local res
  for _code, score in pairs(itemScoreMapCfg) do
    if GM.ItemDataModel:GetChainId(_code) == chain then
      local _level = GM.ItemDataModel:GetChainLevel(_code)
      if level < _level then
        level = _level
        res = _code
      end
    end
  end
  return res
end

function SmartRewardHelper.DeliverRandom205_206(res, totalScore, itemScoreMapCfg, data)
  if data == nil then
    data = {}
    data.resultCount = math.maxinteger
  end
  SmartRewardHelper.AppendTestInfo("\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\226\128\148\n")
  SmartRewardHelper.AppendTestInfo("\229\165\150\229\138\177\229\136\134\229\137\169\228\189\153", totalScore, 0 < totalScore and ", \233\154\143\230\156\186\229\143\145\230\148\190 205/206\n" or "\n")
  while 0 < totalScore and not (data.resultCount <= 0) do
    if totalScore <= itemScoreMapCfg["205"] then
      SmartRewardHelper.AppendToResult(res, "205", nil)
      totalScore = totalScore - itemScoreMapCfg["205"]
      SmartRewardHelper.AppendTestInfo("\229\191\133\228\184\173205\n")
    else
      local code = "205"
      if itemScoreMapCfg["206"] then
        local n = math.random()
        local level = math.floor(n + 0.5) + 5
        code = GM.ItemDataModel:GetTypeByChainAndLevel(ItemChain.Bread, level)
      end
      local score = itemScoreMapCfg[code]
      SmartRewardHelper.AppendToResult(res, code, nil)
      totalScore = totalScore - score
      SmartRewardHelper.AppendTestInfo(code, ", score ", score, "\n")
    end
    data.resultCount = data.resultCount - 1
  end
  return totalScore
end

function SmartRewardHelper.GetEquivalentCode(originCode, config, codeSplitResMap)
  if config[originCode] then
    Log.Info(originCode, "should not be splitted")
    return originCode, 1, config[originCode]
  end
  if codeSplitResMap[originCode] then
    return codeSplitResMap[originCode].Code, codeSplitResMap[originCode].Multi, codeSplitResMap[originCode].ScoreMulti
  end
  local level = GM.ItemDataModel:GetChainLevel(originCode)
  local chain = GM.ItemDataModel:GetChainId(originCode)
  for i = level - 1, 1, -1 do
    local codeTemp = GM.ItemDataModel:GetTypeByChainAndLevel(chain, i)
    if config[codeTemp] then
      local multi = MathUtil.IntPow(2, level - i)
      codeSplitResMap[originCode] = {
        Code = codeTemp,
        Multi = multi,
        ScoreMulti = config[codeTemp] * multi
      }
      return codeSplitResMap[originCode].Code, codeSplitResMap[originCode].Multi, codeSplitResMap[originCode].ScoreMulti
    end
  end
  return nil, nil, nil
end

function SmartRewardHelper.BILogHelpedItem(BIType, otherBIInfo)
  otherBIInfo = otherBIInfo or {}
  local BIInfo_ItemHelped = Table.DeepCopy(otherBIInfo)
  BIInfo_ItemHelped.Type = {}
  for _, code in ipairs(IntllgtRwrd_ItemHelpedToMerge) do
    table.insert(BIInfo_ItemHelped.Type, code)
  end
  GM.BIManager:LogAction(BIType, BIInfo_ItemHelped)
end

function SmartRewardHelper.BILogItemForOrder(BIType, otherBIInfo)
  otherBIInfo = otherBIInfo or {}
  local BIInfo_ItemForOrder = Table.DeepCopy(otherBIInfo)
  local tempMap = {}
  for slot, codes in pairs(IntllgtRwrd_ItemForOrder) do
    if tempMap[tostring(slot)] == nil then
      tempMap[tostring(slot)] = {}
    end
    for _, code in ipairs(codes) do
      table.insert(tempMap[tostring(slot)], code)
    end
  end
  BIInfo_ItemForOrder.slots = tempMap
  GM.BIManager:LogAction(BIType, BIInfo_ItemForOrder)
end

function SmartRewardHelper.AppendToResult(res, code, forSlot)
  table.insert(res, code)
  if forSlot then
    SmartRewardHelper.InsertItemForOrder(code, forSlot)
  end
end

function SmartRewardHelper.AppendTestInfo(...)
  local t = {
    ...
  }
  Table.ListAppend(TESTINFO_SmtRwrd, t)
end

function SmartRewardHelper.LackNum2Codes(num, chainId)
  if num <= 0 then
    return
  end
  local cnt = 1
  local res = ""
  while 0 < num do
    if num & 1 == 1 then
      local code = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, cnt)
      res = res .. code .. ", "
    end
    num = num >> 1
    cnt = cnt + 1
  end
  return res
end
