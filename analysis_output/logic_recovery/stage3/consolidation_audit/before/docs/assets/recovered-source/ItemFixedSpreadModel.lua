ItemFixedSpreadModel = {}
ItemFixedSpreadModel.__index = ItemFixedSpreadModel
local DBColumnWeightConfig = "pairs"
local DBColumnWeightInfo = "sequence"

function ItemFixedSpreadModel:Init()
  self.m_dbTableOld = GM.DBTableManager:GetTable(EDBTableConfigs.FixedSpread)
  self.m_dbTable = GM.DBTableManager:GetTable(EDBTableConfigs.FixedSpreadNew)
  self.m_mapFixedSpreadWeight = {}
  self.m_mapLeftSpreadCount = {}
end

function ItemFixedSpreadModel:GenerateItemCode(type)
  self:_Try2InitSpreadWeight(type)
  local weightInfo = Table.ListWeightSelectOne(self.m_mapFixedSpreadWeight[type], "Weight")
  weightInfo.Weight = weightInfo.Weight - 1
  self.m_mapLeftSpreadCount[type] = self.m_mapLeftSpreadCount[type] - 1
  if self.m_mapLeftSpreadCount[type] <= 0 then
    self:_ResetSpreadWeightInfo(type)
    self:_UpdateSpreadWeightInfo(type)
  else
    self.m_dbTable:Set(type, DBColumnWeightInfo, ItemUtility.CodeWeightPairsToString(self.m_mapFixedSpreadWeight[type]))
  end
  return weightInfo.Code
end

function ItemFixedSpreadModel:_Try2InitSpreadWeight(type)
  if self.m_mapFixedSpreadWeight[type] ~= nil then
    local config = GM.ItemDataModel:GetModelConfig(type)
    if config.Spread_Weight_Str == self.m_dbTable:GetValue(type, DBColumnWeightConfig) then
      return
    end
  end
  local hasOldData = not StringUtil.IsNilOrEmpty(self.m_dbTableOld:GetValue(type, DBColumnWeightInfo)) and not StringUtil.IsNilOrEmpty(self.m_dbTableOld:GetValue(type, DBColumnWeightConfig))
  if hasOldData then
    local sequenceList = StringUtil.SplitToNum(self.m_dbTableOld:GetValue(type, DBColumnWeightInfo), ",")
    local mapLeftCount = {}
    local pairConfig = ItemUtility.StringToCodeWeightPairs(self.m_dbTableOld:GetValue(type, DBColumnWeightConfig))
    for _, sequence in ipairs(sequenceList) do
      local index = sequence
      for _, item in ipairs(pairConfig) do
        if index <= item.Weight then
          mapLeftCount[item.Code] = (mapLeftCount[item.Code] or 0) + 1
          break
        else
          index = index - item.Weight
        end
      end
    end
    local curSpreadWeight = Table.DeepCopy(pairConfig)
    for _, item in ipairs(curSpreadWeight) do
      item.Weight = mapLeftCount[item.Code] or 0
    end
    self.m_dbTable:Set(type, DBColumnWeightConfig, self.m_dbTableOld:GetValue(type, DBColumnWeightConfig))
    self.m_dbTable:Set(type, DBColumnWeightInfo, ItemUtility.CodeWeightPairsToString(curSpreadWeight))
    self.m_dbTableOld:Remove(type)
  end
  local config = GM.ItemDataModel:GetModelConfig(type)
  if StringUtil.IsNilOrEmpty(self.m_dbTable:GetValue(type, DBColumnWeightConfig)) or StringUtil.IsNilOrEmpty(self.m_dbTable:GetValue(type, DBColumnWeightInfo)) or config.Spread_Weight_Str ~= self.m_dbTable:GetValue(type, DBColumnWeightConfig) then
    self.m_dbTable:Set(type, DBColumnWeightConfig, config.Spread_Weight_Str)
    self:_ResetSpreadWeightInfo(type)
  end
  self:_UpdateSpreadWeightInfo(type)
