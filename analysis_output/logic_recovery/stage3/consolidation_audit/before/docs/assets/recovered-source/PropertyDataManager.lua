PropertyDataManager = {}
PropertyDataManager.__index = PropertyDataManager

function PropertyDataManager:Init()
  Log.Info("PropertyDataManager\229\136\157\229\167\139\229\140\150")
  self.m_base64 = require("Model.Network.Base64")
end

function PropertyDataManager:IsPropertyType(type)
  if self.m_mapPropertyType == nil then
    self.m_mapPropertyType = {}
    for _, v in pairs(EPropertyType) do
      self.m_mapPropertyType[v] = true
    end
  end
  return self.m_mapPropertyType[type]
end

function PropertyDataManager:Acquire(arrProperties, source, scene, boardType)
  Log.Assert(source == EPropertySource.Buy or source == EPropertySource.Give, "should only acquire buy or give property")
  local recordUserProperty = false
  for i = 1, #arrProperties do
    local property = arrProperties[i]
    local type = property[PROPERTY_TYPE]
    local count = property[PROPERTY_COUNT]
    local eventActivityType, handler = self:_GetEventActivityHandler(type, "acquire")
    if eventActivityType ~= nil then
      local model = GM.ActivityManager:GetModel(eventActivityType)
      model[handler](model, count)
    elseif GM.ActivityManager:GetStartedAlbumActivity() ~= nil and AlbumActivityModel.IsCacheProperty(type) then
      GM.ActivityManager:GetStartedAlbumActivity():AcquireActivityCardPack(property, scene)
    elseif RewardApi.IsJokekRewardCard(type) then
      if GM.ActivityManager:GetStartedAlbumActivity() then
        GM.ActivityManager:GetStartedAlbumActivity():AddJokerCard(property, scene)
      end
    elseif GM.EnergyModel:PropertyTypeToEnergyType(type) ~= nil then
      GM.EnergyModel:AddEnergy(GM.EnergyModel:PropertyTypeToEnergyType(type), count, true)
      recordUserProperty = true
    elseif GM.EnergyModel:PropertyTypeToInfiniteEnergyType(type) ~= nil then
      GM.EnergyModel:AddEnergyInfiniteTime(GM.EnergyModel:PropertyTypeToInfiniteEnergyType(type), count)
    elseif type == EPropertyType.BakeOutToken then
      GM.ActivityManager:GetModel(ActivityType.BakeOut):AcquireToken(count)
    elseif GM.CharacterIntimacyModel:IsGiftType(type) then
      GM.CharacterIntimacyModel:AcquireGift(type, count)
    elseif DigTokenTypeToActivityType[type] ~= nil then
      GM.ActivityManager:GetModel(DigTokenTypeToActivityType[type]):AddDigPropNum(count, source == EPropertySource.Buy)
    elseif type == EPropertyType.BingoBall then
      GM.ActivityManager:GetModel(ActivityType.Bingo):AddBall(count)
    elseif type == EPropertyType.CustomizedPack then
      Log.Error("\229\174\154\229\136\182\229\141\161\229\140\133\228\184\141\229\186\148\232\175\165\232\181\176RewardApiLogic\232\142\183\229\143\150")
    elseif WheelTokenTypeToActivityType[type] ~= nil then
      GM.ActivityManager:GetModel(WheelTokenTypeToActivityType[type]):AcquireActivityToken(count, scene)
    elseif FarmboardActivityModel.IsActivityTokenType(type) then
      local model = GM.ActivityManager:GetStartedFarmboardActivity()
      if model then
        model:AcquireToken(count)
      end
    elseif type == EPropertyType.RoomTool then
      local model = GM.ActivityManager:GetStartedRoomActivity()
      if model then
        model:AcquireToken(count, source)
      end
    elseif type == EPropertyType.RoomKey then
      local model = GM.ActivityManager:GetStartedRoomActivity()
      if model then
        model:AcquireKey(count, source)
      end
    elseif type == EPropertyType.BuyEnergyToken then
      local buyEnergyProgressModel = GM.AccountManager:GetModel(ActivityType.BuyEnergyProgress)
      buyEnergyProgressModel:SetToken(buyEnergyProgressModel:GetToken() + count)
    elseif GM.ActivityModuleManager:IsActivityModuleLogicReward(type) then
      GM.ActivityModuleManager:AcquireModuleLogicReward(type, count, scene)
    elseif type == EPropertyType.FloatRaceScore then
      local model = GM.ActivityManager:GetModel(ActivityType.FloatRace)
      if model ~= nil then
        model:AcquireActivityToken(count)
      end
    elseif FreefallHitTokenTypeToActivityType[type] ~= nil then
      local model = GM.ActivityManager:GetModel(FreefallHitTokenTypeToActivityType[type])
      if model ~= nil then
        model:AcquireHitTokens({property})
      end
    elseif type == EPropertyType.WeeklyActiveQuestStar then
      WeeklyActiveQuestModel.AddStar(count)
    elseif type == EPropertyType.MissionMedal then
      local model = GM.ActivityManager:GetStartedMissionActivity()
      if model == nil then
        model = GM.ActivityManager:GetEndedMissionActivity()
      end
      if model ~= nil then
        model:AddMedalCount(count)
      end
    elseif type == EPropertyType.BattlePassScore then
      for activityType, definition in pairs(PassActivityDefinition) do
        local model = GM.ActivityManager:GetModel(activityType)
        if model ~= nil and model:GetBattleScoreOrder() == PassActivityModel.BattleScoreOrderId then
          model:_AcquireToken(count, false)
        end
      end
    elseif type == EPropertyType.OrderBoostSmile then
      local model = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
      model:AcquireSmileLogic(count)
    else
      local key = self:GetPropertyKey(type, source)
      GM.UserModel:ChangeNumber(key, count)
      self:OnPropertyChanged(type)
      if GameConfig.IsTestMode() and scene == EBIType.ItemCollect then
        if type == EPropertyType.Gem then
          GM.UserModel:ChangeNumber(EPropertyTestKey.GemAcquireFromBoardCollect, count)
        elseif type == EPropertyType.Gold then
          GM.UserModel:ChangeNumber(EPropertyTestKey.GoldAcquireFromBoardCollect, count)
        end
      end
      GM.DBTableManager:SaveAllWhenLateUpdate()
      recordUserProperty = true
    end
    GM.BIManager:LogAcquire(type, count, scene, source == EPropertySource.Give, boardType)
    if type == EPropertyType.Gold or type == EPropertyType.Gem or type == EPropertyType.Experience or GM.EnergyModel:PropertyTypeToEnergyType(type) ~= nil then
      CSPlatform:SDK_TrackEvent("virtual_resource_transaction", type .. ":" .. count)
    end
  end
  local message = {arrProperties = arrProperties, scene = scene}
  EventDispatcher.DispatchEvent(EEventType.PropertyAcquired, message)
  self:_Try2SendGoldScoreEvent(arrProperties, scene)
  if recordUserProperty then
    self:UpdateRecordUserProperties()
  end
