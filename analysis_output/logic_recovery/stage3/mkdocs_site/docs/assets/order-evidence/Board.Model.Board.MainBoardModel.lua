StoreFailedReason = {
  CannotStore = 1,
  InventoryFull = 2,
  GeneratorFactory = 3
}
ItemGeneratorFirstUnlockTipType = {
  ["1"] = "106",
  ["4"] = "406",
  ["7"] = "706",
  ["10"] = "1007",
  ["12"] = "1206",
  ["17"] = "1706"
}
MainBoardModel = setmetatable({
  BoardType = EBoardType.Main
}, BaseActionBoardModel)
MainBoardModel.__index = MainBoardModel
MainBoardModel.HorizontalTiles = 7
MainBoardModel.VerticalTiles = 9

function MainBoardModel:Init()
  ModelHelper.DefineSyncData(self, "ItemData", GM.DBTableManager:GetTable(EDBTableConfigs.Item))
  ModelHelper.DefineSyncData(self, "ItemLayerData", GM.DBTableManager:GetTable(EDBTableConfigs.Board))
  ModelHelper.DefineSyncData(self, "ItemCacheData", GM.DBTableManager:GetTable(EDBTableConfigs.CacheItem))
  ModelHelper.DefineSyncData(self, "ItemStoreData", GM.DBTableManager:GetTable(EDBTableConfigs.Inventory))
  ModelHelper.DefineSyncData(self, "OrderMetaData", GM.DBTableManager:GetTable(EDBTableConfigs.OrderMeta))
  ModelHelper.DefineSyncData(self, "OrderData", GM.DBTableManager:GetTable(EDBTableConfigs.Order))
  local itemManager = ItemManager.Create(self.m_itemData, self)
  local itemLayerModel = MainBoardItemLayerModel.Create(self, self.m_itemLayerData, itemManager, "BoardModelConfig")
  local itemCacheModel = ItemCacheModel.Create(self.m_itemCacheData, itemManager:GetIdGenerator())
  local orderModel = MainOrderModel.Create(self.m_orderMetaData, self.m_orderData, self)
  local hostOrderModel = HostOrderModel.Create(self)
  BaseActionBoardModel.Init(self, itemLayerModel)
  DEFINE_ITEM_EVENT(self, "Open")
  DEFINE_ITEM_EVENT(self, "SpeedUp")
  DEFINE_ITEM_EVENT(self, "Choose")
  DEFINE_ITEM_EVENT(self, "Activate")
  self.m_gameMode = EGameMode.Main
  self.m_itemManager = itemManager
  self.m_itemCacheModel = itemCacheModel
  self.m_orderModels = {
    [OrderModelType.Slot] = orderModel,
    [OrderModelType.Host] = hostOrderModel
  }
  self.m_codeStateMap = {}
  self.m_codeRequireCount = {}
  self.m_lastBreakBubbleType = nil
  self.m_itemStoreModel = ItemStoreModel.Create(self.m_itemStoreData, itemManager)
  self.m_itemGeneratorFactoryModel = ItemGeneratorFactoryModel.Create()
  self:InitSpreadRefreshFunc()
end

function MainBoardModel:InitSpreadRefreshFunc()
  self:InitRefreshrestNumberZeroCD(function(message)
    return message[EBuffProperty.BuffItemcd] ~= nil or message[EBuffProperty.buff_smart] ~= nil
  end, function(itemSpread)
    return itemSpread:CanSupportCDBuff() or itemSpread:CanSupportSmart()
  end, "TryUnlockCdByZroCd", EEventType.BuffPropertyConsume)
  self:InitRefreshrestNumberZeroCD(function(message)
    return message[EBuffProperty.BuffItemcd] ~= nil
  end, function(itemSpread)
    return itemSpread:CanSupportCDBuff()
  end, "OnTimeSkip", EEventType.BuffNoZeroCDPlayAct, function(message)
    self.event:Call(BoardEventType.ZeroCDItemBuffConsume, message[EBuffProperty.BuffItemcd])
  end, {
    nil,
    ItemSkipType.Buff
  })
  self:InitRefreshrestNumberZeroCD(function(MessageEventArgs)
    return true
  end, function(ItemSpread)
    return ItemSpread:CanSupportBoostDisco()
  end, "OnTimeSkip", EEventType.TriggerBoostDiscoActStarted, function()
    self.event:Call(BoardEventType.DiscoBoostTrigger)
  end, {
    nil,
    ItemSkipType.Buff
  })
  self:InitRefreshrestNumberZeroCD(function(message)
    return true
  end, function(ItemSpread)
    return ItemSpread:CanSupportBoostDisco()
  end, "OnTimeSkipInZeroRestNumber", EEventType.TriggerBoostDiscoStarted)
  self:InitRefreshrestNumberZeroCD(function(message)
    return true
  end, function(itemSpread)
    return itemSpread:CanSupportSmart()
  end, "OnTimeSkip", EEventType.SmartBuffItemSpreadAct, function(message)
    self.event:Call(BoardEventType.SmartBuffConsume)
  end, {
    nil,
    ItemSkipType.Buff
  })
  self:InitRefreshrestNumberZeroCD(function(message)
    local model = GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition)
    if model == nil then
      return false
    end
    return true
  end, function(itemSpread)
    return itemSpread:CanSupportGeneratorBoostCDBuff()
  end, "OnTimeSkipInZeroRestNumber", EEventType.GeneratorBoostBuffActiveLogic)
  self:InitRefreshrestNumberZeroCD(function(message)
    local model = GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition)
    if model == nil then
      return false
    end
    return true
  end, function(itemSpread)
    return itemSpread:CanSupportGeneratorBoostCDBuff()
  end, "OnTimeSkip", EEventType.GeneratorBoostBuffActivePlayed, function()
    self.event:Call(BoardEventType.GeneratorBoostBuffActive)
  end, {
    nil,
    ItemSkipType.Buff
  })
end

function MainBoardModel:OnSyncDataFinished()
  self.m_itemManager:OnSyncDataFinished()
  self.m_itemLayerModel:OnSyncDataFinished()
  self.m_itemCacheModel:OnSyncDataFinished()
  self.m_itemStoreModel:OnSyncDataFinished()
  for _, orderModel in pairs(self.m_orderModels) do
    orderModel:OnSyncDataFinished()
  end
  self:CountItemsCode()
  self:UpdateOrderState()
  self:UpdateOpeningItem()
end

function MainBoardModel:LateInit()
  for _, orderModel in pairs(self.m_orderModels) do
    orderModel:LateInit()
  end
  self.m_itemGeneratorFactoryModel:LateInit()
  self:_CheckCobwebItems()
  self:_CheckCacheItems()
  self:_BIPaperboxExtraItem()
end

function MainBoardModel:Update()
  if self.m_gameMode ~= GM.SceneManager:GetGameMode() then
    return
  end
  for item, _ in pairs(self:GetAllBoardItems(true)) do
    if item ~= nil then
      item:DispatchComponentUpdateEvent()
    end
  end
end

function MainBoardModel:LoadFileConfig()
  self.m_promptConfig = {}
  local promptConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.BoardPrompt)
  for _, promptConfig in ipairs(promptConfigs) do
    self.m_promptConfig[promptConfig.Type] = promptConfig
  end
  self.m_itemLayerModel:LoadFileConfig()
  for _, orderModel in pairs(self.m_orderModels) do
    orderModel:LoadFileConfig()
  end
  self:InitPaperBoxRewardConfig()
end

function MainBoardModel:UpdatePerSecond()
  if self.m_gameMode == GM.SceneManager:GetGameMode() then
    BaseActionBoardModel.UpdatePerSecond(self)
  end
  for _, orderModel in pairs(self.m_orderModels) do
    orderModel:UpdatePerSecond()
  end
end

function MainBoardModel:GetGameMode()
  return self.m_gameMode
end

function MainBoardModel:_SetItem(position, item, autoUpdateOrderState)
  BaseActionBoardModel._SetItem(self, position, item, autoUpdateOrderState)
  if autoUpdateOrderState ~= false then
    self:CountItemsCode()
    self:UpdateOrderState()
  end
end

function MainBoardModel:GetCodeCountMap(includeBoard, includeCache, includeStore)
  local codeCountMap = BaseActionBoardModel.GetCodeCountMap(self, includeBoard, includeCache, includeStore)
  includeStore = includeStore ~= false
  if includeStore then
    for i = 1, self.m_itemStoreModel:GetItemCount() do
      local item = self.m_itemStoreModel:GetItem(i)
      if item ~= nil then
        local code = item:GetCode()
        if codeCountMap[code] == nil then
          codeCountMap[code] = 0
        end
        codeCountMap[code] = codeCountMap[code] + 1
      end
    end
  end
  return codeCountMap
end

function MainBoardModel:HasEnoughItemsToMergeAcquire(code, includeBoard, includeCache, includeStore)
  local codeCountMap = Table.DeepCopy(self:GetCodeCountMap(includeBoard, includeCache, includeStore))
  return BoardModelHelper.CalculateLackNumForMergeRequire(code, codeCountMap) == 0
end

function MainBoardModel:GenerateItems(listInfo, isnotUpdateOrderState)
  local listNewItems = {}
  for _, info in ipairs(listInfo) do
    local Pos = info.position
    local Code = info.code
    local newItem = ItemModelFactory.CreateWithCode(self, Pos, Code, true)
    self:SaveItemProperty(newItem)
    self:_SetItem(Pos, newItem, false)
    table.insert(listNewItems, newItem)
    if self.m_mergeAllIgnoredItems ~= nil then
      self.m_mergeAllIgnoredItems[newItem] = true
    end
  end
  self:CountItemsCode()
  if not isnotUpdateOrderState then
    self:UpdateOrderState()
  end
  return listNewItems
