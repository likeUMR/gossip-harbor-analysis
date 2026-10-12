TokenChainActivityModel = setmetatable({AllowRestoreOnEnd = true}, BaseActivityModel)
TokenChainActivityModel.__index = TokenChainActivityModel
local DBKeys = {
  Index = "Index",
  TokenNum = "TokenNum",
  PopEndWindow = "PopEndWindow",
  GenerateRoundTotalCountKey = "TotalClickTimes",
  GenerateRoundValidCountKey = "ValidClickTimes",
  PopMainWindowWhenEnd = "PopMainWindowWhenEnd",
  PopConfirmWindow = "PopConfirmWindow",
  StartToken = "StartToken"
}

function TokenChainActivityModel:Init(activityType, activityDataTable)
  self.m_activityDefinition = TokenChainActivityDefinition[activityType]
  BaseActivityModel.Init(self, activityType, activityDataTable)
  EventDispatcher.AddListener(EEventType.ChangeGameMode, self, self.OnChangeGameMode)
end

function TokenChainActivityModel:LateInit()
  BaseActivityModel.LateInit(self)
  self.m_lateInit = true
end

function TokenChainActivityModel:Destroy()
  EventDispatcher.RemoveTarget(self)
end

function TokenChainActivityModel:_LoadOtherServerConfig(config)
  self.m_giftContentConfig = {}
  for _, cfg in pairs(config.tokenChainGiftContent) do
    self.m_giftContentConfig[cfg.index] = cfg
  end
  self.m_tokenConfig = config.tokenChainGiftConfig[1]
end

function TokenChainActivityModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_popMainWindow = nil
end

function BaseActivityModel:GetServerConfigGroupId()
  if self.m_giftContentConfig ~= nil then
    return self.m_giftContentConfig[1].groupId
  end
end

function TokenChainActivityModel:_OnStateChanged()
  BaseActivityModel._OnStateChanged(self)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.StateChangedEvent)
  if self:GetState() == ActivityState.Started then
    if self:CanGiveStartToken() then
      self:GetStartToken()
      self:SetTokenNum(self:GetTokenNum() + 10)
      self:LogActivity(EBIType.ActivityAddScore, GM.BIManager:TableToString({source = "free", num = 10}))
    end
    GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.ClickAcquireProperty, self, self.m_tokenConfig.chance[1], self.m_tokenConfig.chance[2], function(num, sourceItem)
      if num == nil or num <= 0 then
        return
      end
      self:SetTokenNum(self:GetTokenNum() + num)
      self:LogActivity(EBIType.ActivityAddScore, GM.BIManager:TableToString({
        source = "cost_energy",
        num = num
      }))
      local boardView = MainBoardView.GetInstance()
      if boardView == nil then
        return
      end
      local StartItemView = boardView:GetItemView(sourceItem)
      if StartItemView == nil then
        return
      end
      local screenPosition = boardView:ConvertWorldPositionToScreenPosition(StartItemView.transform.position)
      local uiPosition = PositionUtil.UICameraScreen2World(screenPosition)
      local viewData = {
        arrWorldPos = {uiPosition}
      }
      RewardApi.AcquireRewardsInView({
        {
          [PROPERTY_TYPE] = self.m_activityDefinition.ActivityTokenPropertyType,
          [PROPERTY_COUNT] = num
        }
      }, viewData)
    end, DBKeys, function()
      if self:GetState() == ActivityState.Started and not self:IsFinished() then
        return true
      end
    end)
  end
end

function TokenChainActivityModel:GetResourceLabels()
  return self.m_activityDefinition.ResourceLabels
end

function TokenChainActivityModel:IsPayGift(index)
  return self.m_giftContentConfig[index].tokens == nil and self.m_giftContentConfig[index].desc_price ~= nil and self.m_giftContentConfig[index].payID ~= nil
end