end

function ItemFixedSpreadModel:_ResetSpreadWeightInfo(type)
  local configStr = self.m_dbTable:GetValue(type, DBColumnWeightConfig)
  if StringUtil.IsNilOrEmpty(configStr) then
    return
  end
  self.m_dbTable:Set(type, DBColumnWeightInfo, configStr)
end

function ItemFixedSpreadModel:_UpdateSpreadWeightInfo(type)
  self.m_mapFixedSpreadWeight[type] = ItemUtility.StringToCodeWeightPairs(self.m_dbTable:GetValue(type, DBColumnWeightInfo))
  self.m_mapLeftSpreadCount[type] = 0
  for _, weightInfo in ipairs(self.m_mapFixedSpreadWeight[type]) do
    self.m_mapLeftSpreadCount[type] = self.m_mapLeftSpreadCount[type] + weightInfo.Weight
  end
end

local spreadType2Desc

function ItemFixedSpreadModel:GetTestInfo()
  local boardModel, boardView = BoardModelHelper.GetActiveModel()
  if boardView == nil then
    return "\230\178\161\230\156\137\230\163\139\231\155\152"
  end
  if boardView.GetSelectedItemModel == nil then
    return "\229\189\147\229\137\141\228\184\141\230\148\175\230\140\129\233\128\137\228\184\173\230\163\139\229\173\144"
  end
  local itemModel = boardView:GetSelectedItemModel()
  if itemModel == nil then
    return "\229\189\147\229\137\141\230\178\161\230\156\137\233\128\137\228\184\173\230\163\139\229\173\144"
  end
  local itemSpread = itemModel:GetComponent(ItemSpread)
  if itemSpread == nil then
    return "\229\189\147\229\137\141\233\128\137\228\184\173\230\163\139\229\173\144\228\184\141\230\152\175\230\175\141\228\189\147\230\163\139\229\173\144"
  end
  local type = itemSpread:GetWeightType()
  if spreadType2Desc == nil then
    spreadType2Desc = {
      [ItemSpreadWeightType.Fixed] = "\229\155\186\229\174\154\230\166\130\231\142\135",
      [ItemSpreadWeightType.Decremental] = "\230\157\131\233\135\141\232\135\170\229\135\143",
      [ItemSpreadWeightType.OrderItem] = "\232\174\162\229\141\149\230\163\139\229\173\144\229\174\157\231\174\177"
    }
  end
  local result = "\229\150\183\229\143\145\231\177\187\229\158\139:" .. (spreadType2Desc[type] or "\230\156\170\231\159\165\231\177\187\229\158\139\239\188\140\232\129\148\231\179\187\229\188\128\229\143\145\229\164\132\231\144\134" .. type) .. "\n"
  if type == ItemSpreadWeightType.Fixed then
    self:_Try2InitSpreadWeight(itemModel:GetType())
    local subStr = ""
    for _, weightInfo in ipairs(self.m_mapFixedSpreadWeight[itemModel:GetType()]) do
      subStr = subStr .. "  " .. weightInfo.Code .. " : " .. weightInfo.Weight .. "\n"
    end
    result = result .. "\230\156\172\232\189\174\229\137\169\228\189\153\229\150\183\229\143\145:\n" .. subStr
  elseif type == ItemSpreadWeightType.Decremental then
    local subStr = ""
    for _, weightInfo in ipairs(itemSpread.m_codeWeightPairs) do
      subStr = subStr .. "  " .. weightInfo.Code .. " : " .. weightInfo.Weight .. "\n"
    end
    result = result .. "\229\137\169\228\189\153\229\150\183\229\143\145:\n" .. subStr
  elseif type == ItemSpreadWeightType.OrderItem then
    result = result .. "\231\155\180\230\142\165\232\167\129\229\150\183\229\143\145\230\151\165\229\191\151"
  end
  return result
end
