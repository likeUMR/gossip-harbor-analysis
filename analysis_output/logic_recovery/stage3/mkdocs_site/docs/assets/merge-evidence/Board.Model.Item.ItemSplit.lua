ItemSplit = setmetatable({}, BaseItemComponent)
ItemSplit.__index = ItemSplit
local DEFAULT_COUNT = 1

function ItemSplit.Create(count)
  local itemSplit = setmetatable({}, ItemSplit)
  itemSplit:Init(count)
  return itemSplit
end

function ItemSplit:Init(count)
  count = count or DEFAULT_COUNT
  self.m_count = count
end

function ItemSplit:CostSplitUseCount()
  self.m_count = self.m_count - 1
  self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
end

function ItemSplit:HasLeftSplitUseCount()
  return self.m_count > 0
end

function ItemSplit:SetSplitUseCount(count)
  self.m_count = count
  self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
end

function ItemSplit:GetSplitUseCount()
  return self.m_count
end
