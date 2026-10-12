function DEFINE_ITEM_EVENT(model, eventName)
  local functionName = eventName .. "Item"
  
  local dispatchFunctionName = "On" .. eventName
  model[functionName] = function(model, item, ...)
    item:DispatchComponentEvent(dispatchFunctionName, ...)
  end
end

BaseBoardModel = {
  BoardType = EBoardType.Empty,
  Freefall = false,
  IgnoreBI = false
}
BaseBoardModel.__index = BaseBoardModel
BaseBoardModel.TileSize = 145
BaseBoardModel.HorizontalTiles = nil
BaseBoardModel.VerticalTiles = nil
BaseBoardModel.ModelTypeInstances = {}

function BaseBoardModel:GetModelInstance(boardType)
  return self.ModelTypeInstances[boardType]
end

function BaseBoardModel:_SetInstance()
  self.ModelTypeInstances[self.BoardType] = self
end

function BaseBoardModel:Init(itemLayerModel)
  self.event = PairEvent.Create(self)
  self.m_itemLayerModel = itemLayerModel
  self:_SetInstance()
  DEFINE_ITEM_EVENT(self, "Tap")
end

function BaseBoardModel:UpdatePerSecond()
  for model, _ in pairs(self:GetAllBoardItems(true)) do
    model:DispatchComponentEvent("UpdatePerSecond")
  end
end

function BaseBoardModel:CreateMatrix()
  local matrix = setmetatable({}, Matrix)
  matrix:Init(self)
  return matrix
end

function BaseBoardModel:CreatePositionFromLocalPosition(localPositionX, localPositionY)
  local x = math.floor(localPositionX) // self.TileSize + 1
  local y = self.VerticalTiles - math.floor(localPositionY) // self.TileSize
  return BoardPosition.Create(x, y)
end

function BaseBoardModel:GetValidPositionIterator()
  return self._ValidPositionIterator, self, nil
end

function BaseBoardModel:_ValidPositionIterator(position)
  if position == nil then
    return BoardPosition.Create(1, 1)
  end
  local x = position:GetX()
  local y = position:GetY()
  if x ~= self.HorizontalTiles then
    x = x + 1
  else
    x = 1
    y = y + 1
  end
  if y > self.VerticalTiles then
    return nil
  else
    return BoardPosition.Create(x, y)
  end
end

function BaseBoardModel:GetInverseYValidPositionIterator()
  return self._InverseYValidPositionIterator, self, nil
end

function BaseBoardModel:_InverseYValidPositionIterator(position)
  if position == nil then
    return BoardPosition.Create(1, self.VerticalTiles)
  end
  local x = position:GetX()
  local y = position:GetY()
  if x ~= self.HorizontalTiles then
    x = x + 1
  else
    x = 1
    y = y - 1
  end
  if y < 1 then
    return nil
  else
    return BoardPosition.Create(x, y)
  end
end

function BaseBoardModel:GetDiagonalValidPositionIterator()
  return self._DiagonalValidPositionIterator, self, nil
end

function BaseBoardModel:_DiagonalValidPositionIterator(position)
  if position == nil then
    return BoardPosition.Create(1, 1)
  end
  local x = position:GetX()
  local y = position:GetY()
  x = x + 1
  y = y - 1
  if y < 1 or x > self.HorizontalTiles then
    if x + y == self.HorizontalTiles + self.VerticalTiles then
      return nil
    end
    local sumxy = x + y + 1
    y = math.min(x + y, self.VerticalTiles)
    x = sumxy - y
  end
  return BoardPosition.Create(x, y)
end

function BaseBoardModel:PositionIsValid(position)
  return position:GetX() >= 1 and position:GetX() <= self.HorizontalTiles and 1 <= position:GetY() and position:GetY() <= self.VerticalTiles
end

function BaseBoardModel:ToLocalPosition(position)
  local x = (position:GetX() - 1) * self.TileSize
  local y = (self.VerticalTiles - position:GetY()) * self.TileSize
  return Vector2(x, y)
end

function BaseBoardModel:ToLocalPositionSetZ(position, z)
  local x = (position:GetX() - 0.5) * self.TileSize
  local y = (self.VerticalTiles - position:GetY() + 0.5) * self.TileSize
  return Vector3(x, y, z)
end

function BaseBoardModel:IsPositionInteractable(position)
  return self:PositionIsValid(position)
end