end

function MainBoardModel:FindSpreadPosition(itemSpread, itemModel)
  if itemSpread:IsDisposable() then
    return self:FindRandomPosition()
  else
    return self:FindEmptyPositionInCircleOrder(itemModel:GetPosition())
  end
end

function MainBoardModel:SpreadItem(sourceItem, newItemPosition, newItemCode, args)
  local message = BaseActionBoardModel.SpreadItem(self, sourceItem, newItemPosition, newItemCode, args)
  EventDispatcher.DispatchEvent(EEventType.ItemSpread, message)
  if args.logSpread then
    if args.spreadType == BoardSpreadType.GeneratorBoostExtraNormal then
      args.spreadType = BoardSpreadType.Normal
    elseif args.spreadType == BoardSpreadType.GeneratorBoostExtraSmart then
      args.spreadType = BoardSpreadType.GeneratorBoostSmart
    end
    local discoHandler = GM.BoostChargeManager:GetHandler(EBoostChargeType.BoostCharge_disco)
    local boostChargeSpreadType = 0
    if discoHandler and discoHandler:IsBoostDiscoActive() then
      boostChargeSpreadType = discoHandler:GetCacheData().curProperty
    end
    local biExt = {
      eb = args.energyBoostRatio,
      md = GM.EnergyBoostModel:GetEnergyBoostType(),
      st = args.spreadType == BoardSpreadType.Disco and boostChargeSpreadType or args.spreadType or 0,
      oriEle = args.originalElement,
      sc = args.specialScene
    }
    local itemSpread = sourceItem:GetComponent(ItemSpread)
    if itemSpread and itemSpread:CanSupportGeneratorBoost() then
      local model = GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition)
      local buff = model:GetActivedBuffString()
      if not StringUtil.IsNilOrEmpty(buff) then
        biExt.ab = buff
      end
    end
    GM.BIManager:LogSpread(sourceItem:GetCode(), newItemCode, biExt, self.BoardType)
  end
  self:_TryLogBoardFull()
end

function MainBoardModel:SkipItems(sourceItem, duration)
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil then
      item:DispatchComponentEvent("OnTimeSkip", duration, ItemSkipType.item)
    end
  end
  self.event:Call(BoardEventType.TimeSkip, {Item = sourceItem, Duration = duration})
end

function MainBoardModel:DragItem(item, targetPosition)
  if not self:PositionIsValid(targetPosition) then
    item:SetPosition(item:GetPosition())
    return
  end
  local sourceItem = self:GetItem(item:GetPosition())
  if sourceItem ~= item then
    item:SetPosition(item:GetPosition())
    return
  end
  local targetItem = self:GetItem(targetPosition)
  if targetItem == nil or targetItem == item then
    self:_SetItem(item:GetPosition(), nil, false)
    self:_SetItem(targetPosition, item, false)
    if targetItem ~= item then
      self:_LogMove(item, item:GetPosition(), targetPosition)
    end
    item:SetPosition(targetPosition)
    self:_UpdateAccelerate(item, targetItem)
    EventDispatcher.DispatchEvent(EEventType.ItemMoveEnd, {item = item})
    return
  end
  if self:CanItemAffect(item, targetItem) then
    if self:_AffectItem(item, targetItem, targetPosition) then
      return
    end
  elseif item:GetSpecialType() ~= nil then
    self:_ShowAffectFailTip(item, targetItem)
  end
  if self:CanItemMerge(item, targetItem) then
    self:_MergeItem(item, targetItem, targetPosition)
    return
  end
  local targetItemSwallow = targetItem:GetComponent(ItemSwallow)
  if targetItemSwallow ~= nil and targetItemSwallow:CanSwallow(item) then
    targetItemSwallow:Swallow(item)
    return
  end
  if not self:CanItemMove(targetItem) then
    item:SetPosition(item:GetPosition())
    return
  end
  local itemPosition = item:GetPosition()
  self:_SetItem(item:GetPosition(), nil, false)
  self:_SetItem(targetPosition, item, false)
  self:_SetItem(itemPosition, targetItem)
  self:_LogMove(item, item:GetPosition(), targetPosition)
  self:_LogMove(targetItem, targetPosition, itemPosition)
  item:SetPosition(targetPosition)
  targetItem:SetPosition(itemPosition)
  self:_UpdateAccelerate(item, targetItem)
end

function MainBoardModel:_AffectItem(item, targetItem, targetPosition)
  local specialType = item:GetSpecialType()
  if specialType == ItemSpecialType.LevelUp then
    GM.UIManager:OpenView(UIPrefabConfigName.UseSpecialItemConfirmWindow, item:GetType(), targetItem:GetType(), targetItem:GetMergedType(), nil, "rainbow_item_use_confirm", function(window)
      if self:CanItemAffect(item, targetItem) then
        self:RemoveItem(item)
        local newItem = self:ReplaceItem(targetItem, targetItem:GetMergedType())
        local mergeMessage = {
          Source = item,
          Target = targetItem,
          New = newItem
        }
        self.event:Call(BoardEventType.MergeItem, mergeMessage)
        EventDispatcher.DispatchEvent(EEventType.ItemMerged, mergeMessage)
        self:ShockNeighborItems(targetPosition)
        EventDispatcher.DispatchEvent(EEventType.ItemShocked)
        local ext = {levelup = 1}
        GM.BIManager:LogMerge(item:GetType(), newItem:GetCode(), ext)
      end
      window:Close()
    end)
    item:SetPosition(item:GetPosition())
    return true
  elseif specialType == ItemSpecialType.LevelDown then
    if targetItem:GetSpecialType() == ItemSpecialType.LevelDown then
      local targetItemSplit = targetItem:GetComponent(ItemSplit)
      local dragItemSplit = item:GetComponent(ItemSplit)
      self:RemoveItem(item)
      self:RemoveItem(targetItem)
      local newItem = self:GenerateItem(targetPosition, targetItem:GetType())
      local newItemSplit = newItem:GetComponent(ItemSplit)
      local scissorCount = targetItemSplit:GetSplitUseCount() + dragItemSplit:GetSplitUseCount()
      newItemSplit:SetSplitUseCount(scissorCount)
      local mergeMessage = {
        Source = item,
        Target = targetItem,
        New = newItem
      }
      self.event:Call(BoardEventType.MergeItem, mergeMessage)
      EventDispatcher.DispatchEvent(EEventType.ItemMerged, mergeMessage)
      GM.BIManager:LogMerge(item:GetType(), newItem:GetCode(), {scissor = scissorCount})
      return true
    else
      local type = targetItem:GetType()
      local chainId = GM.ItemDataModel:GetChainId(type)
      local level = GM.ItemDataModel:GetChainLevel(type)
      local chain = GM.ItemDataModel:GetChain(chainId)
      local prevType = chain[level - 1]
      GM.UIManager:OpenView(UIPrefabConfigName.UseSpecialItemConfirmWindow, item:GetType(), targetItem:GetType(), prevType, prevType, "scissor_item_use_confirm", function(window)
        if self:CanItemAffect(item, targetItem) then
          local itemSplit = item:GetComponent(ItemSplit)
          itemSplit:CostSplitUseCount()
          if not itemSplit:HasLeftSplitUseCount() then
            self:RemoveItem(item)
          end
          self:RemoveItem(targetItem)
          local newItem1 = self:GenerateItem(targetPosition, prevType)
          local otherPosition = self:FindEmptyPositionInSpreadOrder(targetPosition)
          local newItem2 = self:GenerateItem(otherPosition, prevType)
          local message = {
            Split = item,
            Target = targetItem,
            New1 = newItem1,
            New2 = newItem2
          }
          self.event:Call(BoardEventType.SplitItem, message)
          GM.BIManager:LogSplit(targetItem:GetType(), newItem1:GetType(), {scissor = 1})
          self:_TryLogBoardFull()
        end
        window:Close()
      end)
      item:SetPosition(item:GetPosition())
      return true
    end
  end
  return false
end

function MainBoardModel:_ShowAffectFailTip(specialItem, targetItem)
  local spType = specialItem:GetSpecialType()
  if spType == ItemSpecialType.LevelUp then
    GM.UIManager:ShowPromptWithKey("hint_not_upgrade")
  elseif spType == ItemSpecialType.LevelDown then
    if self:IsBoardFull() then
      GM.UIManager:ShowPromptWithKey("hint_board_full")
    else
      GM.UIManager:ShowPromptWithKey("hint_not_split")
    end
  end
end

function MainBoardModel:_UpdateAccelerate(item1, item2)
  local function checkFunc(item)
    if item == nil then
      return false
    end
    return item:GetComponent(ItemSpread) ~= nil and item:GetComponent(ItemSpread):CanAccelerate() or item:GetComponent(ItemTransform) ~= nil and item:GetComponent(ItemTransform):CanAccelerate() or item:GetComponent(ItemAccelerate) ~= nil and item:GetComponent(ItemAccelerate):IsActivated()
  end
  
  if checkFunc(item1) or checkFunc(item2) then
    self:UpdatePerSecond()
    self:UpdatePerSecond()
  end
end

function MainBoardModel:_MergeItem(item, targetItem, targetPosition, autoUpdateOrderState)
  local mergeInfo = self:_DoMergeItem(item, targetItem, targetPosition, autoUpdateOrderState)
  self:_LogMerge(mergeInfo)
end

