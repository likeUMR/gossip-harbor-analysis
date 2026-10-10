SpreadFailedReason = {
  ItemClosed = 1,
  ItemOpening = 2,
  ItemRecharging = 3,
  BoardFull = 4
}
ItemSpreadEventType = {StateChanged = 1, SpeedUp = 2}
ItemSpreadState = {
  Initializing = 4,
  Closed = 1,
  Opening = 2,
  Opened = 3
}
ItemSpreadWeightType = {
  Fixed = 1,
  Decremental = 2,
  OrderItem = 3,
  ChestCustomItem = 4,
  SmartItem = 5
}
ItemSpread = setmetatable({}, BaseItemComponent)
ItemSpread.__index = ItemSpread
ItemSpread.OrderItemDiffScoreLimit = 300

function ItemSpread.Create(itemConfig)
  local itemSpread = setmetatable({}, ItemSpread)
  itemSpread:Init(itemConfig)
  return itemSpread
end

function ItemSpread:Init(itemConfig)
  self.event = PairEvent.Create(self)
  self.m_chainId = GM.ItemDataModel:GetChainId(itemConfig.Type)
  self.m_auto = itemConfig.Spread_Auto
  self.m_initDuration = itemConfig.Spread_InitDuration
  self.m_initSpeedUpCost = itemConfig.Spread_InitSpeedUpCost
  self.m_openDuration = itemConfig.Spread_OpenDuration
  self.m_openSpeedUpCost = itemConfig.Spread_OpenSpeedUpCost
  self.m_costEnergy = itemConfig.Spread_CostEnergy
  self.m_itemMaxNumber = itemConfig.Spread_ItemMaxNumber
  self.m_itemRecoveryDuration = itemConfig.Spread_ItemRecoveryDuration
  self.m_itemSpeedUpCost = itemConfig.Spread_ItemSpeedUpCost
  self.m_storageMaxNumber = itemConfig.Spread_StorageMaxNumber
  self.m_storageRecoveryDuration = itemConfig.Spread_StorageRecoveryDuration
  self.m_storageSpeedUpCost = itemConfig.Spread_StorageSpeedUpCost
  self.m_transformNumber = itemConfig.Spread_TransformNumber
  local forcedDuration = TutorialBoardHelper.GetForcedTimerDuration()
  if forcedDuration ~= nil then
    self.m_initDuration = self.m_initDuration and forcedDuration
    self.m_openDuration = self.m_openDuration and forcedDuration
    self.m_itemRecoveryDuration = self.m_itemRecoveryDuration and forcedDuration
    self.m_storageRecoveryDuration = self.m_storageRecoveryDuration and forcedDuration
  end
  self.m_codeWeightPairs = Table.DeepCopy(itemConfig.Spread_Weight)
  self.m_weightType = itemConfig.Spread_WeightType
  self.m_itemRestNumber = self.m_itemMaxNumber
  self.m_storageRestNumber = self.m_storageMaxNumber
  self.m_spreadCount = 0
  if self.m_initDuration ~= nil then
    self.m_state = ItemSpreadState.Initializing
    self:UpdatePerSecond()
  elseif self.m_openDuration ~= nil then
    self.m_state = ItemSpreadState.Closed
  else
    self.m_state = ItemSpreadState.Opened
  end
end

function ItemSpread:Update()
  if self:IsAutoSpread() then
    while self:_TryAutoSpread() do
    end
  end
end

function ItemSpread:UpdatePerSecond()
  if self.m_startTimer == nil then
    if self.m_state == ItemSpreadState.Initializing or self.m_state == ItemSpreadState.Opening or self.m_state == ItemSpreadState.Opened and (self.m_itemRestNumber < self.m_itemMaxNumber or self.m_storageRestNumber == 0) and not self:IsDisposable() then
      self.m_startTimer = GM.GameModel:GetServerTime()
      if self.m_itemModel ~= nil then
        self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
      end
      self.event:Call(ItemSpreadEventType.StateChanged)
    end
    return
  end
  local itemAccelerateTime = self.m_itemModel:GetComponent(ItemAccelerateTime)
  if self:CanAccelerate() and itemAccelerateTime ~= nil and itemAccelerateTime:IsAccelerated() then
    local endTime = math.min(itemAccelerateTime:GetTime(), GM.GameModel:GetServerTime())
    self.m_startTimer = self.m_startTimer + itemAccelerateTime:GetLastUpdateTime() - endTime
    self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
  end
  if self:GetTimerAmount() == 1 then
    self:_UpdateRecoveryState()
    self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
  end
  self.event:Call(ItemSpreadEventType.StateChanged)
end

function ItemSpread:CanAccelerate()
  return self.m_startTimer ~= nil
end

function ItemSpread:ShowCountdownAnimation()
  local itemAccelerateTime = self.m_itemModel:GetComponent(ItemAccelerateTime)
  return self:CanAccelerate() and itemAccelerateTime:IsAccelerated()
end

function ItemSpread:ShowCountDown()
  local notShow = self:GetItemRestNumber() > 0 and self:GetState() ~= ItemSpreadState.Initializing and self:GetState() ~= ItemSpreadState.Opening or self:GetItemRestNumber() == 0 and self:IsDisposable()
  return not notShow
end

