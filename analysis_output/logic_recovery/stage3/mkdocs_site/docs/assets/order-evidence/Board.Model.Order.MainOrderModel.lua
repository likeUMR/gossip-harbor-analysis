MainOrderModel = setmetatable({}, SlotOrderModel)
MainOrderModel.__index = MainOrderModel
local DBColumnFirstOrder = "FirstOrder"
local DBColumnValue = "value"
local DBLastFinishOrderKey = "lastfinishorder_"
local DBIsLuckyOrderKey = "luckorder_"
local DBIsBaselineOrderKey = "baselineorder_"
local DBTotalDiffScore = "TotalDiffScore"
local DBDiffScoreRefreshTime = "DiffScoreRefreshTime"
local DBUnlockedDiffRange = "UnLockedDiffRange_"
local DBRepeatWeightDecreaseChain = "RepeatWeightDecreaseChain"

function MainOrderModel.Create(dbMetaTable, dbTable, boardModel)
  local mainOrderModel = setmetatable({}, MainOrderModel)
  mainOrderModel:Init(dbMetaTable, dbTable, boardModel)
  return mainOrderModel
end

function MainOrderModel:Init(dbMetaTable, dbTable, boardModel)
  SlotOrderModel.Init(self, boardModel, MainOrderSlotDefinition.SlotCount)
  self.m_dbMetaTable = dbMetaTable
  self.m_dbTable = dbTable
  self.m_idGenerator = DBIdGenerator.Create()
  self.m_tutorialOrderModel = TutorialOrderModel.Create(self, dbMetaTable)
  EventDispatcher.AddListener(EEventType.LevelUp, self, self._TryFillOrders)
  EventDispatcher.AddListener(EEventType.OrderBoostFillOrder, self, self._TryFillOrders)
  EventDispatcher.AddListener(EEventType.ForceTryFillOrders, self, self._TryFillOrders)
  EventDispatcher.AddListener(EEventType.BranchStart, self, self._TryCreateBranchOrders)
end

function MainOrderModel:LoadFileConfig()
  self.m_fixedOrderConfig = {}
  local fixedOrderConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderFixed)
  for _, fixedOrderConfig in ipairs(fixedOrderConfigs) do
    self.m_fixedOrderConfig[fixedOrderConfig.Id] = fixedOrderConfig
  end
  self.m_randomOrderConfig = {}
  local randomOrderConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderRandom)
  for _, randomOrderConfig in ipairs(randomOrderConfigs) do
    if randomOrderConfig.IsLucky == 1 then
      self.m_luckyOrderConfig = randomOrderConfig
    else
      self.m_randomOrderConfig[randomOrderConfig.Type] = randomOrderConfig
    end
  end
  self.m_randomOrderRecallConfig = {}
  local randomOrderRecallConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderRandomReCall)
  for _, randomOrderConfig in ipairs(randomOrderRecallConfigs) do
    self.m_randomOrderRecallConfig[randomOrderConfig.Type] = randomOrderConfig
  end
  self.m_specialOrderConfig = {}
  local specialOrderConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderSpecial)
  for _, specialOrderConfig in ipairs(specialOrderConfigs) do
    specialOrderConfig.Rewards = ConfigUtil.GetCurrencyFromArrStr(specialOrderConfig.Rewards)
    self.m_specialOrderConfig[specialOrderConfig.Id] = specialOrderConfig
  end
  self.m_branchOrderConfig = {}
  local branchOrderConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderBranch)
  for _, config in ipairs(branchOrderConfigs) do
    self.m_branchOrderConfig[config.Slot] = config
  end
  self.m_itemNumberWeightConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderItemNumberWeight)
  table.sort(self.m_itemNumberWeightConfig, function(config1, config2)
    return config1.Level < config2.Level
  end)
  self.m_itemCodeConfigMap = {}
  local itemConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderItem)
  for _, itemConfig in ipairs(itemConfigs) do
    self.m_itemCodeConfigMap[itemConfig.Code] = itemConfig
  end
  self.m_avatarConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.OrderAvatar)
  self.m_normalAvatarConfigs = {}
  for _, normalAvatarConfig in ipairs(self.m_avatarConfig.NormalAvatars) do
    self.m_normalAvatarConfigs[normalAvatarConfig.Id] = normalAvatarConfig
  end
  self.m_chestRandomOrderConfig = {}
  local chestRandomConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.ChestOrderRandomConfig)
  for _, randomOrderConfig in ipairs(chestRandomConfigs) do
    self.m_chestRandomOrderConfig[randomOrderConfig.Type] = randomOrderConfig
  end
  self.m_chestRandomOrderRecallConfig = {}
  local chestRandomRecallConfigs = GM.ConfigModel:GetLocalConfig(LocalConfigKey.ChestOrderRandomRecallConfig)
  for _, randomOrderConfig in ipairs(chestRandomRecallConfigs) do
    self.m_chestRandomOrderRecallConfig[randomOrderConfig.Type] = randomOrderConfig
  end
  self:SafeCheckConfig()
end

function MainOrderModel:SafeCheckConfig()
  if not GameConfig.IsTestMode() then
    return false
  end
  local mapCheckAvatarId = {}
  for _, config in pairs(self.m_avatarConfig) do
    for avatarId, eleConfig in pairs(config) do
      if eleConfig.Id ~= nil then
        if mapCheckAvatarId[eleConfig.Id] then
          Log.Error("\233\148\153\232\175\175\231\154\132\233\135\141\229\164\141AvatarId" .. tostring(eleConfig.Id))
        else
          mapCheckAvatarId[eleConfig.Id] = true
        end
      elseif mapCheckAvatarId[avatarId] then
        Log.Error("\233\148\153\232\175\175\231\154\132\233\135\141\229\164\141AvatarId" .. tostring(avatarId))
      else
        mapCheckAvatarId[avatarId] = true
      end
    end
  end
end

function MainOrderModel:OnSyncDataFinished()
  SlotOrderModel.OnSyncDataFinished(self)
  self.m_tutorialOrderModel:OnSyncDataFinished()
  self.m_lastFinishOrder = self:_DBGetLastFinishOrder()
  self:_RemoveErrorOrder()
  self.m_mapRepeatWeightDecreaseInfo = self:_DBGetRepeatWeightDecreaseInfo()
end

function MainOrderModel:LateInit()
  EventDispatcher.AddListener(EEventType.EnterMainScene, self, self._OnEnterMainScene)
  EventDispatcher.AddListener(EEventType.BakeOutStateChanged, self, self._UpdateBakeOutOrderStatus)
  EventDispatcher.AddListener(EEventType.BakeOutModeChanged, self, self._UpdateBakeOutOrderStatus)
  EventDispatcher.AddListener(EEventType.CharacterIntimacyStateChanged, self, self._UpdateMainOrderStatus)
  for _, definition in pairs(DashActivityDefinition) do
    if definition.UpdateMainOrderStatus then
      EventDispatcher.AddListener(definition.StateChangedEvent, self, self._UpdateMainOrderStatus)
      EventDispatcher.AddListener(definition.UpgradedEvent, self, self._UpdateMainOrderStatus)
    end
  end
  for _, activityDefinition in pairs(MainDecorActivityDefinition) do
    EventDispatcher.AddListener(activityDefinition.StateChangedEvent, self, self._UpdateMainOrderStatus)
  end
  for _, activityDefinition in pairs(MainDecorNewActivityDefinition) do
    EventDispatcher.AddListener(activityDefinition.StateChangedEvent, self, self._UpdateMainOrderStatus)
  end
  self:_UpdateMainOrderStatus()
  EventDispatcher.AddListener(EEventType.BuffPropertyConsume, self, self._OnBuffPropertyChanged)
  EventDispatcher.AddListener(EEventType.BuffPropertyOutTime, self, self._OnBuffPropertyChanged)
  self:_CheckSpecialOrder()
  self:TryRefreshTotalDiffScore()
  self.m_tutorialOrderModel:LateInit()
  SlotOrderModel.LateInit(self)
  if self.m_cacheAlbumRemoveSlot then
    local albumModel = GM.ActivityManager:GetStartedAlbumActivity()
    if albumModel then
      albumModel:RemoveOrderReward(self.m_cacheAlbumRemoveSlot)
    end
  end
