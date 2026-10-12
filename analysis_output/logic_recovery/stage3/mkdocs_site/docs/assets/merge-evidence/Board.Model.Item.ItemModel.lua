ItemEventType = {SetPosition = 1}
ItemModel = {}
ItemModel.__index = ItemModel

function ItemModel.Create(boardModel, position, itemConfig, originalCode)
  local itemModel = setmetatable({}, ItemModel)
  itemModel:_Init(boardModel, position, itemConfig, originalCode)
  return itemModel
end

function ItemModel:_Init(boardModel, position, itemConfig, originalCode)
  self.event = PairEvent.Create(self)
  self.m_components = {}
  self.m_boardModel = boardModel
  self.m_position = position
  self.m_type = itemConfig.Type
  self.m_mergedType = itemConfig.MergedType
  self.m_bubbleChance = itemConfig.BubbleChance
  self.m_sellingPrice = itemConfig.SellingPrice
  self.m_code = originalCode
  self.m_rare = itemConfig.Rare
  self.m_specialType = itemConfig.SpecialType
  for specialType, configKey in pairs(ItemSpecialType2ConfigKey) do
    if itemConfig[configKey] == 1 then
      if self.m_mapSpecialTypeTarget == nil then
        self.m_mapSpecialTypeTarget = {}
      end
      self.m_mapSpecialTypeTarget[specialType] = true
    end
  end
  self.m_updateComponents = {}
  self.b_needUpdate = false
end

function ItemModel:AddComponent(component)
  component:SetItemModel(self)
  local componentClass = getmetatable(component)
  self.m_components[componentClass] = component
  if component.Update ~= nil then
    self.m_updateComponents[componentClass] = component
    self.b_needUpdate = true
  end
end

function ItemModel:GetComponent(type)
  return self.m_components[type]
end

function ItemModel:GetComponents()
  return self.m_components
end

function ItemModel:DispatchComponentEvent(functionName, ...)
  for _, component in pairs(self.m_components) do
    if component[functionName] ~= nil then
      component[functionName](component, ...)
    end
  end
end

function ItemModel:GetBoardModel()
  return self.m_boardModel
end

function ItemModel:GetPosition()
  return self.m_position
end

function ItemModel:GetLocalPosition()
  local zIndex = self.m_boardModel.HorizontalTiles * self.m_boardModel.VerticalTiles - self.m_boardModel.HorizontalTiles * (self.m_position:GetY() - 1) - self.m_position:GetX() + 1
  return self.m_boardModel:ToLocalPositionSetZ(self.m_position, zIndex * 10)
end

function ItemModel:GetLocalPositionVector2()
  return self.m_boardModel:ToLocalPosition(self.m_position)
end

function ItemModel:GetLocalPositionOverrideZ(z)
  local pos = self:GetLocalPosition()
  pos.z = z
  return pos
end

function ItemModel:IsInBoard()
  return self.m_boardModel:GetItem(self.m_position) == self
end

function ItemModel:SetPosition(position)
  self.m_position = position
  self.event:Call(ItemEventType.SetPosition, position)
end

function ItemModel:SetPositionWithoutAnim(position)
  self.m_position = position
end

function ItemModel:GetType()
  return self.m_type
end

function ItemModel:GetMergedType()
  return self.m_mergedType
end

function ItemModel:GetBubbleChance()
  return self.m_bubbleChance
end

function ItemModel:GetSellingPrice()
  return self.m_sellingPrice
end

function ItemModel:GetCode()
  return self.m_code
end

function ItemModel:GetId()
  return self.m_id
end

function ItemModel:SetId(id)
  self.m_id = id
end

function ItemModel:IsRare()
  return self.m_rare == 1
end

function ItemModel:IsShowCollectEffect()
  return self:GetComponent(ItemCollectable) ~= nil and GM.ItemDataModel:IsMaxLevelItemType(self.m_type) and not self:GetComponent(ItemPropertyBubble)
end

function ItemModel:GetSpecialType()
  return self.m_specialType
end

function ItemModel:CanSpecialTypeAffect(specialType)
  return specialType ~= nil and self:_IsSpecialTypeSatisfied(specialType)
end

function ItemModel:_IsSpecialTypeSatisfied(specialType)
  if self:GetSpecialType() == specialType and specialType == ItemSpecialType.LevelDown then
    return true
  end
  if self.m_mapSpecialTypeTarget == nil or not self.m_mapSpecialTypeTarget[specialType] then
    return false
  end
  if specialType == ItemSpecialType.LevelDown then
    return not self.m_boardModel:IsBoardFull()
  end
  return true
end

function ItemModel:DispatchComponentUpdateEvent(dt)
  if not self.b_needUpdate then
    return
  end
  for _, component in pairs(self.m_updateComponents) do
    component.Update(component, dt)
  end
end

function ItemModel:GetSpriteName()
  local spriteName
  local itemCobweb = self:GetComponent(ItemCobweb)
  if itemCobweb ~= nil then
    spriteName = GM.ItemDataModel:GetSpriteName(itemCobweb:GetInnerItemCode())
  else
    spriteName = GM.ItemDataModel:GetSpriteName(self:GetType())
  end
  local itemBubble = self:GetComponent(ItemBubble)
  if itemBubble ~= nil then
    spriteName = GM.ItemDataModel:GetSpriteName(itemBubble:GetInnerItemCode())
  end
  return spriteName
end
