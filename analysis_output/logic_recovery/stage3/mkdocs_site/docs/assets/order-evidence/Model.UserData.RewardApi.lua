RewardApi = {}
RewardApi.DefaultViewData = {
  arrWorldPos = {},
  eventLock = true,
  noDelayTime = false
}
ERewardCategoryType = {
  Unknown = "Unknown",
  Property = "Property",
  Skin = "Skin",
  Item = "Item",
  Avatar = "Avatar",
  AvatarFrame = "AvatarFrame",
  BuffProperty = "BuffProperty",
  RandomReward = "RandomReward",
  AdventureToolItem = "AdventureToolItem",
  OrderBuffBox = "OrderBuffBox",
  MultiboardsMergeLineItem = "MultiboardsMergeLineItem",
  AlbumNewCard = "AlbumNewCard",
  PlaneReward = "PlaneReward",
  RaccoonReward = "RaccoonReward",
  NChooseOneReward = "NChooseOneReward",
  CustomBoardItem = "CustomBoardItem",
  ChestCustomOrderReward = "ChestCustomOrderReward",
  BoostCharge = "BoostCharge",
  SpinRandomReward = "SpinRandomReward",
  CustomerUpgradeReward = "CustomerUpgradeReward",
  CannonReward = "CannonReward",
  PureBoardMergeLineItem = "PureBoardMergeLineItem"
}
SKIN_REWARD_PREFIX = "skin_rwd_"
AVATAR_REWARD_PREFIX = "ar_"
AVATAR_FRAME_REWARD_PREFIX = "arfm_"
BUFF_REWARD_PREFIX = "buff"
RANDOM_REWARD_PREFIX = "rdm_rwd_"
ORDER_BUFF_BOX_PREFIX = "bf_chest_"
ALBUM_NEW_CARD_PREFIX = "album_nc"
PLANE_REWARD_PREFIX = "plane_"
RACCOON_REWARD_PREFIX = "raccoon_"
CUSTOM_BOARD_ITEM_PREFIX = "cbitm_"
BOOST_CHARGE_PREFIX = "boostcharge_"
SPIN_RANDOM_PREFIX = "spin_rdm_rwd_"
CUSTOMER_UPGRADE_PREFIX = "customer_upgrade"
N_CHOOSE_ONE_PREFIX = "n_choose_one"
ORDER_BOOST_SMILE_PREFIX = "orderBoostSmile"
CANNON_REWARD_PREFIX = "cannon_"

