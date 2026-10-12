ItemModelFactory = {}

function ItemModelFactory.CreateWithData(boardModel, data)
  if data.codeStr == nil or type(data.codeStr) ~= "string" then
    Log.Error("ItemModelFactory.CreateWithData codeStr is " .. tostring(data.codeStr) .. "code is " .. tostring(data.code))
  end
  local item = ItemModelFactory.CreateWithCode(boardModel, nil, data.codeStr, false)
  if item == nil then
    return
  end
  item.m_id = data.id
  local itemSpread = item:GetComponent(ItemSpread)
  if itemSpread ~= nil then
    itemSpread.m_state = data.spreadState
    itemSpread.m_startTimer = data.spreadStartTimer
    itemSpread.m_itemRestNumber = data.spreadItemRestNumber
    itemSpread.m_storageRestNumber = data.spreadStorageRestNumber
    itemSpread.m_spreadCount = data.spreadCount or 0
    itemSpread.m_codeWeightPairs = ItemUtility.StringToCodeWeightPairs(data.spreadCodeWeightPairs)
  end
  local itemTransform = item:GetComponent(ItemTransform)
  if itemTransform ~= nil then
    itemTransform.m_startTimer = data.transformStartTimer
  end
  local itemSwallow = item:GetComponent(ItemSwallow)
  if itemSwallow ~= nil then
    itemSwallow.m_swallowInfo = ItemSwallow.StringToSwallowInfo(data.swallowInfo)
  end
  local itemBubble = item:GetComponent(ItemBubble)
  if itemBubble ~= nil then
    itemBubble.m_startTimer = data.bubbleStartTimer
  end
  local itemPropertyBubble = item:GetComponent(ItemPropertyBubble)
  if itemPropertyBubble ~= nil then
    itemPropertyBubble.m_startTimer = data.bubbleStartTimer
  end
  local itemAccelerate = item:GetComponent(ItemAccelerate)
  if itemAccelerate ~= nil then
    itemAccelerate.m_startTimer = data.accelerateStartTimer
  end
  local itemAccelerateTime = item:GetComponent(ItemAccelerateTime)
  if itemAccelerateTime ~= nil then
    itemAccelerateTime.m_time = data.accelerateTime or 0
    itemAccelerateTime.m_lastUpdateTime = data.accelerateLastUpdateTime
  end
  local itemSplit = item:GetComponent(ItemSplit)
  if itemSplit ~= nil then
    itemSplit.m_count = data.splitUseCount
  end
  return item
end

function ItemModelFactory.CreateWithCode(boardModel, position, code, needUnlockType)
  local itemModel = ItemModelFactory._CreateWithCode(boardModel, position, code, needUnlockType)
  if itemModel ~= nil and boardModel ~= nil and boardModel.Freefall then
    local itemFall = ItemFall.Create(boardModel)
    itemModel:AddComponent(itemFall)
  end
  return itemModel
end

function ItemModelFactory._CreateWithCode(boardModel, position, code, needUnlockType)
  local numberCode = tonumber(code)
  if numberCode ~= nil then
    if numberCode == 0 then
      return nil
    end
    if numberCode > ItemCodeOffset.PaperBox and numberCode < ItemCodeOffset.Cobweb then
      local innerCode = numberCode - ItemCodeOffset.PaperBox + ItemCodeOffset.Cobweb
      return ItemModelFactory._CreatePaperBox(boardModel, position, tostring(innerCode), code)
    elseif numberCode > ItemCodeOffset.Cobweb and numberCode < ItemCodeOffset.Bubble then
      local innerCode = numberCode - ItemCodeOffset.Cobweb
      return ItemModelFactory._CreateCobweb(boardModel, position, tostring(innerCode), code)
    elseif numberCode > ItemCodeOffset.Bubble and numberCode < ItemCodeOffset.PlainPaperBox then
      local innerCode = numberCode - ItemCodeOffset.Bubble
      return ItemModelFactory._CreateBubble(boardModel, position, tostring(innerCode), code)
    elseif numberCode > ItemCodeOffset.PlainPaperBox then
      local innerCode = numberCode - ItemCodeOffset.PlainPaperBox
      return ItemModelFactory._CreatePaperBox(boardModel, position, tostring(innerCode), code)
    end
  end
  if ItemModelFactory.s_codePrefixCreatorMap == nil then
    ItemModelFactory.s_codePrefixCreatorMap = {
      [ItemCodePrefix.PaperBox] = ItemModelFactory._CreatePaperBox,
      [ItemCodePrefix.Cobweb] = ItemModelFactory._CreateCobweb,
      [ItemCodePrefix.Bubble] = function(boardModel, position, innerCode, originalCode)
        return ItemModelFactory._CreateBubble(boardModel, position, innerCode, originalCode, false)
      end,
      [ItemCodePrefix.InstantBubble] = function(boardModel, position, innerCode, originalCode)
        return ItemModelFactory._CreateBubble(boardModel, position, innerCode, originalCode, true)
      end,
      [ItemCodePrefix.Temp] = ItemModelFactory._CreateTemp,
      [ItemCodePrefix.RewardBubble] = ItemModelFactory._CreateRewardBubble,
      [ItemCodePrefix.Fog] = ItemModelFactory._CreateFog,
      [ItemCodePrefix.PropertyBubble] = ItemModelFactory._CreatePropertyBubble,
      [ItemCodePrefix.Locked] = ItemModelFactory._CreateLocked
    }
  end
  for prefix, creator in pairs(ItemModelFactory.s_codePrefixCreatorMap) do
    if StringUtil.StartWith(code, prefix) then
      local innerCode = string.sub(code, string.len(prefix) + 1)
      return creator(boardModel, position, innerCode, code)
    end
  end
  return ItemModelFactory._CreateWithType(boardModel, position, code, needUnlockType)
