MainBoardView = setmetatable({CompleteTileColor = "92EBE4"}, BaseActionBoardView)
MainBoardView.__index = MainBoardView
EBoardBackgroundMode = {Default = 1, BakeOut = 2}
MainBoardView.MergePromptInterval = 2.3
MainBoardView.MergePromptIntervalNewUser = 0.7

local function REGISTER_TOUCH_HANDLER(view, eventName)
  local triggerEventName = "OnLua" .. eventName
  local functionName = "_On" .. eventName
  view.m_eventTrigger[triggerEventName] = function(eventData)
    view[functionName](view, eventData)
  end
end

local EBackgroundModeDataSet = {
  [EBoardBackgroundMode.Default] = {
    [EBoardBackgroundElement.Bg] = BoardBackground.DefaultRes,
    [EBoardBackgroundElement.BoardBgSimple] = BoardBackground.DefaultRes,
    [EBoardBackgroundElement.Counter] = BoardBackground.DefaultRes,
    [EBoardBackgroundElement.ItemBoard] = BoardBackground.DefaultRes
  },
  [EBoardBackgroundMode.BakeOut] = {
    [EBoardBackgroundElement.Bg] = ImageFileConfigName.board_bg1_bakeout,
    [EBoardBackgroundElement.BoardBg] = ImageFileConfigName.board_bg2_bakeout,
    [EBoardBackgroundElement.Counter] = ImageFileConfigName.order_counter_bakeout,
    [EBoardBackgroundElement.Deco2] = ImageFileConfigName.board_bg4_bakeout,
    [EBoardBackgroundElement.ItemBoard] = ImageFileConfigName.board_bakeout
  }
}

function MainBoardView.GetInstance()
  return MainBoardView.s_instance
end

