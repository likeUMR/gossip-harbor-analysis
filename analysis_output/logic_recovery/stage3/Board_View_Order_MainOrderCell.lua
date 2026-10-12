MainOrderCell = setmetatable({}, BaseOrderCell)
MainOrderCell.__index = MainOrderCell

function MainOrderCell:OnDestroy()
  BaseOrderCell.OnDestroy(self)
  Scheduler.UnscheduleTarget(self)
end

function MainOrderCell:GetDisplayRewards()
  local displayRewards = Table.ShallowCopy(self.m_order:GetRewards())
  if GM.CharacterIntimacyModel:IsOpen() and self.m_order:GetInnerType() == MainOrderType.CharacterIntimacyRandom then
    local rewardList = self.m_order:GetGiftRewards()
    if not Table.IsEmpty(rewardList) then
      table.insert(displayRewards, rewardList[1])
    else
      GM.BIManager:LogErrorInfo("cir_err", "no gift")
    end
  end
  local newDisplayRewards = {}
  for _, reward in ipairs(displayRewards) do
    if not StringUtil.StartWith(reward[PROPERTY_TYPE], ChestCustomerModel.RewardKey) then
      table.insert(newDisplayRewards, reward)
    end
  end
  return newDisplayRewards
end

function MainOrderCell:OnRewardCellInitFinish(cell, reward)
  if GM.BuffManager:IsBuffActiveByType(EBuffProperty.BuffGold) then
    local goldType = self.m_order.GetFirstRewardPropertyType and self.m_order:GetFirstRewardPropertyType() or EPropertyType.Gold
    if reward[PROPERTY_TYPE] == goldType then
      local orgCount = math.floor(reward[PROPERTY_COUNT] / 2)
      cell:SetCountText("+" .. orgCount)
      cell:SetRateText(" x" .. 2)
    end
  end
end

function MainOrderCell:GetDisplayTray()
  return ImageFileConfigName.order_tray
end

function MainOrderCell:GetTestInfoStr()
  local color = "94261A"
  local id = self.m_order:GetId()
  local innerType = self.m_order.GetInnerType and self.m_order:GetInnerType() or nil
  local diffScore, allScore = self.m_order:GetTestDiffScore()
  diffScore = diffScore or "nil"
  allScore = allScore or "nil"
  local slotInfo = "Slot: " .. StringUtil.MakeColorFormat(self.m_order:GetSlot(), "94261A") .. "  "
  local typeInfo = "Type: " .. StringUtil.MakeColorFormat(tostring(innerType), "94261A") .. "\n"
  local idInfo = "Id: " .. StringUtil.MakeColorFormat(tostring(id), "94261A") .. "  "
  local allScoreInfo = "DS: " .. StringUtil.MakeColorFormat(tostring(allScore), "94261A") .. "\n"
  local diffScoreInfo = StringUtil.MakeColorFormat(tostring(diffScore), "94261A") .. "\n"
  return slotInfo .. typeInfo .. idInfo .. allScoreInfo .. diffScoreInfo
end

function MainOrderCell:OnAvatarClick()
  if self.m_bGoButtonEnabled == false then
    return
  end
  EventDispatcher.DispatchEvent(EEventType.AvatarSelected, self)
end

function MainOrderCell:Awake()
  EventDispatcher.AddListener(EEventType.CharacterIntimacyStateChanged, self, self.OnCharacterIntimacyStateChanged)
end

function MainOrderCell:Init(order, orderArea)
  BaseOrderCell.Init(self, order, orderArea)
  self:OnCharacterIntimacyStateChanged()
  if self.m_order:GetInnerType() == MainOrderType.CharacterIntimacyRandom and self.m_characterIntimacyStarEffectGo == nil then
    local config = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.CharacterIntimacyStarEffect)
    
    local function callback(gameObject)
      self.m_characterIntimacyStarEffectGo = gameObject
      self.m_starEffectGo = gameObject
      gameObject:SetActive(false)
    end
    
    GM.ResourceLoader:LoadPrefab(config, self.m_characterIntimacyComponentNode, Vector3(0, 150, 0), callback)
  end
  local model = GM.ActivityManager:GetStartedButterflyActivity()
  if model and self.m_order:GetSlot() == model:GetButterflySlot() then
    self:LoadButterfly(function()
      if model:GetForceCreateSlot() > 0 then
        model:SetForceCreateSlot(-1)
      else
        self:ShowButterfly()
      end
    end)
  end
