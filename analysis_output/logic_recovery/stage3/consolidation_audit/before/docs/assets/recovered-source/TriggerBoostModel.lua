TriggerBoostModel = setmetatable({}, BaseActivityModel)
TriggerBoostModel.__index = TriggerBoostModel
TriggerBoostModel.ScoreType = {
  gold = "gold_type",
  energy = "energy_type"
}
local strDBKeys = {
  TriggerCache = "TriggerCache",
  ActivationCache = "activationCache",
  ShowActivationCache = "showActivationCache",
  EnergyCostFromStartFin = "EnergyCostFromStartFin",
  HasTriggeredToday = "HasTriggeredToday"
}
TriggerBoostModel.DiscoStates = {
  Pink = "generatorBoost1_1",
  Yellow = "generatorBoost2_1",
  Colorful = "generatorBoost3_1"
}

function TriggerBoostModel:Init(dbTable)
  self:LoadCacheData(dbTable)
  BaseActivityModel.Init(self, ActivityType.TriggerBoost, dbTable)
  EventDispatcher.AddListener(EEventType.BoardCollect, self, self._OnBoardCollect)
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
  EventDispatcher.AddListener(EEventType.GoldScoreAcquired, self, self._OnGoldScoreAcquired)
  EventDispatcher.AddListener(EEventType.ItemSpread, self, self._OnItemSpread)
  EventDispatcher.AddListener(EEventType.ItemTransform, self, self._OnItemTransform)
  EventDispatcher.AddListener(EEventType.EnergyChanged, self, self._OnEnergyChanged)
  self:UpdatePerSecond()
end

function TriggerBoostModel:LoadCacheData(dbTable)
  self.m_canTriggerCache = json.decode(dbTable:GetValue(strDBKeys.TriggerCache, "value") or "")
  self.m_activationCache = json.decode(dbTable:GetValue(strDBKeys.ActivationCache, "value") or "")
  self.m_showActivationCache = json.decode(dbTable:GetValue(strDBKeys.ShowActivationCache, "value") or "")
  local config = require("Data.Config.ItemGenerateScore")
  self.m_ItemGenerateScoreConfig = {}
  for itemType, score in pairs(config) do
    local itemChain = GM.ItemDataModel:GetChainId(itemType)
    local level = GM.ItemDataModel:GetChainLevel(itemType)
    if itemChain and level then
      self.m_ItemGenerateScoreConfig[itemChain] = {Level = level, BaseScore = score}
    end
  end
end

function TriggerBoostModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(EEventType.TriggerBoostStateChanged)
  self:TryStartTriggerBoostActivity()
end

function TriggerBoostModel:TryStartTriggerBoostActivity()
  if not self:GetState() == ActivityState.Started then
    return
  end
  if self:IsTriggerOnGoning(false) then
    return
  end
  if not Table.IsEmpty(self.m_canTriggerCache) then
    return
  end
  self:ResetTriggerCache()
end

function TriggerBoostModel:TryResetTriggerCache()
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if self:IsTriggerOnGoning(false) then
    return
  end
  if Table.IsEmpty(self.m_canTriggerCache) then
    return
  end
  if self.m_canTriggerCache.startUTCZeroTime // Sec2Day ~= GM.GameModel:GetServerTime() // Sec2Day then
    self:ResetTriggerCache()
  end
end

TriggerBoostModel.FinishState = {
  noTrigger = 0,
  Faild = 1,
  Success = 2
}

function TriggerBoostModel:ResetTriggerCache(llEtime)
  llEtime = llEtime or GM.GameModel:GetServerTime()
  self.m_canTriggerCache = {}
  self.m_canTriggerCache.startUTCZeroTime = llEtime // Sec2Day * Sec2Day
  self.m_canTriggerCache.CostEnergyNum = 0
  self.m_canTriggerCache.toadyHasTriggered = -1
  self.m_canTriggerCache.FinishCurAllDisco = TriggerBoostModel.FinishState.noTrigger
  self:SaveCacheData()