function MainBoardView:Awake()
  MainBoardView.s_instance = self
  self:Init(GM.MainBoardModel)
  EventDispatcher.AddListener(EEventType.OnViewWillClose, self, self._OnWillCloseView)
  EventDispatcher.AddListener(EEventType.ResolutionChanged, self, self._OnResolutionChanged)
  self.m_orderArea:Init(self, true)
  self:_InitPaperBoxExtraRewards()
  REGISTER_BOARD_EVENT_HANDLER(self, "StoreItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "RetrieveStoredItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "FinishSpecialOrder")
  REGISTER_BOARD_EVENT_HANDLER(self, "StoreFailed")
  REGISTER_BOARD_EVENT_HANDLER(self, "BatchRemoveItems")
  REGISTER_BOARD_EVENT_HANDLER(self, "FinishBranchOrder")
  REGISTER_BOARD_EVENT_HANDLER(self, "RemoverOrderImmediate")
  REGISTER_BOARD_EVENT_HANDLER(self, "AddCacheItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "ZeroCDItemBuffConsume")
  REGISTER_BOARD_EVENT_HANDLER(self, "AddAdventureActivityItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "BuyActivityBubble")
  REGISTER_BOARD_EVENT_HANDLER(self, "TempDisappear")
  REGISTER_BOARD_EVENT_HANDLER(self, "AddOrderFinishItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "CollectPuzzleToken")
  REGISTER_BOARD_EVENT_HANDLER(self, "AddMultiboardsActivityItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "CollectScoreRaceToken")
  REGISTER_BOARD_EVENT_HANDLER(self, "CollectFarmboardToken")
  REGISTER_BOARD_EVENT_HANDLER(self, "GeneratorBoostBuffActive")
  REGISTER_BOARD_EVENT_HANDLER(self, "DiscoBoostTrigger")
  REGISTER_BOARD_EVENT_HANDLER(self, "Add2GeneratorFactory")
  REGISTER_BOARD_EVENT_HANDLER(self, "ReplaceItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "SmartBuffConsume")
  self.m_retrieveList = {}
end

function MainBoardView:Init(boardModel)
  self.CompleteTileColor = UIUtil.ConvertHexColor2CSColor(self.CompleteTileColor)
  self.m_completeTileMap = boardModel:CreateMatrix()
  BaseActionBoardView.Init(self, boardModel)
  self:_UpdateCompleteTiles(false)
  self:_InitSandFills()
  self.m_camera = GM.ModeViewController:GetBoardInfo()
  self.m_canvas.worldCamera = self.m_camera
  self.m_infoBar:Init(boardModel)
  self.m_mapPromptLockInfo = {}
  EventDispatcher.AddListener(EEventType.OrderStateChanged, self, self._OnOrderStateChanged)
  EventDispatcher.AddListener(EEventType.ChangeGameMode, self, self._OnGameModeChanged)
  EventDispatcher.AddActiveListener(EEventType.OpenView, self, self._OnOpenView)
  EventDispatcher.AddActiveListener(EEventType.CloseView, self, self._OnCloseView)
  EventDispatcher.AddActiveListener(EEventType.TutorialFinished, self, self._TryStartPrompt)
  EventDispatcher.AddActiveListener(EEventType.TutorialAnyStrongTutorialUpdated, self, self.OnTutorialAnyStrongTutorialUpdated)
  EventDispatcher.AddActiveListener(EEventType.ApplicationWillEnterForeground, self, self._ClearPointerDataOnUnexpectedPointerExit)
  EventDispatcher.AddActiveListener(EEventType.TryStartBoardPromptEvent, self, self._TryStartPromptByEvent)
  REGISTER_TOUCH_HANDLER(self, "PointerDown")
  REGISTER_TOUCH_HANDLER(self, "Drag")
  REGISTER_TOUCH_HANDLER(self, "PointerUp")
  REGISTER_BOARD_EVENT_HANDLER(self, "MergeItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "CollapseItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "CostItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "SellItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "UndoSellItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "PopCachedItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "ChooseItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "SplitItem")
  REGISTER_BOARD_EVENT_HANDLER(self, "TimeSkip")
  REGISTER_BOARD_EVENT_HANDLER(self, "BubbleBreak")
  REGISTER_BOARD_EVENT_HANDLER(self, "BubbleDisappear")
  REGISTER_BOARD_EVENT_HANDLER(self, "FinishOrder")
  REGISTER_BOARD_EVENT_HANDLER(self, "LackGem")
  REGISTER_BOARD_EVENT_HANDLER(self, "LackEnergy")
  REGISTER_BOARD_EVENT_HANDLER(self, "SpreadFailed")
  REGISTER_BOARD_EVENT_HANDLER(self, "UpdateOpeningItem")
  self:InitActivityUIRefreshed()
end

function MainBoardView:OnEnable()
  self:_StartPrompt()
  local sceneView = GM.UIManager:GetOpenedTopViewByType(EViewType.SceneView)
  if sceneView ~= nil and self.m_camera ~= nil then
    self:_UpdateInfoBarPosition()
    if not self.m_adjustedInfoBarPosition then
      self.m_adjustedInfoBarPosition = true
      Scheduler.Schedule(function()
        self:_UpdateInfoBarPosition()
      end, self, nil, 10, nil)
    end
  end
end

function MainBoardView:_UpdateInfoBarPosition()
  local sceneView = GM.UIManager:GetOpenedTopViewByType(EViewType.SceneView)
  if sceneView == nil then
    return
  end
  local screenPosition = sceneView:GetBoardInfoBarScreenPosition()
  local worldPosition = self:ConvertScreenPositionToWorldPosition(screenPosition)
  local transform = self.m_infoBar.gameObject.transform
  local localPosition = transform.parent:InverseTransformPoint(worldPosition)
  localPosition.z = 0
  transform.localPosition = localPosition
end

function MainBoardView:OnDestroy()
  BaseActionBoardView.OnDestroy(self)
  EventDispatcher.RemoveTarget(self)
  Scheduler.UnscheduleTarget(self)
  GM.UIManager:RemoveAllEventLocks(self)
  MainBoardView.s_instance = nil
end

function MainBoardView:GetInfoBar()
  return self.m_infoBar
end

function MainBoardView:GetOrderArea()
  return self.m_orderArea
end

function MainBoardView:GetCacheRoot()
  return self.m_orderArea:GetBoardCacheRoot()
end

function MainBoardView:_GetInventoryButton()
  local baseSceneView = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView)
  return baseSceneView:GetHudButton(ESceneViewHudButtonKey.Inventory)
end

function MainBoardView:ConvertWorldPositionToScreenPosition(position)
  return self.m_camera:WorldToScreenPoint(position)
end

function MainBoardView:ConvertScreenPositionToWorldPosition(position)
  return self.m_camera:ScreenToWorldPoint(position)
end

function MainBoardView:ConvertBoardPositionToScreenPosition(boardPosition)
  localPosition = self.m_model:ToLocalPositionSetZ(boardPosition, 0)
  local worldPosition = self:GetItemsTransform():TransformPoint(localPosition)
  return self:ConvertWorldPositionToScreenPosition(worldPosition)
end

function MainBoardView:_RemoveItemView(itemView)
  if self.m_lastTouchedItem == itemView then
    self.m_lastTouchedItem = nil
    if self.m_onInventory then
      self:_GetInventoryButton():PlayDragEndEffect()
      self.m_onInventory = false
    end
  end
  BaseActionBoardView._RemoveItemView(self, itemView)
end

function MainBoardView:_AddTile(boardPosition)
  BaseActionBoardView._AddTile(self, boardPosition)
  local tileObject = Object.Instantiate(self.m_tilePrefab, self.m_tilesTransform)
  local tileSprite = tileObject:GetComponent(typeof(SpriteRenderer))
  SpriteUtil.SetSpriteRenderer(tileSprite, ImageFileConfigName.tile_bg3)
  tileSprite.color = self.CompleteTileColor
  self.m_completeTileMap:SetValueOnPosition(boardPosition, {Sprite = tileSprite, Show = true})
  tileObject.transform.localPosition = self.m_model:ToLocalPositionSetZ(boardPosition, -1)
end

function MainBoardView:_UpdateCompleteTiles(animation)
  local codeStateMap = self.m_model:GetOrderCodeStateMap()
  for position in self.m_model:GetValidPositionIterator() do
    local itemModel = self.m_model:GetItem(position)
    self:UpdateCompleteTileDisplay(position, itemModel ~= nil and codeStateMap[itemModel:GetCode()] == OrderState.CanDeliver, animation)
  end
end

function MainBoardView:_UpdateSingleCompleteTile(position, animation)
  local codeStateMap = self.m_model:GetOrderCodeStateMap()
  local itemModel = self.m_model:GetItem(position)
  self:UpdateCompleteTileDisplay(position, itemModel ~= nil and codeStateMap[itemModel:GetCode()] == OrderState.CanDeliver, animation)
end

function MainBoardView:UpdateCompleteTileDisplay(position, show, animation)
  if self.m_completeTileMap:GetValueOnPosition(position).Show == show then
    if not animation then
      self.m_completeTileMap:GetValueOnPosition(position).Sprite:DOKill()
      UIUtil.SetAlpha(self.m_completeTileMap:GetValueOnPosition(position).Sprite, show and 1 or 0)
    end
  else
    self.m_completeTileMap:GetValueOnPosition(position).Show = show
    if animation then
      self.m_completeTileMap:GetValueOnPosition(position).Sprite:DOFade(show and 1 or 0, 0.2)
    else
      UIUtil.SetAlpha(self.m_completeTileMap:GetValueOnPosition(position).Sprite, show and 1 or 0)
    end
  end
end

function MainBoardView:UpdateCompleteTileColor(color)
  color = color or self.CompleteTileColor
  local tileSprite, alpha
  for position in self.m_model:GetValidPositionIterator() do
    tileSprite = self.m_completeTileMap:GetValueOnPosition(position).Sprite
    alpha = tileSprite.color.a
    tileSprite.color = color
    UIUtil.SetAlpha(tileSprite, alpha)
  end
end

function MainBoardView:_InitSandFills()
  local invalidMap = {}
  
  local function setInvalid(x, y)
    if invalidMap[x] == nil then
      invalidMap[x] = {}
    end
    invalidMap[x][y] = false
  end
  
  for y = 1, self.m_model.VerticalTiles do
    setInvalid(1, y)
  end
  for x = 1, self.m_model.HorizontalTiles do
    setInvalid(x, 1)
  end
  for position in self.m_model:GetValidPositionIterator() do
    local x = position:GetX()
    local y = position:GetY()
    local itemModel = self.m_model:GetItem(position)
    if itemModel == nil then
      setInvalid(x, y)
      setInvalid(x, y + 1)
      setInvalid(x + 1, y)
      setInvalid(x + 1, y + 1)
    elseif itemModel:GetComponent(ItemPaperBox) == nil then
      setInvalid(x, y)
      setInvalid(x + 1, y)
      if itemModel:GetComponent(ItemCobweb) == nil then
        setInvalid(x, y + 1)
        setInvalid(x + 1, y + 1)
      end
    end
  end
  self.m_mapSandFills = nil
  for position in self.m_model:GetValidPositionIterator() do
    local x = position:GetX()
    local y = position:GetY()
    if invalidMap[x] == nil or invalidMap[x][y] == nil then
      local sandFillObject = Object.Instantiate(self.m_sandFillPrefab, self.m_sandFillsTransform)
      local localPosition = self.m_model:ToLocalPosition(position)
      sandFillObject.transform.localPosition = Vector3(localPosition.x, localPosition.y + self.m_model.TileSize, 0)
      if self.m_mapSandFills == nil then
        self.m_mapSandFills = self.m_model:CreateMatrix()
      end
      self.m_mapSandFills:SetValueOnPosition(position, sandFillObject)
    end
  end
end

function MainBoardView:_TryToRemoveSandFills(removeItemModel)
  if self.m_mapSandFills == nil then
    return
  end
  local cobwebItem = removeItemModel:GetComponent(ItemCobweb) ~= nil
  local paperboxItem = removeItemModel:GetComponent(ItemPaperBox) ~= nil
  if cobwebItem or paperboxItem then
    if self.m_sandFillRemoveFunc == nil then
      function self.m_sandFillRemoveFunc(x, y)
        if x < 1 or x > self.m_model.HorizontalTiles or y < 1 or y > self.m_model.VerticalTiles then
          return
        end
        local targetSandFillObject = self.m_mapSandFills:Get(x, y)
        if targetSandFillObject ~= nil then
          targetSandFillObject:RemoveSelf()
          self.m_mapSandFills:Set(x, y, nil)
        end
      end
    end
    local position = removeItemModel:GetPosition()
    local x, y = position:GetX(), position:GetY()
    if paperboxItem then
      self.m_sandFillRemoveFunc(x, y)
      self.m_sandFillRemoveFunc(x + 1, y)
    end
    if cobwebItem then
      self.m_sandFillRemoveFunc(x, y + 1)
      self.m_sandFillRemoveFunc(x + 1, y + 1)
    end
  end
end

function MainBoardView:_SandFillRemove(x, y)
  if x < 1 or x > self.m_model.HorizontalTiles or y < 1 or y > self.m_model.VerticalTiles then
    return
  end
  local targetSandFillObject = self.m_mapSandFills:Get(x, y)
  if targetSandFillObject ~= nil then
    targetSandFillObject:RemoveSelf()
    self.m_mapSandFills:Set(x, y, nil)
  end
end

function MainBoardView:ClearSelectedInfo()
  self:_UpdateIndicator()
  self.m_infoBar:UpdateInfoBar()
end

function MainBoardView:_CanShowMergeLight(itemModel, lastItemModel)
  if GM.TutorialModel:GetForceEffectBoardPosition() and GM.TutorialModel:GetForceEffectBoardPosition() ~= itemModel:GetPosition() then
    return false
  end
  if self.m_model:CanItemAffect(lastItemModel, itemModel) then
    return true
  end
  return BaseActionBoardView._CanShowMergeLight(self, itemModel, lastItemModel)
end

function MainBoardView:_ShowMergeLight(itemView)
  BaseActionBoardView._ShowMergeLight(self, itemView)
  self.m_lastMergableItem = itemView:GetModel()
  self.m_lastMergableItemTime = CS.UnityEngine.Time.timeSinceLevelLoad
end

function MainBoardView:_PlayRemoveOrderItemAnimation(targetCell, index, itemModel, moveDuration, removeDelay)
  if self.m_selectedBoardPosition == itemModel:GetPosition() then
    self:_UpdateIndicator()
    self.m_infoBar:UpdateInfoBar()
  end
  local targetIcon = targetCell:GetIcon(index)
  local targetPosition = targetIcon.transform.position
  targetPosition = Vector3(targetPosition.x, targetPosition.y, 0)
  local itemView = self:GetItemView(itemModel)
  itemView:SetFlying(true)
  itemView.toBeRemoved = true
  local transform = itemView.transform
  local position = transform.position
  position = Vector3(position.x, position.y, 0)
  transform.position = position
  local sequence = DOTween.Sequence()
  sequence:Insert(0, transform:DOMove(targetPosition, moveDuration):SetEase(Ease.OutQuad))
  sequence:Insert(0, transform:DOScale(1.8, moveDuration * 0.7))
  sequence:Insert(moveDuration * 0.7, transform:DOScale(0.8, moveDuration * 0.3))
  sequence:InsertCallback(removeDelay, function()
    self:_RemoveItemView(itemView)
    if targetCell:GetOrder():GetSlot() == MainOrderSlotDefinition.ExtraCustomerSlot then
      targetCell:PlayDeliverAnim()
    end
  end)
end

function MainBoardView:_PlayAddOrderItemAnimation(targetCell, itemModel)
  local itemView = self:_AddItemView(itemModel)
  if itemView == nil then
    return
  end
  itemView.gameObject:SetActive(false)
  itemView:SetFlying(true)
  local targetIcon = targetCell:GetIcon(1)
  local targetPosition = targetIcon.transform.position
  targetPosition = Vector3(targetPosition.x, targetPosition.y, 0)
  local position = itemView.transform.position
  local positionZero = Vector3(position.x, position.y, 0)
  itemView.transform.position = targetPosition
  itemView.transform.localScale = Vector3(0.8, 0.8, 1)
  local sequence = DOTween.Sequence()
  sequence:InsertCallback(1, function()
    itemView.gameObject:SetActive(true)
  end)
  sequence:Insert(0.9, itemView.transform:DOMove(positionZero, 0.8):SetEase(Ease.InQuad))
  sequence:Insert(0.9, itemView.transform:DOScale(1.8, 0.3))
  sequence:Insert(1.2, itemView.transform:DOScale(1, 0.5))
  sequence:InsertCallback(1.7, function()
    itemView:SetFlying(false)
    itemView.transform.position = position
  end)
end

function MainBoardView:_ShowRetrieveLight()
  for i = #self.m_retrieveList, 1, -1 do
    self.m_retrieveList[i]:ShowRetrieveLight()
    self.m_retrieveList[i] = nil
  end
end

function MainBoardView:PlayItemFly2OrderItemAnimation(targetCell, index, itemType, sourceUIWorldPos, scale)
  self:_PlayCustomItem2OrderItemAnimation(targetCell, index, itemType, sourceUIWorldPos, scale, 0.7, 0.7)
end

function MainBoardView:_OnPointerDown(eventData)
  self:_ClearPointerDataOnUnexpectedPointerExit()
  local screenPosition = eventData.position
  local worldPosition = self.m_camera:ScreenToWorldPoint(Vector3(screenPosition.x, screenPosition.y, 0))
  local boardPosition = self:_GetBoardPosition(worldPosition)
  if self.m_model:PositionIsValid(boardPosition) then
    local forceSourceBoardPosition = GM.TutorialModel:GetForceSourceBoardPosition()
    if forceSourceBoardPosition ~= nil and forceSourceBoardPosition ~= boardPosition then
      return
    end
    local itemModel = self.m_model:GetItem(boardPosition)
    if itemModel ~= nil then
      if itemModel:GetComponent(ItemPaperBox) ~= nil then
        return
      end
      self.m_lastTouchedItem = self:GetItemView(itemModel)
      self:_RecordLastTapGenerator(itemModel)
      self.lastTapItem = itemModel
      if self.m_selectedBoardPosition == boardPosition then
        self.m_moreThanOnceTap = true
      end
      self:_UpdateIndicator(itemModel, false)
      self.m_infoBar:UpdateInfoBar(itemModel)
      if self:_StartPromptStep2() then
        self.m_startedPromptStep2 = true
      else
        self:_CancelPrompt()
      end
      local pre_audioSource
      if itemModel:GetComponent(ItemSpread) ~= nil and (itemModel:GetComponent(ItemSpread):GetState() == ItemSpreadState.Opening or itemModel:GetComponent(ItemSpread):GetState() == ItemSpreadState.Closed) and self.m_moreThanOnceTap then
        pre_audioSource = AudioFileConfigName.SfxColdingClick
      elseif itemModel:GetComponent(ItemSpread) ~= nil and itemModel:GetComponent(ItemSpread):GetItemRestNumber() == 0 then
        pre_audioSource = AudioFileConfigName.SfxColdingClick
      end
      if pre_audioSource ~= nil then
        GM.AudioModel:PlayEffect(pre_audioSource)
      end
      EventDispatcher.DispatchEvent(EEventType.ItemClick, {})
    end
  end
end

function MainBoardView:_OnDrag(eventData)
  if self.m_lastTouchedItem == nil or self.m_lastTouchedItem:GetModel() == nil then
    return
  end
  local canItemMove = self.m_model:CanItemMove(self.m_lastTouchedItem:GetModel())
  if not self.m_dragging and canItemMove then
    EventDispatcher.DispatchEvent(EEventType.StartDraggingItem, {
      item = self.m_lastTouchedItem
    })
    self:_UpdateIndicator()
    self:UpdateCompleteTileDisplay(self.m_lastTouchedItem:GetModel():GetPosition(), false, true)
    self:_UpdateItemAffectedEffect()
  end
  self.m_dragging = true
  if not canItemMove then
    return
  end
  local screenPosition = eventData.position
  if eventData.pointerCurrentRaycast.gameObject and eventData.pointerCurrentRaycast.gameObject.name == "Inventory" then
    if not self.m_onInventory then
      self.m_onInventory = true
      self:_GetInventoryButton():PlayDragStartEffect()
    end
  elseif self.m_onInventory then
    self:_GetInventoryButton():PlayDragEndEffect()
    self.m_onInventory = false
  end
  local worldPosition = self.m_camera:ScreenToWorldPoint(Vector3(screenPosition.x, screenPosition.y, 0))
  self.m_lastTouchedItem.transform.position = Vector3(worldPosition.x, worldPosition.y, 0)
  self:_TryShowMergeLight(worldPosition)
end

function MainBoardView:_UpdateItemAffectedEffect()
  for _, view in pairs(self.m_modelViewMap) do
    if view ~= self.m_lastTouchedItem and (not GM.TutorialModel:GetForceEffectBoardPosition() or GM.TutorialModel:GetForceEffectBoardPosition() == view:GetModel():GetPosition()) then
      view:UpdateItemAffectedEffect(self.m_lastTouchedItem and self.m_lastTouchedItem:GetModel() or nil)
    end
  end
end

function MainBoardView:_OnPointerUp(eventData)
  if self.m_lastTouchedItem == nil then
    return
  end
  self:_ClearMergeLight()
  local screenPosition = eventData.position
  local worldPosition = self.m_camera:ScreenToWorldPoint(Vector3(screenPosition.x, screenPosition.y, 0))
  local targetBoardPosition = self:_GetBoardPosition(worldPosition)
  if self.m_lastMergableItem ~= nil and CS.UnityEngine.Time.timeSinceLevelLoad - self.m_lastMergableItemTime < 0.15 then
    local lastMergeablePosition = self.m_lastMergableItem:GetPosition()
    if (lastMergeablePosition:GetX() - targetBoardPosition:GetX()) ^ 2 <= 1 and 1 >= (lastMergeablePosition:GetY() - targetBoardPosition:GetY()) ^ 2 then
      targetBoardPosition = lastMergeablePosition
    end
  end
  local forceTargetBoardPosition = GM.TutorialModel:GetForceTargetBoardPosition()
  if forceTargetBoardPosition ~= nil and forceTargetBoardPosition ~= targetBoardPosition then
    targetBoardPosition = BoardPosition.Create(0, 0)
  end
  local itemModel = self.m_lastTouchedItem:GetModel()
  local boardPositionChanged = targetBoardPosition ~= itemModel:GetPosition()
  self.m_lastMergableItem = nil
  self.m_lastMergableItemTime = nil
  if self.m_onInventory then
    self:_GetInventoryButton():PlayDragEndEffect()
    self.m_onInventory = false
  end
  if self.m_dragging then
    if self.m_model:CanItemMove(itemModel) then
      if eventData.pointerCurrentRaycast.gameObject ~= nil and eventData.pointerCurrentRaycast.gameObject.name == "Inventory" then
        local stored = false
        if GM.OpenFunctionModel:IsFunctionOpen(EFunction.Inventory) then
          if self.m_model:StoreItem(itemModel) then
            self:_GetInventoryButton():PlayItemInEffect()
            stored = true
          end
        else
          self:_GetInventoryButton():ShowLockedPrompt()
        end
        if not stored then
          self.m_model:DragItem(itemModel, targetBoardPosition, false)
        end
      else
        self.m_model:DragItem(itemModel, targetBoardPosition)
        if self.m_model:GetItem(itemModel:GetPosition()) == itemModel then
          self.m_selectedBoardPosition = itemModel:GetPosition()
        else
          self.m_selectedBoardPosition = targetBoardPosition
        end
      end
    end
  else
    if self.m_moreThanOnceTap and (forceTargetBoardPosition == nil or forceTargetBoardPosition == itemModel:GetPosition()) then
      if self.m_infoBar:GetOpenBtnGo().activeInHierarchy then
        self.m_infoBar:GetInfoContent():OnOpenButtonClicked()
      elseif self.m_infoBar:GetActivateBtnGo().activeInHierarchy then
        self.m_infoBar:GetInfoContent():OnActivateButtonClicked()
      elseif (itemModel:GetComponent(ItemBubble) ~= nil or itemModel:GetComponent(ItemPropertyBubble) ~= nil) and not GM.TutorialModel:HasAnyStrongTutorialOngoing() then
        self.m_model:BreakItem(itemModel)
      elseif itemModel:GetComponent(ItemChoose) == nil then
        self.m_model:TapItem(itemModel)
      elseif not GM.UIManager:IsEventLock() and not GM.UIManager:IsViewExisting(UIPrefabConfigName.ItemChooseWindow) then
        GM.UIManager:OpenView(UIPrefabConfigName.ItemChooseWindow, itemModel)
      end
    end
    if self.m_model:GetItem(itemModel:GetPosition()) == itemModel then
      local itemView = self:GetItemView(itemModel)
      itemView:PlayTapAnimation(0.2)
    end
  end
  local selectedItem = self:GetSelectedItemModel()
  local selectedItemDisappeared = selectedItem ~= itemModel and self.m_model:GetItem(itemModel:GetPosition()) ~= itemModel
  local itemCollectableTipShowStatus
  if selectedItemDisappeared then
    itemCollectableTipShowStatus = ItemCollectableTipShowStatus.MergeItem
  elseif not boardPositionChanged then
    itemCollectableTipShowStatus = ItemCollectableTipShowStatus.SelectItem
  else
    itemCollectableTipShowStatus = ItemCollectableTipShowStatus.None
  end
  self:_UpdateIndicator(selectedItem, true, itemModel == selectedItem, itemCollectableTipShowStatus)
  self.m_infoBar:UpdateInfoBar(selectedItem)
  EventDispatcher.DispatchEvent(EEventType.BoardPointerUp, {
    dragging = self.m_dragging
  })
  self:_ClearPointerData()
  self:_UpdateItemAffectedEffect()
  if self.m_startedPromptStep2 then
    self.m_startedPromptStep2 = false
  else
    self:_StartPrompt()
  end
  self:_UpdateCompleteTiles(true)
end

function MainBoardView:_ClearPointerData()
  self.m_moreThanOnceTap = false
  self.m_dragging = false
  self.m_lastTouchedItem = nil
end

function MainBoardView:OnTutorialAnyStrongTutorialUpdated(enabled)
  if enabled then
    self:_CancelPrompt()
  end
end

function MainBoardView:_StartPromptStep2()
  return self.m_prompt ~= nil and self.m_prompt:StartStep2(self)
end

function MainBoardView:_GetPrompts()
  if GameConfig.IsTestMode() and TestMaskButton.autoMergeAll then
    return {
      BoardPromptMergeItems.Create(),
      BoardPromptStoreItem.Create(),
      BoardPromptFinishTask.Create()
    }
  end
  return {
    BoardPromptGeneratorFactory.Create(),
    BoardPromptMergeItems.Create(),
    BoardPromptOpenChest.Create(),
    BoardPromptTapNonDisposableSpreadItem.Create(),
    BoardPromptTapDisposableSpreadItem.Create(),
    BoardPromptFinishOrder.Create(),
    BoardPromptSwallowItems.Create(),
    BoardPromptTapCacheItems.Create(),
    BoardPromptStoreItem.Create(),
    BoardPromptFinishTask.Create()
  }
end

function MainBoardView:_StartPrompt()
  if self:IsPromptLock() then
    return
  end
  local isNewUser = not GM.MainTaskModel:IsTaskFinished(1, 3)
  local interval = isNewUser and MainBoardView.MergePromptIntervalNewUser or MainBoardView.MergePromptInterval
  self:_DoStartPrompt(interval)
end

function MainBoardView:_SelectPrompt()
  local promptConfig = self.m_model:GetPromptConfig()
  
  local function isOpen(prompt)
    local closeCondition = promptConfig[prompt:GetType()].CloseCondition
    if closeCondition == nil then
      return true
    end
    local parts = StringUtil.Split(closeCondition, "_")
    if #parts == 1 then
      return GM.LevelModel:GetCurrentLevel() < tonumber(parts[1])
    else
      return not GM.MainTaskModel:IsTaskFinished(tonumber(parts[1]), tonumber(parts[2]))
    end
  end
  
  return self:_DoSelectPrompt(isOpen)
end

function MainBoardView:_OnOrderStateChanged()
  self:_UpdateCompleteTiles(true)
  self:_TryStartPrompt()
end

function MainBoardView:AddPromptLock(target)
  Log.Assert(target ~= nil and target.gameObject ~= nil and not target.gameObject:IsNull(), "PromptLock\232\174\190\231\189\174\231\154\132Target\228\184\186\231\169\186")
  if self.m_mapPromptLockInfo[target] == nil then
    self.m_mapPromptLockInfo[target] = 0
  end
  self.m_mapPromptLockInfo[target] = self.m_mapPromptLockInfo[target] + 1
end

function MainBoardView:ReducePromptLock(target)
  if self.m_mapPromptLockInfo[target] ~= nil then
    self.m_mapPromptLockInfo[target] = self.m_mapPromptLockInfo[target] - 1
    if self.m_mapPromptLockInfo[target] <= 0 then
      self.m_mapPromptLockInfo[target] = nil
    end
  end
end

function MainBoardView:IsPromptLock()
  if Table.IsEmpty(self.m_mapPromptLockInfo) then
    return false
  end
  for target, count in pairs(self.m_mapPromptLockInfo) do
    if target.gameObject == nil or target.gameObject:IsNull() then
      self.m_mapPromptLockInfo[target] = nil
    end
  end
  if Table.IsEmpty(self.m_mapPromptLockInfo) then
    return false
  end
  return true
end

function MainBoardView:_TryStartPromptByEvent()
  self:_TryStartPrompt()
end

function MainBoardView:_TryStartPrompt()
  if self.gameObject.activeInHierarchy and GM.UIManager.allWindowClosed and not self:IsPromptLock() then
    self:_StartPrompt()
  end
end

function MainBoardView:_ClearPointerDataOnUnexpectedPointerExit()
  self:_ClearMergeLight()
  if self.m_lastTouchedItem == nil then
    return
  end
  self.m_eventTrigger:ResetPressedState()
  if self.m_onInventory then
    self:_GetInventoryButton():PlayDragEndEffect()
    self.m_onInventory = false
  end
  local itemModel = self.m_lastTouchedItem:GetModel()
  if itemModel ~= nil and self.m_model:CanItemMove(itemModel) then
    self.m_model:DragItem(itemModel, BoardPosition.Create(0, 0))
  end
  local selectedItem = self:GetSelectedItemModel()
  self:_UpdateIndicator(selectedItem, true)
  if not self.m_infoBar.gameObject:IsNull() then
    self.m_infoBar:UpdateInfoBar(selectedItem)
  end
  self:_ClearPointerData()
  self:_UpdateItemAffectedEffect()
end

function MainBoardView:_OnCloseView(msg)
  self:_TryStartPrompt()
  if msg.name == UIPrefabConfigName.InventoryWindow then
    self:_ShowRetrieveLight()
  end
end

function MainBoardView:_PlayCustomItem2OrderItemAnimation(targetCell, index, itemType, sourceUIWorldPosition, scale, moveDuration, removeDelay)
  local targetIcon = targetCell:GetIcon(index)
  local targetPosition = targetIcon.transform.position
  targetPosition = Vector3(targetPosition.x, targetPosition.y, 0)
  targetPosition = PositionUtil.UICameraScreen2World(self.m_camera:WorldToScreenPoint(targetPosition))
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.FlyElement), GM.UIManager:GetCanvasRoot(), sourceUIWorldPosition, function(go)
    if not go:IsNull() then
      local image = go:GetComponent(typeof(Image))
      SpriteUtil.SetImage(image, GM.ItemDataModel:GetSpriteName(itemType), true, function()
        if not image:IsNull() then
          image.enabled = true
        end
      end)
      local transform = go.transform
      UIUtil.SetLocalPosition(transform, nil, nil, 0)
      transform.localScale = scale
      local sequence = DOTween.Sequence()
      sequence:Insert(0, transform:DOMove(targetPosition, moveDuration):SetEase(Ease.OutQuad))
      sequence:Insert(0, transform:DOScale(1.8, moveDuration * 0.7))
      sequence:Insert(moveDuration * 0.7, transform:DOScale(0.8, moveDuration * 0.3))
      sequence:InsertCallback(removeDelay, function()
        AddressableLoader.Destroy(go)
      end)
    end
  end)
end

function MainBoardView:_PlayInventory2OrderItemAnimation(targetCell, index, itemType, scale, moveDuration, removeDelay)
  local sceneView = GM.UIManager:GetOpenedTopViewByType(EViewType.SceneView)
  local sourceWorldPos = sceneView:GetHudButton(ESceneViewHudButtonKey.Inventory).transform.position
  self:_PlayCustomItem2OrderItemAnimation(targetCell, index, itemType, sourceWorldPos, scale, moveDuration, removeDelay)
end

function MainBoardView:_PlaySpecialOrderFinishAnimation(orderModel, removeItems, addItems, unlockOnLeave, cellLeaveDelay, cellLeaveCallback, cellRemoveDelay, cellRemoveCallback)
  self.m_orderArea:ForceRebuildLayout()
  GM.UIManager:SetEventLock(true)
  removeItems = removeItems or Table.Empty
  addItems = addItems or Table.Empty
  local targetCell = self.m_orderArea:GetCell(orderModel)
  for _, itemModel in pairs(removeItems) do
    self:_PlayRemoveOrderItemAnimation(targetCell, 1, itemModel, 0.7, 0.7)
  end
  for _, itemModel in ipairs(addItems) do
    self:_PlayAddOrderItemAnimation(targetCell, itemModel)
  end
  local sequence = DOTween.Sequence()
  sequence:InsertCallback(cellLeaveDelay, function()
    targetCell:PlayLeaveAnimation()
    if cellLeaveCallback ~= nil then
      cellLeaveCallback()
    end
    if unlockOnLeave then
      GM.UIManager:SetEventLock(false)
    end
  end)
  sequence:InsertCallback(cellRemoveDelay, function()
    self.m_orderArea:RemoveCell(orderModel)
    if cellRemoveCallback ~= nil then
      cellRemoveCallback()
    end
    if not unlockOnLeave then
      GM.UIManager:SetEventLock(false)
    end
  end)
end

function MainBoardView:_OnRemoverOrderImmediate(message)
  self.m_orderArea:RemoveCell(message.Order)
end

function MainBoardView:_OnFinishSpecialOrder(message)
  self:_PlaySpecialOrderFinishAnimation(message.Order, message.Removed, message.New, true, 1.4, function()
    local orderConfig = self.m_model:GetSpecialOrderConfig(message.Order)
    GM.UIManager:OpenView(UIPrefabConfigName.SpecialOrderCompleteWindow, orderConfig)
  end, 2.6, nil)
end

function MainBoardView:_OnFinishBranchOrder(message)
  self:_PlaySpecialOrderFinishAnimation(message.Order, message.Removed, message.New, false, 1.8, nil, 3, function()
    local orderConfig = self.m_model:GetSpecialOrderConfig(message.Order)
    GM.TimelineModel:StartSpTimeline(orderConfig.EndTimeline)
  end)
end

function MainBoardView:_OnStoreItem(message)
  local itemView = self:GetItemView(message.Source)
  self:_RemoveItemView(itemView)
  self:_UpdateIndicator()
  self.m_infoBar:UpdateInfoBar()
  EventDispatcher.DispatchEvent(EEventType.VibrationMedium)
  GM.AudioModel:PlayEffect(AudioFileConfigName.sfxMoveToTepository)
end

function MainBoardView:_OnRetrieveStoredItem(message)
  local itemView = self:_AddItemView(message.Source)
  if itemView == nil then
    return
  end
  EventDispatcher.DispatchEvent(EEventType.VibrationLight)
  self.m_retrieveList[#self.m_retrieveList + 1] = itemView
  self:_UpdateIndicator(message.Source, true)
  if not self.m_infoBar.gameObject:IsNull() then
    self.m_infoBar:UpdateInfoBar(message.Source)
  end
end

function MainBoardView:_OnStoreFailed(message)
  local function onStoreFailed()
    local itemView = self:GetItemView(message.Item)
    
    local targetPosition = itemView.transform.position + Vector3(0, 100, 0)
    local screenPosition = self:ConvertWorldPositionToScreenPosition(targetPosition)
    local key = message.Reason == StoreFailedReason.CannotStore and "hint_cannot_store" or "hint_inventory_full"
    if message.Reason == StoreFailedReason.GeneratorFactory then
      key = "generator_factory_nomove"
    end
    GM.UIManager:ShowPromptWithKey(key, screenPosition)
  end
  
  DOVirtual.DelayedCall(ItemView.MoveDuration, onStoreFailed)
end

function MainBoardView:_OnBatchRemoveItems(message)
  for _, itemModel in ipairs(message.Removed) do
    local itemView = self:GetItemView(itemModel)
    itemView.toBeRemoved = true
    itemView.transform:DOScale(0, 0.5):OnComplete(function()
      self:_RemoveItemView(itemView)
    end)
    if self.m_selectedBoardPosition == itemModel:GetPosition() then
      self:_UpdateIndicator()
      self.m_infoBar:UpdateInfoBar()
    end
  end
end

function MainBoardView:_OnAddCacheItem(message)
  if message.CacheItem == nil then
    return
  end
  local itemView = self.m_itemViewFactory:CreateFlyItem(self, message.CacheItem, ItemFlyView.EFLYTYPE.Default)
  local localPos = message.Source:GetLocalPosition()
  itemView.transform.localPosition = Vector3(localPos.x, localPos.y, -90)
  local orderArea = self:GetOrderArea()
  local transf = orderArea:GetCacheRoot()
  if transf ~= nil then
    local targetPos = transf.position + Vector3(0, -30, 0)
    itemView:FlyToTarget(targetPos, message.EnergyBoost)
  end
end

function MainBoardView:_OnAddAdventureActivityItem(message)
  local cell
  for activityType, _ in pairs(AdventureActivityDefinition) do
    local orderArea = self:GetOrderArea()
    cell = orderArea:GetActivityBubble(activityType)
    if cell ~= nil then
      break
    end
  end
  if cell == nil then
    return
  end
  local targetPos = cell:GetTargetPosition()
  local itemView = self.m_itemViewFactory:CreateFlyItem(self, message.AdventureActivityItem, ItemFlyView.EFLYTYPE.AdventureActivity)
  itemView:SetNum(message.AdventureActivityItemCount)
  if message.FromType == AdventureActivityModel.GenItemFromType.Energy then
    local localPos = message.Source:GetLocalPosition()
    itemView.transform.localPosition = Vector3(localPos.x, localPos.y, -90)
  elseif message.FromType == AdventureActivityModel.GenItemFromType.Order then
    local order = message.Source
    local orderCell = self.m_orderArea:GetCell(order)
    itemView.transform.position = orderCell.transform.position + Vector3(0, 0, -90)
    itemView.transform.localPosition = itemView.transform.localPosition + Vector3(0, -150, 0)
  end
  itemView:FlyToTarget(targetPos, message.EnergyBoost)
end

function MainBoardView:_OnAddMultiboardsActivityItem(message)
  local cell
  for activityType, _ in pairs(MultiboardsActivityDefinition) do
    local orderArea = self:GetOrderArea()
    cell = orderArea:GetActivityBubble(activityType)
    if cell ~= nil then
      break
    end
  end
  if cell == nil then
    return
  end
  local targetPos = cell:GetTargetPosition()
  local itemView = self.m_itemViewFactory:CreateFlyItem(self, message.MultiboardsActivityItem, ItemFlyView.EFLYTYPE.MultiboardsActivity)
  itemView:SetNum(message.MultiboardsActivityItemCount)
  local order = message.Source
  local orderCell = self.m_orderArea:GetCell(order)
  itemView.transform.position = orderCell.transform.position + Vector3(0, 0, -90)
  itemView.transform.localPosition = itemView.transform.localPosition + Vector3(0, -150, 0)
  itemView:FlyToTarget(targetPos, message.EnergyBoost)
end

function MainBoardView:_OnCollectPuzzleToken(message)
  local orderCell = self.m_orderArea:GetCell(message.Order)
  local sourcePosition = orderCell.transform.position + Vector3(0, -150, -90)
  local targetEntry = self.m_orderArea:GetActivityBubble(ActivityType.Puzzle)
  targetEntry:CreateFlyItem(UIPrefabConfigName.PuzzleScoreItem, self, sourcePosition, message.Number)
end

function MainBoardView:_OnCollectScoreRaceToken(message)
  local orderCell = self.m_orderArea:GetCell(message.Order)
  local sourcePosition = orderCell.transform.position + Vector3(0, -150, -90)
  local targetEntry = self.m_orderArea:GetActivityBubble(ActivityType.ScoreRace)
  targetEntry:CreateFlyItem(UIPrefabConfigName.ScoreRaceFlyScore, self, sourcePosition, message.Number)
end

function MainBoardView:_OnCollectFarmboardToken(message)
  local orderCell = self.m_orderArea:GetCell(message.Order)
  local sourcePosition = orderCell.transform.position + Vector3(0, -150, -90)
  local targetEntry = self.m_orderArea:GetActivityBubble(message.ActivityType)
  targetEntry:CreateFlyItem(UIPrefabConfigName.FarmboardActivityScoreItem, self, sourcePosition, message.RewardItem)
end

function MainBoardView:_OnAddOrderFinishItem(message)
  local cell = self.m_orderArea:GetActivityBubble(message.ActivityType)
  if cell == nil then
    return
  end
  local targetPos = cell:GetTargetPosition()
  local itemView = self.m_itemViewFactory:CreateFlyItem(self, message.Img, message.ItemFlyType)
  itemView:SetNum(message.Count)
  local order = message.Source
  local orderCell = self.m_orderArea:GetCell(order)
  itemView.transform.position = orderCell.transform.position + Vector3(0, 0, -90)
  itemView.transform.localPosition = itemView.transform.localPosition + Vector3(0, -150, 0)
  itemView:FlyToTarget(targetPos, message.EnergyBoost)
end

function MainBoardView:_OnZeroCDItemBuffConsume(message)
  local item, itemView
  for position in self.m_model:GetValidPositionIterator() do
    item = self.m_model:GetItem(position)
    if item ~= nil and item:GetComponent(ItemSpread) ~= nil and item:GetComponent(ItemSpread):CanSupportCDBuff() then
      itemView = self:GetItemView(item)
      if itemView ~= nil then
        itemView:PlayShowNoCDItemAct()
      end
    end
  end
end

function MainBoardView:_OnGeneratorBoostBuffActive()
  local item, itemView
  for position in self.m_model:GetValidPositionIterator() do
    item = self.m_model:GetItem(position)
    if item ~= nil then
      local itemSpread = item:GetComponent(ItemSpread)
      if itemSpread ~= nil and itemSpread:CanSupportGeneratorBoost() then
        itemView = self:GetItemView(item)
        if itemView ~= nil then
          itemView:PlayGeneratorBoostBuffActiveAnimation()
        end
      end
    end
  end
end

function MainBoardView:_OnDiscoBoostTrigger()
  local item, itemView
  for position in self.m_model:GetValidPositionIterator() do
    item = self.m_model:GetItem(position)
    if item ~= nil then
      local itemSpread = item:GetComponent(ItemSpread)
      if itemSpread ~= nil and itemSpread:CanSupportBoostDisco() then
        itemView = self:GetItemView(item)
        if itemView ~= nil then
          itemView:PlayGeneratorBoostBuffActiveAnimation()
        end
      end
    end
  end
end

function MainBoardView:_OnSmartBuffConsume()
  local item, itemView
  for position in self.m_model:GetValidPositionIterator() do
    item = self.m_model:GetItem(position)
    if item ~= nil then
      local itemSpread = item:GetComponent(ItemSpread)
      if itemSpread ~= nil and itemSpread:CanSupportSmart() then
        itemView = self:GetItemView(item)
        if itemView ~= nil then
          itemView:PlayShowNoCDItemAct()
        end
      end
    end
  end
end

function MainBoardView:_OnAdd2GeneratorFactory(message)
  local targetPos = self:_GetInventoryButton().transform.position
  targetPos = PositionUtil.WorldToScreenPoint(GM.UIManager.camera, targetPos)
  targetPos = PositionUtil.ScreenToWorldPoint(self.m_camera, targetPos)
  targetPos = Vector3(targetPos.x, targetPos.y, 0)
  local itemModel = message.Source
  local itemView = self:GetItemView(itemModel)
  itemView:SetFlying(true)
  itemView.toBeRemoved = true
  local transform = itemView.transform
  GM.AudioModel:PlayEffect(AudioFileConfigName.sfxCardFly)
  local sequence = DOTween.Sequence()
  sequence:Insert(0, transform:DOMove(targetPos, 0.5):SetEase(Ease.OutQuad))
  sequence:InsertCallback(0, function()
    self:_GetInventoryButton():PlayDragStartEffect()
  end)
  sequence:InsertCallback(0.7, function()
    self:_GetInventoryButton():PlayDragEndEffect()
    self:_RemoveItemView(itemView)
    GM.AudioModel:PlayEffect(AudioFileConfigName.SfxEnergyCrush)
    EventDispatcher.DispatchEvent(EEventType.VibrationLight)
    local window = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.InventoryWindow)
    if window ~= nil then
      self:_GetInventoryButton():_UpdateIconState(true)
    end
  end)
end

function MainBoardView:_OnReplaceItem(message)
  local oldItem = message.oldItem
  local newItem = message.newItem
  local itemView = self:GetItemView(oldItem)
  self:_RemoveItemView(itemView)
  self:_AddItemView(newItem)
  self:_UpdatePaperBoxReward()
  local position = oldItem:GetPosition()
  local x, y = position:GetX(), position:GetY()
  self:_SandFillRemove(x, y)
  self:_SandFillRemove(x + 1, y)
  self:_SandFillRemove(x, y + 1)
  self:_SandFillRemove(x + 1, y + 1)
end

function MainBoardView:_OnBuyActivityBubble(message)
  local itemModel = message.Source
  GM.MainBoardModel:RemoveItem(itemModel)
  self:_UpdateIndicator()
  self.m_infoBar:UpdateInfoBar()
  self:GetItemView(itemModel).toBeRemoved = true
  DelayExecuteFunc(function()
    self:_RemoveItemView(self:GetItemView(itemModel))
    message.Callback()
  end, 1)
end

function MainBoardView:_OnTempDisappear(message)
  if self.m_selectedBoardPosition == message.Source:GetPosition() then
    self:_UpdateIndicator(message.New, true)
    self.m_infoBar:UpdateInfoBar(message.New)
  end
  local sourceItemView = self:GetItemView(message.Source)
  sourceItemView.toBeRemoved = true
  local spriteRenderer = sourceItemView:GetSpriteRenderer()
  spriteRenderer.gameObject:SetActive(false)
  local innerSpriteRenderer = sourceItemView:GetInnerSpriteRenderer()
  local newItemView = self:_AddItemView(message.New)
  newItemView.transform.localScale = Vector3.zero
  local sequence = DOTween.Sequence()
  sequence:Append(innerSpriteRenderer:DOFade(0, 0.5))
  sequence:Insert(newItemView.transform:DOScale(1, 0.5))
  sequence:AppendCallback(function()
    self:_RemoveItemView(sourceItemView)
  end)
  local config = GM.DataResource.ScenePrefabConfig:GetConfig(ScenePrefabConfigName.effect_temp_disappear)
  local position = message.Source:GetLocalPositionOverrideZ(0)
  GM.ResourceLoader:LoadPrefab(config, self.transform, position, function()
  end)
end

function MainBoardView:_OnGameModeChanged()
  if GM.SceneManager:GetGameMode() == self.m_model:GetGameMode() then
    self:_UpdateIndicator()
    self.m_infoBar:UpdateInfoBar()
    local chestCustomerModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
    if chestCustomerModel and chestCustomerModel:GetHighestPriorityOrderSlotWaitingToScroll() ~= nil then
      self.m_bHasSetOrderAreaDefault = true
      local slot = chestCustomerModel:GetHighestPriorityOrderSlotWaitingToScroll()
      for model, cell in pairs(self.m_orderArea:GetCells(OrderModelType.Slot)) do
        if model.GetSlot ~= nil and model:GetSlot() == slot then
          if cell.ResetEnterEffectShown then
            DelayExecuteFuncInView(function()
              self.m_orderArea:ScrollToRectTransformMiddle(cell.gameObject.transform)
            end, 0.3, self)
            cell:ResetEnterEffectShown()
          end
          chestCustomerModel:MarkAllOrderScrolled()
          break
        end
      end
    elseif not GM.ConfigModel:IsOrderPositionOpt() then
      self.m_orderArea:ScrollToFront()
    elseif not self.m_bHasSetOrderAreaDefault then
      self.m_bHasSetOrderAreaDefault = true
      DelayExecuteFuncInView(function()
        local firstOrder = self.m_orderArea:GetFirstNormalOrder()
        if firstOrder ~= nil then
          self.m_orderArea:ScrollToRectTransformMiddle(firstOrder.gameObject.transform)
        end
      end, 0.1, self)
    end
  else
    self:_CancelPrompt()
    if self.m_lastTouchedItem ~= nil then
      self:_ClearPointerDataOnUnexpectedPointerExit()
    end
  end
  if GM.SceneManager:GetGameMode() == self.m_model:GetGameMode() then
    self:_UpdateBoardDisplay()
  end
end

function MainBoardView:_UpdateBoardDisplay()
  for activityType, activityDefinition in pairs(MainDecorActivityDefinition) do
    local activityModel = GM.ActivityManager:GetModel(activityType)
    if activityDefinition.MainBoardBgReplace and activityModel:GetState() == ActivityState.Started then
      if self.m_curBg ~= activityType then
        self.m_curBg = activityType
        self.m_boardBackground:UpdateBackgroundByConfig(activityDefinition.MainBoardBgReplace.Board)
        self:_UpdateTile(activityDefinition.MainBoardBgReplace.Tile.TileBg1 or nil, activityDefinition.MainBoardBgReplace.Tile.TileBg2 or nil)
      end
      self:UpdateCompleteTileColor(UIUtil.ConvertHexColor2CSColor(activityDefinition.CompleteTileColor))
      return
    end
  end
  for activityType, activityDefinition in pairs(MainDecorNewActivityDefinition) do
    local activityModel = GM.ActivityManager:GetModel(activityType)
    if activityDefinition.MainBoardBgReplace and activityModel:GetState() == ActivityState.Started then
      if self.m_curBg ~= activityType then
        self.m_curBg = activityType
        self.m_boardBackground:UpdateBackgroundByConfig(activityDefinition.MainBoardBgReplace.Board)
        self:_UpdateTile(activityDefinition.MainBoardBgReplace.Tile.TileBg1 or nil, activityDefinition.MainBoardBgReplace.Tile.TileBg2 or nil)
      end
      self:UpdateCompleteTileColor(UIUtil.ConvertHexColor2CSColor(activityDefinition.CompleteTileColor))
      return
    end
  end
  local bakeOutModel = GM.ActivityManager:GetModel(ActivityType.BakeOut)
  local bakeOutOn = bakeOutModel ~= nil and bakeOutModel:CanAcquireToken()
  if bakeOutOn then
    if self.m_curBg ~= EBoardBackgroundMode.BakeOut then
      self.m_curBg = EBoardBackgroundMode.BakeOut
      self.m_boardBackground:UpdateBackgroundByConfig(EBackgroundModeDataSet[EBoardBackgroundMode.BakeOut])
      self:_UpdateTile(ImageFileConfigName.tile_bg1_bakeout, ImageFileConfigName.tile_bg2_bakeout)
      self:UpdateCompleteTileColor(self.CompleteTileColor)
    end
    return
  end
  if self.m_curBg ~= EBoardBackgroundMode.Default then
    self.m_boardBackground:UpdateBackgroundByConfig(EBackgroundModeDataSet[EBoardBackgroundMode.Default])
    self:_UpdateTile()
    self.m_curBg = EBoardBackgroundMode.Default
    self:UpdateCompleteTileColor(self.CompleteTileColor)
  end
end

function MainBoardView:TestUpdatePaperBoxExtraReward()
  for pos, extraReward in pairs(self.m_mapPaperBoxExtraReward) do
    local itemModel = self.m_model:GetItem(pos)
    if itemModel == nil or itemModel:GetType() ~= ItemType.PaperBox then
      self.m_mapPaperBoxExtraReward[pos].gameObject:RemoveSelf()
      self.m_mapPaperBoxExtraReward[pos] = nil
    end
  end
end

local fullBoardScreenCount = 0

function MainBoardView:_OnOpenView(view)
  if self.gameObject.activeInHierarchy and not GM.UIManager.allWindowClosed then
    self:_CancelPrompt()
  end
  if view.fullBoardScreen and GM.SceneManager:GetGameMode() == EGameMode.Main then
    fullBoardScreenCount = fullBoardScreenCount + 1
    if 0 < fullBoardScreenCount then
      DelayExecuteFuncInView(function()
        if fullBoardScreenCount <= 0 then
          return
        end
        UIUtil.SetActive(GM.ModeViewController:GetBoardRootTrans().gameObject, false)
      end, 0.2, self)
    end
  end
end

function MainBoardView:_OnWillCloseView(view)
  if view.fullBoardScreen and GM.SceneManager:GetGameMode() == EGameMode.Main then
    fullBoardScreenCount = fullBoardScreenCount - 1
    if fullBoardScreenCount <= 0 then
      UIUtil.SetActive(GM.ModeViewController:GetBoardRootTrans().gameObject, true)
      self.m_orderArea:_OnGameModeChanged()
    end
  end
end

function MainBoardView:_OnResolutionChanged()
  Scheduler.Schedule(function()
    self:_UpdateInfoBarPosition()
  end, self, nil, 2, nil)
  self.m_boardBackground:AdjustBackground()
  self.m_orderArea:AdjustScreenSize()
end

function MainBoardView:GetMergeAudioSfx(message)
  local newItemType = message.New:GetType()
  local cardItemModel = GM.ActivityManager:GetModel(ActivityType.CardItem)
  if cardItemModel and cardItemModel:IsCardItemAndMaxLevel(newItemType) then
    return AudioFileConfigName.sfxCardItemMerge
  end
  local hasTempItem = message.Source:GetComponent(ItemTemp) ~= nil or message.Target:GetComponent(ItemTemp) ~= nil
  if hasTempItem then
    return AudioFileConfigName.SfxIceBreak
  end
  local numberType = tonumber(newItemType)
  if numberType ~= nil and numberType >= tonumber(ItemType.Dog02) and numberType <= tonumber(ItemType.Dog04) then
    return AudioFileConfigName.sfxDogBark1
  elseif numberType ~= nil and numberType >= tonumber(ItemType.Dog05) and numberType <= tonumber(ItemType.Dog07) then
    return AudioFileConfigName.sfxDogBark2
  elseif numberType ~= nil and numberType >= tonumber(ItemType.Dog08) and numberType <= tonumber(ItemType.Dog10) then
    return AudioFileConfigName.sfxDogBark3
  end
  return BaseActionBoardView.GetMergeAudioSfx(self, message)
end

function MainBoardView:_OnMergeItem(message)
  self:_UpdateIndicator(message.New, true)
  self.m_infoBar:UpdateInfoBar(message.New)
  BaseActionBoardView._OnMergeItem(self, message)
  self:_TryToRemoveSandFills(message.Target)
end

function MainBoardView:PlayMergeAnimation(message)
  local cardItemModel = GM.ActivityManager:GetModel(ActivityType.CardItem)
  if message.New ~= nil and cardItemModel:IsCardItemAndMaxLevel(message.New:GetType()) then
    self:PlayCardItemMergeAnimation(message)
  else
    BaseActionBoardView.PlayMergeAnimation(self, message)
  end
end

MainBoardView.PopCardItemMergeMaxTime = 1.8

function MainBoardView:PlayCardItemMergeAnimation(message)
  GM.AudioModel:PlayEffect(self:GetMergeAudioSfx(message))
  local sourceItemView = self:GetItemView(message.Source)
  sourceItemView.toBeRemoved = true
  local targetItemView = self:GetItemView(message.Target)
  targetItemView.toBeRemoved = true
  local newItemView = self:_AddItemView(message.New)
  local targetPosition = targetItemView.transform.localPosition
  local sequence = DOTween.Sequence()
  targetItemView:MergeLightDisappear()
  local leftItemView = sourceItemView.transform.localPosition.x < targetItemView.transform.localPosition.x and sourceItemView or targetItemView
  local rightItemView = sourceItemView.transform.localPosition.x >= targetItemView.transform.localPosition.x and sourceItemView or targetItemView
  sourceItemView.transform.localPosition = Vector3(sourceItemView.transform.localPosition.x, sourceItemView.transform.localPosition.y, 1)
  targetItemView.transform.localPosition = Vector3(targetItemView.transform.localPosition.x, targetItemView.transform.localPosition.y, 1)
  local targetPos = targetItemView.transform.localPosition
  leftItemView.transform.localPosition = targetPos + Vector3(-65, 0, 0)
  rightItemView.transform.localPosition = targetPos + Vector3(65, 0, 0)
  
  local function shakeFunc(trans, isDir)
    local isDir = isDir or 1
    local shakeSeq = DOTween.Sequence()
    shakeSeq:Append(trans:DORotate(Vector3(0, 0, isDir * 10), 0.05))
    shakeSeq:SetLoops(10, LoopType.Yoyo)
    return shakeSeq
  end
  
  local effectGo
  local effectKilled = false
  local leftGo, rightGo
  
  local function KillMergeEffect()
    effectKilled = true
    if effectGo then
      AddressableLoader.Destroy(effectGo)
      effectGo = nil
    end
    if leftGo then
      AddressableLoader.Destroy(leftGo)
      leftGo = nil
    end
    if rightGo then
      AddressableLoader.Destroy(rightGo)
      rightGo = nil
    end
  end
  
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.carditem_effect_shandian01), self.m_itemsTransform, Vector3.zero, function(go)
    if effectKilled then
      AddressableLoader.Destroy(go)
      return
    end
    go.transform.position = leftItemView.transform.position
    leftGo = go
  end)
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.carditem_effect_shandian01), self.m_itemsTransform, Vector3.zero, function(go)
    if effectKilled then
      AddressableLoader.Destroy(go)
      return
    end
    go.transform.position = rightItemView.transform.position
    rightGo = go
  end)
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.carditem_effect_shandian), self.m_itemsTransform, Vector3.zero, function(go)
    if effectKilled then
      AddressableLoader.Destroy(go)
      return
    end
    go.transform.position = newItemView.transform.position
    effectGo = go
  end)
  sequence:AppendCallback(function()
    EventDispatcher.DispatchEvent(EEventType.VibrationMedium)
  end)
  sequence:Append(shakeFunc(leftItemView.transform))
  sequence:Join(shakeFunc(rightItemView.transform, -1))
  sequence:Append(leftItemView.transform:DOLocalMove(targetPos + Vector3(-39, 0, 0), 0.167):SetEase(Ease.InOutSine))
  sequence:Join(rightItemView.transform:DOLocalMove(targetPos + Vector3(39, 0, 0), 0.167):SetEase(Ease.InOutSine))
  sequence:Append(leftItemView.transform:DOLocalMove(targetPos, 0.13):SetEase(Ease.InOutSine))
  sequence:Join(rightItemView.transform:DOLocalMove(targetPos, 0.13):SetEase(Ease.InOutSine))
  newItemView.transform.localScale = Vector3.zero
  sequence:AppendCallback(function()
    self:_RemoveItemView(sourceItemView)
    self:_RemoveItemView(targetItemView)
    if newItemView.gameObject:IsNull() then
      return
    end
    EventDispatcher.DispatchEvent(EEventType.VibrationMedium)
    newItemView.transform.localScale = V3One * 0.3
    local newItemSeq = DOTween.Sequence()
    newItemSeq:Append(newItemView.transform:DOScale(1.3, 0.2))
    newItemSeq:Append(newItemView.transform:DOScale(1, 0.1))
    KillMergeEffect()
    GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.carditem_effect_hecheng_bomb), self.m_itemsTransform, Vector3.zero, function(go)
      go.transform.position = newItemView.transform.position
      local seq = DOTween.Sequence()
      seq:AppendInterval(3)
      seq:AppendCallback(function()
        AddressableLoader.Destroy(go)
      end)
    end)
    GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.carditem_effect_qizi_down), self.m_itemsTransform, Vector3.zero, function(go)
      go.transform.position = newItemView.transform.position + Vector3(0, 0, 10)
      local seq = DOTween.Sequence()
      seq:AppendInterval(3)
      seq:AppendCallback(function()
        AddressableLoader.Destroy(go)
      end)
    end)
  end)
  GM.UIManager:SetEventLock(true, self)
  local delayPopSeq = DOTween.Sequence()
  delayPopSeq:AppendInterval(MainBoardView.PopCardItemMergeMaxTime)
  delayPopSeq:AppendCallback(function()
    GM.UIManager:SetEventLock(false, self)
    EventDispatcher.DispatchEvent(EEventType.CardItemMergeAniFinish)
  end)
