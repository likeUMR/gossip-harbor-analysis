PropertyRewardCategoryHandler = setmetatable({}, BaseRewardCategoryHandler)
PropertyRewardCategoryHandler.__index = PropertyRewardCategoryHandler

function PropertyRewardCategoryHandler.Create()
  local handler = setmetatable({}, PropertyRewardCategoryHandler)
  handler:Init()
  return handler
end

function PropertyRewardCategoryHandler:Init()
  self.m_propertyHandlers = {}
  self:_RegisterByPropertyType(EPropertyType.BakeOutToken, PropertyRewardBakeOutHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.BingoBall, PropertyRewardBingoHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.CookingFrenzyScore, PropertyRewardCookingFrenzyHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.TriggerBoostScore, PropertyRewardTriggerBoostHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.BuyEnergyToken, PropertyRewardBuyEnergyHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.FloatRaceScore, PropertyRewardFloatRaceHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.MissionMedal, PropertyRewardMissionHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.BattlePassScore, PropertyRewardBattlePassHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.MapExploreKeyReward, PropertyRewardMapExploreHandler.Create())
  self:_RegisterByPropertyType(EPropertyType.OrderBoostSmile, PropertyRewardSmileHandler.Create())
  self:_RegisterByPropertyTypeList({
    EPropertyType.JokerCommonCard,
    EPropertyType.JokerGoldenCard
  }, PropertyRewardJokerCardHandler.Create())
  self:_RegisterByPropertyTypeList(AlbumActivityModel.GetCacheProperty(), PropertyRewardAlbumPackHandler.Create())
  self:_RegisterByActivityDefinition(AvenueDefinition, PropertyRewardAvenueHandler.Create())
  self:_RegisterByActivityDefinition(UpwardDefinition, PropertyRewardUpwardHandler.Create())
  self:_RegisterByActivityDefinition(ExpedDefinition, PropertyRewardExpedHandler.Create(), {
    "ScorePropertyType"
  })
  self:_RegisterByActivityDefinition(RoadDefinition, PropertyRewardRoadHandler.Create())
  self:_RegisterByActivityDefinition(WheelDefinition, PropertyRewardWheelHandler.Create())
  self:_RegisterByActivityDefinition(RingDefinition, PropertyRewardRingHandler.Create())
  self:_RegisterByActivityDefinition(RoomDefinition, PropertyRewardRoomHandler.Create(), {
    "ActivityTokenPropertyType",
    "ActivityTokenPropertyKey"
  })
  self:_RegisterByActivityDefinition(FarmboardActivityDefinition, PropertyRewardFarmboardHandler.Create(), {
    "TokenProperty"
  })
  self:_RegisterByActivityDefinition(BreakDefinition, PropertyRewardBreakHandler.Create(), {
    "TokenProperty"
  })
  self:_RegisterByActivityDefinition(PairworkDefinition, PropertyRewardPairworkHandler.Create(), {
    "TokenProperty"
  })
  self:_RegisterByActivityDefinition(StickerboardActivityDefinition, PropertyRewardStickerboardHandler.Create())
  self:_RegisterByActivityDefinition(ComboActivityDefinition, PropertyRewardComboHandler.Create())
  self:_RegisterByActivityDefinition(TokenChainActivityDefinition, PropertyRewardTokenChainHandler.Create())
  self:_RegisterByActivityDefinition(DigActivityDefinition, PropertyRewardDigHandler.Create())
  local freefallHandler = PropertyRewardFreefallHandler.Create()
  for _, definition in pairs(FreefallActivityDefinition) do
    self:_RegisterByPropertyTypeList(definition.HitTokenProperties, freefallHandler)
  end
  self:_RegisterByActivityDefinition(FreefallActivityDefinition, freefallHandler, {
    "TokenProperty"
  })
  local mainDecorHandler = PropertyRewardMainDecorNewHandler.Create()
  self:_RegisterByPropertyType(EPropertyType.MainDecorGeneralToken, mainDecorHandler)
  self:_RegisterByActivityDefinition(MainDecorNewActivityDefinition, mainDecorHandler)
  local hitBricksHandler = PropertyRewardHitBricksHandler.Create()
  self:_RegisterByPropertyType(EPropertyType.HitBricksHammer, hitBricksHandler)
  self:_RegisterByActivityDefinition(HitBricksActivityDefinition, hitBricksHandler, {"coinToken"})
  local weeklyHandler = PropertyRewardWeeklyActiveQuestHandler.Create()
  self:_RegisterByPropertyType(EPropertyType.WeeklyActiveQuestStar, weeklyHandler)
  self:_RegisterByActivityDefinition(WeeklyActiveQuestDefinition, weeklyHandler, {
    "ScorePropertyType"
  })
  self:_RegisterByPropertyType(EPropertyType.noviceScore, PropertyRewardNoviceHandler.Create())
