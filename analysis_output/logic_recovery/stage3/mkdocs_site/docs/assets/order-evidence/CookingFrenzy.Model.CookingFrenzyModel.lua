CookingFrenzyModel = setmetatable({}, BaseActivityModel)
CookingFrenzyModel.__index = CookingFrenzyModel
local CookieFrenzyRewardItemState = {
  orderBoostOrderLackItem = 1,
  orderLackItem = 2,
  orderBackItem = 3,
  orderRepeatItem = 12
}
local strDBKeys = {
  CookingFrenzyCurData = "CookingFrenzyCurData",
  CookingFrenzyLastEndTime = "CookingFrenzyLastEndTime",
  CookingFrenzyOpenWindowScore = "CookingFrenzyPopWindowScore",
  CookingFrenzyTriggerCount = "CookingFrenzyTriggerCount"
}
CookingFrenzyModel.SpineKeyAnimationMap = {
  copper = "1",
  silver = "2",
  gold = "3",
  ruby = "4"
}

function CookingFrenzyModel:Init(dbTable)
  BaseActivityModel.Init(self, ActivityType.CookingFrenzy, dbTable)
  self:LoadSaveData()
  EventDispatcher.AddListener(EEventType.ChangeGameMode, self, self._OnGameModeChanged)
  EventDispatcher.AddListener(EEventType.BoardCollect, self, self._OnBoardCollect)
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
  EventDispatcher.AddListener(EEventType.GoldScoreAcquired, self, self._OnGoldScoreAcquired)
  self.m_mapCacheAcquireReward = {}
  self.m_mapShowPlayersItem = {}
  self.m_bLogin = true
  EventDispatcher.AddListener(EEventType.LoginFinished, self, self._OnLoginFinished)
end

function CookingFrenzyModel:_OnLoginFinished()
  self:TryTriggerLogin()
  self.m_bLogin = true
end

function CookingFrenzyModel:LoadSaveData()
  self.m_curData = json.decode(self.m_dbTable:GetValue(strDBKeys.CookingFrenzyCurData, "value") or "")
  self.m_lastEndTime = tonumber(self.m_dbTable:GetValue(strDBKeys.CookingFrenzyLastEndTime, "value") or 0)
end

function CookingFrenzyModel:_OnGameModeChanged()
  EventDispatcher.DispatchEvent(EEventType.TestOutputTableInfo, {
    "\229\136\135\229\156\186\230\153\175\229\176\157\232\175\149\232\167\166\229\143\145\232\174\162\229\141\149\231\139\130\231\131\173" .. GM.SceneManager:GetGameMode()
  })
  self:TryCloseTrigger()
  if self:CanTrigger() then
    self:TriggerData()
  end
end

function CookingFrenzyModel:_OnGoldScoreAcquired(message)
  if not self:CanAddScore() or message.scene == EBIType.ItemCollect then
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
    local entry = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView):GetHudButton(ESceneViewHudButtonKey.CookingFrenzy)
    if entry ~= nil then
      entry:UpdateTextAnimation(0, message.count, false)
    end
  end
end

function CookingFrenzyModel:_OnBoardCollect(message)
  if self.m_curData == nil then
    return
  end
  local _, boardview = BoardModelHelper.GetActiveModel()
  if message.Rewards ~= nil and self:CanAddScore() then
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
              [PROPERTY_TYPE] = EPropertyType.CookingFrenzyScore,
              [PROPERTY_COUNT] = reward[PROPERTY_COUNT]
            }
          }, {
            arrWorldPos = {uiStartPos},
            noDelayTime = true
          })
        else
          local entry = GM.UIManager:GetOpenedViewByName(UIPrefabConfigName.BaseSceneView):GetHudButton(ESceneViewHudButtonKey.CookingFrenzy)
          if entry ~= nil then
            entry:UpdateTextAnimation(0, reward[PROPERTY_COUNT], false)
          end
        end
        return
      end
    end
  end
end

