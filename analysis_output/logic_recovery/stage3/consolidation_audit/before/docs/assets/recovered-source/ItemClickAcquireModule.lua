ItemClickAcquireModule = setmetatable({}, BaseActivityModule)
ItemClickAcquireModule.__index = ItemClickAcquireModule
local strDBKey = {
  GenerateRoundTotalCountKey = "GenerateRoundTotalCountKey",
  GenerateRoundValidCountKey = "GenerateRoundValidCountKey",
  CurPropertyNum = "CurPropertyNum"
}

function ItemClickAcquireModule.Create()
  local eleModel = setmetatable({}, ItemClickAcquireModule)
  eleModel:Init()
  return eleModel
end

function ItemClickAcquireModule:Init()
  BaseActivityModule.Init(self)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
  EventDispatcher.AddListener(EEventType.ItemTransform, self, self._OnItemTransform)
end

function ItemClickAcquireModule:AddRegister(model, rewardCount, conditionCount, AddNumFunction, DBKeys, conditionFunction)
  conditionFunction = conditionFunction or function()
    return model:GetState() == ActivityState.Started
  end
  DBKeys = DBKeys or {}
  for k, v in pairs(strDBKey) do
    if DBKeys[k] == nil then
      DBKeys[k] = model:GetType() .. v
    end
  end
  self.m_mapModelInfo[model] = {
    rewardCount = rewardCount,
    conditionCount = conditionCount,
    AddNumFunction = AddNumFunction,
    conditionFunction = conditionFunction,
    DBKeys = DBKeys
  }
end

function ItemClickAcquireModule:RemoveRegister(model)
  self.m_mapModelInfo[model] = nil
end

function ItemClickAcquireModule:_OnItemSpread(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:_TryGenerateItem(message.Source, message.EnergyBoostRatio)
  end
end

function ItemClickAcquireModule:_OnItemTransform(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:_TryGenerateItem(message.Source, message.EnergyBoostRatio)
  end
end

function ItemClickAcquireModule:_TryGenerateItem(sourceItem, energyBoostRatio)
  for model, modelInfo in pairs(self.m_mapModelInfo) do
    if modelInfo.conditionFunction() then
      local num = self:_GenerateItemType(model, modelInfo, energyBoostRatio)
      modelInfo.AddNumFunction(num, sourceItem)
    end
  end
end

function ItemClickAcquireModule:_GenerateItemType(model, modelInfo, energyBoostRatio)
  local dbTable = model:GetDBTable(self)
  local roundTotalCount = dbTable:GetValue(modelInfo.DBKeys.GenerateRoundTotalCountKey, "value") or 0
  local roundValidCount = dbTable:GetValue(modelInfo.DBKeys.GenerateRoundValidCountKey, "value") or 0
  if roundTotalCount == 0 then
    roundTotalCount = modelInfo.rewardCount
    roundValidCount = modelInfo.conditionCount
    dbTable:Set(modelInfo.DBKeys.GenerateRoundValidCountKey, "value", roundValidCount)
  end
  local index = MathUtil.Random(roundTotalCount)
  roundTotalCount = roundTotalCount - 1
  dbTable:Set(modelInfo.DBKeys.GenerateRoundTotalCountKey, "value", roundTotalCount)
  if roundValidCount < index then
    return nil
  end
  roundValidCount = roundValidCount - 1
  dbTable:Set(modelInfo.DBKeys.GenerateRoundValidCountKey, "value", roundValidCount)
  local num = 1
  if energyBoostRatio ~= nil and 0 < energyBoostRatio then
    for i = 1, energyBoostRatio do
      num = num * 2
    end
  end
  return num
end
