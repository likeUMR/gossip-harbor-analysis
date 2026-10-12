OrderModelType = {Slot = 1, Host = 2}
BaseOrderModel = {}
BaseOrderModel.__index = BaseOrderModel

function BaseOrderModel:Init(boardModel)
  self.m_boardModel = boardModel
end

function BaseOrderModel:LoadFileConfig()
  Log.Assert(false, "LoadFileConfig()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrderModel:OnSyncDataFinished()
  self.m_orders = {}
  Log.Assert(false, "OnSyncDataFinished()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrderModel:LateInit()
  Log.Assert(false, "LateInit()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrderModel:UpdatePerSecond()
  Log.Assert(false, "UpdatePerSecond()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function BaseOrderModel:ContainsOrder(order)
  return Table.Contain(self.m_orders, order)
end

function BaseOrderModel:UpdateState(codeCountMap, codeStateMap)
  for _, order in pairs(self.m_orders) do
    order:UpdateState(codeCountMap)
  end
  for _, order in pairs(self.m_orders) do
    local orderState = order:GetState()
    local fillStates = order:GetRequirementFillStates()
    for index, code in ipairs(order:GetRequirements()) do
      if fillStates[index] and orderState ~= OrderState.Finished then
        if codeStateMap[code] == nil then
          codeStateMap[code] = OrderState.Init
        end
        if orderState > codeStateMap[code] then
          codeStateMap[code] = orderState
        end
      end
    end
  end
end

function BaseOrderModel:_LogOrder(order, type, content, action)
  GM.BIManager:LogOrder(order:GetId(), type, content, action)
end

function BaseOrderModel:_GetLogOrderActionOrderType(order)
  if order:GetType() == OrderType.Fixed then
    return "fixed"
  elseif order:GetType() == OrderType.Special then
    return "special"
  else
    return "random"
  end
end

function BaseOrderModel:_LogOrderAction(order, action)
  local type = self:_GetLogOrderActionOrderType(order)
  local content = {}
  for _, requirement in ipairs(order:GetRequirements()) do
    if content[requirement] == nil then
      content[requirement] = 0
    end
    content[requirement] = content[requirement] + 1
  end
  self:_LogOrder(order, type, content, action)
end

function BaseOrderModel:GetOrders()
  return self.m_orders
end
