local nStart = 0

local function autoIncrease()
  nStart = nStart + 1
  return nStart
end

local EAnimationType = {
  SpreadReady = autoIncrease(),
  Tap = autoIncrease(),
  Prompt = autoIncrease(),
  PromptBack = autoIncrease(),
  BubbleIdle = autoIncrease(),
  TimeSkip = autoIncrease(),
  MergeLight = autoIncrease(),
  GeneratorBoost = autoIncrease(),
  NoCD = autoIncrease(),
  Jump = autoIncrease(),
  Move2Board = autoIncrease()
}
nStart = 0
local EEffectType = {
  Tail = autoIncrease(),
  Bonus = autoIncrease(),
  MergeLightAppear = autoIncrease(),
  MergeLightRepeat = autoIncrease(),
  MergeLightDisappear = autoIncrease(),
  LuckyProduce = autoIncrease(),
  LuckyProduceUpper = autoIncrease(),
  LuckyProduceFly = autoIncrease(),
  SpreadLight = autoIncrease(),
  SpreadFly = autoIncrease(),
  Retrieve = autoIncrease(),
  MaxLevelCollect = autoIncrease(),
  ItemSpreadFocus = autoIncrease(),
  MaxLevelCollectTip = autoIncrease(),
  Affected = autoIncrease(),
  AffectedLoop = autoIncrease(),
  TimeSkip = autoIncrease(),
  BubbleBreak = autoIncrease(),
  RewardItem = autoIncrease(),
  ObstacleReward = autoIncrease()
}
local KeepOnRecycleInfo = {keepOnRecycle = true}
local KeepOnRecycleParticleInfo = {keepOnRecycle = true, particle = true}
local EffectInfo = {
  [EEffectType.Tail] = Table.Empty,
  [EEffectType.Bonus] = KeepOnRecycleInfo,
  [EEffectType.MergeLightAppear] = KeepOnRecycleParticleInfo,
  [EEffectType.MergeLightRepeat] = KeepOnRecycleInfo,
  [EEffectType.MergeLightDisappear] = KeepOnRecycleParticleInfo,
  [EEffectType.LuckyProduce] = Table.Empty,
  [EEffectType.LuckyProduceUpper] = Table.Empty,
  [EEffectType.SpreadLight] = Table.Empty,
  [EEffectType.Retrieve] = Table.Empty,
  [EEffectType.MaxLevelCollect] = KeepOnRecycleInfo,
  [EEffectType.ItemSpreadFocus] = KeepOnRecycleParticleInfo,
  [EEffectType.MaxLevelCollectTip] = Table.Empty,
  [EEffectType.Affected] = Table.Empty,
  [EEffectType.AffectedLoop] = Table.Empty,
  [EEffectType.TimeSkip] = Table.Empty,
  [EEffectType.BubbleBreak] = Table.Empty,
  [EEffectType.RewardItem] = KeepOnRecycleInfo,
  [EEffectType.ObstacleReward] = Table.Empty
}
ItemView = {}
ItemView.__index = ItemView
ItemView.MoveDuration = 0.2

