BaseActionBoardView = setmetatable({}, BaseBoardView)
BaseActionBoardView.__index = BaseActionBoardView

function BaseActionBoardView:Init(boardModel)
  BaseBoardView.Init(self, boardModel)
  REGISTER_BOARD_EVENT_HANDLER(self, "CollectItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "CacheItemFromSpread")
end

function BaseActionBoardView:Update()
  if self.m_model == nil then
    return
  end
  if self.m_hasCollapsedPaperBox then
    GM.AudioModel:PlayEffect(AudioFileConfigName.sfxSandBreak)
  end
  self.m_hasCollapsedPaperBox = false
end

function BaseActionBoardView:OnDestroy()
  BaseBoardView.OnDestroy(self)
  if self.m_cachedItemCollectableTip ~= nil then
    if self.m_cachedItemCollectableTip ~= true and self.m_cachedItemCollectableTip.gameObject ~= nil then
      self.m_cachedItemCollectableTip.gameObject:RemoveSelf()
    end
    self.m_cachedItemCollectableTip = nil
  end
end

function BaseActionBoardView:GetSelectedItemModel()
  return self.m_selectedBoardPosition and self.m_model:GetItem(self.m_selectedBoardPosition)
end

function BaseActionBoardView:UpdateSwallowIndicator(item)
  self.m_swallowItemIndicator:UpdateIndicator(item)
end

function BaseActionBoardView:_UpdateIndicator(item, playAnimation, showSwallowItemIndicator, itemCollectableTipShowStatus)
  self.m_selectedBoardPosition = item and item:GetPosition()
  self.m_indicator:UpdateIndicator(item, playAnimation)
  if showSwallowItemIndicator then
    self.m_swallowItemIndicator:UpdateIndicator(item)
  else
    self.m_swallowItemIndicator:UpdateIndicator(nil)
  end
  self:_UpdateItemCollectableTip(item, itemCollectableTipShowStatus)
end

function BaseActionBoardView:_UpdateItemCollectableTip(item, itemCollectableTipShowStatus)
  local showItemCollectableTip = itemCollectableTipShowStatus == ItemCollectableTipShowStatus.SelectItem or itemCollectableTipShowStatus == ItemCollectableTipShowStatus.MergeItem
  local bTapItemDiffer = self.m_itemCollectableTipItem ~= item
  if showItemCollectableTip then
    self.m_itemCollectableTipItem = item
  end
  if self:_CanShowItemCollectableTip(itemCollectableTipShowStatus) and showItemCollectableTip then
    if self.m_cachedItemCollectableTip == nil then
      local prefabConfig = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemCollectableTip)
      self.m_cachedItemCollectableTip = true
      GM.ResourceLoader:LoadPrefab(prefabConfig, GM.UIManager:GetCanvasRoot(), Vector3.zero, function(object)
        if self.gameObject:IsNull() then
          object:RemoveSelf()
          return
        end
        self.m_cachedItemCollectableTip = object:GetLuaTable()
        if not self:_CanShowItemCollectableTip() then
          self.m_cachedItemCollectableTip:Hide()
          return
        end
        local reward = item:GetComponent(ItemCollectable):GetRewards()[1]
        self.m_cachedItemCollectableTip:Show(self:ConvertBoardPositionToScreenPosition(item:GetPosition()), reward)
        if itemCollectableTipShowStatus == ItemCollectableTipShowStatus.MergeItem then
          self:_SetItemTypeCollectableTipShownFromMerge(item:GetType())
        end
      end)
    elseif self.m_cachedItemCollectableTip ~= nil and self.m_cachedItemCollectableTip ~= true and bTapItemDiffer then
      local reward = item:GetComponent(ItemCollectable):GetRewards()[1]
      self.m_cachedItemCollectableTip:Show(self:ConvertBoardPositionToScreenPosition(item:GetPosition()), reward)
      if itemCollectableTipShowStatus == ItemCollectableTipShowStatus.MergeItem then
        self:_SetItemTypeCollectableTipShownFromMerge(item:GetType())
      end
    end
  elseif self.m_cachedItemCollectableTip ~= nil and self.m_cachedItemCollectableTip ~= true then
    self.m_cachedItemCollectableTip:Hide()
  end
end