function ItemSpread:_UpdateRecoveryState()
  if self.m_state == ItemSpreadState.Initializing or self.m_state == ItemSpreadState.Opening then
    self.m_startTimer = nil
    self.m_state = ItemSpreadState.Opened
    EventDispatcher.DispatchEvent(EEventType.ItemOpened, {
      item = self.m_itemModel
    })
    self.m_itemModel:GetBoardModel():UpdateOpeningItem()
    return
  end
  if self.m_storageRestNumber == 0 then
    self.m_startTimer = nil
    self.m_storageRestNumber = self.m_storageMaxNumber
    self.m_itemRestNumber = self.m_itemMaxNumber
    return
  end
  local recoveryNumber = self.m_itemMaxNumber - self.m_itemRestNumber
  self.m_itemRestNumber = self.m_itemMaxNumber
  self.m_storageRestNumber = self.m_storageRestNumber - recoveryNumber
  if self.m_storageRestNumber <= 0 then
    self.m_storageRestNumber = 0
    self.m_startTimer = self.m_startTimer + self.m_itemRecoveryDuration
    self:UpdatePerSecond()
  else
    self.m_startTimer = nil
  end
end

function ItemSpread:OnTap()
  local spreadCount = 1
  if GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestSuperTap, 0) == 1 then
    spreadCount = 10
    if self.m_itemModel:GetBoardModel().BoardType == EBoardType.Tutorial then
      spreadCount = 1
    end
  end
  for i = 1, spreadCount do
    local canContinue = self:_TrySpread()
    if not canContinue then
      break
    end
  end
  if not self:IsDisposable() and self:CanAccelerate() then
    local restDuration = self:GetTimerDuration() + self:GetStartTimer() - GM.GameModel:GetServerTime()
    if 1200 <= restDuration and self.m_itemRestNumber == 0 then
      GM.NotificationModel:TryOpenIOSNotificationWindow(ENotiSceneDescKey.ItemCoolDown)
    end
  end
end

function ItemSpread:OnOpen()
  self.m_state = ItemSpreadState.Opening
  self:UpdatePerSecond()
  EventDispatcher.DispatchEvent(EEventType.ItemOpening)
  self.m_itemModel:GetBoardModel():UpdateOpeningItem()
  GM.BIManager:LogAction(EBIType.OpenItem, self.m_itemModel:GetId())
end

function ItemSpread:OnSpeedUp(isFree)
  self:_SpeedUp(isFree)
end

function ItemSpread:_SpeedUp(isFree)
  if not isFree then
    local cost = self:GetSpeedUpCost()
    local gemNumber = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Gem)
    if cost > gemNumber then
      local boardModel = self.m_itemModel:GetBoardModel()
      boardModel.event:Call(BoardEventType.LackGem, {
        LackNumber = cost - gemNumber,
        Scene = EGemCostScene.TimeSkip
      })
      return
    end
    GM.PropertyDataManager:Consume(EPropertyType.Gem, cost, EBIType.SpeedUp, self.m_itemModel:GetCode())
  end
  if self.m_startTimer ~= nil then
    self:OnTimeSkip(nil, isFree and ItemSkipType.ad or ItemSkipType.Gem)
    self.event:Call(ItemSpreadEventType.SpeedUp)
  end
end

function ItemSpread:OnTimeSkip(duration, BISkipType)
  if self.m_startTimer ~= nil then
    if duration == nil then
      duration = self:GetTimerDuration()
      self.m_startTimer = GM.GameModel:GetServerTime()
    end
    self.m_startTimer = self.m_startTimer - duration
    self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
    GM.AudioModel:PlayEffect(AudioFileConfigName.sfxItemSpeedUp)
    self:UpdatePerSecond()
    if not self.m_itemModel:GetBoardModel().IgnoreBI then
      GM.BIManager:LogAction(EBIType.SpeedUp, {
        t = self.m_itemModel:GetType(),
        d = duration,
        s = BISkipType
      })
    end
  end
end

function ItemSpread:TryUnlockCdByZroCd()
  if self.m_itemRestNumber == 0 then
    self:TryUseCDBuff()
  end
end

function ItemSpread:TryUseCDBuff()
  if not self:CanSupportCDBuff() and not self:CanSupportGeneratorBoostCDBuff() and not self:CanTestSupportCDFree() then
    return
  end
  if self.m_itemRestNumber == 0 then
    self:OnTimeSkip(nil, ItemSkipType.Buff)
  end
  self.event:Call(ItemSpreadEventType.StateChanged)
end

function ItemSpread:OnTimeSkipInZeroRestNumber()
  if not GM.ItemDataModel:IsGeneratorItem(self.m_itemModel:GetType()) then
    return
  end
  if not self:CostEnergy() then
    return
  end
  if GM.MainBoardModel ~= self.m_itemModel:GetBoardModel() then
    return
  end
  if self.m_itemRestNumber == 0 then
    self:OnTimeSkip(nil, ItemSkipType.Buff)
  end
  self.event:Call(ItemSpreadEventType.StateChanged)
end

function ItemSpread:EmptySpreadCount()
  self.m_itemRestNumber = 0
  self.m_storageRestNumber = 0
  if self.m_weightType == ItemSpreadWeightType.Decremental then
    self.m_codeWeightPairs = {}
  end
  self:UpdatePerSecond()
  self.event:Call(ItemSpreadEventType.StateChanged)
  self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
end

function ItemSpread:IsAutoSpread()
  return self.m_auto == 1
end

function ItemSpread:GetOpenDuration()
  return self.m_openDuration
end

function ItemSpread:CostEnergy()
  local forcedCostEnergy = TutorialBoardHelper.GetForcedCostEnergy()
  if forcedCostEnergy ~= nil then
    return forcedCostEnergy
  end
  return self.m_costEnergy == 1
end

function ItemSpread:GetCodeWeightPairs()
  return self.m_codeWeightPairs or {}
end

function ItemSpread:GetItemRestNumber()
  return self.m_itemRestNumber
end

function ItemSpread:GetStorageRestNumber()
  return self.m_storageRestNumber
end

function ItemSpread:GetSpreadCount()
  return self.m_spreadCount
end

function ItemSpread:GetSpreadMaxNum()
  return self.m_itemMaxNumber
end

