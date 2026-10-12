ChestCustomerModel = setmetatable({}, BaseActivityModel)
ChestCustomerModel.__index = ChestCustomerModel
local strDBKeys = {cacheData = "cacheData", cacheID = "cacheID"}
ChestCustomerModel.RewardKey = "chest_custom_reward_randomreward_"

function ChestCustomerModel:Init(dbTable)
  self:LoadCacheData(dbTable)
  BaseActivityModel.Init(self, ActivityType.ChestCustomer, dbTable)
  self.m_mapCacheReward = {}
  self.m_effectLoaderNum = 0
end

function ChestCustomerModel:_LoadOtherServerConfig(config)
  self.m_CustomerConfig = config.chestOrderCustomerConfig
  self.m_RewardConfig = config.chestOrderRewardConfig
  self.m_eventOrderScore = config.eventOrderScore
end

function ChestCustomerModel:LoadCacheData(dbTable)
  self.m_CacheData = json.decode(dbTable:GetValue(strDBKeys.cacheData, "value") or "")
end

function ChestCustomerModel:LateInit()
  self.m_bLateInit = true
  self:TryRemoveOrder()
  self:TryCreateChestOrder()
end

function ChestCustomerModel:_DropData()
  BaseActivityModel._DropData(self)
end

function ChestCustomerModel:_OnStateChanged()
  self:TryRemoveOrder()
  self:TryCreateChestOrder()
  EventDispatcher.DispatchEvent(EEventType.ChestCustomerStateChanged)
end

function ChestCustomerModel:RemoveOrders()
  if self.m_CacheData ~= nil then
    for _, cacheData in pairs(self.m_CacheData) do
      if cacheData.LastTime == -1 then
        GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):RemoveOrder(cacheData.slot)
      end
    end
    self.m_CacheData = nil
    self:SaveCacheData()
    if self.m_effectLoader ~= nil then
      AddressableLoader.Destroy(self.m_effectLoader.gameObject)
      self.m_effectLoader = nil
      self.m_effectLoaderNum = 0
    end
  end
end

function ChestCustomerModel:TryCreateChestOrder()
  if self:GetState(false) == ActivityState.Started and self.m_CacheData == nil then
    self.m_CacheData = {}
    self.m_dbTable:Set(strDBKeys.cacheID, "value", self.m_config.id)
    self:SaveCacheData()
  end
end

function ChestCustomerModel:TryRemoveOrder()
  if not self.m_bLateInit then
    return
  end
  if self:GetState(false) ~= ActivityState.Started or self.m_dbTable:GetValue(strDBKeys.cacheID, "value") ~= self.m_config.id then
    self:RemoveOrders()
  end
  if self:GetState(false) == ActivityState.Started then
    self:RemoveErrorOrders()
  end
end

function ChestCustomerModel:RemoveErrorOrders()
  if self.m_CacheData ~= nil then
    for _, cacheData in pairs(self.m_CacheData) do
      if cacheData.LastTime == -1 then
        local slot = cacheData.slot
        local avatarConfig = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetAvatarConfig()
        local order = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetOrders()[slot]
        if order == nil or avatarConfig.ChestCustomerAvatars[order:GetAvatarId()] == nil then
          cacheData.LastTime = GM.GameModel:GetServerTime()
        end
      end
    end
    self:SaveCacheData()
  end
end

function ChestCustomerModel:CheckCreateChestOrder(orderType)
  local bCheckResource = true
  if GM.SceneManager:GetGameMode() == EGameMode.Loading then
    bCheckResource = false
  end
  if self:GetState(bCheckResource) ~= ActivityState.Started then
    return false
  end
  local slotOrderModel = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot)
  local customConfig = self:GetCustomerConfig(orderType)
  if customConfig == nil then
    return false
  end
  if self.m_CacheData == nil then
    return false
  end
  if GM.CustomerUpgradeRewardModel:CanFillChestCustomerOrder() then
    return true
  end
  local Key = tostring(orderType)
  local cacheData = self.m_CacheData[Key]
  if cacheData == nil or cacheData.LastTime ~= -1 and cacheData.LastTime + customConfig.Cooldown * 60 < GM.GameModel:GetServerTime() then
    local fRand = MathUtil.Random()
    if fRand < customConfig.Chance then
      return true
    end
  end
  return false
end

