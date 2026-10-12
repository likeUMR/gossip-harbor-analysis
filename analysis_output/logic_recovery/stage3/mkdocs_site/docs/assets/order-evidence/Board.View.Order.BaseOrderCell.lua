BaseOrderCell = setmetatable({}, AvatarCell)
BaseOrderCell.__index = BaseOrderCell

function BaseOrderCell:GetDisplayRewards()
  return Table.ShallowCopy(self.m_order:GetRewards())
end

function BaseOrderCell:GetDisplayTray()
  return ImageFileConfigName.order_tray
end

function BaseOrderCell:GetTestInfoStr()
end

function BaseOrderCell:GetDeliverAudioEffectName()
  return AudioFileConfigName.sfxOrderCompleteNew
end

function BaseOrderCell:OnRewardCellInitFinish(cell, reward)
end

function BaseOrderCell:OnGoButtonClicked()
  if self.m_bGoButtonEnabled == false then
    return
  end
  GM.AudioModel:PlayEffect("sfxOrderServe")
  local boardModel = self.m_orderArea:GetBoardView():GetModel()
  if self.m_order:CanDeliver(boardModel:GetCodeCountMap(true, false, false)) then
    boardModel:FinishOrder(self.m_order)
  else
    GM.UIManager:OpenView(UIPrefabConfigName.UseInventoryItemConfirmWindow, boardModel, self.m_order)
  end
end

function BaseOrderCell:OnAvatarClick()
end

function BaseOrderCell:GetCellType()
end

function BaseOrderCell:Init(order, orderArea)
  self.m_order = order
  self.m_orderArea = orderArea
  self:_UpdateAvatar()
  self:_UpdateRequirementIcons()
  self:_UpdateReward()
  self:_UpdateServeButtonPosition()
  self:_UpdateTray()
  if not self.m_inited then
    self.m_showDeliver = self.m_order:GetState() == OrderState.CanDeliver and self.m_order.GetInnerType ~= nil and self.m_order:GetInnerType() ~= MainOrderType.BaselineOrder
    self:PlayEnterAnimation()
    if not self.m_orderArea.isFirstEnterMain then
      self.m_firstShowDeliver = true
    end
  end
  self:_OnShowItemTestInfoChanged()
  self.m_inited = true
end

function BaseOrderCell:_UpdateAvatar()
  local avatarName = self.m_order:GetAvatarName() .. "_order"
  if avatarName ~= self.m_avatarName then
    if self.m_avatar ~= nil then
      AddressableLoader.Destroy(self.m_avatar.gameObject)
      self.m_avatar = nil
    end
    self.m_avatarName = avatarName
    GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(avatarName), self.m_avatarTransform, Vector3.zero, function(gameObject)
      self.m_avatar = gameObject:GetLuaTable()
      self.m_avatar:Init(self.m_order)
      if self.m_bAvatarUpdateStateAfterLoad then
        self.m_bAvatarUpdateStateAfterLoad = nil
        self:OnOrderStateChanged()
      end
    end)
  end
end

function BaseOrderCell:_UpdateAvatarByName(name)
  function self.m_order.GetAvatarName()
    return name
  end
  
  local avatarName = name .. "_order"
  if avatarName ~= self.m_avatarName then
    if self.m_avatar ~= nil then
      AddressableLoader.Destroy(self.m_avatar.gameObject)
      self.m_avatar = nil
    end
    self.m_avatarName = avatarName
    GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(avatarName), self.m_avatarTransform, Vector3.zero, function(gameObject)
      self.m_avatar = gameObject:GetLuaTable()
      self.m_avatar:Init(self.m_order)
      if self.m_bAvatarUpdateStateAfterLoad then
        self.m_bAvatarUpdateStateAfterLoad = nil
        self:OnOrderStateChanged()
      end
    end)
  end
end