function BaseBoardModel:GenerateItem(position, code, autoUpdateOrderState, needUnlockType)
  local newItem = ItemModelFactory.CreateWithCode(self, position, code, needUnlockType ~= false)
  self:SaveItemProperty(newItem)
  if position ~= nil then
    self:_SetItem(position, newItem, autoUpdateOrderState)
  end
  if self.m_mergeAllIgnoredItems ~= nil then
    self.m_mergeAllIgnoredItems[newItem] = true
  end
  return newItem
end

function BaseBoardModel:ReplaceItem(sourceItem, newItemCode, autoUpdateOrderState)
  self:RemoveItem(sourceItem, false)
  return self:GenerateItem(sourceItem:GetPosition(), newItemCode, autoUpdateOrderState)
end

function BaseBoardModel:RemoveItem(item, autoUpdateOrderState)
  local spreadCmp = item:GetComponent(ItemSpread)
  local isOpeningBox = spreadCmp ~= nil and spreadCmp:GetState() == ItemSpreadState.Opening
  self:_SetItem(item:GetPosition(), nil, autoUpdateOrderState)
  self:_RemoveItemProperty(item)
  if isOpeningBox and self.UpdateOpeningItem then
    self:UpdateOpeningItem()
  end
end

function BaseBoardModel:SpreadItem(sourceItem, newItemPosition, newItemCode, args)
  local newItem = self:GenerateItem(newItemPosition, newItemCode, args.autoUpdateOrderState, nil, args.generateItemState)
  local message = {
    Source = sourceItem,
    New = newItem,
    EnergyBoostRatio = args.energyBoostRatio or 0,
    CostEnergy = args.costEnergy,
    BoardSpreadType = args.spreadType
  }
  self.event:Call(BoardEventType.SpreadItem, message)
  return message
end

function BaseBoardModel:ShockNeighborItems(centerPosition)
  for dir = 1, 4 do
    local testPosition = BoardPosition.GetDir4Position(centerPosition, dir)
    local testItem = self:GetItem(testPosition)
    if testItem ~= nil then
      testItem:DispatchComponentEvent("OnShock")
    end
  end
end

function BaseBoardModel:CollapseItem(boardPos, unlockShocked)
  local sourceItem = self:GetItem(boardPos)
  if sourceItem == nil then
    return
  end
  local itemPaperBox = sourceItem:GetComponent(ItemPaperBox)
  if itemPaperBox == nil then
    return
  end
  local newItem = self:ReplaceItem(sourceItem, itemPaperBox:GetInnerItemCode(), false)
  if self:CanItemMove(newItem) and not unlockShocked then
    self:ShockNeighborItems(boardPos)
  end
  local message = {
    Source = sourceItem,
    New = newItem,
    UnlockShocked = unlockShocked
  }
  self:_PostProcessCollapseItem(boardPos, message)
  self.event:Call(BoardEventType.CollapseItem, message)
  GM.BIManager:LogAction(EBIType.CollapseItem, {
    c = sourceItem:GetCode(),
    us = unlockShocked,
    rwd = message.CollapseReward and ConfigUtil.GetCurrencyStr(message.CollapseReward) or nil
  })
  EventDispatcher.DispatchEvent(EEventType.PaperboxDisappear, message)
end

function BaseBoardModel:_PostProcessCollapseItem(boardPos, msg)
end

