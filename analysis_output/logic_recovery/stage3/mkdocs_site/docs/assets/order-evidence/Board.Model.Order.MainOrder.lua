MainOrder = setmetatable({}, SlotOrder)
MainOrder.__index = MainOrder

function MainOrder.Create(orderModel, slot, id, requirements, innerType, avatarId, bIsLukcy, bIsBaseline, diffRange)
  local order = setmetatable({}, MainOrder)
  order:Init(orderModel, slot, id, requirements, innerType, avatarId, bIsLukcy, bIsBaseline, diffRange)
  return order
end

function MainOrder:Init(orderModel, slot, id, requirements, innerType, avatarId, bIsLukcy, bIsBaseline, diffRange)
  SlotOrder.Init(self, slot, id, requirements)
  self.m_orderModel = orderModel
  self.m_innerType = innerType
  self.m_avatarId = avatarId
  self.m_bIsLucky = bIsLukcy
  self.m_bIsBaseline = bIsBaseline
  self.m_diffRange = diffRange
end

function MainOrder:UpdateRequirements(requirements)
  SlotOrder.UpdateRequirements(self, requirements)
  for activityType, _ in pairs(AlbumActivityDefinition) do
    local AlbumModel = GM.ActivityManager:GetModel(activityType)
    if AlbumModel and AlbumModel:IsActivityOpen() then
      local slot = self:GetSlot()
      AlbumModel:ClearOrderReward(slot)
    end
  end
end

function MainOrder:SetGiftRewardInfo(giftRewards)
  self.m_giftRewards = giftRewards
end

function MainOrder:GetInnerType()
  return self.m_innerType
end

function MainOrder:GetType()
  if self:GetInnerType() == MainOrderType.Fixed then
    return OrderType.Fixed
  elseif self:GetInnerType() == MainOrderType.Special or self:GetInnerType() == MainOrderType.Branch then
    return OrderType.Special
  else
    return OrderType.Random
  end
end

function MainOrder:GetAvatarId()
  return self.m_avatarId
end

function MainOrder:UpdateAvatarId(avatarId)
  self.m_avatarId = avatarId
end

function MainOrder:GetAvatarName()
  local avatarConfig = self.m_orderModel:GetAvatarConfig()
  if avatarConfig.ChestCustomerAvatars[self.m_avatarId] ~= nil then
    return avatarConfig.ChestCustomerAvatars[self.m_avatarId]
  elseif self:GetInnerType() == MainOrderType.Special then
    return avatarConfig.SpecialAvatars[self.m_avatarId]
  elseif self:GetInnerType() == MainOrderType.Branch then
    return avatarConfig.BranchAvatars[self.m_avatarId]
  elseif avatarConfig.BakeOutAvatars[self.m_avatarId] ~= nil then
    return avatarConfig.BakeOutAvatars[self.m_avatarId]
  elseif self:GetInnerType() == MainOrderType.CharacterIntimacyRandom and avatarConfig.CharacterIntimacyAvatars[self.m_avatarId] ~= nil then
    return avatarConfig.CharacterIntimacyAvatars[self.m_avatarId]
  elseif self:GetInnerType() == MainOrderType.TimedOrder and avatarConfig.TimedOrderAvatars[self.m_avatarId] ~= nil then
    return avatarConfig.TimedOrderAvatars[self.m_avatarId]
  elseif self:GetInnerType() == MainOrderType.ExtraCustomer and avatarConfig.ExtraCustomerAvatars[self.m_avatarId] ~= nil then
    return avatarConfig.ExtraCustomerAvatars[self.m_avatarId]
  elseif self:GetInnerType() == MainOrderType.Contiorder then
    if self.m_contiorderAvatarName == nil then
      local model, def = GM.ActivityManager:GetStartedContiorders()
      self.m_contiorderAvatarName = model and def.OrderAvatarName or nil
    end
    return self.m_contiorderAvatarName
  else
    local avatarConfig = self.m_orderModel:GetNormalAvatarConfig(self.m_avatarId)
    return avatarConfig ~= nil and avatarConfig.Avatar or nil
  end