function MainBoardModel:_DoMergeItem(item, targetItem, targetPosition)
  local mergeInfo = BaseActionBoardModel._DoMergeItem(self, item, targetItem, targetPosition)
  self.m_lastBreakBubbleType = nil
  local scoreRaceModel = GM.ActivityManager:GetModel(ActivityType.ScoreRace)
  local mergeScore = scoreRaceModel:_OnItemMerged(item)
  if mergeScore ~= nil then
    mergeInfo.ScoreRace_Score = mergeScore
  end
  local hasCreateItem = false
  if not self:IsBoardFull() and not hasCreateItem then
    local tempItemModel = GM.ActivityManager:GetModel(ActivityType.TempItem)
    local tempType = tempItemModel:GenerateType(mergeInfo.New:GetType())
    if tempType ~= nil then
      local position = self:FindEmptyPositionInSpreadOrder(mergeInfo.New:GetPosition())
      self:SpreadItem(mergeInfo.New, position, ItemCodePrefix.Temp .. tempType, {logSpread = false})
      mergeInfo.TempType = tempType
      hasCreateItem = true
    end
  end
  if not self:IsBoardFull() and not hasCreateItem then
    local CardItemModel = GM.ActivityManager:GetModel(ActivityType.CardItem)
    local itemType = CardItemModel:TryGenerateItem(mergeInfo.itemType)
    if itemType ~= nil then
      local position = self:FindEmptyPositionInSpreadOrder(mergeInfo.New:GetPosition())
      self:SpreadItem(mergeInfo.New, position, itemType, {
        logSpread = false,
        spreadType = BoardSpreadType.CardItem
      })
      mergeInfo.CardType = itemType
      hasCreateItem = true
      EventDispatcher.DispatchEvent(EEventType.CardItemGenerate, {
        item = self.m_itemLayerModel:GetItem(position)
      })
    end
  end
  if not hasCreateItem then
    local model = GM.ActivityManager:GetModel(ActivityType.EnergyBubble)
    if model and model:CanSpreadEnergyBubble() then
      local bubbleInfo = model:GetBubbleInfo()
      if bubbleInfo ~= nil then
        local position = self:FindEmptyPositionInSpreadOrder(mergeInfo.New:GetPosition())
        self:SpreadItem(mergeInfo.New, position, bubbleInfo.Code, {logSpread = false})
        mergeInfo.BubbleType = bubbleInfo.Code
        mergeInfo.Group = bubbleInfo.Group
        hasCreateItem = true
      end
    end
  end
  if not hasCreateItem then
    local bubbleType = self:_TrySpreadBubbleByMerge(mergeInfo.New, targetItem)
    mergeInfo.BubbleType = bubbleType
    if bubbleType ~= nil then
      local model = GM.ActivityManager:GetModel(ActivityType.BubbleSale)
      if model and model:IsActivityOpen() then
        local salePrice, oriPrice = model:GetBubblePrice(bubbleType)
        mergeInfo.BubbleSalePrice = salePrice
        mergeInfo.BubblePrice = oriPrice
        hasCreateItem = true
      end
    end
  end
  if not self:IsBoardFull() then
    local level = GM.SystemConfigModel:GetConfig(SystemConfigKey.SpreadCoinMinChainLevel)
    if level <= GM.ItemDataModel:GetChainLevel(mergeInfo.New:GetType()) then
      local coinPosition = self:FindEmptyPositionInSpreadOrder(mergeInfo.New:GetPosition())
      self:SpreadItem(mergeInfo.New, coinPosition, ItemType.Coin01, {logSpread = false})
    end
  end
  GM.SyncModel:CheckMoreUpload(mergeInfo.New:GetType())
  return mergeInfo
end

function MainBoardModel:_TrySpreadBubbleByMerge(newItem, targetItem)
  if self:IsBoardFull() then
    return
  end
  local bubbleType, bubbleChance
  if GM.OpenFunctionModel:IsFunctionOpen(EFunction.Bubble) then
    bubbleChance = newItem:GetBubbleChance()
  end
  local spreadBubbleTestInfo = ""
  local testMode = GameConfig.IsTestMode()
  if bubbleChance ~= nil and 0 < bubbleChance then
    if self:_HasBubbleItemWithInnerCode(newItem:GetType()) then
      bubbleChance = nil
      if testMode then
        spreadBubbleTestInfo = "\229\183\178\231\187\143\230\156\137\229\175\185\229\186\148\231\177\187\229\158\139\231\154\132\230\179\161\230\179\161\230\163\139\229\173\144\239\188\140\228\184\141\231\148\159\230\136\144"
      end
    elseif self:_CanBubbleBuyBonus(targetItem:GetType()) or self:_CanBubbleOrderBonus(newItem:GetType()) then
      bubbleChance = 100
      if testMode then
        if self:_CanBubbleBuyBonus(targetItem:GetType()) then
          spreadBubbleTestInfo = "\233\128\154\232\191\135\232\180\173\228\185\176\230\179\161\230\179\161\230\163\139\229\173\144\229\144\136\230\136\144\230\150\176\230\163\139\229\173\144\228\188\154\232\191\158\231\187\173\228\186\167\231\148\159\230\179\161\230\179\161\230\163\139\229\173\144\239\188\140100%\228\186\167\231\148\159"
        else
          spreadBubbleTestInfo = "\229\144\136\230\136\144\232\174\162\229\141\149\230\137\128\233\156\128\230\163\139\229\173\144\231\154\132\229\137\141\228\184\128\231\186\167\230\163\139\229\173\144\239\188\140100%\228\186\167\231\148\159"
        end
      end
    else
      local originBubbleChance = bubbleChance
      local ratio1, ratio2
      local ratio = self:_GetDecreaseBubbleChanceRatio(newItem)
      if ratio ~= nil and 0 < ratio then
        Log.Debug("DecreaseBubble1:" .. ratio)
        bubbleChance = bubbleChance * ratio
        ratio1 = ratio
      end
      ratio = self:_GetDecreaseBubbleChanceRatio2(newItem)
      if ratio ~= nil and 0 < ratio then
        Log.Debug("DecreaseBubble2:" .. ratio)
        bubbleChance = bubbleChance * ratio
        ratio2 = ratio
      end
      ratio = GM.BubbleDecreaseModel:GetBubbleDecreaseRatio()
      bubbleChance = bubbleChance * ratio
      bubbleChance = math.max(bubbleChance, 1)
      if testMode then
        spreadBubbleTestInfo = "\229\136\157\229\167\139\230\166\130\231\142\135\239\188\154" .. originBubbleChance .. "%" .. "\n\232\174\162\229\141\149\228\184\141\233\156\128\232\166\129\228\186\167\231\148\159\231\154\132\230\166\130\231\142\135\232\161\176\229\135\143:" .. tostring(ratio1 or "\230\151\160") .. "\n\229\173\152\229\156\168\230\155\180\233\171\152\231\173\137\231\186\167\230\163\139\229\173\144\228\186\167\231\148\159\231\154\132\230\166\130\231\142\135\232\161\176\229\135\143:" .. tostring(ratio2 or "\230\151\160") .. "\n\231\142\169\229\174\182\230\156\170\232\180\173\228\185\176\230\179\161\230\179\161\228\186\167\231\148\159\231\154\132\230\166\130\231\142\135\232\161\176\229\135\143:" .. tostring(ratio < 1 and ratio or "\230\151\160") .. "\n\230\156\128\231\187\136\230\166\130\231\142\135\239\188\154" .. tostring(bubbleChance) .. "%"
      end
    end
  end
  if GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestBubbleMustSpread, 0) == 1 then
    bubbleChance = 100
    if testMode then
      spreadBubbleTestInfo = spreadBubbleTestInfo .. "\n\227\128\144\231\137\185\230\174\138\239\188\154\230\181\139\232\175\149\230\168\161\229\188\143\228\184\139\229\188\186\229\136\182\228\186\167\231\148\159\230\179\161\230\179\161\230\163\139\229\173\144\227\128\145"
    end
  end
  if bubbleChance ~= nil and bubbleChance >= MathUtil.Random(100) then
    bubbleType = newItem:GetType()
    local bubbleCode = ItemCodePrefix.Bubble .. bubbleType
    if tonumber(bubbleType) ~= nil then
      bubbleCode = tostring(tonumber(bubbleType) + ItemCodeOffset.Bubble)
    end
    local bubblePosition = self:FindEmptyPositionInSpreadOrder(newItem:GetPosition())
    self:SpreadItem(newItem, bubblePosition, bubbleCode, {logSpread = false})
    EventDispatcher.DispatchEvent(EEventType.BubbleSpread, {itemModel = newItem})
  end
  if testMode then
    local fullTestInfo = "\228\184\138\230\172\161\229\144\136\230\136\144\230\179\161\230\179\161\230\166\130\231\142\135\229\143\152\229\140\150\232\191\135\231\168\139\228\191\161\230\129\175\239\188\154" .. "\n\231\155\174\230\160\135\230\163\139\229\173\144\231\177\187\229\158\139" .. tostring(newItem:GetType()) .. "\n\230\152\175\229\144\166\228\186\167\231\148\159\230\179\161\230\179\161:" .. tostring(bubbleType ~= nil) .. "\n[\232\191\135\231\168\139\228\191\161\230\129\175]\n" .. (spreadBubbleTestInfo or "\230\151\160")
    GM.BubbleDecreaseModel:RecordBubbleDecreaseInfo(fullTestInfo)
  end
  return bubbleType
end

