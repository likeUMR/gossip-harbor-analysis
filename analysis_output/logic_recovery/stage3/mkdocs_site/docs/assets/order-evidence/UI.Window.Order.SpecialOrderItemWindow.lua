SpecialOrderItemWindow = setmetatable({
  canClickWindowMask = true,
  needBlurEffect = false,
  canCloseByAndroidBack = false
}, BaseWindow)
SpecialOrderItemWindow.__index = SpecialOrderItemWindow

function SpecialOrderItemWindow:Init(order)
  self.m_order = order
  local sequence = DOTween.Sequence()
  sequence:InsertCallback(1, function()
    self.m_initialized = true
    UIUtil.UpdateSortingOrder(self.m_effectGo, self:GetSortingOrder())
    self.m_effectGo:SetActive(true)
  end)
  local requirements = order:GetRequirements()
  local itemImage, targetItemView
  local itemCount = 0
  for i = 1, 3 do
    itemImage = self["m_itemGo" .. i]
    UIUtil.SetActive(itemImage.gameObject, requirements[i] ~= nil)
    itemCount = itemCount + (requirements[i] ~= nil and 1 or 0)
  end
  LayoutRebuilder.ForceRebuildLayoutImmediate(self.m_layoutRectTrans)
  local boardView = MainBoardView.GetInstance()
  local mapSelectedItem = {}
  self.m_inventoryItemMap = {}
  for i = 1, 3 do
    if requirements[i] ~= nil then
      local function filter(itemModel)
        return itemModel:GetType() == requirements[i] and mapSelectedItem[itemModel] == nil
      end
      
      local targetItem = GM.MainBoardModel:FilterItems(filter)[1]
      if targetItem ~= nil then
        mapSelectedItem[targetItem] = true
        boardView:UpdateCompleteTileDisplay(targetItem:GetPosition(), false, true)
        itemImage = self["m_itemImage" .. i]
        local targetItemView = boardView:GetItemView(targetItem)
        self["m_targetItemView" .. i] = targetItemView
        targetItemView.gameObject:SetActive(false)
        itemImage.sprite = targetItemView:GetSpriteRenderer().sprite
        SpriteUtil.SetNativeSize(itemImage)
        local imageTransform = itemImage.transform
        local screenPosition = boardView:ConvertWorldPositionToScreenPosition(targetItemView.transform.position)
        local uiWorldPosition = PositionUtil.UICameraScreen2World(screenPosition)
        imageTransform.position = Vector3(uiWorldPosition.x, uiWorldPosition.y, imageTransform.position.z)
        sequence:Insert(0, imageTransform:DOAnchorPos(Vector2.zero, 1))
        sequence:Insert(0, imageTransform:DOScale(1 < itemCount and 2 or 3, 1))
        sequence:InsertCallback(1, function()
          local shakeSequence = DOTween.Sequence()
          shakeSequence:Append(imageTransform:DOAnchorPos(Vector2(0, -10), 1))
          shakeSequence:Append(imageTransform:DOAnchorPos(Vector2(0, 10), 2))
          shakeSequence:Append(imageTransform:DOAnchorPos(Vector2.zero, 1))
          shakeSequence:SetLoops(-1)
        end)
      else
        self.m_inventoryItemMap[i] = requirements[i]
        local img = self["m_itemImage" .. i]
        img.enabled = false
        SpriteUtil.SetImage(img, GM.ItemDataModel:GetSpriteName(requirements[i]), true, function()
          if not img:IsNull() then
            img.enabled = true
          end
        end)
        local sceneView = GM.UIManager:GetOpenedTopViewByType(EViewType.SceneView)
        local sourceWorldPos = sceneView:GetHudButton(ESceneViewHudButtonKey.Inventory).transform.position
        local imageTransform = img.transform
        UIUtil.SetPosition(imageTransform, sourceWorldPos.x, sourceWorldPos.y)
        sequence:Insert(0, imageTransform:DOAnchorPos(Vector2.zero, 1))
        sequence:Insert(0, imageTransform:DOScale(1 < itemCount and 2 or 3, 1))
        sequence:InsertCallback(1, function()
          local shakeSequence = DOTween.Sequence()
          shakeSequence:Append(imageTransform:DOAnchorPos(Vector2(0, -10), 1))
          shakeSequence:Append(imageTransform:DOAnchorPos(Vector2(0, 10), 2))
          shakeSequence:Append(imageTransform:DOAnchorPos(Vector2.zero, 1))
          shakeSequence:SetLoops(-1)
        end)
      end
    end
  end
end

function SpecialOrderItemWindow:OnWindowMaskClicked()
  if not self.m_initialized then
    return
  end
  local targetItemView, itemImage
  for i = 1, 3 do
    targetItemView = self["m_targetItemView" .. i]
    if targetItemView ~= nil and not targetItemView.gameObject:IsNull() then
      itemImage = self["m_itemImage" .. i]
      targetItemView.gameObject:SetActive(true)
      local itemViewTransform = targetItemView.transform
      itemViewTransform.localScale = itemImage.transform.localScale
      local screenPosition = PositionUtil.UICameraWorld2Screen(itemImage.transform.position)
      itemViewTransform.position = MainBoardView.GetInstance():ConvertScreenPositionToWorldPosition(screenPosition)
    end
  end
  GM.MainBoardModel:FinishOrder(self.m_order)
  local boardView = MainBoardView.GetInstance()
  local orderCell = boardView:GetOrderArea():GetCell(self.m_order)
  if orderCell ~= nil then
    for i, type in pairs(self.m_inventoryItemMap) do
      boardView:PlayItemFly2OrderItemAnimation(orderCell, 1, type, self["m_itemImage" .. i].transform.position, self["m_itemImage" .. i].transform.localScale)
    end
  end
  self:Close()
end