function BaseOrderCell:_UpdateAvatarByName(name)
  function self.m_order.GetAvatarName()
    return name
  end
  
  local avatarName = name .. "_order"
  if avatarName ~= self.m_avatarName then
    if self.m_avatar ~= nil then
      AddressableLoader.Destroy(self.m_avatar.gameObject)
      self.m_avatar = nil
    end
    self.m_avatarName = avatarName
    GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(avatarName), self.m_avatarTransform, Vector3.zero, function(gameObject)
      self.m_avatar = gameObject:GetLuaTable()
      self.m_avatar:Init(self.m_order)
      if self.m_bAvatarUpdateStateAfterLoad then
        self.m_bAvatarUpdateStateAfterLoad = nil
        self:OnOrderStateChanged()
      end
    end)
  end
end

function BaseOrderCell:_UpdateRequirementIcons()
  self.m_icons = self.m_icons or {}
  for _, icon in ipairs(self.m_icons) do
    icon.gameObject:SetActive(false)
  end
  for i = 1, #self.m_order:GetRequirements() do
    if self.m_icons[i] == nil then
      local iconObject = Object.Instantiate(self.m_iconPrefab, self.m_iconArea.transform)
      local orderIcon = iconObject:GetLuaTable()
      table.insert(self.m_icons, orderIcon)
    end
    self.m_icons[i].gameObject:SetActive(true)
    self.m_icons[i]:Init(self.m_order, i)
  end
  if #self.m_order:GetRequirements() == 2 then
    local rectOffset = CS.UnityEngine.RectOffset(25, 25, 0, 0)
    self.m_iconArea.padding = rectOffset
  end
end

function BaseOrderCell:_UpdateReward()
  self.m_rewardCells = self.m_rewardCells or {}
  for _, reward in ipairs(self.m_rewardCells) do
    reward.gameObject:SetActive(false)
  end
  local displayRewards = self:GetDisplayRewards()
  if Table.IsEmpty(displayRewards) then
    self.m_rewards.gameObject:SetActive(false)
    return
  end
  self.m_rewards.gameObject:SetActive(true)
  local normalRewards, specialRewards = self:_SplitRewards(displayRewards)
  if #normalRewards == 0 then
    self.m_rewards.gameObject:SetActive(false)
  else
    for i, reward in ipairs(normalRewards) do
      if self.m_rewardCells[i] == nil then
        local orderRewardGo = Object.Instantiate(self.m_rewardPrefab, self.m_rewards)
        table.insert(self.m_rewardCells, orderRewardGo:GetLuaTable())
      end
      self.m_rewardCells[i].gameObject:SetActive(true)
      self.m_rewardCells[i]:Init(reward)
      self:OnRewardCellInitFinish(self.m_rewardCells[i], reward)
    end
  end
  self:_UpdateActivitySpecialRewardView(specialRewards)
end