function MainBoardModel:_GetDecreaseBubbleChanceRatio(newItem)
  local decreaseRatio = GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.BubbleOrderDecrease, ConfigModel.EGeneralConfigParam.Float)
  if IsNil(decreaseRatio) or decreaseRatio <= 0 or 1 <= decreaseRatio then
    return
  end
  local itemCodeNumByMapAndInventory = self:GetCodeCountMap(true, false, true)
  local orderModel = self:GetOrderModel(OrderModelType.Slot)
  local itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
  local itemCodeExistMap = {}
  for _, order in pairs(orderModel:GetOrders()) do
    local orderRequirements = order:GetRequirements()
    for k, itemCode in pairs(orderRequirements) do
      if itemCodeConfigMap[itemCode] ~= nil and itemCodeConfigMap[itemCode].WeightMultiple == 1 then
        if not itemCodeExistMap[itemCode] then
          itemCodeExistMap[itemCode] = 0
        end
        itemCodeExistMap[itemCode] = itemCodeExistMap[itemCode] + 1
      end
    end
  end
  local arrItemCode = {}
  local chainId = GM.ItemDataModel:GetChainId(newItem:GetType())
  local chain = GM.ItemDataModel:GetChain(chainId)
  for i, code in ipairs(chain) do
    if itemCodeConfigMap[code] ~= nil and itemCodeConfigMap[code].WeightMultiple == 1 then
      arrItemCode[#arrItemCode + 1] = code
    end
  end
  local sum = 0
  for i, v in ipairs(arrItemCode) do
    if itemCodeExistMap[v] then
      sum = itemCodeNumByMapAndInventory[v] or 0
      if sum < itemCodeExistMap[v] then
        return
      end
    end
  end
  return decreaseRatio
end

function MainBoardModel:_GetDecreaseBubbleChanceRatio2(newItem)
  local level = GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.BubbleChainDecreaseLevel, ConfigModel.EGeneralConfigParam.Int)
  if IsNil(level) or level <= 0 then
    return
  end
  local decreaseRatio = GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.BubbleChainDecreaseRatio, ConfigModel.EGeneralConfigParam.Float)
  if IsNil(decreaseRatio) or decreaseRatio <= 0 or 1 <= decreaseRatio then
    return
  end
  local mapBoardItem = self:GetCodeCountMap(true, false, false)
  local arrBubbleItem = {}
  local chainId = GM.ItemDataModel:GetChainId(newItem:GetType())
  local chain = GM.ItemDataModel:GetChain(chainId)
  if level >= #chain then
    return
  end
  local bubbleCode
  for i = level + 1, #chain do
    bubbleCode = ItemCodePrefix.Bubble .. chain[i]
    if tonumber(chain[i]) ~= nil then
      bubbleCode = tostring(tonumber(chain[i]) + ItemCodeOffset.Bubble)
    end
    arrBubbleItem[#arrBubbleItem + 1] = bubbleCode
  end
  if Table.IsEmpty(arrBubbleItem) then
    return
  end
  local ratio = 1
  for i, v in ipairs(arrBubbleItem) do
    if mapBoardItem[v] ~= nil and 0 < mapBoardItem[v] then
      ratio = ratio * decreaseRatio ^ mapBoardItem[v]
    end
  end
  if ratio == 1 then
    return
  end
  return ratio
end

function MainBoardModel:_HasBubbleItemWithInnerCode(code)
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    local itemBubble = item and item:GetComponent(ItemBubble)
    if itemBubble ~= nil and itemBubble:GetInnerItemCode() == code then
      return true
    end
  end
  return false
end

function MainBoardModel:_CanBubbleBuyBonus(sourceType)
  return sourceType ~= nil and self.m_lastBreakBubbleType == sourceType and GM.ConfigModel:HasBubbleBuyBonus()
end

function MainBoardModel:_CanBubbleOrderBonus(mergedType)
  local type = GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.BubbleOrderBonus, ConfigModel.EGeneralConfigParam.Int)
  if IsNil(type) or type ~= 1 and type ~= 2 then
    return false
  end
  local orderModel = self.m_orderModels[OrderModelType.Slot]
  local itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
  if itemCodeConfigMap[mergedType] == nil or itemCodeConfigMap[mergedType].WeightMultiple ~= 1 then
    return false
  end
  local config = GM.ItemDataModel:GetModelConfig(mergedType)
  if config == nil then
    return false
  end
  local nextLevelCode = config.MergedType
  if nextLevelCode == nil then
    return false
  end
  if self:GetOrderCodeLackCountMap()[nextLevelCode] == nil or self:GetOrderCodeLackCountMap()[nextLevelCode] <= 0 then
    return false
  end
  if type == 2 then
    local itemCodeNumByMapAndInventory = self:GetCodeCountMap(true, false, true)
    if itemCodeNumByMapAndInventory and itemCodeNumByMapAndInventory[mergedType] and 2 <= itemCodeNumByMapAndInventory[mergedType] then
      return false
    end
  end
  return true
end

function MainBoardModel:SellItem(item)
  local cost = item:GetSellingPrice()
  if cost ~= 0 then
    local exchanges = {
      {
        [PROPERTY_TYPE] = EPropertyType.Gold,
        [PROPERTY_COUNT] = cost,
        [PROPERTY_CRYPT] = Crypt.CryptCurrency(cost)
      }
    }
    RewardApi.AcquireRewardsLogic(exchanges, EPropertySource.Give, EBIType.ItemSell)
  end
  self:RemoveItem(item)
  GM.BIManager:LogStore(item:GetCode(), 1, EPropertyType.Gold, cost, EShopType.SellItem)
  self.event:Call(BoardEventType.SellItem, {Source = item})
end

function MainBoardModel:UndoSellItem(item)
  local position = item:GetPosition()
  local removedItem
  local originalItem = self:GetItem(item:GetPosition())
  if originalItem ~= nil then
    local otherPosition = self:FindEmptyPositionInSpreadOrder(item:GetPosition())
    if otherPosition == nil then
      removedItem = originalItem
      self:RemoveItem(originalItem)
      GM.BIManager:LogAction(EBIType.RemoveItem, {
        t = originalItem:GetCode(),
        s = "undoSellRemove"
      })
    else
      position = otherPosition
    end
  end
  local cost = item:GetSellingPrice()
  if cost ~= 0 then
    GM.PropertyDataManager:Consume(EPropertyType.Gold, cost, EBIType.UndoSellItem, item:GetCode())
  end
  item:SetPosition(position)
  self:SaveItemProperty(item)
  self:_SetItem(position, item)
  GM.BIManager:LogStore(EPropertyType.Gold, cost, item:GetCode(), 1, EShopType.SellItem)
  self.event:Call(BoardEventType.UndoSellItem, {Source = item, Removed = removedItem})
end

function MainBoardModel:BreakItem(item, isFree)
  item:DispatchComponentEvent("OnBreak", isFree)
  local itemBubble = item:GetComponent(ItemBubble)
  if itemBubble ~= nil then
    self.m_lastBreakBubbleType = itemBubble:GetInnerItemCode()
  end
end

function MainBoardModel:_LogMove(item, sourcePosition, targetPosition)
  local function positionToString(position)
    return position:GetX() .. "," .. position:GetY()
  end
  
  local action = {
    code = item:GetCode(),
    source = positionToString(sourcePosition),
    target = positionToString(targetPosition),
    event_id = BoardModelHelper.GetActiveActivityModelEventId()
  }
  local actionString = GM.BIManager:TableToString(action)
  GM.BIManager:LogAction(EBIType.MoveItem, actionString)
end

function MainBoardModel:_LogMerge(mergeInfo)
  local ext = {
    temp = mergeInfo.TempType,
    bubble = mergeInfo.BubbleType,
    bubbleSalePrice = mergeInfo.BubbleSalePrice,
    bubblePrice = mergeInfo.BubblePrice,
    balloon = mergeInfo.Balloon,
    scorerace = mergeInfo.ScoreRace_Score,
    CardType = mergeInfo.CardType
  }
  if mergeInfo.Target:GetComponent(ItemCobweb) ~= nil then
    ext.cobWeb = 1
  end
  local logType = mergeInfo.Source:GetType()
  if mergeInfo.Target:GetComponent(ItemTemp) ~= nil then
    logType = mergeInfo.Target:GetType()
  end
  if mergeInfo.Group ~= nil then
    ext.ebGroup = mergeInfo.Group
  end
  if self:CheckNearestTouchedMergeItem(mergeInfo.Source, mergeInfo.Target) then
    ext.isTouched = true
  end
  GM.BIManager:LogMerge(logType, mergeInfo.New:GetCode(), ext, self.BoardType)
end

function MainBoardModel:_LogCacheItems(info)
  for _, code in ipairs(info.items) do
    GM.BIManager:LogAction(EBIType.CacheItem, tostring(code))
  end
end

function MainBoardModel:_TryLogBoardFull()
  if self:IsBoardFull() then
    GM.BIManager:LogAction(EBIType.BoardFull, {
      itf = self.IsInventoryFull and self:IsInventoryFull() and 1 or 0,
      m = GM.SceneManager:GetGameMode() == EGameMode.Main and 1 or 0
    })
  end
end

function MainBoardModel:StoreItem(item)
  local bStore, reason = self:CanItemStore(item)
  if not bStore then
    self.event:Call(BoardEventType.StoreFailed, {
      Item = item,
      Reason = reason or StoreFailedReason.CannotStore
    })
    return false
  end
  if self:IsInventoryFull() then
    self.event:Call(BoardEventType.StoreFailed, {
      Item = item,
      Reason = StoreFailedReason.InventoryFull
    })
    return false
  end
  self:_SetItem(item:GetPosition(), nil, false)
  self.m_itemStoreModel:AddItem(item)
  self:CountItemsCode()
  self:UpdateOrderState()
  GM.BIManager:LogAction(EBIType.StoreItem, tostring(item:GetCode()))
  self.event:Call(BoardEventType.StoreItem, {Source = item})
  EventDispatcher.DispatchEvent(EEventType.InventoryStoryItem)
  return true
