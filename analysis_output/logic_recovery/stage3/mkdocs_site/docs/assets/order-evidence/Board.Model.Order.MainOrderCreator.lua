local DBColumnCurrentFixedOrderId = "CurrentFixedOrderId"
local DBColumnCurrentSpecialOrderId = "CurrentSpecialOrderId"
local DBColumnReturnUserFreeOrderTimer = "ReturnUserFreeOrderTimer"
local DBColumnLuckyOrderPoints = "LuckyOrderPoints"
local DBColumnLuckyOrderTimer = "LuckyOrderTimer"
MainOrderCreatorFixed = {}

function MainOrderCreatorFixed.Create(orderModel, slot)
  local metaData = orderModel:GetMetaData()
  local currentFixedOrderId = tonumber(metaData:GetValue(DBColumnCurrentFixedOrderId, "value")) or 0
  local nextFixedOrderId = currentFixedOrderId + 1
  local fixedOrderConfig = orderModel:GetFixedOrderConfig()
  local nextConfig = fixedOrderConfig[nextFixedOrderId]
  if not (nextConfig ~= nil and Table.ListContain(nextConfig.Slots, slot)) or GM.LevelModel:GetCurrentLevel() < nextConfig.UnlockLevel then
    return nil
  end
  metaData:Set(DBColumnCurrentFixedOrderId, "value", tostring(nextFixedOrderId))
  local requirements = {
    nextConfig.Requirement1,
    nextConfig.Requirement2,
    nextConfig.Requirement3
  }
  local avatarId = orderModel:GetAvatarId()
  return MainOrder.Create(orderModel, slot, nextFixedOrderId, requirements, MainOrderType.Fixed, avatarId)
end

MainOrderCreatorSpecial = {}

function MainOrderCreatorSpecial.GetConfig(orderModel, offset)
  local metaData = orderModel:GetMetaData()
  local currentSpecialOrderId = tonumber(metaData:GetValue(DBColumnCurrentSpecialOrderId, "value")) or 0
  local specialOrderId = currentSpecialOrderId + offset
  local specialOrderConfig = orderModel:GetSpecialOrderConfig()
  return specialOrderConfig[specialOrderId], specialOrderId
end

function MainOrderCreatorSpecial.CanCreate(orderModel)
  local nextConfig = MainOrderCreatorSpecial.GetConfig(orderModel, 1)
  if nextConfig == nil then
    return false
  end
  local parts = StringUtil.Split(nextConfig.Trigger, "-")
  local dayId = StringUtil.Split(parts[2], "_")
  return GM.MainTaskModel:IsTaskFinished(tonumber(dayId[1]), tonumber(dayId[2]))
end

function MainOrderCreatorSpecial.Create(orderModel, slot)
  local nextConfig, nextSpecialOrderId = MainOrderCreatorSpecial.GetConfig(orderModel, 1)
  local metaData = orderModel:GetMetaData()
  metaData:Set(DBColumnCurrentSpecialOrderId, "value", tostring(nextSpecialOrderId))
  local requirements = {
    nextConfig.Requirement1,
    nextConfig.Requirement2,
    nextConfig.Requirement3
  }
  return MainOrder.Create(orderModel, slot, nextSpecialOrderId, requirements, MainOrderType.Special, nextConfig.AvatarId)
end

function MainOrderCreatorSpecial.IsCreated(orderModel, specialOrderId)
  local metaData = orderModel:GetMetaData()
  local currentSpecialOrderId = tonumber(metaData:GetValue(DBColumnCurrentSpecialOrderId, "value")) or 0
  return specialOrderId <= currentSpecialOrderId
end

function MainOrderCreatorSpecial.ResetCurrentSpecialOrderId(orderModel, id)
  local metaData = orderModel:GetMetaData()
  metaData:Set(DBColumnCurrentSpecialOrderId, "value", tostring(id))
end

MainOrderCreatorBranch = {}

function MainOrderCreatorBranch.Create(orderModel, slot)
  if not MainOrderCreatorBranch.CanCreate(orderModel, slot) then
    return nil
  end
  local config = orderModel:GetBranchOrderConfig()[slot]
  local requirements = {
    config.Requirement
  }
  return MainOrder.Create(orderModel, slot, config.Id, requirements, MainOrderType.Branch, config.AvatarId)
