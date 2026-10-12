local input_path = assert(arg[1], "input bytecode path is required")

UIPrefabConfigName = setmetatable({}, { __index = function(_, key) return key end })
ImageFileConfigName = setmetatable({}, { __index = function(_, key) return key end })
AudioFileConfigName = setmetatable({}, { __index = function(_, key) return key end })
CSColor = function(value) return value end

local function json_escape(value)
  return value:gsub('[%z\1-\31\\\"]', function(char)
    local escapes = { ['\\'] = '\\\\', ['\"'] = '\\"', ['\b'] = '\\b', ['\f'] = '\\f',
      ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t' }
    return escapes[char] or string.format('\\u%04x', string.byte(char))
  end)
end

local function is_array(value)
  local maximum, count = 0, 0
  for key in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
    if key > maximum then maximum = key end
    count = count + 1
  end
  return maximum == count
end

local function encode(value, seen)
  local kind = type(value)
  if kind == "nil" then return "null" end
  if kind == "boolean" or kind == "number" then return tostring(value) end
  if kind == "string" then return '"' .. json_escape(value) .. '"' end
  if kind ~= "table" then return '"<' .. kind .. '>"' end
  if seen[value] then return '"<cycle>"' end
  seen[value] = true
  local parts = {}
  if is_array(value) then
    for index = 1, #value do parts[#parts + 1] = encode(value[index], seen) end
    seen[value] = nil
    return "[" .. table.concat(parts, ",") .. "]"
  end
  for key, item in pairs(value) do
    parts[#parts + 1] = '"' .. json_escape(tostring(key)) .. '":' .. encode(item, seen)
  end
  table.sort(parts)
  seen[value] = nil
  return "{" .. table.concat(parts, ",") .. "}"
end

local chunk = assert(loadfile(input_path, "b"))
local value = chunk()
io.write(encode(value, {}))