end

function PropertyDataManager:_Try2SendGoldScoreEvent(arrProperties, scene)
  if scene == EBIType.ItemSell then
    return
  end
  local count = 0
  for _, property in ipairs(arrProperties) do
    if property[PROPERTY_TYPE] == EPropertyType.Gold or property[PROPERTY_TYPE] == EPropertyType.BakeOutToken then
      count = count + property[PROPERTY_COUNT]
    end
  end
  if 0 < count then
    EventDispatcher.DispatchEvent(EEventType.GoldScoreAcquired, {count = count, scene = scene})
  end
end

function PropertyDataManager:OnPropertyChanged(type)
  if type == EPropertyType.Gem or type == EPropertyType.Gold then
    GM.SyncModel:UpdateProgressLastModifiedTime()
  end
end

function PropertyDataManager:AcquireWithCollectAnimation(arrProperties, source, uiWorldPos, customData, scene)
  self:Acquire(arrProperties, source, scene)
  self:PlayCollectAnimation(arrProperties, uiWorldPos, customData)
end

function PropertyDataManager:AcquireWithSimpleAnimation(arrProperties, source, scene)
  self:Acquire(arrProperties, source, scene)
  self:PlayAcquireAnimation(arrProperties)
end

function PropertyDataManager:PlayCollectAnimation(arrProperties, uiWorldPos, customData)
  EventDispatcher.DispatchEvent(EEventType.PlayCollectAnimation, {
    arrProperties = arrProperties,
    uiWorldPos = uiWorldPos,
    customData = customData
  })