end

function MainOrderCell:OnCharacterIntimacyStateChanged()
  if self.m_order:GetGiftRewards() == nil then
    return
  end
  if self.m_order:GetInnerType() == MainOrderType.CharacterIntimacyRandom then
    return
  end
  if GM.CharacterIntimacyModel:IsOpen() then
    if self.m_characterIntimacyComponentNormal == nil then
      local config = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.CharacterIntimacyComponentNormal)
      
      local function callback(gameObject)
        local component = gameObject:GetLuaTable()
        component:Init(self.m_order)
        self.m_characterIntimacyComponentNormal = component
      end
      
      GM.ResourceLoader:LoadPrefab(config, self.m_characterIntimacyComponentNode, Vector3(55, -2, 0), callback)
    end
  elseif self.m_characterIntimacyComponentNormal ~= nil then
    Object.Destroy(self.m_characterIntimacyComponentNormal.gameObject)
    self.m_characterIntimacyComponentNormal = nil
  end
end

function MainOrderCell:_UpdateReward()
  BaseOrderCell._UpdateReward(self)
  self:UpdateBuffReward()
  self:UpdateFailedSmileReward()
  self:UpdateSmileReward()
  self:UpdateCookingFrenzyOrderReward()
end

function MainOrderCell:UpdateBuffReward()
  if self.m_buffRewardPrefab == nil then
    return
  end
  local buffRewrads = self.m_order:GetBuffRewards()
  if Table.IsEmpty(buffRewrads) then
    if self.m_buffReward ~= nil then
      UIUtil.SetActive(self.m_buffReward.gameObject, false)
    end
  else
    if self.m_buffReward == nil then
      self.m_buffReward = Object.Instantiate(self.m_buffRewardPrefab, self.m_buffRewardsRectTrans):GetLuaTable()
    end
    UIUtil.SetActive(self.m_buffReward.gameObject, true)
    self.m_buffReward:Init(buffRewrads)
  end
end

function MainOrderCell:UpdateSmileReward()
  local obModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  if obModel:GetAddOrderBoostScoreByOrder(self:GetOrder()) > 0 then
    if self.m_smileBoost == nil then
      GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(OrderBoostUIDefinition[obModel:GetUIType()].RewardContentPrefabName), self.m_SmileRewardsRectTrans, Vector3.zero, function(gameObject)
        if self.m_smileBoost ~= nil then
          AddressableLoader.Destroy(gameObject)
          return
        end
        self.m_smileBoost = gameObject:GetLuaTable()
        if obModel:GetAddOrderBoostScoreByOrder(self:GetOrder()) > 0 then
          UIUtil.SetActive(self.m_smileBoost.gameObject, true)
          self.m_smileBoost:Init(obModel:GetAddOrderBoostScoreByOrder(self:GetOrder()))
        else
          UIUtil.SetActive(self.m_smileBoost.gameObject, false)
        end
      end)
    else
      self.m_smileBoost:Init(obModel:GetAddOrderBoostScoreByOrder(self:GetOrder()))
      UIUtil.SetActive(self.m_smileBoost.gameObject, true)
    end
  elseif self.m_smileBoost ~= nil then
    UIUtil.SetActive(self.m_smileBoost.gameObject, false)
  end
end

function MainOrderCell:UpdateFailedSmileReward()
  local obModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  if self.m_smileBoost ~= nil and self.m_smileBoost:GetType() ~= obModel:GetUIType() then
    self.m_smileBoost:PlayDestroyAni()
    self.m_smileBoost = nil
    GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(OrderBoostUIDefinition[obModel:GetUIType()].RewardContentPrefabName), self.m_SmileRewardsRectTrans, Vector3.zero, function(gameObject)
      if self.m_smileBoost ~= nil then
        AddressableLoader.Destroy(gameObject)
        return
      end
      self.m_smileBoost = gameObject:GetLuaTable()
      if obModel:GetAddOrderBoostScoreByOrder(self:GetOrder()) > 0 then
        UIUtil.SetActive(self.m_smileBoost.gameObject, true)
        self.m_smileBoost:Init(obModel:GetAddOrderBoostScoreByOrder(self:GetOrder()))
      else
        UIUtil.SetActive(self.m_smileBoost.gameObject, false)
      end
    end)
  end
end

