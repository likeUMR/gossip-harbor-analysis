CardItemModel = setmetatable({}, BaseActivityModel)
CardItemModel.__index = CardItemModel
CardItemModel.StrKeys = {
  CacheData = "CardItemCacheData",
  isPopFirstMergeWindow = "isPopFirstMergeWindow",
  isPlayFirstTutorial = "isPlayFirstTutorial"
}

function CardItemModel:Init(dbTable)
  self:LoadCacheData(dbTable)
  self:LoadCardItemConfig()
  BaseActivityModel.Init(self, ActivityType.CardItem, dbTable)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self.OnItemMerge)
  EventDispatcher.AddListener(EEventType.CardItemUsed, self, self.OnItemUsed)
  EventDispatcher.AddListener(EEventType.CardItemGenerate, self, self.OnCardItemGenerate)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self.OnItemSpread)
end

function CardItemModel:LoadCacheData(dbTable)
  self.m_cacheData = json.decode(dbTable:GetValue(CardItemModel.StrKeys.CacheData, "value") or "") or {}
  self.m_mapPopChain = json.decode(dbTable:GetValue(CardItemModel.StrKeys.isPopFirstMergeWindow, "value") or "") or {}
end

function CardItemModel:SaveCacheData()
  self.m_dbTable:Set(CardItemModel.StrKeys.CacheData, "value", json.encode(self.m_cacheData))
  self.m_dbTable:Set(CardItemModel.StrKeys.isPopFirstMergeWindow, "value", json.encode(self.m_mapPopChain))
end

function CardItemModel:OnItemUsed(message)
  local itemModel = message.ItemModel
  local chainId = GM.ItemDataModel:GetChainId(itemModel:GetType())
  if GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.cardItemStack) == 1 then
    if chainId == self.m_cacheData.chain then
      local _, num = self:CheckCanMergeMaxCardItem()
      if num == 0 then
        self.m_cacheData.isFinish = true
        self:SaveCacheData()
      end
    end
    return
  end
  if chainId == self.m_cacheData.chain then
    self.m_cacheData.isFinish = true
    self:SaveCacheData()
  end
end

function CardItemModel:IsCardItemByLevel(itemType)
  if Table.IsEmpty(self.m_mapCardItemTypeConfig) then
    return false
  end
  local itemChain = GM.ItemDataModel:GetChainId(itemType)
  for _, cardItemConfig in pairs(self.m_mapCardItemTypeConfig) do
    if cardItemConfig.ItemChain == itemChain and cardItemConfig.UnlockLevel <= GM.LevelModel:GetCurrentLevel() then
      return true
    end
  end
  return false
end