function BaseBoardModel:SkipItems(sourceItem, duration)
  Log.Assert(false, "SkipItems()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseBoardModel:DragItem(item, targetPosition)
  Log.Assert(false, "DragItem()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseBoardModel:_MergeItem(item, targetItem, targetPosition)
  self:_DoMergeItem(item, targetItem, targetPosition)
end

function BaseBoardModel:_DoMergeItem(item, targetItem, targetPosition, autoUpdateOrderState)
  self:RemoveItem(item, false)
  local mergedType, itemType
  if item:GetComponent(ItemTemp) == nil then
    mergedType = item:GetMergedType()
    itemType = item:GetType()
  else
    mergedType = targetItem:GetMergedType()
    itemType = item:GetType()
  end
  local isUnlock = GM.ItemDataModel:IsUnlocked(mergedType)
  local newItem = self:ReplaceItem(targetItem, mergedType, autoUpdateOrderState)
  local message = {
    Source = item,
    Target = targetItem,
    New = newItem,
    itemType = itemType,
    isFirstUnlock = isUnlock == nil
  }
  self.event:Call(BoardEventType.MergeItem, message)
  EventDispatcher.DispatchEvent(EEventType.ItemMerged, message)
  self:ShockNeighborItems(targetPosition)
  EventDispatcher.DispatchEvent(EEventType.ItemShocked)
  return message
end

function BaseBoardModel:MergeAll()
  self.m_mergeAllIgnoredItems = {}
  local ignoreCobweb = PlayerPrefs.GetInt(EPlayerPrefKey.TestMergeAllIgnoreCobweb, 0) == 1
  local ignoreCanSpread = PlayerPrefs.GetInt(EPlayerPrefKey.TestMergeAllIgnoreCanSpread, 0) == 1
  if GameConfig.IsTestMode() and (ignoreCobweb or ignoreCanSpread) then
    local find = false
    for position in self:GetValidPositionIterator() do
      local item = self:GetItem(position)
      if item ~= nil then
        if ignoreCobweb and item:GetComponent(ItemCobweb) then
          self.m_mergeAllIgnoredItems[item] = true
          find = true
        end
        if ignoreCanSpread and item:GetComponent(ItemSpread) then
          local itemSpread = item:GetComponent(ItemSpread)
          if 0 < itemSpread:GetItemRestNumber() then
            self.m_mergeAllIgnoredItems[item] = true
            find = true
          end
        end
      end
    end
    if find then
      GM.UIManager:ShowPrompt("\227\128\144\230\181\139\232\175\149\231\142\175\229\162\131\227\128\145\229\183\178\229\191\189\231\149\165" .. (ignoreCobweb and "\232\155\155\231\189\145\230\163\139\229\173\144" or "") .. (ignoreCobweb and ignoreCanSpread and "\227\128\129" or "") .. (ignoreCanSpread and "\229\143\175\229\150\183\229\143\145\230\163\139\229\173\144" or ""))
    end
  end
  local orderNeedItemCountMap
  if self.GetOrderCodeRequireCountMap and PlayerPrefs.GetInt(EPlayerPrefKey.TestMergeAllKeepOrderNeed, 0) == 1 then
    orderNeedItemCountMap = Table.ShallowCopy(self:GetOrderCodeRequireCountMap())
  end
  local pair = self:FindMergePair(self.m_mergeAllIgnoredItems, orderNeedItemCountMap)
  if pair == nil and GameConfig.IsTestMode() then
    GM.UIManager:ShowPrompt("\230\137\190\228\184\141\229\136\176\229\143\175\229\144\136\229\185\182\231\154\132\230\163\139\229\173\144")
    return
  end
  while pair ~= nil do
    self:_MergeItem(pair[1], pair[2], pair[2]:GetPosition())
    orderNeedItemCountMap = nil
    if self.GetOrderCodeRequireCountMap and PlayerPrefs.GetInt(EPlayerPrefKey.TestMergeAllKeepOrderNeed, 0) == 1 then
      orderNeedItemCountMap = Table.ShallowCopy(self:GetOrderCodeRequireCountMap())
    end
    pair = self:FindMergePair(self.m_mergeAllIgnoredItems, orderNeedItemCountMap)
  end
end

function BaseBoardModel:GetDistanceInBoard(positionA, positionB)
  return math.abs(positionA:GetX() - positionB:GetX()) + math.abs(positionA:GetY() - positionB:GetY())
end

function BaseBoardModel:CanItemMove(item)
  if item:GetComponent(ItemPaperBox) ~= nil or item:GetComponent(ItemCobweb) ~= nil then
    return false
  end
  if item:GetComponent(ItemLocked) ~= nil then
    return false
  end
  local itemSwallow = item:GetComponent(ItemSwallow)
  if itemSwallow == nil then
    return true
  end
  return itemSwallow:AllowTap()
end

function BaseBoardModel:CanItemFall(item)
  return self:CanItemMove(item)
end

function BaseBoardModel:CanItemMerge(item1, item2)
  local itemSpread1 = item1:GetComponent(ItemSpread)
  if itemSpread1 ~= nil and itemSpread1:IsChestUsedOnce() then
    return false
  end
  local itemSpread2 = item2:GetComponent(ItemSpread)
  if itemSpread2 ~= nil and itemSpread2:IsChestUsedOnce() then
    return false
  end
  local itemType1, itemType2, mergedType
  local itemSpecial1 = item1:GetComponent(ItemCobweb) or item1:GetComponent(ItemTemp)
  if itemSpecial1 ~= nil then
    itemType1 = itemSpecial1:GetInnerItemCode()
  else
    itemType1 = item1:GetType()
    mergedType = item1:GetMergedType()
  end
  local itemSpecial2 = item2:GetComponent(ItemCobweb) or item2:GetComponent(ItemTemp)
  if itemSpecial2 ~= nil then
    itemType2 = itemSpecial2:GetInnerItemCode()
  else
    itemType2 = item2:GetType()
    mergedType = item2:GetMergedType()
  end
  if self.IsGeneratorFactoryOpen and self:IsGeneratorFactoryOpen() and self.IsGeneratorFactoryItem and self:IsGeneratorFactoryItem(itemType1) then
    return false
  end
  return itemType1 == itemType2 and mergedType ~= nil
end

function BaseBoardModel:IsItemPaperBoxLocked(item)
  return self:GetCurrentPaperBoxLevel() < self:GetItemPaperBoxUnLockLevel(item)
end

function BaseBoardModel:GetItemPaperBoxUnLockLevel(item)
  return 0
end

function BaseBoardModel:GetCurrentPaperBoxLevel()
  return 0
end

function BaseBoardModel:Try2UnlockPaperBoxItem()
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil then
      local itemPaperBox = item:GetComponent(ItemPaperBox)
      if itemPaperBox ~= nil then
        itemPaperBox:Try2Unlock()
      end
    end
  end
end

function BaseBoardModel:FindEmptyPositionInCircleOrder(centerPosition)
  return self.m_itemLayerModel:FindEmptyPositionInCircleOrder(centerPosition, self)
end

function BaseBoardModel:FindRandomPosition()
  return self.m_itemLayerModel:FindRandomPosition()
end

function BaseBoardModel:GetItem(position)
  return self.m_itemLayerModel:GetItem(position)
end

function BaseBoardModel:_SetItem(position, item, autoUpdateOrderState)
  self.m_itemLayerModel:SetItem(position, item)
end

function BaseBoardModel:IsBoardFull()
  return not self.m_itemLayerModel:HasEmptyPosition()
end

function BaseBoardModel:FindEmptyPositionInValidOrder()
  return self.m_itemLayerModel:FindEmptyPositionInValidOrder()
end

function BaseBoardModel:FindEmptyPositionInSpreadOrder(centerPosition, openedPosition)
  return self.m_itemLayerModel:FindEmptyPositionInSpreadOrder(centerPosition, openedPosition)
end

function BaseBoardModel:FindEmptySpreadPosition(itemType, centerPosition)
  if not itemType or ItemModelFactory.GetCodePrefixTargetType(itemType) ~= nil then
    return
  end
  local isPopCacheItem = centerPosition == nil
  local dirs = {
    7,
    3,
    1,
    5,
    8,
    2,
    6,
    4
  }
  local curPos
  local itemModels = self:FilterItems(function(itemModel)
    local itemCobweb = itemModel:GetComponent(ItemCobweb)
    return itemModel:GetType() == itemType or itemCobweb and itemCobweb:GetInnerItemCode() == itemType
  end)
  if 0 < #itemModels then
    centerPosition = centerPosition or BoardPosition.Create(1, 1)
    table.sort(itemModels, function(itemModelA, itemModelB)
      if self:GetDistanceInBoard(centerPosition, itemModelA:GetPosition()) == self:GetDistanceInBoard(centerPosition, itemModelB:GetPosition()) then
        if itemModelA:GetPosition():GetX() == itemModelB:GetPosition():GetX() then
          return itemModelA:GetPosition():GetY() < itemModelB:GetPosition():GetY()
        end
        return itemModelA:GetPosition():GetX() < itemModelB:GetPosition():GetX()
      end
      return self:GetDistanceInBoard(centerPosition, itemModelA:GetPosition()) < self:GetDistanceInBoard(centerPosition, itemModelB:GetPosition())
    end)
    for _, dir in ipairs(dirs) do
      for _, itemModel in ipairs(itemModels) do
        curPos = BoardPosition.GetDir8Position(itemModel:GetPosition(), dir)
        if self:PositionIsValid(curPos) and self.m_itemLayerModel:GetItem(curPos) == nil then
          return curPos
        end
      end
    end
  end
  local targetChainId = GM.ItemDataModel:GetChainId(itemType)
  local targetChainLevel = GM.ItemDataModel:GetChainLevel(itemType)
  itemModels = self:FilterItems(function(itemModel)
    return GM.ItemDataModel:GetChainId(itemModel:GetType()) == targetChainId
  end)
  if 0 < #itemModels then
    table.sort(itemModels, function(itemModelA, itemModelB)
      if math.abs(targetChainLevel - GM.ItemDataModel:GetChainLevel(itemModelA:GetType())) == math.abs(targetChainLevel - GM.ItemDataModel:GetChainLevel(itemModelB:GetType())) then
        return GM.ItemDataModel:GetChainLevel(itemModelA:GetType()) < GM.ItemDataModel:GetChainLevel(itemModelB:GetType())
      end
      return math.abs(targetChainLevel - GM.ItemDataModel:GetChainLevel(itemModelA:GetType())) < math.abs(targetChainLevel - GM.ItemDataModel:GetChainLevel(itemModelB:GetType()))
    end)
    for _, itemModel in ipairs(itemModels) do
      for _, dir in ipairs(dirs) do
        curPos = BoardPosition.GetDir8Position(itemModel:GetPosition(), dir)
        if self:PositionIsValid(curPos) and self.m_itemLayerModel:GetItem(curPos) == nil then
          return curPos
        end
      end
    end
  end
  if isPopCacheItem then
    return self:FindEmptyPositionInValidOrder()
  else
    return self:FindEmptyPositionInSpreadOrder(centerPosition)
  end
end

function BaseBoardModel:FindEmptyPositionInSpreadOrderWithNum(centerPosition, openedPosition, num, bInCludeCenter)
  return self.m_itemLayerModel:FindEmptyPositionInSpreadOrderWithNum(centerPosition, openedPosition, num, bInCludeCenter)
end

function BaseBoardModel:FindEmptyPositionInDiagonalOrderWithNum(num)
  return self.m_itemLayerModel:FindEmptyPositionInDiagonalOrderWithNum(num)
end

function BaseBoardModel:GetAllBoardItems(copy)
  local items = self.m_itemLayerModel:GetAllItems()
  if copy then
    return Table.ShallowCopy(items)
  end
  return items
end

function BaseBoardModel:FilterItems(filter)
  return self.m_itemLayerModel:FilterItems(filter)
end

function BaseBoardModel:GetCostEnergyType()
  return EnergyType.Main
end

function BaseBoardModel:GetOrderCodeStateMap()
  return Table.Empty
end

function BaseBoardModel:GetCodeCountMap(includeBoard, includeCache, includeStore)
  local codeCountMap = {}
  includeBoard = includeBoard ~= false
  if includeBoard then
    if not self.m_codeCountMap then
      self:CountItemsCode()
    end
    for k, v in pairs(self.m_codeCountMap) do
      codeCountMap[k] = v
    end
  end
  return codeCountMap
end

function BaseBoardModel:CountItemsCode()
  self.m_codeCountMap = {}
  for model, _ in pairs(self:GetAllBoardItems()) do
    local code = model:GetCode()
    if self.m_codeCountMap[code] == nil then
      self.m_codeCountMap[code] = 0
    end
    self.m_codeCountMap[code] = self.m_codeCountMap[code] + 1
  end
end

function BaseBoardModel:_FillMergePairGroup(mapGroups, position, ignoredItems, ignoredItemsWithCounts)
  if not self:IsPositionInteractable(position) then
    return
  end
  local itemModel = self:GetItem(position)
  if itemModel == nil or ignoredItems[itemModel] ~= nil then
    return
  end
  local itemSpread = itemModel:GetComponent(ItemSpread)
  if itemSpread ~= nil and itemSpread:IsChestUsedOnce() then
    return
  end
  local itemCobweb = itemModel:GetComponent(ItemCobweb)
  local itemTemp = itemModel:GetComponent(ItemTemp)
  local itemType
  local isCobweb = false
  local isTemp = false
  if itemCobweb ~= nil then
    itemType = itemCobweb:GetInnerItemCode()
    isCobweb = true
  elseif itemTemp ~= nil then
    itemType = itemTemp:GetInnerItemCode()
    isTemp = true
  elseif itemModel:GetMergedType() ~= nil then
    itemType = itemModel:GetType()
  end
  if itemType == nil then
    return
  end
  if self.IsGeneratorFactoryOpen and self:IsGeneratorFactoryOpen() and self.IsGeneratorFactoryItem and self:IsGeneratorFactoryItem(itemType) then
    return
  end
  local ignoredCount = ignoredItemsWithCounts[itemType]
  if ignoredCount ~= nil and 0 < ignoredCount and not isCobweb and not isTemp then
    ignoredItemsWithCounts[itemType] = ignoredItemsWithCounts[itemType] - 1
    return
  end
  if mapGroups[itemType] == nil then
    mapGroups[itemType] = {
      Cobweb = {},
      Temp = {},
      Normal = {}
    }
  end
  local targetGroup
  if isCobweb then
    targetGroup = mapGroups[itemType].Cobweb
  elseif isTemp then
    targetGroup = mapGroups[itemType].Temp
  else
    targetGroup = mapGroups[itemType].Normal
  end
  table.insert(targetGroup, itemModel)
end

function BaseBoardModel:FindMergePair(ignoredItems, ignoredItemsWithCounts, lastTouchedItem)
  ignoredItems = ignoredItems or {}
  ignoredItemsWithCounts = ignoredItemsWithCounts or {}
  local mapGroups = {}
  for position in self:GetValidPositionIterator() do
    self:_FillMergePairGroup(mapGroups, position, ignoredItems, ignoredItemsWithCounts)
  end
  local arrayWithCobweb = {}
  local arrayWithTemp = {}
  local arrayNormal = {}
  local arrayOrangeTree = {}
  if lastTouchedItem and mapGroups[lastTouchedItem:GetType()] and lastTouchedItem:GetComponent(ItemTemp) == nil and lastTouchedItem:GetComponent(ItemCobweb) == nil then
    local nearestItemModel = self:_GetNearestTouchedMergeItem(lastTouchedItem, mapGroups)
    if nearestItemModel ~= nil then
      self.m_logNearestTouchedMergeItem = {
        [lastTouchedItem] = true,
        [nearestItemModel] = true
      }
      return {lastTouchedItem, nearestItemModel}
    end
  end
  for type, group in pairs(mapGroups) do
    if #group.Normal > 0 then
      if 0 < #group.Cobweb then
        table.insert(arrayWithCobweb, {
          Table.ListRandomSelectOne(group.Normal),
          Table.ListRandomSelectOne(group.Cobweb)
        })
      elseif 0 < #group.Temp then
        table.insert(arrayWithTemp, {
          Table.ListRandomSelectOne(group.Normal),
          Table.ListRandomSelectOne(group.Temp)
        })
      elseif #group.Normal >= 2 then
        if type == ItemType.OrangeTree06 or type == ItemType.OrangeTree07 or type == ItemType.OrangeTree08 or type == ItemType.OrangeTree09 or type == ItemType.OrangeTree10 then
          table.insert(arrayOrangeTree, Table.ListRandomSelectN(group.Normal, 2))
        else
          table.insert(arrayNormal, Table.ListRandomSelectN(group.Normal, 2))
        end
      end
    end
  end
  if 0 < #arrayWithCobweb then
    return Table.ListRandomSelectOne(arrayWithCobweb)
  elseif 0 < #arrayWithTemp then
    return Table.ListRandomSelectOne(arrayWithTemp)
  elseif 0 < #arrayNormal then
    return Table.ListRandomSelectOne(arrayNormal)
  elseif 0 < #arrayOrangeTree then
    return Table.ListRandomSelectOne(arrayOrangeTree)
  end
  return nil
end

function BaseBoardModel:ResetLogNearestTouchedMergeItem()
  self.m_logNearestTouchedMergeItem = nil
end

function BaseBoardModel:CheckNearestTouchedMergeItem(itemModelA, itemModelB)
  return itemModelA and itemModelB and self.m_logNearestTouchedMergeItem and self.m_logNearestTouchedMergeItem[itemModelA] and self.m_logNearestTouchedMergeItem[itemModelB]
end

function BaseBoardModel:_GetNearestTouchedMergeItem(lastTouchedItem, mapGroups)
  local group = mapGroups[lastTouchedItem:GetType()]
  local allItems = {}
  if #group.Cobweb > 0 then
    Table.ListAppend(allItems, group.Cobweb)
  end
  if 0 < #group.Temp then
    Table.ListAppend(allItems, group.Temp)
  end
  if 0 < #group.Normal then
    Table.ListAppend(allItems, group.Normal)
  end
  local nearestItemModel
  local nearestDis = 99999
  if 2 <= #allItems then
    for _, itemModel in ipairs(allItems) do
      if lastTouchedItem ~= itemModel then
        local dis = self:GetDistanceInBoard(lastTouchedItem:GetPosition(), itemModel:GetPosition())
        if nearestDis > dis then
          nearestDis = dis
          nearestItemModel = itemModel
        end
      end
    end
  end
  return nearestItemModel
end

function BaseBoardModel:HasOpeningItem()
  return true
end

function BaseBoardModel:SaveItemProperty(item)
end

function BaseBoardModel:_RemoveItemProperty(item)
end