function BaseActionBoardView:_CanShowItemCollectableTip(itemCollectableTipShowStatus)
  if not self:GetSelectedItemModel() then
    return false
  end
  local item = self:GetSelectedItemModel()
  local hasShownTipFromMerge = itemCollectableTipShowStatus == ItemCollectableTipShowStatus.MergeItem and self:_HasItemTypeCollectableTipShownFromMerge(item:GetType())
  return item:GetComponent(ItemCollectable) ~= nil and item:GetSpecialType() == ItemSpecialType.TipCollectable and not hasShownTipFromMerge
end

function BaseActionBoardView:_HasItemTypeCollectableTipShownFromMerge(itemType)
  return false
end

function BaseActionBoardView:_SetItemTypeCollectableTipShownFromMerge(itemType)
end

function BaseActionBoardView:ClearIndicator()
  self.m_selectedBoardPosition = nil
  self.m_indicator:UpdateIndicator()
  self:_UpdateItemCollectableTip()
end

function BaseActionBoardView:_DoStartPrompt(interval)
  self:_CancelPrompt()
  if self.m_promptSchedulerOrigin == nil then
    function self.m_promptSchedulerOrigin()
      if self.m_promptScheduler then
        Scheduler.Unschedule(self.m_promptScheduler, self)
        
        self.m_promptScheduler = nil
      end
      if self.m_model.ResetLogNearestTouchedMergeItem then
        self.m_model:ResetLogNearestTouchedMergeItem()
      end
      self.m_prompt = self:_SelectPrompt()
      if self.m_prompt ~= nil then
        self.m_prompt:Start(self)
      end
    end
  end
  self.m_promptScheduler = self.m_promptSchedulerOrigin
  Scheduler.Schedule(self.m_promptScheduler, self, 0, 1, interval)
end

function BaseActionBoardView:_DoSelectPrompt(checkFunc)
  if GM.TutorialModel:HasAnyStrongTutorialOngoing() then
    return nil
  end
  local prompts = self:_GetPrompts()
  local promptConfig = self.m_model:GetPromptConfig()
  
  local function comparer(prompt1, prompt2)
    local priority1 = promptConfig[prompt1:GetType()].Priority
    local priority2 = promptConfig[prompt2:GetType()].Priority
    return priority1 < priority2
  end
  
  table.sort(prompts, comparer)
  for _, prompt in ipairs(prompts) do
    if (checkFunc == nil or checkFunc(prompt)) and prompt:CanStart(self) then
      return prompt
    end
  end
  return nil
end

function BaseActionBoardView:_CancelPrompt()
  if self.m_promptScheduler ~= nil then
    Scheduler.Unschedule(self.m_promptScheduler, self)
    self.m_promptScheduler = nil
  end
  if self.m_prompt ~= nil then
    self.m_prompt:Stop(self)
    self.m_prompt = nil
  end
end

function BaseActionBoardView:ShowHandTapEffect(targetPosition)
  self.m_handTapEffectGo:SetActive(true)
  targetPosition = Vector3(targetPosition.x + 40, targetPosition.y - 65, 0)
  self.m_handTapEffectGo.transform.position = targetPosition
end

function BaseActionBoardView:HideHandTapEffect()
  self.m_handTapEffectGo:SetActive(false)
end

function BaseActionBoardView:ShowHandDragEffect(sourcePosition, targetPosition)
  if self.m_dragTween ~= nil then
    self.m_dragTween:Kill()
    self.m_dragTween = nil
  end
  sourcePosition.x = sourcePosition.x + 60
  sourcePosition.y = sourcePosition.y - 65
  sourcePosition.z = 0
  targetPosition.x = targetPosition.x + 60
  targetPosition.y = targetPosition.y - 65
  targetPosition.z = 0
  self.m_handDragEffectGo.transform.position = sourcePosition
  self.m_handDragEffectGo:SetActive(true)
  if self.m_dragInCallback == nil then
    function self.m_dragInCallback()
      if not self.m_handDragEffectAnimator:IsNull() then
        SafeCall(function()
          self.m_handDragEffectAnimator:Play("am_shouzhi_huadong_in")
        end)
      end
    end
  end
  if self.m_dragOutCallback == nil then
    function self.m_dragOutCallback()
      if not self.m_handDragEffectAnimator:IsNull() then
        SafeCall(function()
          self.m_handDragEffectAnimator:Play("am_shouzhi_huadong_out")
        end)
      end
    end
  end
  local sequence = DOTween.Sequence():SetLoops(-1)
  sequence:AppendInterval(1.0)
  sequence:AppendCallback(self.m_dragInCallback)
  sequence:AppendInterval(0.6)
  sequence:Append(self.m_handDragEffectGo.transform:DOMove(targetPosition, Vector3.Distance(sourcePosition, targetPosition) / 530))
  sequence:AppendInterval(0.2)
  sequence:AppendCallback(self.m_dragOutCallback)
  sequence:AppendInterval(0.4)
  self.m_dragTween = sequence
