SlotOrderModel = setmetatable({}, BaseOrderModel)
SlotOrderModel.__index = SlotOrderModel

function SlotOrderModel:Init(boardModel, slotCount)
  self.m_slotCount = slotCount
  BaseOrderModel.Init(self, boardModel)
end

function SlotOrderModel:OnSyncDataFinished()
  self.m_orders = self:_DBGetOrders()
end

function SlotOrderModel:LateInit()
  self:_TryFillOrders()
end

function SlotOrderModel:_DBGetOrders()
  Log.Assert(false, "_DBGetOrders()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function SlotOrderModel:_DBAddOrder(order)
  Log.Assert(false, "_DBAddOrder()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function SlotOrderModel:_DBRemoveOrder(slot)
  Log.Assert(false, "_DBRemoveOrder()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function SlotOrderModel:_TryFillOrders()
  local hasFilledOrder = false
  local hasFilledOrderOnce = false
  local arrNewOrders = {}
  repeat
    hasFilledOrderOnce = false
    for slot = 1, self.m_slotCount do
      local order = self.m_orders[slot]
      if order == nil or order:GetState() == OrderState.Finished then
        if order ~= nil then
          self:_RemoveOrder(slot)
          self.m_orders[slot] = nil
        end
        local newOrder = self:_TryCreateOrder(slot)
        if newOrder ~= nil then
          hasFilledOrder = true
          hasFilledOrderOnce = true
          self:_DBAddOrder(newOrder)
          self.m_orders[slot] = newOrder
          table.insert(arrNewOrders, newOrder)
        end
      end
    end
  until not hasFilledOrderOnce
  if hasFilledOrder then
    self.m_boardModel:UpdateOrderState()
    for _, order in ipairs(arrNewOrders) do
      self:_LogOrderAction(order, "unlock")
    end
  end
end

function SlotOrderModel:_TryCreateOrder(slot)
  Log.Assert(false, "_TryCreateNewOrder()\230\152\175\230\138\189\232\177\161\230\142\165\229\143\163")
end

function SlotOrderModel:FinishOrder(order)
  if not self:ContainsOrder(order) then
    return false
  end
  order:SetFinished()
  self:_LogOrderAction(order, "finish")
  self:_TryFillOrders()
  EventDispatcher.DispatchEvent(EEventType.OrderFinished, {order = order})
  return true
end