end

function MainBoardView:_GetSpreadAudio(message)
  if message.BoardSpreadType == BoardSpreadType.CardItem then
    return AudioFileConfigName.sfxCardItemGenerate
  end
  if message.New:GetComponent(ItemBubble) ~= nil then
    return AudioFileConfigName.SfxMergeBubbleSpawn
  end
  if message.New:GetComponent(ItemTemp) ~= nil then
    return AudioFileConfigName.sfxTempItemAppear
  end
  if GM.ItemDataModel:GetChainId(message.Source:GetType()) == ItemChain.DogHouse then
    return AudioFileConfigName.sfxDogBark1
  end
  if message.BoardSpreadType == BoardSpreadType.Lucky or message.BoardSpreadType == BoardSpreadType.FreeLucky then
    return AudioFileConfigName.sfxLuckyProduce1
  elseif message.BoardSpreadType == BoardSpreadType.SuperLucky or message.BoardSpreadType == BoardSpreadType.FreeSuperLucky then
    return AudioFileConfigName.sfxLuckyProduce2
  elseif message.BoardSpreadType == BoardSpreadType.DoubleLucky or message.BoardSpreadType == BoardSpreadType.TripleLucky1 then
    return AudioFileConfigName.sfxLuckyProduce3
  elseif message.BoardSpreadType == BoardSpreadType.TripleLucky2 then
    return AudioFileConfigName.sfxLuckyProduce4
  end
  if message.EnergyBoostRatio > 0 then
    return AudioFileConfigName.SfxMergeSpawnManualEnergyBoost
  end
  return BaseActionBoardView._GetSpreadAudio(self, message)