end

function MainOrderCreatorBranch.CanCreate(orderModel, slot)
  return false
end

MainOrderCreatorReturnFreeOrder = {}
local CreatorReturnFreeOrderRefreshTime = 28800

function MainOrderCreatorReturnFreeOrder.CanCreate(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.Slot1 and slot ~= MainOrderSlotDefinition.Slot2 and slot ~= MainOrderSlotDefinition.Slot3 then
    return false
  end
  if not GM.ReturnUserModel:IsOpen() then
    return false
  end
  if not GM.ReturnUserModel:IsInReturnRewardTime() then
    return false
  end
  local metaData = orderModel:GetMetaData()
  local startTimer = tonumber(metaData:GetValue(DBColumnReturnUserFreeOrderTimer, "value"))
  if startTimer == 0 then
    startTimer = GM.GameModel:GetServerTime()
    metaData:Set(DBColumnReturnUserFreeOrderTimer, "value", tostring(startTimer))
    return false
  elseif startTimer == nil or GM.GameModel:GetServerTime() - startTimer >= CreatorReturnFreeOrderRefreshTime then
    metaData:Set(DBColumnReturnUserFreeOrderTimer, "value", "0")
    return true
  else
    return false
  end
end

function MainOrderCreatorReturnFreeOrder.Create(orderModel, slot)
  local selectItemCode
  local itemOnBoard = GM.MainBoardModel:GetItemsOnBoard(true)
  for i = #itemOnBoard.levelList, 1, -1 do
    if itemOnBoard.levelList[i] <= 7 then
      local itemList = itemOnBoard.levelMap[itemOnBoard.levelList[i]]
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\228\191\157\233\128\129\232\174\162\229\141\149\229\128\153\233\128\137\230\163\139\229\173\144\239\188\154" .. (Table.IsEmpty(itemList) and "\231\169\186" or table.concat(itemList, ",")))
      end
      local selectIdx = MathUtil.Random(1, #itemList)
      selectItemCode = itemList[selectIdx]
      if GameConfig.IsTestMode() then
        Log.Debug("[\229\155\158\229\189\146\231\148\168\230\136\183\232\174\162\229\141\149]\228\191\157\233\128\129\232\174\162\229\141\149\233\128\137\230\139\169\230\163\139\229\173\144\239\188\154" .. selectItemCode)
      end
      break
    end
  end
  if not selectItemCode then
    return
  end
  local metaData = orderModel:GetMetaData()
  local startTimer = metaData:GetValue(MainOrderDBColumnRandomStartTimer[slot], "value")
  startTimer = startTimer and tonumber(startTimer)
  if startTimer == 0 then
    startTimer = GM.GameModel:GetServerTime()
    metaData:Set(MainOrderDBColumnRandomStartTimer[slot], "value", tostring(startTimer))
    if GameConfig.IsTestMode() then
      Log.Info("[\233\154\143\230\156\186\232\174\162\229\141\149][Slot/Timer:" .. slot .. "]\229\136\155\229\187\186\228\191\157\233\128\129\232\174\162\229\141\149\239\188\140\229\189\147\229\137\141\230\167\189\228\189\141\229\166\130\230\158\156\229\142\159\233\154\143\230\156\186\232\174\162\229\141\149CD\228\184\1860\239\188\140\229\136\153\231\155\180\230\142\165\232\191\155\229\133\165CD " .. tostring(startTimer))
    end
  end
  local requirements = {selectItemCode}
  local avatarId = orderModel:GetAvatarId()
  return MainOrder.Create(orderModel, slot, nil, requirements, MainOrderType.ReturnUserFree, avatarId)
end

MainOrderCreatorLuckyOrder = {}

function MainOrderCreatorLuckyOrder.CanCreate(orderModel, slot)
  if slot ~= MainOrderSlotDefinition.LuckyOrderSlot or not orderModel:CanTriggerLucky() then
    return false
  end
  orderModel:CloseTriggerLucky()
  local metaData = orderModel:GetMetaData()
  local currentPoints = tonumber(metaData:GetValue(DBColumnLuckyOrderPoints, "value")) or 0
  local lastTime = tonumber(metaData:GetValue(DBColumnLuckyOrderTimer, "value")) or 0
  local luckyOrderConfig = orderModel:GetLuckyOrderConfig()
  if luckyOrderConfig == nil then
    if GameConfig.IsTestMode() then
      Log.Info("\230\137\190\228\184\141\229\136\176\230\131\138\229\150\156\232\174\162\229\141\149\233\133\141\231\189\174\239\188\140\231\148\159\230\136\144\229\164\177\232\180\165")
    end
    return false
  end
  if GM.LevelModel:GetCurrentLevel() < luckyOrderConfig.UnlockLevel then
    return false
  end
  if 1 < currentPoints then
    return true
  elseif currentPoints == 1 then
    metaData:Set(DBColumnLuckyOrderTimer, "value", tostring(GM.GameModel:GetServerTime()))
    metaData:Set(DBColumnLuckyOrderPoints, "value", "0")
    if GameConfig.IsTestMode() then
      Log.Info("\230\131\138\229\150\156\232\174\162\229\141\149\232\191\158\231\187\173\231\148\159\230\136\144\231\130\185\230\149\176\232\128\151\229\176\189\239\188\140\232\191\155\229\133\165cd")
    end
    return false
  elseif lastTime + luckyOrderConfig.RefreshTime <= GM.GameModel:GetServerTime() then
    return true
  else
    if GameConfig.IsTestMode() then
      Log.Info("\230\131\138\229\150\156\232\174\162\229\141\149\229\134\183\229\141\180cd\228\184\173\239\188\140\231\148\159\230\136\144\229\164\177\232\180\165\239\188\140\232\191\152\229\137\169\239\188\154" .. lastTime + luckyOrderConfig.RefreshTime - GM.GameModel:GetServerTime() .. "\231\167\146")
    end
    return false
  end
end

function MainOrderCreatorLuckyOrder.Create(orderModel, slot)
  local luckyOrderConfig = orderModel:GetLuckyOrderConfig()
  if luckyOrderConfig == nil then
    return nil
  end
  local metaData = orderModel:GetMetaData()
  local currentPoints = tonumber(metaData:GetValue(DBColumnLuckyOrderPoints, "value")) or 0
  local selectedFilter = RandomOrderHelper.GetSelectedFilterConfig(luckyOrderConfig, orderModel, slot)
  local availableItems = RandomOrderHelper.GetAvailableItems({
    orderModel = orderModel,
    slot = slot,
    config = luckyOrderConfig
  })
  local firstAvailableItems = RandomOrderHelper.FilterByLevel(availableItems, selectedFilter.FirstMin, selectedFilter.FirstMax, orderModel)
  local secondAvailableItems = RandomOrderHelper.FilterByLevel(availableItems, selectedFilter.SecondMin, selectedFilter.SecondMax, orderModel)
  local thirdAvailableItems = RandomOrderHelper.FilterByLevel(availableItems, selectedFilter.ThirdMin, selectedFilter.ThirdMax, orderModel)
  local LuckRandomAvailable = MainOrderCreatorLuckyOrder.TryLuckyRandom(orderModel, slot, firstAvailableItems, secondAvailableItems, thirdAvailableItems)
  if LuckRandomAvailable ~= nil then
    firstAvailableItems = LuckRandomAvailable.firstAvailableItems
    secondAvailableItems = LuckRandomAvailable.secondAvailableItems
    thirdAvailableItems = LuckRandomAvailable.thirdAvailableItems
  else
    if GameConfig.IsTestMode() then
      Log.Info("\229\183\178\230\156\137\230\163\139\229\173\144\228\184\141\230\187\161\232\182\179\230\157\161\228\187\182\239\188\140\230\131\138\229\150\156\232\174\162\229\141\149\231\148\159\230\136\144\229\164\177\232\180\165")
    end
    if currentPoints ~= 0 then
      metaData:Set(DBColumnLuckyOrderTimer, "value", tostring(GM.GameModel:GetServerTime()))
      metaData:Set(DBColumnLuckyOrderPoints, "value", "0")
    end
    return nil
  end
  local itemNumberWeightConfig = orderModel:GetItemNumberWeightConfig()
  local level = GM.LevelModel:GetCurrentLevel()
  local weightConfig
  if luckyOrderConfig.ItemAmounts ~= nil then
    weightConfig = luckyOrderConfig.ItemAmounts
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
  if Table.IsEmpty(weightConfig) then
    for i = #itemNumberWeightConfig, 1, -1 do
      local config = itemNumberWeightConfig[i]
      if level >= config.Level then
        weightConfig = config
        break
      end
    end
  end
  Log.Assert(weightConfig ~= nil, "MainOrderCreatorLuckyOrder.Create")
  local countWeightList = {}
  if #firstAvailableItems ~= 0 then
    table.insert(countWeightList, {
      Count = 1,
      Weight = weightConfig.OneItemWeight
    })
    if #secondAvailableItems ~= 0 then
      table.insert(countWeightList, {
        Count = 2,
        Weight = weightConfig.TwoItemsWeight
      })
      if #thirdAvailableItems ~= 0 then
        table.insert(countWeightList, {
          Count = 3,
          Weight = weightConfig.ThreeItemsWeight
        })
      end
    end
  elseif GameConfig.IsTestMode() then
    Log.Info("\229\185\184\232\191\144\232\174\162\229\141\149\231\172\172\228\184\128\228\184\170\233\156\128\230\177\130\230\163\139\229\173\144\229\143\175\233\128\137\229\136\151\232\161\168\228\184\186\231\169\186\239\188\140\230\151\160\230\179\149\229\136\155\229\187\186\232\174\162\229\141\149\239\188\140\232\175\183\230\159\165\231\156\139OrderRandomConfig\231\154\132Filters\233\133\141\231\189\174")
  end
  local count = Table.ListWeightSelectOne(countWeightList).Count
  local requirements = {}
  table.insert(requirements, Table.ListWeightSelectOne(firstAvailableItems).Code)
  if 2 <= count then
    MainOrderCreatorLuckyOrder.LuckRandomRemoveCode(secondAvailableItems, requirements[1])
    MainOrderCreatorLuckyOrder.LuckRandomRemoveCode(thirdAvailableItems, requirements[1])
    if 0 < #secondAvailableItems then
      table.insert(requirements, Table.ListWeightSelectOne(secondAvailableItems).Code)
      if 3 <= count then
        MainOrderCreatorLuckyOrder.LuckRandomRemoveCode(thirdAvailableItems, requirements[2])
        if 0 < #thirdAvailableItems then
          table.insert(requirements, Table.ListWeightSelectOne(thirdAvailableItems).Code)
        end
      end
    end
  end
  local avatarId = orderModel:GetAvatarId()
  local order = MainOrder.Create(orderModel, slot, nil, requirements, MainOrderType.Lucky, avatarId, true)
  if order ~= nil then
    if currentPoints ~= 0 then
      metaData:Set(DBColumnLuckyOrderPoints, "value", tostring(currentPoints - 1))
    else
      metaData:Set(DBColumnLuckyOrderPoints, "value", tostring(luckyOrderConfig.Point))
    end
    return order
  else
    if GameConfig.IsTestMode() then
      Log.Info("\229\183\178\230\156\137\230\163\139\229\173\144\228\184\141\230\187\161\232\182\179\230\157\161\228\187\182\239\188\140\230\131\138\229\150\156\232\174\162\229\141\149\231\148\159\230\136\144\229\164\177\232\180\165")
    end
    if currentPoints ~= 0 then
      metaData:Set(DBColumnLuckyOrderTimer, "value", tostring(GM.GameModel:GetServerTime()))
      metaData:Set(DBColumnLuckyOrderPoints, "value", "0")
    end
    return nil
  end
end

function MainOrderCreatorLuckyOrder.TryLuckyRandom(orderModel, slot, firstAvailableItems, secondAvailableItems, thirdAvailableItems)
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

function MainOrderCreatorLuckyOrder.LuckRandomRemoveCode(listItemCodes, Code)
  for i = #listItemCodes, 1, -1 do
    if listItemCodes[i].CurNum ~= nil and listItemCodes[i].Code == Code then
      listItemCodes[i].CurNum = listItemCodes[i].CurNum - 1
      if listItemCodes[i].CurNum == 0 then
        table.remove(listItemCodes, i)
      end
    end
  end
end