end

function MainOrder:GetMaxPossibleRewardNumber()
  local number = 1
  for activityType, _ in pairs(MainDecorActivityDefinition) do
    local activity = GM.ActivityManager:GetModel(activityType)
    if activity:CanAddScore() then
      number = number + 1
    end
  end
  for activityType, _ in pairs(MainDecorNewActivityDefinition) do
    local activity = GM.ActivityManager:GetModel(activityType)
    if activity:CanAddScore() then
      number = number + 1
    end
  end
  local buffRewards = self:GetBuffRewards()
  if buffRewards ~= nil then
    number = number + #buffRewards
  end
  return number
end

function MainOrder:_HasGoldReward()
  return self:GetInnerType() ~= MainOrderType.CharacterIntimacyRandom or not GM.CharacterIntimacyModel:IsOpen()
end

function MainOrder:GetPrice()
  local price = 0
  local itemCodeConfigMap = self.m_orderModel:GetItemCodeConfigMap()
  for _, itemCode in ipairs(self.m_requirements) do
    local config = itemCodeConfigMap[itemCode]
    if config == nil then
      GM.BIManager:LogErrorInfo("cfg_err", "no item code config " .. itemCode)
      return 0
    end
    if self.m_bIsBaseline and config.RecommendedPrice ~= nil then
      price = price + config.RecommendedPrice
    else
      price = price + config.Price
    end
  end
  return price
end

function MainOrder:CanSupportAlbumBuff()
  local albumModel = GM.ActivityManager:GetStartedAlbumActivity()
  if albumModel == nil or Table.IsEmpty(albumModel:GetMainOrderScore2AlbumPack(self:GetDiffScore(), self:GetSlot() or "orderType" .. self:GetInnerType(), false)) then
    return false
  end
  return GM.BuffManager:IsBuffActiveByType(EBuffProperty.buff_album) and self:GetInnerType() ~= MainOrderType.TimedOrder and self:GetInnerType() ~= MainOrderType.Special
end