function MainOrderCell:UpdateCookingFrenzyOrderReward()
  local cfModel = GM.ActivityManager:GetModel(ActivityType.CookingFrenzy)
  if cfModel:GetCurBuffConifgByOrder(self:GetOrder()) ~= nil then
    if self.m_cookingFrenzyReward == nil then
      GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.CookingFrenzyOrderReward), self.m_CookingFrenzyRewardRectTrans, Vector3.zero, function(gameObject)
        if self.m_cookingFrenzyReward ~= nil then
          AddressableLoader.Destroy(gameObject)
          return
        end
        local config = cfModel:GetCurBuffConifgByOrder(self:GetOrder())
        self.m_cookingFrenzyReward = gameObject:GetLuaTable()
        if config ~= nil then
          UIUtil.SetActive(self.m_cookingFrenzyReward.gameObject, true)
          self.m_cookingFrenzyReward:Init(config, self:GetOrder(), self)
        else
          UIUtil.SetActive(self.m_cookingFrenzyReward.gameObject, false)
        end
      end)
    else
      local config = cfModel:GetCurBuffConifgByOrder(self:GetOrder())
      self.m_cookingFrenzyReward:Init(config, self:GetOrder(), self)
      UIUtil.SetActive(self.m_cookingFrenzyReward.gameObject, true)
    end
  elseif self.m_cookingFrenzyReward ~= nil then
    self.m_cookingFrenzyReward:PlayDestroyAni()
    self.m_cookingFrenzyReward = nil
  end
end

function MainOrderCell:RemoveCookingFrenzyOrderReward()
  AddressableLoader.Destroy(self.m_cookingFrenzyReward.gameObject)
  self.m_cookingFrenzyReward = nil
end

function MainOrderCell:PlayHideOrderBoostReward()
  if self.m_smileBoost ~= nil then
    self.m_smileBoost:PlayHideOrderBoostReward()
  end
end

function MainOrderCell:GetBuffRewardTransByType(type)
  if self.m_buffReward == nil then
    return nil
  end
  return self.m_buffReward:GetRewardTransByType(type)
end

function MainOrderCell:GetCookingFrenzy()
  return self.m_cookingFrenzyReward
end

function MainOrderCell:_UpdateServeButtonPosition()
  BaseOrderCell._UpdateServeButtonPosition(self)
  if self.m_RewardsVert ~= nil then
    self.m_RewardsVert.transform.localScale = self.m_rewards.localScale
    self.m_rewards.localScale = Vector3(1, 1, 1)
  end
  if UIHelper.IsUsingOrderButtonNewPositionType() then
    return
  end
  local buffRewrads = self.m_order:GetBuffRewards()
  if Table.IsEmpty(buffRewrads) then
    return
  end
  UIUtil.SetAnchoredPosition(self.m_button, nil, self.m_button.anchoredPosition.y + 25, nil)
end

function MainOrderCell:GetBuffRewardLuaTable()
  if self.m_buffReward == nil then
    return nil
  end
  return self.m_buffReward
end

function MainOrderCell:GetRewardsTrans()
  return self.m_rewards
end

local function GetDisplayRewardFromSplitRewards(splitRewards, activityDefinitionSet)
  if Table.IsEmpty(splitRewards) then
    return nil
  end
  for _, reward in ipairs(splitRewards) do
    for activityType, activityDefinition in pairs(activityDefinitionSet) do
      if reward.model:GetType() == activityType then
        return reward.reward, reward.model
      end
    end
  end
  return nil
end

local function GetDisplayRewardFromSplitRewardsByActivityType(splitRewards, activityType)
  if Table.IsEmpty(splitRewards) then
    return nil
  end
  for _, reward in ipairs(splitRewards) do
    if reward.model:GetType() == activityType then
      return reward.reward, reward.model
    end
  end
  return nil
end

local function GetDisplayRewardFromActivityType(activityType, order)
  local model = GM.ActivityManager:GetModel(activityType)
  if model:GetState() ~= ActivityState.Started then
    return nil
  end
  return model:GetGenerateItemByOrder(order)
end

local function GetDisplayRewardFromActivityDefinitionSet(activityDefinitionSet, order)
  for activityType, _ in pairs(activityDefinitionSet) do
    local displayReward = GetDisplayRewardFromActivityType(activityType, order)
    if displayReward ~= nil then
      return displayReward
    end
  end
  return nil
end

