EmptyReqOrder = setmetatable({}, MainOrder)
EmptyReqOrder.__index = EmptyReqOrder

function EmptyReqOrder.Create(orderModel, slot, id, requirements, innerType, avatarId, bIsLukcy, bIsBaseline, diffRange)
  local order = setmetatable({}, EmptyReqOrder)
  order:Init(orderModel, slot, id, requirements, innerType, avatarId, bIsLukcy, bIsBaseline, diffRange)
  return order
end

function EmptyReqOrder:Init(orderModel, slot, id, requirements, innerType, avatarId, bIsLukcy, bIsBaseline, diffRange)
  MainOrder.Init(self, orderModel, slot, id, requirements, innerType, avatarId, bIsLukcy, bIsBaseline, diffRange)
  self:_SetState(OrderState.Dormant)
end

function EmptyReqOrder:_SetState(state)
  MainOrder._SetState(self, state)
end

function EmptyReqOrder:CanDeliver(codeCountMap)
  if self.m_state == OrderState.Dormant then
    return false
  end
  return MainOrder.CanDeliver(self, codeCountMap)
end

function EmptyReqOrder:TryRefreshMyRequirements(defaultReq)
  local mainOrderModel = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot)
  local tempOrder = RandomOrderHelper.CreateNormalRandomOrder(mainOrderModel, self.m_slot, self.m_innerType, self.m_avatarId)
  if GameConfig.IsTestMode() then
    GM.TestModel:ShowTestOrderLog(tempOrder)
  end
  if tempOrder then
    local req = tempOrder:GetRequirements()
    if not Table.IsEmpty(req) then
      mainOrderModel:UpdateRequirements(self.m_slot, req)
      mainOrderModel:_LogOrderAction(self, "refresh")
    end
  else
    local req = defaultReq or {
      ItemType.Flour12
    }
    mainOrderModel:UpdateRequirements(self.m_slot, req)
    mainOrderModel:_LogOrderAction(self, "refresh")
    GM.BIManager:LogErrorInfo(EBIType.EmptyReqOrderNoUpdateReqs, "\230\178\161\230\137\190\229\136\176\228\187\187\228\189\149\229\143\175\231\148\168\230\163\139\229\173\144\239\188\140\228\189\191\231\148\168\229\133\156\229\186\149\230\163\139\229\173\144")
  end
end

function EmptyReqOrder:GetRewards()
  if self.m_state == OrderState.Dormant then
    return Table.Empty
  end
  return MainOrder.GetRewards(self)
end

function EmptyReqOrder:GetBuffRewards()
  if self.m_state == OrderState.Dormant then
    return nil
  end
  return MainOrder.GetBuffRewards(self)
end

function EmptyReqOrder:GetCookingFrenzyConfig()
  if self.m_state == OrderState.Dormant then
    return nil
  end
  return MainOrder.GetCookingFrenzyConfig(self)
end

function EmptyReqOrder:GetScore(includeGold)
  if self.m_state == OrderState.Dormant then
    return 0
  end
  return MainOrder.GetScore(self, includeGold)
end

function EmptyReqOrder:GetDiffScore()
  if self.m_state == OrderState.Dormant then
    return 0
  end
  return MainOrder.GetDiffScore(self)
end

function EmptyReqOrder:GetTestDiffScore()
  if self.m_state == OrderState.Dormant then
    return 0, 0
  end
  return MainOrder.GetTestDiffScore(self)
end