end

function ItemModelFactory._CreatePaperBox(boardModel, position, innerCode, originalCode)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.PaperBox)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local itemPaperBox = ItemPaperBox.Create(innerCode)
  itemModel:AddComponent(itemPaperBox)
  return itemModel
end

function ItemModelFactory._CreateCobweb(boardModel, position, innerCode, originalCode)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.Cobweb)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local itemObstacleClear
  if StringUtil.StartWith(innerCode, ItemCodePrefix.ObstacleClear) then
    itemObstacleClear = ItemObstacleClear.Create()
    itemModel:AddComponent(itemObstacleClear)
  end
  local itemCobweb = ItemCobweb.Create(innerCode)
  itemModel:AddComponent(itemCobweb)
  return itemModel
end

function ItemModelFactory._CreateBubble(boardModel, position, innerCode, originalCode, instant)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.Bubble)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local itemBubble = ItemBubble.Create(innerCode, instant)
  itemModel:AddComponent(itemBubble)
  return itemModel
end

function ItemModelFactory._CreateTemp(boardModel, position, innerCode, originalCode)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.Temp)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local itemTemp = ItemTemp.Create(innerCode)
  itemModel:AddComponent(itemTemp)
  return itemModel
end

function ItemModelFactory._CreateRewardBubble(boardModel, position, innerCode, originalCode)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.RewardBubble)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local rewardStr = innerCode .. "-1"
  local itemCollectable = ItemCollectable.Create({rewardStr})
  itemModel:AddComponent(itemCollectable)
  return itemModel
end

function ItemModelFactory._CreatePropertyBubble(boardModel, position, innerCode, originalCode)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.PropertyBubble)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local i = StringUtil.rFindChar(innerCode, "-")
  local price = string.sub(innerCode, i + 1)
  local rewardStr = string.sub(innerCode, 1, i - 1)
  local itemCollectable = ItemCollectable.Create({rewardStr})
  itemModel:AddComponent(itemCollectable)
  local itemPropertyBubble = ItemPropertyBubble.Create({rewardStr}, price)
  itemModel:AddComponent(itemPropertyBubble)
  return itemModel
end

function ItemModelFactory._CreateFog(boardModel, position, innerCode, originalCode)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.Fog)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local itemFog = ItemFog.Create(innerCode)
  itemModel:AddComponent(itemFog)
  return itemModel
end

function ItemModelFactory._CreateLocked(boardModel, position, innerCode, originalCode)
  local itemConfig = GM.ItemDataModel:GetModelConfig(ItemType.Locked)
  local itemModel = ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local itemLocked = ItemLocked.Create(innerCode)
  itemModel:AddComponent(itemLocked)
  return itemModel
end

function ItemModelFactory.CreateWithType(boardModel, position, type, needUnlockType)
  local itemModel = ItemModelFactory._CreateWithType(boardModel, position, type, needUnlockType)
  if itemModel ~= nil and boardModel.Freefall then
    local itemFall = ItemFall.Create(boardModel)
    itemModel:AddComponent(itemFall)
  end
  return itemModel
end