end

function PropertyDataManager:PlayAcquireAnimation(arrProperties, customData)
  for i, property in ipairs(arrProperties) do
    EventDispatcher.DispatchEvent(EEventType.PlayAcquireAnimation, {
      property = property,
      customData = (customData or Table.Empty)[i] or Table.Empty
    })
  end
end

function PropertyDataManager:PlayFloatUpAnimation(arrProperties, uiWorldPos, customData)
  EventDispatcher.DispatchEvent(EEventType.PlayFloatUpAnimation, {
    arrProperties = arrProperties,
    uiWorldPos = uiWorldPos,
    customData = customData
  })
end

function PropertyDataManager:PlayFlyScoreAnimation(arrProperties, uiWorldPos, customData)
  EventDispatcher.DispatchEvent(EEventType.PlayFlyScoreAnimation, {
    arrProperties = arrProperties,
    uiWorldPos = uiWorldPos,
    customData = customData
  })
end

function PropertyDataManager:DispatchConsumeEvent(propertyType, num, scene, ext, consumer)
  local message = {
    property = {
      [PROPERTY_TYPE] = propertyType,
      [PROPERTY_COUNT] = num
    },
    ext = ext
  }
  EventDispatcher.DispatchEvent(EEventType.PropertyConsumed, message)
  GM.BIManager:LogUseItem(propertyType, num, scene, consumer)
end

function PropertyDataManager:Consume(propertyType, num, scene, consumer)
  num = num or 1
  if num < 0 then
    Log.Error("PropertyDataManager:Consume num < 0")
    return false
  end
  if num == 0 then
    return true
  end
  if GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestInfiniteProperty, 0) == 1 and propertyType ~= EPropertyType.Experience and consumer ~= "test" then
    return true
  end
  local eventActivityType, handler = self:_GetEventActivityHandler(propertyType, "consume")
  if eventActivityType ~= nil then
    local model = GM.ActivityManager:GetModel(eventActivityType)
    local result = model[handler](model, num)
    if result then
      self:DispatchConsumeEvent(propertyType, num, scene, nil, consumer)
    end
    CSPlatform:SDK_TrackEvent("use_prop", propertyType .. ":" .. num)
    return result
  end
  if GM.CharacterIntimacyModel:IsGiftType(propertyType) then
    local result = GM.CharacterIntimacyModel:ConsumeGift(propertyType, num)
    if result then
      self:DispatchConsumeEvent(propertyType, num, scene, nil, consumer)
    end
    return result
  end
  if GM.EnergyModel:PropertyTypeToEnergyType(propertyType) ~= nil then
    local result, realCostNum = GM.EnergyModel:SubtractEnergy(GM.EnergyModel:PropertyTypeToEnergyType(propertyType), num)
    if result then
      self:DispatchConsumeEvent(propertyType, realCostNum, scene, {origin = num}, consumer)
      self:UpdateRecordUserProperties()
      CSPlatform:SDK_TrackEvent("virtual_resource_transaction", propertyType .. ":" .. -num)
    end
    return result
  end
  if num <= self:GetPropertyNum(propertyType) then
    local result = true
    local buyKey = self:GetPropertyKey(propertyType, EPropertySource.Buy)
    local buyNum = self:GetPropertyNum(propertyType, EPropertySource.Buy)
    if num <= buyNum then
      result = GM.UserModel:ChangeNumber(buyKey, -num)
    else
      local giveKey = self:GetPropertyKey(propertyType, EPropertySource.Give)
      result = GM.UserModel:ChangeNumber(buyKey, -buyNum) and GM.UserModel:ChangeNumber(giveKey, buyNum - num)
    end
    if result then
      self:OnPropertyChanged(propertyType)
      self:DispatchConsumeEvent(propertyType, num, scene, nil, consumer)
      if GameConfig.IsTestMode() and scene ~= EBIType.Test then
        if propertyType == EPropertyType.Gem then
          GM.UserModel:ChangeNumber(EPropertyTestKey.GemConsume, num)
        elseif propertyType == EPropertyType.Gold then
          GM.UserModel:ChangeNumber(EPropertyTestKey.GoldConsume, num)
        end
      end
      self:UpdateRecordUserProperties()
      if propertyType == EPropertyType.Gem then
        EventDispatcher.DispatchEvent(EEventType.GemConsumed, {num = num})
      end
      if propertyType == EPropertyType.Gold or propertyType == EPropertyType.Gem or propertyType == EPropertyType.Experience then
        CSPlatform:SDK_TrackEvent("virtual_resource_transaction", propertyType .. ":" .. -num)
      end
    end
    return result
  end
  return false
