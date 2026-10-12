EOrderBoostType = {
  Normal = 0,
  Super = 1,
  FailedSuper = 2
}
OrderBoostModel = setmetatable({}, BaseActivityModel)
OrderBoostModel.__index = OrderBoostModel
local strDBKeys = {
  CurConfigs = "CurConfigs",
  CurLevelRewardConfig = "CurLevelRewardConfig",
  CurInfo = "CurInfo",
  FinishSmile = "FinishSmile",
  FirstPopup = "FirstPopup",
  FirstHint = "FirstHint",
  BubbleHint = "BubbleHint",
  LastBubbleHintTime = "LastBubbleHint",
  FinishedNormalCount = "FinishedNormalCount",
  IsProConfig = "IsProConfig",
  CurLogicType = "CurLogicType",
  LastLogicType = "LastLogicType",
  ProEndTime = "ProEndTime",
  PopCountdownTip = "PopCountdownTip",
  ProTrigNum = "ProTrigNum",
  FirstProPopup = "FirstProPopup",
  LessScoreRound = "LessScoreRound",
  TutorialGestureNum = "TutorialGestureNum",
  CannonBoosterRound = "CannonBoosterRound",
  CannonBoosterIsOpen = "CannonBoosterIsOpen",
  CannonBoosterShownRound = "CannonBoosterShownRound",
  CannonBoosterRewardTimes = "CannonBoosterRewardTimes",
  SavedIncludeConfig = "SavedIncludeConfig"
}

function OrderBoostModel:Init(dbtable)
  BaseActivityModel.Init(self, ActivityType.OrderBoost, dbtable)
  self:LoadLocalConfig()
  EventDispatcher.AddListener(EEventType.ChangeGameMode, self, self._OnGameModeChanged)
end

function OrderBoostModel:LoadLocalConfig()
  self.m_curOrderConfigs = json.decode(self.m_dbTable:GetValue(strDBKeys.CurConfigs, "value") or "") or {}
  self.m_rewardConfig = json.decode(self.m_dbTable:GetValue(strDBKeys.CurLevelRewardConfig, "value") or "") or {}
  self.m_curInfo = json.decode(self.m_dbTable:GetValue(strDBKeys.CurInfo, "value") or "") or nil
  self.m_FinishSmile = tonumber(self.m_dbTable:GetValue(strDBKeys.FinishSmile, "value") or 0) or 0
  self.m_BubbleHint = tonumber(self.m_dbTable:GetValue(strDBKeys.BubbleHint, "value") or 0)
  self.m_proTrigNum = self.m_dbTable:GetValue(strDBKeys.ProTrigNum, "value") or nil
end

function OrderBoostModel:SaveMetaData()
  if self.m_curOrderConfigs ~= nil then
    self.m_dbTable:Set(strDBKeys.CurConfigs, "value", json.encode(self.m_curOrderConfigs))
  end
  if self.m_rewardConfig ~= nil then
    self.m_dbTable:Set(strDBKeys.CurLevelRewardConfig, "value", json.encode(self.m_rewardConfig))
  end
  if self.m_curInfo ~= nil then
    self.m_dbTable:Set(strDBKeys.CurInfo, "value", json.encode(self.m_curInfo))
  end
  if self.m_FinishSmile ~= nil then
    self.m_dbTable:Set(strDBKeys.FinishSmile, "value", tostring(self.m_FinishSmile))
  end
end

function OrderBoostModel:_OnStateChanged()
  if self:GetState() == ActivityState.Started and self.m_bLateInited then
    self:TryCreateNewSmile()
  end
  EventDispatcher.DispatchEvent(EEventType.OrderBoostStateChanged)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  if self.m_bLateInited then
    GM.MainBoardModel:UpdateOrderState()
  end
end

function OrderBoostModel:_DropData()
  self.m_curOrderConfigs = {}
  self.m_rewardConfig = {}
  self.m_curInfo = nil
  self.m_FinishSmile = 0
  self.m_proTrigNum = nil
  BaseActivityModel._DropData(self)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function OrderBoostModel:_OnGameModeChanged()
  if GM.SceneManager:GetGameMode() ~= EGameMode.Main then
    return
  end
  if not self:CanPopOrderBoostProWindow() then
    self:TrySetProEndTime()
  end
end

function OrderBoostModel:OnOrderFinished(order)
  if self:GetState() ~= ActivityState.Started or order:GetGameMode() ~= EGameMode.Main then
    return
  end
  if self:GetAddOrderBoostScoreByOrder(order) > 0 then
    local addScore = self:GetAddOrderBoostScoreByOrder(order)
    self.m_curInfo.curScore = math.min(self.m_curInfo.curScore + addScore, self.m_curInfo.MaxScore)
    local strSlot = tostring(order:GetSlot())
    if self.m_curInfo.orderFinishInfo[strSlot] == nil then
      self.m_curInfo.orderFinishInfo[strSlot] = 0
    end
    self:LogActivity(EBIType.ActivityAddScore, addScore)
    self.m_curInfo.orderFinishInfo[strSlot] = self.m_curInfo.orderFinishInfo[strSlot] + 1
    if self.m_curInfo.curScore >= self.m_curInfo.MaxScore then
      self:LogActivity(EBIType.ActivityRankUp, self.m_FinishSmile + 1)
      if self:GetLogicType() == EOrderBoostType.Super then
        GM.BIManager:LogAction(EBIType.OrderBoostProFinish, {
          t = self:GetProEndTime() - GM.GameModel:GetServerTime(),
          r = self.m_FinishSmile + 1
        })
      end
      local reviewRaceModel = GM.ActivityManager:GetModel(ActivityType.ReviewRace)
      if reviewRaceModel then
        reviewRaceModel:FinishRace()
      end
    end
    local orderCell = MainBoardView.GetInstance():GetOrderArea():GetCell(order)
    if orderCell ~= nil then
      local rewardBox = orderCell:GetOrderSmileRewardBox()
      if rewardBox and not rewardBox.gameObject:IsNull() then
        OrderBoostAnimationManager.PlayFlySmileAnimation(rewardBox:GetSmileTrans(), addScore)
      end
    end
    self:SaveMetaData()
    EventDispatcher.DispatchEvent(EEventType.OrderBoostSmileAddScore, addScore)
  end
end