function ItemView:Init(itemModel, spriteMapping)
  if self.m_components ~= nil then
    self:_ResetItemDisplay()
  end
  self.m_model = itemModel
  self.m_spriteMapping = spriteMapping
  self.m_components = self.m_components or {}
  self.m_tweens = self.m_tweens or {}
  self.m_effects = self.m_effects or {}
  self.transform.localPosition = self:_GetLocalPosition(self.m_model:GetPosition())
  local itemBubble = itemModel:GetComponent(ItemBubble)
  local itemPropertyBubble = itemModel:GetComponent(ItemPropertyBubble)
  local itemCobweb = itemModel:GetComponent(ItemCobweb)
  local itemTemp = itemModel:GetComponent(ItemTemp)
  local itemStateCollection = itemModel:GetComponent(ItemStateCollection)
  local itemLocked = itemModel:GetComponent(ItemLocked)
  if itemBubble ~= nil then
    SpriteUtil.SetSpriteRenderer(self.m_spriteRenderer, itemBubble:GetSpriteName())
    local innerSpriteName = self:GetSpriteName(itemBubble:GetInnerItemCode())
    SpriteUtil.SetSpriteRenderer(self.m_innerSpriteRenderer, innerSpriteName)
    local _, bSale = itemBubble:GetBreakCost()
    UIUtil.SetActive(self.m_saleGo, bSale)
    self:_PlayBubbleIdleAnimation()
    EventDispatcher.AddListener(EEventType.BubbleSaleStateChanged, self, self.UpdateBubbleSale)
  elseif itemPropertyBubble ~= nil then
    SpriteUtil.SetSpriteRenderer(self.m_spriteRenderer, itemPropertyBubble:GetSpriteName())
    self:_PlayBubbleIdleAnimation()
  elseif itemCobweb ~= nil then
    local spriteName = self:GetSpriteName(itemCobweb:GetInnerItemCode())
    SpriteUtil.SetSpriteRenderer(self.m_spriteRenderer, spriteName)
  elseif itemTemp ~= nil then
    SpriteUtil.SetSpriteRenderer(self.m_spriteRenderer, ImageFileConfigName.item_temp)
    local innerSpriteName = self:GetSpriteName(itemTemp:GetInnerItemCode())
    SpriteUtil.SetSpriteRenderer(self.m_innerSpriteRenderer, innerSpriteName)
  elseif itemStateCollection ~= nil then
    local spriteName = self:GetSpriteName(itemStateCollection:GetStateType())
    SpriteUtil.SetSpriteRenderer(self.m_spriteRenderer, spriteName)
  elseif itemLocked ~= nil then
  else
    local spriteName = self:GetSpriteName(itemModel:GetType())
    SpriteUtil.SetSpriteRenderer(self.m_spriteRenderer, spriteName)
    if itemModel:GetType() == ItemType.RewardBubble then
      if self.m_effects[EEffectType.RewardItem] == nil then
        self.m_effects[EEffectType.RewardItem] = Object.Instantiate(self.m_rewardItemEffectPrefab, self.transform)
      end
      self:_PlayBubbleIdleAnimation()
    end
  end
  AddHandlerAndRecordMap(self.m_model.event, ItemEventType.SetPosition, {
    obj = self,
    method = self._MoveToBoardPosition
  })
  EventDispatcher.AddListener(EEventType.OrderStateChanged, self, self._UpdateChecked)
  if itemModel:GetComponent(ItemGeneratorFactory) ~= nil then
    EventDispatcher.AddListener(EEventType.GeneratorFactoryStateChanged, self, self._UpdateGeneratorFactoryState)
    self:_UpdateGeneratorFactoryState()
  end
  self:_UpdateChecked()
  self:_UpdateStar()
  self:_UpdateItemBonus()
  if self.m_model:IsShowCollectEffect() then
    self:ShowMaxCollectEffect()
  end
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ResourceCollectHint) then
    local canTypeShow, hasShowedTip = GM.ItemDataModel:CanShowCollectTip(self.m_model:GetType())
    if canTypeShow then
      EventDispatcher.AddListener(EEventType.ChangeGameMode, self, self._UpdateMaxCollectTip)
      EventDispatcher.AddListener(EEventType.TutorialFinished, self, self._UpdateMaxCollectTip)
      EventDispatcher.AddListener(EEventType.TutorialAnyStrongTutorialUpdated, self, self._UpdateMaxCollectTip)
      self:_UpdateMaxCollectTip()
    end
  end
  local itemSpread = itemModel:GetComponent(ItemSpread)
  if itemSpread ~= nil then
    if itemSpread:GetState() == ItemSpreadState.Closed then
      self:UpdateExclamation(not itemModel:GetBoardModel():HasOpeningItem())
    else
      self:UpdateExclamation(false)
    end
  else
    self:UpdateExclamation(false)
  end
end

function ItemView:GetSpriteName(itemType)
  if self.m_spriteMapping ~= nil and IsTable(self.m_spriteMapping[itemType]) and #self.m_spriteMapping[itemType] > 0 then
    return Table.ListRandomSelectOne(self.m_spriteMapping[itemType])
  else
    return GM.ItemDataModel:GetSpriteName(itemType)
  end
end

function ItemView:AddComponent(componentMetatable, component)
  component:SetItemView(self)
  self.m_components[componentMetatable] = component
end

function ItemView:GetComponent(type)
  return self.m_components[type]
end

function ItemView:GetModel()
  return self.m_model
end

function ItemView:GetSpriteRenderer()
  return self.m_spriteRenderer
end

function ItemView:GetInnerSpriteRenderer()
  return self.m_innerSpriteRenderer
end

function ItemView:OnDestroy()
  if self.m_model == nil then
    return
  end
  EventDispatcher.RemoveTarget(self)
  RemoveAllHandlers(self.m_model.event, self)
  for type, tween in pairs(self.m_tweens) do
    if tween:IsActive() then
      tween:Kill()
    end
    self.m_tweens[type] = nil
  end
  self.m_model = nil
end

function ItemView:OnRecycle()
  self:SetFlying(false)
  for _, comp in pairs(self.m_components) do
    comp:OnRecycle()
  end
  self:OnDestroy()
  self:RemoveLuckySpreadEffect()
  self.m_lastAffectedEffect = nil
  self.m_lastAffectedEffectLoop = nil
  self.m_bShoNoCDAct = nil
  for type, effect in pairs(self.m_effects) do
    if EffectInfo[type] ~= nil and EffectInfo[type].keepOnRecycle then
      if EffectInfo[type].particle then
        effect:Stop()
      end
    else
      if not effect:IsNull() then
        if EffectInfo[type] ~= nil and EffectInfo[type].particle then
          effect.gameObject:RemoveSelf()
        else
          effect:RemoveSelf()
        end
      end
      self.m_effects[type] = nil
    end
  end
end

local Scale = V3One
local Position = V3Zero
local InnerScale = Vector3(0.8, 0.8, 1)

function ItemView:_ResetItemDisplay()
  self.transform.localScale = Scale
  local spriteTransform = self.m_spriteRenderer.transform
  spriteTransform.localScale = Scale
  spriteTransform.localPosition = Position
  UIUtil.SetAlpha(self.m_spriteRenderer, 1)
  local innerSpriteTransform = self.m_innerSpriteRenderer.transform
  innerSpriteTransform.localScale = InnerScale
  innerSpriteTransform.localPosition = Position
  UIUtil.SetAlpha(self.m_innerSpriteRenderer, 1)
end

