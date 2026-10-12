ItemFixedSwallowModel = {}
ItemFixedSwallowModel.__index = ItemFixedSwallowModel

function ItemFixedSwallowModel:Init()
  self.m_dbTable = GM.DBTableManager:GetTable(EDBTableConfigs.FixedSwallow)
end

function ItemFixedSwallowModel:GenerateTargetCode(type, swallowWeight, index)
  local sequence = self.m_dbTable:GetValue(type, "sequence" .. index)
  local codeWeightPairsString = ItemUtility.CodeWeightPairsToString(swallowWeight)
  if StringUtil.IsNilOrEmpty(sequence) or codeWeightPairsString ~= self.m_dbTable:GetValue(type, "pairs" .. index) then
    sequence = self:_GenerateSequence(swallowWeight)
    self.m_dbTable:Set(type, "pairs" .. index, codeWeightPairsString)
  end
  local selectedIndex
  local startIndex, endIndex = string.find(sequence, ",", 1, true)
  if startIndex == nil then
    selectedIndex = tonumber(sequence)
    sequence = nil
  else
    selectedIndex = tonumber(string.sub(sequence, 1, startIndex - 1))
    sequence = string.sub(sequence, endIndex + 1)
  end
  self.m_dbTable:Set(type, "sequence" .. index, sequence)
  for _, item in ipairs(swallowWeight) do
    if selectedIndex <= item.Weight then
      return item.Code
    else
      selectedIndex = selectedIndex - item.Weight
    end
  end
  Log.Assert(false, "\233\154\143\230\156\186\229\144\158\229\153\172\229\186\143\229\136\151\229\143\150\229\135\186\229\188\130\229\184\184")
end

function ItemFixedSwallowModel:_GenerateSequence(codeWeightPairs)
  local sumWeight = 0
  for _, item in ipairs(codeWeightPairs) do
    sumWeight = sumWeight + item.Weight
  end
  local array = {}
  for i = 1, sumWeight do
    array[i] = i
  end
  for i = sumWeight, 1, -1 do
    local index = MathUtil.Random(i)
    local temp = array[index]
    array[index] = array[i]
    array[i] = temp
  end
  local sequence
  for _, number in ipairs(array) do
    if sequence == nil then
      sequence = tostring(number)
    else
      sequence = sequence .. "," .. number
    end
  end
  return sequence
end