function CardItemModel:TryRemoveItem()
  if not self.m_bLateInit then
    return
  end
  if self:GetState(false) == ActivityState.Started then
    local function transformFunc(itemType)
      if not self:IsCardItem(itemType) and StringUtil.StartWith(itemType, "main_card_") then
        return true, itemType.Energy04
      end
      return false
    end
    
    local removeItems, removeStoreItems = GM.MainBoardModel:TransformItems(transformFunc, true)
    local BIRemoveItems = {}
    for _, item in ipairs(removeItems) do
      table.insert(BIRemoveItems, item:GetType())
    end
    GM.BIManager:LogAction(EBIType.CardItemRemoved, {
      chain = "",
      removeItems = BIRemoveItems,
      removeStoreItems = removeStoreItems
    })
    if 0 < #removeItems + #removeStoreItems then
      GM.BIManager:LogAcquire(ItemType.Energy04, #removeItems + #removeStoreItems, EBIType.CardItemChangeReward, true, EBoardType.Main)
    end
    if not Table.IsEmpty(self.m_cacheData) and self.m_cacheData.chain ~= nil then
      local bFind = false
      for _, cardItemConfig in pairs(self.m_mapCardItemTypeConfig) do
        if cardItemConfig.ItemChain == self.m_cacheData.chain then
          bFind = true
        end
      end
      if not bFind then
        self.m_cacheData = {}
        self:SaveCacheData()
      end
    end
    return
  end
  if not Table.IsEmpty(self.m_cacheData) and self.m_cacheData.isFinish ~= nil then
    self.m_cacheData.isFinish = true
    self:SaveCacheData()
  end
  local chain = self.m_cacheData.chain
  
  local function transformFunc(itemType)
    if self:IsCardItem(itemType) then
      return true, ItemType.Energy04
    end
    return false
  end
  
  local removeItems, removeStoreItems = GM.MainBoardModel:TransformItems(transformFunc, true)
  local BIRemoveItems = {}
  for _, item in ipairs(removeItems) do
    table.insert(BIRemoveItems, item:GetType())
  end
  if 0 < #removeItems + #removeStoreItems then
    GM.BIManager:LogAcquire(ItemType.Energy04, #removeItems + #removeStoreItems, EBIType.CardItemChangeReward, true, EBoardType.Main)
    GM.BIManager:LogAction(EBIType.CardItemRemoved, {
      chain = chain,
      removeItems = BIRemoveItems,
      removeStoreItems = removeStoreItems
    })
  end
end

function CardItemModel:LateInit()
  self.m_bLateInit = true
  self:TryRemoveItem()
end

function CardItemModel:_OnStateChanged()
  self:TryRemoveItem()
  if self:GetState() == ActivityState.Started then
    self:SetWindowOpened()
  end
  GM.ActivityModuleManager:AddRegister(ActivityModuleManager.ModuleType.ConvertDynamicReward, self, {}, {
    isPropertyFunc = function(type)
      local cateType = RewardApi.GetRewardCategoryType(type)
      return cateType == ERewardCategoryType.Item and self:IsCardItem(type)
    end,
    getPropertyFunc = function(reward, needBi)
      if self:GetState(false) ~= ActivityState.Started then
        local newReward = {}
        newReward[PROPERTY_TYPE] = ItemType.Energy01
        newReward[PROPERTY_COUNT] = reward[PROPERTY_COUNT]
        return newReward
      end
    end
  })
  EventDispatcher.DispatchEvent(EEventType.CardItemStateChanged)
end

function CardItemModel:_LoadOtherServerConfig(config)
  self.m_energyGenerateNum = nil
  if config.misc_conf_new then
    local energyConfig = Table.ListSelect(config.misc_conf_new, function(data)
      return data.confType == "card_item_energy"
    end)
    if energyConfig ~= nil and energyConfig[1] ~= nil then
      self.m_energyGenerateNum = energyConfig[1].param_int
    end
  end
end

function CardItemModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_cacheData = {}
  self:TryRemoveItem()
end

function CardItemModel:CheckFinish()
  if self:GetState(false) ~= ActivityState.Started then
    return
  end
  local isStack = GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.cardItemStack) == 1
  if isStack and self:CheckCanMergeMaxCardItem() then
    self.m_cacheData.isFinish = true
    self:SaveCacheData()
  end
end

function CardItemModel:OnItemSpread(message)
  if message.CostEnergy == true and self.m_energyGenerateNum ~= nil then
    local costEnergy = MathUtil.IntPow(2, message.EnergyBoostRatio)
    self:AddEnergyNum(costEnergy, message.Source)
  end
end

function CardItemModel:OnItemMerge(message)
  if self:GetState(false) ~= ActivityState.Started then
    return
  end
  local itemType = message.New:GetType()
  if not self:IsCardItemAndMaxLevel(itemType) then
    return
  end
  local chain = GM.ItemDataModel:GetChainId(itemType)
  if self.m_mapPopChain[chain] == 1 then
    return
  end
  self.m_mapPopChain[chain] = 0
  self:SaveCacheData()
  local chain = GM.ItemDataModel:GetChainId(itemType)
  local rarity = self.m_mapCardItemTypeConfig[chain] and self.m_mapCardItemTypeConfig[chain].Rarity or 1
  EventDispatcher.DispatchEvent(EEventType.CardItemFirstPopWindow, {itemType = itemType, rarity = rarity})
end

function CardItemModel:CanPopFirstMergeWindow(itemType)
  local chain = GM.ItemDataModel:GetChainId(itemType)
  return self.m_mapPopChain[chain] == 0
end

function CardItemModel:PopFirstMergeWindow(itemType)
  local chain = GM.ItemDataModel:GetChainId(itemType)
  self.m_mapPopChain[chain] = 1
  self:SaveCacheData()
end

function CardItemModel:OnCardItemGenerate(item)
  if self.m_dbTable:GetValue(CardItemModel.StrKeys.isPlayFirstTutorial, "value") == "2" then
    return
  end
  self.m_dbTable:Set(CardItemModel.StrKeys.isPlayFirstTutorial, "value", "1")
  EventDispatcher.DispatchEvent(EEventType.TutorialStartPop)
end

function CardItemModel:CanPopCardItemTutorial()
  if self:GetState(false) ~= ActivityState.Started then
    return false
  end
  return self.m_dbTable:GetValue(CardItemModel.StrKeys.isPlayFirstTutorial, "value") == "1"
end

function CardItemModel:PopCardItemTutorial()
  self.m_dbTable:Set(CardItemModel.StrKeys.isPlayFirstTutorial, "value", "2")
end

function CardItemModel:LoadCardItemConfig()
  local cardItemConfig = require("Data.Config.CardItemConfig")
  self.m_mapCardItemTypeConfig = {}
  for _, config in ipairs(cardItemConfig) do
    self.m_mapCardItemTypeConfig[config.ItemChain] = config
  end
  local cardItemProduceConfig = require("Data.Config.CardItemProduceConfig")
  self.m_mapCardItemProduceConfig = {}
  for _, config in ipairs(cardItemProduceConfig) do
    self.m_mapCardItemProduceConfig[config.ItemType] = self.m_mapCardItemProduceConfig[config.ItemType] or {}
    table.insert(self.m_mapCardItemProduceConfig[config.ItemType], config)
  end
end

function CardItemModel:CanGenerateCardItem()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  self:CheckFinish()
  if self:CheckCanMergeMaxCardItem() then
    return false
  end
  return true
end

function CardItemModel:GenerateCardItem()
  if self.m_cacheData.chain ~= nil and self.m_cacheData.isFinish == false then
    return GM.ItemDataModel:GetTypeByChainAndLevel(self.m_cacheData.chain, 1)
  else
    local curChain = self:TryGenerateNewChain()
    self.m_cacheData.chain = curChain
    self.m_cacheData.isFinish = false
    self:SaveCacheData()
    return GM.ItemDataModel:GetTypeByChainAndLevel(curChain, 1)
  end
end

function CardItemModel:AddEnergyNum(num, source)
  if not self:CanGenerateCardItem() then
    return
  end
  self.m_cacheData.m_curCostEnergy = self.m_cacheData.m_curCostEnergy or 0
  if self.m_cacheData.m_generateEnergy == nil then
    self.m_cacheData.m_generateEnergy = MathUtil.Random(self.m_cacheData.m_curCostEnergy + 1, self.m_energyGenerateNum)
  end
  local nextNum = self.m_cacheData.m_curCostEnergy + num
  if GM.MainBoardModel:IsBoardFull() then
    self.m_cacheData.m_curCostEnergy = nextNum
    self:SaveCacheData()
    return
  end
  if nextNum >= self.m_cacheData.m_generateEnergy and not self.m_cacheData.m_generateByRound then
    self.m_cacheData.m_generateByRound = true
    local cardItemCode = self:GenerateCardItem()
    local position = GM.MainBoardModel:FindEmptyPositionInSpreadOrder(source:GetPosition())
    GM.MainBoardModel:SpreadItem(source, position, cardItemCode, {
      logSpread = false,
      spreadType = BoardSpreadType.CardItem
    })
    EventDispatcher.DispatchEvent(EEventType.CardItemGenerate, {
      item = GM.MainBoardModel:GetItem(position)
    })
    GM.BIManager:LogAction(EBIType.CardItemGenerateByEnergy, {
      code = cardItemCode,
      costEnergy = num,
      generateEnergy = self.m_cacheData.m_generateEnergy,
      curAlreadyEnergy = nextNum,
      src = source:GetType()
    })
  end
  if nextNum >= self.m_energyGenerateNum then
    self.m_cacheData.m_generateByRound = false
    self.m_cacheData.m_generateEnergy = nil
  end
  self.m_cacheData.m_curCostEnergy = nextNum % self.m_energyGenerateNum
  self:SaveCacheData()
end

function CardItemModel:TryGenerateItem(itemType)
  if not self:CanGenerateCardItem() then
    return nil
  end
  local listProduceConfig = self.m_mapCardItemProduceConfig[itemType]
  if not listProduceConfig then
    return nil
  end
  local level = GM.LevelModel:GetCurrentLevel()
  local supportConfig
  for _, config in ipairs(listProduceConfig) do
    if level >= config.LevelMin and (config.LevelMax == nil or level <= config.LevelMax) then
      supportConfig = config
      break
    end
  end
  if not supportConfig then
    return nil
  end
  local isLevelLock = true
  for _, cardConfig in ipairs(self.m_mapCardItemTypeConfig) do
    if level >= cardConfig.UnlockLevel then
      isLevelLock = false
      break
    end
  end
  if not isLevelLock then
    return nil
  end
  local random = math.random(10000)
  if random <= supportConfig.Chance or GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestForceCreateCard, 0) == 1 then
    return self:GenerateCardItem()
  end
  return nil