function ItemView:_UpdateChecked()
  if self.m_checkGo:IsNull() then
    Log.Assert(false, "m_checkGo\228\184\141\232\131\189\228\184\186\231\169\186")
    return
  end
  local codeStateMap = self.m_model:GetBoardModel():GetOrderCodeStateMap()
  if codeStateMap[self.m_model:GetCode()] ~= nil then
    UIUtil.SetActive(self.m_checkGo, true)
    return
  end
  UIUtil.SetActive(self.m_checkGo, false)
end

function ItemView:_UpdateGeneratorFactoryState()
  local itemGeneratorFactory = self.m_model:GetComponent(ItemGeneratorFactory)
  if itemGeneratorFactory ~= nil then
    local bOpen = itemGeneratorFactory:IsGeneratorFactoryOpen()
    if bOpen then
      if self.m_effects[EEffectType.RewardItem] == nil then
        self.m_effects[EEffectType.RewardItem] = Object.Instantiate(self.m_rewardItemEffectPrefab, self.transform)
      end
      self:_PlayBubbleIdleAnimation()
    else
      if self.m_effects[EEffectType.RewardItem] ~= nil then
        self.m_effects[EEffectType.RewardItem]:RemoveSelf()
        self.m_effects[EEffectType.RewardItem] = nil
      end
      self:_StopAnimation(EAnimationType.BubbleIdle)
    end
  end
end

function ItemView:UpdateExclamation(show)
  if show ~= self.m_exclamationGo.activeSelf then
    self.m_exclamationGo:SetActive(show)
  end
end

function ItemView:UpdateBubbleSale()
  local itemBubble = self.m_model:GetComponent(ItemBubble)
  if itemBubble then
    local _, bSale = itemBubble:GetBreakCost()
    UIUtil.SetActive(self.m_saleGo, bSale)
  end
end

function ItemView:HideBubbleSale()
  UIUtil.SetActive(self.m_saleGo, false)
end

function ItemView:_UpdateStar()
  if self.m_model:GetComponent(ItemSwallow) == nil and self.m_model:GetComponent(ItemBubble) == nil and self.m_model:GetComponent(ItemPropertyBubble) == nil and self.m_model:GetComponent(ItemPaperBox) == nil and self.m_model:GetComponent(ItemCobweb) == nil and self.m_model:GetComponent(ItemFog) == nil and self.m_model:GetComponent(ItemTemp) == nil and self.m_model:GetComponent(ItemSplit) == nil and self.m_model:GetComponent(ItemDig) == nil and self.m_model:GetComponent(ItemPortal) == nil and self.m_model:GetComponent(ItemLocked) == nil and self.m_model:GetType() ~= ItemType.RewardBubble then
    local chainId = GM.ItemDataModel:GetChainId(self.m_model:GetType())
    local level = GM.ItemDataModel:GetChainLevel(self.m_model:GetType())
    if level == GM.ItemDataModel:GetChainMaxLevel(chainId) and self.m_model:GetMergedType() == nil then
      self.m_starGo:SetActive(true)
    end
  end
end

function ItemView:_UpdateItemBonus()
  if self.m_effects[EEffectType.Bonus] == nil then
    local cardItemModel = GM.ActivityManager:GetModel(ActivityType.CardItem)
    if self.m_model:GetSpecialType() == ItemSpecialType.LevelUp then
      self.m_effects[EEffectType.Bonus] = Object.Instantiate(self.m_levelupPiecePrefab, self.transform)
    elseif cardItemModel:IsCardItemAndMaxLevel(self.m_model:GetType()) then
      self.m_effects[EEffectType.Bonus] = Object.Instantiate(self.m_levelupPiecePrefab, self.transform)
    end
  end
end

function ItemView:SetFlying(flying)
  if flying then
    self.m_starGo:SetActive(false)
    self.m_checkGo:SetActive(false)
  else
    self:_UpdateStar()
    self:_UpdateChecked()
  end
  for _, component in pairs(self.m_components) do
    component:SetFlying(flying)
  end
end

function ItemView:_MoveToBoardPosition(boardPosition)
  if self.m_tweens[EAnimationType.Jump] ~= nil then
    self.m_tweens[EAnimationType.Jump]:Complete(true)
    self.m_tweens[EAnimationType.Jump] = nil
    self.transform.localScale = V3One
  end
  self.m_tweens[EAnimationType.Move2Board] = self.transform:DOLocalMove(self:_GetLocalPosition(boardPosition), ItemView.MoveDuration)
end

function ItemView:_GetLocalPosition(boardPosition)
  local boardModel = self.m_model:GetBoardModel()
  local localPosition = boardModel:ToLocalPosition(boardPosition)
  local zIndex = boardModel.HorizontalTiles * boardModel.VerticalTiles - boardModel.HorizontalTiles * (boardPosition:GetY() - 1) - boardPosition:GetX() + 1
  return Vector3(localPosition.x + boardModel.TileSize / 2, localPosition.y + boardModel.TileSize / 2, zIndex * 10)
end