function OrderBoostModel:AcquireSmileLogic(addScore)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  self.m_curInfo.curScore = math.min(self.m_curInfo.curScore + addScore, self.m_curInfo.MaxScore)
  self:LogActivity(EBIType.ActivityAddScore, addScore)
  if self.m_curInfo.curScore >= self.m_curInfo.MaxScore then
    self:LogActivity(EBIType.ActivityRankUp, self.m_FinishSmile + 1)
    if self:GetLogicType() == EOrderBoostType.Super then
      GM.BIManager:LogAction(EBIType.OrderBoostProFinish, {
        t = self:GetProEndTime() - GM.GameModel:GetServerTime(),
        r = self.m_FinishSmile + 1
      })
    end
    local reviewRaceModel = GM.ActivityManager:GetModel(ActivityType.ReviewRace)
    if reviewRaceModel then
      reviewRaceModel:FinishRace()
    end
  end
  self:SaveMetaData()
  EventDispatcher.DispatchEvent(EEventType.OrderBoostSmileAddScore, addScore)
end

function OrderBoostModel:OnFinishRoundSmile()
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self.m_curInfo == nil then
    return
  end
  if self.m_curInfo.curScore >= self.m_curInfo.MaxScore then
    local bPro = false
    if self:IsProConfig() and self:IsProStart() and not Table.IsEmpty(self.m_orderBoostProRewardConfig) then
      if self.m_proTrigNum == nil then
        self.m_proTrigNum = math.random(self.m_rewardConfig.pro_trig_num[1], self.m_rewardConfig.pro_trig_num[2])
        self.m_dbTable:Set(strDBKeys.ProTrigNum, "value", self.m_proTrigNum)
        if self:GetLogicType() == EOrderBoostType.Super then
          self:SetLessScoreRound(self.m_rewardConfig.pro_trig_num[1])
        else
          self:SetLessScoreRound(-1)
        end
        if GameConfig.IsTestMode() then
          Log.Info("\232\182\133\231\186\167\231\172\145\232\132\184\233\154\143\230\156\186\229\136\176\233\156\128\232\166\129\231\154\132\230\153\174\233\128\154boost\230\149\176\233\135\143\239\188\154" .. tostring(self.m_proTrigNum) .. "\n Score_less \232\189\174\230\149\176\239\188\154" .. self:GetLessScoreRound())
        end
      end
      local count = self:GetFinishedNormalCount()
      if self:GetLogicType() == EOrderBoostType.Normal then
        count = count + 1
        self:SetFinishedNormalCount(count)
      end
      Log.Info("[\232\182\133\231\186\167\231\172\145\232\132\184]\232\183\157\231\166\187\232\167\166\229\143\145\232\191\152\230\156\137" .. self.m_proTrigNum - count)
      if count >= self.m_proTrigNum then
        bPro = true
        self:SetFinishedNormalCount(0)
        self:ClearFirstHint()
        self.m_dbTable:Remove(strDBKeys.ProTrigNum, "value")
        self.m_proTrigNum = nil
      end
    end
    local oldType = self:GetLogicType()
    self.m_dbTable:Set(strDBKeys.LastLogicType, "value", oldType)
    local oldUIType = self:GetUIType()
    self.m_bProReward = false
    if oldType == EOrderBoostType.Super then
      self:RemoveProEndTime()
      self:SetCountdownTipPop(false)
      self.m_bProReward = true
    end
    self.m_dbTable:Set(strDBKeys.CurLogicType, "value", bPro and EOrderBoostType.Super or EOrderBoostType.Normal)
    local reviewRaceModel = GM.ActivityManager:GetModel(ActivityType.ReviewRace)
    if reviewRaceModel then
      reviewRaceModel:TryTriggerRace()
    end
    local oldRewardConfig = Table.DeepCopy(self.m_rewardConfig)
    local oldOrderConfig = Table.DeepCopy(self.m_curOrderConfigs)
    self.m_bTypeChanged = oldUIType ~= self:GetUIType()
    self.m_FinishSmile = self.m_FinishSmile + 1
    self.m_curInfo = nil
    local needCannonReward
    if self:IsCannonRewardOpen() then
      local round = self:GetFinishedRoundWhenCannonOpen()
      round = round + 1
      if round == 3 then
        needCannonReward = true
        self:SetFinishedRoundWhenCannonOpen(0)
      else
        self:SetFinishedRoundWhenCannonOpen(round)
      end
    end
    self:TryCreateNewSmile()
    self:SetTutorialGestureNum(self:GetTutorialGestureNum() + 1)
    EventDispatcher.DispatchEvent(EEventType.OrderBoostFillOrder, self)
    local target = self:TryGenerateSmileItem(oldRewardConfig, oldOrderConfig, oldType)
    local cannonReward
    if needCannonReward then
      cannonReward = self:TryGenerateCannonRewardItem()
    end
    self:LogActivity(EBIType.ActivityGetRewards, self.m_FinishSmile)
    return target, cannonReward
  end
  return
end

function OrderBoostModel:IntelligentGenerateSmileItem(targetItems, FindItemsAndPos, oldRewardConfig, oldOrderConfig, oldType)
  local itemScoreMapCfg = {}
  local itemWeightMapCfg = {}
  for _, itemConfig in pairs(self.m_orderBoostItemConfigsaved) do
    if GM.ItemDataModel:GetModelConfig(itemConfig.item_type, true) ~= nil then
      local minLevel = itemConfig.level_min
      local maxLevel = itemConfig.level_max
      local currentLevel = GM.LevelModel:GetCurrentLevel()
      if (minLevel == nil or minLevel <= currentLevel) and (maxLevel == nil or maxLevel >= currentLevel) then
        itemScoreMapCfg[itemConfig.item_type] = itemConfig.score
        itemWeightMapCfg[#itemWeightMapCfg + 1] = {
          Code = itemConfig.item_type,
          Weight = itemConfig.weight
        }
      end
    end
  end
  local totalScore = oldType == EOrderBoostType.Super and oldRewardConfig.score_pro_sum or oldRewardConfig.score_sum
  local biInfo = {}
  biInfo.boostround = self:GetFinishRound()
  biInfo.ispro = oldType == EOrderBoostType.Super
  if oldOrderConfig and oldOrderConfig[1] then
    biInfo.groupid = tostring(oldOrderConfig[1].level_min) .. "_" .. tostring(oldOrderConfig[1].level_max)
  end
  local res = SmartRewardHelper.GetCodesForOrderBoost(itemScoreMapCfg, itemWeightMapCfg, totalScore, "boost", biInfo)
  for _, code in ipairs(res) do
    table.insert(targetItems, {item_type = code})
  end
  self:FindPositionForItems(FindItemsAndPos, targetItems, oldType)
  if GameConfig.IsTestMode() then
    local str = "\230\153\186\232\131\189\229\143\145\229\165\150 \231\172\145\232\132\184 \230\156\128\231\187\136\231\154\132\230\163\139\229\173\144\231\154\132\228\189\141\231\189\174\229\146\140\228\191\161\230\129\175\n"
    for _, item in ipairs(FindItemsAndPos) do
      str = str .. "itemType: " .. item.itemType .. ",   pos: " .. tostring(item.Pos or "\231\188\147\229\173\152\233\152\159\229\136\151") .. "\n"
    end
    Log.Info(str)
  end