end

function TriggerBoostModel:TryCloseActivationTriggerBoost()
  if not Table.IsEmpty(self.m_activationCache) and GM.GameModel:GetServerTime() >= self.m_activationCache.llEndTime then
    local isFinish = self:IsFinishRound()
    local llEtime = self.m_activationCache.llEndTime
    local popEndWindow = self.m_activationCache.PopEndWindow
    self.m_activationCache = nil
    self.m_showActivationCache = nil
    self:ResetTriggerCache(llEtime)
    self.m_canTriggerCache.toadyHasTriggered = llEtime
    self.m_canTriggerCache.FinishCurAllDisco = isFinish and TriggerBoostModel.FinishState.Success or TriggerBoostModel.FinishState.Faild
    if popEndWindow ~= true then
      self.m_canTriggerCache.FinishCurAllDisco = TriggerBoostModel.FinishState.noTrigger
    end
    self:SaveCacheData()
    EventDispatcher.DispatchEvent(EEventType.TriggerBoostDiscoActionEnded)
  end
end

function TriggerBoostModel:TryActivationTriggerBoost()
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if Table.IsEmpty(self.m_canTriggerCache) then
    return
  end
  if self:IsTriggerOnGoning() then
    return
  end
  if self.m_canTriggerCache.toadyHasTriggered ~= nil and self.m_canTriggerCache.toadyHasTriggered ~= -1 and self.m_canTriggerCache.toadyHasTriggered // Sec2Day == GM.GameModel:GetServerTime() // Sec2Day then
    return
  end
  if self.m_canTriggerCache.CostEnergyNum < self.m_triggerConfig.energy then
    return
  end
  if GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy) > self.m_triggerConfig.trigger_energy then
    return
  end
  local curGem = GM.ShopModel:GetEnergyCostExcludeFree()
  if curGem < self.m_triggerConfig.trigger_gem then
    return
  end
  local durationTime = math.min(Sec2Day - GM.GameModel:GetServerTime() % Sec2Day - 1, self.m_config.eTime - GM.GameModel:GetServerTime())
  if durationTime < self.m_triggerConfig.duration_min * 60 then
    return
  end
  durationTime = math.min(durationTime, self.m_triggerConfig.duration_max * 60)
  durationTime = math.min(durationTime, self.m_config.eTime - GM.GameModel:GetServerTime())
  local endTime = GM.GameModel:GetServerTime() + durationTime
  self.m_canTriggerCache = nil
  self.m_activationCache = {}
  self.m_activationCache.curScore = 0
  self.m_activationCache.level = 1
  self.m_activationCache.maxScore = self.m_rewardConfig[1].token
  self.m_activationCache.llEndTime = endTime
  self.m_activationCache.PopStartWindow = true
  self.m_activationCache.PopEndWindow = true
  self.m_activationCache.isFinish = false
  self.m_showActivationCache = Table.DeepCopy(self.m_activationCache)
  self:SaveCacheData()
  local bi_action = {
    id = self:GetId(),
    g = self:GetServerConfigGroupId(),
    remainTime = durationTime,
    startTime = GM.GameModel:GetServerTime()
  }
  GM.BIManager:LogAction(EBIType.TriggerBoostActivityStart, bi_action)
  self:SetCostFromStartFin(0)
  EventDispatcher.DispatchEvent(EEventType.TriggerBoostActivationStart)
end

function TriggerBoostModel:CanAddScore(isCoin)
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if not self:IsTriggerOnGoning() then
    return false
  end
  if self.m_rewardConfig[self.m_activationCache.level] == nil then
    return false
  end
  if isCoin then
    if self.m_triggerConfig.score_type ~= TriggerBoostModel.ScoreType.gold then
      return false
    end
  elseif self.m_triggerConfig.score_type ~= TriggerBoostModel.ScoreType.energy then
    return false
  end
  return true
end