function ItemSpread:GetState()
  return self.m_state
end

function ItemSpread:GetStartTimer()
  return self.m_startTimer
end

function ItemSpread:GetWeightType()
  return self.m_weightType
end

function ItemSpread:GetTransformNumber()
  return self.m_transformNumber
end

function ItemSpread:GetAutoSpreadDecrementalRemainTypes()
  if not self:IsAutoSpread() or self.m_weightType ~= ItemSpreadWeightType.Decremental or self.m_itemRestNumber == 0 then
    return nil
  end
  local remainTypes = {}
  for _, item in ipairs(self.m_codeWeightPairs) do
    for i = 1, item.Weight do
      remainTypes[#remainTypes + 1] = item.Code
    end
  end
  return remainTypes
end

function ItemSpread:CanSupportCDBuff()
  if GM.BuffManager:IsBuffActiveByType(EBuffProperty.BuffItemcd) and self.m_itemModel:GetBoardModel() == GM.MainBoardModel and self:CostEnergy() and not self:IsDisposable() then
    return true
  end
  return false
end

function ItemSpread:CanSupportSmart()
  return GM.BuffManager:IsBuffActiveByType(EBuffProperty.buff_smart) and self.m_itemModel:GetBoardModel() == GM.MainBoardModel and (self:CostEnergy() and not self:IsDisposable() or self.m_itemModel:GetType() == ItemType.RawFish05)
end

function ItemSpread:CanSupportGeneratorBoost()
  return GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition) and self.m_itemModel:GetBoardModel() == GM.MainBoardModel and (self:CostEnergy() and not self:IsDisposable() or self.m_itemModel:GetType() == ItemType.RawFish05)
end

function ItemSpread:CanSupportGeneratorBoostCDBuff()
  local generatorBoost = GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition)
  return self:CanSupportGeneratorBoost() and generatorBoost:IsNoCDActive()
end

function ItemSpread:CanSupportBoostDisco()
  local bSupport = self.m_itemModel:GetBoardModel() == GM.MainBoardModel
  local handler = GM.BoostChargeManager:GetHandler(EBoostChargeType.BoostCharge_disco)
  return bSupport and handler:CanSupportItem(self.m_itemModel:GetType())
end

function ItemSpread:CanTestSupportCDFree()
  return GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestSpreadItemCDFree, 0) == 1 and self:CostEnergy() and not self:IsDisposable()
end

function ItemSpread:IsDisposable()
  return self.m_itemRecoveryDuration == nil
end

function ItemSpread:GetTimerAmount()
  if self.m_startTimer == nil then
    return 1
  end
  local elapsedTime = GM.GameModel:GetServerTime() - self.m_startTimer
  return self:_GetTimerAmount(elapsedTime)
end

function ItemSpread:GetNextTimerAmount()
  if self.m_startTimer == nil then
    return 1
  end
  local nextElapsedTime = GM.GameModel:GetServerTime() - self.m_startTimer + 1
  return self:_GetTimerAmount(nextElapsedTime)
end

function ItemSpread:_GetTimerAmount(elapsedTime)
  local duration = self:GetTimerDuration()
  if duration == nil then
    local data = {
      init = tostring(self.m_initDuration),
      open = tostring(self.m_openDuration),
      storage = tostring(self.m_storageRecoveryDuration),
      item = tostring(self.m_itemRecoveryDuration),
      storageRestNumber = self.m_storageRestNumber,
      state = self.m_state,
      type = self.m_itemModel:GetType()
    }
    Log.Error("duration is nil:" .. json.encode(data))
    self.m_startTimer = nil
    return 1
  end
  if duration == 0 then
    return 1
  end
  return math.min(elapsedTime / duration, 1)
end

function ItemSpread:GetTimerDuration()
  if self.m_state == ItemSpreadState.Initializing then
    return self.m_initDuration
  elseif self.m_state == ItemSpreadState.Opening then
    return self.m_openDuration
  elseif self.m_state == ItemSpreadState.Opened then
    if self.m_storageRestNumber == 0 then
      return self.m_storageRecoveryDuration
    else
      return self.m_itemRecoveryDuration
    end
  else
    Log.Assert(false, "ItemSpread:GetTimerDuration unknown state")
  end
end

function ItemSpread:GetSpeedUpCost()
  local speedUpCost = GM.TutorialModel:GetForceSkipCost()
  if speedUpCost ~= nil then
    return speedUpCost
  end
  speedUpCost = 0
  if self.m_state == ItemSpreadState.Initializing then
    speedUpCost = self.m_initSpeedUpCost
  elseif self.m_state == ItemSpreadState.Opening then
    speedUpCost = self.m_openSpeedUpCost
  elseif self.m_state == ItemSpreadState.Opened then
    if self.m_storageRestNumber == 0 then
      speedUpCost = self.m_storageSpeedUpCost
    else
      speedUpCost = self.m_itemSpeedUpCost
    end
  end
  speedUpCost = speedUpCost or 0
  local timerAmount = self:GetTimerAmount()
  speedUpCost = (1 - timerAmount) * speedUpCost
  speedUpCost = math.ceil(speedUpCost)
  return math.max(speedUpCost, 1)
end

function ItemSpread:IsChestUsedOnce()
  return self.m_openDuration ~= nil and self.m_itemRestNumber ~= self.m_itemMaxNumber
end

function ItemSpread:CheckLuckyProduce()
  if self.m_itemModel:GetBoardModel().BoardType == EBoardType.Tutorial then
    return false
  end
  if self:CanSupportBoostDisco() then
    return false
  end
  local luckyProduceType, spreadType = GM.ActivityManager:GetModel(ActivityType.LuckyProduce):Try2ProduceLuckyItem(self.m_itemModel)
  if luckyProduceType == nil then
    return false
  end
  return true, luckyProduceType, spreadType
