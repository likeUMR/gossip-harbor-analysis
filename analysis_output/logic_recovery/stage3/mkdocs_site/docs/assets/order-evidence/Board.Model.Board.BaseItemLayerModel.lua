BaseItemLayerModel = {}
BaseItemLayerModel.__index = BaseItemLayerModel

function BaseItemLayerModel:Init(boardModel)
  self.m_boardModel = boardModel
  self.m_items = boardModel:CreateMatrix()
end

function BaseItemLayerModel:GetItem(position)
  Log.Assert(false, "GetItem()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseItemLayerModel:SetItem(position, item)
  Log.Assert(false, "SetItem()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseItemLayerModel:_GetEmptyPositionCount()
  Log.Assert(false, "_GetEmptyPositionCount()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseItemLayerModel:HasEmptyPosition()
  return self:_GetEmptyPositionCount() > 0
end

function BaseItemLayerModel:FindEmptyPositionInSpreadOrder(centerPosition, openedPosition)
  local currentPosition = centerPosition
  local maxTiles = math.max(self.m_boardModel.HorizontalTiles, self.m_boardModel.VerticalTiles)
  for i = 1, maxTiles - 1 do
    currentPosition = BoardPosition.GetDirPosition(currentPosition, -1, -1)
    local stepLength = 2 * i
    for dir = 1, 4 do
      for _ = 1, stepLength do
        currentPosition = BoardPosition.GetDir4Position(currentPosition, dir)
        if self.m_boardModel:PositionIsValid(currentPosition) and self:GetItem(currentPosition) == nil then
          return currentPosition
        end
      end
    end
  end
  return openedPosition
end

function BaseItemLayerModel:FindEmptyPositionInSpreadOrderWithNum(centerPosition, openedPosition, num, bIncldeCenter)
  local target = {}
  local index = 0
  local currentPosition = centerPosition
  if bIncldeCenter and self.m_boardModel:PositionIsValid(currentPosition) and self:GetItem(currentPosition) == nil then
    table.insert(target, currentPosition)
    index = index + 1
    if num <= index then
      return target
    end
  end
  local maxTiles = math.max(self.m_boardModel.HorizontalTiles, self.m_boardModel.VerticalTiles)
  for i = 1, maxTiles - 1 do
    currentPosition = BoardPosition.GetDirPosition(currentPosition, -1, -1)
    local stepLength = 2 * i
    for dir = 1, 4 do
      for _ = 1, stepLength do
        currentPosition = BoardPosition.GetDir4Position(currentPosition, dir)
        if self.m_boardModel:PositionIsValid(currentPosition) and self:GetItem(currentPosition) == nil then
          table.insert(target, currentPosition)
          index = index + 1
          if num <= index then
            return target
          end
        end
      end
    end
  end
  return target
end

function BaseItemLayerModel:FindEmptyPositionInValidOrder()
  for position in self.m_boardModel:GetValidPositionIterator() do
    if self:GetItem(position) == nil then
      return position
    end
  end
  return nil
end

function BaseItemLayerModel:FindEmptyPositionInDiagonalOrderWithNum(num)
  local result = {}
  num = num or 1
  for position in self.m_boardModel:GetDiagonalValidPositionIterator() do
    if self:GetItem(position) == nil then
      result[#result + 1] = position
      if #result == num then
        return result
      end
    end
  end
  return result
end

function BaseItemLayerModel:FindEmptyPositionInCircleOrder(position, boardModel)
  for dir = 1, 8 do
    local tempPos = BoardPosition.GetDir8Position(position, dir)
    if self.m_boardModel:PositionIsValid(tempPos) and self:GetItem(tempPos) == nil then
      return tempPos
    end
  end
  return nil
end

function BaseItemLayerModel:FindRandomPosition()
  local positions = {}
  for position in self.m_boardModel:GetValidPositionIterator() do
    if self:GetItem(position) == nil then
      table.insert(positions, position)
    end
  end
  return Table.ListRandomSelectOne(positions)
end

function BaseItemLayerModel:GetAllItems()
  return Table.Empty
end