function MainOrderCell:_AddSpecialRewards(arrRewards)
  BaseOrderCell._AddSpecialRewards(self, arrRewards)
  local rightDownReward, model = GetDisplayRewardFromSplitRewards(arrRewards, AlbumActivityDefinition)
  if rightDownReward ~= nil then
    self:_AddOneSpecialReward("Album", rightDownReward, UIPrefabConfigName.AlbumSetReward, Vector3(322, -380, 0), nil, model)
  end
  local displayRewardInfo = {
    {
      Key = "MapExplore",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, MapExploreActivityDefinition)
    },
    {
      Key = "Puzzle",
      Reward = GetDisplayRewardFromActivityType(ActivityType.Puzzle, self.m_order)
    },
    {
      Key = "WheelPack",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, WheelPackActivityDefinition)
    },
    {
      Key = "Adventure",
      Reward = GetDisplayRewardFromActivityDefinitionSet(AdventureActivityDefinition, self.m_order)
    },
    {
      Key = "AdventureEnergy",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, AdventureActivityDefinition)
    },
    {
      Key = "Farmboard",
      Reward = GetDisplayRewardFromActivityDefinitionSet(FarmboardActivityDefinition, self.m_order)
    },
    {
      Key = "Break",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, BreakDefinition)
    },
    {
      Key = "Multiboards",
      Reward = GetDisplayRewardFromActivityDefinitionSet(MultiboardsActivityDefinition, self.m_order)
    },
    {
      Key = "MultiboardsEnergy",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, MultiboardsActivityDefinition)
    },
    {
      Key = "Stickerboard",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, StickerboardActivityDefinition)
    },
    {
      Key = "PureBoard",
      Reward = GetDisplayRewardFromActivityDefinitionSet(PureBoardActivityDefinition, self.m_order)
    },
    {
      Key = "Pairwork",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, PairworkDefinition)
    },
    {
      Key = "Dig",
      Reward = GetDisplayRewardFromActivityDefinitionSet(DigActivityDefinition, self.m_order)
    },
    {
      Key = "Freefall",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, FreefallActivityDefinition)
    },
    {
      Key = "Pairup",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, PairupActivityDefinition)
    },
    {
      Key = "combo",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, ComboActivityDefinition)
    },
    {
      Key = "Exped",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, ExpedDefinition)
    },
    {
      Key = "Battle",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, BattleActivityDefinition)
    },
    {
      Key = "Team",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, TeamActivityDefinition)
    },
    {
      Key = "ScoreRace",
      Reward = GetDisplayRewardFromActivityType(ActivityType.ScoreRace, self.m_order)
    },
    {
      Key = "Avenue",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, AvenueDefinition)
    },
    {
      Key = "Road",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, RoadDefinition)
    },
    {
      Key = "Ring",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, RingDefinition)
    },
    {
      Key = "FloatRace",
      Reward = GetDisplayRewardFromSplitRewardsByActivityType(arrRewards, ActivityType.FloatRace)
    },
    {
      Key = "Upward",
      Reward = GetDisplayRewardFromSplitRewards(arrRewards, UpwardDefinition)
    }
  }
  if GameConfig.IsTestMode() then
    for _, reward in ipairs(arrRewards) do
      if GM.ActivityModuleManager:IsOrderSpecialReward(reward.reward[PROPERTY_TYPE]) then
        local bFind = false
        for _, info in ipairs(displayRewardInfo) do
          if info.Reward ~= nil and info.Reward[PROPERTY_TYPE] == reward.reward[PROPERTY_TYPE] then
            bFind = true
            break
          end
        end
        if not bFind then
          Log.Error("\232\175\183\230\179\168\229\134\140DisplayRewardInfo\231\154\132\233\161\186\229\186\143" .. tostring(reward.reward[PROPERTY_TYPE]))
        end
      end
    end
  end
  local leftDownRewardCount = 0
  for _, info in ipairs(displayRewardInfo) do
    leftDownRewardCount = leftDownRewardCount + (info.Reward ~= nil and 1 or 0)
  end
  local innerType = self.m_order:GetInnerType()
  local leftDownRewardPosition
  if innerType == MainOrderType.TimedOrder and 1 < leftDownRewardCount then
    leftDownRewardPosition = Vector3(33, -360, 0)
  elseif innerType == MainOrderType.Contiorder and 1 < leftDownRewardCount then
    leftDownRewardPosition = Vector3(33, -360, 0)
  elseif innerType == MainOrderType.ExtraCustomer and GM.ActivityManager:GetModel(ActivityType.ExtraCustomer):CanShowCountDown() then
    leftDownRewardPosition = Vector3(33, -360, 0)
  else
    leftDownRewardPosition = Vector3(39, -380, 0)
  end
  local scale
  if innerType == MainOrderType.TimedOrder and 1 < leftDownRewardCount then
    scale = 0.8
  elseif innerType == MainOrderType.ExtraCustomer and GM.ActivityManager:GetModel(ActivityType.ExtraCustomer):CanShowCountDown() then
    scale = 0.8
  elseif innerType == MainOrderType.Contiorder and 1 < leftDownRewardCount then
    scale = 0.8
  end
  local rewardPadding = 80
  if innerType == MainOrderType.TimedOrder and 1 < leftDownRewardCount then
    rewardPadding = 50
  elseif innerType == MainOrderType.ExtraCustomer and GM.ActivityManager:GetModel(ActivityType.ExtraCustomer):CanShowCountDown() then
    rewardPadding = 50
  elseif innerType == MainOrderType.Contiorder and 1 < leftDownRewardCount then
    rewardPadding = 50
  end
  for _, info in ipairs(displayRewardInfo) do
    if info.Reward ~= nil then
      self:_AddOneSpecialReward(info.Key, info.Reward, UIPrefabConfigName.OrderLeftDownRewardItem, leftDownRewardPosition, scale)
      leftDownRewardPosition = leftDownRewardPosition + Vector3(rewardPadding, 0, 0)
    end
  end
