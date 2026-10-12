BoardPosition = {}
BoardPosition.__index = BoardPosition

function BoardPosition:Init(x, y, key)
  self.m_x = x
  self.m_y = y
  self.m_key = key
end

function BoardPosition:GetX()
  return self.m_x
end

function BoardPosition:GetY()
  return self.m_y
end

function BoardPosition:GetKey()
  return self.m_key
end

function BoardPosition.__eq(a, b)
  if getmetatable(a) == BoardPosition and getmetatable(b) == BoardPosition then
    return a.m_x == b.m_x and a.m_y == b.m_y
  else
    return false
  end
end

local BoardPositionStringCache = {}

function BoardPosition.__tostring(position)
  if BoardPositionStringCache[position] == nil then
    BoardPositionStringCache[position] = "(x:" .. tostring(position:GetX()) .. ",y:" .. tostring(position:GetY()) .. ")"
  end
  return BoardPositionStringCache[position]
end

local BoardPositionCache = {}
local BoardPositionKeyCache = {}

function BoardPosition.Create(x, y)
  if BoardPositionKeyCache[x] == nil then
    BoardPositionKeyCache[x] = {}
  end
  if BoardPositionKeyCache[x][y] == nil then
    BoardPositionKeyCache[x][y] = x .. "_" .. y
  end
  local key = BoardPositionKeyCache[x][y]
  if BoardPositionCache[key] == nil then
    local pos = setmetatable({}, BoardPosition)
    pos:Init(x, y, key)
    BoardPositionCache[key] = pos
  end
  return BoardPositionCache[key]
end

BoardPosition.Dir4OffsetX = {
  1,
  0,
  -1,
  0
}
BoardPosition.Dir4OffsetY = {
  0,
  1,
  0,
  -1
}
BoardPosition.Dir8OffsetX = {
  0,
  1,
  1,
  1,
  0,
  -1,
  -1,
  -1
}
BoardPosition.Dir8OffsetY = {
  -1,
  -1,
  0,
  1,
  1,
  1,
  0,
  -1
}

function BoardPosition.GetDirPosition(position, x, y)
  return BoardPosition.Create(position.m_x + x, position.m_y + y)
end

function BoardPosition.GetDir8Position(position, dir)
  return BoardPosition.GetDirPosition(position, BoardPosition.Dir8OffsetX[dir], BoardPosition.Dir8OffsetY[dir])
end

function BoardPosition.GetDir4Position(position, dir)
  return BoardPosition.GetDirPosition(position, BoardPosition.Dir4OffsetX[dir], BoardPosition.Dir4OffsetY[dir])
end