end

function CardItemModel:CheckCanMergeMaxCardItem()
  if self.m_cacheData.isFinish == nil or self.m_cacheData.isFinish == true then
    return false
  end
  local curChain = self.m_cacheData.chain
  local maxLevel = GM.ItemDataModel:GetChainMaxLevel(curChain)
  local needOneLevelNum = MathUtil.IntPow(2, maxLevel - 1)
  local mapItemNum = GM.MainBoardModel:GetCodeCountMap(true, true, true)
  local curNum = 0
  for code, num in pairs(mapItemNum) do
    if ItemModelFactory.GetCodePrefixTargetType(code) == nil then
      local chain = GM.ItemDataModel:GetChainId(code)
      if chain == curChain then
        local level = GM.ItemDataModel:GetChainLevel(code)
        curNum = curNum + MathUtil.IntPow(2, level - 1) * num
      end
    end
  end
  if curNum ~= 0 and curNum % needOneLevelNum == 0 then
    return true
  end
  return false, curNum
end

function CardItemModel:TryGenerateNewChain()
  local listChain = {}
  local backListChain = {}
  local oldChain = self.m_cacheData.chain
  local level = GM.LevelModel:GetCurrentLevel()
  for _, cardItemConfig in pairs(self.m_mapCardItemTypeConfig) do
    if level >= cardItemConfig.UnlockLevel then
      if oldChain ~= cardItemConfig.ItemChain then
        table.insert(listChain, cardItemConfig)
      else
        table.insert(backListChain, cardItemConfig)
      end
    end
  end
  if #listChain == 0 then
    listChain = backListChain
  end
  local targetConfig = Table.ListWeightSelectOne(listChain)
  return targetConfig.ItemChain