end

function OrderBoostModel:ClassicGenerateSmileItem(targetItems, FindItemsAndPos, oldRewardConfig, oldOrderConfig, oldType)
  local currentOrders = GM.MainBoardModel:GetOrders()
  local missing_requested_items = {}
  local mapItemLackNum = {}
  local lackInfo = "\230\137\128\230\156\137\230\156\170\232\142\183\229\190\151\230\163\139\229\173\144\229\143\138\231\188\186\229\164\177\230\149\176\233\135\143\239\188\136\231\173\137\230\149\1361\231\186\167\230\163\139\229\173\144\239\188\137\239\188\154\n"
  if self:RewardStockCountOn() then
    mapItemLackNum = GM.MainBoardModel:CalculateOrderCodeLackNumMap(false, true, false)
    for code, lack in pairs(mapItemLackNum) do
      missing_requested_items[code] = 1
      if GameConfig.IsTestMode() then
        lackInfo = lackInfo .. code .. " : " .. lack .. "\n"
      end
    end
  else
    local currentItems = GM.MainBoardModel:GetCodeCountMap(true, false, true)
    for _, order in pairs(currentOrders) do
      local requireItems = order:GetRequirements()
      for _, item in pairs(requireItems) do
        if currentItems[item] == nil then
          missing_requested_items[item] = 1
        end
      end
    end
  end
  local randomChainByType = {}
  local mapRandomChainByType = {}
  local unLockItems = {}
  local itemsRandomType = {}
  for _, itemConfig in pairs(self.m_orderBoostItemConfigsaved) do
    if GM.ItemDataModel:GetModelConfig(itemConfig.item_type, true) ~= nil then
      local minLevel = itemConfig.level_min
      local maxLevel = itemConfig.level_max
      local currentLevel = GM.LevelModel:GetCurrentLevel()
      if minLevel == nil or maxLevel == nil or minLevel <= currentLevel and maxLevel >= currentLevel then
        for waitItem, _ in pairs(missing_requested_items) do
          if GM.ItemDataModel:GetChainId(waitItem) == GM.ItemDataModel:GetChainId(itemConfig.item_type) and GM.ItemDataModel:GetChainLevel(waitItem) > GM.ItemDataModel:GetChainLevel(itemConfig.item_type) then
            local weight = Mathf.Pow(2, math.max(1, GM.ItemDataModel:GetChainLevel(waitItem) - 3))
            weight = math.min(weight, 100)
            weight = math.max(weight, 5)
            if mapRandomChainByType[waitItem] == nil then
              mapRandomChainByType[waitItem] = weight
            end
            if itemsRandomType[waitItem] == nil then
              itemsRandomType[waitItem] = {}
            end
            table.insert(itemsRandomType[waitItem], itemConfig)
          end
        end
        if GM.ItemDataModel:IsUnlocked(itemConfig.item_type) then
          table.insert(unLockItems, itemConfig)
        end
      end
    end
  end
  for type, weight in pairs(mapRandomChainByType) do
    table.insert(randomChainByType, {ItemType = type, Weight = weight})
  end
  local randomChainByTypeCache = Table.DeepCopy(randomChainByType)
  local RandomChainTarget
  local testInfo = "" .. lackInfo
  local totalScore = oldType == EOrderBoostType.Super and oldRewardConfig.score_pro_sum or oldRewardConfig.score_sum
  if #randomChainByType == 0 then
    local curScore = 0
    if GameConfig.IsTestMode() then
      testInfo = testInfo .. "\226\128\148\226\128\148\232\174\162\229\141\149\230\163\139\229\173\144\229\157\135\229\183\178\232\142\183\229\190\151 / \230\156\170\232\142\183\229\190\151\230\163\139\229\173\144\228\184\141\229\173\152\229\156\168\229\175\185\229\186\148\233\133\141\231\189\174\227\128\130\233\154\143\230\156\186\233\128\137\229\143\150\229\183\178\232\167\163\233\148\129\230\163\139\229\173\144\226\128\148\226\128\148\n"
    end
    testInfo = self:RandomChooseUnlockItems(0, totalScore, unLockItems, targetItems, testInfo)
  else
    if GameConfig.IsTestMode() then
      testInfo = testInfo .. "\226\128\148\226\128\148\232\174\162\229\141\149\230\163\139\229\173\144\230\156\170\229\133\168\233\131\168\232\142\183\229\190\151\239\188\140\228\184\148\229\173\152\229\156\168\229\175\185\229\186\148\233\133\141\231\189\174\227\128\130\230\156\170\232\142\183\229\190\151\230\163\139\229\173\144\230\149\176\233\135\143 = " .. #randomChainByType .. "\n"
    end
    local curScore = 0
    while totalScore > curScore do
      if 0 < #randomChainByType then
        RandomChainTarget = Table.ListWeightSelectOne(randomChainByType)
        local curRandomItems = itemsRandomType[RandomChainTarget.ItemType]
        local targetOne = Table.ListWeightSelectOne(curRandomItems, "weight")
        curScore = curScore + targetOne.score
        table.insert(targetItems, targetOne)
        if GameConfig.IsTestMode() then
          testInfo = testInfo .. tostring(RandomChainTarget.ItemType) .. "(" .. tostring(targetOne.item_type) .. ")"
          testInfo = testInfo .. (self:RewardStockCountOn() and " \231\188\186\229\164\177\230\149\176\233\135\143\229\143\152\229\140\150\239\188\154" or "\n")
        end
        if self:RewardStockCountOn() then
          local tempLevel = GM.ItemDataModel:GetChainLevel(targetOne.item_type)
          if GameConfig.IsTestMode() then
            testInfo = testInfo .. mapItemLackNum[RandomChainTarget.ItemType] .. " minus " .. MathUtil.IntPow(2, tempLevel - 1) .. "\n"
          end
          mapItemLackNum[RandomChainTarget.ItemType] = mapItemLackNum[RandomChainTarget.ItemType] - MathUtil.IntPow(2, tempLevel - 1)
          if mapItemLackNum[RandomChainTarget.ItemType] <= 0 then
            mapItemLackNum[RandomChainTarget.ItemType] = 0
            for i, data in ipairs(randomChainByType) do
              if data.ItemType == RandomChainTarget.ItemType then
                table.remove(randomChainByType, i)
                if GameConfig.IsTestMode() then
                  testInfo = testInfo .. data.ItemType .. " \231\188\186\229\164\177\230\149\176\233\135\143\228\184\1860, \231\167\187\233\153\164\227\128\130" .. "\229\137\169\228\189\153\229\143\175\233\128\137\230\163\139\229\173\144\230\149\176\233\135\143 = " .. #randomChainByType .. "\n"
                end
                goto lbl_359
              end
            end
            end
          end
        else
          break
        end
      ::lbl_359::
    end
    if self:RewardStockCountOn() and totalScore > curScore then
      testInfo = self:RandomChooseUnlockItems(curScore, totalScore, unLockItems, targetItems, testInfo)
    end
  end
  self:FindPositionForItems(FindItemsAndPos, targetItems, oldType)
  if GameConfig.IsTestMode() then
    self:MakeUpTestInfos(testInfo, oldType, totalScore, missing_requested_items, randomChainByTypeCache, itemsRandomType, unLockItems, FindItemsAndPos)
  end