local MapInnerTypeToAvatar = {
  [MainOrderType.Random1] = 1001,
  [MainOrderType.Random2] = 1001,
  [MainOrderType.Random5New] = 1002,
  [MainOrderType.Random3] = 1003,
  [MainOrderType.Random4] = 1004
}

function ChestCustomerModel:CreateNewChestCustomerOrder(orderType, slot)
  local Key = tostring(orderType)
  local originalLastTime
  if GM.CustomerUpgradeRewardModel:CanFillChestCustomerOrder() then
    local oldCacheData = self.m_CacheData[Key]
    if oldCacheData ~= nil and oldCacheData.LastTime ~= -1 then
      originalLastTime = oldCacheData.LastTime
    end
  end
  self.m_CacheData[Key] = {
    slot = slot,
    LastTime = -1,
    orderType = orderType
  }
  if originalLastTime ~= nil then
    self.m_CacheData[Key].originalLastTime = originalLastTime
  end
  self:SaveCacheData()
  EventDispatcher.DispatchEvent(EEventType.ChestCustomerOrderCreate)
  return MapInnerTypeToAvatar[orderType]
end

function ChestCustomerModel:ReplaceOrderWithChestCustomerOrder(orderType, slot)
  local Key = tostring(orderType)
  local cacheData = self.m_CacheData[Key]
  if cacheData ~= nil and cacheData.LastTime ~= -1 then
    local originalLastTime = cacheData.LastTime
    self.m_CacheData[Key] = {
      slot = slot,
      LastTime = -1,
      orderType = orderType,
      originalLastTime = originalLastTime
    }
  else
    self.m_CacheData[Key] = {
      slot = slot,
      LastTime = -1,
      orderType = orderType
    }
  end
  self:SaveCacheData()
  EventDispatcher.DispatchEvent(EEventType.ChestCustomerOrderCreate)
  return MapInnerTypeToAvatar[orderType]
end

local function GetRewardsByItemTypes(ListType)
  local rewards = {}
  for _, ItemType in ipairs(ListType) do
    table.insert(rewards, {
      [PROPERTY_TYPE] = ItemType,
      [PROPERTY_COUNT] = 1
    })
  end
  return rewards
end

function ChestCustomerModel:FindNormalRewardConfig(scoreNum, rewardConfig, testStr)
  local oldScore = scoreNum
  local rewards = {}
  while 0 < scoreNum do
    local reward = Table.ListRandomSelectOne(rewardConfig.rewards)
    local rewardType = reward[PROPERTY_TYPE]
    local itemdiffScore = reward[PROPERTY_COUNT]
    scoreNum = scoreNum - itemdiffScore
    table.insert(rewards, {
      [PROPERTY_TYPE] = rewardType,
      [PROPERTY_COUNT] = 1
    })
    if GameConfig.IsTestMode() then
      testStr = testStr .. "\229\165\150\229\138\177:" .. tostring(rewardType) .. " \229\136\134\230\149\176" .. tostring(itemdiffScore) .. "\229\137\169\228\189\153:" .. tostring(scoreNum) .. "\n"
    end
  end
  return rewards, oldScore - scoreNum, testStr
end