end

function PropertyRewardCategoryHandler:_RegisterByPropertyType(propertyType, handler)
  self.m_propertyHandlers[propertyType] = handler
end

function PropertyRewardCategoryHandler:_RegisterByPropertyTypeList(propertyTypeList, handler)
  for _, propertyType in ipairs(propertyTypeList) do
    self.m_propertyHandlers[propertyType] = handler
  end
end

function PropertyRewardCategoryHandler:_RegisterByActivityDefinition(definition, handler, propertyArgs)
  for _, definition in pairs(definition) do
    if not Table.IsEmpty(propertyArgs) then
      for _, arg in ipairs(propertyArgs) do
        if definition[arg] ~= nil then
          self.m_propertyHandlers[definition[arg]] = handler
        else
          Log.Error("PropertyRewardCategoryHandler:_RegisterByActivityDefinition: PropertyType\230\156\137\232\175\175/\231\188\186\229\176\145")
        end
      end
    else
      if definition.ActivityTokenPropertyType == nil then
        Log.Error("PropertyRewardCategoryHandler:_RegisterByActivityDefinition: \231\188\186\229\176\145ActivityTokenPropertyType")
        return
      end
      self.m_propertyHandlers[definition.ActivityTokenPropertyType] = handler
    end
  end
end

function PropertyRewardCategoryHandler:LogicHandle(rewardDatas, logicArgs)
  GM.PropertyDataManager:Acquire(rewardDatas, logicArgs.source, logicArgs.scene, logicArgs.boardType)
end

function PropertyRewardCategoryHandler:InViewHandle(rewardData, showArgs)
  local viewData = showArgs.viewData
  local rewardType = rewardData[PROPERTY_TYPE]
  local handler = self.m_propertyHandlers[rewardType]
  local noViewHandle = false
  if handler and handler.InViewHandle then
    handler:InViewHandle(rewardData, showArgs)
  elseif GM.ActivityModuleManager:IsShowBoardAreaEntryReward(rewardType, showArgs) then
    GM.ActivityModuleManager:InViewHandle(rewardData, showArgs)
  elseif GM.ActivityModuleManager:IsActivityModuleViewReward(rewardType) then
    self:ModuleRewardInViewHandler(rewardData, showArgs)
  elseif rewardType == EPropertyType.EnergyInfiniteTime then
    EventDispatcher.DispatchEvent(EEventType.EnergyInfiniteAcquire, {rewardData = rewardData, showArgs = showArgs})
  else
    local customData = {
      {
        flyDelay = showArgs.flyDelay,
        eventLock = viewData.eventLock,
        alwaysInMiddle = viewData.alwaysInMiddle,
        spriteScale = viewData.spriteScale
      }
    }
    if viewData.simpleCollect then
      GM.PropertyDataManager:PlayAcquireAnimation({rewardData}, customData)
    else
      GM.PropertyDataManager:PlayCollectAnimation({rewardData}, showArgs.uiWorldPosition, customData)
    end
  end
end

function PropertyRewardCategoryHandler:GetRewardIconNameAndIsSetNativeSize(rewardType)
  local handler = self.m_propertyHandlers[rewardType]
  if handler then
    return handler:GetRewardIconNameAndIsSetNativeSize(rewardType)
  else
    local iconName, nativeSize = GM.ActivityModuleManager:GetRewardBigIconNameAndNativeSize(rewardType)
    if iconName ~= nil then
      return iconName, nativeSize
    end
  end
  return EPropertySpriteBig[rewardType], true
end

function PropertyRewardCategoryHandler:ConvertDynamicHandle(reward, needBI)
  local rewardType = reward[PROPERTY_TYPE]
  local handler = self.m_propertyHandlers[rewardType]
  if handler then
    return handler:ConvertDynamicHandle(reward, needBI) or reward
  else
    local newReward = GM.ActivityModuleManager:ConvertDynamicReward(reward, needBI)
    if newReward ~= nil then
      return newReward
    end
  end
  return reward
end

function PropertyRewardCategoryHandler:CanShowTipButton(rewardType)
  local handler = self.m_propertyHandlers[rewardType]
  if handler then
    return handler:CanShowTipButton(rewardType)
  end
  if GM.ActivityModuleManager:CanShowTipButton(rewardType) then
    return true
  end
  return false
end
