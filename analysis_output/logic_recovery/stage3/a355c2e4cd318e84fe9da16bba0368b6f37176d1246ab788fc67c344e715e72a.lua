ItemGeneratorFactory = setmetatable({}, BaseItemComponent)
ItemGeneratorFactory.__index = ItemGeneratorFactory

function ItemGeneratorFactory.Create()
  local comp = setmetatable({}, ItemGeneratorFactory)
  comp:Init()
  return comp
end

function ItemGeneratorFactory:Init()
end

function ItemGeneratorFactory:OnTap()
  local boardModel = self.m_itemModel:GetBoardModel()
  if not boardModel:IsGeneratorFactoryOpen() then
    return
  end
  local type = self.m_itemModel:GetType()
  boardModel:StoreFactoryItem(type)
  boardModel:RemoveItem(self.m_itemModel)
  boardModel.event:Call(BoardEventType.Add2GeneratorFactory, {
    Source = self.m_itemModel
  })
  EventDispatcher.DispatchEvent(EEventType.GeneratorFactoryTabBoardItem)
end

function ItemGeneratorFactory:IsGeneratorFactoryOpen()
  return self.m_itemModel:GetBoardModel():IsGeneratorFactoryOpen()
end

function ItemGeneratorFactory:GetBoardInfoDescriptionText()
  return GM.GameTextModel:GetText("item_tap_collect_desc")
end