end

function BaseActionBoardView:HideHandDragEffect()
  self.m_handDragEffectGo:SetActive(false)
  if self.m_dragTween ~= nil then
    self.m_dragTween:Kill()
    self.m_dragTween = nil
  end
end

function BaseActionBoardView:_CanShowMergeLight(itemModel, lastItemModel)
  if self.m_model:CanItemMerge(itemModel, lastItemModel) then
    return true
  end
  local itemSwallow = itemModel:GetComponent(ItemSwallow)
  return itemSwallow ~= nil and itemSwallow:CanSwallow(lastItemModel)
end

function BaseActionBoardView:_TryShowMergeLight(worldPosition)
  local boardPosition = self:_GetBoardPosition(worldPosition)
  local itemModel
  if self.m_model:IsPositionInteractable(boardPosition) then
    itemModel = self.m_model:GetItem(boardPosition)
  end
  local itemView = self:GetItemView(itemModel)
  if itemView == self.m_lastMergeLightItem then
    return
  end
  self:_ClearMergeLight()
  local lastItemModel = self.m_lastTouchedItem:GetModel()
  if itemModel == nil or itemModel == lastItemModel then
    return
  end
  if self:_CanShowMergeLight(itemModel, lastItemModel) then
    self:_ShowMergeLight(itemView)
  end
end

function BaseActionBoardView:_ShowMergeLight(itemView)
  itemView:MergeLightAppear()
  self.m_lastMergeLightItem = itemView
end

function BaseActionBoardView:_ClearMergeLight()
  if self.m_lastMergeLightItem ~= nil then
    if not self.m_lastMergeLightItem.gameObject:IsNull() then
      self.m_lastMergeLightItem:MergeLightDisappear()
    end
    self.m_lastMergeLightItem = nil
  end
end

function BaseActionBoardView:_PlayParabolaAnimation(itemView, sourcePosition, targetPosition, height, totaltim, scl)
  sourcePosition = Vector3(sourcePosition.x, sourcePosition.y, 0)
  targetPosition = Vector3(targetPosition.x, targetPosition.y, 0)
  local h1 = height
  local h2 = sourcePosition.y + height - targetPosition.y
  local tim1 = 1 / (1 + math.sqrt(h2 * 1.0 / h1)) * totaltim
  local tim2 = totaltim - tim1
  local dx1 = (targetPosition.x - sourcePosition.x) * tim1 / totaltim
  local sequence = DOTween.Sequence()
  itemView:SetJumpTween(sequence)
  local transform = itemView.gameObject.transform
  transform.localPosition = sourcePosition
  transform.localScale = Vector3.zero
  sequence:Insert(0, transform:DOLocalMoveY(sourcePosition.y + h1, tim1):SetEase(Ease.OutQuart))
  sequence:Insert(0, transform:DOScale(Vector3(scl, scl, 1), tim1):SetEase(Ease.OutQuart))
  sequence:Insert(0, transform:DOLocalMoveX(targetPosition.x, totaltim))
  sequence:Insert(tim1, transform:DOLocalMoveY(targetPosition.y, tim2):SetEase(Ease.InQuad))
  sequence:Insert(tim1, transform:DOScale(Vector3.one, tim2):SetEase(Ease.InQuad))
  sequence:InsertCallback(totaltim - 0.1, function()
    itemView:ShowSpreadLight(false)
  end)
end

