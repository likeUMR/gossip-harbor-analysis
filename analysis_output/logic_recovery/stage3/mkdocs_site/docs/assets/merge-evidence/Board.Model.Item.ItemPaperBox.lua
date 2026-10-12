ItemPaperBox = setmetatable({}, BaseItemComponent)
ItemPaperBox.__index = ItemPaperBox

function ItemPaperBox.Create(innerItemCode)
  local itemPaperBox = setmetatable({}, ItemPaperBox)
  itemPaperBox:Init(innerItemCode)
  return itemPaperBox
end

function ItemPaperBox:Init(innerItemCode)
  self.m_innerItemCode = innerItemCode
end

function ItemPaperBox:GetInnerItemCode()
  return self.m_innerItemCode
end

function ItemPaperBox:Try2Unlock()
  local boardModel = self.m_itemModel:GetBoardModel()
  if boardModel:GetItemPaperBoxUnLockLevel(self.m_itemModel) > 0 and not boardModel:IsItemPaperBoxLocked(self.m_itemModel) then
    self.m_itemModel:GetBoardModel():CollapseItem(self.m_itemModel:GetPosition(), true)
  end
end

function ItemPaperBox:OnShock()
  if not self.m_itemModel:GetBoardModel():IsItemPaperBoxLocked(self.m_itemModel) then
    self.m_itemModel:GetBoardModel():CollapseItem(self.m_itemModel:GetPosition())
  end
end