function ItemView:MergeLightAppear()
  if self.m_effects[EEffectType.MergeLightAppear] == nil and self.m_mergeLightAppearPrefab and not self.m_mergeLightAppearPrefab:IsNull() then
    self.m_effects[EEffectType.MergeLightAppear] = Object.Instantiate(self.m_mergeLightAppearPrefab, self.transform):GetComponent(typeof(ParticleSystem))
  end
  if self.m_effects[EEffectType.MergeLightRepeat] ~= nil then
    self.m_effects[EEffectType.MergeLightAppear]:Play()
  end
  if self.m_tweens[EAnimationType.MergeLight] ~= nil then
    self.m_tweens[EAnimationType.MergeLight]:Kill()
    self.m_tweens[EAnimationType.MergeLight] = nil
  end
  self.m_tweens[EAnimationType.MergeLight] = DOVirtual.DelayedCall(0.34, function()
    if self.m_effects[EEffectType.MergeLightRepeat] == nil and self.m_mergeLightContinuePrefab and not self.m_mergeLightContinuePrefab:IsNull() then
      self.m_effects[EEffectType.MergeLightRepeat] = Object.Instantiate(self.m_mergeLightContinuePrefab, self.transform)
    end
    if self.m_effects[EEffectType.MergeLightRepeat] ~= nil then
      UIUtil.SetActive(self.m_effects[EEffectType.MergeLightRepeat], true)
    end
  end)
end

function ItemView:MergeLightDisappear()
  if self.m_tweens[EAnimationType.MergeLight] ~= nil then
    self.m_tweens[EAnimationType.MergeLight]:Kill()
    self.m_tweens[EAnimationType.MergeLight] = nil
  end
  if self.m_effects[EEffectType.MergeLightRepeat] ~= nil then
    UIUtil.SetActive(self.m_effects[EEffectType.MergeLightRepeat], false)
  end
  if self.m_effects[EEffectType.MergeLightDisappear] == nil and self.m_mergeLightDisappearPrefab and not self.m_mergeLightDisappearPrefab:IsNull() then
    self.m_effects[EEffectType.MergeLightDisappear] = Object.Instantiate(self.m_mergeLightDisappearPrefab, self.transform):GetComponent(typeof(ParticleSystem))
  end
  if self.m_effects[EEffectType.MergeLightDisappear] ~= nil then
    self.m_effects[EEffectType.MergeLightDisappear]:Play()
  end
end

function ItemView:ShowTail(energyBoost, spreadType)
  self:RemoveTail()
  self.m_spreadTailType = spreadType
  if self.m_model:GetType() == ItemType.Temp then
    self.m_effects[EEffectType.Tail] = Object.Instantiate(self.m_spreadTailTempItemPrefab, self.transform)
    return true
  elseif spreadType == BoardSpreadType.Dig then
    self.m_effects[EEffectType.Tail] = Object.Instantiate(self.m_spreadTailDigPrefab, self.transform)
    return true
  elseif spreadType == BoardSpreadType.GeneratorBoostExtra or spreadType == BoardSpreadType.GeneratorBoostExtraLucky or spreadType == BoardSpreadType.GeneratorBoostExtraNormal or spreadType == BoardSpreadType.GeneratorBoostExtraSmart then
    self.m_effects[EEffectType.Tail] = Object.Instantiate(self.m_spreadTailGeneratorBoostPrefab, self.transform)
    return true
  elseif spreadType == BoardSpreadType.Disco then
    local prefabName = GM.BoostChargeManager:GetHandler(EBoostChargeType.BoostCharge_disco):GetItemSpreadTrail()
    self:AddAsyncEffectSpread(spreadType, EEffectType.Tail, prefabName, Vector3(0, 0, 10))
    return true
  elseif spreadType == BoardSpreadType.DoubleLucky or spreadType == BoardSpreadType.TripleLucky1 then
    self.m_effects[EEffectType.Tail] = Object.Instantiate(self.m_spreadTailConti2Prefab, self.transform)
    return true
  elseif spreadType == BoardSpreadType.TripleLucky2 then
    self.m_effects[EEffectType.Tail] = Object.Instantiate(self.m_spreadTailConti3Prefab, self.transform)
    return true
  elseif spreadType == BoardSpreadType.CardItem then
    local prefabName = UIPrefabConfigName.carditem_effect_qizi_Trail
    self:AddAsyncEffectSpread(spreadType, EEffectType.Tail, prefabName, Vector3(0, 0, 10))
    return true
  elseif spreadType == BoardSpreadType.UIBoardEnergy then
  elseif energyBoost ~= nil and 0 < energyBoost then
    if energyBoost == 3 then
      self.m_effects[EEffectType.Tail] = Object.Instantiate(self.m_spreadTailEightEnergyBoostPrefab, self.transform)
    else
      self.m_effects[EEffectType.Tail] = Object.Instantiate(self.m_spreadTailEnergyBoostPrefab, self.transform)
    end
    return true
  end
  return false
end

function ItemView:AddAsyncEffectSpread(spreadType, effectType, prefabName, pos)
  self.m_effects[effectType] = CS.UnityEngine.GameObject()
  self.m_effects[effectType].name = spreadType
  self.m_effects[effectType].transform:SetParent(self.transform)
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(prefabName), self.transform, pos or Vector3.zero, function(go)
    if self.m_effects[effectType] == nil then
      AddressableLoader.Destroy(go)
      return
    end
    if self.m_effects[effectType].name ~= self.m_spreadTailType then
      AddressableLoader.Destroy(go)
      return
    end
    Object.Destroy(self.m_effects[effectType])
    self.m_effects[effectType] = go
  end)
end