function BaseActionBoardView:_PlayJumpAnimation(itemView, sourcePosition, targetPosition, energyBoost, spreadEffectType)
  local luckySpread = BoardSpreadType.IsLuckySpread(spreadEffectType)
  local digSpread = spreadEffectType == BoardSpreadType.Dig or spreadEffectType == BoardSpreadType.Disco
  local generatorBoostExtraLuckySpread = spreadEffectType == BoardSpreadType.GeneratorBoostExtraLucky
  local conti1LuckySpread = spreadEffectType == BoardSpreadType.TripleLucky1 or spreadEffectType == BoardSpreadType.DoubleLucky
  local conti2LuckySpread = spreadEffectType == BoardSpreadType.TripleLucky2
  local tempItemSpread = itemView:GetModel():GetType() == ItemType.Temp
  local sourcePositionZero = Vector3(sourcePosition.x, sourcePosition.y, -1)
  local targetPositionZero = Vector3(targetPosition.x, targetPosition.y, 0)
  local deltaPosition = targetPositionZero - sourcePositionZero
  local transform = itemView.gameObject.transform
  transform.localPosition = sourcePositionZero
  transform.localScale = Vector3.zero
  local bTailShown = itemView:ShowTail(energyBoost, spreadEffectType)
  local sequence = DOTween.Sequence()
  itemView:SetJumpTween(sequence)
  sequence:Insert(0.05, transform:DOLocalJump(sourcePositionZero + deltaPosition * 0.9, 60, 1, 0.6))
  sequence:Insert(0.65, transform:DOLocalMove(targetPosition, 0.25):SetEase(Ease.OutQuad))
  sequence:InsertCallback(0.6, function()
    itemView:ShowSpreadLight(energyBoost, spreadEffectType)
    self:_PlayItemSpreadPrompt(itemView, spreadEffectType)
    if bTailShown then
      itemView:RemoveTail()
    end
    if spreadEffectType == BoardSpreadType.CardItem then
      EventDispatcher.DispatchEvent(EEventType.VibrationLight)
    end
    if conti1LuckySpread or conti2LuckySpread then
      EventDispatcher.DispatchEvent(EEventType.VibrationMedium)
    end
    if spreadEffectType == BoardSpreadType.ObstacleReward then
      GM.AudioModel:PlayEffect(AudioFileConfigName.SfxBoardObstacleFly1)
      EventDispatcher.DispatchEvent(EEventType.VibrationMedium)
    end
    if tempItemSpread then
      Scheduler.Schedule(function()
        EventDispatcher.DispatchEvent(EEventType.VibrationMedium)
      end, self, 0.1, 3, 0)
    end
  end)
  sequence:Insert(0.05, transform:DOScale(Vector3(0.8, 0.8, 1), 0.1))
  sequence:Insert(0.15, transform:DOScale(Vector3(1.5, 1.5, 1), 0.2))
  sequence:Insert(0.35, transform:DOScale(Vector3(1, 1, 1), 0.3))
  sequence:Insert(0.65, transform:DOScale(V3One, 0.2))
  if luckySpread or generatorBoostExtraLuckySpread then
    itemView:ShowLuckySpreadEffect()
    sequence:InsertCallback(0.65, function()
      itemView:RemoveLuckySpreadEffect()
    end)
  end
  itemView:ShowSpreadFlyEffect(spreadEffectType)
  sequence:InsertCallback(0.65, function()
    itemView:RemoveSpreadFlyEffect()
  end)
  if conti1LuckySpread or conti2LuckySpread then
    GM.UIManager:SetEventLock(true, self)
    local delay = conti1LuckySpread and 0.3 or 0.5
    sequence:InsertCallback(delay, function()
      GM.UIManager:SetEventLock(false, self)
    end)
  end
  if conti2LuckySpread then
    sequence:InsertCallback(0.65, function()
      GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.effect_Flash_magic_3_large), GM.UIManager:GetCanvasRoot(), Vector3.zero, Function.Void)
    end)
  end
  return sequence
end

function BaseActionBoardView:GetMergeAudioSfx(message)
  local newItemType = message.New:GetType()
  local level = GM.ItemDataModel:GetChainLevel(newItemType)
  local sfx = AudioUtil.GetMergeAudioConfigFileName(level)
  return sfx
end

function BaseActionBoardView:_OnMergeItem(message)
  self:PlayMergeAnimation(message)
end