end

function MainOrderModel:_RemoveErrorOrder()
  local orders = self:GetOrders()
  if Table.IsEmpty(orders) then
    return
  end
  Log.Assert(not Table.IsEmpty(self.m_itemCodeConfigMap), "m_itemCodeConfigMap is nil")
  local itemDataModel = GM.ItemDataModel
  for slot, order in pairs(orders) do
    if self:OrderAvatarIsEmpty(order) then
      self:_RemoveErrorOrderData(slot)
      GM.BIManager:LogAction(EBIType.ErrorOrderRemove, "Name nil slot: " .. tostring(slot))
    elseif slot ~= MainOrderSlotDefinition.SpecialSlot then
      for _, requirement in ipairs(order:GetRequirements()) do
        local itemConfig = itemDataModel:GetModelConfig(requirement, true)
        if Table.IsEmpty(itemConfig) or Table.IsEmpty(self.m_itemCodeConfigMap[requirement]) then
          self:_RemoveErrorOrderData(slot)
          GM.BIManager:LogAction(EBIType.ErrorOrderRemove, "req nil item:" .. (requirement or "nil") .. " slot: " .. tostring(slot))
          break
        end
      end
    end
  end
end

function MainOrderModel:OrderAvatarIsEmpty(order)
  if order:GetSlot() == MainOrderSlotDefinition.ContiorderSlot then
    return false
  else
    return order:GetAvatarName() == nil
  end
end