function ItemView:RemoveTail()
  if self.m_effects[EEffectType.Tail] ~= nil then
    Object.Destroy(self.m_effects[EEffectType.Tail])
    self.m_effects[EEffectType.Tail] = nil
  end
end

function ItemView:ShowSpreadLight(energyBoost, spreadType)
  self.m_spreadLightType = spreadType
  local luckyProducePrefab, luckyProduceUpperPrefab
  if spreadType == BoardSpreadType.Lucky or spreadType == BoardSpreadType.FreeLucky then
    luckyProducePrefab = self.m_luckyProducePrefab
    luckyProduceUpperPrefab = self.m_luckyProduceUpperPrefab
  elseif spreadType == BoardSpreadType.SuperLucky or spreadType == BoardSpreadType.FreeSuperLucky then
    luckyProducePrefab = self.m_luckyProduceSuperPrefab
    luckyProduceUpperPrefab = self.m_luckyProduceSuperUpperPrefab
  elseif spreadType == BoardSpreadType.DoubleLucky or spreadType == BoardSpreadType.TripleLucky1 then
    luckyProducePrefab = self.m_luckyProduceConti2Prefab
    luckyProduceUpperPrefab = self.m_luckyProduceConti2UpperPrefab
  elseif spreadType == BoardSpreadType.TripleLucky2 then
    luckyProducePrefab = self.m_luckyProduceConti3Prefab
    luckyProduceUpperPrefab = self.m_luckyProduceConti3UpperPrefab
  elseif spreadType == BoardSpreadType.GeneratorBoostExtraLucky then
    luckyProduceUpperPrefab = self.m_spreadLightGeneratorBoostExtraLuckyPrefab
  end
  if luckyProducePrefab ~= nil then
    if self.m_effects[EEffectType.LuckyProduce] ~= nil and not self.m_effects[EEffectType.LuckyProduce]:IsNull() then
      self.m_effects[EEffectType.LuckyProduce]:RemoveSelf()
    end
    self.m_effects[EEffectType.LuckyProduce] = Object.Instantiate(luckyProducePrefab, self.transform)
  end
  if luckyProduceUpperPrefab ~= nil then
    if self.m_effects[EEffectType.LuckyProduceUpper] ~= nil and not self.m_effects[EEffectType.LuckyProduceUpper]:IsNull() then
      self.m_effects[EEffectType.LuckyProduceUpper]:RemoveSelf()
    end
    self.m_effects[EEffectType.LuckyProduceUpper] = Object.Instantiate(luckyProduceUpperPrefab, self.transform)
  end
  if self.m_effects[EEffectType.SpreadLight] ~= nil and not self.m_effects[EEffectType.SpreadLight]:IsNull() then
    self.m_effects[EEffectType.SpreadLight]:RemoveSelf()
    self.m_effects[EEffectType.SpreadLight] = nil
  end
  if self.m_model:GetType() == ItemType.Temp then
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self.m_spreadLightTempItemPrefab, self.transform)
  elseif spreadType == BoardSpreadType.Disco then
    local prefabName = GM.BoostChargeManager:GetHandler(EBoostChargeType.BoostCharge_disco):GetItemSpreadArriveEffect()
    self:AddAsyncEffect(EEffectType.SpreadLight, prefabName, 1, function()
      return self.m_spreadLightType
    end)
  elseif spreadType == BoardSpreadType.CardItem then
    local prefabName = UIPrefabConfigName.carditem_effect_bomb
    self:AddAsyncEffectSpread(spreadType, EEffectType.SpreadLight, prefabName, Vector3(0, 0, 10))
  elseif spreadType == BoardSpreadType.Dig then
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self.m_spreadLightDigPrefab, self.transform)
  elseif spreadType == BoardSpreadType.OrderBoostPro then
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self.m_spreadLightOrderBoostProPrefab, self.transform)
  elseif spreadType == BoardSpreadType.GeneratorBoostExtra or spreadType == BoardSpreadType.GeneratorBoostExtraNormal or spreadType == BoardSpreadType.GeneratorBoostExtraSmart then
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self.m_spreadLightGeneratorBoostExtraPrefab, self.transform)
  elseif spreadType == BoardSpreadType.ObstacleReward then
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self.m_spreadObstacleRewardPrefab, self.transform)
    self.m_effects[EEffectType.ObstacleReward] = Object.Instantiate(self.m_spreadObstacleRewardBelowPrefab, self.transform)
  elseif spreadType == BoardSpreadType.UIBoardEnergy then
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self["m_uiBoardEnergySpreadLight" .. energyBoost], self.transform)
  elseif energyBoost then
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self.m_spreadLightEnergyBoostPrefab, self.transform)
  else
    self.m_effects[EEffectType.SpreadLight] = Object.Instantiate(self.m_spreadLightPrefab, self.transform)
  end
end

function ItemView:AddAsyncEffect(effectType, prefabName, delay, GetSpreadTypeFunc)
  self.m_effects[effectType] = CS.UnityEngine.GameObject()
  self.m_effects[effectType].name = GetSpreadTypeFunc()
  self.m_effects[effectType].transform:SetParent(self.transform)
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(prefabName), self.transform, Vector3.zero, function(go)
    if self.m_effects[effectType] == nil then
      AddressableLoader.Destroy(go)
      return
    end
    if self.m_effects[effectType].name ~= GetSpreadTypeFunc() then
      AddressableLoader.Destroy(go)
      return
    end
    Object.Destroy(self.m_effects[effectType])
    self.m_effects[effectType] = go
    if delay ~= nil then
      DelayExecuteFuncInView(function()
        if self.m_effects[effectType] == go and not go:IsNull() then
          AddressableLoader.Destroy(go)
          self.m_effects[effectType] = nil
        end
      end, delay, self)
    end
  end)