end

function PropertyDataManager:GetPropertyKey(key, source)
  if key == nil then
    return false
  end
  return key .. EPropertyKeySuffix[source]
end

function PropertyDataManager:GetPropertyNum(propertyType, propertySource)
  local eventActivityType, handler = self:_GetEventActivityHandler(propertyType, "get_number")
  if eventActivityType ~= nil then
    local model = GM.ActivityManager:GetModel(eventActivityType)
    return model[handler](model)
  end
  if GM.EnergyModel:PropertyTypeToEnergyType(propertyType) ~= nil then
    if propertySource == EPropertySource.Buy then
      return 0
    else
      return GM.EnergyModel:GetEnergy(GM.EnergyModel:PropertyTypeToEnergyType(propertyType))
    end
  end
  local propertyNum = {}
  propertyNum[EPropertySource.Give] = GM.UserModel:GetInNumber(self:GetPropertyKey(propertyType, EPropertySource.Give))
  propertyNum[EPropertySource.Buy] = GM.UserModel:GetInNumber(self:GetPropertyKey(propertyType, EPropertySource.Buy))
  if propertySource then
    return propertyNum[propertySource]
  else
    return propertyNum[EPropertySource.Give] + propertyNum[EPropertySource.Buy]
  end
end

function PropertyDataManager:PropertyToSyncDataTable(ePropertyType)
  local tb = {}
  for _, ePropertySource in pairs(EPropertySource) do
    tb[ePropertySource] = self:GetPropertyNum(ePropertyType, ePropertySource)
  end
  return tb
end

function PropertyDataManager:PropertyToSyncData(ePropertyType)
  return json.encode(self:PropertyToSyncDataTable(ePropertyType))
end

function PropertyDataManager:PropertyFromSyncData(ePropertyType, propertyJson)
  propertyJson = propertyJson or ""
  local tb = json.decode(propertyJson) or {}
  local mapContent = {}
  for ePropertySource, count in pairs(tb) do
    mapContent[self:GetPropertyKey(ePropertyType, ePropertySource)] = {value = count}
  end
  GM.UserModel:BatchSet(mapContent)
  return tb
end

function PropertyDataManager:GetPropertyNumFromSyncData(propertyJson)
  local total = 0
  local tb = json.decode(propertyJson) or {}
  for _, count in pairs(tb) do
    total = total + count
  end
  return total