function CookingFrenzyModel:_OnOrderFinished(message)
  if self.m_cacheOrderScore ~= nil then
    local score = self.m_cacheOrderScore
    self.m_cacheOrderScore = nil
    if 0 < score then
      do
        local order = message.order
        local seq = DOTween.Sequence()
        seq:AppendInterval(0.5)
        if order:GetCookingFrenzyConfig() ~= nil then
          seq:AppendInterval(1)
        end
        seq:AppendCallback(function()
          local orderCell = MainBoardView.GetInstance():GetOrderArea():GetCell(order)
          if orderCell ~= nil then
            local worldPosition = orderCell:GetIconArea().transform.position
            local screenPos = MainBoardView.GetInstance():ConvertWorldPositionToScreenPosition(worldPosition)
            local uiStartPos = PositionUtil.UICameraScreen2World(screenPos)
            RewardApi.AcquireRewardsInView({
              {
                [PROPERTY_TYPE] = EPropertyType.CookingFrenzyScore,
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

function CookingFrenzyModel:CanAddScore()
  if self.m_curData == nil then
    return false
  end
  local levelConfigList = self.m_curData.m_levelConfig
  local lastConfig = levelConfigList[#levelConfigList]
  if lastConfig.score <= self.m_curData.m_score then
    return false
  end
  return true
end

function CookingFrenzyModel:AddScore(score)
  if self.m_curData == nil then
    Log.Error("\232\174\162\229\141\149\231\139\130\231\131\173 \229\138\160\229\136\134\233\148\153\232\175\175")
  end
  local levelConfigList = self.m_curData.m_levelConfig
  local lastConfig = levelConfigList[#levelConfigList]
  local addScore = math.min(lastConfig.score - self.m_curData.m_score, score)
  addScore = math.max(addScore, 0)
  local buffId = self:GetCurDoingBuff()
  self.m_curData.m_score = self.m_curData.m_score + addScore
  local newBuffId = self:GetCurDoingBuff()
  local curCount = tonumber(self.m_dbTable:GetValue(strDBKeys.CookingFrenzyTriggerCount, "value") or "") or 0
  if buffId ~= newBuffId then
    self:SetWaitOpenTriggerWindowState(true)
    EventDispatcher.DispatchEvent(EEventType.CookingFrenzyBuffChanged, {buffId = newBuffId})
    GM.BIManager:LogAction(EBIType.CookingFrenzyBuffTrigger, {buffId = newBuffId, round = curCount})
  end
  self:SaveData()
  EventDispatcher.DispatchEvent(EEventType.CookingFrenzyAddScore)
  GM.BIManager:LogAction(EBIType.CookingFrenzyScore, {
    round = curCount,
    score = self.m_curData.m_score,
    addScroe = addScore
  })
end

function CookingFrenzyModel:GetCurDoingBuff(score)
  if self.m_curData == nil then
    return nil
  end
  if score == nil then
    score = self.m_curData.m_score
  end
  local strBuffId
  local curIndex = 0
  for index, levelConfig in ipairs(self.m_curData.m_levelConfig) do
    if score < levelConfig.score then
      break
    end
    strBuffId = levelConfig.buff_id
    curIndex = index
  end
  local relaIndex = curIndex
  if #self.m_curData.m_levelConfig == 3 and strBuffId ~= nil then
    curIndex = curIndex + 1
  end
  return strBuffId, curIndex, relaIndex
end

function CookingFrenzyModel:GetCurBuffConifgByOrder(order)
  if self.m_curData == nil then
    return nil
  end
  local strBuffId = self:GetCurDoingBuff()
  if strBuffId == nil then
    return nil
  end
  for _, buffConfig in ipairs(self.m_curData.m_buffConfig) do
    if buffConfig.buff_id == strBuffId and order:GetDiffScore() >= buffConfig.diff_score_min and order:GetDiffScore() <= buffConfig.diff_score_max then
      return buffConfig
    end
  end
  return nil
end

function CookingFrenzyModel:CanTrigger()
  if not self:_CanTriggerNecessary() then
    return false
  end
  if GM.SceneManager:GetGameMode() ~= EGameMode.Main then
    return false
  end
  if not self.m_bLogin then
    return false
  end
  return true
end

function CookingFrenzyModel:_CanTriggerNecessary()
  if self:GetState() ~= ActivityState.Started then
    return false
  end
  if self.m_curData ~= nil then
    return false
  end
  if self.m_lastEndTime ~= nil and GM.GameModel:GetServerTime() < self.m_lastEndTime + self.m_CookingFrenzyconfig.m_generalConfig.cooldown * 60 then
    return false
  end
  return true
end

function CookingFrenzyModel:TryTriggerLogin()
  self:TryCloseTrigger()
  if GM.SceneManager:GetGameMode() ~= EGameMode.Main or not self:_CanTriggerNecessary() then
    return false
  end
  self:TriggerData()
  return true
end

function CookingFrenzyModel:TriggerData()
  self.m_curData = {}
  self.m_curData.m_score = 0
  self.m_curData.m_levelConfig = {}
  local curLevel = GM.LevelModel:GetCurrentLevel()
  for _, levelConfig in ipairs(self.m_CookingFrenzyconfig.m_levelConfig) do
    if curLevel >= levelConfig.sLv and curLevel <= levelConfig.eLv then
      table.insert(self.m_curData.m_levelConfig, levelConfig)
    end
  end
  table.sort(self.m_curData.m_levelConfig, function(a, b)
    return a.score < b.score
  end)
  local isreturn
  if GM.ReturnUserModel:IsInNewReturnExperienceTime() then
    self:SaveOpenWindowScore()
    self.m_curData.m_score = self.m_curData.m_levelConfig[1].score
    self:SetWaitOpenTriggerWindowState(true)
    isreturn = true
  else
    if self.m_lightMode == 1 then
      self:SetWaitPopLightWindowState(true)
    else
      self:SetWaitPopMainWindowState(true)
    end
    isreturn = false
  end
  self.m_curData.m_buffConfig = self.m_CookingFrenzyconfig.m_buffConfig
  self.m_curData.m_eTime = math.min(GM.GameModel:GetServerTime() + self.m_CookingFrenzyconfig.m_generalConfig.duration * 60, self.m_config.rTime)
  self.m_curData.m_sTime = GM.GameModel:GetServerTime()
  self.m_lastEndTime = self.m_curData.m_eTime
  self.m_bLogin = false
  EventDispatcher.DispatchEvent(EEventType.CookingFrenzyTriggerChanged)
  self:SaveData()
  local curCount = tonumber(self.m_dbTable:GetValue(strDBKeys.CookingFrenzyTriggerCount, "value") or "") or 0
  curCount = curCount + 1
  GM.BIManager:LogAction(EBIType.CookingFrenzyStart, {
    cnt = curCount,
    isReturn = tostring(isreturn)
  })
  self.m_dbTable:Set(strDBKeys.CookingFrenzyTriggerCount, "value", tostring(curCount))
end

function CookingFrenzyModel:TryCloseTrigger()
  if self.m_curData == nil then
    return
  end
  if self.m_curData.m_eTime <= GM.GameModel:GetServerTime() then
    local buffID = self:GetCurDoingBuff()
    local sTime = self.m_curData.m_sTime
    local eTime = self.m_curData.m_eTime
    self.m_curData = nil
    EventDispatcher.DispatchEvent(EEventType.CookingFrenzyTriggerChanged)
    EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
    self:SetWaitOpenTriggerWindowState(false)
    self:SetWaitPopMainWindowState(false)
    self:SetWaitPopLightWindowState(false)
    self:SaveData()
    local curCount = tonumber(self.m_dbTable:GetValue(strDBKeys.CookingFrenzyTriggerCount, "value") or "") or 0
    GM.BIManager:LogAction(EBIType.CookingFrenzyBuffEnded, {
      sTime = sTime,
      eTime = eTime,
      buffId = buffID,
      duration = eTime - sTime,
      round = curCount
    })
  end
end

function CookingFrenzyModel:SaveData()
  if self.m_curData == nil then
    self.m_dbTable:Remove(strDBKeys.CookingFrenzyCurData, "value")
  else
    self.m_dbTable:Set(strDBKeys.CookingFrenzyCurData, "value", json.encode(self.m_curData))
    self.m_dbTable:Set(strDBKeys.CookingFrenzyLastEndTime, "value", self.m_curData.m_eTime)
  end
end

function CookingFrenzyModel:_DropData()
  BaseActivityModel._DropData(self)
  self.m_curData = nil
  self.m_lastEndTime = nil
  self:SetWaitOpenTriggerWindowState(false)
  self:SetWaitPopMainWindowState(false)
  self:SetWaitPopLightWindowState(false)
  EventDispatcher.DispatchEvent(EEventType.OrderStatusChanged)
end

function CookingFrenzyModel:UpdatePerSecond()
  BaseActivityModel.UpdatePerSecond(self)
  self:TryCloseTrigger()
end

function CookingFrenzyModel:_OnStateChanged()
  EventDispatcher.DispatchEvent(EEventType.CookingFrenzyStateChanged)
end

function CookingFrenzyModel:IsShowEntry()
  if self.m_curData ~= nil then
    return true
  end
  return false
end

function CookingFrenzyModel:_LoadOtherServerConfig(config)
  self.m_CookingFrenzyconfig = {}
  self.m_CookingFrenzyconfig.m_generalConfig = config.cookingFrenzyGeneralConfig[1]
  self.m_CookingFrenzyconfig.m_levelConfig = config.cookingFrenzyLevelConfig
  self.m_CookingFrenzyconfig.m_buffConfig = config.cookingFrenzyBuffConfig
  self.m_CookingFrenzyconfig.rTime = config.rTime
  table.sort(self.m_CookingFrenzyconfig.m_levelConfig, function(a, b)
    return a.score < b.score
  end)
  self.m_lightMode = GM.ConfigModel:GetGeneralConfByType(EGeneralConfType.CookingFrenzyLight, ConfigModel.EGeneralConfigParam.Int, 0)
end

function CookingFrenzyModel:AcquireRandomRewards(cfg, order)
  local itemRandomCodes = self:GetCookingFrenzyItemCode(order, cfg)
  local rewards = {}
  local randomIndex = 1
  if cfg.win_all ~= 1 then
    local curRandomRange = {}
    local itemNumWeight = 0
    local randomItemReward = {}
    local index = 1
    for curRewardIndex, reward in ipairs(cfg.rewards) do
      if reward[PROPERTY_TYPE] == EPropertyType.CookingFrenzyItem then
        itemNumWeight = itemNumWeight + reward.Weight
        table.insert(randomItemReward, {reward = reward, index = index})
        index = index + 1
      else
        table.insert(curRandomRange, reward)
      end
    end
    if 0 < itemNumWeight then
      table.insert(curRandomRange, {
        [PROPERTY_TYPE] = EPropertyType.CookingFrenzyItem,
        Weight = itemNumWeight,
        [PROPERTY_COUNT] = 1
      })
    end
    local optionReward = Table.ListWeightSelectOne(curRandomRange)
    if optionReward[PROPERTY_TYPE] == EPropertyType.CookingFrenzyItem then
      local itemRandomCodes = self:GetCookingFrenzyItemCode(order, cfg)
      for index, reward in ipairs(randomItemReward) do
        if itemRandomCodes[reward.index].state == CookieFrenzyRewardItemState.orderBoostOrderLackItem then
          randomItemReward[reward.index].Weight = randomItemReward[reward.index].reward.Weight * 10000
        elseif itemRandomCodes[reward.index].state == CookieFrenzyRewardItemState.orderLackItem then
          randomItemReward[reward.index].Weight = randomItemReward[reward.index].reward.Weight * 100
        else
          randomItemReward[reward.index].Weight = randomItemReward[reward.index].reward.Weight
        end
      end
      if GameConfig.IsTestMode() then
        local strTest = ""
        strTest = strTest .. "\232\190\147\229\135\186\232\174\162\229\141\149\231\139\130\231\131\173\233\128\137\230\139\169\230\163\139\229\173\144\231\154\132\229\136\164\230\150\173\n"
        for index, info in pairs(randomItemReward) do
          strTest = strTest .. "\231\172\172" .. tostring(index) .. "\228\184\170\229\165\150\229\138\177\n"
          strTest = strTest .. tostring("\230\157\131\233\135\141\239\188\154") .. tostring(info.Weight)
          strTest = strTest .. tostring("\230\163\139\229\173\144\239\188\154") .. tostring(itemRandomCodes[info.index].item)
        end
        Log.Info(strTest)
      end
      local targetReward = Table.ListWeightSelectOne(randomItemReward)
      rewards = {
        targetReward.reward
      }
      randomIndex = targetReward.index
    else
      rewards = {optionReward}
    end
  else
    rewards = cfg.rewards
  end
  local fixedMaxNum = 0
  for _, reward in ipairs(rewards) do
    if GM.ItemDataModel:GetModelConfig(reward[PROPERTY_TYPE], true) ~= nil then
      fixedMaxNum = fixedMaxNum + reward.MaxNum
    end
  end
  local boarNewPos = BoardPosition.Create(4, 9)
  local listItemEmptyPos = GM.MainBoardModel:FindEmptyPositionInSpreadOrderWithNum(boarNewPos, nil, #itemRandomCodes + fixedMaxNum, true)
  local posIndex = 1
  rewards = Table.DeepCopy(rewards)
  local targetRewards = {}
  for _, reward in ipairs(rewards) do
    if reward[PROPERTY_TYPE] == EPropertyType.CookingFrenzyItem then
      local newItem = itemRandomCodes[randomIndex].item
      reward[PROPERTY_TYPE] = newItem
      reward[PROPERTY_COUNT] = 1
      if listItemEmptyPos[posIndex] ~= nil then
        reward.itemPos = listItemEmptyPos[posIndex]
      else
        reward.isCookingFrenzyItem = true
      end
      randomIndex = randomIndex + 1
      posIndex = posIndex + 1
      table.insert(targetRewards, reward)
    elseif GM.ItemDataModel:GetModelConfig(reward[PROPERTY_TYPE], true) ~= nil then
      local num = math.ceil(MathUtil.Random(reward.MinNum, reward.MaxNum))
      for i = 1, num do
        local newReward = {}
        newReward[PROPERTY_TYPE] = reward[PROPERTY_TYPE]
        newReward[PROPERTY_COUNT] = 1
        if listItemEmptyPos[posIndex] ~= nil then
          newReward.itemPos = listItemEmptyPos[posIndex]
        else
          newReward.isCookingFrenzyItem = true
        end
        posIndex = posIndex + 1
        table.insert(targetRewards, newReward)
      end
    else
      reward[PROPERTY_COUNT] = math.ceil(MathUtil.Random(reward.MinNum, reward.MaxNum))
      table.insert(targetRewards, RewardApi.ConvertDynamicReward(reward))
    end
  end
  self.m_mapCacheAcquireReward[order] = targetRewards
  return targetRewards
end

function CookingFrenzyModel:GetCookingFrenzyItemCode(order, cfg)
  local bRefresh = false
  if self.m_mapShowPlayersItem == nil then
    self.m_mapShowPlayersItem = {}
  end
  local isTestLog = GameConfig.IsTestMode()
  local strTest = ""
  if isTestLog then
    strTest = strTest .. "\232\174\162\229\141\149\231\139\130\231\131\173\229\188\128\229\167\139\229\149\166 \n \229\189\147\229\137\141\233\154\143\230\156\186\231\154\132\232\174\162\229\141\149\230\167\189\228\189\141" .. tostring(order:GetSlot()) .. "\n"
    strTest = strTest .. "\229\189\147\229\137\141\232\174\162\229\141\149\231\154\132\233\154\190\229\186\166\229\136\134: " .. order:GetDiffScore() .. " \n"
    strTest = strTest .. "\229\189\147\229\137\141\232\174\162\229\141\149\231\139\130\231\131\173\231\154\132buffID : " .. cfg.buff_id .. " \n"
  end
  local strTempTest = ""
  if self.m_mapShowPlayersItem[order] == nil then
    bRefresh = true
  else
    local listCodes = self.m_mapShowPlayersItem[order]
    local randomIndex = 1
    local cfgItemNum = 0
    for _, reward in ipairs(cfg.rewards) do
      if reward[PROPERTY_TYPE] == EPropertyType.CookingFrenzyItem then
        cfgItemNum = cfgItemNum + 1
      end
    end
    if #listCodes ~= cfgItemNum then
      bRefresh = true
    else
      for _, reward in ipairs(cfg.rewards) do
        if reward[PROPERTY_TYPE] == EPropertyType.CookingFrenzyItem then
          if GameConfig.IsTestMode() then
            strTempTest = strTempTest .. "\n\229\189\147\229\137\141\231\172\172 " .. tostring(randomIndex) .. "\228\184\170\230\163\139\229\173\144\229\165\150\229\138\177 \n"
          end
          local curCode = listCodes[randomIndex].item
          randomIndex = randomIndex + 1
          local ListtargetItems, streleTest = self:GetOptionalChessPieces(order, reward)
          strTempTest = strTempTest .. streleTest
          local targetItems = {}
          for _, listItem in ipairs(ListtargetItems) do
            if 0 < #listItem then
              targetItems = listItem
              break
            end
          end
          local newTargetItems = {}
          for i = 1, #targetItems do
            local bFind = false
            for j = 1, #listCodes do
              if listCodes[j].item == targetItems[i] then
                bFind = true
                break
              end
            end
            if not bFind then
              table.insert(newTargetItems, targetItems[i])
            end
          end
          local bFind = false
          if #newTargetItems == 0 then
            bFind = true
          else
            for i = 1, #targetItems do
              if curCode == targetItems[i] then
                bFind = true
                break
              end
            end
          end
          if not bFind then
            bRefresh = true
            break
          end
        end
      end
    end
  end
  if bRefresh == true then
    if GameConfig.IsTestMode() then
      strTest = strTest .. " \n  \n \229\136\183\230\150\176\228\186\134\229\165\150\229\138\177 \n \n"
    end
    self.m_mapShowPlayersItem[order] = {}
    local index = 1
    local listCacheItemIndex = {}
    for _, reward in ipairs(cfg.rewards) do
      if reward[PROPERTY_TYPE] == EPropertyType.CookingFrenzyItem then
        if GameConfig.IsTestMode() then
          strTest = strTest .. "\n\229\189\147\229\137\141\231\172\172 " .. tostring(index) .. "\228\184\170\230\163\139\229\173\144\229\165\150\229\138\177 \n"
        end
        local targetItems, testLog = self:GetOptionalChessPieces(order, reward)
        strTest = strTest .. testLog
        local allTargetItem = {}
        for i = 1, #targetItems do
          for j = 1, #targetItems[i] do
            table.insert(allTargetItem, targetItems[i][j])
          end
        end
        table.insert(listCacheItemIndex, {
          items = Table.DeepCopy(targetItems),
          index = index,
          realItems = Table.DeepCopy(allTargetItem)
        })
        index = index + 1
      end
    end
    local orderBoostOrderLackMap = GM.MainBoardModel:GetOrderBoostOrderCodeLackMap()
    if GameConfig.IsTestMode() then
      strTest = strTest .. "\229\188\128\229\167\139\229\176\189\233\135\143\228\191\157\232\175\129\228\184\141\233\135\141\229\164\141 \228\188\152\229\133\136\229\136\134\233\133\141\233\156\128\230\177\130\229\176\145\231\154\132\239\188\140 \233\156\128\230\177\130\229\176\145\231\154\132\229\136\134\233\133\141\229\174\140\229\136\183\230\150\176\229\144\142\229\156\168\229\136\134\233\133\141\233\156\128\230\177\130\229\164\154\231\154\132\n"
    end
    local targetFindItems = {}
    while #listCacheItemIndex ~= 0 do
      table.sort(listCacheItemIndex, function(a, b)
        if #a.items ~= 0 and #b.items ~= 0 then
          for i = 1, #a.items do
            if #b.items[i] == nil then
              return true
            elseif #a.items[i] == 0 and #b.items[i] ~= 0 then
              return false
            elseif #a.items[i] ~= 0 and #b.items[i] == 0 then
              return true
            elseif #a.items[i] ~= #b.items[i] then
              return #a.items[i] < #b.items[i]
            end
          end
          return true
        elseif #a.items ~= 0 then
          return true
        elseif #b.items ~= 0 then
          return false
        else
          return true
        end
      end)
      local curItem = table.remove(listCacheItemIndex, 1)
      local curList = curItem.items
      local curIndex = curItem.index
      local targetList = {}
      local itemState = 0
      for i = 1, #curList do
        if 0 < #curList[i] then
          itemState = i
          targetList = curList[i]
          break
        end
      end
      if #targetList == 0 then
        targetList = curItem.realItems
        itemState = CookieFrenzyRewardItemState.orderRepeatItem
      end
      local item = Table.ListRandomSelectOne(targetList)
      targetFindItems[curIndex] = {item = item, state = itemState}
      if GameConfig.IsTestMode() then
        strTest = strTest .. "\231\172\172" .. tostring(curIndex) .. "\229\165\150\229\138\177\239\188\140 \230\163\139\229\173\144\230\152\175" .. tostring(targetFindItems[curIndex].item)
        if itemState == CookieFrenzyRewardItemState.orderBackItem then
          strTest = strTest .. "\229\164\135\233\128\137\230\163\139\229\173\144 \n"
        elseif itemState == CookieFrenzyRewardItemState.orderBoostOrderLackItem then
          strTest = strTest .. "\232\174\162\229\141\149boost\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144 \n"
        elseif itemState == CookieFrenzyRewardItemState.orderLackItem then
          strTest = strTest .. "\230\153\174\233\128\154\232\174\162\229\141\149\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144 \n"
        elseif itemState == CookieFrenzyRewardItemState.orderRepeatItem then
          strTest = strTest .. "\233\135\141\229\164\141\231\154\132\230\163\139\229\173\144 \n"
        end
      end
      local itemCode = targetFindItems[curIndex].item
      for i = 1, #listCacheItemIndex do
        for j = #listCacheItemIndex[i].items, 1, -1 do
          for z = #listCacheItemIndex[i].items[j], 1, -1 do
            if listCacheItemIndex[i].items[j][z] == itemCode then
              table.remove(listCacheItemIndex[i].items[j], z)
            end
          end
        end
      end
    end
    self.m_mapShowPlayersItem[order] = targetFindItems
  else
    local listCodes = self.m_mapShowPlayersItem[order]
    strTest = strTest .. strTempTest
    strTest = strTest .. " \n \n \230\156\170\229\136\183\230\150\176\229\165\150\229\138\177 \n \n"
    for inedex, itemInfo in pairs(listCodes) do
      strTest = strTest .. "\231\172\172" .. tostring(inedex) .. "\229\165\150\229\138\177\239\188\140 \230\163\139\229\173\144\230\152\175" .. tostring(itemInfo.item)
      local itemState = itemInfo.state
      if itemState == CookieFrenzyRewardItemState.orderBackItem then
        strTest = strTest .. "\229\164\135\233\128\137\230\163\139\229\173\144 \n"
      elseif itemState == CookieFrenzyRewardItemState.orderBoostOrderLackItem then
        strTest = strTest .. "\232\174\162\229\141\149boost\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144 \n"
      elseif itemState == CookieFrenzyRewardItemState.orderLackItem then
        strTest = strTest .. "\230\153\174\233\128\154\232\174\162\229\141\149\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144 \n"
      elseif itemState == CookieFrenzyRewardItemState.orderRepeatItem then
        strTest = strTest .. "\233\135\141\229\164\141\231\154\132\230\163\139\229\173\144 \n"
      end
    end
  end
  if GameConfig.IsTestMode() then
    Log.Info(strTest)
  end
  return self.m_mapShowPlayersItem[order]
end

function CookingFrenzyModel:GetOptionalChessPieces(order, reward)
  local strTest = ""
  local isTestLog = GameConfig.IsTestMode()
  local minScore = reward.MinNum
  local maxScore = reward.MaxNum
  local orderItemsConfig = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
  local mapLackItems = Table.DeepCopy(GM.MainBoardModel:GetOrderCodeLackCountMap())
  local curOrderRequirements = order:GetRequirements()
  for _, item in ipairs(curOrderRequirements) do
    if mapLackItems[item] ~= nil then
      mapLackItems[item] = mapLackItems[item] - 1
      if mapLackItems[item] == 0 then
        mapLackItems[item] = nil
      end
    end
  end
  local missing_requested_chain_maxLevel = {}
  for item, _ in pairs(mapLackItems) do
    local chainId = GM.ItemDataModel:GetChainId(item)
    if missing_requested_chain_maxLevel[chainId] == nil then
      missing_requested_chain_maxLevel[chainId] = GM.ItemDataModel:GetChainLevel(item)
    else
      missing_requested_chain_maxLevel[chainId] = math.max(missing_requested_chain_maxLevel[chainId], GM.ItemDataModel:GetChainLevel(item))
    end
  end
  local orderboostLackMap = Table.DeepCopy(GM.MainBoardModel:GetOrderBoostOrderCodeLackMap())
  local curOrderRequirements = order:GetRequirements()
  for _, item in ipairs(curOrderRequirements) do
    if orderboostLackMap[item] ~= nil then
      orderboostLackMap[item] = orderboostLackMap[item] - 1
    end
  end
  local curSelcetableItems = {}
  local curOrderBoostSeleceedItems = {}
  for chainId, maxLevel in pairs(missing_requested_chain_maxLevel) do
    for level = 1, maxLevel do
      local item = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, level)
      curSelcetableItems[item] = true
    end
  end
  for itemCode, num in pairs(orderboostLackMap) do
    if 0 < num then
      local maxLevel = GM.ItemDataModel:GetChainLevel(itemCode)
      local chainId = GM.ItemDataModel:GetChainId(itemCode)
      for level = 1, maxLevel do
        local item = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, level)
        curOrderBoostSeleceedItems[item] = true
      end
    end
  end
  local targetItems = {}
  targetItems[CookieFrenzyRewardItemState.orderBoostOrderLackItem] = {}
  targetItems[CookieFrenzyRewardItemState.orderLackItem] = {}
  targetItems[CookieFrenzyRewardItemState.orderBackItem] = {}
  for itemCode, _ in pairs(orderItemsConfig) do
    local isUnLockProduct = false
    local chainId = GM.ItemDataModel:GetChainId(itemCode)
    local generators = GM.ItemDataModel:GetChainGenerators(chainId)
    for _, generator in ipairs(generators) do
      if GM.ItemDataModel:IsUnlocked(generator) then
        isUnLockProduct = true
        break
      end
    end
    if orderItemsConfig[itemCode].DiffScore ~= nil and minScore <= orderItemsConfig[itemCode].DiffScore and maxScore >= orderItemsConfig[itemCode].DiffScore and orderItemsConfig[itemCode].UnlockLevel <= GM.LevelModel:GetCurrentLevel() and isUnLockProduct then
      if curOrderBoostSeleceedItems[itemCode] ~= nil then
        table.insert(targetItems[1], itemCode)
      elseif curSelcetableItems[itemCode] ~= nil then
        table.insert(targetItems[2], itemCode)
      end
      table.insert(targetItems[3], itemCode)
    end
  end
  if GameConfig.IsTestMode() then
    strTest = strTest .. "\229\189\147\229\137\141\229\165\150\229\138\177\230\163\139\229\173\144\231\154\132\233\154\190\229\186\166\229\136\134 " .. tostring(minScore) .. " - " .. tostring(maxScore) .. "\n"
    strTest = strTest .. "\231\172\166\229\144\136\233\154\190\229\186\166\229\136\134\239\188\140\231\173\137\231\186\167\229\144\136\233\128\130\239\188\140\228\184\148\230\175\141\228\189\147\230\163\139\229\173\144\232\167\163\233\148\129\231\154\132\230\163\139\229\173\144\239\188\154\n"
    for _, itemCode in pairs(targetItems[3]) do
      strTest = strTest .. itemCode .. " "
    end
    strTest = strTest .. "\n"
    strTest = strTest .. "\229\133\182\228\187\150\232\174\162\229\141\149\228\184\173\231\188\186\229\176\145\230\163\139\229\173\144\231\154\132\228\184\170\230\149\176\239\188\154\n"
    for item, num in pairs(mapLackItems) do
      strTest = strTest .. item .. " : " .. tostring(num) .. "\n"
    end
    strTest = strTest .. "\231\172\166\229\144\136\239\188\136\233\154\190\229\186\166\229\136\134\232\140\131\229\155\180\239\188\137&\239\188\136\229\133\182\228\187\150\232\174\162\229\141\149\231\188\186\229\176\145\230\163\139\229\173\144\229\143\138\229\144\136\230\136\144\231\186\191\228\184\138\228\189\142\231\186\167\230\163\139\229\173\144\239\188\137\228\186\164\233\155\134\231\154\132\230\163\139\229\173\144:\n"
    for _, itemCode in pairs(targetItems[1]) do
      strTest = strTest .. itemCode .. " "
    end
    for _, itemCode in pairs(targetItems[2]) do
      strTest = strTest .. itemCode .. " "
    end
    strTest = strTest .. "\n"
    strTest = strTest .. "\228\186\164\233\155\134\230\163\139\229\173\144\228\184\173\229\177\158\228\186\142\231\172\145\232\132\184\232\174\162\229\141\149\231\154\132\230\152\175:\n"
    for _, itemCode in pairs(targetItems[1]) do
      strTest = strTest .. itemCode .. " "
    end
  end
  return targetItems, strTest
end

function CookingFrenzyModel:PopShowRewardByCfg(order)
  if self.m_mapCacheAcquireReward[order] == nil then
    return nil
  end
  local target = self.m_mapCacheAcquireReward[order]
  self.m_mapCacheAcquireReward[order] = nil
  return target
end

function CookingFrenzyModel:GetBIRewardByOrder(order)
  if self.m_mapCacheAcquireReward[order] == nil then
    return nil
  end
  local biReward
  if self.m_mapCacheAcquireReward[order] ~= nil then
    biReward = Table.DeepCopy(self.m_mapCacheAcquireReward[order])
    for k, reward in ipairs(biReward) do
      if reward.itemPos ~= nil then
        biReward[k] = reward
        biReward[k].itemPos = tostring(reward.itemPos)
        local itemCodeConfigMap = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
        local score = 0
        score = itemCodeConfigMap[reward[PROPERTY_TYPE]] ~= nil and itemCodeConfigMap[reward[PROPERTY_TYPE]].DiffScore or score
        local itemLevel = 0
        if 126 <= score then
          itemLevel = 3
        elseif 61 <= score then
          itemLevel = 2
        elseif 31 <= score then
          itemLevel = 1
        end
        biReward[k].itemLevel = itemLevel
      else
        biReward[k] = reward
      end
    end
  end
  return biReward
end

function CookingFrenzyModel:GetCurData()
  return self.m_curData
end

function CookingFrenzyModel:GetWaitPopMainWindowState()
  return self.m_waitOpenMainWindow
end

function CookingFrenzyModel:SetWaitPopMainWindowState(bState)
  self.m_waitOpenMainWindow = bState
end

function CookingFrenzyModel:GetWaitPopLightWindowState()
  return self.m_waitOpenLightWindow
end

function CookingFrenzyModel:SetWaitPopLightWindowState(bState)
  self.m_waitOpenLightWindow = bState
end

function CookingFrenzyModel:GetWaitOpenTriggerWindowState()
  return self.m_bWaitOpenTriggerWindow
end

function CookingFrenzyModel:SetWaitOpenTriggerWindowState(bState)
  self.m_bWaitOpenTriggerWindow = bState
end

function CookingFrenzyModel:SaveOpenWindowScore()
  self.m_dbTable:Set(strDBKeys.CookingFrenzyOpenWindowScore, "value", tostring(self.m_curData.m_score))
end

function CookingFrenzyModel:GetLastOpenWindowScore()
  return tonumber(self.m_dbTable:GetValue(strDBKeys.CookingFrenzyOpenWindowScore, "value") or "") or 0
end

function CookingFrenzyModel:GetResourceLabels()
  return {
    AddressableLabel.CookingFrenzy
  }
end

function CookingFrenzyModel:IsActive()
  if self.m_curData ~= nil then
    return true
  elseif self:CanTrigger() then
    return true
  else
    return false
  end
end

function CookingFrenzyModel:CanPopupNotificationWindow()
  if self.m_curData == nil then
    return false
  end
  local _, __, id = self:GetCurDoingBuff()
  if id ~= 1 then
    return false
  end
  return self.m_curData.m_eTime - GM.GameModel:GetServerTime() > 7200
end

function CookingFrenzyModel:GetNotificationDelay()
  if self.m_curData == nil then
    return 0
  end
  local _, __, id = self:GetCurDoingBuff()
  if id == 0 then
    return 0
  end
  return self.m_curData.m_eTime - GM.GameModel:GetServerTime() - 3600
end