end

function ItemView:ShowSpreadFlyEffect(spreadType)
  self.m_flySpreadType = spreadType
  if self.m_model:GetType() == ItemType.Temp then
    self.m_effects[EEffectType.SpreadFly] = Object.Instantiate(self.m_spreadFlyTempItemPrefab, self.transform)
  elseif spreadType == BoardSpreadType.CardItem then
    self:AddAsyncEffect(EEffectType.SpreadFly, UIPrefabConfigName.carditem_effect_jumpcard, nil, function()
      return self.m_flySpreadType
    end)
  end
end

function ItemView:RemoveSpreadFlyEffect()
  if self.m_effects[EEffectType.SpreadFly] ~= nil and not self.m_effects[EEffectType.SpreadFly]:IsNull() then
    self.m_effects[EEffectType.SpreadFly]:RemoveSelf()
  end
  self.m_effects[EEffectType.SpreadFly] = nil
end

function ItemView:ShowRetrieveLight()
  if self.m_effects[EEffectType.Retrieve] ~= nil and not self.m_effects[EEffectType.Retrieve]:IsNull() then
    self.m_effects[EEffectType.Retrieve]:RemoveSelf()
  end
  self.m_effects[EEffectType.Retrieve] = Object.Instantiate(self.m_retrieveLightPrefab, self.transform)
end

function ItemView:ShowMaxCollectEffect()
  if self.m_effects[EEffectType.MaxLevelCollect] ~= nil then
    return
  end
  self.m_effects[EEffectType.MaxLevelCollect] = Object.Instantiate(self.m_maxEffectPrefab, self.transform)
end

function ItemView:ShowFocusEffect()
  if self.m_effects[EEffectType.ItemSpreadFocus] == nil then
    self.m_effects[EEffectType.ItemSpreadFocus] = Object.Instantiate(self.m_focusEffectPrefab, self.transform):GetComponent(typeof(ParticleSystem))
  end
  self.m_effects[EEffectType.ItemSpreadFocus]:Play()
end

function ItemView:ShowLuckySpreadEffect()
  if self.m_effects[EEffectType.LuckyProduceFly] == nil or self.m_effects[EEffectType.LuckyProduceFly]:IsNull() then
    self.m_effects[EEffectType.LuckyProduceFly] = GameObject.Instantiate(self.m_luckySpreadEffectPrefab, self.transform)
  end
  self.m_spriteRendererScale = self.m_spriteRenderer.transform.localScale
  self.m_spriteRenderer.transform.localScale = V3Zero
  self.m_checkScale = self.m_checkGo.transform.localScale
  self.m_checkGo.transform.localScale = V3Zero
end

function ItemView:RemoveLuckySpreadEffect()
  if self.m_effects[EEffectType.LuckyProduceFly] then
    Object.Destroy(self.m_effects[EEffectType.LuckyProduceFly])
    self.m_effects[EEffectType.LuckyProduceFly] = nil
    self.m_spriteRenderer.transform.localScale = self.m_spriteRendererScale
    self.m_spriteRendererScale = nil
    self.m_checkGo.transform.localScale = self.m_checkScale
    self.m_checkScale = nil
  end
end

function ItemView:UpdateMaxCollectTip(bShow)
  if bShow and self.m_effects[EEffectType.MaxLevelCollectTip] == nil then
    self.m_effects[EEffectType.MaxLevelCollectTip] = Object.Instantiate(self.m_maxCollectTipPrefab, self.transform)
  elseif not bShow and self.m_effects[EEffectType.MaxLevelCollectTip] then
    Object.Destroy(self.m_effects[EEffectType.MaxLevelCollectTip])
    self.m_effects[EEffectType.MaxLevelCollectTip] = nil
  end
end

function ItemView:_UpdateMaxCollectTip()
  local canTypeShow, hasShowedTip = GM.ItemDataModel:CanShowCollectTip(self.m_model:GetType())
  self:UpdateMaxCollectTip(canTypeShow and not hasShowedTip and not GM.TutorialModel:HasAnyStrongTutorialOngoing())
end