function MainOrder:GetRewards()
  if self.m_state == OrderState.Finished then
    return Table.DeepCopy(self.m_cacheRewards)
  end
  local type = self:GetInnerType()
  if type == MainOrderType.Special then
    return Table.Empty
  end
  local rewards = {}
  local price = self:GetPrice()
  local diffScore = self:GetDiffScore()
  local mainDecorActivity, mainDecorActivityDefinition = GM.ActivityManager:GetStartedMainDecorActivity()
  if mainDecorActivity and mainDecorActivity:CanAddScore() then
    local tokenNum = mainDecorActivity:GetMainOrderCoinToEventToken(price, diffScore)
    if 0 < tokenNum then
      table.insert(rewards, {
        [PROPERTY_TYPE] = mainDecorActivityDefinition.ActivityTokenPropertyType,
        [PROPERTY_COUNT] = tokenNum,
        [PROPERTY_CRYPT] = Crypt.CryptCurrency(tokenNum)
      })
    end
  end
  local floatRaceModel = GM.ActivityManager:GetModel(ActivityType.FloatRace)
  if floatRaceModel and floatRaceModel:CanAddScore() then
    local score = floatRaceModel:GetAddScoreByOrder(self)
    if score ~= nil then
      table.insert(rewards, score)
    end
  end
  local skipAlbumReward = false
  if type == MainOrderType.TimedOrder and self.GetTimedOrderRewards ~= nil then
    local timedOrderRewards = self:GetTimedOrderRewards()
    for _, reward in ipairs(timedOrderRewards) do
      if AlbumActivityModel.IsCacheProperty(reward[PROPERTY_TYPE]) then
        skipAlbumReward = true
      end
    end
  end
  if not skipAlbumReward then
    local AlbumModel = GM.ActivityManager:GetStartedAlbumActivity()
    if AlbumModel and AlbumModel:IsActivityOpen() then
      local albumReward = AlbumModel:GetMainOrderScore2AlbumPack(diffScore, self:GetSlot() or "orderType" .. self:GetInnerType(), true)
      local tempalbumReward = Table.DeepCopy(albumReward)
      if not Table.IsEmpty(tempalbumReward) then
        if self:CanSupportAlbumBuff() then
          tempalbumReward[PROPERTY_COUNT] = tempalbumReward[PROPERTY_COUNT] * 2
        end
        table.insert(rewards, tempalbumReward)
      end
    end
  end
  local avenueModel = GM.ActivityManager:GetStartedAvenueActivity()
  if avenueModel then
    local avenueScore = avenueModel:GetAddScoreByOrder(self)
    if 0 < avenueScore then
      table.insert(rewards, {
        [PROPERTY_TYPE] = avenueModel:GetTokenPropertyType(),
        [PROPERTY_COUNT] = avenueScore
      })
    end
  end
  local upwardModel = GM.ActivityManager:GetStartedUpwardActivity()
  if upwardModel then
    local upwardScore = upwardModel:GetAddScoreByOrder(self)
    if upwardScore ~= nil then
      table.insert(rewards, upwardScore)
    end
  end
  local roadModel = GM.ActivityManager:GetStartedRoadActivity()
  if roadModel then
    local roadScore = roadModel:GetAddScoreByOrder(self)
    if 0 < roadScore then
      table.insert(rewards, {
        [PROPERTY_TYPE] = roadModel:GetTokenPropertyType(),
        [PROPERTY_COUNT] = roadScore
      })
    end
  end
  local hitBricksModel = GM.ActivityManager:GetStartedHitBricksActivity()
  if hitBricksModel and hitBricksModel:GetAddScoreByOrder(self) then
    local hammerReward = hitBricksModel:GetAddScoreByOrder(self)
    table.insert(rewards, hammerReward)
  end
  local ringModel = GM.ActivityManager:GetStartedRingActivity()
  if ringModel then
    local ringReward = ringModel:GetAddScoreByOrder(self)
    if ringReward then
      table.insert(rewards, ringReward)
    end
  end
  local comboModel = GM.ActivityManager:GetStartedComboActivity()
  if comboModel then
    local comboReward = comboModel:GetAddScoreByOrder(self)
    if comboReward then
      table.insert(rewards, comboReward)
    end
  end
  local activityModuleRewards = GM.ActivityModuleManager:GetRewardsByOrder(self)
  Table.ListAppend(rewards, activityModuleRewards)
  local chestCustomModel = GM.ActivityManager:GetModel(ActivityType.ChestCustomer)
  if chestCustomModel and chestCustomModel:IsChestCustomerOrder(self:GetSlot()) then
    table.insert(rewards, {
      [PROPERTY_TYPE] = ChestCustomerModel.RewardKey .. tostring(self:GetInnerType()) .. "_" .. tostring(self:GetSlot()),
      [PROPERTY_COUNT] = 1
    })
  end
  if self:_HasGoldReward() then
    local nMultiple = 1
    if GM.BuffManager:IsBuffActiveByType(EBuffProperty.BuffGold) then
      nMultiple = 2
    end
    local count = math.ceil(price * nMultiple)
    table.insert(rewards, {
      [PROPERTY_TYPE] = self:GetFirstRewardPropertyType(),
      [PROPERTY_COUNT] = count,
      [PROPERTY_CRYPT] = Crypt.CryptCurrency(count)
    })
  end
  return rewards
end

function MainOrder:GetOrderRewardByFinishOrder()
  local rewards = self:GetRewards()
  local targetRewards, otherMapReward = {}, {}
  for _, reward in ipairs(rewards) do
    local isChestCustomReward = StringUtil.StartWith(reward[PROPERTY_TYPE], ChestCustomerModel.RewardKey)
    if not isChestCustomReward then
      table.insert(targetRewards, reward)
    elseif isChestCustomReward then
      if otherMapReward[ChestCustomerModel.RewardKey] == nil then
        otherMapReward[ChestCustomerModel.RewardKey] = {}
      end
      table.insert(otherMapReward[ChestCustomerModel.RewardKey], reward)
    end
  end
  return targetRewards, otherMapReward