end

function OrderBoostModel:TryGenerateSmileItem(oldRewardConfig, oldOrderConfig, oldType)
  local targetItems = {}
  local FindItemsAndPos = {}
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ItemRewardIntelligent) then
    self:IntelligentGenerateSmileItem(targetItems, FindItemsAndPos, oldRewardConfig, oldOrderConfig, oldType)
  else
    self:ClassicGenerateSmileItem(targetItems, FindItemsAndPos, oldRewardConfig, oldOrderConfig, oldType)
  end
  return FindItemsAndPos
end

function OrderBoostModel:FindPositionForItems(FindItemsAndPos, targetItems, oldType)
  local boarNewPos = BoardPosition.Create(7, 1)
  local targetPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrderWithNum(boarNewPos, nil, #targetItems, true)
  local AddItems = {}
  for index, Pos in ipairs(targetPos) do
    table.insert(AddItems, {
      position = Pos,
      code = targetItems[index].item_type
    })
  end
  local listItemModel = GM.MainBoardModel:GenerateItems(AddItems)
  local cacheItems = {}
  for index, itemType in ipairs(targetItems) do
    local Pos = targetPos[index]
    local itemModel
    if Pos ~= nil then
      itemModel = listItemModel[index]
    else
      table.insert(cacheItems, itemType.item_type)
    end
    GM.BIManager:LogAcquire(itemType.item_type, 1, oldType == EOrderBoostType.Super and EBIType.OrderBoostProAcquireItems or EBIType.OrderBoostAcquireItems)
    table.insert(FindItemsAndPos, {
      Pos = Pos,
      itemType = itemType.item_type,
      itemModel = itemModel
    })
  end
  GM.MainBoardModel:CacheItems(cacheItems, CacheItemType.Type2)
end

function OrderBoostModel:TryGenerateCannonRewardItem()
  local rewardTimes = self.m_dbTable:GetValue(strDBKeys.CannonBoosterRewardTimes, "value") or 0
  rewardTimes = rewardTimes + 1
  self.m_dbTable:Set(strDBKeys.CannonBoosterRewardTimes, "value", rewardTimes)
  local currentLevel = GM.LevelModel:GetCurrentLevel()
  local cannonScore
  local FindItemsAndPos = {}
  for _, config in ipairs(self.m_orderBoostExtraRewardConfig) do
    if currentLevel >= config.level_min and currentLevel <= config.level_max then
      cannonScore = config.score
      break
    end
  end
  return RandomGenerateCodeHelper.GetCannonReward(rewardTimes, cannonScore)
end

function OrderBoostModel:RandomChooseUnlockItems(curScore, totalScore, unlockItems, targetItems, testInfo)
  if GameConfig.IsTestMode() then
    testInfo = testInfo .. "\233\154\143\230\156\186\230\138\189\229\143\150\230\163\139\229\173\144, \229\189\147\229\137\141\229\136\134\230\149\176 / \231\172\145\232\132\184\230\128\187\229\136\134\230\149\176 = " .. curScore .. " / " .. totalScore .. "\n"
  end
  while curScore < totalScore do
    local targetOne = Table.ListWeightSelectOne(unlockItems, "weight")
    curScore = curScore + targetOne.score
    table.insert(targetItems, targetOne)
    if GameConfig.IsTestMode() then
      testInfo = testInfo .. tostring(targetOne.item_type) .. " "
    end
  end
  return testInfo
end

function OrderBoostModel:MakeUpTestInfos(testInfo, oldType, totalScore, missing_requested_items, randomChainByType, itemsRandomType, unLockItems, FindItemsAndPos)
  local str = ""
  str = str .. "\229\189\147\229\137\141\231\177\187\229\158\139\239\188\154" .. tostring(oldType == EOrderBoostType.Super and "\232\182\133\231\186\167\231\172\145\232\132\184" or "\230\153\174\233\128\154\231\172\145\232\132\184") .. "\n"
  if self:RewardStockCountOn() then
    str = str .. "\230\150\176\229\143\145\229\165\150\233\128\187\232\190\145\229\183\178\231\148\159\230\149\136\239\188\136v3.88\239\188\137\n"
  end
  str = str .. "\229\165\150\229\138\177\230\163\139\229\173\144\230\128\187\229\136\134\230\149\176\239\188\154" .. tostring(totalScore) .. "\n"
  str = str .. "\n"
  str = str .. "\229\189\147\229\137\141\232\174\162\229\141\149\230\156\170\232\142\183\229\190\151\230\163\139\229\173\144\229\136\151\232\161\168" .. (self:RewardStockCountOn() and "(\228\189\142\231\173\137\231\186\167\230\163\139\229\173\144\229\144\136\230\136\144\232\174\161\231\174\151)" or "") .. "\239\188\154\n"
  for waitItem, _ in pairs(missing_requested_items) do
    str = str .. waitItem .. " "
  end
  str = str .. [[


]]
  str = str .. "\229\189\147\229\137\141\230\178\161\230\156\137\233\128\137\228\184\173\231\154\132\230\163\139\229\173\144 \229\143\175\233\128\137\230\139\169\231\154\132\231\148\159\230\136\144\231\154\132\230\163\139\229\173\144 \n"
  for itemType, itemConfig in pairs(randomChainByType) do
    str = str .. itemConfig.ItemType .. " \230\157\131\233\135\141 = " .. itemConfig.Weight .. " \229\143\175\233\128\137\233\133\141\231\189\174:\n    "
    for _, item in pairs(itemsRandomType[itemConfig.ItemType]) do
      str = str .. item.item_type .. " / "
    end
    str = str .. "\n"
  end
  str = str .. "\n"
  str = str .. "\231\142\169\229\174\182\229\183\178\231\187\143\232\167\163\233\148\129\231\154\132\229\143\175\233\128\137\230\139\169\230\163\139\229\173\144\233\133\141\231\189\174\239\188\136\229\186\148\231\148\168\228\186\142\233\154\143\230\156\186\229\143\145\230\148\190\230\181\129\231\168\139\239\188\137 \n"
  for _, itemConfig in pairs(unLockItems) do
    str = str .. json.encode(itemConfig) .. "\n"
  end
  str = str .. "\n" .. testInfo .. "\n"
  str = str .. "\230\156\128\231\187\136\231\154\132\230\163\139\229\173\144\231\154\132\228\189\141\231\189\174\229\146\140\228\191\161\230\129\175\n"
  for _, item in ipairs(FindItemsAndPos) do
    str = str .. "itemType: " .. item.itemType .. ",   pos: " .. tostring(item.Pos or "\231\188\147\229\173\152\233\152\159\229\136\151") .. "\n"
  end
  Log.Info(str)
end

function OrderBoostModel:RewardStockCountOn()
  return GM.ConfigModel:IsServerControlOpen(EGeneralConfType.RewardStockCount)
end

function OrderBoostModel:CanSendSmile()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_curInfo == nil then
    return false
  end
  return self.m_curInfo.curScore >= self.m_curInfo.MaxScore
end

function OrderBoostModel:GetCurScore()
  return self.m_curInfo.curScore
end

function OrderBoostModel:GetMaxScore()
  return self.m_curInfo.MaxScore
end

function OrderBoostModel:GetFinishRound()
  return self.m_FinishSmile
end

function OrderBoostModel:LoadProServerConfig()
  local md5 = GM.ConfigModel:GetServerConfigMD5(ServerConfigKey.OrderBoostProRewardConfig)
  if md5 == self.m_md5Pro then
    return
  end
  self.m_md5Pro = md5
  local configs = GM.ConfigModel:GetServerConfig(ServerConfigKey.OrderBoostProRewardConfig)
  self.m_orderBoostProRewardConfig = {}
  if not Table.IsEmpty(configs) then
    for _, config in ipairs(configs) do
      if GM.ConfigModel:GetOrderBoostProConfig().tag == config.order_tag then
        table.insert(self.m_orderBoostProRewardConfig, config)
      end
    end
  end
end

function OrderBoostModel:LoadServerConfig()
  self:_LoadServerConfig()
  if self:IsProConfigOpen() then
    self:LoadProServerConfig()
  end
  self:_CheckId()
  self:_UpdateState()
end

function OrderBoostModel:NewRoundUseNewConfig()
  if Table.IsEmpty(self.m_orderBoostSlotConfigstemp) then
    return
  end
  local savedIncludeConfig = {
    orderBoostSlotConfig2 = self.m_orderBoostSlotConfigstemp,
    orderBoostRewardConfig2 = self.m_orderBoostRewardConfigtemp,
    orderBoostItemConfig2 = self.m_orderBoostItemConfigtemp
  }
  self.m_orderBoostSlotConfigssaved = self.m_orderBoostSlotConfigstemp
  self.m_orderBoostRewardConfigsaved = self.m_orderBoostRewardConfigtemp
  self.m_orderBoostItemConfigsaved = self.m_orderBoostItemConfigtemp
  self.m_dbTable:Set(strDBKeys.SavedIncludeConfig, "value", json.encode(savedIncludeConfig))
end

function OrderBoostModel:_LoadOtherServerConfig(config)
  local savedIncludeConfig = json.decode(self.m_dbTable:GetValue(strDBKeys.SavedIncludeConfig, "value") or "") or {}
  if Table.IsEmpty(savedIncludeConfig) then
    self.m_orderBoostSlotConfigssaved = config.orderBoostSlotConfig
    self.m_orderBoostRewardConfigsaved = config.orderBoostRewardConfig
    self.m_orderBoostItemConfigsaved = config.orderBoostItemConfig
  else
    self.m_orderBoostSlotConfigssaved = savedIncludeConfig.orderBoostSlotConfig2
    self.m_orderBoostRewardConfigsaved = savedIncludeConfig.orderBoostRewardConfig2
    self.m_orderBoostItemConfigsaved = savedIncludeConfig.orderBoostItemConfig2
  end
  self.m_orderBoostSlotConfigstemp = config.orderBoostSlotConfig2
  self.m_orderBoostRewardConfigtemp = config.orderBoostRewardConfig2
  self.m_orderBoostItemConfigtemp = config.orderBoostItemConfig2
  self.m_orderBoostHint = false
  self.m_orderBoostExtraRewardConfig = config.orderBoostExtraRewardConfig
  if self.m_orderBoostExtraRewardConfig == nil then
    self.m_dbTable:Remove(strDBKeys.CannonBoosterRound, "value")
    self.m_dbTable:Remove(strDBKeys.CannonBoosterIsOpen, "value")
  end
  if self.m_bLateInited then
    self:TryCreateNewSmile()
  end
end

function OrderBoostModel:LateInit()
  self.m_bLateInited = true
  self:TryCreateNewSmile()
end

function OrderBoostModel:SetCannonStart()
  self.m_dbTable:Set(strDBKeys.CannonBoosterIsOpen, "value", "1")
  self.m_dbTable:Set(strDBKeys.CannonBoosterShownRound, "value", 0)
end

function OrderBoostModel:TryCreateNewSmile()
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self.m_curInfo ~= nil then
    return
  end
  if self.m_orderBoostExtraRewardConfig == nil then
    self.m_dbTable:Remove(strDBKeys.CannonBoosterRound, "value")
    self.m_dbTable:Remove(strDBKeys.CannonBoosterIsOpen, "value")
  elseif GM.LevelModel:GetCurrentLevel() >= self.m_orderBoostExtraRewardConfig[1].sLevel and self:GetFinishedRoundWhenCannonOpen() == 0 then
    self:SetCannonStart()
  end
  self:NewRoundUseNewConfig()
  local curLevel = GM.LevelModel:GetCurrentLevel()
  self.m_curOrderConfigs = {}
  for _, slotConfig in ipairs(self.m_orderBoostSlotConfigssaved) do
    if curLevel >= slotConfig.level_min and curLevel <= slotConfig.level_max then
      self.m_curOrderConfigs[#self.m_curOrderConfigs + 1] = Table.DeepCopy(slotConfig)
    end
  end
  self.m_rewardConfig = nil
  local rewardConfigs = self.m_orderBoostRewardConfigsaved
  if self:IsProConfigOpen() and not Table.IsEmpty(self.m_orderBoostProRewardConfig) then
    rewardConfigs = self.m_orderBoostProRewardConfig
    self:SetProConfig()
  end
  for _, rewardConfig in ipairs(rewardConfigs) do
    if curLevel >= rewardConfig.level_min and curLevel <= rewardConfig.level_max then
      self.m_rewardConfig = Table.DeepCopy(rewardConfig)
    end
  end
  if self:IsProConfig() and self:IsProStart() and self:GetLogicType() == EOrderBoostType.Normal and self:GetFinishedNormalCount() < self:GetLessScoreRound() then
    if GameConfig.IsTestMode() then
      Log.Info("Creating \230\153\174\233\128\154\231\172\145\232\132\184 round " .. self:GetFinishedNormalCount() .. ",\nScore_less \233\133\141\231\189\174\232\166\134\231\155\150 " .. self.m_rewardConfig.score_sum .. "->" .. self.m_rewardConfig.score_sum_less)
    end
    self.m_rewardConfig.score_sum = self.m_rewardConfig.score_sum_less
  end
  self.m_curInfo = {}
  self.m_curInfo.curScore = 0
  self.m_curInfo.MaxScore = self.m_rewardConfig.smile_sum
  self.m_curInfo.orderFinishInfo = {}
  self:SaveMetaData()
  self.m_BubbleHint = 0
  self.m_dbTable:Set(strDBKeys.BubbleHint, "value", tostring(self.m_BubbleHint))
  local orders = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetOrders()
  local biInfo = {}
  biInfo.order = {}
  biInfo.oboostround = self:GetFinishRound() + 1
  biInfo.ispro = self:GetLogicType() == EOrderBoostType.Super
  for _, order in pairs(orders) do
    if self:GetAddOrderBoostScoreByOrder(order) ~= 0 then
      local cueInfo = {}
      local content = {}
      for _, requirement in ipairs(order:GetRequirements()) do
        if content[requirement] == nil then
          content[requirement] = 0
        end
        content[requirement] = content[requirement] + 1
      end
      cueInfo.code = GM.BIManager:TableToString(content)
      cueInfo.slot = order:GetSlot()
      cueInfo.facenum = self:GetAddOrderBoostScoreByOrder(order)
      table.insert(biInfo.order, cueInfo)
    end
  end
  GM.BIManager:LogAction(EBIType.OrderBoostRefresh, biInfo)
  GM.BIManager:LogAction(EBIType.OrderBoostRefresh2, {
    oboostround = biInfo.oboostround,
    ispro = biInfo.ispro
  })
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  if not self.m_bTypeChanged then
    EventDispatcher.DispatchEvent(EEventType.OrderBoostSmileChanged)
  end
  GM.MainBoardModel:UpdateOrderState()
end

function OrderBoostModel:GetAddOrderBoostScoreByOrder(order)
  if order == nil then
    return 0
  end
  if order.GetSlot == nil then
    return 0
  end
  if self:GetState() ~= ActivityState.Started then
    return 0
  end
  local slot = order:GetSlot()
  return self:GetAddSmileScoreBySlot(slot)
end

function OrderBoostModel:SmileCompleted()
  return self.m_curInfo.curScore >= self.m_curInfo.MaxScore
end

function OrderBoostModel:GetAddSmileScoreBySlot(slot)
  if self:GetState() ~= ActivityState.Started then
    return 0
  end
  if self.m_curInfo == nil then
    return 0
  end
  if slot == MainOrderSlotDefinition.TimedOrderSlot then
    return 2
  elseif slot == MainOrderSlotDefinition.ExtraCustomerSlot then
    return 0
  elseif slot == MainOrderSlotDefinition.ContiorderSlot then
    local contiModel = GM.ActivityManager:GetStartedContiorders()
    if contiModel then
      return contiModel:GetSmileCount()
    end
  end
  local finishSlot = self.m_curInfo.orderFinishInfo[tostring(slot)] or 0
  local MaxFinishSlot = 0
  local findConfig
  for _, slotConfig in ipairs(self.m_curOrderConfigs) do
    if slotConfig.order_slot == slot then
      MaxFinishSlot = slotConfig.order_num
      findConfig = slotConfig
    end
  end
  if finishSlot >= MaxFinishSlot then
    return 0
  end
  return findConfig.reward_num
end

function OrderBoostModel:CanPopOrderBoostWindow()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_dbTable:GetValue(strDBKeys.FirstPopup, "value") == "1" then
    return false
  end
  if self.m_curInfo ~= nil then
    return true
  end
end

function OrderBoostModel:PopOrderBoostWindow()
  self.m_dbTable:Set(strDBKeys.FirstPopup, "value", "1")
end

function OrderBoostModel:IsFirstOpenWindow()
  return self.m_dbTable:GetValue(strDBKeys.FirstPopup, "value") ~= "1"
end

function OrderBoostModel:GetFirstHint()
  return self.m_dbTable:GetValue(strDBKeys.FirstHint, "value") ~= "1"
end

function OrderBoostModel:SetFirstHint()
  self.m_dbTable:Set(strDBKeys.FirstHint, "value", "1")
end

function OrderBoostModel:ClearFirstHint()
  self.m_dbTable:Set(strDBKeys.FirstHint, "value", "-1")
end

function OrderBoostModel:CanPopBubble(index)
  if 1 << index & self.m_BubbleHint ~= 0 then
    return false
  end
  return true
end

function OrderBoostModel:PopBubble(index)
  self.m_BubbleHint = self.m_BubbleHint | 1 << index
  self.m_dbTable:Set(strDBKeys.BubbleHint, "value", tostring(self.m_BubbleHint))
  self.m_dbTable:Set(strDBKeys.LastBubbleHintTime, "value", tostring(GM.GameModel:GetServerTime()))
end

function OrderBoostModel:UpdatePerSecond()
  local state = self:GetState()
  if state == ActivityState.Started and tonumber(self.m_dbTable:GetValue(strDBKeys.LastBubbleHintTime, "value") or "") ~= nil and tonumber(self.m_dbTable:GetValue(strDBKeys.LastBubbleHintTime, "value") or "") // Sec2Day ~= GM.GameModel:GetServerTime() // Sec2Day then
    self.m_BubbleHint = self.m_BubbleHint & 1
    self.m_dbTable:Set(strDBKeys.BubbleHint, "value", tostring(self.m_BubbleHint))
  end
  local time = GM.GameModel:GetServerTime()
  if state == ActivityState.Started then
    if self:IsProConfigOpen() then
      if self:GetLogicType() == EOrderBoostType.Super then
        local endTime = self:GetProEndTime()
        if endTime ~= nil and self.m_curInfo.curScore < self.m_curInfo.MaxScore then
          if self:CanPopCountdownTip() and endTime - time <= 3600 and 3 < endTime - time then
            EventDispatcher.DispatchEvent(EEventType.OrderBoostProCountdownTip)
          end
          if time >= endTime then
            self:ChangeProToOtherType(EOrderBoostType.FailedSuper)
          end
        end
      end
    elseif self:IsProConfig() then
      local curLevel = GM.LevelModel:GetCurrentLevel()
      self.m_rewardConfig = nil
      for _, rewardConfig in ipairs(self.m_orderBoostRewardConfigsaved) do
        if curLevel >= rewardConfig.level_min and curLevel <= rewardConfig.level_max then
          self.m_rewardConfig = Table.DeepCopy(rewardConfig)
        end
      end
      if self.m_curInfo.curScore >= self.m_curInfo.MaxScore then
        self.m_curInfo.curScore = self.m_rewardConfig.smile_sum
      end
      self.m_curInfo.MaxScore = self.m_rewardConfig.smile_sum
      self:SaveMetaData()
      self.m_dbTable:Remove(strDBKeys.IsProConfig, "value")
      self:SetFinishedNormalCount(0)
      if self:GetLogicType() == EOrderBoostType.Super then
        self:ChangeProToOtherType(EOrderBoostType.Normal)
      end
    end
  end
  BaseActivityModel.UpdatePerSecond(self)
end

function OrderBoostModel:ChangeProToOtherType(type)
  self.m_dbTable:Set(strDBKeys.CurLogicType, "value", type)
  self:RemoveProEndTime()
  self:SetCountdownTipPop(false)
  self.m_bTypeChanged = true
  EventDispatcher.DispatchEvent(EEventType.OrderBoostProEnd)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  EventDispatcher.DispatchEvent(EEventType.OrderBoostRefreshEntry)
end

function OrderBoostModel:GetCurInfo()
  return self.m_curInfo
end

function OrderBoostModel:GetOrderEntryCanHint()
  return GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.OrderBoostHint) == 1
end

function OrderBoostModel:GetResourceLabels()
  return {
    AddressableLabel.OrderBoost,
    AddressableLabel.OrderBoostPro,
    AddressableLabel.OrderBoostCommon,
    AddressableLabel.Cannon
  }
end

function OrderBoostModel:GetUIType()
  return self:GetLogicType() == EOrderBoostType.Super and EOrderBoostType.Super or EOrderBoostType.Normal
end

function OrderBoostModel:GetLogicType()
  return self.m_dbTable:GetValue(strDBKeys.CurLogicType, "value") or EOrderBoostType.Normal
end

function OrderBoostModel:GetLastLogicType()
  return self.m_dbTable:GetValue(strDBKeys.LastLogicType, "value") or EOrderBoostType.Normal
end

function OrderBoostModel:GetFinishedNormalCount()
  return self.m_dbTable:GetValue(strDBKeys.FinishedNormalCount, "value") or 0
end

function OrderBoostModel:SetFinishedNormalCount(num)
  self.m_dbTable:Set(strDBKeys.FinishedNormalCount, "value", num)
end

function OrderBoostModel:GetFinishedRoundWhenCannonOpen()
  return self.m_dbTable:GetValue(strDBKeys.CannonBoosterRound, "value") or 0
end

function OrderBoostModel:SetFinishedRoundWhenCannonOpen(num)
  self.m_dbTable:Set(strDBKeys.CannonBoosterRound, "value", num)
end

function OrderBoostModel:IsProConfig()
  return self.m_dbTable:GetValue(strDBKeys.IsProConfig, "value") == "1"
end

function OrderBoostModel:SetProConfig()
  self.m_dbTable:Set(strDBKeys.IsProConfig, "value", "1")
end

function OrderBoostModel:SetLessScoreRound(value)
  self.m_dbTable:Set(strDBKeys.LessScoreRound, "value", value)
end

function OrderBoostModel:GetLessScoreRound()
  return self.m_dbTable:GetValue(strDBKeys.LessScoreRound, "value") or 0
end

function OrderBoostModel:TrySetProEndTime()
  if self:GetState() == ActivityState.Started and self:GetLogicType() == EOrderBoostType.Super and self:GetProEndTime() == nil then
    local time = GM.GameModel:GetServerTime() + self.m_rewardConfig.last_time * 60
    self.m_dbTable:Set(strDBKeys.ProEndTime, "value", time)
    EventDispatcher.DispatchEvent(EEventType.OrderBoostProStart)
    self:SetFirstHint()
  end
end

function OrderBoostModel:GetProEndTime()
  return self.m_dbTable:GetValue(strDBKeys.ProEndTime, "value")
end

function OrderBoostModel:RemoveProEndTime()
  self.m_dbTable:Remove(strDBKeys.ProEndTime, "value")
end

function OrderBoostModel:SetTutorialGestureNum(value)
  self.m_dbTable:Set(strDBKeys.TutorialGestureNum, "value", value)
end

function OrderBoostModel:GetTutorialGestureNum()
  return self.m_dbTable:GetValue(strDBKeys.TutorialGestureNum, "value") or 0
end

function OrderBoostModel:IsProStart()
  if self.m_forceProClose then
    return false
  end
  return GM.ConfigModel:GetOrderBoostProConfig().IsOpen and GM.GameModel:GetServerTime() < GM.ConfigModel:GetOrderBoostProConfig().eTime
end

function OrderBoostModel:IsProConfigOpen()
  return GM.ConfigModel:GetOrderBoostProConfig().IsOpen and GM.GameModel:GetServerTime() < GM.ConfigModel:GetOrderBoostProConfig().rTime
end

function OrderBoostModel:SetCountdownTipPop(bPop)
  self.m_dbTable:Set(strDBKeys.PopCountdownTip, "value", bPop and "1" or "0")
end

function OrderBoostModel:CanPopCountdownTip()
  return self:GetLogicType() == EOrderBoostType.Super and self.m_dbTable:GetValue(strDBKeys.PopCountdownTip, "value") ~= "1"
end

function OrderBoostModel:GetLastTime()
  return self.m_rewardConfig.last_time * 60
end

function OrderBoostModel:CanRefreshEntry()
  return self.m_bTypeChanged
end

function OrderBoostModel:CanPopOrderBoostProWindow()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_dbTable:GetValue(strDBKeys.FirstProPopup, "value") == "1" then
    return false
  end
  if self.m_curInfo ~= nil and self:IsProConfig() and self:IsProStart() and not Table.IsEmpty(self.m_orderBoostProRewardConfig) then
    return true
  end
end

function OrderBoostModel:PopOrderBoostProWindow()
  self.m_dbTable:Set(strDBKeys.FirstProPopup, "value", "1")
end

function OrderBoostModel:IsProReward()
  return self.m_bProReward
end

function OrderBoostModel:IsCannonRewardOpen()
  return self.m_orderBoostExtraRewardConfig ~= nil and self.m_dbTable:GetValue(strDBKeys.CannonBoosterIsOpen, "value") == "1" and GM.LevelModel:GetCurrentLevel() >= self.m_orderBoostExtraRewardConfig[1].sLevel
end

function OrderBoostModel:TestFinishCurRound()
  local addScore = self.m_curInfo.MaxScore - self.m_curInfo.curScore
  self.m_curInfo.curScore = self.m_curInfo.MaxScore
  for _, slotConfig in ipairs(self.m_curOrderConfigs) do
    self.m_curInfo.orderFinishInfo[tostring(slotConfig.order_slot)] = slotConfig.order_num
  end
  self:SaveMetaData()
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
  EventDispatcher.DispatchEvent(EEventType.OrderBoostSmileChanged)
  EventDispatcher.DispatchEvent(EEventType.OrderBoostSmileAddScore, addScore)
  local reviewRaceModel = GM.ActivityManager:GetModel(ActivityType.ReviewRace)
  if reviewRaceModel then
    reviewRaceModel:FinishRace()
  end
end

function OrderBoostModel:TestForceToPro()
  if self:IsProStart() and not Table.IsEmpty(self.m_orderBoostProRewardConfig) and GM.TutorialModel:IsTutorialFinished("tutorial_order_boost_end") then
    if self.m_proTrigNum == nil then
      self.m_proTrigNum = math.random(self.m_rewardConfig.pro_trig_num[1], self.m_rewardConfig.pro_trig_num[2])
      self.m_dbTable:Set(strDBKeys.ProTrigNum, "value", self.m_proTrigNum)
    end
    local addScore = self.m_curInfo.MaxScore - self.m_curInfo.curScore
    self.m_curInfo.curScore = self.m_curInfo.MaxScore
    for _, slotConfig in ipairs(self.m_curOrderConfigs) do
      self.m_curInfo.orderFinishInfo[tostring(slotConfig.order_slot)] = slotConfig.order_num
    end
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
    EventDispatcher.DispatchEvent(EEventType.OrderBoostSmileChanged)
    EventDispatcher.DispatchEvent(EEventType.OrderBoostSmileAddScore, addScore)
    self:SetFinishedNormalCount(self.m_proTrigNum)
    self:SaveMetaData()
    local reviewRaceModel = GM.ActivityManager:GetModel(ActivityType.ReviewRace)
    if reviewRaceModel then
      reviewRaceModel:FinishRace()
    end
  else
    GM.UIManager:ShowPrompt("\230\151\160\230\179\149\229\188\128\229\144\175\232\182\133\231\186\167\231\172\145\232\132\184\232\174\162\229\141\149\239\188\154\230\163\128\230\159\165\233\133\141\231\189\174\230\152\175\229\144\166\229\188\128\229\144\175\227\128\129eTime\228\185\139\229\137\141\227\128\129\230\156\137\230\151\160\229\165\150\229\138\177\233\133\141\231\189\174\227\128\129\230\153\174\233\128\154\229\188\149\229\175\188\230\152\175\229\144\166\229\174\140\230\136\144")
  end
end

function OrderBoostModel:TestForceProClose()
  if not self.m_forceProClose or self.m_forceProClose == nil then
    self.m_forceProClose = true
    Log.Info("[\232\182\133\231\186\167\231\172\145\232\132\184] \232\182\133\231\186\167\229\183\178\229\133\179\233\151\173")
  else
    self.m_forceProClose = false
    Log.Info("[\232\182\133\231\186\167\231\172\145\232\132\184] \232\182\133\231\186\167\229\183\178\229\188\128\229\144\175")
  end
end

function OrderBoostModel:SetShownCannonProgress(num)
  self.m_dbTable:Set(strDBKeys.CannonBoosterShownRound, "value", num)
end

function OrderBoostModel:GetShownCannonProgress()
  return self.m_dbTable:GetValue(strDBKeys.CannonBoosterShownRound, "value")
end