end

function PropertyDataManager:MergeProperties(arrFrom, arrTo)
  local mapMerged = {}
  for i = 1, #arrTo do
    local ePropertyType = arrTo[i][PROPERTY_TYPE]
    local iAmount = arrTo[i][PROPERTY_COUNT]
    mapMerged[ePropertyType] = iAmount
  end
  for i = 1, #arrFrom do
    local ePropertyType = arrFrom[i][PROPERTY_TYPE]
    local iAmount = arrFrom[i][PROPERTY_COUNT]
    if mapMerged[ePropertyType] then
      mapMerged[ePropertyType] = mapMerged[ePropertyType] + iAmount
    else
      mapMerged[ePropertyType] = iAmount
    end
  end
  local arrMerged = {}
  for type, count in pairs(mapMerged) do
    arrMerged[#arrMerged + 1] = {
      [PROPERTY_TYPE] = type,
      [PROPERTY_COUNT] = count
    }
  end
  return arrMerged
end

function PropertyDataManager:GetPropertySpriteKey(ePropertyType)
  local strSprite = EPropertySprite[ePropertyType]
  if strSprite then
    return strSprite
  end
  return ""
end

function PropertyDataManager:GetRewardsText(arrProperties)
  local key = ""
  for i = 1, #arrProperties do
    local ePropertyType = arrProperties[i][PROPERTY_TYPE]
    local iAmount = arrProperties[i][PROPERTY_COUNT]
    key = key .. StringUtil.GetElementInTextStr(self:GetPropertySpriteKey(ePropertyType)) .. tostring(iAmount) .. "  "
  end
  return key
end

function PropertyDataManager:CreateNewUser()
  local mapContent = {}
  for _, v in pairs(EPropertyType) do
    mapContent[self:GetPropertyKey(v, EPropertySource.Give)] = {value = 0}
  end
  GM.UserModel:BatchSet(mapContent)
  local gem = GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.NewUserGem) or 200
  if 0 < gem then
    self:Acquire({
      {
        [PROPERTY_TYPE] = EPropertyType.Gem,
        [PROPERTY_COUNT] = gem,
        [PROPERTY_CRYPT] = Crypt.CryptCurrency(gem)
      }
    }, EPropertySource.Give, EBIType.CreateNewUser)
  end
end

function PropertyDataManager:_GetEventActivityHandler(property, use)
  for activityType, activityDefinition in pairs(MainDecorActivityDefinition) do
    if property == activityDefinition.ActivityTokenPropertyType then
      if use == "acquire" then
        return activityType, "AcquireActivityToken"
      elseif use == "consume" then
        return activityType, "ConsumeActivityToken"
      elseif use == "get_number" then
        return activityType, "GetActivityTokenNumber"
      end
    end
  end
  for activityType, activityDefinition in pairs(MainDecorNewActivityDefinition) do
    if property == activityDefinition.ActivityTokenPropertyType then
      if use == "acquire" then
        return activityType, "AcquireActivityToken"
      elseif use == "consume" then
        return activityType, "ConsumeActivityToken"
      elseif use == "get_number" then
        return activityType, "GetActivityTokenNumber"
      end
    end
  end
  for activityType, activityDefinition in pairs(HitBricksActivityDefinition) do
    if property == activityDefinition.coinToken and use == "acquire" then
      return activityType, "AcquireActivityToken"
    end
  end
  for activityType, activityDefinition in pairs(WheelDefinition) do
    if property == activityDefinition.ActivityTokenPropertyType and use == "acquire" then
      return activityType, "AcquireActivityToken"
    end
  end
  for activityType, activityDefinition in pairs(RingDefinition) do
    if property == activityDefinition.ActivityTokenPropertyType and use == "acquire" then
      return activityType, "AcquireActivityToken"
    end
  end
  for activityType, activityDefinition in pairs(UpwardDefinition) do
    if property == activityDefinition.ActivityTokenPropertyType and use == "acquire" then
      return activityType, "AcquireActivityToken"
    end
  end
  for activityType, activityDefinition in pairs(WeeklyActiveQuestDefinition) do
    if property == activityDefinition.ScorePropertyType and use == "acquire" then
      return activityType, "AcquireActivityScore"
    end
  end
  local definitions = {
    {
      AvenueDefinition,
      {
        acquire = "AcquireActivityToken"
      }
    },
    {
      RoadDefinition,
      {
        acquire = "AcquireActivityToken"
      }
    },
    {
      ComboActivityDefinition,
      {
        acquire = "AcquireActivityToken"
      }
    }
  }
  for _, definition in ipairs(definitions) do
    for activityType, activityDefinition in pairs(definition[1]) do
      local checkProperty = activityDefinition.ActivityTokenPropertyType or activityDefinition.coinToken
      if property == checkProperty and definition[2][use] then
        return activityType, definition[2][use]
      end
    end
  end
  if property == EPropertyType.ScoreRaceScore and use == "acquire" then
    return ActivityType.ScoreRace, "AcquireActivityScore"
  end
  return nil
