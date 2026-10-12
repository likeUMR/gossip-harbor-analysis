ItemSwallowEventType = {ProgressChanged = 1}
ItemSwallow = setmetatable({}, BaseItemComponent)
ItemSwallow.__index = ItemSwallow
ItemSwallow.TapProtectionTime = 1

function ItemSwallow.Create(itemConfig)
  local itemSwallow = setmetatable({}, ItemSwallow)
  itemSwallow:Init(itemConfig)
  return itemSwallow
end

function ItemSwallow:Init(itemConfig)
  self.event = PairEvent.Create(self)
  self.m_swallowInfo = {
    self:_CreateSwallowInfo(itemConfig, 1),
    self:_CreateSwallowInfo(itemConfig, 2)
  }
  self.m_allowTap = itemConfig.Swallow_AllowTap ~= 0
  self.m_generateTime = GM.GameModel:GetServerTime()
end

function ItemSwallow:AllowTap()
  return self.m_allowTap
end

function ItemSwallow:OnTap()
  if GM.GameModel:GetServerTime() - self.m_generateTime <= ItemSwallow.TapProtectionTime or not self.m_allowTap then
    return
  end
  local targetItems = {}
  local targetNumbers = {0, 0}
  local boardModel = self.m_itemModel:GetBoardModel()
  for position in boardModel:GetValidPositionIterator() do
    local item = boardModel:GetItem(position)
    if item ~= nil then
      for index, info in ipairs(self.m_swallowInfo) do
        if info.Code == item:GetCode() and info.Swallowed + targetNumbers[index] < info.Count then
          table.insert(targetItems, item)
          targetNumbers[index] = targetNumbers[index] + 1
        end
      end
    end
  end
  if #targetItems == 0 then
    return
  end
  local message = {
    Sources = targetItems,
    Target = self.m_itemModel
  }
  boardModel.event:Call(BoardEventType.BatchSwallowItem, message)
end

function ItemSwallow:CanSwallow(item)
  for _, info in ipairs(self.m_swallowInfo) do
    if info.Code == item:GetCode() and info.Swallowed < info.Count then
      return true
    end
  end
  return false
end

function ItemSwallow:Swallow(item)
  for _, info in ipairs(self.m_swallowInfo) do
    if info.Code == item:GetCode() then
      info.Swallowed = info.Swallowed + 1
      break
    end
  end
  local boardModel = self.m_itemModel:GetBoardModel()
  boardModel:SaveItemProperty(self.m_itemModel)
  boardModel:RemoveItem(item)
  local message = {
    Source = item,
    Target = self.m_itemModel
  }
  boardModel.event:Call(BoardEventType.SwallowItem, message)
  GM.BIManager:LogAction(EBIType.SwallowItem, {
    s = item:GetCode(),
    t = self.m_itemModel:GetCode()
  })
  local canTransform = true
  for _, info in ipairs(self.m_swallowInfo) do
    if info.Swallowed < info.Count then
      canTransform = false
      break
    end
  end
  self.event:Call(ItemSwallowEventType.ProgressChanged)
  if canTransform then
    local itemTransform = self.m_itemModel:GetComponent(ItemTransform)
    itemTransform:Transform()
    if not self.m_allowTap then
      boardModel:ShockNeighborItems(self.m_itemModel:GetPosition())
    end
  end
  EventDispatcher.DispatchEvent(EEventType.ItemSwallow, message)
end

function ItemSwallow:GetSwallowInfo()
  return self.m_swallowInfo
end

function ItemSwallow:_CreateSwallowInfo(itemConfig, index)
  local swallowWeight = itemConfig["Swallow_Weight" .. index]
  if swallowWeight == nil then
    return nil
  end
  local code
  local forcedTypes = TutorialBoardHelper.GetForcedSwallowItemTypes()
  if forcedTypes == nil then
    code = GM.ItemFixedSwallowModel:GenerateTargetCode(itemConfig.Type, swallowWeight, index)
  else
    code = forcedTypes[index]
  end
  if code == nil then
    return nil
  end
  return {
    Code = code,
    Count = itemConfig["Swallow_Number" .. index],
    Swallowed = 0
  }
end

function ItemSwallow.SwallowInfoToString(swallowInfo)
  local data = ""
  for index, item in ipairs(swallowInfo) do
    data = data .. item.Code .. "-" .. item.Swallowed .. "-" .. item.Count
    if index ~= #swallowInfo then
      data = data .. ";"
    end
  end
  return data
end

function ItemSwallow.StringToSwallowInfo(data)
  local swallowInfo = {}
  local array = StringUtil.Split(data, ";")
  for _, item in ipairs(array) do
    local parts = StringUtil.Split(item, "-")
    table.insert(swallowInfo, {
      Code = parts[1],
      Swallowed = tonumber(parts[2]),
      Count = tonumber(parts[3])
    })
  end
  return swallowInfo
end