function TriggerBoostModel:AddScore(score)
  if self:GetState() ~= ActivityState.Started then
    return
  end
  if not self:IsTriggerOnGoning() then
    return
  end
  self.m_activationCache.curScore = self.m_activationCache.curScore + score
  local bi_action = {
    id = self:GetId(),
    g = self:GetServerConfigGroupId(),
    s = score,
    startTime = GM.GameModel:GetServerTime()
  }
  GM.BIManager:LogAction(EBIType.TriggerBoostScoreGet, bi_action)
  while not self:IsTriggerAllFinished() and self.m_activationCache ~= nil and self.m_activationCache.curScore >= self.m_activationCache.maxScore do
    local extraScore = self.m_activationCache.curScore - self.m_activationCache.maxScore
    local reward = self.m_rewardConfig[self.m_activationCache.level].reward
    local preCache = Table.DeepCopy(self.m_activationCache)
    if self.m_rewardConfig[self.m_activationCache.level].isCyclic == 1 then
    else
      self.m_activationCache.level = self.m_activationCache.level + 1
    end
    local bi_action = {
      id = self:GetId(),
      g = self:GetServerConfigGroupId(),
      startTime = GM.GameModel:GetServerTime(),
      buffid = reward[PROPERTY_TYPE],
      eg = self:GetCostFromStartFin()
    }
    GM.BIManager:LogAction(EBIType.TriggerBoostStageFin, bi_action)
    local isFinsh = self.m_rewardConfig[self.m_activationCache.level] == nil
    if not isFinsh then
      self.m_activationCache.maxScore = self.m_rewardConfig[self.m_activationCache.level].token
      self.m_activationCache.curScore = extraScore
    end
    if isFinsh then
      self.m_activationCache.isFinish = true
    end
    if self.m_showActivationCache.level + 1 ~= self.m_activationCache.level then
      self.m_showActivationCache = preCache
      self.m_showActivationCache.curScore = 0
    end
    RewardApi.AcquireRewardsLogic({reward}, EPropertySource.Give, EBIType.TriggerBoostAcquireReward)
    EventDispatcher.DispatchEvent(EEventType.TriggerBoostActivationFinishStage, {isFinsh = isFinsh})
  end
  self:SaveCacheData()
end

function TriggerBoostModel:_OnGoldScoreAcquired(message)
  if not self:CanAddScore(true) then
    return
  end
  if message.scene == EBIType.ItemCollect then
    return
  end
  self:AddScore(message.count)
  if message.scene == EBIType.FinishOrder and GM.SceneManager:GetGameMode() == EGameMode.Main then
    self.m_cacheOrderScore = (self.m_cacheOrderScore or 0) + message.count
    return
  else
    if GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView) == nil then
      return
    end
    local entry = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView):GetHudButton(ESceneViewHudButtonKey.Triggerboost)
    if entry then
      entry:UpdateContent()
    end
  end
end

function TriggerBoostModel:_OnBoardCollect(message)
  if not self:CanAddScore(true) then
    return
  end
  local _, boardview = BoardModelHelper.GetActiveModel()
  if message.Rewards ~= nil then
    for _, reward in ipairs(message.Rewards) do
      if reward[PROPERTY_TYPE] == EPropertyType.Gold then
        self:AddScore(reward[PROPERTY_COUNT])
        if boardview == MainBoardView.GetInstance() then
          local itemModel = message.item
          local itemView = boardview:GetItemView(itemModel)
          local uiStartPos = Vector3.zero
          if itemView ~= nil then
            local screenPos = boardview:ConvertBoardPositionToScreenPosition(itemModel:GetPosition())
            uiStartPos = PositionUtil.UICameraScreen2World(screenPos)
          end
          RewardApi.AcquireRewardsInView({
            {
              [PROPERTY_TYPE] = EPropertyType.TriggerBoostScore,
              [PROPERTY_COUNT] = reward[PROPERTY_COUNT]
            }
          }, {
            arrWorldPos = {uiStartPos},
            noDelayTime = true
          })
        else
          local entry = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView):GetHudButton(ESceneViewHudButtonKey.Triggerboost)
          if entry then
            entry:UpdateContent()
          end
        end
        return
      end
    end
  end