end

function MainBoardView:_OnSpreadItem(message)
  BaseActionBoardView._OnSpreadItem(self, message)
  local itemSpread = message.Source:GetComponent(ItemSpread)
  if self.m_selectedBoardPosition == message.Source:GetPosition() and itemSpread ~= nil and itemSpread:IsAutoSpread() then
    self.m_infoBar:UpdateInfoBar(message.Source)
  end
end

function MainBoardView:_OnCollectItem(message)
  local rewards = message.Source:GetComponent(ItemCollectable):GetRewards()
  local CardItemModel = GM.ActivityManager:GetModel(ActivityType.CardItem)
  if rewards[1][PROPERTY_TYPE] == "skip" then
    local itemView = self:GetItemView(message.Source)
    self:_RemoveItemView(itemView)
    return
  elseif CardItemModel:IsCardItem(message.Source:GetType()) then
    local itemView = self:GetItemView(message.Source)
    self:_RemoveItemView(itemView)
    self:_UpdateIndicator(nil, false)
    self.m_infoBar:UpdateInfoBar(nil)
    return
  else
    BaseActionBoardView._OnCollectItem(self, message)
  end
end

function MainBoardView:_OnCollapseItem(message)
  if message.CollapseReward ~= nil then
    self:_PlayPaperboxExtraRewardAnimation(message)
  else
    self:_DOCollapseItem(message)
  end