end

function MainOrder:IsBuffGoldDouble()
  return self:_HasGoldReward() and GM.BuffManager:IsBuffActiveByType(EBuffProperty.BuffGold)
end

function MainOrder:GetGiftRewards()
  return self.m_giftRewards
end

function MainOrder:GetBuffRewards()
  return GM.BuffManager:GetBuffRewards(self)
end

function MainOrder:GetSupportBuffId()
  return GM.BuffManager:GetSupportBuffId(self)
end

function MainOrder:GetCookingFrenzyConfig()
  local model = GM.ActivityManager:GetModel(ActivityType.CookingFrenzy)
  return model:GetCurBuffConifgByOrder(self)
end

function MainOrder:GetCookingBIConfig()
  local model = GM.ActivityManager:GetModel(ActivityType.CookingFrenzy)
  local buffID
  if model:GetCurBuffConifgByOrder(self) then
    buffID = model:GetCurBuffConifgByOrder(self).buff_id
  end
  return buffID, model:GetBIRewardByOrder(self)
end

function MainOrder:SetOrderBoostFinish(score)
  self.m_bSupportSmile = score
end

function MainOrder:GetSupportOrderBoost()
  local model = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  if model:GetAddOrderBoostScoreByOrder(self) > 0 then
    return model:GetAddOrderBoostScoreByOrder(self)
  end
  return self.m_bSupportSmile
end

function MainOrder:IsOrderBoostPro()
  local model = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  if model == nil then
    return false
  end
  return model:GetLogicType() == EOrderBoostType.Super
end

function MainOrder:GetOrderBoostFinishRound()
  local model = GM.ActivityManager:GetModel(ActivityType.OrderBoost)
  if self:GetSupportOrderBoost() then
    return model:GetFinishRound()
  end
  return nil
end

function MainOrder:IsButterfly()
  local model = GM.ActivityManager:GetStartedButterflyActivity()
  return model and model:GetButterflySlot() == self:GetSlot() or false
end

function MainOrder:GetFirstRewardPropertyType()
  if self:GetInnerType() ~= MainOrderType.Special and GM.ActivityManager:GetModel(ActivityType.BakeOut):CanAcquireToken() then
    return EPropertyType.BakeOutToken
  end
  return EPropertyType.Gold
end

function MainOrder:GetScore(includeGold)
  local rewards
  if self:GetInnerType() == MainOrderType.Special then
    local orderConfig = GM.MainBoardModel:GetSpecialOrderConfig(self)
    rewards = orderConfig.Rewards
  else
    rewards = self:GetRewards()
  end
  return self:_CalculateScore(rewards, includeGold)
end

function MainOrder:GetDiffScore()
  local score = 0
  local type = self:GetInnerType()
  if type == MainOrderType.Special then
    return score
  end
  local itemCodeConfigMap = self.m_orderModel:GetItemCodeConfigMap()
  for _, itemCode in ipairs(self.m_requirements) do
    local config = itemCodeConfigMap[itemCode]
    if config == nil then
      GM.BIManager:LogErrorInfo("cfg_err", "no item code config " .. itemCode)
      return 0
    end
    if config.DiffScore ~= nil then
      score = score + config.DiffScore
    end
  end
  return score
end

function MainOrder:GetTestDiffScore()
  local testScore = ""
  local score = 0
  local type = self:GetInnerType()
  if type == MainOrderType.Special then
    return score
  end
  local itemCodeConfigMap = self.m_orderModel:GetItemCodeConfigMap()
  for _, itemCode in ipairs(self.m_requirements) do
    local config = itemCodeConfigMap[itemCode]
    if config ~= nil and config.DiffScore ~= nil then
      testScore = testScore .. itemCode .. ":" .. config.DiffScore .. ","
      score = score + config.DiffScore
    end
  end
  return testScore, score
end

function MainOrder:IsLuckyOrder()
  return self.m_bIsLucky
end

function MainOrder:IsBaselineOrder()
  return self.m_bIsBaseline
end

function MainOrder:GetDiffRange()
  return self.m_diffRange
end