end

function MainBoardModel:RetrieveStoredItem(index)
  local position = self:FindEmptyPositionInValidOrder()
  if position == nil then
    return false
  end
  local item = self.m_itemStoreModel:GetItem(index)
  if item == nil then
    Log.Assert(false, "item\228\184\141\232\131\189\228\184\186\231\169\186")
    return false
  end
  self.m_itemStoreModel:RemoveItem(index)
  self:_SetItem(position, item)
  item:SetPosition(position)
  GM.BIManager:LogAction(EBIType.RetrieveItem, tostring(item:GetCode()))
  self.event:Call(BoardEventType.RetrieveStoredItem, {Source = item})
  EventDispatcher.DispatchEvent(EEventType.ItemRetrieved, {item = item})
  self:_TryLogBoardFull()
  return true
end

function MainBoardModel:GetStoredItem(index)
  return self.m_itemStoreModel:GetItem(index)
end

function MainBoardModel:GetStoredItemCount()
  return self.m_itemStoreModel:GetItemCount()
end

function MainBoardModel:IsInventoryFull()
  return self:GetStoredItemCount() >= self:GetStoreSlotCount()
end

function MainBoardModel:BuyStoreSlot()
  local slotConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.InventorySlot)
  local cap = GM.MiscModel:GetInventoryCapInNumber() + 1
  if GM.PropertyDataManager:Consume(EPropertyType.Gem, slotConfig.UnlockCost[cap + slotConfig.DefaultNumber], EBIType.BuyInventorySlot, cap) then
    GM.AudioModel:PlayEffect(AudioFileConfigName.SfxShopBuy)
    GM.MiscModel:SetInventoryCap(cap)
    EventDispatcher.DispatchEvent(EEventType.InventoryNewSlot)
    return true
  end
  return false
end

function MainBoardModel:GetStoreSlotCount()
  local slotConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.InventorySlot)
  return GM.MiscModel:GetInventoryCapInNumber() + slotConfig.DefaultNumber
end

function MainBoardModel:CanItemStore(item)
  if not self:CanItemMove(item) then
    return false
  end
  if item:GetComponent(ItemBubble) ~= nil or item:GetComponent(ItemTemp) ~= nil or item:GetComponent(ItemPropertyBubble) ~= nil then
    return false
  end
  local itemTransform = item:GetComponent(ItemTransform)
  if itemTransform ~= nil and itemTransform:GetDuration() ~= nil then
    return false
  end
  local itemSpread = item:GetComponent(ItemSpread)
  if itemSpread ~= nil and itemSpread:GetState() == ItemSpreadState.Opening then
    return false
  end
  if self:IsGeneratorFactoryOpen() and self:IsGeneratorFactoryItem(item:GetType()) then
    return false, StoreFailedReason.GeneratorFactory
  end
  return true
end

function MainBoardModel:GetFirstUnlockGeneratorItemTipType(itemType)
  local chainId = GM.ItemDataModel:GetChainId(itemType)
  if not StringUtil.IsNilOrEmpty(chainId) then
    local type = ItemGeneratorFirstUnlockTipType[chainId]
    if not StringUtil.IsNilOrEmpty(type) then
      return type
    end
  end
end

function MainBoardModel:IsFirstUnlockGeneratorItemTipType(itemType)
  local chainId = GM.ItemDataModel:GetChainId(itemType)
  if not StringUtil.IsNilOrEmpty(chainId) then
    local type = ItemGeneratorFirstUnlockTipType[chainId]
    if not StringUtil.IsNilOrEmpty(type) then
      return tonumber(itemType) >= tonumber(type)
    end
  end
  return false
end

function MainBoardModel:IsGeneratorFactoryOpen()
  return self.m_itemGeneratorFactoryModel:IsOpen()
end

function MainBoardModel:IsGeneratorFactoryItem(itemType)
  return self.m_itemGeneratorFactoryModel:IsGeneratorFactoryItem(itemType)
end

function MainBoardModel:StoreFactoryItem(type)
  self.m_itemGeneratorFactoryModel:StoreItem(type)
end

function MainBoardModel:GetGenFactoryDefaultIndex()
  return self.m_itemGeneratorFactoryModel:GetDefaultIndex()
end

function MainBoardModel:GetGenDataByType(type)
  return self.m_itemGeneratorFactoryModel:GetGenDataByType(type)
end

function MainBoardModel:GetItemGeneratorFactoryModel()
  return self.m_itemGeneratorFactoryModel
end

function MainBoardModel:GetOrderModel(orderModelType)
  return self.m_orderModels[orderModelType]
end

function MainBoardModel:_RefreshOrderAndCodeData()
  local codeCountMap = self:GetCodeCountMap(true, false, true)
  self.m_codeStateMap = {}
  for _, orderModel in pairs(self.m_orderModels) do
    orderModel:UpdateState(codeCountMap, self.m_codeStateMap)
  end
  self.m_orderCodeRequireCountMap, self.m_orderCodeLackCountMap = self:CalculateOrderCodeCountData(codeCountMap)
end

function MainBoardModel:UpdateOrderState()
  self:_RefreshOrderAndCodeData()
  EventDispatcher.DispatchEvent(EEventType.OrderStateChanged)
end

function MainBoardModel:CustomerUpgradeActive()
  self:_RefreshOrderAndCodeData()
  EventDispatcher.DispatchEvent(EEventType.CustomerUpgradeActive)
end

local function setRequirement(requirement, codeRequireCountMap)
  if codeRequireCountMap[requirement] == nil then
    codeRequireCountMap[requirement] = 0
  end
  codeRequireCountMap[requirement] = codeRequireCountMap[requirement] + 1
end

function MainBoardModel:CalculateOrderCodeCountData(codeCountMap, alreadyRequiredItems)
  local orderCodeRequireCountMap = {}
  for _, order in pairs(self:GetOrders()) do
    if order:GetState() ~= OrderState.Finished then
      for _, requirement in ipairs(order:GetRequirements()) do
        setRequirement(requirement, orderCodeRequireCountMap)
      end
    end
  end
  if alreadyRequiredItems ~= nil then
    for _, requirement in ipairs(alreadyRequiredItems) do
      setRequirement(requirement, orderCodeRequireCountMap)
    end
  end
  local orderCodeLackCountMap = {}
  for code, requireCount in pairs(orderCodeRequireCountMap) do
    local count = codeCountMap[code] or 0
    if requireCount > count then
      orderCodeLackCountMap[code] = requireCount - count
    end
  end
  return orderCodeRequireCountMap, orderCodeLackCountMap
end

function MainBoardModel:CalculateOrderCodeLackNumMap(isNotBoard, isNotCache, isNotStore)
  local codeCountMap = GM.MainBoardModel:GetCodeCountMap(not isNotBoard, not isNotCache, not isNotStore)
  local orderCodeRequireCountMap = {}
  for _, order in pairs(self:GetOrders()) do
    if order:GetState() ~= OrderState.Finished then
      for _, requirement in ipairs(order:GetRequirements()) do
        setRequirement(requirement, orderCodeRequireCountMap)
      end
    end
  end
  local orderCodeLackCountMap = {}
  for code, requireCount in pairs(orderCodeRequireCountMap) do
    while 1 <= requireCount do
      local lackNum = BoardModelHelper.CalculateLackNumForMergeRequire(code, codeCountMap)
      if 0 < lackNum then
        if orderCodeLackCountMap[code] == nil then
          orderCodeLackCountMap[code] = lackNum
        else
          orderCodeLackCountMap[code] = orderCodeLackCountMap[code] + lackNum
        end
      end
      requireCount = requireCount - 1
    end
  end
  return orderCodeLackCountMap
end

function MainBoardModel:CalculateOrderCodeLackNumMapByLevelSize(isNotBoard, isNotCache, isNotStore)
  local codeCountMap = GM.MainBoardModel:GetCodeCountMap(not isNotBoard, not isNotCache, not isNotStore)
  local listRequirements = {}
  for _, order in pairs(self:GetOrders()) do
    if order:GetState() ~= OrderState.Finished then
      for _, requirement in ipairs(order:GetRequirements()) do
        table.insert(listRequirements, {
          code = requirement,
          level = GM.ItemDataModel:GetChainLevel(requirement)
        })
      end
    end
  end
  table.sort(listRequirements, function(a, b)
    return a.level < b.level
  end)
  local caclauteNoFinishList = {}
  for _, requirement in ipairs(listRequirements) do
    local lackNum = BoardModelHelper.CalculateLackNumForMergeRequire(requirement.code, codeCountMap)
    if 0 < lackNum then
      table.insert(caclauteNoFinishList, {
        code = requirement.code,
        level = requirement.level,
        lackNum = lackNum
      })
    end
  end
  local mapTarget = {}
  for _, requirement in ipairs(caclauteNoFinishList) do
    if mapTarget[requirement.code] == nil then
      mapTarget[requirement.code] = 0
    end
    mapTarget[requirement.code] = mapTarget[requirement.code] + requirement.lackNum
  end
  return mapTarget
end

