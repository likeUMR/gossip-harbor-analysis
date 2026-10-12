ItemRewardCategoryHandler = setmetatable({}, BaseRewardCategoryHandler)
ItemRewardCategoryHandler.__index = ItemRewardCategoryHandler

function ItemRewardCategoryHandler.Create()
  local handler = setmetatable({}, ItemRewardCategoryHandler)
  return handler
end

function ItemRewardCategoryHandler:LogicHandle(rewardDatas, logicArgs)
  local arrItems = {}
  for _, itemData in ipairs(rewardDatas) do
    for i = 1, itemData[PROPERTY_COUNT] do
      arrItems[#arrItems + 1] = itemData[PROPERTY_TYPE]
    end
  end
  local boardModel = BoardModelHelper.GetModelByGameMode(logicArgs.targetGameMode)
  boardModel:CacheItems(arrItems, logicArgs.cacheItemType)
  for _, itemData in ipairs(rewardDatas) do
    GM.BIManager:LogAcquire(itemData[PROPERTY_TYPE], itemData[PROPERTY_COUNT], logicArgs.scene, logicArgs.source == EPropertySource.Give, logicArgs.boardType)
  end
end

function ItemRewardCategoryHandler:InViewHandle(rewardData, showArgs)
  local viewData = showArgs.viewData
  if viewData.simpleCollect then
    return
  end
  local rewardType = rewardData[PROPERTY_TYPE]
  if rewardType ~= ItemType.Lollipop01 then
    local customData = {
      {
        endPos = showArgs.endPosition,
        flyCount = 1,
        spriteKey = GM.ItemDataModel:GetSpriteName(rewardType),
        flyDelay = showArgs.flyDelay,
        eventLock = viewData.eventLock,
        targetButton = viewData.targetButton,
        spriteScale = viewData.spriteScale
      }
    }
    GM.PropertyDataManager:PlayCollectAnimation({rewardData}, showArgs.uiWorldPosition, customData)
  end
end

function ItemRewardCategoryHandler:CanShowTipButton(rewardType)
  if rewardType == ItemType.level_up_piece_1 or rewardType == ItemType.level_down_piece_1 then
    return true
  end
  if RewardApi.CheckRewardCategoryType(rewardType, ERewardCategoryType.Item) then
    local itemModelConfig = GM.ItemDataModel:GetModelConfig(rewardType)
    if itemModelConfig ~= nil and itemModelConfig.Spread_WeightType ~= nil and (itemModelConfig.Spread_WeightType == ItemSpreadWeightType.ChestCustomItem or itemModelConfig.Spread_WeightType == ItemSpreadWeightType.SmartItem) then
      return true
    end
  end
  return false
end