function BaseOrderCell:_SplitRewards(rewards)
  local normalRewards = {}
  local specialRewards = {}
  if rewards == nil then
    return normalRewards, specialRewards
  end
  local albumModel = GM.ActivityManager:GetStartedAlbumActivity()
  local aveModel = GM.ActivityManager:GetStartedAvenueActivity()
  local ringModel = GM.ActivityManager:GetStartedRingActivity()
  local floatRaceModel = GM.ActivityManager:GetModel(ActivityType.FloatRace)
  local roadModel = GM.ActivityManager:GetStartedRoadActivity()
  local upwardModel = GM.ActivityManager:GetStartedUpwardActivity()
  local expedModel = GM.ActivityManager:GetStartedExpedActivity()
  local comboModel = GM.ActivityManager:GetStartedComboActivity()
  for _, reward in ipairs(rewards) do
    if albumModel ~= nil and AlbumActivityModel.IsCacheProperty(reward[PROPERTY_TYPE]) then
      specialRewards[#specialRewards + 1] = {reward = reward, model = albumModel}
    elseif aveModel ~= nil and aveModel:IsTokenProperty(reward[PROPERTY_TYPE]) then
      specialRewards[#specialRewards + 1] = {reward = reward, model = aveModel}
    elseif roadModel ~= nil and roadModel:IsTokenProperty(reward[PROPERTY_TYPE]) then
      specialRewards[#specialRewards + 1] = {reward = reward, model = roadModel}
    elseif ringModel ~= nil and ringModel:IsTokenProperty(reward[PROPERTY_TYPE]) then
      specialRewards[#specialRewards + 1] = {reward = reward, model = ringModel}
    elseif GM.ActivityModuleManager:IsOrderSpecialReward(reward[PROPERTY_TYPE]) then
      specialRewards[#specialRewards + 1] = {
        reward = reward,
        model = GM.ActivityModuleManager:GetActivityModelByType(reward[PROPERTY_TYPE])
      }
    elseif floatRaceModel ~= nil and reward[PROPERTY_TYPE] == EPropertyType.FloatRaceScore then
      specialRewards[#specialRewards + 1] = {reward = reward, model = floatRaceModel}
    elseif upwardModel ~= nil and upwardModel:IsTokenProperty(reward[PROPERTY_TYPE]) then
      specialRewards[#specialRewards + 1] = {reward = reward, model = upwardModel}
    elseif comboModel ~= nil and comboModel:IsTokenProperty(reward[PROPERTY_TYPE]) then
      specialRewards[#specialRewards + 1] = {reward = reward, model = comboModel}
    else
      normalRewards[#normalRewards + 1] = reward
    end
  end
  return normalRewards, specialRewards
end

function BaseOrderCell:_UpdateActivitySpecialRewardView(arrData)
  if self.m_specialRewardNodeRectTrans == nil then
    return
  end
  self.m_specialRewardObjects = self.m_specialRewardObjects or {}
  for _, gameObject in pairs(self.m_specialRewardObjects) do
    if not gameObject:IsNull() then
      gameObject:SetActive(false)
    end
  end
  self:_AddSpecialRewards(arrData)
  for key, gameObject in pairs(self.m_specialRewardObjects) do
    if not gameObject.activeSelf then
      AddressableLoader.Destroy(gameObject)
      self.m_specialRewardObjects[key] = nil
    end
  end
end

function BaseOrderCell:_AddSpecialRewards(arrRewards)
end

function BaseOrderCell:_AddOneSpecialReward(key, reward, prefabName, position, scale, model)
  scale = scale or 1
  if self.m_specialRewardObjects[key] == nil then
    local config = GM.DataResource.UIPrefabConfig:GetConfig(prefabName)
    self.m_specialRewardObjectPosInfo = self.m_specialRewardObjectPosInfo or {}
    self.m_specialRewardObjectPosInfo[key] = {
      pos = position,
      scale = scale,
      reward = reward
    }
    
    local function callback(gameObject)
      if self.m_specialRewardObjects[key] ~= nil then
        AddressableLoader.Destroy(self.m_specialRewardObjects[key])
      end
      local reward = self.m_specialRewardObjectPosInfo[key].reward
      local position = self.m_specialRewardObjectPosInfo[key].pos
      local scale = self.m_specialRewardObjectPosInfo[key].scale
      self.m_specialRewardObjects[key] = gameObject
      gameObject:GetLuaTable():Init(reward, model, self)
      gameObject.transform.localPosition = position
      UIUtil.SetLocalScale(gameObject.transform, scale, scale, 1)
      if gameObject:GetLuaTable().PlayShowAnimation ~= nil then
        gameObject:GetLuaTable():PlayShowAnimation()
      end
    end
    
    GM.ResourceLoader:LoadPrefab(config, self.m_specialRewardNodeRectTrans, Vector3.zero, callback)
  else
    local gameObject = self.m_specialRewardObjects[key]
    gameObject:SetActive(true)
    gameObject:GetLuaTable():UpdateContent(reward)
    gameObject.transform.localPosition = position
    UIUtil.SetLocalScale(gameObject.transform, scale, scale, 1)
  end
end

function BaseOrderCell:GetSpecialRewardByKey(key)
  if self.m_specialRewardObjects == nil then
    return nil
  end
  return self.m_specialRewardObjects[key]
end

function BaseOrderCell:_UpdateServeButtonPosition()
  local maxNumber = self.m_order:GetMaxPossibleRewardNumber()
  local buttonY = 20
  local rewardNodeScale = 1.3
  local rewardNodeY = 110
  if maxNumber == 2 then
    buttonY = 60
  elseif maxNumber == 3 then
    buttonY = 60
    rewardNodeScale = 1.1
    rewardNodeY = 93
  elseif 3 < maxNumber then
    buttonY = 60
    rewardNodeScale = 1.1
    rewardNodeY = 93
  end
  if UIHelper.IsUsingOrderButtonNewPositionType() then
    UIHelper.UpdateOrderButtonOnNewPositionType(self.m_button)
  else
    UIUtil.SetAnchoredPosition(self.m_button, nil, buttonY, nil)
  end
  self.m_rewards.localScale = Vector3(rewardNodeScale, rewardNodeScale, 1)
  UIUtil.SetAnchoredPosition(self.m_rewards, nil, rewardNodeY, nil)
end

function BaseOrderCell:_UpdateTray()
  local imageKey = self:GetDisplayTray()
  SpriteUtil.SetImage(self.m_TrayImg, imageKey)
end

function BaseOrderCell:_OnShowItemTestInfoChanged()
  if not GameConfig.IsTestMode() then
    return
  end
  if not self.m_bUpdateTestInfoDisplay then
    self.m_bUpdateTestInfoDisplay = true
    DelayExecuteFuncInView(function()
      local testFinishButtonTrans = self.transform:Find("TestFinishButton")
      if testFinishButtonTrans then
        local testFinishButtonImageTrans = testFinishButtonTrans:Find("Image")
        if testFinishButtonImageTrans then
          local testFinishButtonImage = testFinishButtonImageTrans.gameObject:GetComponent(typeof(CS.UnityEngine.UI.Image))
          testFinishButtonImage.raycastTarget = false
        end
      end
      local targetY = 0
      local offsetY
      local baseSceneView = GM.UIManager:GetOpenedTopViewByType(EViewType.SceneView)
      if baseSceneView then
        local sceneViewHud = baseSceneView:GetHud()
        if sceneViewHud then
          local energyButton = sceneViewHud:GetHudButton(ESceneViewHudButtonKey.Energy)
          local screenPos = PositionUtil.UICameraWorld2Screen(energyButton.transform:TransformPoint(Vector3(0, -energyButton.transform.sizeDelta.y / 2, 0)))
          local boardWorldPos = self.m_orderArea:GetBoardView():ConvertScreenPositionToWorldPosition(screenPos)
          targetY = self.transform:InverseTransformPoint(boardWorldPos).y
          if testFinishButtonTrans then
            targetY = targetY - testFinishButtonTrans.sizeDelta.y / 2
            if targetY < testFinishButtonTrans.localPosition.y then
              offsetY = targetY - testFinishButtonTrans.localPosition.y
            end
          end
        end
      end
      if offsetY ~= nil then
        if testFinishButtonTrans then
          UIUtil.AddAnchoredPosition(testFinishButtonTrans, nil, offsetY, nil)
        end
        local testTextTrans = self.transform:Find("TestText")
        if testTextTrans then
          UIUtil.AddAnchoredPosition(testTextTrans, nil, offsetY, nil)
          local canvasComponent = testTextTrans.gameObject:AddComponent(typeof(CS.UnityEngine.Canvas))
          canvasComponent.overrideSorting = true
          canvasComponent.sortingOrder = 5
        end
        local testAddItemButtonTrans = self.transform:Find("TestAddItemButton")
        if testAddItemButtonTrans then
          UIUtil.AddAnchoredPosition(testAddItemButtonTrans, nil, offsetY, nil)
        end
      end
    end, 0.1, self)
  end
  local color = "94261A"
  local infoStr = self:GetTestInfoStr()
  if StringUtil.IsNilOrEmpty(infoStr) then
    self.m_testText.gameObject:SetActive(true)
    local id = self.m_order:GetId()
    local slotInfo = "Slot: " .. StringUtil.MakeColorFormat(self.m_order:GetSlot(), color) .. "  "
    local typeInfo = "Type: " .. StringUtil.MakeColorFormat(tostring(self.m_order:GetType()), color) .. "\n"
    local idInfo = "Id: " .. StringUtil.MakeColorFormat(tostring(id), color) .. "  "
    infoStr = slotInfo .. typeInfo .. idInfo
  end
  local diffRange = self.m_order:GetDiffRange()
  if diffRange and diffRange ~= "" then
    diffRange = "DiffRange: " .. StringUtil.MakeColorFormat(diffRange, color)
  else
    diffRange = ""
  end
  infoStr = infoStr .. diffRange
  local albumModel = GM.ActivityManager:GetStartedAlbumActivity()
  if albumModel ~= nil then
    local diffScore = self.m_order:GetDiffScore()
    infoStr = infoStr .. [[

DiffScore: ]] .. diffScore
    if GM.ActivityManager:GetStartedAlbumActivity():GetOrderReward(self.m_order:GetSlot()) ~= nil then
      for i, v in ipairs(albumModel.m_arrScore2RewardConfig) do
        local scoreMin = v.scoreMin
        local scoreMax = v.scoreMax
        if diffScore >= scoreMin and diffScore <= scoreMax then
          local scIndex = scoreMin .. "_" .. scoreMax
          local albumPackRewards = v.packReward
          local albumPackInfos = albumModel.m_orderGenerateRights[scIndex]
          infoStr = infoStr .. "\n"
          local flag = false
          for i, rwdInfo in pairs(albumPackRewards) do
            if not Table.IsEmpty(albumPackInfos) then
              for i, pinfo in pairs(albumPackInfos) do
                if pinfo[PROPERTY_TYPE] == rwdInfo[PROPERTY_TYPE] then
                  infoStr = infoStr .. pinfo[PROPERTY_TYPE] .. " Weight:" .. pinfo[PROPERTY_WEIGHT] .. "\n"
                  flag = true
                end
              end
            end
            if not flag then
              infoStr = infoStr .. rwdInfo[PROPERTY_TYPE] .. " Weight: 0" .. "\n"
            end
            flag = false
          end
          break
        end
      end
      local oriRwd = albumModel:GetOrderOriRewardById(tostring(self.m_order:GetSlot()))
      if oriRwd ~= nil then
        oriRwd = oriRwd[PROPERTY_TYPE]
        infoStr = infoStr .. "oriRwd: " .. oriRwd
      end
    end
  end
  self.m_testText.text = infoStr
end

function BaseOrderCell:OnTestAddItemClicked()
  if not GameConfig.IsTestMode() then
    return
  end
  local boardModel = self.m_orderArea:GetBoardView():GetModel()
  if not self.m_order:CanDeliver(boardModel:GetCodeCountMap(true, false, false)) then
    local requirements = self.m_order:GetRequirements()
    for i = 1, #requirements do
      local code = requirements[i]
      local position = boardModel:FindEmptyPositionInValidOrder()
      if position then
        GM.TestModel:AddItemOnBoard(boardModel, position, code)
      else
        GM.UIManager:ShowPrompt("\230\163\139\231\155\152\229\183\178\230\187\161\239\188\140\230\183\187\229\138\160\229\136\176\231\188\147\229\173\152\233\152\159\229\136\151")
        boardModel:CacheItems({code}, CacheItemType.Type2)
      end
    end
  end
end

function BaseOrderCell:_OnTestFinishOrder()
  if not GameConfig.IsTestMode() then
    return
  end
  if self.m_testFinishingOrder then
    return
  end
  if self.m_order:GetState() == OrderState.Finished then
    return
  end
  self.m_testFinishingOrder = true
  local boardModel = self.m_orderArea:GetBoardView():GetModel()
  if not self.m_order:CanDeliver(boardModel:GetCodeCountMap(true, false, false)) then
    local requirements = self.m_order:GetRequirements()
    for i = 1, #requirements do
      local code = requirements[i]
      local position = boardModel:FindEmptyPositionInValidOrder()
      if position then
        GM.TestModel:AddItemOnBoard(boardModel, position, code)
      else
        GM.UIManager:ShowPrompt("\230\163\139\231\155\152\229\183\178\230\187\161\239\188\140\230\151\160\230\179\149\231\171\139\229\141\179\229\174\140\230\136\144\232\174\162\229\141\149")
        canFinish = false
        self.m_testFinishingOrder = false
        return
      end
    end
  end
  local testFinishButtonTrans = self.transform:Find("TestFinishButton")
  if testFinishButtonTrans then
    testFinishButtonTrans.gameObject:SetActive(false)
  end
  self:SetGoButtonEnabled(true)
  self:OnGoButtonClicked()
end

function BaseOrderCell:OnDestroy()
  EventDispatcher.RemoveTarget(self)
end

function BaseOrderCell:GetOrder()
  return self.m_order
end

function BaseOrderCell:GetIconArea()
  return self.m_iconArea
end

function BaseOrderCell:GetIcon(index)
  return self.m_icons[index]
end

function BaseOrderCell:GetGoButton()
  return self.m_button
end

function BaseOrderCell:SetOrderIconClickEnabled(enable)
  for _, icon in ipairs(self.m_icons) do
    icon:SetClickEnabled(enable)
  end
end

function BaseOrderCell:SetGoButtonEnabled(enable)
  self.m_bGoButtonEnabled = enable
end

function BaseOrderCell:CheckHaveFinshOrderInActivity()
  local model = GM.ActivityManager:GetModel(ActivityType.CookingFrenzy)
  local bAcivityCf = model and model:GetCurDoingBuff() ~= nil
  local slotCells = MainBoardView.GetInstance():GetOrderArea():GetCells(OrderModelType.Slot)
  if bAcivityCf and MainBoardView.GetInstance() then
    for _, cell in pairs(slotCells) do
      if cell:GetOrder():GetState() == OrderState.Finished then
        return true
      end
    end
  end
  local model = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  if model:GetState() == ActivityState.Started then
    for _, cell in pairs(slotCells) do
      if cell:GetOrder():GetState() == OrderState.Finished and (cell.IsPlayFinishRewardAnimation and cell:IsPlayFinishRewardAnimation() or model:IsChestCustomerOrder(cell:GetOrder():GetSlot())) then
        return true
      end
    end
  end
  return false
end

function BaseOrderCell:OnOrderStateChanged()
  if self.m_playingAnimation then
    return
  end
  local canDeliverOrder = self.m_order:GetState() == OrderState.CanDeliver
  local bHaveFinishOrder = self:CheckHaveFinshOrderInActivity()
  if not bHaveFinishOrder and canDeliverOrder and (not self.m_showDeliver or self.m_firstShowDeliver) and GM.SceneManager:GetGameMode() == EGameMode.Main then
    self:ScrollToOrder()
    local soundName = self:GetDeliverAudioEffectName()
    if soundName ~= nil then
      GM.AudioModel:PlayEffect(soundName)
    end
    self.m_firstShowDeliver = false
  end
  self.m_button.gameObject:SetActive(canDeliverOrder)
  self.m_starEffectGo:SetActive(canDeliverOrder)
  self.m_radianceGo:SetActive(canDeliverOrder)
  self.m_showDeliver = canDeliverOrder
  if self.m_avatar ~= nil then
    self.m_avatar:OnOrderStateChanged()
  end
  for _, icon in ipairs(self.m_icons) do
    icon:OnOrderStateChanged()
  end
end

function BaseOrderCell:ScrollToOrder()
  self.m_orderArea:ScrollToRectTransformMiddle(self.transform)
end

function BaseOrderCell:ScrollToOrderIfNotInView()
  if not self.m_orderArea:OrderIsInView(self.transform) then
    self.m_orderArea:ScrollToRectTransformMiddle(self.transform)
  end
end

function BaseOrderCell:PlayEnterAnimation()
  self.m_playingAnimation = true
  local sequence = DOTween.Sequence()
  if self.m_order:GetState() ~= OrderState.Dormant then
    sequence:Append(self:PlayTrayAnimation())
  end
  sequence:InsertCallback(0.2, function()
    if self.m_avatar ~= nil then
      self.m_avatar:SetTransparent(false)
      self.m_avatar:PlayEnterAnimation()
    else
      self.m_bAvatarUpdateStateAfterLoad = true
    end
  end)
  sequence:InsertCallback(1.1, function()
    self.m_playingAnimation = false
    self:OnOrderStateChanged()
  end)
end

function BaseOrderCell:PlayTrayAnimation()
  self.m_tray.localScale = Vector3.zero
  self.m_tray.gameObject:SetActive(true)
  local sequence = DOTween.Sequence()
  sequence:Append(self.m_tray:DOScale(1.1, 0.5))
  sequence:Append(self.m_tray:DOScale(1.0, 0.2))
  return sequence
end

function BaseOrderCell:PlayTrayAnimationHide()
  local sequence = DOTween.Sequence()
  sequence:Append(self.m_tray:DOScale(1.1, 0.2))
  sequence:Append(self.m_tray:DOScale(0.0, 0.5))
  sequence:OnComplete(function()
    self.m_tray.localScale = Vector3.zero
    self.m_tray.gameObject:SetActive(false)
  end)
  return sequence
end

function BaseOrderCell:PlayEnterBoardAnimation(showUIDelay, showAvatarDelay)
  self.m_playingAnimation = true
  local avatarExists = self.m_avatar ~= nil
  if avatarExists then
    self.m_avatar:SetTransparent(true)
  else
    self.m_bAvatarUpdateStateAfterLoad = true
  end
  self.m_radianceGo:SetActive(false)
  self.m_starEffectGo:SetActive(false)
  self.m_tray.gameObject:SetActive(false)
  self.m_rewards.gameObject:SetActive(false)
  local buttonGroup = self.m_button:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
  buttonGroup.alpha = 0
  local sequence = DOTween.Sequence()
  sequence:InsertCallback(showUIDelay, function()
    if self.m_order:GetState() ~= OrderState.Dormant then
      self.m_tray.gameObject:SetActive(true)
      self.m_rewards.gameObject:SetActive(true)
    end
  end)
  sequence:InsertCallback(showAvatarDelay, function()
    if avatarExists and self.m_avatar ~= nil then
      self.m_avatar:SetTransparent(false)
      self.m_avatar:ClearTracks()
      self.m_avatar:PlayEnterAnimation()
    end
    if self.m_order:GetState() == OrderState.CanDeliver then
      self.m_radianceGo:SetActive(true)
      self.m_starEffectGo:SetActive(true)
    end
  end)
  sequence:Insert(showAvatarDelay + 0.3, buttonGroup:DOFade(1, 0.3))
  sequence:InsertCallback(showAvatarDelay + 0.7, function()
    self.m_playingAnimation = false
    self:OnOrderStateChanged()
  end)
end

function BaseOrderCell:PlayCoinEffect()
  GM.AudioModel:PlayEffect(AudioFileConfigName.SfxMergeCollectCoins)
  if self.m_SpecialRewardsRectTrans then
    UIUtil.SetActive(self.m_SpecialRewardsRectTrans.gameObject, false)
  end
  self.m_rewards.gameObject:SetActive(false)
  for key, object in pairs(self.m_specialRewardObjects) do
    if not object:GetLuaTable().PlayDestoryAnimation then
      UIUtil.SetActive(object, false)
    else
      object:GetLuaTable():PlayDestoryAnimation()
    end
  end
  Object.Instantiate(self.m_coinEffectPrefab, self.m_tray)
end

function BaseOrderCell:PlayLeaveAnimation()
  if self.m_avatar ~= nil then
    self.m_avatar:PlayLeaveAnimation()
  end
end

function BaseOrderCell:SetHandEffectActive(active)
  self.m_handEffectGo:SetActive(active)
end

function BaseOrderCell:HideTrayTrans()
  UIUtil.SetActive(self.m_tray.gameObject, false)
end