function RewardApi.SplitRewards(arrRewards)
  if Table.IsEmpty(arrRewards) then
    return Table.Empty
  end
  local splitedRewardDatas = {}
  if arrRewards and not arrRewards[1] then
    arrRewards = {arrRewards}
  end
  for _, reward in ipairs(arrRewards) do
    local categoryType = RewardApi.GetRewardCategoryType(reward[PROPERTY_TYPE])
    if splitedRewardDatas[categoryType] == nil then
      splitedRewardDatas[categoryType] = {}
    end
    splitedRewardDatas[categoryType][#splitedRewardDatas[categoryType] + 1] = reward
  end
  return splitedRewardDatas
end

function RewardApi.AcquireRewards(formattedRewards, source, scene, viewData, targetGameMode, cacheItemType, boardType)
  if formattedRewards == nil then
    return
  end
  RewardApi.AcquireRewardsLogic(formattedRewards, source, scene, targetGameMode, cacheItemType, boardType)
  RewardApi.AcquireRewardsInView(formattedRewards, viewData)
end

function RewardApi.AcquireRewardsLogic(formattedRewards, source, scene, targetGameMode, cacheItemType, boardType)
  if Table.IsEmpty(formattedRewards) then
    return
  end
  if formattedRewards and not formattedRewards[1] then
    formattedRewards = {formattedRewards}
  end
  local convertedRewards = {}
  for i = 1, #formattedRewards do
    convertedRewards[#convertedRewards + 1] = RewardApi.ConvertDynamicReward(formattedRewards[i])
  end
  local splitedRewardDatas = RewardApi.SplitRewards(convertedRewards)
  RewardApi._AcquireRewardsLogic(splitedRewardDatas, source, scene, targetGameMode, cacheItemType, boardType)
  if GameConfig.IsTestMode() then
    EventDispatcher.DispatchEvent(EEventType.TestPropertyMonitorRewardsLogic, convertedRewards)
  end
end

function RewardApi._AcquireRewardsLogic(splitedRewardDatas, source, scene, targetGameMode, cacheItemType, boardType)
  local handlers = GM.RewardHandlerManager:GetAllHandlers()
  local arrConfig = {
    source = source,
    scene = scene,
    targetGameMode = targetGameMode,
    cacheItemType = cacheItemType,
    boardType = boardType
  }
  for type, handler in pairs(handlers) do
    if not Table.IsEmpty(splitedRewardDatas[type]) then
      handler:LogicHandle(splitedRewardDatas[type], arrConfig)
    end
  end
end

function RewardApi.AcquireRewardsInView(arrRewards, viewData)
  viewData = viewData or RewardApi.DefaultViewData
  viewData.arrWorldPos = viewData.arrWorldPos or Table.Empty
  viewData.targetGameMode = viewData.targetGameMode or Table.Empty
  viewData.alwaysInMiddle = viewData.alwaysInMiddle == nil and true or viewData.alwaysInMiddle
  local baseSceneView = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView)
  local itemFlyEndPosition = baseSceneView:GetFlyCachedItemTargetPosition()
  local itemFlyEndPositionInOtherGameMode = baseSceneView:GetFlyCachedItemTargetPosition(false)
  local curGameMode = GM.SceneManager:GetGameMode()
  if not Table.IsEmpty(viewData.highlightHudArgs) then
    RewardApi.HighlightHud(arrRewards, viewData.highlightHudArgs)
  end
  local hasRandomReward = false
  local hasAvatarFrameReward = false
  local hasNChooseOneReward = false
  for i, rewardData in ipairs(arrRewards) do
    rewardData = RewardApi.ConvertDynamicReward(rewardData)
    local flyDelay = 0
    if not viewData.noDelayTime then
      local interval = viewData.interval or 0.3
      flyDelay = 0.5 + interval * (i - 1)
    end
    local uiWorldPosition = viewData.arrWorldPos[i] or V3Zero
    local endPosition
    if viewData.targetButton == nil then
      if viewData.itemAlwaysFlytoOther then
        endPosition = itemFlyEndPositionInOtherGameMode
      elseif viewData.targetGameMode[i] == nil or viewData.targetGameMode[i] == curGameMode then
        endPosition = itemFlyEndPosition
      else
        endPosition = itemFlyEndPositionInOtherGameMode
      end
    end
    local rewardType = rewardData[PROPERTY_TYPE]
    local categoryType = RewardApi.GetRewardCategoryType(rewardType)
    if viewData.floatUp then
      if categoryType == ERewardCategoryType.RandomReward then
        viewData.eventLock = true
      end
      viewData.simpleCollect = true
      viewData.waitingForFloatUp = true
      local interval = viewData.interval or 0.25
      local customData = {
        {
          flyDelay = interval * (i - 1),
          eventLock = viewData.eventLock,
          spriteScale = viewData.spriteScale,
          floatUpMovePosY = viewData.floatUpMovePosY,
          floatUpMoveTime = viewData.floatUpMoveTime
        }
      }
      GM.PropertyDataManager:PlayFloatUpAnimation({rewardData}, uiWorldPosition, customData)
    end
    local handler = GM.RewardHandlerManager:GetHandler(categoryType)
    if handler and handler.InViewHandle then
      local arrConfig = {
        viewData = viewData,
        flyDelay = flyDelay,
        uiWorldPosition = uiWorldPosition,
        endPosition = endPosition,
        index = i
      }
      handler:InViewHandle(rewardData, arrConfig)
    end
    if categoryType == ERewardCategoryType.RandomReward then
      hasRandomReward = true
    end
    if categoryType == ERewardCategoryType.AvatarFrame then
      hasAvatarFrameReward = true
    end
    if categoryType == ERewardCategoryType.NChooseOneReward then
      hasNChooseOneReward = true
    end
  end
  if viewData.onFinish ~= nil then
    local function onUpdate()
      if GM.UIManager:IsEventLock() then
        return
      end
      if hasRandomReward and not RandomRewardWindow.IsFinished() then
        return
      end
      if hasAvatarFrameReward and not AvatarFrameRewardWindow.IsFinished() then
        return
      end
      Scheduler.Unschedule(onUpdate)
      viewData.onFinish()
    end
    
    Scheduler.Schedule(onUpdate)
  end
end

function RewardApi.GetRewardIconNameAndIsSetNativeSize(rewardType)
  local categoryType = RewardApi.GetRewardCategoryType(rewardType)
  local handler = GM.RewardHandlerManager:GetHandler(categoryType)
  if handler ~= nil then
    return handler:GetRewardIconNameAndIsSetNativeSize(rewardType)
  end
  return GM.ItemDataModel:GetSpriteName(rewardType), true
end

function RewardApi.CheckRewardPrefix(rewardType, prefix)
  if not rewardType or not IsString(rewardType) then
    return false
  end
  if not StringUtil.StartWith(rewardType, prefix) then
    return false
  end
  return true
end

function RewardApi.SkinRewardToSkinId(rewardType)
  return string.sub(rewardType, #SKIN_REWARD_PREFIX + 1)
end

function RewardApi.SkinIdToSkinReward(skinId)
  return {
    [PROPERTY_TYPE] = SKIN_REWARD_PREFIX .. skinId,
    [PROPERTY_COUNT] = 1
  }
end

function RewardApi.CheckIsAdventureToolItem(rewardType)
  for _, definition in pairs(AdventureActivityDefinition) do
    if RewardApi.CheckRewardPrefix(rewardType, definition.ToolItemChain) then
      return true
    end
  end
  return false
end

function RewardApi.CheckIsPureBoardMergeLineItem(rewardType)
  for _, definition in pairs(PureBoardActivityDefinition) do
    if RewardApi.CheckRewardPrefix(rewardType, definition.ItemChainPrefix) then
      return true
    end
  end
  return false
end

function RewardApi.CheckIsMultiboardsMergeLineItem(rewardType)
  for _, definition in pairs(MultiboardsActivityDefinition) do
    if RewardApi.CheckRewardPrefix(rewardType, definition.ItemChain) then
      return true
    end
  end
  return false
end

function RewardApi.CheckRewardCategoryType(rewardType, categoryType)
  return RewardApi.GetRewardCategoryType(rewardType) == categoryType
end

function RewardApi.GetRewardCategoryType(rewardType, ignoreError)
  Log.Assert(not StringUtil.IsNilOrEmpty(rewardType), "[RewardApi] reward is nil or not have type")
  if GM.PropertyDataManager:IsPropertyType(rewardType) then
    return ERewardCategoryType.Property
  elseif RewardApi.CheckRewardPrefix(rewardType, SKIN_REWARD_PREFIX) then
    return ERewardCategoryType.Skin
  elseif RewardApi.CheckRewardPrefix(rewardType, AVATAR_REWARD_PREFIX) then
    return ERewardCategoryType.Avatar
  elseif RewardApi.CheckRewardPrefix(rewardType, AVATAR_FRAME_REWARD_PREFIX) then
    return ERewardCategoryType.AvatarFrame
  elseif RewardApi.CheckRewardPrefix(rewardType, BUFF_REWARD_PREFIX) then
    return ERewardCategoryType.BuffProperty
  elseif RewardApi.CheckRewardPrefix(rewardType, RANDOM_REWARD_PREFIX) then
    return ERewardCategoryType.RandomReward
  elseif RewardApi.CheckRewardPrefix(rewardType, ORDER_BUFF_BOX_PREFIX) then
    return ERewardCategoryType.OrderBuffBox
  elseif RewardApi.CheckRewardPrefix(rewardType, ALBUM_NEW_CARD_PREFIX) then
    return ERewardCategoryType.AlbumNewCard
  elseif RewardApi.CheckRewardPrefix(rewardType, PLANE_REWARD_PREFIX) then
    return ERewardCategoryType.PlaneReward
  elseif RewardApi.CheckRewardPrefix(rewardType, RACCOON_REWARD_PREFIX) then
    return ERewardCategoryType.RaccoonReward
  elseif RewardApi.CheckIsAdventureToolItem(rewardType) then
    return ERewardCategoryType.AdventureToolItem
  elseif RewardApi.CheckIsMultiboardsMergeLineItem(rewardType) then
    return ERewardCategoryType.MultiboardsMergeLineItem
  elseif RewardApi.CheckRewardPrefix(rewardType, CUSTOM_BOARD_ITEM_PREFIX) then
    return ERewardCategoryType.CustomBoardItem
  elseif RewardApi.CheckRewardPrefix(rewardType, ChestCustomerModel.RewardKey) then
    return ERewardCategoryType.ChestCustomOrderReward
  elseif RewardApi.CheckRewardPrefix(rewardType, BOOST_CHARGE_PREFIX) then
    return ERewardCategoryType.BoostCharge
  elseif RewardApi.CheckRewardPrefix(rewardType, SPIN_RANDOM_PREFIX) then
    return ERewardCategoryType.SpinRandomReward
  elseif RewardApi.CheckRewardPrefix(rewardType, CUSTOMER_UPGRADE_PREFIX) then
    return ERewardCategoryType.CustomerUpgradeReward
  elseif RewardApi.CheckRewardPrefix(rewardType, N_CHOOSE_ONE_PREFIX) then
    return ERewardCategoryType.NChooseOneReward
  elseif RewardApi.CheckRewardPrefix(rewardType, CANNON_REWARD_PREFIX) then
    return ERewardCategoryType.CannonReward
  elseif RewardApi.CheckIsPureBoardMergeLineItem(rewardType) then
    return ERewardCategoryType.PureBoardMergeLineItem
  elseif ItemTypeMap[rewardType] then
    return ERewardCategoryType.Item
  else
    if not ignoreError then
      GM.BIManager:LogErrorInfo(EBIType.UnknownRewardType, tostring(rewardType))
    end
    return ERewardCategoryType.Unknown
  end
end

function RewardApi.IsJokekRewardCard(rewardType)
  return rewardType == EPropertyType.JokerCommonCard or rewardType == EPropertyType.JokerGoldenCard
end

function RewardApi.CanShowTipButton(rewardType)
  if GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestShowAllRewardItemTip, 0) == 1 then
    return true
  end
  local categoryType = RewardApi.GetRewardCategoryType(rewardType)
  local handler = GM.RewardHandlerManager:GetHandler(categoryType)
  if handler ~= nil then
    return handler:CanShowTipButton(rewardType)
  end
end

function RewardApi.IsRewardsEqual(rewards1, rewards2)
  if #rewards1 ~= #rewards2 then
    return false
  end
  rewards1 = Table.DeepCopy(rewards1)
  rewards2 = Table.DeepCopy(rewards2)
  
  local function sortReward(a, b)
    if a[PROPERTY_TYPE] ~= b[PROPERTY_TYPE] then
      return a[PROPERTY_TYPE] < b[PROPERTY_TYPE]
    else
      return a[PROPERTY_COUNT] < b[PROPERTY_COUNT]
    end
  end
  
  table.sort(rewards1, sortReward)
  table.sort(rewards2, sortReward)
  for i = 1, #rewards1 do
    if rewards1[i][PROPERTY_TYPE] ~= rewards2[i][PROPERTY_TYPE] or rewards1[i][PROPERTY_COUNT] ~= rewards2[i][PROPERTY_COUNT] then
      return false
    end
  end
  return true
end

function RewardApi.ConvertDynamicReward(reward, needBI)
  local rewardType = reward[PROPERTY_TYPE]
  local categoryType = RewardApi.GetRewardCategoryType(rewardType)
  local handler = GM.RewardHandlerManager:GetHandler(categoryType)
  if handler ~= nil then
    return handler:ConvertDynamicHandle(reward, needBI)
  end
  return reward
end

function RewardApi.MergeRewards(arrSrc, arrNew)
  if Table.IsEmpty(arrSrc) then
    arrSrc = Table.DeepCopy(arrNew, true)
    return arrSrc
  end
  for i, v in ipairs(arrNew) do
    local bMerge = false
    for j, v1 in ipairs(arrSrc) do
      if v1[PROPERTY_TYPE] == v[PROPERTY_TYPE] then
        v1[PROPERTY_COUNT] = v1[PROPERTY_COUNT] + v[PROPERTY_COUNT]
        bMerge = true
        break
      end
    end
    if not bMerge then
      arrSrc[#arrSrc + 1] = Table.DeepCopy(v, true)
    end
  end
  return arrSrc
end

function RewardApi.CustomBoardItem2BoardTypeAndRealItemCode(rewardType)
  local strs = StringUtil.Split(rewardType, "_")
  return strs[2], table.concat(strs, "_", 3)
end

function RewardApi._InitHighlightInfo()
  if not RewardApi._highlightPropertyHudKeys then
    RewardApi._highlightPropertyHudKeys = {
      ESceneViewHudButtonKey.Energy,
      ESceneViewHudButtonKey.Coin,
      ESceneViewHudButtonKey.Gem
    }
  end
  if not RewardApi._highlightBoardHudKeys then
    RewardApi._highlightBoardHudKeys = {
      ESceneViewHudButtonKey.MainBoard
    }
  end
  if not RewardApi._highlightHudKeys then
    RewardApi._highlightHudKeys = {
      ESceneViewHudButtonKey.Energy,
      ESceneViewHudButtonKey.Coin,
      ESceneViewHudButtonKey.Gem,
      ESceneViewHudButtonKey.MainBoard
    }
  end
  if not RewardApi._highlightHudAnchorType then
    RewardApi._highlightHudAnchorType = {
      EHudAnchorType.CenterLeft,
      EHudAnchorType.Center,
      EHudAnchorType.CenterRight,
      EHudAnchorType.BottomLeft,
      EHudAnchorType.BottomCenter,
      EHudAnchorType.BottomRight
    }
  end
  if not RewardApi._mapPackType then
    RewardApi._mapPackType = {}
    for _, v in pairs(EPropertyType) do
      if string.find(v, "card") or string.find(v, "pack") then
        RewardApi._mapPackType[v] = true
      end
    end
  end
end

function RewardApi.HighlightHud(arrRewards, highlightHudArgs)
  RewardApi._InitHighlightInfo()
  if highlightHudArgs.duration == nil then
    Log.Error("highlightHudArgs\230\156\170\228\188\160duration")
    return
  end
  local showHudAnchorType = highlightHudArgs.showHudAnchorType or RewardApi._highlightHudAnchorType
  local HighlightHudKeys = highlightHudArgs.highlightHudKeys or RewardApi._GetHighlightHudKeys(arrRewards)
  if not HighlightHudKeys then
    return
  end
  EventDispatcher.DispatchEvent(EEventType.HighlightHud, {highlight = true, arrHudKey = HighlightHudKeys})
  DelayExecuteFunc(function()
    EventDispatcher.DispatchEvent(EEventType.HighlightHud, {highlight = false, arrHudKey = HighlightHudKeys})
    if highlightHudArgs.func then
      highlightHudArgs.func()
    end
  end, highlightHudArgs.duration)
end

function RewardApi._GetHighlightHudKeys(arrRewards)
  local hasBoard, hasProperty
  for _, rewardData in ipairs(arrRewards) do
    rewardData = RewardApi.ConvertDynamicReward(rewardData)
    local categoryType = RewardApi.GetRewardCategoryType(rewardData[PROPERTY_TYPE])
    if categoryType == ERewardCategoryType.Property then
      if rewardData[PROPERTY_TYPE] == EPropertyType.Energy or rewardData[PROPERTY_TYPE] == EPropertyType.Gem or rewardData[PROPERTY_TYPE] == EPropertyType.Gold then
        hasProperty = true
      elseif RewardApi.IsPackReward(rewardData[PROPERTY_TYPE]) then
        hasBoard = true
      end
    elseif categoryType == ERewardCategoryType.Item or categoryType == ERewardCategoryType.AlbumNewCard then
      hasBoard = true
    end
  end
  if hasBoard and not hasProperty then
    return RewardApi._highlightBoardHudKeys
  elseif hasProperty and not hasBoard then
    return RewardApi._highlightPropertyHudKeys
  elseif hasProperty and hasBoard then
    return RewardApi._highlightHudKeys
  end
end

function RewardApi.IsPackReward(propertyType)
  RewardApi._InitHighlightInfo()
  return RewardApi._mapPackType[propertyType]
end