end

function ItemSpread:TryGenerateLuckyItem(maxEnergyBoostRatio, luckyProduceType, spreadType)
  maxEnergyBoostRatio = GM.ActivityManager:GetModel(ActivityType.LuckyProduce):GetAdjustedMaxEnergyBoostRatio(maxEnergyBoostRatio)
  if 0 < maxEnergyBoostRatio then
    local itemDataModel = GM.ItemDataModel
    for i = 1, maxEnergyBoostRatio do
      luckyProduceType = itemDataModel:GetModelConfig(luckyProduceType).MergedType or luckyProduceType
    end
  end
  return luckyProduceType, spreadType, maxEnergyBoostRatio
end

function ItemSpread:SafeSpreadItem()
  if self.m_itemRestNumber > self.m_itemMaxNumber then
    local action = {
      rest = self.m_itemRestNumber,
      max = self.m_itemMaxNumber
    }
    local actionString = GM.BIManager:TableToString(action)
    GM.BIManager:LogAction(EBIType.ItemRestNumberOverflowError, actionString)
    self.m_itemRestNumber = self.m_itemMaxNumber
  end
  if self.m_storageRestNumber ~= nil and self.m_storageRestNumber > self.m_storageMaxNumber then
    local action = {
      rest = self.m_storageRestNumber,
      max = self.m_storageMaxNumber
    }
    local actionString = GM.BIManager:TableToString(action)
    GM.BIManager:LogAction(EBIType.StorageRestNumberOverflowError, actionString)
    self.m_storageRestNumber = self.m_storageMaxNumber
  end
end

function ItemSpread:SpreadCheckEnergyRatioAndCode(code, maxEnergyBoostRatio, bCanEnergyBoost)
  self.m_testLastSpreadCodeOrigin = code
  local originCode = code
  local energyBoostRatio = 0
  local itemDataModel = GM.ItemDataModel
  if 0 < maxEnergyBoostRatio and bCanEnergyBoost and ItemModelFactory.GetCodePrefixTargetType(code) == nil then
    energyBoostRatio = maxEnergyBoostRatio
    local boardModel = self.m_itemModel:GetBoardModel()
    if boardModel.GetOrderCodeLackCountMap ~= nil then
      local chainId = itemDataModel:GetChainId(code)
      local chainLevel = itemDataModel:GetChainLevel(code)
      local chainMaxLevel = itemDataModel:GetChainMaxLevel(chainId)
      local chainItemTypes = itemDataModel:GetChain(chainId)
      local lackCountMap = boardModel:GetOrderCodeLackCountMap()
      local itemCodeCountMap = boardModel:GetCodeCountMap(true, false, false)
      local orderRequiredMap = Table.Empty
      if boardModel.GetOrderCodeRequireCountMap ~= nil then
        orderRequiredMap = boardModel:GetOrderCodeRequireCountMap()
      end
      for i = 0, maxEnergyBoostRatio do
        if chainMaxLevel >= chainLevel + i then
          local checkType = itemDataModel:GetTypeByChainAndLevel(chainId, chainLevel + i)
          if lackCountMap[checkType] or chainLevel + i < maxEnergyBoostRatio + 1 and itemCodeCountMap[checkType] ~= nil and math.max(itemCodeCountMap[checkType] - (orderRequiredMap[checkType] or 0), 0) % 2 == 1 then
            energyBoostRatio = i
            break
          end
        end
      end
    end
    for i = 1, energyBoostRatio do
      code = GM.ItemDataModel:GetModelConfig(code).MergedType or code
    end
  end
  self.m_testLastSpreadCodeEnergyBoost = code
  self.m_testLastSpreadFishNetProduceSmartCode = nil
  local logSpreadExtScene
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.FishNetProduceSmart) and ItemModelFactory.GetCodePrefixTargetType(code) == nil then
    local chainId = itemDataModel:GetChainId(code)
    if chainId == ItemChain.RwaFish then
      local boardModel = self.m_itemModel:GetBoardModel()
      local itemCodeCountMap = boardModel:GetCodeCountMap(true, false, false)
      local maxFishLevel = itemDataModel:GetChainMaxLevel(chainId)
      local totalLevelOneItemCount = 0
      for level = 1, maxFishLevel - 1 do
        local fishItemType = itemDataModel:GetTypeByChainAndLevel(chainId, level)
        totalLevelOneItemCount = totalLevelOneItemCount + (itemCodeCountMap[fishItemType] or 0) * MathUtil.IntPow(2, level - 1)
      end
      local maxLevelFishOneCount = MathUtil.IntPow(2, maxFishLevel - 1)
      local lackMaxLevelOneCount = maxLevelFishOneCount - totalLevelOneItemCount % maxLevelFishOneCount
      if MathUtil.IsPowerOfTwo(lackMaxLevelOneCount) and lackMaxLevelOneCount ~= maxLevelFishOneCount then
        local minOriginSpreadLevel = 1
        local maxOriginSpreadLevel = 3
        local minEnergyBoostRatioSpreadLevel = minOriginSpreadLevel + energyBoostRatio
        local maxEnergyBoostRatioSpreadLevel = maxOriginSpreadLevel + energyBoostRatio
        maxEnergyBoostRatioSpreadLevel = math.min(maxEnergyBoostRatioSpreadLevel, maxFishLevel)
        if lackMaxLevelOneCount >= MathUtil.IntPow(2, minEnergyBoostRatioSpreadLevel - 1) then
          for spreadLevel = minEnergyBoostRatioSpreadLevel, maxEnergyBoostRatioSpreadLevel do
            local newCode = itemDataModel:GetTypeByChainAndLevel(chainId, spreadLevel)
            if MathUtil.IntPow(2, spreadLevel - 1) == lackMaxLevelOneCount and spreadLevel < itemDataModel:GetChainLevel(code) then
              code = newCode
              self.m_testLastSpreadFishNetProduceSmartCode = newCode
              logSpreadExtScene = ELogSpreadExtScene.FishNetProduceSmart
              break
            end
          end
        end
      end
    end
  end
  return code, energyBoostRatio, logSpreadExtScene