function ChestCustomerModel:AcquireChestCustomOrderReward(reward)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  local innerType, slot = reward[PROPERTY_TYPE]:match(ChestCustomerModel.RewardKey .. "(%d+)_(%d+)")
  local order = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetOrders()[tonumber(slot)]
  if order == nil then
    Log.Error("\233\148\153\232\175\175\239\188\140 \232\174\162\229\141\149\230\151\160\230\149\136" .. tostring(slot))
    return
  end
  local diffScore = order:GetDiffScore()
  local scoreNum = 0
  for _, scoreConfig in ipairs(self.m_eventOrderScore) do
    if diffScore >= scoreConfig.diff_score_min and diffScore <= scoreConfig.diff_score_max then
      if scoreConfig.reward_num_percentage ~= nil then
        scoreNum = diffScore * scoreConfig.reward_num_percentage / 10000
      else
        scoreNum = scoreConfig.reward_num_fix
      end
    end
  end
  if tonumber(innerType) == MainOrderType.Random2 and tonumber(slot) == MainOrderSlotDefinition.Slot3 then
    scoreNum = math.min(scoreNum, 18)
  end
  local testStr = ""
  if GameConfig.IsTestMode() then
    testStr = testStr .. "[\229\174\157\231\174\177\232\174\162\229\141\149] \230\167\189\228\189\141:" .. tostring(slot) .. ", \230\128\187\229\136\134\230\149\176:" .. tostring(scoreNum) .. "\n"
  end
  local rewardConfig = Table.ListWeightSelectOne(self:GetChestOrderRewardConfig(tonumber(innerType)), "weight")
  local bUseOrderItemReward = false
  for _, reward in ipairs(rewardConfig.rewards) do
    if reward[PROPERTY_TYPE] == "chestcustomeritem" then
      bUseOrderItemReward = true
      break
    end
  end
  local rewards, _
  if bUseOrderItemReward == true then
    local listTargetItem, eleStr = RandomGenerateCodeHelper.GenerateChestCustomCodeRule(scoreNum, nil, true)
    rewards = GetRewardsByItemTypes(listTargetItem)
    testStr = testStr .. eleStr
  else
    rewards, _, testStr = self:FindNormalRewardConfig(scoreNum, rewardConfig, testStr)
  end
  Log.Debug(testStr)
  local boarNewPos = BoardPosition.Create(1, 1)
  local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrderWithNum(boarNewPos, nil, #rewards, true)
  local AddItems = {}
  local cacheItems = {}
  for index, Pos in ipairs(targetPos) do
    rewards[index].pos = Pos
    table.insert(AddItems, {
      position = Pos,
      code = rewards[index][PROPERTY_TYPE]
    })
    GM.BIManager:LogAcquire(rewards[index][PROPERTY_TYPE], 1, EBIType.ChestCustomOrderReward)
  end
  for index = #targetPos + 1, #rewards do
    table.insert(cacheItems, rewards[index])
  end
  GM.MainBoardModel:GenerateItems(AddItems)
  RewardApi.AcquireRewardsLogic(cacheItems, EPropertySource.Give, EBIType.ChestCustomOrderReward, EGameMode.Main, CacheItemType.Type2)
  self.m_mapCacheReward[innerType .. "_" .. slot] = rewards
  self:SaveCacheData()
end

function ChestCustomerModel:GetRewardsBySlot(innerType, slot)
  if self:GetState() ~= ActivityState.Started then
    return {}
  end
  if self.m_CacheData == nil then
    return {}
  end
  return self.m_mapCacheReward[tostring(innerType) .. "_" .. tostring(slot)]
end

function ChestCustomerModel:HasOrderScrolled(innerType)
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  return self.m_CacheData[tostring(innerType)].isScollOrder
end

local typeSequence = {
  MainOrderType.Random2,
  MainOrderType.Random4,
  MainOrderType.Random3,
  MainOrderType.Random5New,
  MainOrderType.Random1
}

function ChestCustomerModel:GetHighestPriorityOrderSlotWaitingToScroll()
  if self:GetState() ~= ActivityState.Started or self.m_CacheData == nil then
    return nil
  end
  local selected
  for _, cacheData in pairs(self.m_CacheData) do
    if not cacheData.isScollOrder and (selected == nil or Table.GetIndex(typeSequence, cacheData.orderType) < Table.GetIndex(typeSequence, selected.orderType)) then
      selected = cacheData
    end
  end
  if selected ~= nil then
    return selected.slot
  end
  return nil
end

function ChestCustomerModel:MarkAllOrderScrolled()
  if self.m_CacheData == nil then
    return
  end
  for _, cacheData in pairs(self.m_CacheData) do
    cacheData.isScollOrder = true
  end
  self:SaveCacheData()
end

function ChestCustomerModel:MarkOrderScrolled(innerType)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  self.m_CacheData[tostring(innerType)].isScollOrder = true
  self:SaveCacheData()
end

function ChestCustomerModel:ChestOrderFinish(slot)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  for _, cacheData in pairs(self.m_CacheData) do
    if cacheData.slot == slot and cacheData.LastTime == -1 then
      if cacheData.originalLastTime ~= nil then
        cacheData.LastTime = cacheData.originalLastTime
        cacheData.originalLastTime = nil
      else
        cacheData.LastTime = GM.GameModel:GetServerTime()
      end
      self:SaveCacheData()
    end
  end
end

function ChestCustomerModel:IsChestCustomerOrder(slot)
  if self:GetState(false) ~= ActivityState.Started then
    return false
  end
  if self.m_CacheData == nil then
    self:TryCreateChestOrder()
  end
  for _, cacheData in pairs(self.m_CacheData) do
    if cacheData.slot == slot and cacheData.LastTime == -1 then
      return true
    end
  end
  return false
end

function ChestCustomerModel:SaveCacheData()
  if self.m_CacheData == nil then
    self.m_dbTable:Remove(strDBKeys.cacheData, "value")
    return
  end
  self.m_dbTable:Set(strDBKeys.cacheData, "value", json.encode(self.m_CacheData))
end

function ChestCustomerModel:GetCustomerConfig(orderType)
  for _, config in ipairs(self.m_CustomerConfig) do
    if config.orderType == orderType then
      return config
    end
  end
  return nil
end

function ChestCustomerModel:GetChestOrderRewardConfig(orderType)
  local target = {}
  for _, config in ipairs(self.m_RewardConfig) do
    if Table.Contain(config.orderPool, orderType) then
      table.insert(target, config)
    end
  end
  return target
end

function ChestCustomerModel:GetCurDoingChestCustomerOrder()
  if self:GetState() ~= ActivityState.Started then
    return nil
  end
  for _, cacheData in pairs(self.m_CacheData) do
    if cacheData.LastTime == -1 then
      return cacheData.slot
    end
  end
  return nil
end

function ChestCustomerModel:CanPopTutorialWindow()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if not GM.TutorialModel:IsTutorialFinished(ETutorialId.ChestCustomOrderStart) and self:GetCurDoingChestCustomerOrder() ~= nil then
    return true
  end
  return false
end

local ListWaitLoader = {}

function ChestCustomerModel:LoadOrderLoaderPrefab(callback)
  if self.m_effectLoaderNum == 0 and self.m_effectLoader == nil then
    self.m_effectLoaderNum = 1
    GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ChestCustomerOrderEffectLoader), GM.UIManager:GetCanvasRoot(), Vector3.zero, function(go)
      self.m_effectLoader = go:GetLuaTable()
      callback(self.m_effectLoader)
      for _, elecallback in ipairs(ListWaitLoader) do
        elecallback(self.m_effectLoader)
      end
      ListWaitLoader = {}
    end)
  elseif self.m_effectLoader ~= nil then
    callback(self.m_effectLoader)
  else
    table.insert(ListWaitLoader, callback)
  end