end

function MainBoardView:_DOCollapseItem(message)
  if self.m_selectedBoardPosition == message.Source:GetPosition() then
    self:_UpdateIndicator()
    self.m_infoBar:UpdateInfoBar()
  end
  if message.UnlockShocked then
    local itemView = self:GetItemView(message.Source)
    local itemPaperBoxView = itemView:GetComponent(ItemPaperBox)
    if itemPaperBoxView ~= nil then
      GM.UIManager:SetEventLock(true, self)
      local duration = itemPaperBoxView:PlayUnlockShockedAnimation()
      DelayExecuteFuncInView(function()
        GM.UIManager:SetEventLock(false, self)
        self:_CollapseItemView(message)
      end, duration, self)
    else
      self:_CollapseItemView(message)
    end
  else
    self:_CollapseItemView(message)
  end
end

function MainBoardView:_CollapseItemView(message)
  if message.Source:GetComponent(ItemPaperBox) ~= nil then
    self.m_hasCollapsedPaperBox = true
  end
  local position = message.Source:GetLocalPositionOverrideZ(0)
  local itemView = self:GetItemView(message.Source)
  self:_RemoveItemView(itemView)
  if message.New ~= nil then
    self:_AddItemView(message.New)
  end
  GM.ResourceLoader:LoadPrefab(GM.DataResource.ScenePrefabConfig:GetConfig(ScenePrefabConfigName.effect_zhixiang_boom), self.transform, position, function(go)
  end)
  self:_TryToRemoveSandFills(message.Source)
end

function MainBoardView:_OnCostItem(message)
  BaseActionBoardView._OnCostItem(self, message)
  if self.m_selectedBoardPosition == message.Source:GetPosition() then
    self.m_infoBar:UpdateInfoBar()
  end
  self:_TryToRemoveSandFills(message.Source)
end

function MainBoardView:_OnTransformItem(message)
  if self.m_selectedBoardPosition == message.Source:GetPosition() then
    self:_UpdateIndicator(message.New, true)
    self.m_infoBar:UpdateInfoBar(message.New)
  end
  self:_DoTransformItem(message, 0)
end

function MainBoardView:BoostCannonDeleteItem(message)
  if self.m_selectedBoardPosition == message.Source:GetPosition() then
    self:_UpdateIndicator(message.New, true)
    self.m_infoBar:UpdateInfoBar(message.New)
  end
  local sourceItemView = self:GetItemView(message.Source)
  sourceItemView.toBeRemoved = true
  local delay = 0.3
  local sequence = DOTween.Sequence()
  sequence:Insert(delay, sourceItemView.transform:DOScale(0, 0.1))
  sequence:InsertCallback(delay + 0.1, function()
    self:_RemoveItemView(sourceItemView)
  end)
end