end

function CardItemModel:IsCardItem(itemType)
  if Table.IsEmpty(self.m_mapCardItemTypeConfig) then
    return false
  end
  local itemChain = GM.ItemDataModel:GetChainId(itemType)
  for _, cardItemConfig in pairs(self.m_mapCardItemTypeConfig) do
    if cardItemConfig.ItemChain == itemChain then
      return true
    end
  end
  return false
end

function CardItemModel:IsCardItemAndMaxLevel(itemType)
  if self:IsCardItem(itemType) ~= true then
    return false
  end
  local itemChain = GM.ItemDataModel:GetChainId(itemType)
  local maxLevel = GM.ItemDataModel:GetChainMaxLevel(itemChain)
  local curLevel = GM.ItemDataModel:GetChainLevel(itemType)
  if curLevel == maxLevel then
    return true
  end
  return false
end

function CardItemModel:GetCardItemConfig(itemType)
  local chain = GM.ItemDataModel:GetChainId(itemType)
  return self.m_mapCardItemTypeConfig and self.m_mapCardItemTypeConfig[chain]
end

function CardItemModel:GetResourceLabels()
  return {
    AddressableLabel.CardItem
  }
end

function CardItemModel:GetTestInfo()
  local str = "\229\189\147\229\137\141\231\173\137\231\186\167\232\131\189\228\186\167\231\148\159\229\141\161\231\137\140\239\188\154\n"
  local level = GM.LevelModel:GetCurrentLevel()
  for _, cardItemConfig in pairs(self.m_mapCardItemTypeConfig) do
    if level >= cardItemConfig.UnlockLevel then
      str = str .. cardItemConfig.ItemChain .. ":" .. cardItemConfig.Weight .. ";  "
    end
  end
  str = str .. "\n"
  local listItemConfig = {}
  for itemType, listConfig in pairs(self.m_mapCardItemProduceConfig) do
    for _, config in ipairs(listConfig) do
      if level >= config.LevelMin and (config.LevelMax == nil or level <= config.LevelMax) then
        table.insert(listItemConfig, config)
        break
      end
    end
  end
  table.sort(listItemConfig, function(a, b)
    local aType = a.ItemType
    local bType = b.ItemType
    local aChain = GM.ItemDataModel:GetChainId(aType)
    local bChain = GM.ItemDataModel:GetChainId(bType)
    local aLevel = GM.ItemDataModel:GetChainLevel(aType)
    local bLevel = GM.ItemDataModel:GetChainLevel(bType)
    if aChain == bChain then
      return aLevel < bLevel
    else
      return aChain < bChain
    end
  end)
  str = str .. "\229\143\175\232\167\166\229\143\145\231\154\132\230\163\139\229\173\144:"
  local finishIndex, startIndex, curChain
  for _, config in ipairs(listItemConfig) do
    if curChain == nil then
      curChain = GM.ItemDataModel:GetChainId(config.ItemType)
      startIndex = GM.ItemDataModel:GetChainLevel(config.ItemType)
      finishIndex = startIndex
    else
      local chain = GM.ItemDataModel:GetChainId(config.ItemType)
      local level = GM.ItemDataModel:GetChainLevel(config.ItemType)
      if curChain ~= chain then
        str = str .. GM.ItemDataModel:GetTypeByChainAndLevel(curChain, startIndex) .. "-" .. GM.ItemDataModel:GetTypeByChainAndLevel(curChain, finishIndex) .. "\n"
        curChain = chain
        startIndex = level
        finishIndex = level
      elseif curChain == chain then
        if finishIndex + 1 == level then
          finishIndex = level
        else
          str = str .. GM.ItemDataModel:GetTypeByChainAndLevel(curChain, startIndex) .. "-" .. GM.ItemDataModel:GetTypeByChainAndLevel(curChain, finishIndex) .. "\n"
          startIndex = level
          finishIndex = level
        end
      end
    end
  end
  if curChain ~= nil then
    str = str .. GM.ItemDataModel:GetTypeByChainAndLevel(curChain, startIndex) .. "-" .. GM.ItemDataModel:GetTypeByChainAndLevel(curChain, finishIndex) .. "\n"
  end
  if self.m_energyGenerateNum ~= nil then
    str = str .. "\228\189\147\229\138\155\231\155\184\229\133\179\228\191\161\230\129\175:" .. "\229\190\170\231\142\175\230\149\176" .. self.m_energyGenerateNum .. "\n"
    local curCostEnergy = self.m_cacheData.m_curCostEnergy or "0"
    local curGenEnergy = self.m_cacheData.m_generateEnergy or "0"
    str = str .. "\229\189\147\229\137\141\232\174\161\230\149\176:" .. curCostEnergy .. " \231\148\159\230\136\144\232\174\161\230\149\176" .. curGenEnergy .. "\n"
  end
  return str
end
