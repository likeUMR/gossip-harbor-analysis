MathUtil = {}

function MathUtil.RandomN(n, selectCount)
  local cacheMap = {}
  local resultList = {}
  if n == 0 then
    return {}
  end
  for i = 1, selectCount do
    local selectIdx = MathUtil.Random(1, n - i + 1)
    for k, _ in pairs(cacheMap) do
      if k < selectIdx then
        selectIdx = selectIdx + 1
      end
    end
    while cacheMap[selectIdx] do
      selectIdx = selectIdx + 1
    end
    cacheMap[selectIdx] = true
    resultList[#resultList + 1] = selectIdx
  end
  return resultList
end

function MathUtil.Random(l, r)
  local fCurLeft = 0
  local fCurRight = 1
  if GameConfig.IsTestMode() then
    fCurLeft, fCurRight = GM.TestModel:GetMathRandomNumber()
  end
  Log.Assert(0 <= fCurLeft and fCurLeft < 1, "fCurLeft \229\191\133\233\161\187\229\156\168 [0, 1) \232\140\131\229\155\180\229\134\133")
  Log.Assert(fCurLeft <= fCurRight and fCurRight <= 1, "fCurRight \229\191\133\233\161\187\229\156\168 [fCurLeft, 1] \232\140\131\229\155\180\229\134\133")
  local CurRandom = math.random() * (fCurRight - fCurLeft) + fCurLeft
  if l == nil then
    return CurRandom
  elseif r == nil then
    if l % 1 ~= 0 then
      Log.Assert(false, "\233\154\143\230\156\186\230\149\176\228\184\141\229\133\129\232\174\184\228\188\160\229\133\165\229\184\166\230\156\137\229\176\143\230\149\176\231\130\185\231\154\132\230\149\176")
    end
    return math.floor(CurRandom * l) + 1
  else
    if l % 1 ~= 0 or r % 1 ~= 0 then
      Log.Assert(false, "\233\154\143\230\156\186\230\149\176\228\184\141\229\133\129\232\174\184\228\188\160\229\133\165\229\184\166\230\156\137\229\176\143\230\149\176\231\130\185\231\154\132\230\149\176")
    end
    return l + math.floor(CurRandom * (r - l + 1))
  end
end

function MathUtil.atan2(y, x)
  if 0 < x then
    return math.atan(y / x)
  elseif x < 0 then
    if 0 <= y then
      return math.atan(y / x) + math.pi
    else
      return math.atan(y / x) - math.pi
    end
  elseif 0 < y then
    return math.pi / 2
  elseif y < 0 then
    return -math.pi / 2
  else
    return 0
  end
end

function MathUtil.Clamp(value, upperBound, lowerBound)
  value = math.max(value, lowerBound)
  value = math.min(value, upperBound)
  return value
end

function MathUtil.IntPow(x, y)
  local result = 1
  for i = 1, y do
    result = result * x
  end
  return result
end

function MathUtil.Dec2BinStr(num)
  if num == 0 then
    return "0"
  end
  local result = {}
  while 0 < num do
    table.insert(result, 1, tostring(num & 1))
    num = num >> 1
  end
  return table.concat(result)
end

function MathUtil.IsPowerOfTwo(num)
  if type(num) ~= "number" or num <= 0 or math.floor(num) ~= num then
    return false
  end
  return num & num - 1 == 0
end

function MathUtil.ToRoman(num)
  if not num or type(num) ~= "number" or num <= 0 or 3999 < num then
    return nil, "\232\190\147\229\133\165\229\191\133\233\161\187\229\156\1681-3999\228\185\139\233\151\180"
  end
  local romanNumerals = {
    {1000, "M"},
    {900, "CM"},
    {500, "D"},
    {400, "CD"},
    {100, "C"},
    {90, "XC"},
    {50, "L"},
    {40, "XL"},
    {10, "X"},
    {9, "IX"},
    {5, "V"},
    {4, "IV"},
    {1, "I"}
  }
  local result = ""
  for _, pair in ipairs(romanNumerals) do
    local value, symbol = pair[1], pair[2]
    while num >= value do
      result = result .. symbol
      num = num - value
    end
  end
  return result
end

function MathUtil.IsVersionGreater(version, target)
  local function splitToNumbers(v)
    local parts = {}
    
    for num in string.gmatch(v, "%d+") do
      table.insert(parts, tonumber(num))
    end
    return parts
  end
  
  local vParts = splitToNumbers(version)
  local tParts = splitToNumbers(target)
  for i = 1, math.max(#vParts, #tParts) do
    local vNum = vParts[i] or 0
    local tNum = tParts[i] or 0
    if vNum > tNum then
      return true
    elseif vNum < tNum then
      return false
    end
  end
  return false
end

function MathUtil.FormatNumber(num)
  if type(num) ~= "number" then
    return num
  end
  local intPart, decimalPart = math.modf(num)
  local formatted = tostring(intPart)
  local k
  while true do
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
    if k == 0 then
      break
    end
  end
  if decimalPart ~= 0 then
    formatted = formatted .. string.format("%.2f", math.abs(decimalPart)):sub(2)
  end
  return formatted
end