function MainBoardView:BoostCannonNewItem(message)
  local newItemView = self:_AddItemView(message.New)
  if newItemView ~= nil then
    newItemView.transform.localScale = Vector3.one * 1.3
    newItemView.transform:DOScale(1, 0.2)
  end
end

function MainBoardView:_OnSellItem(message)
  local itemView = self:GetItemView(message.Source)
  itemView.toBeRemoved = true
  itemView.transform:DOScale(0, 0.5):OnComplete(function()
    if self:GetItemView(message.Source) == itemView then
      self:_RemoveItemView(itemView)
    else
      itemView.transform:DOKill(false)
      itemView.gameObject:RemoveSelf()
    end
  end)
  local cost = message.Source:GetSellingPrice()
  if cost ~= 0 then
    local properties = {
      {
        [PROPERTY_TYPE] = EPropertyType.Gold,
        [PROPERTY_COUNT] = cost
      }
    }
    local worldPosition = itemView.transform.position
    local screenPosition = self:ConvertWorldPositionToScreenPosition(worldPosition)
    local uiWorldPosition = PositionUtil.UICameraScreen2World(screenPosition)
    GM.PropertyDataManager:PlayCollectAnimation(properties, uiWorldPosition)
    GM.AudioModel:PlayEffect(AudioFileConfigName.SfxMergeCollectCoins)
  end
  self:_UpdateIndicator()
end

function MainBoardView:_OnUndoSellItem(message)
  if message.Removed ~= nil then
    local removedItemView = self:GetItemView(message.Removed)
    self:_RemoveItemView(removedItemView)
  end
  local itemView = self:_AddItemView(message.Source)
  if itemView ~= nil then
    itemView.transform.localScale = V3Zero
    itemView.transform:DOScale(1, 0.5)
  end
  self.m_infoBar:UpdateInfoBar()
end

function MainBoardView:_OnPopCachedItem(message)
  BaseActionBoardView._OnPopCachedItem(self, message)
  self:_UpdateIndicator()
  self.m_infoBar:UpdateInfoBar()
end

function MainBoardView:_OnChooseItem(message)
  self:_UpdateIndicator(message.New, true)
  self.m_infoBar:UpdateInfoBar(message.New)
  local sourceItemView = self:GetItemView(message.Source)
  self:_RemoveItemView(sourceItemView)
  local newItemView = self:_AddItemView(message.New)
  if newItemView ~= nil then
    GM.AudioModel:PlayEffect(AudioFileConfigName.sfxItemLanding)
    EventDispatcher.DispatchEvent(EEventType.VibrationLight)
    newItemView:ShowRetrieveLight()
  end
end

function MainBoardView:_OnSplitItem(message)
  self:_UpdateIndicator()
  self.m_infoBar:UpdateInfoBar()
  local itemSplit = message.Split:GetComponent(ItemSplit)
  if itemSplit:HasLeftSplitUseCount() then
    message.Split:SetPosition(message.Split:GetPosition())
  else
    local splitItemView = self:GetItemView(message.Split)
    self:_RemoveItemView(splitItemView)
  end
  local targetItemView = self:GetItemView(message.Target)
  targetItemView.toBeRemoved = true
  local newItemView1 = self:_AddItemView(message.New1)
  local newItemView2 = self:_AddItemView(message.New2)
  local sequence = DOTween.Sequence()
  targetItemView:MergeLightDisappear()
  sequence:Insert(0, targetItemView.transform:DOScale(0.3, 0.1))
  sequence:InsertCallback(0.1, function()
    self:_RemoveItemView(targetItemView)
  end)
  if newItemView1 ~= nil then
    newItemView1.transform.localScale = Vector3.zero
    sequence:InsertCallback(0.1, function()
      newItemView1.transform.localScale = 0.3 * V3One
    end)
    sequence:Insert(0.1, newItemView1.transform:DOScale(1.3, 0.2))
    sequence:Insert(0.3, newItemView1.transform:DOScale(1, 0.1))
  end
  if newItemView2 ~= nil then
    self:_PlayJumpAnimation(newItemView2, targetItemView.transform.localPosition, newItemView2.transform.localPosition)
  end
  sequence:InsertCallback(0.1, function()
    newItemView1:ShowSpreadLight()
  end)
end

function MainBoardView:_OnTimeSkip(message)
  local cPos = message.Item:GetPosition()
  local item, itemView
  for position in self.m_model:GetValidPositionIterator() do
    item = self.m_model:GetItem(position)
    if item ~= nil and message.Item ~= item and self.m_model:CanItemMove(item) then
      itemView = self:GetItemView(item)
      if itemView ~= nil then
        itemView:PlayTimeSkipAnimation(self:_GetTimeSkipDelay(cPos, position))
      end
    end
  end
end

function MainBoardView:_GetTimeSkipDelay(cPos, tPos)
  return math.max(math.abs(cPos:GetX() - tPos:GetX()) - 1, math.abs(cPos:GetY() - tPos:GetY()) - 1) * 0.25
end

function MainBoardView:_OnBubbleBreak(message)
  if message.Source:GetComponent(ItemPropertyBubble) ~= nil or message.Source:GetComponent(ItemBubble):IsInstant() then
    self:_UpdateIndicator(nil, true)
    self.m_infoBar:UpdateInfoBar(nil)
  else
    self:_UpdateIndicator(message.New, true)
    self.m_infoBar:UpdateInfoBar(message.New)
  end
  GM.AudioModel:PlayEffect(AudioFileConfigName.SfxMergeBubbleOpen)
  local sourceItemView = self:GetItemView(message.Source)
  sourceItemView.toBeRemoved = true
  local spriteRenderer = sourceItemView:GetSpriteRenderer()
  local innerSpriteRenderer = sourceItemView:GetInnerSpriteRenderer()
  UIUtil.SetAlpha(innerSpriteRenderer, 0)
  sourceItemView:HideBubbleSale()
  if message.New then
    local newItemView = self:_AddItemView(message.New)
    if newItemView ~= nil then
      newItemView.transform.localScale = Vector3(0.8, 0.8, 1)
      local sequence = DOTween.Sequence()
      sequence:Append(spriteRenderer.transform:DOScale(2, 0.6))
      sequence:Insert(0, spriteRenderer:DOFade(0, 0.6))
      sequence:AppendCallback(function()
        sourceItemView:ShowBubbleBreakLight()
      end)
      sequence:AppendInterval(1)
      sequence:Insert(0.6, newItemView.transform:DOScale(1, 0.3))
      sequence:AppendCallback(function()
        self:_RemoveItemView(sourceItemView)
      end)
    end
  end
end

function MainBoardView:_OnBubbleDisappear(message)
  if self.m_selectedBoardPosition == message.Source:GetPosition() then
    self:_UpdateIndicator(message.New, true)
    self.m_infoBar:UpdateInfoBar(message.New)
  end
  GM.AudioModel:PlayEffect(AudioFileConfigName.SfxMergeBubbleBreak)
  local sourceItemView = self:GetItemView(message.Source)
  sourceItemView.toBeRemoved = true
  sourceItemView:HideBubbleSale()
  local spriteRenderer = sourceItemView:GetSpriteRenderer()
  local innerSpriteRenderer = sourceItemView:GetInnerSpriteRenderer()
  local newItemView = self:_AddItemView(message.New)
  if newItemView ~= nil then
    newItemView.transform.localScale = Vector3.zero
    newItemView:UpdateItemAffectedEffect(self.m_lastTouchedItem and self.m_lastTouchedItem:GetModel() or nil)
    local sequence = DOTween.Sequence()
    sequence:Append(innerSpriteRenderer.transform:DOScale(0, 0.2))
    sequence:Append(spriteRenderer.transform:DOScale(2, 0.8))
    sequence:Insert(0.2, spriteRenderer:DOFade(0, 0.8))
    sequence:Insert(0.2, newItemView.transform:DOScale(1, 0.2))
    sequence:AppendCallback(function()
      self:_RemoveItemView(sourceItemView)
    end)
  end
end