end

function ChestCustomerModel:GetCacheData()
  return self.m_CacheData
end

function ChestCustomerModel:GetCustomConfigs()
  return self.m_CustomerConfig
end

function ChestCustomerModel:GetChestCustomerOrderSlots()
  local result = {}
  for _, config in ipairs(self.m_CustomerConfig) do
    local slots = MainOrderTypeSlotMap[config.orderType]
    if not Table.IsEmpty(slots) then
      for _, slot in ipairs(slots) do
        table.insert(result, slot)
      end
    end
  end
  return result
end

function ChestCustomerModel:GetResourceLabels()
  return {
    AddressableLabel.chestCustomOrder
  }
end

function ChestCustomerModel:GetTestInfo()
  local cachedData = self:GetCacheData()
  if cachedData == nil then
    return
  end
  local str = ""
  for _, data in pairs(cachedData) do
    local Time
    local duration = self:GetCustomerConfig(data.orderType).Cooldown
    if data.LastTime == -1 then
      Time = "\232\191\155\232\161\140\228\184\173"
      str = str .. "slot:" .. data.slot .. " orderType" .. data.orderType .. [[

 Time:]] .. Time .. [[
 

]]
    elseif data.LastTime + duration * 60 > GM.GameModel:GetServerTime() then
      Time = TimeUtil.ParseTimeDescription(data.LastTime + duration * 60 - GM.GameModel:GetServerTime())
      str = str .. "slot:" .. data.slot .. " orderType" .. data.orderType .. [[
 
 Time:]] .. Time .. [[
 

]]
    else
      Time = "\231\173\137\229\190\133\229\136\183\230\150\176"
      str = str .. " orderType" .. data.orderType .. [[
 
 Time:]] .. Time .. [[


]]
    end
  end
  for _, customConfig in pairs(self:GetCustomConfigs()) do
    local innerType = customConfig.orderType
    if cachedData[tostring(innerType)] == nil then
      str = str .. " orderType" .. innerType .. "\n Time: \231\173\137\229\190\133\229\136\183\230\150\176\n\n"
    end
  end
  return str
end
