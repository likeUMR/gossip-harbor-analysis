UseInventoryItemConfirmWindow = setmetatable({}, BaseWindow)
UseInventoryItemConfirmWindow.__index = UseInventoryItemConfirmWindow

function UseInventoryItemConfirmWindow:Init(boardModel, orderModel, callback, listListeners)
  if listListeners ~= nil then
    for _, eEventType in ipairs(listListeners) do
      EventDispatcher.AddActiveListener(eEventType, self, self.Close)
    end
  end
  self.m_callback = callback
  self.m_titleText.text = GM.GameTextModel:GetText("inventory_item_use_title")
  self.m_descText.text = GM.GameTextModel:GetText("inventory_item_use_desc")
  self.m_redText.text = GM.GameTextModel:GetText("inventory_item_use_refuse")
  self.m_greenText.text = GM.GameTextModel:GetText("inventory_item_use_confirm")
  local _, lackedCodeCountMap = orderModel:CanDeliver(boardModel:GetCodeCountMap(true, false, false))
  local arrFormattedItemList = {}
  for type, count in pairs(lackedCodeCountMap) do
    for i = 1, count do
      arrFormattedItemList[#arrFormattedItemList + 1] = {
        [PROPERTY_TYPE] = type,
        [PROPERTY_COUNT] = 1
      }
    end
  end
  self.m_rewardContent:Init(arrFormattedItemList)
  self.m_boardModel = boardModel
  self.m_orderModel = orderModel
end

function UseInventoryItemConfirmWindow:OnRedClick()
  self:Close()
end

function UseInventoryItemConfirmWindow:OnGreenClick()
  self.m_bFinishOrder = true
  self:Close()
end

function UseInventoryItemConfirmWindow:OnCloseFinish()
  BaseWindow.OnCloseFinish(self)
  if self.m_bFinishOrder then
    if self.m_callback ~= nil then
      self.m_callback()
    elseif self.m_boardModel:GetOrderModel(OrderModelType.Slot):ContainsOrder(self.m_orderModel) then
      self.m_boardModel:FinishOrder(self.m_orderModel)
    end
  end
end