function ItemView:UpdateItemAffectedEffect(dragItemModel)
  local affectedEffect, loopEffect
  local setAlpha = false
  local dragSpecialItem = dragItemModel ~= nil and dragItemModel:GetSpecialType() ~= nil
  if dragSpecialItem then
    local specialType = dragItemModel:GetSpecialType()
    if self.m_model:CanSpecialTypeAffect(specialType) then
      if specialType == ItemSpecialType.LevelUp then
        affectedEffect = self.m_levelupEffectPrefab
      elseif specialType == ItemSpecialType.LevelDown and self.m_model:GetSpecialType() ~= ItemSpecialType.LevelDown then
        affectedEffect = self.m_leveldownEffectPrefab
      end
      loopEffect = self.m_targetEffectPrefab
    else
      setAlpha = self.m_model ~= dragItemModel and self.m_model:GetComponent(ItemPaperBox) == nil and self.m_model:GetComponent(ItemCobweb) == nil
    end
  end
  if affectedEffect ~= self.m_lastAffectedEffect then
    self.m_lastAffectedEffect = affectedEffect
    if self.m_effects[EEffectType.Affected] ~= nil then
      self.m_effects[EEffectType.Affected]:RemoveSelf()
      self.m_effects[EEffectType.Affected] = nil
    end
    if affectedEffect ~= nil then
      self.m_effects[EEffectType.Affected] = Object.Instantiate(affectedEffect, self.transform)
    end
  end
  if loopEffect ~= self.m_lastAffectedEffectLoop then
    self.m_lastAffectedEffectLoop = loopEffect
    if self.m_effects[EEffectType.AffectedLoop] ~= nil then
      self.m_effects[EEffectType.AffectedLoop]:RemoveSelf()
      self.m_effects[EEffectType.AffectedLoop] = nil
    end
    if loopEffect ~= nil then
      self.m_effects[EEffectType.AffectedLoop] = Object.Instantiate(loopEffect, self.transform)
    end
  end
  if dragSpecialItem then
    self.m_starGo:SetActive(false)
    self.m_checkGo:SetActive(false)
    if setAlpha then
      self.m_formerSpriteAlpha = self.m_spriteRenderer.color.a
      self.m_formerInnerSpriteAlpha = self.m_innerSpriteRenderer.color.a
      UIUtil.SetAlpha(self.m_spriteRenderer, math.min(self.m_formerSpriteAlpha, 0.5))
      UIUtil.SetAlpha(self.m_innerSpriteRenderer, math.min(self.m_formerInnerSpriteAlpha, 0.5))
      if self.m_effects[EEffectType.Bonus] then
        self.m_effects[EEffectType.Bonus]:SetActive(false)
      end
      for _, comp in pairs(self.m_components) do
        comp.gameObject:SetActive(false)
      end
    end
  else
    self:_UpdateStar()
    self:_UpdateChecked()
    if self.m_formerSpriteAlpha ~= nil then
      UIUtil.SetAlpha(self.m_spriteRenderer, self.m_formerSpriteAlpha)
      self.m_formerSpriteAlpha = nil
    end
    if self.m_formerInnerSpriteAlpha ~= nil then
      UIUtil.SetAlpha(self.m_innerSpriteRenderer, self.m_formerInnerSpriteAlpha)
      self.m_formerInnerSpriteAlpha = nil
    end
    if self.m_effects[EEffectType.Bonus] then
      self.m_effects[EEffectType.Bonus]:SetActive(true)
    end
    for _, comp in pairs(self.m_components) do
      comp.gameObject:SetActive(true)
    end
  end
end

function ItemView:PlayTapAnimation(range)
  local transform = self.m_spriteRenderer.transform
  local sequence = DOTween.Sequence()
  sequence:Append(transform:DOScaleX(1 - range, 0.1))
  sequence:Join(transform:DOScaleY(1 - range, 0.1))
  sequence:Append(transform:DOScaleX(1 + range, 0.2))
  sequence:Join(transform:DOScaleY(1 + range, 0.2))
  sequence:Append(transform:DOScaleX(1, 0.2))
  sequence:Join(transform:DOScaleY(1, 0.2))
  sequence:Append(transform:DOScaleX(1 + range / 2, 0.2))
  sequence:Join(transform:DOScaleY(1 + range / 2, 0.2))
  sequence:Append(transform:DOScaleX(1, 0.2))
  sequence:Join(transform:DOScaleY(1, 0.2))
  sequence:OnComplete(function()
    self.m_tweens[EAnimationType.Tap] = nil
  end)
  self.m_tweens[EAnimationType.Tap] = sequence
end

function ItemView:PlayPromptAnimation(targetPosition)
  self:StopPromptAnimation(false)
  local sequence = DOTween.Sequence()
  local transform = self.m_spriteRenderer.transform
  local hasCobweb = self.m_model:GetComponent(ItemCobweb)
  local movePos
  if hasCobweb or targetPosition == nil then
    movePos = V3Zero
  else
    local direction = Vector3.Normalize(targetPosition - transform.position)
    direction.z = 0
    movePos = 20 * direction
  end
  for i = 1, 3 do
    sequence:Append(transform:DOScale(1.15, 0.25):SetEase(Ease.OutCubic))
    sequence:Join(transform:DOLocalMove(movePos, 0.45):SetEase(Ease.OutCubic))
    sequence:AppendInterval(0.05)
    sequence:Append(transform:DOScale(1, 0.25))
    sequence:Join(transform:DOLocalMove(V3Zero, 0.5))
  end
  sequence:AppendInterval(2)
  sequence:SetLoops(-1)
  self.m_tweens[EAnimationType.Prompt] = sequence
end

function ItemView:StopPromptAnimation(ignoreAnim)
  if self.m_tweens[EAnimationType.Prompt] ~= nil then
    self:_StopAnimation(EAnimationType.Prompt)
    local transform = self.m_spriteRenderer.transform
    self:_StopAnimation(EAnimationType.PromptBack)
    if ignoreAnim ~= false then
      local duration = (transform.localScale.x - 1) / 0.19999999999999996 * 0.4
      local sequence = DOTween.Sequence()
      sequence:Insert(0, transform:DOScale(1, duration))
      sequence:Insert(0, transform:DOLocalMove(V3Zero, duration))
      sequence:OnComplete(function()
        self.m_tweens[EAnimationType.PromptBack] = nil
      end)
      self.m_tweens[EAnimationType.PromptBack] = sequence
    else
      transform.localScale = V3One
      transform.localPosition = V3Zero
    end
  end
