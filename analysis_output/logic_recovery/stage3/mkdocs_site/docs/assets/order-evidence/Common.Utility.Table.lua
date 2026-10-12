Table = {}
Table.Empty = setmetatable({}, {
  __index = {},
  __newindex = function(t, k, v)
    Log.Error("cannot set in Table.Empty")
  end
})

function Table.Clear(t)
  for k, _ in pairs(t) do
    t[k] = nil
  end
  return t
end

function Table.ShallowCopy(source)
  if source == nil then
    return nil
  end
  local newTable = {}
  for k, v in pairs(source) do
    newTable[k] = v
  end
  return newTable
end

function Table.DeepCopy(object, ignoreMeta)
  local lookup_table = {}
  
  local function _copy(object)
    if type(object) ~= "table" then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end
    local new_table = {}
    lookup_table[object] = new_table
    for key, value in pairs(object) do
      new_table[_copy(key)] = _copy(value)
    end
    return ignoreMeta and new_table or setmetatable(new_table, getmetatable(object))
  end
  
  return _copy(object)
end

function Table.GetMapSize(map)
  local size = 0
  if map then
    for _, _ in pairs(map) do
      size = size + 1
    end
  end
  return size
end

function Table.ListAppend(to, from)
  table.move(from, 1, #from, #to + 1, to)
end

function Table.ListRemove(source, element)
  local count = #source
  for i = 1, count do
    if source[i] == element then
      table.remove(source, i)
      return true
    end
  end
  return false
end

function Table.ListContain(source, target)
  local count = #source
  for i = 1, count do
    if source[i] == target then
      return i
    end
  end
  return false
end

function Table.ListRandomSelectN(source, selectCount)
  if selectCount >= #source then
    return source
  end
  local results = {}
  for i = 1, selectCount do
    local index = MathUtil.Random(#source)
    table.insert(results, source[index])
    table.remove(source, index)
  end
  return results
end

function Table.ListRandomSelectOne(source)
  if #source == 0 then
    return nil
  end
  local randomIndex = MathUtil.Random(#source)
  return source[randomIndex]
end

function Table.ListWeightSelectOne(source, weightKey)
  weightKey = weightKey or "Weight"
  local sumWeight = 0
  for _, item in ipairs(source) do
    sumWeight = sumWeight + item[weightKey]
  end
  if sumWeight <= 0 then
    Log.Assert(false, "\233\148\153\232\175\175\239\188\140\233\128\137\230\139\169\230\163\139\229\173\144\231\154\132\230\137\128\230\156\137\230\157\131\233\135\141 <= 0 \232\175\183\230\163\128\230\159\165 ")
  end
  local randomIndex = MathUtil.Random(sumWeight)
  for _, item in ipairs(source) do
    if randomIndex <= item[weightKey] then
      return item
    else
      randomIndex = randomIndex - item[weightKey]
    end
  end
  if sumWeight <= 0 and 0 < #source then
    return source[1]
  end
  Log.Assert(false, "Table.ListWeightSelectOne")
end

function Table.ListRemoveDuplicate(list)
  local map = {}
  local new = {}
  local value
  local count = #list
  for i = 1, count do
    value = list[i]
    if not map[value] then
      map[value] = true
      new[#new + 1] = value
    end
  end
  return new
end

function Table.Contain(source, target)
  for _, value in pairs(source) do
    if value == target then
      return true
    end
  end
  return false
end

function Table.GetIndex(list, target)
  local count = #list
  for i = 1, count do
    if list[i] == target then
      return i
    end
  end
  return 0
end

function Table.GetIndexWithFilter(list, filter)
  local count = #list
  for i = 1, count do
    if filter(list[i]) then
      return i
    end
  end
  return 0
end

function Table.GetKey(map, target)
  for key, value in pairs(map) do
    if value == target then
      return key
    end
  end
  return nil
end

function Table.MapSize(source)
  local size = 0
  for k, v in pairs(source) do
    size = size + 1
  end
  return size
end

function Table.Select(source, filter)
  local result = {}
  for _, value in pairs(source) do
    if filter(value) then
      table.insert(result, value)
    end
  end
  return result
end

function Table.ListSelect(source, filter)
  local result = {}
  local count = #source
  for i = 1, count do
    local value = source[i]
    if filter(value) then
      table.insert(result, value)
    end
  end
  return result
end

function Table.Foreach(source, func)
  for _, value in pairs(source) do
    func(value)
  end
end

function Table.ListForeach(source, func)
  local count = #source
  for i = 1, count do
    func(i, source[i])
  end
end

function Table.GetKeys(source)
  local keys = {}
  local count = 0
  for key, _ in pairs(source) do
    count = count + 1
    keys[count] = key
  end
  return keys
end

function Table.GetValueList(source)
  local values = {}
  local count = 0
  for _, value in pairs(source) do
    count = count + 1
    values[count] = value
  end
  return values
end

function Table.IsEmpty(source)
  return IsNil(source) or type(source) ~= "table" or next(source) == nil
end

function Table.Reverse(source)
  local list = {}
  for i = 1, #source do
    list[#source - i + 1] = source[i]
  end
  return list
end

function Table.ListRep(ele, repCount, deepCopy)
  local list = {}
  for i = 1, repCount do
    list[#list + 1] = deepCopy and Table.DeepCopy(ele) or ele
  end
  return list
end

function Table.ListAlwaysRandomSelectN(source, selectCount)
  local result = {}
  if Table.IsEmpty(source) then
    return result
  end
  local tb = Table.DeepCopy(source)
  for i = 1, math.min(#tb, selectCount) do
    local index = MathUtil.Random(#tb)
    result[#result + 1] = tb[index]
    table.remove(tb, index)
  end
  return result
end

function Table.BinarySearch(searchTb, tarVal, minKey, maxKey)
  if Table.IsEmpty(searchTb) then
    return nil
  end
  local left = 1
  local right = #searchTb
  local mid
  while left <= right do
    mid = (left + right) // 2
    if tarVal < searchTb[mid][minKey] then
      right = mid - 1
    elseif tarVal > searchTb[mid][maxKey] then
      left = mid + 1
    else
      return mid
    end
  end
  return nil
end

function Table.ShuffleTable(list)
  if list == nil then
    return
  end
  local n = #list
  while 1 < n do
    local k = math.random(n)
    list[n], list[k] = list[k], list[n]
    n = n - 1
  end
end
