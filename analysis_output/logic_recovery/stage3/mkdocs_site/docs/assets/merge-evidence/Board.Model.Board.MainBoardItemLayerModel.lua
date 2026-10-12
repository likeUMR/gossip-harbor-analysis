MainBoardItemLayerModel = setmetatable({}, BaseItemLayerModel)
MainBoardItemLayerModel.__index = MainBoardItemLayerModel

function MainBoardItemLayerModel.Create(boardModel, dbTable, itemManager, fileName)
  local itemLayerModel = setmetatable({}, MainBoardItemLayerModel)
  itemLayerModel:Init(boardModel, dbTable, itemManager, fileName)
  return itemLayerModel
end

function MainBoardItemLayerModel:Init(boardModel, dbTable, itemManager, fileName)
  BaseItemLayerModel.Init(self, boardModel)
  self.m_dbTable = dbTable
  self.m_itemManager = itemManager
  self.m_fileName = fileName
  self.m_mapItems = {}
end

function MainBoardItemLayerModel:LoadFileConfig()
  self.m_initCodeMap = require("Data.Config." .. self.m_fileName)
end

function MainBoardItemLayerModel:OnSyncDataFinished()
  self.m_emptyCount = self.m_boardModel.HorizontalTiles * self.m_boardModel.VerticalTiles
  if self.m_dbTable:IsEmpty() and self.m_itemManager:IsEmpty() then
    for position in self.m_boardModel:GetValidPositionIterator() do
      local code = self.m_initCodeMap[position:GetY()][position:GetX()]
      local item = ItemModelFactory.CreateWithCode(self.m_boardModel, position, code, true)
      if item ~= nil then
        self.m_itemManager:SetItem(item)
        self:SetItem(position, item)
      end
    end
  else
    local posArr = {}
    for key, data in pairs(self.m_dbTable:GetReadOnlyValues()) do
      local item = self.m_itemManager:GetItem(data.itemId)
      if item then
        local count = 1
        for p in string.gmatch(key, "([^_]+)") do
          posArr[count] = tonumber(p)
          count = count + 1
        end
        local pos = BoardPosition.Create(posArr[1], posArr[2])
        self.m_items:SetValueOnPosition(pos, data.itemId)
        item:SetPosition(pos)
        self:_OnItemChange(item, true)
      else
        GM.BIManager:LogAction(EBIType.ItemNotFound, "SILM itemId:" .. tostring(data.itemId))
        self.m_dbTable:Remove(key)
      end
    end
  end
end

function MainBoardItemLayerModel:_OnItemChange(itemModel, addItem)
  self.m_emptyCount = self.m_emptyCount + (addItem and -1 or 1)
  if addItem then
    self.m_mapItems[itemModel] = true
  else
    self.m_mapItems[itemModel] = nil
  end
end

function MainBoardItemLayerModel:GetItem(position)
  if position == nil or not self.m_boardModel:PositionIsValid(position) then
    return nil
  end
  local itemId = self.m_items:GetValueOnPosition(position)
  return self.m_itemManager:GetItem(itemId)
end

function MainBoardItemLayerModel:FilterItems(filter)
  local results = {}
  for position in self.m_boardModel:GetValidPositionIterator() do
    local itemModel = self:GetItem(position)
    if itemModel ~= nil and filter(itemModel) then
      table.insert(results, itemModel)
    end
  end
  return results
end

function MainBoardItemLayerModel:SetItem(position, item)
  if not self.m_boardModel:PositionIsValid(position) then
    return
  end
  local originalItem = self:GetItem(position)
  if originalItem ~= nil then
    self:_OnItemChange(originalItem, false)
  end
  local itemId = item and item:GetId()
  if itemId == nil then
    self.m_dbTable:Remove(position:GetKey())
  else
    self.m_dbTable:Set(position:GetKey(), "itemId", itemId)
  end
  self.m_items:SetValueOnPosition(position, itemId)
  if item ~= nil then
    self:_OnItemChange(item, true)
  end
end

function MainBoardItemLayerModel:_GetEmptyPositionCount()
  return self.m_emptyCount
end

function MainBoardItemLayerModel:GetAllItems()
  return self.m_mapItems
end