function MainBoardView:_OnFinishOrder(message)
  self.m_orderArea:ForceRebuildLayout()
  self.m_orderArea:SetScrollEnabled(false)
  local targetCell = self.m_orderArea:GetCell(message.Order)
  local order = targetCell:GetOrder()
  local rewards = message.Rewards or Table.DeepCopy(order:GetRewards())
  local mapDelayRewards = message.mapDelayRewards or {}
  self:TryPlayBuffAndOrderBoostReward(order, targetCell, rewards)
  self:AddContiorderExtraReward(rewards, message.Order)
  for index, itemModel in pairs(message.RemoveItemInfo.RemovedFromBoard) do
    self:_PlayRemoveOrderItemAnimation(targetCell, index, itemModel, 0.5, 2)
  end
  local worldPosition = targetCell:GetIconArea().transform.position
  local screenPosition = self:ConvertWorldPositionToScreenPosition(worldPosition)
  local uiWorldPosition = PositionUtil.UICameraScreen2World(screenPosition)
  local delayRewards = {}
  local chestCustomOrderReward = mapDelayRewards[ChestCustomerModel.RewardKey] or {}
  local otherReards = {}
  for i, v in ipairs(rewards) do
    if AlbumActivityModel.IsCacheProperty(v[PROPERTY_TYPE]) then
      delayRewards[#delayRewards + 1] = v
    else
      otherReards[#otherReards + 1] = v
    end
  end
  local sequence = DOTween.Sequence()
  sequence:AppendInterval(0.5)
  self:TryPlayCookingFrenzyAni(message, order, targetCell, sequence)
  sequence:AppendCallback(function()
    targetCell:PlayCoinEffect()
    local positionArray = Table.ListRep(uiWorldPosition, #otherReards)
    local viewData = {
      arrWorldPos = positionArray,
      noDelayTime = true,
      orderCell = targetCell
    }
    RewardApi.AcquireRewardsInView(otherReards, viewData)
  end)
  local giftRewards = order:GetGiftRewards()
  if giftRewards ~= nil and GM.CharacterIntimacyModel:IsOpen() then
    Table.ListAppend(delayRewards, giftRewards)
    sequence:AppendCallback(function()
      local sceneView = GM.UIManager:GetOpenedTopViewByType(EViewType.SceneView)
      local entry = sceneView:GetHudButton(ESceneViewHudButtonKey.CharacterIntimacy)
      entry:ShowOnBoard()
    end)
  end
  if not Table.IsEmpty(delayRewards) then
    sequence:AppendInterval(0.3)
    sequence:AppendCallback(function()
      local delayRewardPositionArray = Table.ListRep(uiWorldPosition, #delayRewards)
      local vd = {
        arrWorldPos = delayRewardPositionArray,
        noDelayTime = true,
        orderCell = targetCell
      }
      RewardApi.AcquireRewardsInView(delayRewards, vd)
    end)
  end
  sequence:AppendInterval(0.5)
  self:TryPlayChestCustomBoxRewards(order, targetCell, sequence, chestCustomOrderReward, uiWorldPosition)
  local leaveAnimationTime = targetCell.GetLeaveAnimationTime and targetCell:GetLeaveAnimationTime() or nil
  sequence:AppendCallback(function()
    targetCell:PlayLeaveAnimation()
  end)
  sequence:AppendInterval(leaveAnimationTime or 1)
  sequence:AppendCallback(function()
    self.m_orderArea:RemoveCell(message.Order)
    self.m_orderArea:SetScrollEnabled(true)
    EventDispatcher.DispatchEvent(EEventType.ButterflyDelayScroll)
    self:_StartPrompt()
  end)
  local targetCell = self.m_orderArea:GetCell(message.Order)
  for index, itemType in pairs(message.RemoveItemInfo.RemovedFromInventory) do
    self:_PlayInventory2OrderItemAnimation(targetCell, index, itemType, V3One, 0.5, 2)
  end
end

function MainBoardView:TryPlayBuffAndOrderBoostReward(order, targetCell, rewards)
  if order.GetBuffRewards then
    local buffRewards = order:GetBuffRewards()
    if buffRewards then
      Table.ListAppend(rewards, buffRewards)
      local orderBoostModel = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
      if orderBoostModel:GetAddOrderBoostScoreByOrder(order) then
        targetCell:PlayHideOrderBoostReward()
      end
    end
  end
end

function MainBoardView:AddContiorderExtraReward(rewards, order)
  if order:GetInnerType() == MainOrderType.Contiorder then
    local model = GM.ActivityManager:GetStartedContiorders()
    if model:GetState() == ActivityState.Started or model:GetState() == ActivityState.Ended then
      local extraReward = model:GetExtraReward()
      table.insert(rewards, extraReward)
    end
  end
end

function MainBoardView:TryPlayChestCustomBoxRewards(order, targetCell, sequence, chestCustomOrderReward, uiWorldPosition)
  if Table.IsEmpty(chestCustomOrderReward) then
    return
  end
  local chestCustomModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  local rewards = {}
  for _, chestRewardCfg in ipairs(chestCustomOrderReward) do
    local reward = chestCustomModel:GetRewardsBySlot(order:GetInnerType(), order:GetSlot())
    Table.ListAppend(rewards, reward)
  end
  local fInterVal = 0.2
  local delyTraySeq = DOTween.Sequence()
  delyTraySeq:AppendInterval(2)
  delyTraySeq:AppendCallback(function()
    targetCell:HideTrayTrans()
  end)
  local waitCharacterTime = 0.4
  local waitFlyTime = 0.3
  sequence:AppendCallback(function()
  end)
  sequence:AppendInterval(waitCharacterTime)
  sequence:AppendCallback(function()
    targetCell:PlayRewardAnimation()
  end)
  sequence:AppendInterval(waitFlyTime)
  local waitTime = sequence:Duration()
  targetCell:SetPlayFinishRewardAnimation(true)
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ShowItemrewardDisplayWindow) then
    GM.UIManager:SetEventLock(true, self)
  end
  for index, reward in ipairs(rewards) do
    local curIndex = index
    if reward.pos ~= nil then
      local itemModel = self.m_model:GetItem(reward.pos)
      local item = self:_AddItemView(itemModel)
      item.transform.localPosition = itemModel:GetLocalPosition()
      local endItemPos = itemModel:GetPosition()
      UIUtil.SetActive(item.gameObject, false)
      GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ChestCustomFlyItem), GM.UIManager:GetCanvasRoot(), Vector3.zero, function(flyitem)
        flyitem:GetLuaTable():Init(reward[PROPERTY_TYPE])
        UIUtil.SetActive(flyitem.gameObject, false)
        flyitem.transform.localScale = Vector3(0.8, 0.8, 1)
        local itemSequnce = DOTween.Sequence()
        itemSequnce:AppendInterval((curIndex - 1) * fInterVal + waitTime)
        itemSequnce:AppendCallback(function()
          if targetCell == nil or targetCell.gameObject:IsNull() then
            if not item.gameObject:IsNull() and item:GetModel() ~= nil then
              UIUtil.SetActive(item.gameObject, true)
            end
            return
          end
          local startPos = self:ConvertWorldPositionToScreenPosition(targetCell:GetRewardStartTrans().position)
          local startUIPos = PositionUtil.UICameraScreen2World(startPos)
          flyitem.transform.position = startUIPos
          local endScreenPos = self:ConvertBoardPositionToScreenPosition(endItemPos)
          local endPos = PositionUtil.UICameraScreen2World(endScreenPos)
          local controlPoint1 = Vector3(startUIPos.x, startUIPos.y + 200, startUIPos.z)
          local controlPoint2 = Vector3(endPos.x, startUIPos.y + 150, endPos.z)
          local wayPoints = {
            endPos,
            controlPoint1,
            controlPoint2
          }
          
          local function addEffectFunc(effectLoader)
            local effect = Object.Instantiate(effectLoader.m_boxEmmisionEffect, GM.UIManager:GetCanvasRoot())
            UIUtil.UpdateSortingOrder(effect, 2)
            effect.transform.position = startUIPos + Vector3(0, -30, 0)
            local delSeq = DOTween.Sequence()
            delSeq:AppendInterval(2)
            delSeq:AppendCallback(function()
              Object.Destroy(effect)
            end)
            GM.AudioModel:PlayEffect(AudioFileConfigName.SfxCoinRaceCoinGrow)
            EventDispatcher.DispatchEvent(EEventType.VibrationLight)
          end
          
          if GM.SceneManager:GetGameMode() == EGameMode.Main then
            chestCustomModel:LoadOrderLoaderPrefab(addEffectFunc)
          end
          UIUtil.SetActive(flyitem.gameObject, true)
          local newSeq = DOTween.Sequence()
          local scaleSeq = DOTween.Sequence()
          scaleSeq:Append(flyitem.transform:DOScale(Vector3(1.4, 1.4, 1.4), 0.2))
          scaleSeq:AppendInterval(0.2)
          scaleSeq:Append(flyitem.transform:DOScale(Vector3(1, 1, 1), 0.1))
          newSeq:Append(flyitem.transform:DOPath(wayPoints, 0.5, PathType.CubicBezier):SetEase(Ease.OutQuad))
          newSeq:Join(scaleSeq)
          newSeq:AppendCallback(function()
            local function flyFinishFunc(effectLoader)
              local effect = Object.Instantiate(effectLoader.m_rewardFlyFinishEffect, GM.UIManager:GetCanvasRoot())
              
              UIUtil.UpdateSortingOrder(effect, 2)
              effect.transform.position = endPos
              local delSeq = DOTween.Sequence()
              delSeq:AppendInterval(2)
              delSeq:AppendCallback(function()
                Object.Destroy(effect)
              end)
            end
            
            if GM.SceneManager:GetGameMode() == EGameMode.Main then
              chestCustomModel:LoadOrderLoaderPrefab(flyFinishFunc)
            end
            AddressableLoader.Destroy(flyitem)
            if not item.gameObject:IsNull() and item:GetModel() ~= nil then
              UIUtil.SetActive(item.gameObject, true)
            end
          end)
        end)
      end)
    else
      GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ChestCustomFlyCacheItem), GM.UIManager:GetCanvasRoot(), Vector3.zero, function(flyitem)
        flyitem:GetLuaTable():Init(reward[PROPERTY_TYPE])
        UIUtil.SetActive(flyitem.gameObject, false)
        local cacheRoot = self:GetOrderArea():GetCacheRoot()
        local curWaitTime = waitTime + (curIndex - 1) * fInterVal
        local showSeq = DOTween.Sequence()
        showSeq:AppendInterval(curWaitTime)
        showSeq:AppendCallback(function()
          local startPos = self:ConvertWorldPositionToScreenPosition(targetCell:GetRewardStartTrans().position)
          local startUIPos = PositionUtil.UICameraScreen2World(startPos)
          local endScreenPos = self:ConvertWorldPositionToScreenPosition(cacheRoot.transform.position)
          local endPos = PositionUtil.UICameraScreen2World(endScreenPos)
          local sourcePositionZero = Vector3(startUIPos.x, startUIPos.y, 0)
          local targetPositionZero = Vector3(endPos.x, endPos.y, 0)
          local deltaPosition = targetPositionZero - sourcePositionZero
          
          local function addEffectFunc(effectLoader)
            local effect = Object.Instantiate(effectLoader.m_boxEmmisionEffect, GM.UIManager:GetCanvasRoot())
            UIUtil.UpdateSortingOrder(effect, 2)
            effect.transform.position = startUIPos + Vector3(0, -30, 0)
            local delSeq = DOTween.Sequence()
            delSeq:AppendInterval(2)
            delSeq:AppendCallback(function()
              Object.Destroy(effect)
            end)
            GM.AudioModel:PlayEffect(AudioFileConfigName.SfxCoinRaceCoinGrow)
            EventDispatcher.DispatchEvent(EEventType.VibrationLight)
          end
          
          if GM.SceneManager:GetGameMode() == EGameMode.Main then
            chestCustomModel:LoadOrderLoaderPrefab(addEffectFunc)
          end
          UIUtil.SetActive(flyitem.gameObject, true)
          local transform = flyitem.gameObject.transform
          transform.localPosition = sourcePositionZero
          transform.localScale = Vector3.zero
          local sequence = DOTween.Sequence()
          sequence:Insert(0.05, transform:DOLocalJump(sourcePositionZero + deltaPosition * 0.9, 60, 1, 0.6))
          sequence:Insert(0.65, transform:DOLocalMove(endPos, 0.25):SetEase(Ease.OutQuad))
          sequence:Insert(0.05, transform:DOScale(Vector3(0.8, 0.8, 1), 0.1))
          sequence:Insert(0.15, transform:DOScale(Vector3(1.5, 1.5, 1), 0.2))
          sequence:Insert(0.35, transform:DOScale(Vector3(1, 1, 1), 0.3))
          sequence:Insert(0.65, transform:DOScale(V3One, 0.2))
          sequence:AppendCallback(function()
            AddressableLoader.Destroy(flyitem.gameObject)
          end)
        end)
      end)
    end
  end
  sequence:AppendInterval((#rewards - 1) * fInterVal + 0.2)
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ShowItemrewardDisplayWindow) then
    sequence:AppendCallback(function()
      GM.UIManager:SetEventLock(false, self)
      local allItems = {}
      for _, reward in ipairs(rewards) do
        allItems[#allItems + 1] = reward[PROPERTY_TYPE]
      end
      GM.UIManager:OpenView(UIPrefabConfigName.ItemRewardDisplayWindow, allItems)
    end)
  end
end

function MainBoardView:TryPlayCookingFrenzyAni(message, order, targetCell, seq)
  if order.GetCookingFrenzyConfig ~= nil then
    local model = GM.ActivityManager:GetModel(ActivityType.CookingFrenzy)
    local rewards = model:PopShowRewardByCfg(message.Order)
    if rewards ~= nil then
      self:ClearSelectedInfo()
      local itemRewards = {}
      local itemCacheRewards = {}
      local otherRewards = {}
      for _, reward in ipairs(rewards) do
        if reward.itemPos ~= nil then
          table.insert(itemRewards, reward)
        elseif reward.isCookingFrenzyItem ~= nil then
          table.insert(itemCacheRewards, reward)
        else
          table.insert(otherRewards, reward)
        end
      end
      local CookingFrenzyOrderReward = targetCell:GetCookingFrenzy()
      local trans
      if CookingFrenzyOrderReward ~= nil and not CookingFrenzyOrderReward.gameObject:IsNull() then
        trans = CookingFrenzyOrderReward.transform
        CookingFrenzyOrderReward:PlayRwardAni()
      end
      trans = trans and trans or targetCell.transform
      local startPos = self:ConvertWorldPositionToScreenPosition(trans.position)
      local startUIPos = PositionUtil.UICameraScreen2World(startPos)
      local arrWorladPos = {}
      for i = 1, #rewards do
        table.insert(arrWorladPos, startUIPos)
      end
      for _, itemReward in ipairs(itemRewards) do
        local itemModel = self.m_model:GetItem(itemReward.itemPos)
        local item = self:_AddItemView(itemModel)
        item.transform.localPosition = itemModel:GetLocalPosition()
        UIUtil.SetActive(item.gameObject, false)
        local strAnimation = "2"
        if CookingFrenzyOrderReward ~= nil then
          strAnimation = CookingFrenzyOrderReward:GetAnimationStr()
        end
        GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.CookingFrenzyBoardFlyItemReward), GM.UIManager:GetCanvasRoot(), startPos, function(flyitem)
          flyitem:GetLuaTable():Init(strAnimation)
          flyitem.transform.position = startUIPos
          local endScreenPos = self:ConvertBoardPositionToScreenPosition(itemModel:GetPosition())
          local endPos = PositionUtil.UICameraScreen2World(endScreenPos) + Vector3(0, -50, 0)
          local sourcePositionZero = Vector3(startUIPos.x, startUIPos.y, 0)
          local targetPositionZero = Vector3(endPos.x, endPos.y, 0)
          local deltaPosition = targetPositionZero - sourcePositionZero
          local transform = flyitem.gameObject.transform
          transform.localPosition = sourcePositionZero
          transform.localScale = Vector3(0.6, 0.6, 0.6)
          UIUtil.SetActive(flyitem.gameObject, false)
          local sequence = DOTween.Sequence()
          local scaleSeq = DOTween.Sequence()
          scaleSeq:Append(transform:DOScale(Vector3(0.8, 0.8, 1), 0.06999999999999999))
          scaleSeq:Append(transform:DOScale(Vector3(1.5, 1.5, 1), 0.13999999999999999))
          scaleSeq:Append(transform:DOScale(Vector3(1, 1, 1), 0.21))
          local delayTime = 0.3
          sequence:AppendInterval(0.3)
          sequence:AppendCallback(function()
            UIUtil.SetActive(flyitem.gameObject, true)
            GM.AudioModel:PlayEffect(AudioFileConfigName.sfxCookingFrenzyFire)
          end)
          sequence:Append(transform:DOLocalJump(sourcePositionZero + deltaPosition * 0.9, 60, 1, 0.42))
          sequence:Join(scaleSeq)
          sequence:Append(transform:DOLocalMove(endPos, 0.175):SetEase(Ease.OutQuad))
          sequence:Join(transform:DOScale(V3One, 0.13999999999999999))
          local duration = sequence:Duration()
          local boomAct = DOTween.Sequence()
          boomAct:AppendInterval(duration - 0.2)
          boomAct:AppendCallback(function()
            local screenpos = self:ConvertBoardPositionToScreenPosition(itemModel:GetPosition())
            local pos = PositionUtil.UICameraScreen2World(screenpos)
            GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.effect_cookiefrenzy_glow_2), GM.UIManager:GetCanvasRoot(), Vector3(pos.x, pos.y, 0), function(go)
              UIUtil.UpdateSortingOrder(go, 101)
              DelayExecuteFuncInView(function()
                AddressableLoader.Destroy(go)
              end, 1, self)
            end)
          end)
          sequence:AppendCallback(function()
            flyitem:GetLuaTable():SetOpen()
            local seqHint = DOTween.Sequence()
            seqHint:AppendInterval(0.3)
            seqHint:AppendCallback(function()
              local screenpos = self:ConvertBoardPositionToScreenPosition(itemModel:GetPosition())
              local pos = PositionUtil.UICameraScreen2World(screenpos)
              local itemCodeConfigMap = self.m_model:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
              local score = 0
              score = itemCodeConfigMap[itemModel:GetCode()] ~= nil and itemCodeConfigMap[itemModel:GetCode()].DiffScore or score
              if 31 <= score then
                GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.CookingFrenzyFlyTip), GM.UIManager:GetCanvasRoot(), Vector3(pos.x, pos.y, 10), function(go)
                  local str = GM.GameTextModel:GetText("frenzy_item_hot_1")
                  if 126 <= score then
                    str = GM.GameTextModel:GetText("frenzy_item_hot_3")
                  elseif 61 <= score then
                    str = GM.GameTextModel:GetText("frenzy_item_hot_2")
                  end
                  go:GetLuaTable():Init(str)
                  go.transform:DOAnchorPosY(go.transform.anchoredPosition.y + 50, 0.5)
                  local seq = DOTween.Sequence()
                  seq:AppendInterval(1.5)
                  seq:AppendCallback(function()
                    AddressableLoader.Destroy(go)
                  end)
                end)
              end
            end)
          end)
          sequence:AppendInterval(0.3)
          sequence:AppendCallback(function()
            GM.AudioModel:PlayEffect(AudioFileConfigName.SfxOpenBox)
            local screenpos = self:ConvertBoardPositionToScreenPosition(itemModel:GetPosition())
            local pos = PositionUtil.UICameraScreen2World(screenpos)
            GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.effect_cookiefrenzy_glow_3), GM.UIManager:GetCanvasRoot(), Vector3(pos.x, pos.y, 0), function(go)
              UIUtil.UpdateSortingOrder(go, 101)
              DelayExecuteFuncInView(function()
                AddressableLoader.Destroy(go)
              end, 1, self)
            end)
          end)
          sequence:AppendInterval(0.4)
          sequence:AppendCallback(function()
            if item:GetModel() ~= nil then
              UIUtil.SetActive(item.gameObject, true)
            end
            UIUtil.SetActive(flyitem.gameObject, false)
          end)
          sequence:AppendInterval(0.5)
          sequence:AppendCallback(function()
            AddressableLoader.Destroy(flyitem.gameObject)
          end)
        end)
      end
      for _, otherReward in ipairs(itemCacheRewards) do
        GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.CookingFrenzyFlyCacheRoot), GM.UIManager:GetCanvasRoot(), startPos, function(flyitem)
          flyitem:GetLuaTable():Init(otherReward[PROPERTY_TYPE])
          local cacheRoot = self:GetOrderArea():GetCacheRoot()
          local endScreenPos = self:ConvertWorldPositionToScreenPosition(cacheRoot.transform.position)
          local endPos = PositionUtil.UICameraScreen2World(endScreenPos)
          local sourcePositionZero = Vector3(startPos.x, startPos.y, 0)
          local targetPositionZero = Vector3(endPos.x, endPos.y, 0)
          local deltaPosition = targetPositionZero - sourcePositionZero
          local transform = flyitem.gameObject.transform
          transform.localPosition = sourcePositionZero
          transform.localScale = Vector3.zero
          local sequence = DOTween.Sequence()
          sequence:Insert(0.05, transform:DOLocalJump(sourcePositionZero + deltaPosition * 0.9, 60, 1, 0.6))
          sequence:Insert(0.65, transform:DOLocalMove(endPos, 0.25):SetEase(Ease.OutQuad))
          sequence:Insert(0.05, transform:DOScale(Vector3(0.8, 0.8, 1), 0.1))
          sequence:Insert(0.15, transform:DOScale(Vector3(1.5, 1.5, 1), 0.2))
          sequence:Insert(0.35, transform:DOScale(Vector3(1, 1, 1), 0.3))
          sequence:Insert(0.65, transform:DOScale(V3One, 0.2))
          sequence:AppendCallback(function()
            flyitem:GetLuaTable():PlayEffect()
            AddressableLoader.Destroy(flyitem.gameObject)
          end)
        end)
      end
      RewardApi.AcquireRewardsInView(otherRewards, {
        arrWorldPos = arrWorladPos,
        noDelayTime = true,
        spriteScale = 0.8
      })
    end
  end