end

function ItemSpread:CosetRestNumber(costCount, energyBoostRatio, code)
  self.m_spreadCount = self.m_spreadCount + 1
  if costCount ~= nil then
    self.m_itemRestNumber = math.max(self.m_itemRestNumber - costCount, 0)
    return
  end
  local costRestNumber
  if self.m_weightType ~= ItemSpreadWeightType.OrderItem then
    if self:IsDisposable() then
      costRestNumber = math.floor(2 ^ energyBoostRatio)
    else
      costRestNumber = GM.EnergyBoostModel:NextEnergyBoostCostIndex(energyBoostRatio)
    end
  else
    for _, item in ipairs(self.m_codeWeightPairs) do
      if item.Code == code then
        costRestNumber = item.Weight
        break
      end
    end
  end
  self.m_itemRestNumber = math.max(self.m_itemRestNumber - costRestNumber, 0)
end

function ItemSpread:TryGenerateDiscoItem()
  local bSupport, code, level = GM.BoostChargeManager:GetHandler(EBoostChargeType.BoostCharge_disco):TryGetSpreadItem(self.m_itemModel:GetType())
  if bSupport then
    return 1, code, BoardSpreadType.Disco, 0
  end
  return 2
end

function ItemSpread:DealActivityLimit(code, energyBoostRatio, costCount)
  if self:CanSupportBoostDisco() then
    local discoHandler = GM.BoostChargeManager:GetHandler(EBoostChargeType.BoostCharge_disco)
    code, energyBoostRatio = discoHandler:TryUseDiscoItem(self.m_itemModel:GetType(), code, energyBoostRatio)
    costCount = 0
  end
  return code, energyBoostRatio, costCount
end

function ItemSpread:GenerateItemCode(maxEnergyBoostRatio)
  maxEnergyBoostRatio = maxEnergyBoostRatio or 0
  local canLuckyProduce, luckyProduceType, spreadType = self:CheckLuckyProduce()
  if canLuckyProduce then
    return self:TryGenerateLuckyItem(maxEnergyBoostRatio, luckyProduceType, spreadType)
  end
  if self:CanSupportBoostDisco() then
    local bSupport, code, tempspreadType, energyBoostRatio = self:TryGenerateDiscoItem()
    if bSupport == 1 then
      return code, tempspreadType, energyBoostRatio
    end
    if bSupport == 2 then
      spreadType = BoardSpreadType.Disco
      maxEnergyBoostRatio = 3
    end
  end
  self:SafeSpreadItem()
  local code, bCanEnergyBoost, costCount, tempSpreadType = self:_GenerateItemCode()
  local originalElement = code
  spreadType = spreadType or tempSpreadType
  local logSpreadExtScene
  local energyBoostRatio = maxEnergyBoostRatio
  code, energyBoostRatio, logSpreadExtScene = self:SpreadCheckEnergyRatioAndCode(code, maxEnergyBoostRatio, bCanEnergyBoost)
  code, energyBoostRatio, costCount = self:DealActivityLimit(code, energyBoostRatio, costCount)
  self:CosetRestNumber(costCount, energyBoostRatio, code)
  self:UpdatePerSecond()
  self.event:Call(ItemSpreadEventType.StateChanged)
  self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
  if logSpreadExtScene then
    return code, spreadType and spreadType or BoardSpreadType.Normal, energyBoostRatio, originalElement, logSpreadExtScene
  end
  return code, spreadType and spreadType or BoardSpreadType.Normal, energyBoostRatio
end