end

function TriggerBoostModel:_OnOrderFinished(message)
  if self.m_cacheOrderScore ~= nil then
    local score = self.m_cacheOrderScore
    self.m_cacheOrderScore = nil
    if 0 < score then
      do
        local order = message.order
        local seq = DOTween.Sequence()
        seq:AppendInterval(0.5)
        seq:AppendCallback(function()
          local orderCell = MainBoardView.GetInstance():GetOrderArea():GetCell(order)
          if orderCell ~= nil then
            local worldPosition = orderCell:GetIconArea().transform.position
            local screenPos = MainBoardView.GetInstance():ConvertWorldPositionToScreenPosition(worldPosition)
            local uiStartPos = PositionUtil.UICameraScreen2World(screenPos)
            RewardApi.AcquireRewardsInView({
              {
                [PROPERTY_TYPE] = EPropertyType.TriggerBoostScore,
                [PROPERTY_COUNT] = score
              }
            }, {
              arrWorldPos = {uiStartPos},
              noDelayTime = true
            })
          end
        end)
      end
    end
  end
end

function TriggerBoostModel:_OnEnergyChanged(info)
  local preEnergy = info.prevEnergy
  local curEnergy = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy)
  local useEnergy = preEnergy - curEnergy
  if 0 < useEnergy then
    if self:GetState() ~= ActivityState.Started then
      return
    end
    if self:CanAddScore() then
      return
    end
    if not Table.IsEmpty(self.m_canTriggerCache) then
      self.m_canTriggerCache.CostEnergyNum = self.m_canTriggerCache.CostEnergyNum + useEnergy
    end
  end
end