end

function ItemView:_PlayBubbleIdleAnimation()
  local transform = self.m_spriteRenderer.transform
  local sequence = DOTween.Sequence()
  sequence:Append(transform:DOScale(0.98, 0.5))
  sequence:Insert(0, transform:DOLocalMove(Vector3(0, 3, 0), 0.5))
  sequence:Append(transform:DOScale(1.02, 1))
  sequence:Insert(0.5, transform:DOLocalMove(Vector3(0, -3, 0), 1))
  sequence:Append(transform:DOScale(V3One, 0.5))
  sequence:Insert(1.5, transform:DOLocalMove(V3Zero, 0.5))
  sequence:SetLoops(-1)
  self.m_tweens[EAnimationType.BubbleIdle] = sequence
end

function ItemView:PlayTimeSkipAnimation(delay)
  delay = delay or 0
  local sequence = DOTween.Sequence()
  local transform = self.m_spriteRenderer.transform
  sequence:Insert(delay, transform:DOLocalMoveY(30, 0.25):SetEase(Ease.OutCubic))
  sequence:Insert(delay + 0.25, transform:DOLocalMoveY(0, 0.25):SetEase(Ease.InCubic))
  sequence:InsertCallback(delay, function()
    if self.m_effects[EEffectType.TimeSkip] ~= nil then
      self.m_effects[EEffectType.TimeSkip]:RemoveSelf()
      self.m_effects[EEffectType.TimeSkip] = nil
    end
    self.m_effects[EEffectType.TimeSkip] = Object.Instantiate(self.m_timeSkipEffectPrefab, self.transform)
  end)
  sequence:InsertCallback(delay + 1, function()
    if self.m_effects[EEffectType.TimeSkip] ~= nil then
      self.m_effects[EEffectType.TimeSkip]:RemoveSelf()
      self.m_effects[EEffectType.TimeSkip] = nil
    end
    self.m_tweens[EAnimationType.TimeSkip] = nil
  end)
  self.m_tweens[EAnimationType.TimeSkip] = sequence
end

function ItemView:PlayShowNoCDItemAct()
  if self.m_bShoNoCDAct == true then
    return
  end
  self.m_bShoNoCDAct = true
  local sequence = DOTween.Sequence()
  local transform = self.m_spriteRenderer.transform
  sequence:AppendInterval(0.16666666666666666)
  sequence:Append(transform:DOLocalMoveY(53, 0.25))
  sequence:Join(transform:DOScaleY(1.0863, 0.25))
  sequence:Append(transform:DOLocalMoveY(0, 0.16666666666666666))
  sequence:Join(transform:DOScaleY(1, 0.16666666666666666))
  sequence:AppendCallback(function()
    self.m_bShoNoCDAct = false
    self.m_tweens[EAnimationType.NoCD] = nil
  end)
  self.m_tweens[EAnimationType.NoCD] = sequence
end

function ItemView:PlayGeneratorBoostBuffActiveAnimation()
  if self.m_bGeneratorBoostBuffAni == true then
    return
  end
  self.m_bGeneratorBoostBuffAni = true
  local sequence = DOTween.Sequence()
  local transform = self.m_spriteRenderer.transform
  sequence:AppendInterval(0.16666666666666666)
  local moveSeq = DOTween.Sequence()
  moveSeq:Append(transform:DOLocalMoveX(8, 0.03333333333333333))
  moveSeq:Append(transform:DOLocalMoveX(-8, 0.03333333333333333))
  moveSeq:Append(transform:DOLocalMoveX(0, 0.03333333333333333))
  sequence:Append(moveSeq:SetLoops(4, LoopType.Yoyo))
  sequence:Append(transform:DOScale(0.35, 0.16666666666666666))
  sequence:Append(transform:DOScale(0.95, 0.08333333333333333))
  sequence:Append(transform:DOScale(1, 0.08333333333333333))
  sequence:AppendCallback(function()
    self.m_bGeneratorBoostBuffAni = false
    self.m_tweens[EAnimationType.GeneratorBoost] = nil
  end)
  self.m_tweens[EAnimationType.GeneratorBoost] = sequence
end

function ItemView:ShowBubbleBreakLight()
  if self.m_effects[EEffectType.BubbleBreak] ~= nil then
    if not self.m_effects[EEffectType.BubbleBreak]:IsNull() then
      self.m_effects[EEffectType.BubbleBreak]:RemoveSelf()
    end
    self.m_effects[EEffectType.BubbleBreak] = nil
  end
  self.m_effects[EEffectType.BubbleBreak] = Object.Instantiate(self.m_bubbleBreakLightPrefab, self.transform)
end

function ItemView:SetJumpTween(tween)
  if self.m_tweens[EAnimationType.Jump] ~= nil then
    self.m_tweens[EAnimationType.Jump]:Kill()
    self.m_tweens = nil
  end
  self.m_tweens[EAnimationType.Jump] = tween
end

function ItemView:_StopAnimation(type)
  if self.m_tweens[type] ~= nil then
    self.m_tweens[type]:Kill()
    self.m_tweens[type] = nil
  end
end