function ItemSpread:_GenerateItemCode()
  local code = GM.TutorialModel:GetForceSpreadItemCode()
  if code ~= nil then
    return code, false
  end
  local costCount
  if self.m_weightType == ItemSpreadWeightType.Fixed then
    local spreadType
    local generatorBoostActivity = GM.ActivityManager:GetStartedActivityByDefinition(GeneratorBoostActivityDefinition)
    local bCanGeneratorBoost = self:CanSupportGeneratorBoost() and generatorBoostActivity ~= nil and generatorBoostActivity:IsBuffActive(EGeneratorBoostBuffType.SmartProduce)
    local bCanSmartBuff = self:CanSupportSmart()
    if bCanGeneratorBoost or bCanSmartBuff then
      code = RandomGenerateCodeHelper.TrySmartProduceItem(self.m_itemModel)
      if code ~= nil then
        if bCanGeneratorBoost then
          spreadType = generatorBoostActivity:TryExtraProduceItem(self.m_itemModel) and BoardSpreadType.GeneratorBoostExtraSmart or BoardSpreadType.GeneratorBoostSmart
        elseif bCanSmartBuff then
          spreadType = BoardSpreadType.BuffSmart
        end
        return code, true, nil, spreadType
      end
    end
    code = self:_FixedGenerateItemCode()
    if bCanGeneratorBoost then
      spreadType = generatorBoostActivity:TryExtraProduceItem(self.m_itemModel) and BoardSpreadType.GeneratorBoostExtraNormal or BoardSpreadType.Normal
    end
    return code, true, nil, spreadType
  elseif self.m_weightType == ItemSpreadWeightType.Decremental then
    code = Table.ListWeightSelectOne(self.m_codeWeightPairs).Code
    for index, item in ipairs(self.m_codeWeightPairs) do
      if code == item.Code then
        item.Weight = item.Weight - 1
        if item.Weight == 0 then
          table.remove(self.m_codeWeightPairs, index)
        end
        self.m_itemModel:GetBoardModel():SaveItemProperty(self.m_itemModel)
        break
      end
    end
  elseif self.m_weightType == ItemSpreadWeightType.OrderItem then
    code = self:GetOrderItemCode()
  elseif self.m_weightType == ItemSpreadWeightType.ChestCustomItem then
    local listItemType, testStr = RandomGenerateCodeHelper.GenerateChestCustomCodeRule(self.m_itemRestNumber, 1, false)
    if listItemType == nil or listItemType[1] == nil then
      code = "205"
      Log.Error("\233\148\153\232\175\175\231\154\132\231\148\159\230\136\144\230\163\139\229\173\144")
    else
      code = listItemType[1]
    end
    local orderItemConfig = self.m_itemModel:GetBoardModel():GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
    costCount = orderItemConfig[code].DiffScore
    if GameConfig.IsTestMode() then
      Log.Debug("\230\163\139\229\173\144\229\165\150\229\138\177\229\150\183\229\143\145\239\188\154" .. "\229\136\134\229\128\188\228\184\138\233\153\144: " .. tostring(self.m_itemRestNumber) .. "\n" .. testStr .. "\n\230\156\128\229\144\142\233\128\137\230\139\169\231\154\132\230\163\139\229\173\144:" .. code .. "\n\232\138\177\232\180\185\231\154\132\229\136\134:" .. costCount)
    end
  elseif self.m_weightType == ItemSpreadWeightType.SmartItem then
    if self.m_SmarOrderConfig == nil then
      local currentDiffScoreLimit = self.m_storageMaxNumber
      self.m_SmarOrderConfig = {}
      local orderItemConfig = self.m_itemModel:GetBoardModel():GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
      for code, config in pairs(orderItemConfig) do
        if config.DiffScore ~= nil and currentDiffScoreLimit >= config.DiffScore then
          self.m_SmarOrderConfig[code] = config.DiffScore
        end
      end
    end
    code = SmartRewardHelper.GetCodesFor_ItemSpread(self.m_SmarOrderConfig, self.m_itemRestNumber, "itemSpread")[1]
    costCount = self.m_SmarOrderConfig[code] or 1
  end
  return code, false, costCount
end

function ItemSpread:GetOrderItemCode()
  assert(self.m_itemModel:GetBoardModel() == GM.MainBoardModel, "\230\157\131\233\135\141\231\177\187\229\158\139\228\184\186OrderItem\231\154\132\230\175\141\228\189\147\230\163\139\229\173\144\229\191\133\233\156\128\228\189\141\228\186\142\228\184\187\230\163\139\231\155\152\228\184\138")
  local orderCodeWeight = {}
  local orderCodeLackCountMap = GM.MainBoardModel:CalculateOrderCodeLackNumMap(false, true, false)
  local itemsInBoostOrder = GM.MainBoardModel:GetOrderBoostOrderCodeLackMap()
  local itemCodeConfigMap = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
  for code, _ in pairs(orderCodeLackCountMap) do
    local codeConfig = itemCodeConfigMap[code]
    if codeConfig ~= nil then
      local diffScore = math.min(codeConfig.DiffScore, ItemSpread.OrderItemDiffScoreLimit)
      table.insert(orderCodeWeight, {
        Code = code,
        Weight = diffScore * (itemsInBoostOrder[code] == nil and 1 or 1000)
      })
    end
  end
  self:_Log("\232\174\162\229\141\149\230\163\139\229\173\144\229\174\157\231\174\177\229\150\183\229\143\145\230\151\165\229\191\151")
  self:_Log("\232\174\162\229\141\149\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144\229\143\138\229\133\182\229\175\185\229\186\1481\231\186\167\230\163\139\229\173\144\230\149\176\233\135\143")
  self:_Log(orderCodeLackCountMap)
  self:_Log("\232\174\162\229\141\149\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144\229\143\138\229\133\182\230\157\131\233\135\141")
  local orderCodeWeightMap = {}
  for _, item in ipairs(orderCodeWeight) do
    orderCodeWeightMap[item.Code] = item.Weight
  end
  self:_Log(orderCodeWeightMap)
  local code
  while code == nil and #orderCodeWeight ~= 0 do
    local item = Table.ListWeightSelectOne(orderCodeWeight)
    Table.ListRemove(orderCodeWeight, item)
    code = self:_TryGenerateItemCodeByOrderItem(item.Code)
    if code ~= nil then
      self:_Log("\233\128\137\229\143\150\229\176\157\232\175\149\229\144\136\230\136\144\231\154\132\231\155\174\230\160\135\230\163\139\229\173\144" .. item.Code .. ", \231\188\186\229\164\177\230\149\176\233\135\143\233\153\141\228\189\142 " .. MathUtil.IntPow(2, GM.ItemDataModel:GetChainLevel(code) - 1))
    end
  end
  if code == nil then
    self:_Log("\230\178\161\230\156\137\229\143\175\233\128\137\230\139\169\231\154\132\232\174\162\229\141\149\230\163\139\229\173\144\239\188\140\229\156\168\230\137\128\230\156\137\233\133\141\231\189\174\231\154\132\230\163\139\229\173\144\228\184\173\232\191\155\232\161\140\233\128\137\230\139\169")
    code = self:_TryGenerateItemCodeAll()
  end
  self:_Log("\233\128\137\230\139\169" .. code .. "\228\189\156\228\184\186\229\150\183\229\143\145\231\154\132\230\163\139\229\173\144")
  self:_FlushLog()
  return code
end