function MainBoardModel:GetOrderBoostOrderCodeLackMap()
  local codeCountMap = self:GetCodeCountMap(true, false, true)
  local orderBoostCodeRequireCountMap = {}
  local obModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  for _, order in pairs(self:GetOrders()) do
    for _, requirement in ipairs(order:GetRequirements()) do
      if obModel ~= nil and obModel:GetAddOrderBoostScoreByOrder(order) > 0 then
        setRequirement(requirement, orderBoostCodeRequireCountMap)
      end
    end
  end
  local orderBoostOrderCodeLackCountMap = {}
  for code, requireCount in pairs(orderBoostCodeRequireCountMap) do
    local count = codeCountMap[code] or 0
    if requireCount > count then
      orderBoostOrderCodeLackCountMap[code] = requireCount - count
    end
  end
  return orderBoostOrderCodeLackCountMap
end

function MainBoardModel:FinishOrder(order)
  if order:GetInnerType() == MainOrderType.Special then
    self:_FinishSpecialOrder(order)
    return
  elseif order:GetInnerType() == MainOrderType.Branch then
    self:_FinishBranchOrder(order)
    return
  end
  local rewards, mapDelayRewards = order:GetOrderRewardByFinishOrder()
  rewards = Table.DeepCopy(rewards)
  mapDelayRewards = Table.DeepCopy(mapDelayRewards)
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, EBIType.FinishOrder, self.m_gameMode, CacheItemType.Type2)
  local giftRewards = order:GetGiftRewards()
  if giftRewards ~= nil and GM.CharacterIntimacyModel:IsOpen() then
    RewardApi.AcquireRewardsLogic(giftRewards, EPropertySource.Give, EBIType.FinishOrder)
  end
  local buffRewards
  if order.GetBuffRewards then
    buffRewards = order:GetBuffRewards()
    if buffRewards ~= nil then
      RewardApi.AcquireRewardsLogic(buffRewards, EPropertySource.Give, EBIType.FinishOrder)
    end
  end
  local orderBoostModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  local triggerButterfly = false
  if order:GetGameMode() == EGameMode.Main and orderBoostModel:GetAddSmileScoreBySlot(order:GetSlot()) > 0 then
    local smileNum = orderBoostModel:GetAddSmileScoreBySlot(order:GetSlot())
    GM.BIManager:LogAcquire("OrderBoostSmoke", smileNum, EBIType.FinishOrder)
    orderBoostModel:OnOrderFinished(order)
    order:SetOrderBoostFinish(smileNum)
    if smileNum == 1 and orderBoostModel:GetCurScore() == 1 and orderBoostModel:GetLogicType() == EOrderBoostType.Normal then
      triggerButterfly = true
    end
  end
  order:SetFinished()
  local removeItemInfo = self:RemoveOrderRequirementItems(order)
  self:TryAcquireCookingFrenzyReward(order)
  local chestCustomerModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  if chestCustomerModel:IsChestCustomerOrder(order:GetSlot()) then
    EventDispatcher.DispatchEvent(EEventType.ChestCustomerOrderFinish)
  end
  for _, eleRewards in pairs(mapDelayRewards) do
    RewardApi.AcquireRewardsLogic(eleRewards, EPropertySource.Give, EBIType.FinishOrder, self.m_gameMode, CacheItemType.Type2)
  end
  for _, orderModel in pairs(self.m_orderModels) do
    if orderModel:ContainsOrder(order) then
      orderModel:FinishOrder(order)
      break
    end
  end
  self:UpdateOrderState()
  if triggerButterfly then
    EventDispatcher.DispatchEvent(EEventType.SmileOrderDeliver_1)
  end
  GM.SyncModel:CheckMoreUpload(nil, nil, order:GetRequirements())
  self.event:Call(BoardEventType.FinishOrder, {
    Order = order,
    RemoveItemInfo = removeItemInfo,
    Rewards = rewards,
    mapDelayRewards = mapDelayRewards
  })
end

function MainBoardModel:RemoveOrderRequirementItems(order)
  local removeInfo = {}
  local removedItemsFromBoard = {}
  local removedItemsFromInventory = {}
  for i, requirement in ipairs(order:GetRequirements()) do
    local itemRemoved = false
    for position in self:GetValidPositionIterator() do
      local item = self:GetItem(position)
      if item ~= nil and item:GetCode() == requirement then
        self:RemoveItem(item, false)
        itemRemoved = true
        removedItemsFromBoard[i] = item
        break
      end
    end
    if not itemRemoved then
      for j = 1, self.m_itemStoreModel:GetItemCount() do
        local item = self.m_itemStoreModel:GetItem(j)
        if item ~= nil and item:GetCode() == requirement then
          self.m_itemStoreModel:RemoveItem(j)
          self:_RemoveItemProperty(item)
          itemRemoved = true
          removedItemsFromInventory[i] = requirement
          break
        end
      end
    end
    self:CountItemsCode()
    self:UpdateOrderState()
    if not itemRemoved then
      GM.BIManager:LogErrorInfo(EBIType.FinishOrderRemoveItemError, requirement)
    end
  end
  removeInfo.RemovedFromBoard = removedItemsFromBoard
  removeInfo.RemovedFromInventory = removedItemsFromInventory
  return removeInfo
end

function MainBoardModel:GetOrders(orderModelType)
  if orderModelType == nil then
    local orders = {}
    for _, orderModel in pairs(self.m_orderModels) do
      for k, v in pairs(orderModel:GetOrders()) do
        orders[k] = v
      end
    end
    return orders
  elseif self.m_orderModels[orderModelType] ~= nil then
    return self.m_orderModels[orderModelType]:GetOrders()
  end
  return {}
end

function MainBoardModel:GetOrderModelType(order)
  for type, orderModel in pairs(self.m_orderModels) do
    if orderModel:ContainsOrder(order) then
      return type
    end
  end
end

function MainBoardModel:GetOrderCodeStateMap()
  return self.m_codeStateMap
end

function MainBoardModel:GetOrderCodeLackCount(code)
  return self.m_orderCodeLackCountMap[code] or 0
end

function MainBoardModel:GetOrderCodeLackCountMap()
  return self.m_orderCodeLackCountMap
end

function MainBoardModel:GetOrderCodeRequireCount(code)
  return self.m_orderCodeRequireCountMap[code] or 0
end

function MainBoardModel:GetOrderCodeRequireCountMap()
  return self.m_orderCodeRequireCountMap
end

function MainBoardModel:GetSpecialOrderConfig(order)
  if order:GetInnerType() == MainOrderType.Special then
    return self.m_orderModels[OrderModelType.Slot]:GetSpecialOrderConfigWithOffset(0)
  elseif order:GetInnerType() == MainOrderType.Branch then
    return self.m_orderModels[OrderModelType.Slot]:GetBranchOrderConfig()[order:GetSlot()]
  end
end

function MainBoardModel:GetCurrentSpecialOrder()
  local orders = self.m_orderModels[OrderModelType.Slot]:GetOrders()
  return orders[MainOrderSlotDefinition.SpecialSlot]
end