function TokenChainActivityModel:BuyGift(index)
  if self:IsPayGift(index) then
    local iapType = self.m_giftContentConfig[index].payID
    local startActivityId = self:GetId()
    UIHelper.Recharge(function()
      local function callback()
        self:_OnBuyRewardSuccess(iapType, index, false)
      end
      
      GM.InAppPurchaseModel:StartPurchase(iapType, callback, EBIType.ShopBuy)
    end)
  else
    local costTokens = self.m_giftContentConfig[index].tokens
    if 0 < costTokens then
      self:SetTokenNum(self:GetTokenNum() - costTokens)
      GM.BIManager:LogAction(self.m_activityDefinition.ConsumeTokenBIType, {
        num = costTokens,
        index = index,
        groupId = self.m_giftContentConfig[index].groupId
      })
    end
    RewardApi.AcquireRewardsLogic(self.m_giftContentConfig[index].content, self:IsNoPayReward(index) and EPropertySource.Give or EPropertySource.Buy, self.m_activityDefinition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
    self:LogActivity(EBIType.ActivityGetRewards, index)
    self:UpdateIndex(index)
    EventDispatcher.DispatchEvent(self.m_activityDefinition.BuyGiftEvent, {index = index, bPay = false})
  end
end

function TokenChainActivityModel:_OnBuyRewardSuccess(iapType, index, isRestore)
  RewardApi.AcquireRewardsLogic(self.m_giftContentConfig[index].content, EPropertySource.Buy, self.m_activityDefinition.GetRewardsBIType, EGameMode.Main, CacheItemType.Type2)
  self:LogActivity(EBIType.ActivityGetRewards, index)
  self:UpdateIndex(index)
  local mainWindow = GM.UIManager:GetOpenedViewByName(self.m_activityDefinition.MainWindowPrefabName)
  if mainWindow == nil then
    RewardApi.AcquireRewardsInView(self.m_giftContentConfig[index].content)
  end
  EventDispatcher.DispatchEvent(self.m_activityDefinition.BuyGiftEvent, {index = index, bPay = true})
end

function TokenChainActivityModel:RestoreIapRewards(iapType)
  if Table.IsEmpty(self.m_giftContentConfig) then
    return false
  end
  local index = self:GetCurIndex()
  local config = self.m_giftContentConfig[index]
  if config ~= nil and config.payID == iapType then
    self:_OnBuyRewardSuccess(iapType, index, true)
    return true
  end
  return false
end

function TokenChainActivityModel:UpdateIndex(index)
  if index == 0 then
    self:SetCurIndex(-1)
  elseif index == #self.m_giftContentConfig then
    self:SetCurIndex(0)
    self:LogActivity(EBIType.ActivityRankUp, 0)
  else
    self:SetCurIndex(index + 1)
    self:LogActivity(EBIType.ActivityRankUp, index + 1)
  end
end

function TokenChainActivityModel:IsTokenEnoughToBuy(index)
  return self.m_giftContentConfig[index] and self.m_giftContentConfig[index].tokens and self:GetTokenNum() >= self.m_giftContentConfig[index].tokens
end

function TokenChainActivityModel:IsFinished()
  return self:GetCurIndex() == -1
end

function TokenChainActivityModel:CanShowRedPoint()
  if self:IsFinished() then
    return 0
  end
  local index = self:GetCurIndex()
  if self:IsTokenEnoughToBuy(index) then
    return 1
  end
  return 0
end

function TokenChainActivityModel:GetRewardsByIndex(index)
  return self.m_giftContentConfig[index].content
end

function TokenChainActivityModel:OnChangeGameMode()
  if self:GetState() == ActivityState.Released or self.m_giftContentConfig == nil then
    return
  end
  local index = self:GetCurIndex()
  if index == -1 then
    return
  end
  if self:IsPayGift(index) then
    return
  end
  self.m_popMainWindow = true
end

function TokenChainActivityModel:PopMainWindow()
  self.m_popMainWindow = false
end

function TokenChainActivityModel:CanTokenEnoughPopMainWindow()
  return self.m_popMainWindow
end

function TokenChainActivityModel:GetCostByIndex(index)
  return self:IsPayGift(index) and self.m_giftContentConfig[index].payID or self.m_giftContentConfig[index].tokens
end

function TokenChainActivityModel:GetNormalRewardCount()
  return #self.m_giftContentConfig
end

function TokenChainActivityModel:IsNoPayReward(index)
  local firstPay = 0
  for i = 1, #self.m_giftContentConfig do
    if self:IsPayGift(i) then
      firstPay = i
      break
    end
  end
  if firstPay == 0 then
    return 0 < index
  end
  return index < firstPay
end

function TokenChainActivityModel:GetCurIndex()
  return self.m_dbTable:GetValue(DBKeys.Index, "value") or 1
end

function TokenChainActivityModel:SetCurIndex(index)
  self.m_dbTable:Set(DBKeys.Index, "value", index)
end

function TokenChainActivityModel:GetTokenNum()
  return self.m_dbTable:GetValue(DBKeys.TokenNum, "value") or 0
end

function TokenChainActivityModel:SetTokenNum(num, biSource)
  self.m_dbTable:Set(DBKeys.TokenNum, "value", num)
  EventDispatcher.DispatchEvent(self.m_activityDefinition.TokenNumChangedEvent)
end

function TokenChainActivityModel:SetPopEndWindow()
  self.m_dbTable:Set(DBKeys.PopEndWindow, "value", "1")
end

function TokenChainActivityModel:CanPopEndWindow()
  return self.m_dbTable:GetValue(DBKeys.PopEndWindow, "value") ~= "1"
end

function TokenChainActivityModel:SetPopMainWindowWhenEnd()
  self.m_dbTable:Set(DBKeys.PopMainWindowWhenEnd, "value", "1")
end

function TokenChainActivityModel:CanPopMainWindowWhenEnd()
  local remainTime = self:GetNextStateTime() - GM.GameModel:GetServerTime()
  if remainTime < 600 then
    return false
  end
  return self.m_dbTable:GetValue(DBKeys.PopMainWindowWhenEnd, "value") ~= "1"
end

function TokenChainActivityModel:SetPopConfirmWindow()
  self.m_dbTable:Set(DBKeys.PopConfirmWindow, "value", "1")
end

function TokenChainActivityModel:CanPopConfirmWindow()
  return self.m_dbTable:GetValue(DBKeys.PopConfirmWindow, "value") ~= "1"
end

function TokenChainActivityModel:CanGiveStartToken()
  return self.m_dbTable:GetValue(DBKeys.StartToken, "value") ~= "1"
end

function TokenChainActivityModel:GetStartToken()
  self.m_dbTable:Set(DBKeys.StartToken, "value", "1")
end

function TokenChainActivityModel:GetHudEntryShowConfig()
  return {
    Type = "TokenChainActivity",
    ArrCheckShowEvent = {
      self.m_activityDefinition.StateChangedEvent,
      self.m_activityDefinition.BuyGiftEvent
    },
    EntryPrefabConfigName = UIPrefabConfigName.HudActivityEntry,
    CheckFunc = function()
      return self:GetState() == ActivityState.Started and not self:IsFinished()
    end,
    HudSideBarType = EHudSideBarType.Right,
    EntryButtonKey = self.m_activityDefinition.EntryButtonKey,
    EntryIconName = self.m_activityDefinition.EntryImageName,
    OnClickedFunc = function()
      GM.UIManager:OpenView(self.m_activityDefinition.MainWindowPrefabName, self:GetType(), false)
    end,
    RedPointType = EntryRedPointType.Exc,
    GetRedPointNumFunc = function()
      return self:CanShowRedPoint()
    end,
    ArrUpdateEntryContentEvent = {
      self.m_activityDefinition.TokenNumChangedEvent,
      self.m_activityDefinition.BuyGiftEvent
    }
  }
end

function TokenChainActivityModel:TestAddScore(num)
  if GameConfig.IsTestMode() then
    self:SetTokenNum(self:GetTokenNum() + num)
  end
end