function ItemSpread:_FixedGenerateItemCode()
  local itemStateCollection = self.m_itemModel:GetComponent(ItemStateCollection)
  if itemStateCollection ~= nil then
    return GM.ItemFixedSpreadModel:GenerateItemCode(itemStateCollection:GetStateType())
  end
  return GM.ItemFixedSpreadModel:GenerateItemCode(self.m_itemModel:GetType())
end

function ItemSpread:_TryGenerateItemCodeByOrderItem(itemCode)
  local targetChainId = GM.ItemDataModel:GetChainId(itemCode)
  local levelLimit = GM.ItemDataModel:GetChainLevel(itemCode)
  local itemCodes = {}
  for _, item in ipairs(self.m_codeWeightPairs) do
    if GM.ItemDataModel:GetModelConfig(item.Code, true) ~= nil then
      local chainId = GM.ItemDataModel:GetChainId(item.Code)
      if chainId == targetChainId then
        local level = GM.ItemDataModel:GetChainLevel(item.Code)
        if levelLimit > level then
          table.insert(itemCodes, item.Code)
        end
      end
    end
  end
  self:_Log("\229\176\157\232\175\149\233\128\137\230\139\169\232\174\162\229\141\149\230\163\139\229\173\144" .. itemCode .. "\239\188\140\229\143\175\232\131\189\229\150\183\229\143\145\231\154\132\230\163\139\229\173\144\229\136\151\232\161\168")
  self:_Log(itemCodes, true)
  return Table.ListRandomSelectOne(itemCodes)
end

function ItemSpread:_TryGenerateItemCodeAll()
  local generatorValidCodes = {}
  for _, pair in ipairs(self.m_codeWeightPairs) do
    if GM.ItemDataModel:GetModelConfig(pair.Code, true) ~= nil then
      local chainId = GM.ItemDataModel:GetChainId(pair.Code)
      local generators = GM.ItemDataModel:GetChainGenerators(chainId)
      for _, generator in ipairs(generators) do
        if GM.ItemDataModel:IsUnlocked(generator) then
          table.insert(generatorValidCodes, pair.Code)
          break
        end
      end
    end
  end
  self:_Log("\230\175\141\228\189\147\230\163\139\229\173\144\229\183\178\229\173\152\229\156\168\231\154\132\230\163\139\229\173\144")
  self:_Log(generatorValidCodes, true)
  if #generatorValidCodes == 0 then
    return Table.ListRandomSelectOne(self.m_codeWeightPairs).Code
  else
    return Table.ListRandomSelectOne(generatorValidCodes)
  end
end

function ItemSpread:_TryAutoSpread()
  if self.m_itemRestNumber == 0 or self.m_state ~= ItemSpreadState.Opened then
    return false
  end
  local boardModel = self.m_itemModel:GetBoardModel()
  local position = self:_GetAutoSpreadPosition(boardModel)
  local bAllowAutoSpreadToCache = self:IsDisposable() and self.m_weightType == ItemSpreadWeightType.Decremental and boardModel.CacheItemFromSpread ~= nil and GM.ConfigModel:IsServerControlOpen(EGeneralConfType.AutoSpreadToCache)
  if position == nil and not bAllowAutoSpreadToCache then
    return false
  end
  if bAllowAutoSpreadToCache and position == nil then
    local remainTypes = self:GetAutoSpreadDecrementalRemainTypes()
    boardModel:CacheItemFromSpread(remainTypes, self.m_itemModel)
    self.m_spreadCount = self.m_spreadCount + #remainTypes
    self:EmptySpreadCount()
  else
    local args = {logSpread = true, energyBoostRatio = 0}
    if self.m_itemModel:GetComponent(ItemDig) ~= nil then
      args.costEnergy = false
      args.spreadType = BoardSpreadType.Dig
    end
    local newItemCode = self:GenerateItemCode()
    boardModel:SpreadItem(self.m_itemModel, position, newItemCode, args)
  end
  if self.m_itemModel:GetComponent(ItemDig) == nil and self.m_transformNumber ~= nil and self.m_transformNumber == self.m_spreadCount then
    self.m_itemModel:GetComponent(ItemTransform):Transform()
    return false
  end
  return true
end

function ItemSpread:CheckSpreadState()
  if self.m_state == ItemSpreadState.Closed then
    self:_NotifySpreadFailed(SpreadFailedReason.ItemClosed)
    return false
  end
  if self.m_state == ItemSpreadState.Opening then
    self:_NotifySpreadFailed(SpreadFailedReason.ItemOpening)
    return false
  end
  if self.m_state == ItemSpreadState.Initializing or self.m_itemRestNumber == 0 then
    if not self:IsDisposable() then
      self:_NotifySpreadFailed(SpreadFailedReason.ItemRecharging)
    end
    return false
  end
  return true
end

function ItemSpread:CheckSpreadPosAndAuto()
  local boardModel = self.m_itemModel:GetBoardModel()
  if self:IsAutoSpread() then
    local autoSpreadPosition = self:_GetAutoSpreadPosition(boardModel)
    if autoSpreadPosition ~= nil then
      return false
    end
  end
  local position = boardModel:FindEmptyPositionInSpreadOrder(self.m_itemModel:GetPosition())
  if position == nil then
    self:_NotifySpreadFailed(SpreadFailedReason.BoardFull)
    return false
  end
  return true, position
end

function ItemSpread:CheckEnergy()
  local costEnergy = self:CostEnergy()
  if self:CanSupportBoostDisco() then
    costEnergy = false
  end
  if not costEnergy then
    return true, 0, false
  end
  local boardModel = self.m_itemModel:GetBoardModel()
  local maxCostCount
  local maxEnergyBoostRatio = 0
  maxCostCount, maxEnergyBoostRatio = ItemSpread.GetCostEnergyNum(self.m_itemModel:GetType())
  if not GM.EnergyModel:HasEnoughEnergy(boardModel:GetCostEnergyType(), maxCostCount) then
    GM.EnergyModel.popupBundleEnergyWindowForLackingEnergy = true
    boardModel.event:Call(BoardEventType.LackEnergy)
    return false
  end
  GM.EnergyModel.popupBundleEnergyWindowForLackingEnergy = false
  return true, maxEnergyBoostRatio, costEnergy