function TriggerBoostModel:_OnItemSpread(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:SetCostFromStartFin(self:GetCostFromStartFin() + MathUtil.IntPow(2, message.EnergyBoostRatio))
    self:_TryGenerateScore(message.Source, message.New, message.EnergyBoostRatio)
  end
end

function TriggerBoostModel:_OnItemTransform(message)
  if message.Source:GetBoardModel() == GM.MainBoardModel and message.CostEnergy then
    self:SetCostFromStartFin(self:GetCostFromStartFin() + MathUtil.IntPow(2, message.EnergyBoostRatio))
    self:_TryGenerateScore(message.Source, message.New, 0)
  end
end

function TriggerBoostModel:_TryGenerateScore(sourceModel, newModel, energyBoostRatio)
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self:CanAddScore() then
    local itemType = newModel:GetType()
    local itemChain = GM.ItemDataModel:GetChainId(itemType)
    local config = self.m_ItemGenerateScoreConfig[itemChain]
    if config == nil then
      return
    end
    local level = GM.ItemDataModel:GetChainLevel(itemType)
    if level < config.Level then
      return
    end
    local score = MathUtil.IntPow(2, level - config.Level) * config.BaseScore
    score = score // 1
    self:AddScore(score)
    EventDispatcher.DispatchEvent(EEventType.TriggerBoostScoreChange, {item = newModel, score = score})
  end
  self:SaveCacheData()
end

function TriggerBoostModel:GetServerConfigGroupId()
  return self.m_triggerConfig.groupId
end

function TriggerBoostModel:_LoadOtherServerConfig(config)
  self.m_triggerConfig = config.triggerBoostConfig[1]
  self.m_rewardConfig = config.triggerBoostRewardConfig
  table.sort(self.m_rewardConfig, function(a, b)
    return a.level < b.level
  end)
end

function TriggerBoostModel:UpdatePerSecond()
  self:TryResetTriggerCache()
  self:TryCloseActivationTriggerBoost()
  self:TryActivationTriggerBoost()
  BaseActivityModel.UpdatePerSecond(self)
end

function TriggerBoostModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_canTriggerCache = nil
  self.m_activationCache = nil
  self.m_showActivationCache = nil
end

function TriggerBoostModel:SaveCacheData()
  self.m_dbTable:Set(strDBKeys.TriggerCache, "value", json.encode(self.m_canTriggerCache or "{}"))
  self.m_dbTable:Set(strDBKeys.ActivationCache, "value", json.encode(self.m_activationCache or "{}"))
  self.m_dbTable:Set(strDBKeys.ShowActivationCache, "value", json.encode(self.m_showActivationCache or "{}"))
end

function TriggerBoostModel:IsTriggerOnGoning(checkResource)
  if self:GetState(checkResource) ~= ActivityState.Started then
    return false
  end
  if Table.IsEmpty(self.m_activationCache) then
    return false
  end
  if self:IsTriggerAllFinished() then
    return false
  end
  return true
end

function TriggerBoostModel:GetTriggeCoseType()
  if self:IsTriggerOnGoning() then
    return self.m_triggerConfig.score_type
  end
end

function TriggerBoostModel:IsFinishRound()
  return self:IsTriggerAllFinished()
end

function TriggerBoostModel:IsTriggerAllFinished()
  if not Table.IsEmpty(self.m_activationCache) then
    return self.m_rewardConfig[self.m_activationCache.level] == nil
  end
  return false
end

function TriggerBoostModel:GetCurBuffLevel()
  if self:IsTriggerOnGoning() then
    return self.m_activationCache.level
  end
end

function TriggerBoostModel:GetCurrCacheData()
  if self:IsTriggerOnGoning() then
    return self.m_activationCache
  end
end

function TriggerBoostModel:GetPreAndCurCache()
  return Table.DeepCopy(self.m_showActivationCache), self.m_activationCache
end

function TriggerBoostModel:SyncShowCache()
  self.m_showActivationCache = Table.DeepCopy(self.m_activationCache)
  self:SaveCacheData()
end

function TriggerBoostModel:SetCostFromStartFin(cEnergy)
  self.m_dbTable:Set(strDBKeys.EnergyCostFromStartFin, "value", cEnergy)
end

function TriggerBoostModel:GetCostFromStartFin()
  return self.m_dbTable:GetValue(strDBKeys.EnergyCostFromStartFin, "value") or 0
end

function TriggerBoostModel:CanPopEndWindow()
  if not Table.IsEmpty(self.m_activationCache) then
    return self:IsFinishRound() and self.m_activationCache.PopEndWindow == true
  end
  if not Table.IsEmpty(self.m_canTriggerCache) then
    return self.m_canTriggerCache.FinishCurAllDisco ~= TriggerBoostModel.FinishState.noTrigger
  end
  return false
end

function TriggerBoostModel:PopEndWindow()
  if not Table.IsEmpty(self.m_activationCache) then
    self.m_activationCache.PopEndWindow = false
    self:SaveCacheData()
  end
  if not Table.IsEmpty(self.m_canTriggerCache) then
    self.m_canTriggerCache.FinishCurAllDisco = TriggerBoostModel.FinishState.noTrigger
    self:SaveCacheData()
  end
end

function TriggerBoostModel:GetFinCurAllDisco()
  if not Table.IsEmpty(self.m_activationCache) then
    return self:IsFinishRound()
  end
  if not Table.IsEmpty(self.m_canTriggerCache) then
    return self.m_canTriggerCache.FinishCurAllDisco == TriggerBoostModel.FinishState.Success
  end
  return false
end

function TriggerBoostModel:CanPopupStartWindow()
  if not self:IsTriggerOnGoning() then
    return false
  end
  if self.m_activationCache.PopStartWindow == true then
    return true
  end
  return false
end

function TriggerBoostModel:PopupStartWindow()
  if not self:IsTriggerOnGoning() then
    return
  end
  if self.m_activationCache.PopStartWindow == false then
    return
  end
  self.m_activationCache.PopStartWindow = false
  self:SaveCacheData()
end

function TriggerBoostModel:GetSmallIconEntryShowConfig()
  return {
    HudButtonKey = ESceneViewHudButtonKey.Triggerboost,
    prefab = UIPrefabConfigName.TriggerBoostBoardEntry,
    listener = {
      EEventType.TriggerBoostStateChanged,
      EEventType.TriggerBoostFinalLightClose,
      EEventType.TriggerBoostActivationStart,
      EEventType.TriggerBoostDiscoActionEnded
    },
    checkfunc = function()
      return self:IsTriggerOnGoning()
    end
  }
end

function TriggerBoostModel:GetResourceLabels()
  return {
    AddressableLabel.TriggerBoost,
    AddressableLabel.BoostCharge
  }
end

function TriggerBoostModel:TestTriggerBoostSatisfy()
  if self.m_triggerConfig then
    local durationTime = math.min(Sec2Day - GM.GameModel:GetServerTime() % Sec2Day - 1, self.m_config.eTime - GM.GameModel:GetServerTime())
    durationTime = math.min(durationTime, self.m_triggerConfig.duration_max * 60)
    durationTime = math.min(durationTime, self.m_config.eTime - GM.GameModel:GetServerTime())
    local endTime = GM.GameModel:GetServerTime() + durationTime
    self.m_canTriggerCache = nil
    self.m_activationCache = {}
    self.m_activationCache.curScore = 0
    self.m_activationCache.level = 1
    self.m_activationCache.maxScore = self.m_rewardConfig[1].token
    self.m_activationCache.llEndTime = endTime
    self.m_activationCache.PopStartWindow = true
    self.m_activationCache.PopEndWindow = true
    self.m_showActivationCache = Table.DeepCopy(self.m_activationCache)
    self:SaveCacheData()
    EventDispatcher.DispatchEvent(EEventType.TriggerBoostActivationStart)
  end
end

function TriggerBoostModel:TestFiniCurrStage()
  if self:IsTriggerOnGoning() then
    self:AddScore(self.m_activationCache.maxScore)
  end
end

function TriggerBoostModel:GetTestInfo()
  if self:GetState() ~= ActivityState.Started then
    return "\230\180\187\229\138\168\230\156\170\229\188\128\229\167\139"
  end
  if self:IsTriggerOnGoning() then
    return "\229\183\178\231\187\143\232\167\166\229\143\145"
  end
  if Table.IsEmpty(self.m_canTriggerCache) then
    return
  end
  local testInfo = ""
  testInfo = testInfo .. "\232\167\166\229\143\145\230\157\161\228\187\182:" .. "\n"
  local curGem = GM.ShopModel:GetEnergyCostExcludeFree()
  local serverTime = GM.GameModel:GetServerTime()
  local durationTime = math.min(Sec2Day - serverTime % Sec2Day - 1, self.m_config.eTime - serverTime)
  testInfo = testInfo .. "\233\146\187\231\159\179\232\180\173\228\185\176\228\189\147\229\138\155\231\154\132\230\161\163\228\189\141" .. curGem .. " \\ " .. self.m_triggerConfig.trigger_gem .. "\n"
  testInfo = testInfo .. "\230\182\136\232\128\151\228\189\147\229\138\155\231\154\132\230\149\176\233\135\143" .. self.m_canTriggerCache.CostEnergyNum .. " \\ " .. self.m_triggerConfig.energy .. "\n"
  testInfo = testInfo .. "\229\189\147\229\137\141\229\137\169\228\189\153\231\154\132\228\189\147\229\138\155" .. GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy) .. " \\ " .. self.m_triggerConfig.trigger_energy .. "\n"
  testInfo = testInfo .. "\230\180\187\229\138\168\230\151\182\233\151\180" .. durationTime .. " \\ " .. self.m_triggerConfig.duration_min * 60 .. "\n"
  return testInfo
end