function BaseActionBoardView:PlayMergeAnimation(message)
  GM.AudioModel:PlayEffect(self:GetMergeAudioSfx(message))
  local sourceItemView = self:GetItemView(message.Source)
  sourceItemView.toBeRemoved = true
  local targetItemView = self:GetItemView(message.Target)
  targetItemView.toBeRemoved = true
  local newItemView = self:_AddItemView(message.New)
  if sourceItemView == nil or targetItemView == nil then
    self:_RemoveItemView(sourceItemView)
    self:_RemoveItemView(targetItemView)
    return
  end
  local bMergeTip = GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ConfNewGenerator) and newItemView ~= nil and message.isFirstUnlock and self.m_model.IsFirstUnlockGeneratorItemTipType and self.m_model:IsFirstUnlockGeneratorItemTipType(message.New:GetType())
  if bMergeTip then
    GM.UIManager:SetEventLock(true)
  end
  local targetPosition = targetItemView.transform.localPosition
  local sequence = DOTween.Sequence()
  sequence:Insert(0, sourceItemView.transform:DOLocalMove(targetPosition, 0.1))
  sequence:Insert(0, sourceItemView.transform:DOScale(0.3, 0.1))
  sequence:InsertCallback(0.1, function()
    self:_RemoveItemView(sourceItemView)
  end)
  targetItemView:MergeLightDisappear()
  sequence:Insert(0, targetItemView.transform:DOScale(0.3, 0.1))
  sequence:InsertCallback(0.1, function()
    self:_RemoveItemView(targetItemView)
  end)
  if newItemView ~= nil then
    newItemView.transform.localScale = Vector3.zero
    sequence:InsertCallback(0.1, function()
      newItemView.transform.localScale = 0.3 * V3One
    end)
    sequence:Insert(0.1, newItemView.transform:DOScale(1.3, 0.2))
    sequence:Insert(0.3, newItemView.transform:DOScale(1, 0.1))
    if bMergeTip then
      local newType = message.New:GetType()
      sequence:InsertCallback(0.3, function()
        local config = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemGeneratorMergeTip)
        GM.ResourceLoader:LoadPrefab(config, self.m_itemsTransform, targetPosition, function(go)
          local tb = go:GetLuaTable()
          tb:Init(newType)
          tb:Play()
        end)
      end)
    end
  end
  local hasTempItem = message.Source:GetComponent(ItemTemp) ~= nil or message.Target:GetComponent(ItemTemp) ~= nil
  if hasTempItem then
    sequence:InsertCallback(0, function()
      local config = GM.DataResource.ScenePrefabConfig:GetConfig(ScenePrefabConfigName.effect_temp_merge)
      GM.ResourceLoader:LoadPrefab(config, self.m_itemsTransform, targetPosition, function()
      end)
    end)
  else
    local level = GM.ItemDataModel:GetChainLevel(message.New:GetType())
    sequence:InsertCallback(0.1, function()
      local mergeEffectPrefab = self.m_mergeEffectManager:GetPrefab(level)
      if mergeEffectPrefab ~= nil then
        local gameObject = Object.Instantiate(mergeEffectPrefab, targetItemView.transform.position, Quaternion.identity, self.m_itemsTransform)
        DOVirtual.DelayedCall(1, function()
          gameObject:RemoveSelf()
        end)
      end
    end)
  end
end

function BaseActionBoardView:_OnCostItem(message)
  local itemView = self:GetItemView(message.Source)
  self:_RemoveItemView(itemView)
  if self.m_selectedBoardPosition == message.Source:GetPosition() then
    self:_UpdateIndicator()
  end
end

function BaseActionBoardView:_OnPopCachedItem(message)
  GM.AudioModel:PlayEffect(AudioFileConfigName.SfxMergeSpawnManual)
  local itemView = self:_AddItemView(message.New)
  if itemView ~= nil then
    local worldPosition = self:GetCacheRoot():GetCachedItemWorldPos()
    local sourcePosition = self.transform:InverseTransformPoint(worldPosition)
    local targetPosition = itemView.transform.localPosition
    self:_PlayJumpAnimation(itemView, sourcePosition, targetPosition)
  end
end