function MainOrderModel:_CheckSpecialOrder()
  local mapChainId2SpecialId = {}
  local maxId = 0
  for id, config in pairs(self.m_specialOrderConfig) do
    local chainIds = config.GeneratorChain
    if type(chainIds) == "string" then
      mapChainId2SpecialId[chainIds] = id
    else
      for _, chainId in ipairs(chainIds) do
        mapChainId2SpecialId[chainId] = id
      end
    end
    maxId = math.max(maxId, id)
  end
  local itemDataModel = GM.ItemDataModel
  local currentSpecialId = 0
  local codeCountMap = self.m_boardModel:GetCodeCountMap(true, true, true)
  for type, _ in pairs(codeCountMap) do
    if itemDataModel:GetModelConfig(type, true) ~= nil then
      local chainId = itemDataModel:GetChainId(type)
      if not StringUtil.IsNilOrEmpty(chainId) and mapChainId2SpecialId[chainId] then
        if currentSpecialId == 0 then
          currentSpecialId = mapChainId2SpecialId[chainId]
        else
          currentSpecialId = math.min(currentSpecialId, mapChainId2SpecialId[chainId])
        end
      end
    end
  end
  if currentSpecialId == 0 then
    return
  end
  local RecordCurrentConfig, RecordCurrentSpecialId = MainOrderCreatorSpecial.GetConfig(self, 0)
  if currentSpecialId == RecordCurrentSpecialId then
    if currentSpecialId ~= 0 and currentSpecialId ~= maxId + 1 and self.m_orders[MainOrderSlotDefinition.SpecialSlot] == nil then
      MainOrderCreatorSpecial.ResetCurrentSpecialOrderId(self, currentSpecialId - 1)
      if MainOrderCreatorSpecial.CanCreate(self) then
        self:CreateSpecialOrder()
      end
    end
    return
  elseif currentSpecialId == 1 and RecordCurrentSpecialId == 0 then
    return
  end
  if self.m_orders[MainOrderSlotDefinition.SpecialSlot] ~= nil then
    self:RemoveOrder(MainOrderSlotDefinition.SpecialSlot)
  end
  MainOrderCreatorSpecial.ResetCurrentSpecialOrderId(self, currentSpecialId - 1)
  if self:CanCreateSpecialOrder() then
    self:CreateSpecialOrder()
  end
  GM.BIManager:LogAction(EBIType.SpeicalTaskRecover, {before = RecordCurrentSpecialId, after = currentSpecialId})
  local arrRemoveChainIds = {}
  for id, config in pairs(self.m_specialOrderConfig) do
    if 3 <= id and id > currentSpecialId then
      local chainIds = config.GeneratorChain
      if type(chainIds) == "string" then
        arrRemoveChainIds[#arrRemoveChainIds + 1] = chainIds
      else
        for _, chainId in ipairs(chainIds) do
          arrRemoveChainIds[#arrRemoveChainIds + 1] = chainId
        end
      end
      for i = 1, 3 do
        local requirement = config["Requirement" .. i]
        if requirement ~= nil then
          arrRemoveChainIds[#arrRemoveChainIds + 1] = GM.ItemDataModel:GetChainId(requirement)
        end
      end
    end
  end
  self.m_boardModel:RemoveItemsInChainList(arrRemoveChainIds, true)
  GM.ShopModel:RefreshFlashSaleAfterSpecialOrderRecovered()
end

function MainOrderModel:UpdatePerSecond()
  self:TryRefreshTotalDiffScore()
  if self.m_orders ~= nil then
    self:_TryFillOrders()
  end
end

function MainOrderModel:TryRefreshTotalDiffScore()
  if self.m_dbMetaTable ~= nil and self.m_orders ~= nil then
    local localeTime = GM.GameModel:GetLocaleTime()
    local refreshTime = tonumber(self.m_dbMetaTable:GetValue(DBDiffScoreRefreshTime, DBColumnValue)) or 0
    if localeTime >= refreshTime then
      self.m_dbMetaTable:Set(DBTotalDiffScore, DBColumnValue, tostring(0))
      if GameConfig.IsTestMode() then
        Log.Info("\232\174\162\229\141\149\233\154\190\229\186\166\229\136\134\229\136\183\230\150\176: " .. self.m_dbMetaTable:GetValue(DBTotalDiffScore, DBColumnValue))
      end
      refreshTime = TimeUtil.ToNext2AMClockTimestamp(localeTime)
      self.m_dbMetaTable:Set(DBDiffScoreRefreshTime, DBColumnValue, tostring(refreshTime))
    end
  end
end

function MainOrderModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function MainOrderModel:_DBGetOrders()
  local orders = {}
  local orderData = self.m_dbTable:GetReadOnlyValues()
  for slot, data in pairs(orderData) do
    local bIsLucky = false
    if self.m_dbMetaTable:GetValue(DBIsLuckyOrderKey .. tostring(slot), DBColumnValue) == "1" then
      bIsLucky = true
    end
    local bIsBaseline = false
    if self.m_dbMetaTable:GetValue(DBIsBaselineOrderKey .. tostring(slot), DBColumnValue) == "1" then
      bIsBaseline = true
    end
    local requirements = {
      data.requirement1Str,
      data.requirement2Str,
      data.requirement3Str
    }
    local diffRange = self.m_dbMetaTable:GetValue(DBUnlockedDiffRange .. tostring(slot), DBColumnValue)
    if diffRange == "" then
      diffRange = nil
    end
    local order = self:_CreateOrder(slot, data.id, requirements, data.type, data.avatarId, bIsLucky, bIsBaseline, diffRange)
    GM.CharacterIntimacyModel:SetGiftRewardInfo(order)
    orders[slot] = order
  end
  return orders
end

function MainOrderModel:_CreateOrder(slot, id, requirements, innerType, avatarId, bIsLucky, bIsBaseline, diffRange)
  if innerType == MainOrderType.TimedOrder and TimedOrderOrder ~= nil then
    return TimedOrderOrder.Create(self, slot, id, requirements, innerType, avatarId, bIsLucky, bIsBaseline)
  elseif innerType == MainOrderType.ExtraCustomer and EmptyReqOrder ~= nil then
    return EmptyReqOrder.Create(self, slot, id, requirements, innerType, avatarId, bIsLucky, bIsBaseline, diffRange)
  else
    return MainOrder.Create(self, slot, id, requirements, innerType, avatarId, bIsLucky, bIsBaseline, diffRange)
  end
end

function MainOrderModel:_DBGetLastFinishOrder()
  local oLastFinishOrder = {}
  local lastOrderData = self.m_dbMetaTable:GetReadOnlyValues()
  for strKey, data in pairs(lastOrderData) do
    if StringUtil.StartWith(strKey, DBLastFinishOrderKey) then
      local slot = tonumber(string.sub(strKey, #DBLastFinishOrderKey + 1))
      local aData = StringUtil.Split(data[DBColumnValue], "@")
      local oOrderInfo = {}
      oOrderInfo.innerType = aData[1]
      oOrderInfo.avatrId = aData[2]
      oOrderInfo.id = aData[3]
      oOrderInfo.requirements = StringUtil.Split(aData[4], ";")
      oLastFinishOrder[slot] = self:_CreateOrder(slot, oOrderInfo.id, oOrderInfo.requirements, oOrderInfo.innerType, oOrderInfo.avatrId)
    end
  end
  return oLastFinishOrder
end

function MainOrderModel:_DBGetRepeatWeightDecreaseInfo()
  local oRepeatWeightDecreaseInfo = {}
  local strSaveRepeatInfo = self.m_dbMetaTable:GetValue(DBRepeatWeightDecreaseChain, DBColumnValue) or ""
  local strMetaData = string.gsub(strSaveRepeatInfo, "@", ",")
  oRepeatWeightDecreaseInfo = json.decode(strMetaData) or {}
  return oRepeatWeightDecreaseInfo
end

function MainOrderModel:SaveRepeatWeightDecreaseInfo()
  if Table.IsEmpty(self.m_mapRepeatWeightDecreaseInfo) then
    self.m_dbMetaTable:Remove(DBRepeatWeightDecreaseChain)
    return
  end
  local strSaveInfo = json.encode(self.m_mapRepeatWeightDecreaseInfo)
  strSaveInfo = string.gsub(strSaveInfo, ",", "@")
  self.m_dbMetaTable:Set(DBRepeatWeightDecreaseChain, DBColumnValue, strSaveInfo)
end

function MainOrderModel:_DBAddOrder(order)
  local addData = {
    [order:GetSlot()] = {
      type = order:GetInnerType(),
      requirement1Str = order:GetRequirements()[1],
      requirement2Str = order:GetRequirements()[2],
      requirement3Str = order:GetRequirements()[3],
      avatarId = order:GetAvatarId(),
      id = order:GetId()
    }
  }
  self.m_dbTable:BatchSet(addData)
  GM.CharacterIntimacyModel:SaveGiftRewardInfo(order)
  if order:IsLuckyOrder() then
    local strKey = DBIsLuckyOrderKey .. tostring(order:GetSlot())
    self.m_dbMetaTable:Set(strKey, DBColumnValue, "1")
  end
  if order:IsBaselineOrder() then
    local strKey = DBIsBaselineOrderKey .. tostring(order:GetSlot())
    self.m_dbMetaTable:Set(strKey, DBColumnValue, "1")
  end
  if order:GetDiffRange() then
    local strKey = DBUnlockedDiffRange .. tostring(order:GetSlot())
    self.m_dbMetaTable:Set(strKey, DBColumnValue, order:GetDiffRange())
  end
end

function MainOrderModel:_RemoveOrder(slot)
  local albumModel = GM.ActivityManager:GetStartedAlbumActivity(false)
  if albumModel then
    albumModel:RemoveOrderReward(slot)
  else
    self.m_cacheAlbumRemoveSlot = slot
  end
  self:_DBRemoveOrder(slot)
end

function MainOrderModel:_DBRemoveOrder(slot)
  self.m_dbTable:Remove(slot)
  GM.CharacterIntimacyModel:RemoveGiftRewardInfo(slot)
  self.m_lastFinishOrder[slot] = nil
  if self.m_orders[slot] ~= nil then
    local order = self.m_orders[slot]
    local aAddData = {}
    aAddData[1] = order:GetInnerType()
    aAddData[2] = order:GetAvatarId() and order:GetAvatarId() or ""
    aAddData[3] = order:GetId() and order:GetId() or ""
    aAddData[4] = table.concat(order:GetRequirements(), ";")
    local strData = table.concat(aAddData, "@")
    local strKey = DBLastFinishOrderKey .. tostring(slot)
    self.m_dbMetaTable:Set(strKey, DBColumnValue, strData)
    self.m_lastFinishOrder[slot] = self.m_orders[slot]
  end
  local strLuckyKey = DBIsLuckyOrderKey .. tostring(slot)
  if self.m_dbMetaTable:GetValue(strLuckyKey, DBColumnValue) then
    self.m_dbMetaTable:Remove(strLuckyKey)
  end
  local strBaselineKey = DBIsBaselineOrderKey .. tostring(slot)
  if self.m_dbMetaTable:GetValue(strBaselineKey, DBColumnValue) then
    self.m_dbMetaTable:Remove(strBaselineKey)
  end
  local strDiffRangeKey = DBUnlockedDiffRange .. tostring(slot)
  if self.m_dbMetaTable:GetValue(strDiffRangeKey, DBColumnValue) then
    self.m_dbMetaTable:Remove(strDiffRangeKey)
  end
  local chestCustomModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  if chestCustomModel ~= nil then
    chestCustomModel:ChestOrderFinish(slot)
  end
end

function MainOrderModel:_DBRemoveCDTimer(slot)
  local dbColumnStartTimer = MainOrderDBColumnRandomStartTimer[slot]
  if not dbColumnStartTimer then
    return
  end
  local metaData = self:GetMetaData()
  local startTimer = metaData:GetValue(dbColumnStartTimer, "value")
  if startTimer ~= nil then
    metaData:Remove(dbColumnStartTimer, "value")
  end
end

function MainOrderModel:_DBUpdateOrder(slot, key, value)
  self.m_dbTable:Set(slot, key, value)
end

function MainOrderModel:CustomerUpgradeTryFillChestCustomerOrders()
  local chestCustomerModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  local slots = chestCustomerModel:GetChestCustomerOrderSlots()
  if Table.IsEmpty(slots) then
    return
  end
  local customConfigs = chestCustomerModel:GetCustomConfigs()
  local innerTypeList = {}
  for _, config in ipairs(customConfigs) do
    innerTypeList[config.orderType] = true
  end
  local hasFilledOrder = false
  local hasFilledOrderOnce = false
  local arrNewOrders = {}
  local arrChangedOrders = {}
  local filledSlots = {}
  local randomCreator = require("Board.Model.Order.MainOrderCreatorRandom")
  repeat
    hasFilledOrderOnce = false
    for _, slot in ipairs(slots) do
      local order = self.m_orders[slot]
      if order == nil or order:GetState() == OrderState.Finished then
        if order ~= nil then
          self:_RemoveOrder(slot)
          self.m_orders[slot] = nil
        end
        local newOrder = randomCreator(self, slot)
        if newOrder ~= nil then
          hasFilledOrder = true
          hasFilledOrderOnce = true
          if newOrder:GetId() == nil and newOrder:GetType() == OrderType.Random then
            newOrder:UpdateId(tonumber(self.m_idGenerator:Generate()))
          end
          self:_DBAddOrder(newOrder)
          self.m_orders[slot] = newOrder
          table.insert(arrNewOrders, newOrder)
          filledSlots[slot] = true
        end
      end
    end
  until not hasFilledOrderOnce
  for _, slot in ipairs(slots) do
    if not chestCustomerModel:IsChestCustomerOrder(slot) then
      local order = self.m_orders[slot]
      if order ~= nil then
        local innerType = order:GetInnerType()
        if innerTypeList[innerType] then
          local newAvatarId = chestCustomerModel:ReplaceOrderWithChestCustomerOrder(innerType, slot)
          self:_DBUpdateOrder(slot, "avatarId", newAvatarId)
          order:UpdateAvatarId(newAvatarId)
          table.insert(arrChangedOrders, order)
          filledSlots[slot] = true
        end
      end
    end
  end
  local newId, changedId, existId = {}, {}, {}
  for _, order in ipairs(arrNewOrders) do
    table.insert(newId, order:GetId())
  end
  for _, order in ipairs(arrChangedOrders) do
    table.insert(changedId, order:GetId())
  end
  for _, slot in ipairs(slots) do
    if not filledSlots[slot] and self.m_orders[slot] ~= nil then
      table.insert(existId, self.m_orders[slot]:GetId())
    end
  end
  GM.BIManager:LogAction(EBIType.CustomerUpgradeRewardActive, {
    newId = 0 < #newId and newId or nil,
    changedId = 0 < #changedId and changedId or nil,
    existId = 0 < #existId and existId or nil
  })
  GM.CustomerUpgradeRewardModel:FinishFillChestCustomerOrder()
  if hasFilledOrder then
    for _, order in ipairs(arrNewOrders) do
      self:_LogOrderAction(order, "unlock")
    end
  end
  self.m_boardModel:CustomerUpgradeActive()
end

function MainOrderModel:_TryCreateOrder(slot)
  local newOrder = MainOrderCreatorFixed.Create(self, slot)
  if newOrder == nil and MainOrderCreatorReturnFreeOrder.CanCreate(self, slot) then
    newOrder = MainOrderCreatorReturnFreeOrder.Create(self, slot)
  end
  if newOrder == nil and self.m_tutorialOrderModel:CanCreate(slot) then
    newOrder = self.m_tutorialOrderModel:CreateOrder(slot)
  end
  local contiModel = GM.ActivityManager:GetStartedContiorders()
  if newOrder == nil and contiModel and contiModel:CanCreateOrder(slot) then
    newOrder = contiModel:CreateOrder(self, slot)
  end
  local extraCustomerModel = GM.ActivityManager:GetModel(ActivityType.ExtraCustomer)
  if newOrder == nil and extraCustomerModel and extraCustomerModel:CanCreateOrder(slot) then
    newOrder = extraCustomerModel:CreateOrder(self, slot)
  end
  if newOrder == nil and MainOrderCreatorLuckyOrder.CanCreate(self, slot) then
    newOrder = MainOrderCreatorLuckyOrder.Create(self, slot)
  end
  if newOrder == nil then
    local randomCreator = require("Board.Model.Order.MainOrderCreatorRandom")
    newOrder = randomCreator(self, slot)
  end
  if newOrder ~= nil then
    if newOrder:GetId() == nil and newOrder:GetType() == OrderType.Random then
      newOrder:UpdateId(tonumber(self.m_idGenerator:Generate()))
    end
    self:_AddGiftRewardInfo(newOrder)
    EventDispatcher.DispatchEvent(EEventType.MainOrderCreated, newOrder)
  end
  return newOrder
end

function MainOrderModel:FinishOrder(order)
  if order:GetInnerType() == MainOrderType.Branch then
    self:_SetBranchOrderFinished(order)
  end
  GM.CharacterIntimacyModel:OnMainOrderFinished()
  self.m_canTriggerLucky = false
  if order:IsLuckyOrder() then
    self.m_canTriggerLucky = true
    if GameConfig.IsTestMode() then
      Log.Info("\229\176\157\232\175\149\232\191\158\231\187\173\232\167\166\229\143\145\230\131\138\229\150\156\232\174\162\229\141\149")
    end
  else
    local randomConfig = self:GetRandomOrderConfigBySlot(order:GetSlot())[order:GetInnerType()]
    if randomConfig ~= nil and randomConfig.LuckyTriggerChance ~= nil then
      local randomNum = MathUtil.Random()
      if randomNum <= randomConfig.LuckyTriggerChance then
        self.m_canTriggerLucky = true
      end
      if GameConfig.IsTestMode() then
        Log.Info("Type" .. randomConfig.Type .. "\229\176\157\232\175\149\230\166\130\231\142\135\232\167\166\229\143\145\230\131\138\229\150\156\232\174\162\229\141\149\n" .. "\232\167\166\229\143\145\230\166\130\231\142\135\239\188\154" .. randomConfig.LuckyTriggerChance .. "\n\233\154\143\230\156\186\230\149\176\239\188\154" .. randomNum)
      end
    elseif GameConfig.IsTestMode() then
      Log.Info("\230\178\161\233\133\141LuckyTriggerChance\239\188\140\228\184\141\232\167\166\229\143\145\230\131\138\229\150\156\232\174\162\229\141\149")
    end
  end
  if NormalOrderSlot[order:GetSlot()] == true then
    local diffScore = order:GetDiffScore()
    local totalDiffScore = self:GetTotalDiffScore()
    totalDiffScore = totalDiffScore + diffScore
    self.m_dbMetaTable:Set(DBTotalDiffScore, DBColumnValue, tostring(totalDiffScore))
    if GameConfig.IsTestMode() then
      Log.Info("\232\175\165\232\174\162\229\141\149\233\154\190\229\186\166\229\136\134\230\149\176\239\188\154" .. diffScore .. "; \230\128\187\233\154\190\229\186\166\229\136\134\230\149\176\239\188\154" .. totalDiffScore)
    end
  end
  local itemModelConfig = self:GetItemCodeConfigMap()
  local requirements = order:GetRequirements()
  for _, itemCode in ipairs(requirements) do
    if itemModelConfig[itemCode] ~= nil and itemModelConfig[itemCode].RepeatWeightDecrease ~= nil and itemModelConfig[itemCode].RepeatWeightDecrease > 0 then
      local chainId = GM.ItemDataModel:GetChainId(itemCode)
      self:ResetRepeatWeightDecreaseByChainId(chainId)
    end
  end
  return SlotOrderModel.FinishOrder(self, order)
end

function MainOrderModel:GetRepeatWeightDecrease()
  return self.m_mapRepeatWeightDecreaseInfo
end

function MainOrderModel:ReduceRepeatWeightDecreaseByChainId(chainId, noSave)
  local count = self.m_mapRepeatWeightDecreaseInfo[chainId] or 0
  if 0 < count then
    self.m_mapRepeatWeightDecreaseInfo[chainId] = count - 1
    if self.m_mapRepeatWeightDecreaseInfo[chainId] == 0 then
      self.m_mapRepeatWeightDecreaseInfo[chainId] = nil
    end
    if not noSave then
      self:SaveRepeatWeightDecreaseInfo()
    end
  end
end

function MainOrderModel:ResetRepeatWeightDecreaseByChainId(chainId, noSave)
  self.m_mapRepeatWeightDecreaseInfo[chainId] = 3
  if not noSave then
    self:SaveRepeatWeightDecreaseInfo()
  end
end

function MainOrderModel:UpdateRepeatWeightDecrease(mapChainInfo)
  for chainId, bFlag in pairs(mapChainInfo) do
    if bFlag then
      self:ReduceRepeatWeightDecreaseByChainId(chainId, true)
    else
      self:ResetRepeatWeightDecreaseByChainId(chainId, true)
    end
  end
  self:SaveRepeatWeightDecreaseInfo()
end

function MainOrderModel:GetTotalDiffScore()
  return tonumber(self.m_dbMetaTable:GetValue(DBTotalDiffScore, DBColumnValue)) or 0
end

function MainOrderModel:RemoveOrder(slot)
  local order = self.m_orders[slot]
  if not order then
    return false
  end
  order:SetFinished()
  self:_RemoveOrder(slot)
  self:_DBRemoveCDTimer(slot)
  self.m_orders[slot] = nil
  self.m_boardModel:UpdateOrderState()
  self.m_boardModel.event:Call(BoardEventType.RemoverOrderImmediate, {Order = order})
end

function MainOrderModel:_RemoveErrorOrderData(slot)
  local order = self.m_orders[slot]
  if not order then
    return false
  end
  self:_RemoveOrder(slot)
  self:_DBRemoveCDTimer(slot)
  self.m_orders[slot] = nil
  self.m_boardModel:UpdateOrderState()
  self.m_boardModel.event:Call(BoardEventType.RemoverOrderImmediate, {Order = order})
end

function MainOrderModel:GetAvatarId()
  if StringUtil.IsNilOrEmpty(self.m_dbMetaTable:GetValue(DBColumnFirstOrder, "value")) then
    self.m_dbMetaTable:Set(DBColumnFirstOrder, "value", "1")
    return MainOrderDefinition.FirstOrderAvatarId
  end
  local level = GM.LevelModel:GetCurrentLevel()
  local avatarIds = {}
  local bakeOutModel = GM.ActivityManager:GetModel(ActivityType.BakeOut)
  local bakeOutOn = bakeOutModel ~= nil and bakeOutModel:CanAcquireToken()
  if bakeOutOn then
    for id, _ in pairs(self.m_avatarConfig.BakeOutAvatars) do
      local found = false
      for _, order in pairs(self.m_orders) do
        if order:GetAvatarId() == id then
          found = true
          break
        end
      end
      if not found then
        table.insert(avatarIds, id)
      end
    end
  end
  local tempAvatarIds = {}
  if not bakeOutOn or #avatarIds == 0 then
    for i = 1, #self.m_avatarConfig.NormalAvatars do
      local unlockLevel = self.m_avatarConfig.NormalAvatars[i].UnlockLevel
      local avatarId = self.m_avatarConfig.NormalAvatars[i].Id
      if unlockLevel == nil or level >= unlockLevel then
        table.insert(tempAvatarIds, avatarId)
        local found = false
        for _, order in pairs(self.m_orders) do
          if order:GetAvatarId() == avatarId then
            found = true
            break
          end
        end
        if not found then
          table.insert(avatarIds, avatarId)
        end
      end
    end
  end
  if #avatarIds == 0 and 0 < #tempAvatarIds then
    return Table.ListRandomSelectOne(tempAvatarIds)
  elseif #avatarIds == 0 and #tempAvatarIds == 0 then
    return MainOrderDefinition.FirstOrderAvatarId
  end
  return Table.ListRandomSelectOne(avatarIds)
end

function MainOrderModel:UpdateRequirements(slot, requirements)
  if not self.m_orders[slot] then
    return false
  end
  if Table.IsEmpty(requirements) then
    return false
  end
  if Table.GetMapSize(requirements) ~= #requirements then
    return false
  end
  self.m_orders[slot]:UpdateRequirements(requirements)
  for i = 1, 3 do
    if requirements[i] then
      self:_DBUpdateOrder(slot, "requirement" .. i .. "Str", requirements[i])
    else
      self:_DBUpdateOrder(slot, "requirement" .. i .. "Str", "")
    end
  end
  self.m_boardModel:UpdateOrderState()
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  if GameConfig.IsTestMode() then
    Log.Info("[ReturnUser] or [EmptyReqOrder] UpdateRequirements slot: " .. slot .. ", requirements: " .. json.encode(requirements))
  end
end

function MainOrderModel:_OnEnterMainScene()
  self.m_bResourceChecked = true
  self:_UpdateBakeOutOrderStatus()
end

function MainOrderModel:_UpdateBakeOutOrderStatus()
  if self.m_bResourceChecked then
    local bakeoutModel = GM.ActivityManager:GetModel(ActivityType.BakeOut)
    if not bakeoutModel:CanAcquireToken() then
      local orderData = self.m_dbTable:GetReadOnlyValues()
      for slot, data in pairs(orderData) do
        if self.m_avatarConfig.BakeOutAvatars[data.avatarId] ~= nil then
          local newAvatarId = self:GetAvatarId()
          self:_DBUpdateOrder(slot, "avatarId", newAvatarId)
          if self.m_orders ~= nil and self.m_orders[slot] ~= nil then
            self.m_orders[slot]:UpdateAvatarId(newAvatarId)
          end
        end
      end
    end
  end
  self:_UpdateMainOrderStatus()
end

function MainOrderModel:_UpdateMainOrderStatus(message)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function MainOrderModel:_OnBuffPropertyChanged(message)
  self:_UpdateMainOrderStatus(message)
end

function MainOrderModel:GetCodeCountMap()
  return self.m_boardModel:GetCodeCountMap(true, false, true)
end

function MainOrderModel:CheckItemCodeProgressUnlock(itemCode)
  if self.m_itemCodeConfigMap[itemCode] == nil then
    return false
  end
  if self.m_itemCodeConfigMap[itemCode].ProgressUnlock ~= 1 then
    return true
  end
  local itemDataModel = GM.ItemDataModel
  local chainLevel = itemDataModel:GetChainLevel(itemCode)
  return 1 < chainLevel and itemDataModel:IsUnlocked(itemDataModel:GetChain(itemDataModel:GetChainId(itemCode))[chainLevel - 1])
end

function MainOrderModel:CanCreateSpecialOrder()
  if self.m_orders[MainOrderSlotDefinition.SpecialSlot] ~= nil then
    return false
  end
  return MainOrderCreatorSpecial.CanCreate(self)
end

function MainOrderModel:CreateSpecialOrder()
  local newOrder = MainOrderCreatorSpecial.Create(self, MainOrderSlotDefinition.SpecialSlot)
  self:_DBAddOrder(newOrder)
  self.m_orders[MainOrderSlotDefinition.SpecialSlot] = newOrder
  self:_LogOrderAction(newOrder, "unlock")
  self.m_boardModel:UpdateOrderState()
  EventDispatcher.DispatchEvent(EEventType.MainOrderCreated, newOrder)
  return newOrder
end

function MainOrderModel:GetSpecialOrderConfigWithOffset(offset)
  return MainOrderCreatorSpecial.GetConfig(self, offset)
end

function MainOrderModel:IsSpecialOrderFinished(specialOrderId)
  if not MainOrderCreatorSpecial.IsCreated(self, specialOrderId) then
    return false
  end
  local specialOrder = self.m_orders[MainOrderSlotDefinition.SpecialSlot]
  return specialOrder == nil or specialOrder:GetId() ~= specialOrderId
end

function MainOrderModel:_TryCreateBranchOrders()
  local slot = MainOrderSlotDefinition.BranchSlot
  if self.m_orders[slot] == nil and MainOrderCreatorBranch.CanCreate(self, slot) then
    local newOrder = MainOrderCreatorBranch.Create(self, slot)
    self.m_orders[slot] = newOrder
    self:_DBAddOrder(newOrder)
    self:_LogOrderAction(self.m_orders[slot], "unlock")
    self.m_boardModel:UpdateOrderState()
  end
end

function MainOrderModel:IsBranchOrderFinished(branchType)
  return self.m_dbMetaTable:GetValue(self:_GetBranchOrderFinishMetaKey(branchType), DBColumnValue) == "1"
end

function MainOrderModel:GetBranchOrderFinalRewardSlotName(branchType)
  for _, config in pairs(self.m_branchOrderConfig) do
    if config.BranchType == branchType then
      return config.EndTimeline
    end
  end
end

function MainOrderModel:GetBranchOrderRequirement(branchType)
  for _, config in pairs(self.m_branchOrderConfig) do
    if config.BranchType == branchType then
      return config.Requirement
    end
  end
end

function MainOrderModel:_GetBranchOrderFinishMetaKey(branchType)
  return "FinishBranchOrder" .. branchType
end

function MainOrderModel:_SetBranchOrderFinished(order)
  local branchType = self.m_branchOrderConfig[order:GetSlot()].BranchType
  self.m_dbMetaTable:Set(self:_GetBranchOrderFinishMetaKey(branchType), DBColumnValue, "1")
end

function MainOrderModel:_AddGiftRewardInfo(order)
  if GM.CharacterIntimacyModel:IsOpen() and GM.CharacterIntimacyModel:IsRandomOrderOpen() and order:GetInnerType() == MainOrderType.CharacterIntimacyRandom then
    local giftNum = GM.CharacterIntimacyModel:GetCoinToGiftNum(order:GetPrice())
    local giftConfig = GM.CharacterIntimacyModel:GetGiftConfig()
    local giftRewards = {
      {
        [PROPERTY_TYPE] = Table.ListRandomSelectOne(giftConfig).Type,
        [PROPERTY_COUNT] = giftNum,
        [PROPERTY_CRYPT] = Crypt.CryptCurrency(giftNum)
      }
    }
    order:SetGiftRewardInfo(giftRewards)
  end
end

function MainOrderModel:ForceRefreshOrderForReturnUser()
  local itemOnBoard = self.m_boardModel:GetItemsOnBoard(true)
  local alreadySelectedItems = {}
  local slot
  local otherOrderRequirements = {}
  
  local function UpdateOtherRequirements()
    otherOrderRequirements = {}
    for _, order in pairs(self:GetOrders()) do
      local orderRequirements = order:GetRequirements()
      for k, itemCode in pairs(orderRequirements) do
        if otherOrderRequirements[itemCode] == nil then
          otherOrderRequirements[itemCode] = 0
        end
        otherOrderRequirements[itemCode] = otherOrderRequirements[itemCode] + 1
      end
    end
  end
  
  local curBoardItemCountMap = self.m_boardModel:GetCodeCountMap(true, false, true)
  
  local function filterSlotItems(slot, ignoreSlots)
    local logStr = ""
    if GameConfig.IsTestMode() then
      logStr = "[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\141" .. slot .. "\229\136\157\231\173\155\230\163\139\231\155\152\228\184\138\231\154\132\230\163\139\229\173\144\239\188\154\n"
    end
    local targetItems = Table.DeepCopy(itemOnBoard)
    if GameConfig.IsTestMode() then
      logStr = logStr .. "\229\189\147\229\137\141\230\163\139\231\155\152\228\184\138\231\154\132\230\163\139\229\173\144\239\188\154\n"
      logStr = logStr .. Log.GetTableFormatStr(targetItems.levelMap)
      logStr = logStr .. [[

------------------------
]]
    end
    local otherSlotOrderRequirements = Table.DeepCopy(otherOrderRequirements)
    if GameConfig.IsTestMode() then
      logStr = logStr .. "\230\137\128\230\156\137\230\167\189\228\189\141\233\156\128\230\177\130\230\163\139\229\173\144\229\143\138\230\149\176\233\135\143\239\188\136\229\142\159\229\167\139\239\188\137\239\188\154\n"
      for itemCode, count in pairs(otherSlotOrderRequirements) do
        if 0 < count then
          logStr = logStr .. itemCode .. "(" .. count .. "), "
        end
      end
      logStr = logStr .. [[

------------------------
]]
    end
    for _, itemCode in pairs(self.m_orders[slot]:GetRequirements()) do
      if otherSlotOrderRequirements[itemCode] ~= nil then
        otherSlotOrderRequirements[itemCode] = math.max(otherSlotOrderRequirements[itemCode] - 1, 0)
      end
    end
    if GameConfig.IsTestMode() then
      logStr = logStr .. "\230\137\128\230\156\137\230\167\189\228\189\141\233\156\128\230\177\130\230\163\139\229\173\144\229\143\138\230\149\176\233\135\143\239\188\136\229\137\148\233\153\164\229\189\147\229\137\141\230\167\189\228\189\141\233\156\128\230\177\130\230\163\139\229\173\144\239\188\137\239\188\154\n"
      for itemCode, count in pairs(otherSlotOrderRequirements) do
        if 0 < count then
          logStr = logStr .. itemCode .. "(" .. count .. "), "
        end
      end
      logStr = logStr .. [[

------------------------
]]
    end
    for _, slot in pairs(ignoreSlots) do
      if self.m_orders[slot] then
        for _, itemCode in pairs(self.m_orders[slot]:GetRequirements()) do
          if otherSlotOrderRequirements[itemCode] ~= nil then
            otherSlotOrderRequirements[itemCode] = math.max(otherSlotOrderRequirements[itemCode] - 1, 0)
          end
        end
      end
    end
    if GameConfig.IsTestMode() then
      logStr = logStr .. "\230\137\128\230\156\137\230\167\189\228\189\141\233\156\128\230\177\130\230\163\139\229\173\144\229\143\138\230\149\176\233\135\143\239\188\136\229\137\148\233\153\164\229\133\182\228\187\150\230\167\189\228\189\141\233\156\128\230\177\130\230\163\139\229\173\144\239\188\137\239\188\154"
      for _, slot in pairs(ignoreSlots) do
        if self.m_orders[slot] then
          logStr = logStr .. "slot" .. slot .. ", "
        end
      end
      logStr = logStr .. "\n"
      for itemCode, count in pairs(otherSlotOrderRequirements) do
        if 0 < count then
          logStr = logStr .. itemCode .. "(" .. count .. "), "
        end
      end
      logStr = logStr .. [[

------------------------
]]
    end
    local newTarget = {}
    for item, _ in pairs(targetItems.codeMap) do
      if otherSlotOrderRequirements[item] == nil or not (otherSlotOrderRequirements[item] >= (curBoardItemCountMap[item] or 0)) then
        table.insert(newTarget, item)
      end
    end
    local itemCodeConfigMap = self:GetItemCodeConfigMap()
    local newItemBoard = {
      levelMap = {},
      levelList = {},
      codeMap = {}
    }
    for _, item in pairs(newTarget) do
      local level
      if itemCodeConfigMap[item].DifficultyLevel ~= nil then
        level = itemCodeConfigMap[item].DifficultyLevel
      else
        level = GM.ItemDataModel:GetChainLevel(item)
      end
      if not newItemBoard.levelMap[level] then
        newItemBoard.levelMap[level] = {}
      end
      if not Table.Contain(newItemBoard.levelMap[level], item) then
        table.insert(newItemBoard.levelMap[level], item)
      end
      if not Table.Contain(newItemBoard.levelList, level) then
        table.insert(newItemBoard.levelList, level)
      end
      newItemBoard.codeMap[item] = true
    end
    table.sort(newItemBoard.levelList)
    if GameConfig.IsTestMode() then
      logStr = logStr .. "\229\189\147\229\137\141\230\163\139\231\155\152\228\184\138\231\154\132\230\163\139\229\173\144\239\188\136\230\156\128\231\187\136\239\188\137\239\188\154\n"
      logStr = logStr .. Log.GetTableFormatStr(newItemBoard.levelMap)
      logStr = logStr .. [[

------------------------
]]
      Log.Info(logStr)
    end
    return newItemBoard
  end
  
  slot = MainOrderSlotDefinition.Slot5
  if self.m_orders[slot] and self.m_orders[slot]:GetInnerType() == MainOrderType.Random4 then
    UpdateOtherRequirements()
    local newItemBoard = filterSlotItems(slot, {
      MainOrderSlotDefinition.Slot4,
      MainOrderSlotDefinition.Slot2,
      MainOrderSlotDefinition.Slot1
    })
    local requirements = {}
    local firstSelectIdx = #newItemBoard.levelList
    if 0 < firstSelectIdx then
      local level = newItemBoard.levelList[firstSelectIdx]
      local firstList = newItemBoard.levelMap[level]
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1415\231\172\172\228\184\128\228\184\170\233\156\128\230\177\130\230\163\139\229\173\144\229\128\153\233\128\137\230\163\139\229\173\144\239\188\154" .. (Table.IsEmpty(firstList) and "\231\169\186" or table.concat(firstList, ",")))
      end
      local selectIdx = MathUtil.Random(1, #firstList)
      table.insert(requirements, firstList[selectIdx])
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1415\231\172\172\228\184\128\228\184\170\233\156\128\230\177\130\230\163\139\229\173\144\233\128\137\230\139\169\230\163\139\229\173\144\239\188\154" .. (Table.IsEmpty(firstList) and "\231\169\186" or firstList[selectIdx]))
      end
      table.insert(alreadySelectedItems, requirements[1])
      table.remove(firstList, selectIdx)
      if not next(firstList) then
        newItemBoard.levelMap[level] = nil
        table.remove(newItemBoard.levelList, firstSelectIdx)
      end
    end
    local secondLevelIdx
    if next(newItemBoard.levelList) then
      for i = #newItemBoard.levelList, 1, -1 do
        if newItemBoard.levelList[i] < 7 then
          secondLevelIdx = i
          break
        end
      end
    end
    if secondLevelIdx then
      local level = newItemBoard.levelList[secondLevelIdx]
      local secondList = newItemBoard.levelMap[level]
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1415\231\172\172\228\186\140\228\184\170\233\156\128\230\177\130\230\163\139\229\173\144\229\128\153\233\128\137\230\163\139\229\173\144\239\188\154" .. (Table.IsEmpty(secondList) and "\231\169\186" or table.concat(secondList, ",")))
      end
      local selectIdx = MathUtil.Random(1, #secondList)
      table.insert(requirements, secondList[selectIdx])
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1415\231\172\172\228\186\140\228\184\170\233\128\137\230\139\169\230\163\139\229\173\144\233\128\137\230\139\169\230\163\139\229\173\144\239\188\154" .. (Table.IsEmpty(secondList) and "\231\169\186" or secondList[selectIdx]))
      end
      table.insert(alreadySelectedItems, requirements[2])
      table.remove(secondList, selectIdx)
      if not next(secondList) then
        newItemBoard.levelMap[level] = nil
        table.remove(newItemBoard.levelList, secondLevelIdx)
      end
    end
    self:UpdateRequirements(slot, requirements)
  end
  slot = MainOrderSlotDefinition.Slot4
  if self.m_orders[slot] and self.m_orders[slot]:GetInnerType() == MainOrderType.Random3 then
    UpdateOtherRequirements()
    local requirements = {}
    local newItemBoard = filterSlotItems(slot, {
      MainOrderSlotDefinition.Slot1,
      MainOrderSlotDefinition.Slot2
    })
    local firstSelectIdx = #newItemBoard.levelList
    if 0 < firstSelectIdx then
      local level = newItemBoard.levelList[firstSelectIdx]
      local list = newItemBoard.levelMap[level]
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1414\231\172\172\228\184\128\228\184\170\233\156\128\230\177\130\230\163\139\229\173\144\229\128\153\233\128\137\230\163\139\229\173\144\239\188\154" .. (Table.IsEmpty(list) and "\231\169\186" or table.concat(list, ",")))
      end
      local selectIdx = MathUtil.Random(1, #list)
      table.insert(requirements, list[selectIdx])
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1414\231\172\172\228\184\128\228\184\170\233\128\137\230\139\169\230\163\139\229\173\144\233\128\137\230\139\169\230\163\139\229\173\144\239\188\154" .. (Table.IsEmpty(list) and "\231\169\186" or list[selectIdx]))
      end
      
      local function selectItem(index)
        local availableItems = RandomOrderHelper.GetAvailableItems({
          orderModel = self,
          slot = slot,
          alreadyRequiredItems = requirements
        })
        if GameConfig.IsTestMode() then
          Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1414\231\172\172" .. index .. "\228\184\170\233\128\137\230\139\169\230\163\139\229\173\144\233\128\154\231\148\168\231\173\155\233\128\137\230\151\165\229\191\151\239\188\154\n" .. TestOrderLogInfo.strCreateOrderTestLog)
        end
        availableItems = RandomOrderHelper.FilterByLevel(availableItems, 4, 5)
        availableItems = RandomOrderHelper.FilterByChainId(availableItems, {
          ItemChain.Bread,
          ItemChain.Coffee
        })
        if #availableItems == 0 then
          if GameConfig.IsTestMode() then
            Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1414\231\172\172" .. index .. "\228\184\170\233\128\137\230\139\169\230\163\139\229\173\144\229\128\153\233\128\137\230\163\139\229\173\144\239\188\154\231\169\186")
          end
          return nil
        end
        local notOnBoard = {}
        local notRequired = {}
        for _, item in ipairs(availableItems) do
          if not newItemBoard.codeMap[item.Code] then
            table.insert(notOnBoard, item)
          end
          if not Table.Contain(alreadySelectedItems, item.Code) and not Table.Contain(requirements, item.Code) then
            table.insert(notRequired, item)
          end
        end
        local items = availableItems
        if next(notOnBoard) then
          items = notOnBoard
          if GameConfig.IsTestMode() then
            local str = ""
            for _, item in ipairs(notOnBoard) do
              str = str .. item.Code .. ","
            end
            Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1414\231\172\172" .. index .. "\228\184\170\233\128\137\230\139\169\230\163\139\229\173\144\229\128\153\233\128\137\230\163\139\229\173\144\239\188\136\230\178\161\230\156\137\229\156\168\229\189\147\229\137\141\230\163\139\231\155\152\228\184\138\231\154\132\239\188\137\239\188\154" .. str)
          end
        elseif next(notRequired) then
          items = notRequired
          if GameConfig.IsTestMode() then
            local str = ""
            for _, item in ipairs(notRequired) do
              str = str .. item.Code .. ","
            end
            Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1414\231\172\172" .. index .. "\228\184\170\233\128\137\230\139\169\230\163\139\229\173\144\229\128\153\233\128\137\230\163\139\229\173\144\239\188\136\229\133\182\228\187\150\230\156\170\232\162\171\233\128\137\228\184\173\231\154\132\239\188\137\239\188\154" .. str)
          end
        elseif GameConfig.IsTestMode() then
          Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\230\167\189\228\189\1414\231\172\172" .. index .. "\228\184\170\233\128\137\230\139\169\230\163\139\229\173\144\229\128\153\233\128\137\230\163\139\229\173\144\239\188\154\231\169\186")
        end
        return Table.ListWeightSelectOne(items).Code
      end
      
      requirements[2] = selectItem(2)
      if GameConfig.IsTestMode() then
        TestOrderLogInfo.Clear()
      end
      requirements[3] = requirements[2] and selectItem(3)
      if GameConfig.IsTestMode() then
        TestOrderLogInfo.Clear()
      end
    end
    self:UpdateRequirements(slot, requirements)
  end
  slot = MainOrderSlotDefinition.Slot2
  if self.m_orders[slot] and self.m_orders[slot]:GetInnerType() == MainOrderType.Random1 then
    local innerType = self.m_orders[slot]:GetInnerType()
    local order = RandomOrderHelper.CreateNormalRandomOrderWithChainIdFilter(self, slot, innerType, {
      ItemChain.Coffee
    })
    if order ~= nil then
      self:UpdateRequirements(slot, order:GetRequirements())
    end
  end
  if GameConfig.IsTestMode() then
    GM.TestModel:ShowTestOrderLog(TestOrderLogInfo.strCreateOrderTestLog)
  end
  slot = MainOrderSlotDefinition.Slot1
  if self.m_orders[slot] and self.m_orders[slot]:GetInnerType() == MainOrderType.Random1 then
    local innerType = self.m_orders[slot]:GetInnerType()
    local order = RandomOrderHelper.CreateNormalRandomOrderWithChainIdFilter(self, slot, innerType, {
      ItemChain.Bread
    })
    if order ~= nil then
      self:UpdateRequirements(slot, order:GetRequirements())
    end
  end
  if GameConfig.IsTestMode() then
    GM.TestModel:ShowTestOrderLog(TestOrderLogInfo.strCreateOrderTestLog)
  end
end

function MainOrderModel:GetFixedOrderConfig()
  return self.m_fixedOrderConfig
end

function MainOrderModel:GetRandomOrderConfig()
  if GM.ReturnUserModel:IsOpen() and GM.ReturnUserModel:IsInReturnRewardTime() then
    return self.m_randomOrderRecallConfig
  end
  return self.m_randomOrderConfig
end

function MainOrderModel:GetRandomOrderConfigBySlot(slot)
  local chestCustomerModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  if chestCustomerModel:IsChestCustomerOrder(slot) then
    if GM.ReturnUserModel:IsOpen() and GM.ReturnUserModel:IsInReturnRewardTime() then
      return self.m_chestRandomOrderRecallConfig
    end
    return self.m_chestRandomOrderConfig
  else
    return self:GetRandomOrderConfig()
  end
end

function MainOrderModel:GetChestRandomOrderConfig()
  if GM.ReturnUserModel:IsOpen() and GM.ReturnUserModel:IsInReturnRewardTime() then
    return self.m_chestRandomOrderRecallConfig
  end
  return self.m_chestRandomOrderConfig
end

function MainOrderModel:GetSpecialOrderConfig()
  return self.m_specialOrderConfig
end

function MainOrderModel:GetBranchOrderConfig()
  return self.m_branchOrderConfig
end

function MainOrderModel:GetLuckyOrderConfig()
  return self.m_luckyOrderConfig
end

function MainOrderModel:GetItemCodeConfigMap()
  return self.m_itemCodeConfigMap
end

function MainOrderModel:GetItemNumberWeightConfig()
  return self.m_itemNumberWeightConfig
end

function MainOrderModel:GetAvatarConfig()
  return self.m_avatarConfig
end

function MainOrderModel:GetNormalAvatarConfig(id)
  return self.m_normalAvatarConfigs[id]
end

function MainOrderModel:GetMetaData()
  return self.m_dbMetaTable
end

function MainOrderModel:GetLastFinishOrder()
  return self.m_lastFinishOrder
end

function MainOrderModel:_LogOrder(order, type, content, action)
  local rewards = order:GetRewards()
  if action == "finish" then
    local puzzleModel = GM.ActivityManager:GetModel(ActivityType.Puzzle)
    local generatedItem = puzzleModel:GetGenerateItemByOrder(order)
    if generatedItem ~= nil then
      table.insert(rewards, generatedItem)
    end
    local scoreRaceModel = GM.ActivityManager:GetModel(ActivityType.ScoreRace)
    local generatedItem = scoreRaceModel:GetGenerateItemByOrder(order)
    if generatedItem ~= nil then
      table.insert(rewards, generatedItem)
    end
    local farmboardModel = GM.ActivityManager:GetStartedFarmboardActivity()
    if farmboardModel ~= nil then
      local generatedItem = farmboardModel:GetGenerateItemByOrder(order)
      if generatedItem ~= nil then
        table.insert(rewards, generatedItem)
      end
    end
  end
  local cfbfId, cfbrwd
  if order.GetCookingBIConfig then
    cfbfId, cfbrwd = order:GetCookingBIConfig()
  end
  local bfid = {}
  if order.GetSupportBuffId then
    Table.ListAppend(bfid, order:GetSupportBuffId())
  end
  if order.CanSupportAlbumBuff and order:CanSupportAlbumBuff() then
    table.insert(bfid, EBuffProperty.buff_album)
  end
  local chestCustomerModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  local _isChestCustomer = chestCustomerModel:IsChestCustomerOrder(order:GetSlot())
  local _faceNum = 0
  if order:GetInnerType() == MainOrderType.ExtraCustomer then
    local extCusModel = GM.ActivityManager:GetModel(ActivityType.ExtraCustomer)
    _faceNum = extCusModel and extCusModel:GetSmileRewardNumber()
  else
    _faceNum = order.GetSupportOrderBoost and order:GetSupportOrderBoost()
  end
  local tb = {
    isBuffGold = order:IsBuffGoldDouble(),
    state = order:GetState(),
    slot = order:GetSlot(),
    islucky = order:IsLuckyOrder(),
    isbaseline = order:IsBaselineOrder(),
    ds = order:GetDiffScore(),
    rwd = rewards,
    bfrwd = order.GetBuffRewards and order:GetBuffRewards(),
    bfid = bfid,
    facenum = _faceNum,
    ispro = order.IsOrderBoostPro and order:IsOrderBoostPro(),
    isbutterfly = order:IsButterfly(),
    cfbrwd = cfbrwd,
    cfbfId = cfbfId,
    isChestCustomer = _isChestCustomer,
    isContiorder = order:GetSlot() == MainOrderSlotDefinition.ContiorderSlot
  }
  if action == "unlock" then
    tb.dynamicMax = {}
    if ItemsUsingDynamicLevel and ItemsUsingDynamicLevel[order:GetSlot()] then
      for _, item in pairs(ItemsUsingDynamicLevel[order:GetSlot()]) do
        if Table.Contain(order:GetRequirements(), item) then
          table.insert(tb.dynamicMax, item)
        end
      end
    end
  end
  if NormalOrderSlot[order:GetSlot()] == true then
    tb.dsrg = order:GetDiffRange()
    if action == "unlock" then
      local randomConfig = self:GetRandomOrderConfig()[order:GetInnerType()]
      if _isChestCustomer then
        randomConfig = self:GetChestRandomOrderConfig()[order:GetInnerType()]
      end
      if randomConfig then
        local config = RandomOrderHelper.GetSelectedFilterConfig(randomConfig, self, order:GetSlot(), true)
        tb.monthPayRange = tostring(config.sMonthPay == nil and "nil" or config.sMonthPay) .. "-" .. tostring(config.eMonthPay == nil and "nil" or config.eMonthPay)
      end
    end
  end
  if order.GetOrderBoostFinishRound and order:GetOrderBoostFinishRound() ~= nil then
    tb.oboostround = order:GetOrderBoostFinishRound() + 1
  end
  GM.BIManager:LogOrder(order:GetId(), type, content, action, tb)
end

function MainOrderModel:_GetLogOrderActionOrderType(order)
  if order.GetInnerType ~= nil then
    local innerType = order:GetInnerType()
    if innerType == MainOrderType.CharacterIntimacyRandom then
      return "intimacy"
    elseif innerType == MainOrderType.TimedOrder then
      return "timedOrder"
    elseif innerType == MainOrderType.BaselineOrder then
      return "baseline"
    end
  end
  return SlotOrderModel._GetLogOrderActionOrderType(self, order)
end

function MainOrderModel:CanTriggerLucky()
  return self.m_canTriggerLucky
end

function MainOrderModel:CloseTriggerLucky()
  self.m_canTriggerLucky = false
end

function MainOrderModel:GetTutorialOrderModel()
  return self.m_tutorialOrderModel
end
