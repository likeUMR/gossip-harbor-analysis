SlotOrder = setmetatable({}, BaseOrder)
SlotOrder.__index = SlotOrder

function SlotOrder:Init(slot, id, requirements)
  self.m_slot = slot
  BaseOrder.Init(self, id, requirements)
end

function SlotOrder:GetSlot()
  return self.m_slot
end

function SlotOrder:GetPriorityBySlot()
  for i, slot in ipairs(MainOrderSlotPriority) do
    if tostring(self.m_slot) == slot then
      return i
    end
  end
  return 1000
end

function SlotOrder:GetDiffScore()
  return 0
end