function BaseActionBoardView:_OnCollectItem(message)
  local rewards = message.Source:GetComponent(ItemCollectable):GetRewards()
  if message.generateItemModel ~= nil then
    Log.Error("\230\140\137\231\144\134\232\175\180\229\143\170\230\156\137\229\141\161\231\137\140\230\163\139\229\173\144\229\143\175\228\187\165\231\154\132\239\188\140\229\166\130\230\158\156\229\186\134\230\157\176\228\189\160\231\156\159\232\166\129\232\191\153\228\185\136\233\133\141\231\189\174\231\154\132\232\175\157\239\188\140\232\166\129\232\181\176\228\184\128\233\129\141\230\181\139\232\175\149\239\188\140\231\132\182\229\144\142\232\174\169\231\168\139\229\186\143\229\136\160\233\153\164\232\191\153\228\184\170\230\143\144\233\134\146\229\147\166")
    local ItemView = self:GetItemView(message.Source)
    local item = self:_AddItemView(message.generateItemModel)
    item.transform.localPosition = message.generateItemModel:GetLocalPosition()
    self:_PlayJumpAnimation(item, ItemView.transform.localPosition, item.transform.localPosition, nil, nil)
    self:_RemoveItemView(ItemView)
    return
  end
  local sfxs = {
    [EPropertyType.Gold] = AudioFileConfigName.SfxMergeCollectCoins,
    [EPropertyType.Gem] = AudioFileConfigName.SfxMergeCollectDiamond,
    [EPropertyType.Experience] = AudioFileConfigName.SfxMergeCollectExperience,
    [EPropertyType.Energy] = AudioFileConfigName.SfxMergeCollectEnergy,
    [EPropertyType.EnergyInfiniteTime] = AudioFileConfigName.SfxMergeCollectEnergy
  }
  local sfx = sfxs[rewards[1][PROPERTY_TYPE]]
  if sfx ~= nil then
    GM.AudioModel:PlayEffect(sfx)
  end
  local itemView = self:GetItemView(message.Source)
  local worldPosition = itemView.transform.position
  local screenPosition = self:ConvertWorldPositionToScreenPosition(worldPosition)
  local uiWorldPosition = PositionUtil.UICameraScreen2World(screenPosition)
  local viewData = {
    arrWorldPos = Table.ListRep(uiWorldPosition, #rewards),
    noDelayTime = true
  }
  self:_HandleCollectItemViewData(viewData, message)
  RewardApi.AcquireRewardsInView(rewards, viewData)
  if message.Source:GetSpecialType() == ItemSpecialType.TipCollectable then
    self:_PlayCollectItemTextAnimation(message.Source)
    self:_UpdateIndicator(nil, false)
  end
  itemView.toBeRemoved = true
  itemView.transform:DOScale(Vector3.zero, 0.2):OnComplete(function()
    self:_RemoveItemView(itemView)
  end)
end

function BaseActionBoardView:_OnCacheItemFromSpread(message)
  local itemView = self:GetItemView(message.Source)
  local startPos = itemView.transform.position
  local interval = 0.1
  local seq = DOTween.Sequence()
  local targetPosition = self.GetCacheRoot ~= nil and self:GetCacheRoot():GetOriginalPosition() or V3Zero
  targetPosition.z = 0
  for i, itemType in ipairs(message.CachedItems) do
    local delay = interval * (i - 1)
    seq:InsertCallback(delay, function()
      if ItemModelFactory.GetCodePrefixTargetType(itemType) == ItemType.RewardBubble then
        itemType = ItemModelFactory.GetInnerType(itemType)
      end
      local flyItem = self.m_itemViewFactory:CreateFlyItem(self, itemType)
      flyItem:UpdateEffect(false)
      flyItem:UpdateNumText(false)
      flyItem.transform.position = Vector3(itemView.transform.position.x, itemView.transform.position.y, itemView.transform.position.z)
      flyItem:Move2Target(targetPosition)
    end)
  end
end

function BaseActionBoardView:_HandleCollectItemViewData(viewData, message)
end

function BaseActionBoardView:_PlayCollectItemTextAnimation(itemModel)
  local reward = itemModel:GetComponent(ItemCollectable):GetRewards()[1]
  local position = PositionUtil.UICameraScreen2World(self:ConvertBoardPositionToScreenPosition(itemModel:GetPosition()))
  position.z = 0
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemCollectablePrompt), GM.UIManager:GetCanvasRoot(), position, function(go)
    local prompt = go:GetLuaTable()
    prompt:Init(reward)
  end)
end