function MainBoardModel:_FinishSpecialOrder(order)
  self.m_orderModels[OrderModelType.Slot]:FinishOrder(order)
  local orderConfig = self:GetSpecialOrderConfig(order)
  local requirementChains = {}
  for i = 1, 3 do
    local requirement = orderConfig["Requirement" .. i]
    if requirement ~= nil then
      requirementChains[#requirementChains + 1] = GM.ItemDataModel:GetChainId(requirement)
    end
  end
  
  local function shouldRemoveType(type)
    local chain = GM.ItemDataModel:GetChainId(type)
    return Table.ListContain(requirementChains, chain) or self.IsInGeneratorChain(chain, orderConfig.GeneratorChain)
  end
  
  local function shouldRemove(item)
    local itemBubble = item:GetComponent(ItemBubble)
    local type = itemBubble == nil and item:GetType() or itemBubble:GetInnerItemCode()
    return shouldRemoveType(type)
  end
  
  local removedItems = self:_BatchRemoveItems(shouldRemove, shouldRemoveType)
  self:UpdateOrderState()
  RewardApi.AcquireRewardsLogic(orderConfig.Rewards, EPropertySource.Give, EBIType.SpecialTaskComplete, EGameMode.Main, CacheItemType.Type2)
  GM.MapDataModel:SetSlot(orderConfig.EndTimeline, "1")
  self.event:Call(BoardEventType.FinishSpecialOrder, {Order = order, Removed = removedItems})
end

function MainBoardModel:_FinishBranchOrder(order)
  self.m_orderModels[OrderModelType.Slot]:FinishOrder(order)
  local orderConfig = self:GetSpecialOrderConfig(order)
  local requirementChains = {
    GM.ItemDataModel:GetChainId(orderConfig.Requirement)
  }
  
  local function shouldRemoveType(type)
    local chain = GM.ItemDataModel:GetChainId(type)
    return Table.ListContain(requirementChains, chain) or self.IsInGeneratorChain(chain, orderConfig.GeneratorChain)
  end
  
  local function shouldRemove(item)
    local itemBubble = item:GetComponent(ItemBubble)
    local type = itemBubble == nil and item:GetType() or itemBubble:GetInnerItemCode()
    return shouldRemoveType(type)
  end
  
  local removedItems = self:_BatchRemoveItems(shouldRemove, shouldRemoveType)
  local newItems = {}
  local rewardWeight = ItemModelFactory.GetCodeAndWeightPairs(orderConfig.Rewards)
  while #rewardWeight ~= 0 do
    local code = Table.ListWeightSelectOne(rewardWeight).Code
    local position = self:FindEmptyPositionInValidOrder()
    if position == nil then
      self:CacheItems({code}, CacheItemType.Type2)
    else
      local newItem = self:GenerateItem(position, code)
      table.insert(newItems, newItem)
    end
    for index, item in ipairs(rewardWeight) do
      if code == item.Code then
        item.Weight = item.Weight - 1
        if item.Weight == 0 then
          table.remove(rewardWeight, index)
        end
        break
      end
    end
  end
  GM.MapDataModel:SetSlot(orderConfig.EndTimeline, "1")
  self.event:Call(BoardEventType.FinishBranchOrder, {
    Order = order,
    Removed = removedItems,
    New = newItems
  })
end

function MainBoardModel.IsInGeneratorChain(chain, generatorChain)
  if IsString(generatorChain) then
    return chain == generatorChain
  end
  if IsTable(generatorChain) then
    for i = 1, #generatorChain do
      if generatorChain[i] == chain then
        return true
      end
    end
  end
  return false
end

function MainBoardModel:CanCreateSpecialOrder()
  return self.m_orderModels[OrderModelType.Slot]:CanCreateSpecialOrder()
end

function MainBoardModel:CreateSpecialOrder()
  local specialOrder = self.m_orderModels[OrderModelType.Slot]:CreateSpecialOrder()
  if specialOrder ~= nil then
    local config = self:GetSpecialOrderConfig(specialOrder)
    if config.StartReward then
      RewardApi.AcquireRewardsLogic({
        {
          [PROPERTY_TYPE] = config.StartReward,
          [PROPERTY_COUNT] = 1,
          [PROPERTY_CRYPT] = Crypt.CryptCurrency(1)
        }
      }, EPropertySource.Give, EBIType.SpecialTaskBegin, EGameMode.Main, CacheItemType.Type2)
    end
  end
end

function MainBoardModel:IsSpecialOrderFinished(specialOrderId)
  return self.m_orderModels[OrderModelType.Slot]:IsSpecialOrderFinished(specialOrderId)
end

function MainBoardModel:GetSpecialOrderConfigWithOffset(offset)
  return self.m_orderModels[OrderModelType.Slot]:GetSpecialOrderConfigWithOffset(offset)
end

function MainBoardModel:IsBranchOrderFinished(branchType)
  return self.m_orderModels[OrderModelType.Slot]:IsBranchOrderFinished(branchType)
end

function MainBoardModel:GetBranchOrderRequirement(branchType)
  return self.m_orderModels[OrderModelType.Slot]:GetBranchOrderRequirement(branchType)
end

function MainBoardModel:GetBranchTypeByRequirementInChain(itemType)
  local targetChainId = GM.ItemDataModel:GetChainId(itemType)
  for _, config in pairs(self.m_orderModels[OrderModelType.Slot]:GetBranchOrderConfig()) do
    if GM.ItemDataModel:GetChainId(config.Requirement) == targetChainId then
      return config.BranchType
    end
  end
end

function MainBoardModel:GetBranchOrderFinalRewardSlotName(branchType)
  return self.m_orderModels[OrderModelType.Slot]:GetBranchOrderFinalRewardSlotName(branchType)
end

function MainBoardModel:TryAcquireCookingFrenzyReward(order)
  if not order.GetCookingFrenzyConfig then
    return
  end
  local CookingFrenzyCfg = order:GetCookingFrenzyConfig()
  if CookingFrenzyCfg ~= nil then
    local model = GM.ActivityManager:GetModel(ActivityType.CookingFrenzy)
    local rewards = model:AcquireRandomRewards(CookingFrenzyCfg, order)
    if rewards ~= nil then
      local itemRewards = {}
      local otherRewards = {}
      for _, reward in ipairs(rewards) do
        if reward.itemPos ~= nil then
          table.insert(itemRewards, reward)
        else
          table.insert(otherRewards, reward)
        end
      end
      local AddItems = {}
      for _, reward in ipairs(itemRewards) do
        for i = 1, reward[PROPERTY_COUNT] do
          table.insert(AddItems, {
            position = reward.itemPos,
            code = reward[PROPERTY_TYPE]
          })
        end
      end
      self:GenerateItems(AddItems)
      RewardApi.AcquireRewardsLogic(otherRewards, EPropertySource.Give, EBIType.FinishOrder, self.m_gameMode, CacheItemType.Type2)
    end
  end
end

function MainBoardModel:CanItemAffect(specialItem, targetItem)
  return targetItem:CanSpecialTypeAffect(specialItem:GetSpecialType())
end

function MainBoardModel:CanItemSell(item)
  if item:GetSellingPrice() == nil then
    return false
  end
  local itemChainId = GM.ItemDataModel:GetChainId(item:GetType())
  local protectLevel = GM.ItemDataModel:GetChainProtectLevel(itemChainId)
  if protectLevel == nil then
    return true
  end
  local maxUnlockedLevel = 0
  for level, type in ipairs(GM.ItemDataModel:GetChain(itemChainId)) do
    if GM.ItemDataModel:IsUnlocked(type) then
      maxUnlockedLevel = level
    end
  end
  if protectLevel >= maxUnlockedLevel then
    return false
  end
  local itemLevel = GM.ItemDataModel:GetChainLevel(item:GetType())
  return itemLevel ~= maxUnlockedLevel
end

function MainBoardModel:UpdateOpeningItem()
  for item in pairs(self:GetAllBoardItems()) do
    local itemSpread = item and item:GetComponent(ItemSpread)
    if itemSpread ~= nil and itemSpread:GetState() == ItemSpreadState.Opening then
      self.m_bHasOpeningItem = true
      self.event:Call(BoardEventType.UpdateOpeningItem)
      return
    end
  end
  self.m_bHasOpeningItem = false
  self.event:Call(BoardEventType.UpdateOpeningItem)
  return
end

function MainBoardModel:HasOpeningItem()
  return self.m_bHasOpeningItem
end

function MainBoardModel:_BatchRemoveItems(itemFilter, typeFilter)
  local removedItems = {}
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil and itemFilter(item) then
      self:RemoveItem(item)
      table.insert(removedItems, item)
    end
  end
  local i = 1
  while i <= self:GetStoredItemCount() do
    local item = self:GetStoredItem(i)
    if item == nil then
      Log.Assert(false, "item\228\184\141\232\131\189\228\184\186\231\169\186")
    end
    if item ~= nil and itemFilter(item) then
      self.m_itemStoreModel:RemoveItem(i)
      self:_RemoveItemProperty(item)
    else
      i = i + 1
    end
  end
  local i = 1
  while i <= self:GetCachedItemCount() do
    local code = self:GetCachedItem(i)
    if typeFilter(code) then
      self:RemoveCachedItem(i)
    else
      i = i + 1
    end
  end
  EventDispatcher.DispatchEvent(EEventType.ChangeCachedItems)
  EventDispatcher.DispatchEvent(EEventType.InventoryItemUpdate)
  return removedItems
end

function MainBoardModel:RemoveItemsInChainList(arrRemoveChainIds, ignoreEvent)
  local function typeFilter(type)
    return Table.ListContain(arrRemoveChainIds, GM.ItemDataModel:GetChainId(type))
  end
  
  local function itemFilter(item)
    local itemBubble = item:GetComponent(ItemBubble)
    local type = itemBubble == nil and item:GetType() or itemBubble:GetInnerItemCode()
    return typeFilter(type)
  end
  
  local removedItems = self:_BatchRemoveItems(itemFilter, typeFilter)
  if not ignoreEvent then
    self.event:Call(BoardEventType.BatchRemoveItems, {Removed = removedItems})
  end
  return removedItems
end

function MainBoardModel:TransformItems2Score(chainList, getScoreFunc)
  local typeNumberMap = {}
  
  local function recordType(type)
    if typeNumberMap[type] == nil then
      typeNumberMap[type] = 0
    end
    typeNumberMap[type] = typeNumberMap[type] + 1
  end
  
  local function typeFilter(type)
    return Table.ListContain(chainList, GM.ItemDataModel:GetChainId(type))
  end
  
  local removedItems = {}
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil then
      if typeFilter(item:GetType()) then
        self:RemoveItem(item)
        recordType(item:GetType())
        table.insert(removedItems, item)
      else
        local itemBubble = item:GetComponent(ItemBubble)
        if itemBubble ~= nil and typeFilter(itemBubble:GetInnerItemCode()) then
          self:RemoveItem(item)
          table.insert(removedItems, item)
        end
      end
    end
  end
  local i = 1
  while i <= self:GetStoredItemCount() do
    local item = self:GetStoredItem(i)
    if item ~= nil and typeFilter(item:GetType()) then
      self.m_itemStoreModel:RemoveItem(i)
      self:_RemoveItemProperty(item)
      recordType(item:GetType())
    else
      i = i + 1
    end
  end
  i = 1
  while i <= self:GetCachedItemCount() do
    local code = self:GetCachedItem(i)
    if typeFilter(code) then
      self:RemoveCachedItem(i)
      recordType(code)
    else
      i = i + 1
    end
  end
  EventDispatcher.DispatchEvent(EEventType.ChangeCachedItems)
  EventDispatcher.DispatchEvent(EEventType.InventoryItemUpdate)
  self.event:Call(BoardEventType.BatchRemoveItems, {Removed = removedItems})
  local score = 0
  for type, number in pairs(typeNumberMap) do
    score = score + getScoreFunc(type) * number
  end
  return score
end

local TransformScene = {
  MainBoard = 1,
  Cache = 2,
  Inventory = 3
}

function MainBoardModel:TransformItems(typeFilter, isNeedTransformStore)
  local removedItems = {}
  local TransformItems = {}
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil then
      local hit, transformType = typeFilter(item:GetType())
      if hit then
        if transformType then
          local newItem = self:ReplaceItem(item, transformType)
          local message = {
            Source = item,
            New = newItem,
            CostEnergy = false
          }
          self.event:Call(BoardEventType.TransformItem, message)
          EventDispatcher.DispatchEvent(EEventType.ItemTransform, message)
          table.insert(TransformItems, item)
        else
          self:RemoveItem(item)
          table.insert(removedItems, item)
        end
        GM.BIManager:LogAction(EBIType.RecycleItem, {
          s = item:GetCode(),
          r = transformType,
          p = TransformScene.MainBoard
        })
      end
    end
  end
  if 0 < #removedItems then
    self.event:Call(BoardEventType.BatchRemoveItems, {Removed = removedItems})
  end
  local removeStoreItem = {}
  local i = 1
  while i <= self:GetStoredItemCount() do
    local item = self:GetStoredItem(i)
    if typeFilter(item:GetType()) then
      self.m_itemStoreModel:RemoveItem(i)
      self:_RemoveItemProperty(item)
      local transformType
      if isNeedTransformStore then
        local hit, type = typeFilter(item:GetType())
        if hit and type ~= nil then
          transformType = type
        end
      end
      GM.BIManager:LogAction(EBIType.RecycleItem, {
        s = item:GetCode(),
        p = TransformScene.Inventory,
        r = transformType
      })
      table.insert(removeStoreItem, item:GetType())
    else
      i = i + 1
    end
  end
  if isNeedTransformStore then
    for _, item in ipairs(removeStoreItem) do
      local hit, transformType = typeFilter(item)
      if hit and transformType ~= nil then
        local newItem = self:GenerateItem(nil, transformType)
        self.m_itemStoreModel:AddItem(newItem)
      end
    end
  end
  local removeCacheItem = {}
  i = 1
  while i <= self:GetCachedItemCount() do
    local code = self:GetCachedItem(i)
    if typeFilter(code) then
      self:RemoveCachedItem(i)
      GM.BIManager:LogAction(EBIType.RecycleItem, {
        s = code,
        p = TransformScene.Cache
      })
      table.insert(removeCacheItem, code)
    else
      i = i + 1
    end
  end
  EventDispatcher.DispatchEvent(EEventType.ChangeCachedItems)
  EventDispatcher.DispatchEvent(EEventType.InventoryItemUpdate)
  return TransformItems, removeStoreItem, removeCacheItem
end

function MainBoardModel:TransformActivityBubble(chainList)
  local function typeFilter(type)
    return StringUtil.StartWith(GM.ItemDataModel:GetChainId(type), chainList)
  end
  
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil then
      local itemBubble = item:GetComponent(ItemBubble)
      if itemBubble ~= nil and typeFilter(itemBubble:GetInnerItemCode()) then
        itemBubble:ForceTransform()
      end
    end
  end
end

function MainBoardModel:GetItemsOnBoard(onlyGeneratorUnlocked)
  local orderModel = self.m_orderModels[OrderModelType.Slot]
  local itemCodeConfigMap = orderModel:GetItemCodeConfigMap()
  local itemOnBoard = {
    levelMap = {},
    levelList = {},
    codeMap = {}
  }
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil and itemCodeConfigMap[item:GetType()] then
      local code = item:GetType()
      if not onlyGeneratorUnlocked or GM.ItemDataModel:CheckGeneratorUnlockedByItemType(code) then
        local level
        if itemCodeConfigMap[item:GetType()].DifficultyLevel ~= nil then
          level = itemCodeConfigMap[item:GetType()].DifficultyLevel
        else
          level = GM.ItemDataModel:GetChainLevel(code)
        end
        if not itemOnBoard.levelMap[level] then
          itemOnBoard.levelMap[level] = {}
        end
        if not Table.Contain(itemOnBoard.levelMap[level], code) then
          table.insert(itemOnBoard.levelMap[level], code)
        end
        if not Table.Contain(itemOnBoard.levelList, level) then
          table.insert(itemOnBoard.levelList, level)
        end
        itemOnBoard.codeMap[code] = true
      end
    end
  end
  table.sort(itemOnBoard.levelList)
  return itemOnBoard
end

function MainBoardModel:_CheckCobwebItems()
  if not GM.EnergyBoostModel:IsEnergyBoostModeOn() or GM.MiscModel:GetCheckCobwebFinishedInNumber() == 1 then
    return
  end
  local hasCobwebOrPaperbox = false
  local anyCobwebReplaced = false
  for position in self:GetValidPositionIterator() do
    local item = self:GetItem(position)
    if item ~= nil then
      local itemPaperbox = item:GetComponent(ItemPaperBox)
      if itemPaperbox ~= nil then
        hasCobwebOrPaperbox = true
      end
      local itemCobweb = item:GetComponent(ItemCobweb)
      if itemCobweb ~= nil then
        if itemCobweb:GetInnerItemCode() == ItemType.DiveGear01 and GM.ItemDataModel:IsUnlocked(ItemType.PoolStorage06) then
          self:ReplaceItem(item, ItemType.DiveGear01, false)
          anyCobwebReplaced = true
          GM.BIManager:LogAction(EBIType.AutoRemoveCobwebItem, item:GetCode())
        elseif itemCobweb:GetInnerItemCode() == ItemType.Seashell01 and GM.ItemDataModel:IsUnlocked(ItemType.Coral05) then
          self:ReplaceItem(item, ItemType.Seashell01, false)
          anyCobwebReplaced = true
          GM.BIManager:LogAction(EBIType.AutoRemoveCobwebItem, item:GetCode())
        elseif itemCobweb:GetInnerItemCode() == ItemType.SwimmingRing01 and GM.ItemDataModel:IsUnlocked(ItemType.PoolStorage05) then
          self:ReplaceItem(item, ItemType.SwimmingRing01, false)
          anyCobwebReplaced = true
          GM.BIManager:LogAction(EBIType.AutoRemoveCobwebItem, item:GetCode())
        else
          hasCobwebOrPaperbox = true
        end
      end
    end
  end
  if anyCobwebReplaced then
    self:CountItemsCode()
    self:UpdateOrderState()
  end
  if not hasCobwebOrPaperbox then
    GM.MiscModel:SetCheckCobwebFinished(1)
  end
end

function MainBoardModel:InitRefreshrestNumberZeroCD(refreshActivationfunc, canItemSpreadFunc, SpreadFuncStr, eventType, finishFunc, listFuncParams, paramCount)
  listFuncParams = listFuncParams or {}
  paramCount = paramCount or 2
  
  local function func(self, message)
    if not refreshActivationfunc(message) then
      return
    end
    for position in self:GetValidPositionIterator() do
      local item = self:GetItem(position)
      if item ~= nil then
        local itemSpread = item:GetComponent(ItemSpread)
        if itemSpread ~= nil and canItemSpreadFunc(itemSpread) then
          item:DispatchComponentEvent(SpreadFuncStr, table.unpack(listFuncParams, 1, paramCount))
        end
      end
    end
    if finishFunc then
      finishFunc(message)
    end
  end
  
  EventDispatcher.AddListener(eventType, self, func)
end

function MainBoardModel:CacheItems(cachedItemCodes, type, mapCacheItemId)
  BaseActionBoardModel.CacheItems(self, cachedItemCodes, type, mapCacheItemId)
  self:_UpdateCacheItems()
end

function MainBoardModel:CacheItemsFromBoard(items, type)
  BaseActionBoardModel.CacheItemsFromBoard(self, items, type)
  self:_UpdateCacheItems()
end

function MainBoardModel:_PostProcessOnPopCachedItem(code, cachedItemId)
  GM.BIManager:LogAction(EBIType.PopCacheItem, {
    c = tostring(code),
    re = self:GetCachedItemCount(),
    id = cachedItemId
  })
  self:_TryLogBoardFull()
  self:_UpdateCacheItems()
end

function MainBoardModel:_CheckCacheItems()
  local cacheCountStr = GM.MiscModel:GetRecordMainCache()
  if not StringUtil.IsNilOrEmpty(cacheCountStr) and tonumber(cacheCountStr) ~= nil then
    local recordCacheCount = self:_XORCaheItemCount(tonumber(cacheCountStr))
    if recordCacheCount ~= self:GetCachedItemCount() then
      local info = {
        r = recordCacheCount,
        c = self:GetCachedItemCount(),
        de = self.m_itemCacheModel:_GetAllCacheItemsForCheck()
      }
      Log.Info("[CheckCacheItems]" .. json.encode(info))
      GM.BIManager:LogProject(EBIProjectType.CacheItemCheat, info)
    end
  end
end

function MainBoardModel:_UpdateCacheItems()
  local cacheCount = self:GetCachedItemCount()
  GM.MiscModel:SetRecordMainCache(self:_XORCaheItemCount(cacheCount))
end

function MainBoardModel:_XORCaheItemCount(cacheCount)
  return cacheCount ~ 134484248
end

function MainBoardModel:_BIPaperboxExtraItem()
  local count = 0
  for pos in self:GetValidPositionIterator() do
    local reward = self:GetPaperBoxExtraReward(pos)
    if reward ~= nil then
      local itemModel = self:GetItem(pos)
      if itemModel and itemModel:GetType() == ItemType.PaperBox then
        count = count + 1
      end
    end
  end
  GM.BIManager:LogAction(EBIType.PaperBoxExtraItemCount, count)
end

function MainBoardModel:GetPaperBoxRewardConfig()
  return GM.ConfigModel:GetLocalConfig(LocalConfigKey.MainPaperboxExtraRewardConfig)
end