end

function MainOrderCell:GetOrderSmileRewardBox()
  return self.m_smileBoost
end

function MainOrderCell:PlayShowAlbumBuffReward()
  if self.m_specialRewardObjects.Album ~= nil and not self.m_specialRewardObjects.Album:IsNull() then
    self.m_specialRewardObjects.Album:GetLuaTable():PlayShowAlbumBuffReward()
  end
end

function MainOrderCell:LoadButterfly(callback)
  if self.m_butterflyGo ~= nil and not self.m_butterflyGo:IsNull() then
    return
  end
  UIUtil.SetActive(self.m_butterflyRectTrans.gameObject, false)
  local _, def = GM.ActivityManager:GetStartedButterflyActivity()
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName[def.FlyItemName]), self.m_butterflyRectTrans, V3Zero, function(go)
    self.m_butterflyGo = go
    self.m_butterflyGo:GetLuaTable():Init()
    self.m_butterflyGo:GetLuaTable():SetOrderCellComponent(true)
    if callback then
      callback()
    end
  end)
end

function MainOrderCell:ShowButterfly()
  UIUtil.SetActive(self.m_butterflyRectTrans.gameObject, true)
  if self.m_butterflyGo then
    self.m_butterflyGo:GetLuaTable():AnimationCountdownShow()
    self.m_butterflyGo:GetLuaTable():UpdatePerSecond()
    self.m_butterflyGo:GetLuaTable():SetSpineAnim("OrderIdle")
  end
end

function MainOrderCell:HideButterfly()
  if self.m_butterflyGo then
    AddressableLoader.Destroy(self.m_butterflyGo)
    self.m_butterflyGo = nil
  end
  UIUtil.SetActive(self.m_butterflyRectTrans.gameObject, false)
end

function MainOrderCell:GetButterflyPos()
  return self.m_butterflyRectTrans.position
end

SpecialOrderCell = setmetatable({}, MainOrderCell)
SpecialOrderCell.__index = SpecialOrderCell

function SpecialOrderCell:_UpdateReward()
  self.m_rewards.gameObject:SetActive(true)
end

function SpecialOrderCell:GetDisplayRewards()
  return Table.Empty
end

function SpecialOrderCell:OnGoButtonClicked()
  if self.m_bGoButtonEnabled == false then
    return
  end
  GM.AudioModel:PlayEffect("sfxOrderServe")
  GM.UIManager:OpenView(UIPrefabConfigName.SpecialOrderItemWindow, self.m_order)
end

function SpecialOrderCell:OnSpecialRewardClicked()
  if self.m_order:GetInnerType() ~= MainOrderType.Special then
    return
  end
  GM.UIManager:OpenView(UIPrefabConfigName.SpecialOrderRewardWindow, self.m_order)
end