function BaseActionBoardView:_OnBatchSwallowItem(message)
  local function onBegin()
    self:_UpdateIndicator(nil, false)
    
    GM.UIManager:SetEventLock(true)
  end
  
  local function onEnd()
    GM.UIManager:SetEventLock(false)
  end
  
  self:_DoBatchSwallowItem(message, onBegin, onEnd)
end

function BaseActionBoardView:IsPaperBoxExtraRewardAnimationPlaying()
  return self.m_paperBoxExtraRewardPlayingAnimationCount and self.m_paperBoxExtraRewardPlayingAnimationCount > 0
end

function BaseActionBoardView:_InitPaperBoxExtraRewards()
  self:SetPaperBoxAreaPosition()
  self.m_mapPaperBoxExtraReward = {}
  self.m_paperBoxExtraRewardPlayingAnimationCount = 0
  for pos in self.m_model:GetValidPositionIterator() do
    local reward = self.m_model:GetPaperBoxExtraReward(pos)
    if reward ~= nil then
      local itemModel = self.m_model:GetItem(pos)
      if itemModel and itemModel:GetType() == ItemType.PaperBox then
        local extraReward = Object.Instantiate(self.m_paperboxExtraRewardPrefab, self.m_paperboxExtraRewardArea)
        self.m_mapPaperBoxExtraReward[pos] = extraReward:GetLuaTable()
        self.m_mapPaperBoxExtraReward[pos]:Init(self.m_model, pos)
        self.m_mapPaperBoxExtraReward[pos]:SetTransformFunction(function(pos)
          local screenPos = self:ConvertWorldPositionToScreenPosition(pos)
          return PositionUtil.UICameraScreen2World(screenPos)
        end)
        if self.m_model:IsPaperBoxExtraRewardFirstAppear(pos) then
          self.m_model:SetPaperBoxExtraRewardAppeared(pos)
          GM.BIManager:LogAction(EBIType.PaperBoxExtraItemShowInBoard, {
            pos = tostring(self.m_model:GetPaperBoxRewardPosition(pos)),
            rwd = ConfigUtil.GetCurrencyStr(reward),
            boardType = self.m_model.BoardType
          })
        end
      end
    end
  end
end

function BaseActionBoardView:SetPaperBoxAreaPosition()
end

function BaseActionBoardView:_UpdatePaperBoxReward()
  for _, extraReward in pairs(self.m_mapPaperBoxExtraReward) do
    extraReward.gameObject:RemoveSelf()
  end
  self:_InitPaperBoxExtraRewards()
end

function BaseActionBoardView:_PlayPaperboxExtraRewardAnimation(message, callback)
  GM.UIManager:SetEventLock(true)
  self.m_paperBoxExtraRewardPlayingAnimationCount = self.m_paperBoxExtraRewardPlayingAnimationCount + 1
  local sequence = DOTween.Sequence()
  local collapseDelay, removeDelay = self.m_mapPaperBoxExtraReward[message.Source:GetPosition()]:PlayRewardAnimation(sequence, message)
  sequence:InsertCallback(collapseDelay, function()
    self:_DOCollapseItem(message)
  end)
  sequence:InsertCallback(removeDelay, function()
    self.m_mapPaperBoxExtraReward[message.Source:GetPosition()].gameObject:RemoveSelf()
    self.m_mapPaperBoxExtraReward[message.Source:GetPosition()] = nil
    GM.UIManager:SetEventLock(false)
    self.m_paperBoxExtraRewardPlayingAnimationCount = self.m_paperBoxExtraRewardPlayingAnimationCount - 1
    if not message.isPropReward then
      self.m_paperBoxRewardCache = RewardApi.MergeRewards(self.m_paperBoxRewardCache, {
        message.CollapseReward
      })
    end
    if self.m_paperBoxExtraRewardPlayingAnimationCount == 0 then
      if not Table.IsEmpty(self.m_paperBoxRewardCache) then
        local rewardWindowArgs = {
          arrRewards = self.m_paperBoxRewardCache,
          closeCallback = callback
        }
        self:_ShowRewardWindowWhenIdle(rewardWindowArgs)
        self.m_paperBoxRewardCache = nil
      elseif callback ~= nil then
        callback()
      end
    end
  end)
end

function BaseActionBoardView:_ShowRewardWindowWhenIdle(rewardWindowArgs)
  GM.UIManager:OpenViewWhenIdle(UIPrefabConfigName.RewardWindow, rewardWindowArgs)
end