end

function PropertyDataManager:UpdateRecordUserProperties()
  if not GM or not GM.UserModel then
    return
  end
  GM.MiscModel:SetCryptRecordProperty(self:_CryptPropertyStr(self:_GetPropertyConcatStr()))
end

function PropertyDataManager:CheckRecordUserProperties()
  local record = GM.MiscModel:GetCryptRecordProperty()
  local cur = self:_GetPropertyConcatStr()
  if not StringUtil.IsNilOrEmpty(record) and record ~= self:_CryptPropertyStr(cur) then
    record = self:_DecryptPropertyStr(record)
    if GameConfig.IsTestMode() then
      GM.UIManager:ShowPrompt("\232\181\132\228\186\167\230\163\128\230\181\139\229\164\177\232\180\165\239\188\140\231\156\139\229\184\166\230\156\137[CheckProperty]\231\154\132\230\151\165\229\191\151")
      Log.Info([[
[CheckProperty]some property changed in unexpected way:
record:]] .. record .. [[

cur:]] .. cur)
    end
    GM.BIManager:LogProject(EBIProjectType.PropertyCheat, {r = record, c = cur})
  end
end

local arrRecordDataKey, arrRecordDataValue

function PropertyDataManager:_GetPropertyConcatStr()
  if arrRecordDataKey == nil then
    arrRecordDataKey = {
      EUserSyncDataKey.UserLevel,
      self:GetPropertyKey(EPropertyType.Experience, EPropertySource.Give),
      self:GetPropertyKey(EPropertyType.Experience, EPropertySource.Buy),
      self:GetPropertyKey(EPropertyType.Gem, EPropertySource.Give),
      self:GetPropertyKey(EPropertyType.Gem, EPropertySource.Buy),
      self:GetPropertyKey(EPropertyType.Gold, EPropertySource.Give),
      self:GetPropertyKey(EPropertyType.Gold, EPropertySource.Buy)
    }
    arrRecordDataValue = {}
  end
  arrRecordDataValue[1] = GM.EnergyModel:GetEnergy(EnergyType.Main)
  local userModel = GM.UserModel
  for i, k in ipairs(arrRecordDataKey) do
    arrRecordDataValue[i + 1] = userModel:GetInNumber(k)
  end
  return table.concat(arrRecordDataValue, ",")
end

function PropertyDataManager:_CryptPropertyStr(str)
  local result
  SafeCall(function()
    result = self.m_base64.encode(Crypt.CryptCurrency(str))
  end, function(err)
    result = ""
  end)
  return result
end

function PropertyDataManager:_DecryptPropertyStr(str)
  local result
  SafeCall(function()
    result = Crypt.CryptCurrency(self.m_base64.decode(str))
  end, function(err)
    result = ""
  end)
  return result
end
