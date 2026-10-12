TutorialOrderModel = {}
TutorialOrderModel.__index = TutorialOrderModel
local strDBKeys = {
  CurTutorialID = "TutorialOrderModel_CurTutorialID"
}
local tutorialOrderState = {Ready = "1", Doing = "2"}

function TutorialOrderModel.Create(orderModel, dbMetaTable)
  local ele = setmetatable({}, TutorialOrderModel)
  ele:Init(orderModel, dbMetaTable)
  return ele
end

function TutorialOrderModel:Init(orderModel, dbMetaTable)
  self.m_orderModel = orderModel
  self.m_dbTable = dbMetaTable
end

function TutorialOrderModel:OnSyncDataFinished()
  self.m_tutorialOrderConfig = GM.ConfigModel:GetLocalConfig(LocalConfigKey.TutoriaiOrderConfig)
end

function TutorialOrderModel:LateInit()
  local tutorialID, state = self:GetCurOrderAndState()
  local tutorialInfo = self:GetTutorialInfoById(tutorialID)
  if state == tutorialOrderState.Doing and tutorialInfo ~= nil then
    local order = self.m_orderModel:GetOrders()[tutorialInfo.Slot]
    if order == nil then
      self:SetCurOrderAndState(tutorialID + 1, tutorialOrderState.Ready)
    end
  end
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self.OnOrderFinished)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self.OnItemMerged)
end

function TutorialOrderModel:OnOrderFinished(message)
  local order = message.order
  local slot = order:GetSlot()
  local tutorialID, state = self:GetCurOrderAndState()
  local tutorialInfo = self:GetTutorialInfoById(tutorialID)
  if tutorialInfo == nil then
    return
  end
  if tutorialInfo.Slot ~= slot then
    return
  end
  if state == tutorialOrderState.Doing then
    self:SetCurOrderAndState(tutorialID + 1, tutorialOrderState.Ready)
  end
end

function TutorialOrderModel:OnItemMerged(message)
  local newItem = message.New
  local tutorialID, state = self:GetCurOrderAndState()
  local tutorialInfo = self:GetTutorialInfoById(tutorialID)
  if tutorialInfo == nil then
    return
  end
  if state ~= tutorialOrderState.Doing then
    return
  end
  if tutorialInfo.UnlockItem ~= ItemType.Fishing05 then
    return
  end
  if not GM.TutorialModel:IsTutorialFinished(ETutorialId.SeaFoodUnlockTutorial2) and newItem:GetType() == ItemType.RawFish05 then
    self.m_startSeafoodTutorial2 = true
    EventDispatcher.DispatchEvent(EEventType.TutorialStartPop)
  end
end

function TutorialOrderModel:CanCreate(slot)
  local tutorialID, state = self:GetCurOrderAndState()
  local tutorialInfo = self:GetTutorialInfoById(tutorialID)
  if tutorialInfo == nil then
    return false
  end
  if tutorialInfo.Slot ~= slot then
    return false
  end
  if state ~= tutorialOrderState.Ready then
    return false
  end
  local skipItem = tutorialInfo.SkipItem
  if skipItem ~= nil and GM.ItemDataModel:IsUnlocked(skipItem) then
    if tutorialInfo.UnlockItem == ItemType.Fishing05 then
      GM.TutorialModel:SetTutorialFinished(ETutorialId.SeaFoodUnlcokTutorial)
      GM.TutorialModel:SetTutorialFinished(ETutorialId.SeaFoodUnlockTutorial2)
    end
    self:SetCurOrderAndState(tutorialID + 1, tutorialOrderState.Ready)
    return self:CanCreate(slot)
  end
  local unlockItem = tutorialInfo.UnlockItem
  if not GM.ItemDataModel:IsUnlocked(unlockItem) then
    return false
  end
  return true
end

function TutorialOrderModel:CreateOrder(slot)
  local tutorialID, state = self:GetCurOrderAndState()
  local tutorialInfo = self:GetTutorialInfoById(tutorialID)
  local avatarId = self.m_orderModel:GetAvatarId()
  local requirements = {}
  if tutorialInfo.Requirement1 ~= nil then
    table.insert(requirements, tutorialInfo.Requirement1)
  end
  if tutorialInfo.Requirement2 ~= nil then
    table.insert(requirements, tutorialInfo.Requirement2)
  end
  if tutorialInfo.Requirement3 ~= nil then
    table.insert(requirements, tutorialInfo.Requirement3)
  end
  self:SetCurOrderAndState(tutorialID, tutorialOrderState.Doing)
  return MainOrder.Create(self.m_orderModel, slot, tutorialID, requirements, MainOrderType.TutorialOrder, avatarId)
end

function TutorialOrderModel:GetCurOrderAndState()
  local str = self.m_dbTable:GetValue(strDBKeys.CurTutorialID, "value")
  if str == "" or str == nil then
    str = "1_1"
  end
  local arr = StringUtil.Split(str, "_")
  local tutorialID = tonumber(arr[1])
  local state = arr[2]
  return tutorialID, state
end

function TutorialOrderModel:SetCurOrderAndState(tutorialID, state)
  local saveStr = tostring(tutorialID) .. "_" .. state
  self.m_dbTable:Set(strDBKeys.CurTutorialID, "value", saveStr)
end

function TutorialOrderModel:GetTutorialInfoById(id)
  for _, info in pairs(self.m_tutorialOrderConfig) do
    if info.id == id then
      return info
    end
  end
  return nil
end

function TutorialOrderModel:IsForceTutorial()
  local tutorialID, state = self:GetCurOrderAndState()
  local tutorialInfo = self:GetTutorialInfoById(tutorialID)
  if tutorialInfo == nil then
    return false
  end
  if state ~= tutorialOrderState.Doing then
    return false
  end
  if tutorialInfo.UnlockItem ~= ItemType.Fishing05 then
    return false
  end
  if GM.TutorialModel:IsTutorialFinished(ETutorialId.SeaFoodUnlcokTutorial) then
    return false
  end
  local bFind = false
  for position in GM.MainBoardModel:GetValidPositionIterator() do
    local itemModel = GM.MainBoardModel:GetItem(position)
    if itemModel ~= nil then
      local type = itemModel:GetType()
      if GM.ItemDataModel:GetChainId(type) == "7" and GM.ItemDataModel:GetChainLevel(type) >= 5 then
        local itemSpread = itemModel:GetComponent(ItemSpread)
        if itemSpread ~= nil and itemSpread:GetItemRestNumber() > 0 then
          bFind = true
        end
      end
    end
  end
  if not bFind then
    return false
  end
  return true
end

function TutorialOrderModel:IsPlaySeafoodTutorial2()
  if GM.TutorialModel:IsTutorialFinished(ETutorialId.SeaFoodUnlockTutorial2) then
    return false
  end
  return self.m_startSeafoodTutorial2
end

function TutorialOrderModel:PopPlaySeafoodTutorial2()
  self.m_startSeafoodTutorial2 = false
end