function ItemModelFactory._CreateWithType(boardModel, position, type, needUnlockType)
  local config = GM.ItemDataModel:GetModelConfig(type, true)
  if not config then
    return
  end
  if needUnlockType then
    GM.ItemDataModel:SetUnlocked(type)
  end
  local sourceType = type
  local state = 1
  local stateType = GM.ItemDataModel:GetStateCollectionStateType(type, 1)
  if stateType == nil and config.StateCollectionType ~= nil then
    sourceType = config.StateCollectionType
    state = config.StateCollectionIndex
    stateType = type
  end
  local sourceItemConfig = GM.ItemDataModel:GetModelConfig(sourceType, true)
  if not sourceItemConfig then
    GM.BIManager:LogErrorInfo(EBIType.StateCollectionItemCreateError, "sourceItemConfig is nil")
    return
  end
  local itemModel = ItemModel.Create(boardModel, position, sourceItemConfig, stateType or type)
  local itemConfig = sourceItemConfig
  if stateType ~= nil then
    itemConfig = GM.ItemDataModel:GetModelConfig(stateType)
    local itemStateCollection = ItemStateCollection.Create(state)
    itemModel:AddComponent(itemStateCollection)
  end
  if itemConfig.Spread_Auto ~= nil then
    local itemSpread = ItemSpread.Create(itemConfig)
    itemModel:AddComponent(itemSpread)
  end
  if itemConfig.Transform_Weight ~= nil then
    local itemTransform = ItemTransform.Create(itemConfig)
    itemModel:AddComponent(itemTransform)
  end
  if itemConfig.Swallow_Weight1 ~= nil then
    local itemSwallow = ItemSwallow.Create(itemConfig)
    itemModel:AddComponent(itemSwallow)
  end
  if itemConfig.CollectRewards ~= nil then
    local itemCollectable = ItemCollectable.Create(itemConfig.CollectRewards)
    itemModel:AddComponent(itemCollectable)
  end
  if itemConfig.Choices ~= nil then
    local itemChoose = ItemChoose.Create(itemConfig.Choices)
    itemModel:AddComponent(itemChoose)
  end
  if itemConfig.CommandOperation ~= nil then
    local itemCommand = ItemCommand.Create(itemConfig.CommandOperation)
    itemModel:AddComponent(itemCommand)
  end
  if itemConfig.AccelerateDuration ~= nil then
    local itemAccelerate = ItemAccelerate.Create(itemConfig.AccelerateDuration)
    itemModel:AddComponent(itemAccelerate)
  end
  if itemConfig.SpecialType == ItemSpecialType.LevelDown then
    local itemSplit = ItemSplit.Create()
    itemModel:AddComponent(itemSplit)
  end
  if itemConfig.Dig_MaxLevel ~= nil then
    local itemDig = ItemDig.Create(itemConfig)
    itemModel:AddComponent(itemDig)
  end
  if itemConfig.Portal ~= nil then
    local itemPortal = ItemPortal.Create()
    itemModel:AddComponent(itemPortal)
  end
  if itemConfig.Clear_ClearNum ~= nil then
    local itemClearTool = ItemClearTool.Create(itemConfig)
    itemModel:AddComponent(itemClearTool)
  end
  if itemModel:GetComponent(ItemSpread) ~= nil or itemModel:GetComponent(ItemTransform) ~= nil then
    local itemAccelerateTime = ItemAccelerateTime.Create()
    itemModel:AddComponent(itemAccelerateTime)
  end
  if boardModel and boardModel.IsGeneratorFactoryItem and boardModel:IsGeneratorFactoryItem(itemConfig.Type) then
    local comp = ItemGeneratorFactory.Create()
    itemModel:AddComponent(comp)
  end
  return itemModel
end

function ItemModelFactory.GetCodeAndWeightPairs(configArray)
  local ret = {}
  for _, str in ipairs(configArray) do
    local pairs = StringUtil.Split(str, "-")
    table.insert(ret, {
      Code = pairs[1],
      Weight = tonumber(pairs[2])
    })
  end
  return ret
end

function ItemModelFactory.GetInnerType(code)
  if tonumber(code) ~= nil then
    return tostring(tonumber(code) % 1000000)
  end
  local index = StringUtil.rFindChar(code, "#")
  if index then
    return string.sub(code, index + 1)
  else
    return code
  end
end

function ItemModelFactory.GetInnerTypeRecursive(code)
  local hasInnerCode = false
  while true do
    local innerCode = ItemModelFactory.GetInnerType(code)
    if innerCode == code then
      break
    end
    code = innerCode
    hasInnerCode = true
  end
  if hasInnerCode then
    return code
  end
end

function ItemModelFactory.GetCodePrefixTargetType(code)
  if ItemModelFactory.s_codePrefixItemTypeMap == nil then
    ItemModelFactory.s_codePrefixItemTypeMap = {
      [ItemCodePrefix.PaperBox] = ItemType.PaperBox,
      [ItemCodePrefix.Cobweb] = ItemType.Cobweb,
      [ItemCodePrefix.Bubble] = ItemType.Bubble,
      [ItemCodePrefix.InstantBubble] = ItemType.Bubble,
      [ItemCodePrefix.Temp] = ItemType.Temp,
      [ItemCodePrefix.RewardBubble] = ItemType.RewardBubble,
      [ItemCodePrefix.Fog] = ItemType.Fog,
      [ItemCodePrefix.PropertyBubble] = ItemType.PropertyBubble,
      [ItemCodePrefix.Locked] = ItemType.Locked
    }
  end
  for prefix, type in pairs(ItemModelFactory.s_codePrefixItemTypeMap) do
    if StringUtil.StartWith(code, prefix) then
      return type
    end
  end
end