end

function ItemSpread:SpreadCostEnergy(energyBoostRatio, costEnergy)
  local boardModel = self.m_itemModel:GetBoardModel()
  local propertyType = GM.EnergyModel:EnergyTypeToPropertyType(boardModel:GetCostEnergyType())
  self.m_testLastCostEnergyCount = 0
  if costEnergy then
    local costCount = EnergyBoostModel.GetBoostCostNum(energyBoostRatio)
    GM.PropertyDataManager:Consume(propertyType, costCount, EBIType.SpreadItem, self.m_itemModel:GetCode())
    self.m_testLastCostEnergyCount = costCount
  end
  return costEnergy
end

function ItemSpread:_TrySpread()
  if not self:CheckSpreadState() then
    return false
  end
  local bCheckPos, position = self:CheckSpreadPosAndAuto()
  if not bCheckPos then
    return false
  end
  local bCheckEnergy, maxEnergyBoostRatio, costEnergy = self:CheckEnergy()
  if not bCheckEnergy then
    return false
  end
  local boardModel = self.m_itemModel:GetBoardModel()
  local newItemCode, spreadType, energyBoostRatio, originalElement, specialScene = self:GenerateItemCode(maxEnergyBoostRatio)
  self:SpreadCostEnergy(energyBoostRatio, costEnergy)
  GM.ActivityManager:GetModel(ActivityType.LuckyProduce):RecordBoostRatioAdjustData(energyBoostRatio, spreadType, costEnergy, self:GetItemModel():GetType())
  position = GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ItemLandOpt) and self.m_itemModel:GetBoardModel().BoardType ~= EBoardType.Tutorial and self.m_itemModel:GetBoardModel():FindEmptySpreadPosition(newItemCode, self.m_itemModel:GetPosition()) or position
  local args = {
    logSpread = true,
    energyBoostRatio = energyBoostRatio,
    costEnergy = costEnergy,
    spreadType = spreadType,
    originalElement = originalElement,
    specialScene = specialScene
  }
  boardModel:SpreadItem(self.m_itemModel, position, newItemCode, args)
  EventDispatcher.DispatchEvent(EEventType.VibrationLight)
  if not self:TryRemoveSelf() then
    return false
  end
  self:TryUseCDBuff()
  return true
end

function ItemSpread:TryRemoveSelf()
  local boardModel = self.m_itemModel:GetBoardModel()
  if self.m_transformNumber ~= nil and self.m_transformNumber == self.m_spreadCount then
    self.m_itemModel:GetComponent(ItemTransform):Transform()
    return false
  elseif self.m_itemRestNumber == 0 and self:IsDisposable() then
    boardModel:RemoveItem(self.m_itemModel)
    boardModel.event:Call(BoardEventType.CollapseItem, {
      Source = self.m_itemModel
    })
    return false
  end
  return true
end

function ItemSpread:_GetAutoSpreadPosition(boardModel)
  return boardModel:FindSpreadPosition(self, self.m_itemModel)
end

function ItemSpread:_NotifySpreadFailed(reason)
  local boardModel = self.m_itemModel:GetBoardModel()
  local eventInfo = {
    Item = self.m_itemModel,
    Reason = reason
  }
  boardModel.event:Call(BoardEventType.SpreadFailed, eventInfo)
  EventDispatcher.DispatchEvent(EEventType.SpreadFailed, eventInfo)
  EventDispatcher.DispatchEvent(EEventType.VibrationHeavy)
end

function ItemSpread.GetCostEnergyNum(itemType)
  local nCostNum = 1
  local nEnergyBoostRatio = 0
  if itemType == nil then
    if GM.EnergyBoostModel:IsEnergyBoostModeOn() then
      nCostNum = GM.EnergyBoostModel:GetEnergyBoostCostNum()
      nEnergyBoostRatio = GM.EnergyBoostModel:GetEnergyBoostPowerRatio()
    end
  elseif GM.EnergyBoostModel:CanEnergyBoost(itemType) then
    nCostNum = GM.EnergyBoostModel:GetEnergyBoostCostNum()
    nEnergyBoostRatio = GM.EnergyBoostModel:GetEnergyBoostPowerRatio()
  end
  return nCostNum, nEnergyBoostRatio
end

function ItemSpread:_Log(element, isList)
  if not GameConfig.IsTestMode() then
    return
  end
  if self.m_log == nil then
    self.m_log = ""
  end
  if type(element) == "string" then
    self.m_log = self.m_log .. element
  elseif isList then
    for _, item in ipairs(element) do
      self.m_log = self.m_log .. tostring(item) .. ", "
    end
  else
    for key, value in pairs(element) do
      self.m_log = self.m_log .. tostring(key) .. " : " .. tostring(value) .. ", "
    end
  end
  self.m_log = self.m_log .. "\n"
end

function ItemSpread:_FlushLog()
  if not GameConfig.IsTestMode() then
    return
  end
  print(self.m_log)
  self.m_log = ""
end

function ItemSpread:GetTestLastSpreadInfo()
  return {
    lastSpreadCodeOrigin = self.m_testLastSpreadCodeOrigin,
    lastSpreadCodeEnergyBoost = self.m_testLastSpreadCodeEnergyBoost,
    lastSpreadFishNetProduceSmartCode = self.m_testLastSpreadFishNetProduceSmartCode,
    lastCostEnergyCount = self.m_testLastCostEnergyCount
  }
end