end

function MainBoardView:_PlayItemSpreadPrompt(itemView, spreadEffectType)
  local promptConfig
  if spreadEffectType == BoardSpreadType.Lucky or spreadEffectType == BoardSpreadType.FreeLucky then
    promptConfig = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemSpreadPromptLuckyNormal)
  elseif spreadEffectType == BoardSpreadType.SuperLucky or spreadEffectType == BoardSpreadType.FreeSuperLucky then
    promptConfig = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemSpreadPromptLuckySuper)
  elseif spreadEffectType == BoardSpreadType.TripleLucky1 or spreadEffectType == BoardSpreadType.DoubleLucky then
    promptConfig = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemSpreadPromptLuckyConti1)
  elseif spreadEffectType == BoardSpreadType.TripleLucky2 then
    promptConfig = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemSpreadPromptLuckyConti2)
  elseif spreadEffectType == BoardSpreadType.GeneratorBoostExtraLucky or spreadEffectType == BoardSpreadType.GeneratorBoostExtra then
    promptConfig = GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.ItemSpreadPromptNormalText)
  end
  if promptConfig == nil then
    return
  end
  local position = self.m_canvas.transform:InverseTransformPoint(self:GetItemsTransform():TransformPoint(itemView:GetModel():GetLocalPosition()))
  position.z = 0
  if spreadEffectType == BoardSpreadType.GeneratorBoostExtraLucky then
    DelayExecuteFuncInView(function()
      GM.ResourceLoader:LoadPrefab(promptConfig, self.m_canvas.transform, position, function(go)
        local prompt = go:GetLuaTable()
        prompt:Init({
          textKey = "generatorBoost_extraLuckyProduce_hint",
          textColor = "FF1DC2"
        })
      end)
    end, 0.3, self)
  elseif spreadEffectType == BoardSpreadType.GeneratorBoostExtra then
    GM.ResourceLoader:LoadPrefab(promptConfig, self.m_canvas.transform, position, function(go)
      local prompt = go:GetLuaTable()
      prompt:Init({
        textKey = "generatorBoost_extraProduce_hint",
        textColor = "FF1DC2"
      })
    end)
  else
    GM.ResourceLoader:LoadPrefab(promptConfig, self.m_canvas.transform, position, Function.Void)
  end
end

function MainBoardView:_OnLackGem(message)
  UIHelper.OnLackGem(message.LackNumber, message.Scene)
end

function MainBoardView:_OnLackEnergy(msg)
  GM.EnergyModel:OnLackEnergy(EnergyType.Main)
end

function MainBoardView:_OnSpreadFailed(message)
  local key
  if message.Reason == SpreadFailedReason.ItemClosed then
    key = "hint_item_locked"
  elseif message.Reason == SpreadFailedReason.ItemOpening then
    key = "hint_item_opening"
  elseif message.Reason == SpreadFailedReason.ItemRecharging then
    key = "hint_item_recharging"
    GM.AudioModel:PlayEffect(AudioFileConfigName.SfxColdingClick)
    local itemSpread = message.Item:GetComponent(ItemSpread)
    if itemSpread ~= nil then
      local restDuration = itemSpread:GetTimerDuration() + itemSpread:GetStartTimer() - GM.GameModel:GetServerTime()
      if 1200 <= restDuration then
        UIHelper.TryOpenWXSubscriptionWindow(SubscriptionType.CDRecover, true)
      end
    end
  else
    key = "hint_board_full"
  end
  local itemView = self:GetItemView(message.Item)
  local targetPosition = (itemView and itemView.transform.position or V3Zero) + Vector3(0, 100, 0)
  local screenPosition = self:ConvertWorldPositionToScreenPosition(targetPosition)
  GM.UIManager:ShowPromptWithKey(key, screenPosition)
  if message.Reason == SpreadFailedReason.ItemRecharging or message.Reason == SpreadFailedReason.ItemOpening then
    self.m_infoBar:GetInfoContent():PlaySkipButtonEffect()
  elseif message.Reason == SpreadFailedReason.ItemClosed and not self.m_model:HasOpeningItem() then
    self.m_infoBar:GetInfoContent():PlayOpenButtonEffect()
  end
end

function MainBoardView:_OnUpdateOpeningItem()
  local hasOpeningItem = self.m_model:HasOpeningItem()
  for itemModel, _ in pairs(self.m_model:GetAllBoardItems()) do
    local itemSpread = itemModel:GetComponent(ItemSpread)
    if itemSpread ~= nil then
      local itemView = self:GetItemView(itemModel)
      if itemView ~= nil then
        if itemSpread:GetState() == ItemSpreadState.Closed then
          itemView:UpdateExclamation(not hasOpeningItem)
        else
          itemView:UpdateExclamation(false)
        end
      end
    end
  end
end

function MainBoardView:_RecordLastTapGenerator(itemModel)
  local itemSpread = itemModel:GetComponent(ItemSpread)
  if itemSpread ~= nil and itemSpread:GetState() == ItemSpreadState.Opened then
    if not itemSpread:IsDisposable() then
      self.LastTapNonDisposableGeneratorChainId = GM.ItemDataModel:GetChainId(itemModel:GetType())
    else
      self.LastTapDisposableGeneratorItemModel = itemModel
    end
  end
end

function MainBoardView:OnAddSmileItem(itemModel, startPos, effect, bPro)
  local needIgnore
  local position = itemModel:GetPosition()
  local currentItem = self.m_model:GetItem(position)
  if currentItem ~= itemModel then
    needIgnore = true
  end
  local newItem = self:_AddItemView(itemModel, needIgnore)
  local newTrai
  if effect ~= nil then
    newTrai = Object.Instantiate(effect, newItem.transform)
    newTrai.transform.localPosition = Vector3(0, 0, -1)
    UIUtil.SetActive(newTrai, true)
  end
  local startLocalPos = self:GetItemsTransform():InverseTransformPoint(startPos)
  local seq = self:_PlayJumpAnimation(newItem, startLocalPos, itemModel:GetLocalPosition(), nil, bPro and BoardSpreadType.OrderBoostPro or nil)
  seq:AppendCallback(function()
    if newTrai ~= nil then
      Object.Destroy(newTrai)
    end
  end)
  return seq, newItem
end

function MainBoardView:AddItemViewByActivity(ItemModel)
  return self:_AddItemView(ItemModel)
end

function MainBoardView:OnAddPlaneItem(itemModel, startPos, sortingOrder)
  local itemView
  if itemModel ~= nil then
    itemView = self:_AddItemView(itemModel)
    itemView.transform.localPosition = itemModel:GetLocalPosition()
    UIUtil.SetActive(itemView.gameObject, false)
  end
  local targetUIWorldPos
  if itemModel ~= nil then
    local endScreenPos = self:ConvertBoardPositionToScreenPosition(itemModel:GetPosition())
    targetUIWorldPos = PositionUtil.UICameraScreen2World(endScreenPos)
  else
    local cacheRoot = self:GetOrderArea():GetCacheRoot()
    local endScreenPos = self:ConvertWorldPositionToScreenPosition(cacheRoot.transform.position)
    targetUIWorldPos = PositionUtil.UICameraScreen2World(endScreenPos)
  end
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.PlaneRewardFlyItem), GM.UIManager:GetCanvasRoot(), startPos, function(flyitem)
    local planeRewardFlyItem = flyitem:GetLuaTable()
    planeRewardFlyItem:UpdateSortingOrder(sortingOrder)
    planeRewardFlyItem:PlayFlyItem(targetUIWorldPos, function()
      if itemView ~= nil and self.m_model:GetItem(itemModel:GetPosition()) == itemModel then
        UIUtil.SetActive(itemView.gameObject, true)
      end
    end)
  end)
end

function MainBoardView:OnAddRaccoonItem(itemModel, startPos, sortingOrder)
  local itemView
  if itemModel ~= nil then
    itemView = self:_AddItemView(itemModel)
    itemView.transform.localPosition = itemModel:GetLocalPosition()
    UIUtil.SetActive(itemView.gameObject, false)
  end
  local targetUIWorldPos
  if itemModel ~= nil then
    local endScreenPos = self:ConvertBoardPositionToScreenPosition(itemModel:GetPosition())
    targetUIWorldPos = PositionUtil.UICameraScreen2World(endScreenPos)
  else
    local cacheRoot = self:GetOrderArea():GetCacheRoot()
    local endScreenPos = self:ConvertWorldPositionToScreenPosition(cacheRoot.transform.position)
    targetUIWorldPos = PositionUtil.UICameraScreen2World(endScreenPos)
  end
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.RaccoonRewardFlyItem), GM.UIManager:GetCanvasRoot(), startPos, function(flyitem)
    local raccoonRewardFlyItem = flyitem:GetLuaTable()
    raccoonRewardFlyItem:UpdateSortingOrder(sortingOrder)
    raccoonRewardFlyItem:PlayFlyItem(targetUIWorldPos, function()
      if itemView ~= nil and self.m_model:GetItem(itemModel:GetPosition()) == itemModel then
        UIUtil.SetActive(itemView.gameObject, true)
      end
    end)
  end)
end

function MainBoardView:InitActivityUIRefreshed()
  local handler = GM.BoostChargeManager:GetHandler(EBoostChargeType.BoostCharge_disco)
  local discoConfig = {
    listeners = {
      EEventType.TriggerBoostDiscoActStarted,
      EEventType.TriggerBoostDiscoFinished
    },
    bubbleName = "m_TriggerBoostDiscoLuaTable",
    GetBubbleFuncName = "GetTriggerBoostDiscoLuaTable",
    prefabName = UIPrefabConfigName.TriggerBoostDiscoProgress,
    showFunc = function()
      return handler:CanShowBoardProgress()
    end,
    deleteFunc = "PlayHideAnimation"
  }
  self:ResgisterUIRefresh(discoConfig)
end

function MainBoardView:ResgisterUIRefresh(config)
  local function func()
    if config.showFunc() then
      if self[config.bubbleName] == nil then
        GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(config.prefabName), self.m_activityExtraRectTrans, Vector3(0, 0, 0), function(go)
          if self[config.bubbleName] ~= nil then
            AddressableLoader.Destroy(go)
            
            return
          end
          self[config.bubbleName] = go:GetLuaTable()
          self[config.bubbleName]:Init()
          if config.showAniFunc ~= nil then
            self[config.bubbleName][config.showAniFunc](self[config.bubbleName])
          end
        end)
      else
        self[config.bubbleName]:UpdateContent()
        if config.showAniFunc ~= nil then
          self[config.bubbleName][config.showAniFunc](self[config.bubbleName])
        end
      end
    elseif self[config.bubbleName] ~= nil then
      if config.deleteFunc ~= nil then
        self[config.bubbleName][config.deleteFunc](self[config.bubbleName])
        self[config.bubbleName] = nil
      else
        AddressableLoader.Destroy(self[config.bubbleName].gameObject)
        self[config.bubbleName] = nil
      end
    end
  end
  
  if config.GetBubbleFuncName ~= nil then
    self[config.GetBubbleFuncName] = function(self)
      return self[config.bubbleName]
    end
  end
  for _, listener in ipairs(config.listeners) do
    EventDispatcher.AddListener(listener, self, func)
  end
  func()
end
