BoostChargeDiscoBoostHandler = setmetatable({}, BoostChargePropertyBaseHandler)
BoostChargeDiscoBoostHandler.__index = BoostChargeDiscoBoostHandler

function BoostChargeDiscoBoostHandler.Create(propertyType, manager)
  local handler = setmetatable({}, BoostChargeDiscoBoostHandler)
  handler:Init(propertyType, manager)
  return handler
end

function BoostChargeDiscoBoostHandler:Init(propertyType, manager)
  BoostChargePropertyBaseHandler:Init(propertyType, manager)
  self.m_mapGenerateCodeCache = {}
end

function BoostChargeDiscoBoostHandler:LoadServerConfig()
  self.m_mapDiscoConfig = {}
  local discoConfig = GM.ConfigModel:GetServerConfig(ServerConfigKey.DiscoContentConfig)
  if discoConfig == nil then
    return
  end
  for _, v in ipairs(discoConfig) do
    self.m_mapDiscoConfig[v.type] = v
  end
end

function BoostChargeDiscoBoostHandler:GetRewardIconNameAndIsSetNativeSize(rewardType)
  if self.m_mapDiscoConfig[rewardType] ~= nil then
    return ImageFileConfigName.icon_energy_big, true
  end
end

function BoostChargeDiscoBoostHandler:GetDiscoConfigByType(type)
  if self.m_mapDiscoConfig[type] then
    return self.m_mapDiscoConfig[type]
  end
  Log.Error("\230\178\161\230\156\137\232\191\153\228\184\170\231\177\187\229\158\139\231\154\132\231\129\175\231\144\131\229\138\169\229\138\155\233\133\141\231\189\174\239\188\140\231\177\187\229\158\139\230\152\175" .. type)
  return nil
end

function BoostChargeDiscoBoostHandler:Acquire(reward, args)
  local rewardType = reward[PROPERTY_TYPE]
  local config = self:GetDiscoConfigByType(rewardType)
  if config == nil then
    return
  end
  local oldCurProperty
  if self:IsBoostDiscoActive() then
    oldCurProperty = self.m_cacheData.curProperty
  end
  local rewardNum = config.score * reward[PROPERTY_COUNT]
  if self.m_cacheData == nil then
    self.m_cacheData = {}
    self.m_cacheData.boostChargeNum = 0
    self.m_cacheData.canPopUpWindow = false
    self.m_cacheData.MaxChargeNum = 0
  end
  self.m_cacheData.boostChargeNum = self.m_cacheData.boostChargeNum + rewardNum
  self.m_cacheData.MaxChargeNum = self.m_cacheData.boostChargeNum
  if self.m_cacheData.boostChargeNum > 0 then
    self.m_cacheData.canPopUpWindow = true
  end
  self.m_cacheData.curProperty = rewardType
  self:SaveCacheData()
  EventDispatcher.DispatchEvent(EEventType.TriggerBoostDiscoStarted)
  local biAction = {}
  local TriggerBoostModel = GM.ActivityManager:GetModel(ActivityType.TriggerBoost)
  if TriggerBoostModel ~= nil and TriggerBoostModel:IsTriggerOnGoning() then
    biAction = {
      id = TriggerBoostModel:GetId(),
      g = TriggerBoostModel:GetServerConfigGroupId()
    }
  end
  biAction.startTime = GM.GameModel:GetServerTime()
  biAction.buffid = rewardType
  biAction.oldBuff = oldCurProperty or "null"
  GM.BIManager:LogAction(EBIType.TriggerBoostBuffActivation, biAction)
  GM.BIManager:LogAcquire(rewardType, 1, args.scene, args.source == EPropertySource.Give)
end

function BoostChargeDiscoBoostHandler:CheckPopupWindow()
  if self.m_cacheData == nil then
    return false
  end
  if self.m_cacheData.canPopUpWindow == true then
    return true
  end
  return false
end

function BoostChargeDiscoBoostHandler:IsDiscoDoing()
  if self.m_cacheData == nil then
    return false
  end
  return self.m_cacheData.boostChargeNum > 0
end

function BoostChargeDiscoBoostHandler:PopWindowFinished()
  if self.m_cacheData == nil then
    return
  end
  self.m_cacheData.canPopUpWindow = false
  self:SaveCacheData()
end

function BoostChargeDiscoBoostHandler:GetMaxLevelByScore(score)
  local power = 0
  local n = score
  while 1 < n do
    n = n >> 1
    power = power + 1
  end
  return power + 1
end

function BoostChargeDiscoBoostHandler:RefreshGenerateCodeCache(type)
  local itemConfig = GM.ItemDataModel:GetModelConfig(type)
  if itemConfig == nil or itemConfig.Spread_Weight == nil then
    self.m_mapGenerateCodeCache[type] = false
    return false
  end
  local codeWeightPairs = itemConfig.Spread_Weight
  local mapCurChain = {}
  for _, v in ipairs(codeWeightPairs) do
    local code = v.Code
    local chain = GM.ItemDataModel:GetChainId(code)
    mapCurChain[chain] = true
  end
  self.m_mapGenerateCodeCache[type] = mapCurChain
end

local discoExitScore = 8

function BoostChargeDiscoBoostHandler:IsCurDiscoSpreadItem(type)
  if not self:CanSupportItem(type) then
    return false
  end
  local testLog = ""
  local mapLackItem = GM.MainBoardModel:CalculateOrderCodeLackNumMapByLevelSize(false, true, false)
  if self.m_mapGenerateCodeCache[type] == nil then
    self:RefreshGenerateCodeCache(type)
  end
  if self.m_mapGenerateCodeCache[type] == false then
    return false
  end
  local discoConfig = self:GetDiscoConfigByType(self.m_cacheData.curProperty)
  if GameConfig.IsTestMode() then
    testLog = testLog .. "\229\150\183\229\143\145\229\138\169\229\138\155\229\189\147\229\137\141\231\154\132\229\150\183\229\143\145\230\163\139\229\173\144:" .. type .. "\n"
    testLog = testLog .. "\229\189\147\229\137\141\231\154\132\233\133\141\231\189\174\233\154\190\229\186\166\231\173\137\231\186\167" .. discoConfig.difficulty_level .. "\n"
    testLog = testLog .. "\229\189\147\229\137\141\229\150\183\229\143\145\231\154\132\230\163\139\229\173\144\229\143\175\228\187\165\229\150\183\229\143\145\231\154\132\229\144\136\230\136\144\231\186\191: \n"
    for chain, _ in pairs(self.m_mapGenerateCodeCache[type]) do
      testLog = testLog .. chain .. " "
    end
    testLog = testLog .. "\n"
    testLog = testLog .. "\229\189\147\229\137\141\232\174\162\229\141\149\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144: \n"
    for code, num in pairs(mapLackItem) do
      testLog = testLog .. code .. " : " .. num .. "\n"
    end
  end
  local listLackItem = {}
  for code, num in pairs(mapLackItem) do
    table.insert(listLackItem, {code = code, num = num})
  end
  table.sort(listLackItem, function(a, b)
    local aLevel = GM.ItemDataModel:GetChainLevel(a.code)
    local bLevel = GM.ItemDataModel:GetChainLevel(b.code)
    if aLevel == bLevel then
      local aHasSub = MapItemSubChain[GM.ItemDataModel:GetChainId(a.code)] ~= nil
      local bHasSub = MapItemSubChain[GM.ItemDataModel:GetChainId(b.code)] ~= nil
      if aHasSub == bHasSub then
        return aLevel < bLevel
      end
      return aHasSub
    end
    return aLevel < bLevel
  end)
  if GameConfig.IsTestMode() then
    testLog = testLog .. "\230\140\137\231\133\167\231\173\137\231\186\167\230\142\146\229\186\143\229\144\142\231\188\186\229\176\145\231\154\132\230\163\139\229\173\144:\n"
    for _, v in ipairs(listLackItem) do
      testLog = testLog .. v.code .. " : " .. v.num .. "\n"
    end
  end
  local generateChain = GM.ItemDataModel:GetChainId(type)
  local listTarget = {}
  for _, lackItem in ipairs(listLackItem) do
    local lackItemCode = lackItem.code
    local lackItemNum = lackItem.num
    local chain = GM.ItemDataModel:GetChainId(lackItemCode)
    if self.m_mapGenerateCodeCache[type][chain] then
      local itemLevel = GM.ItemDataModel:GetChainLevel(lackItemCode)
      local mapOrderItemConfig = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
      local difficultyLevel = itemLevel
      if mapOrderItemConfig[lackItemCode] ~= nil and mapOrderItemConfig[lackItemCode].DifficultyLevel then
        difficultyLevel = mapOrderItemConfig[lackItemCode].DifficultyLevel
      end
      local curChooseMaxLevel = self:GetMaxLevelByScore(self.m_cacheData.boostChargeNum + discoExitScore)
      if difficultyLevel <= discoConfig.difficulty_level and type ~= ItemType.RawFish05 and ItemSpecailGenearteItemChain[generateChain] ~= true then
        local curCode = lackItemCode
        if difficultyLevel > curChooseMaxLevel then
          for i = itemLevel - 1, 1, -1 do
            curCode = GM.ItemDataModel:GetTypeByChainAndLevel(chain, i)
            itemLevel = i
            difficultyLevel = i
            if mapOrderItemConfig[curCode] ~= nil and mapOrderItemConfig[curCode].DifficultyLevel then
              difficultyLevel = mapOrderItemConfig[curCode].DifficultyLevel
            end
            if curChooseMaxLevel >= difficultyLevel then
              break
            end
          end
        end
        table.insert(listTarget, {
          code = curCode,
          difficultyLevel = difficultyLevel,
          level = itemLevel
        })
        break
      else
        local itemConfig = GM.ItemDataModel:GetModelConfig(type)
        local itemSpreadWeight = itemConfig.Spread_Weight
        local listChoostTarget = {}
        for _, v in ipairs(itemSpreadWeight) do
          if GM.ItemDataModel:GetChainId(v.Code) == chain then
            table.insert(listChoostTarget, v)
          end
        end
        if GameConfig.IsTestMode() then
          testLog = testLog .. "\229\189\147\229\137\141\231\154\132\229\150\183\229\143\145\230\163\139\229\173\144\231\154\132\233\154\143\230\156\186\233\133\141\231\189\174 \n"
          for _, v in ipairs(listChoostTarget) do
            testLog = testLog .. v.Code .. " : " .. v.Weight .. "\n"
          end
        end
        local maxWeight = 0
        local curItem = Table.ListWeightSelectOne(listChoostTarget)
        local startLevel = GM.ItemDataModel:GetChainLevel(curItem.Code)
        if GameConfig.IsTestMode() then
          testLog = testLog .. "\229\189\147\229\137\141\233\128\137\230\139\169\231\154\132\233\133\141\231\189\174: " .. curItem.Code .. " \230\157\131\233\135\141: " .. curItem.Weight .. "\n"
        end
        local curStartLevel = math.min(startLevel + 3, curChooseMaxLevel)
        for i = curStartLevel, 1, -1 do
          local num = MathUtil.IntPow(2, i - 1)
          if lackItemNum >= num then
            difficultyLevel = i
            local code = GM.ItemDataModel:GetTypeByChainAndLevel(chain, i)
            if mapOrderItemConfig[code] ~= nil and mapOrderItemConfig[code].DifficultyLevel then
              difficultyLevel = mapOrderItemConfig[code].DifficultyLevel
            end
            table.insert(listTarget, {
              code = GM.ItemDataModel:GetTypeByChainAndLevel(chain, i),
              level = i,
              difficultyLevel = difficultyLevel
            })
            break
          end
        end
        if 0 < #listTarget then
          break
        end
      end
    end
  end
  local bHave = 0 < #listTarget
  if GameConfig.IsTestMode() then
    for _, v in ipairs(listTarget) do
      testLog = testLog .. "\229\143\175\228\190\155\233\128\137\230\139\169\231\154\132\230\163\139\229\173\144: " .. v.code .. " \231\173\137\231\186\167: " .. v.level .. " \233\154\190\229\186\166\231\173\137\231\186\167: " .. v.difficultyLevel .. "\n"
    end
    testLog = testLog .. "\229\189\147\229\137\141\231\154\132\229\138\169\229\138\155\230\149\176\233\135\143: " .. self.m_cacheData.boostChargeNum .. "\n"
    testLog = testLog .. "\229\189\147\229\137\141\229\138\169\229\138\155\233\162\157\229\164\150\230\149\176\233\135\143 \229\141\179\231\173\150\229\136\146\230\129\169\232\181\144\231\154\132\229\136\134\230\149\176" .. discoExitScore .. "\n"
    if 0 < #listTarget then
      testLog = testLog .. "\229\189\147\229\137\141\230\163\139\229\173\144\229\136\134\230\149\176 " .. MathUtil.IntPow(2, listTarget[1].difficultyLevel - 1) .. "\n"
      testLog = testLog .. "\229\137\169\228\189\153\229\138\169\229\138\155\230\149\176\233\135\143" .. self.m_cacheData.boostChargeNum - MathUtil.IntPow(2, listTarget[1].difficultyLevel - 1) .. "\n"
    end
    Log.Info(testLog)
  end
  return bHave, listTarget, testLog
end

function BoostChargeDiscoBoostHandler:ReduceDiscoScore(score)
  self.m_cacheData.boostChargeNum = self.m_cacheData.boostChargeNum - score
  self.m_cacheData.boostChargeNum = math.max(0, self.m_cacheData.boostChargeNum)
  EventDispatcher.DispatchEvent(EEventType.TriggerBoostDiscoUpdate, score)
  if self.m_cacheData.boostChargeNum <= 0 then
    self:CloseDisco()
  end
  self:SaveCacheData()
end

function BoostChargeDiscoBoostHandler:TryGetSpreadItem(type)
  local flag, listTarget, testLog = self:IsCurDiscoSpreadItem(type)
  if not flag then
    return false
  end
  self:ReduceDiscoScore(MathUtil.IntPow(2, listTarget[1].difficultyLevel - 1))
  return true, listTarget[1].code, listTarget[1].level
end

function BoostChargeDiscoBoostHandler:TryUseDiscoItem(generatorType, type, energyBoostRatio)
  if not self:CanSupportItem(generatorType) then
    return false, 0
  end
  local itemLevel = GM.ItemDataModel:GetChainLevel(type)
  local mapOrderItemConfig = GM.MainBoardModel:GetOrderModel(OrderModelType.Slot):GetItemCodeConfigMap()
  local difficultyLevel = itemLevel
  if mapOrderItemConfig[type] ~= nil and mapOrderItemConfig[type].DifficultyLevel then
    difficultyLevel = mapOrderItemConfig[type].DifficultyLevel
  end
  local curScore = self.m_cacheData.boostChargeNum + discoExitScore
  local itemScore = MathUtil.IntPow(2, difficultyLevel - 1)
  while curScore < itemScore do
    itemLevel = itemLevel - 1
    type = GM.ItemDataModel:GetTypeByChainAndLevel(GM.ItemDataModel:GetChainId(type), itemLevel)
    difficultyLevel = itemLevel
    if mapOrderItemConfig[type] ~= nil and mapOrderItemConfig[type].DifficultyLevel then
      difficultyLevel = mapOrderItemConfig[type].DifficultyLevel
    end
    itemScore = MathUtil.IntPow(2, difficultyLevel - 1)
    energyBoostRatio = energyBoostRatio - 1
    if itemLevel == 1 then
      break
    end
  end
  if GameConfig.IsTestMode() then
    local testinfo = ""
    testinfo = testinfo .. "\229\189\147\229\137\141\229\138\169\229\138\155\230\175\141\228\189\147\230\163\139\229\173\144\233\135\135\231\148\168\228\187\1338\229\128\141\231\154\132\230\150\185\229\188\143\n"
    testinfo = testinfo .. "\229\189\147\229\137\141\232\142\183\229\190\151\231\154\132\230\163\139\229\173\144" .. type .. "\n"
    testinfo = testinfo .. "\230\156\128\231\187\136\229\128\141\231\142\135\228\184\186" .. energyBoostRatio
    testinfo = testinfo .. "\229\189\147\229\137\141\231\154\132\229\138\169\229\138\155\230\149\176\233\135\143: " .. self.m_cacheData.boostChargeNum .. "\n"
    testinfo = testinfo .. "\229\189\147\229\137\141\229\138\169\229\138\155\233\162\157\229\164\150\230\149\176\233\135\143 \229\141\179\231\173\150\229\136\146\230\129\169\232\181\144\231\154\132\229\136\134\230\149\176" .. discoExitScore .. "\n"
    testinfo = testinfo .. "\229\189\147\229\137\141\230\163\139\229\173\144\229\136\134\230\149\176 " .. itemScore .. "\n"
    testinfo = testinfo .. "\229\137\169\228\189\153\229\138\169\229\138\155\230\149\176\233\135\143" .. self.m_cacheData.boostChargeNum - itemScore .. "\n"
    Log.Info(testinfo)
  end
  self:ReduceDiscoScore(itemScore)
  return type, energyBoostRatio
end

function BoostChargeDiscoBoostHandler:CloseDisco()
  local closeIcon = self:GetPropertyIcon()
  self.m_willCloseProperty = self.m_cacheData.curProperty
  self.m_cacheData = nil
  self:SaveCacheData()
  self:ShowClosePrompt(closeIcon)
  EventDispatcher.DispatchEvent(EEventType.TriggerBoostDiscoFinished)
end

function BoostChargeDiscoBoostHandler:ShowClosePrompt(closeIcon)
  GM.ResourceLoader:LoadPrefab(GM.DataResource.UIPrefabConfig:GetConfig(UIPrefabConfigName.TriggerBoostDiscoPromptTip), GM.UIManager:GetCanvasRoot(), Vector3.zero, function(go)
    if not go:IsNull() then
      local prompt = go:GetLuaTable()
      prompt:Show(closeIcon)
    end
  end)
end

function BoostChargeDiscoBoostHandler:GetOpenStartWindow()
  if not self:CheckPopupWindow() then
    return nil
  end
  return UIPrefabConfigName.TriggerBoostDiscoEmptyView
end

function BoostChargeDiscoBoostHandler:GetCacheData()
  return self.m_cacheData
end

function BoostChargeDiscoBoostHandler:GetPropertyIcon(rewardType)
  if rewardType == nil then
    if self.m_cacheData == nil then
      rewardType = self.m_willCloseProperty
    else
      rewardType = self.m_cacheData.curProperty
    end
  end
  if rewardType == nil then
    Log.Error("\233\148\153\232\175\175\239\188\140\228\184\186\228\187\128\228\185\136\230\178\161\230\156\137Disco\229\138\169\229\138\155\228\186\134\239\188\159")
    return "disco1"
  end
  if self.m_mapDiscoConfig[rewardType] ~= nil then
    local level = 1
    if self.m_mapDiscoConfig[rewardType].icon == "disco1" then
      level = 1
    elseif self.m_mapDiscoConfig[rewardType].icon == "disco2" then
      level = 2
    else
      level = 3
    end
    return self.m_mapDiscoConfig[rewardType].icon, level
  end
end

function BoostChargeDiscoBoostHandler:IsBoostDiscoActive()
  if self.m_cacheData == nil then
    return false
  end
  if self.m_cacheData.boostChargeNum <= 0 then
    Log.Error("\233\148\153\232\175\175\239\188\154\230\178\161\230\156\137\229\138\169\229\138\155\228\186\134\239\188\140\228\184\186\228\187\128\228\185\136\232\191\152\230\156\137\230\149\176\230\141\174")
    self:CloseDisco()
    return false
  end
  return true
end

function BoostChargeDiscoBoostHandler:CanSupportItem(type)
  if not self:IsBoostDiscoActive() then
    return false
  end
  if self.m_mapGenerateCodeCache[type] == false then
    return false
  end
  if not GM.ItemDataModel:IsGeneratorItem(type) then
    self.m_mapGenerateCodeCache[type] = false
    return false
  end
  local config = GM.ItemDataModel:GetModelConfig(type)
  if config == nil then
    return false
  end
  if config.Spread_CostEnergy ~= 1 then
    return false
  end
  return true
end

function BoostChargeDiscoBoostHandler:CanSupportItemShow(type)
  if not self:CanSupportItem(type) then
    return false
  end
  if self.m_cacheData.canPopUpWindow == true then
    return false
  end
  return true
end

function BoostChargeDiscoBoostHandler:CanShowBoardProgress()
  if not self:IsBoostDiscoActive() then
    return false
  end
  return self.m_cacheData.canPopUpWindow ~= true
end

function BoostChargeDiscoBoostHandler:TempSetProgressActive(bFlag)
  self.m_bTempProgressActive = bFlag
end

function BoostChargeDiscoBoostHandler:IsTempProgressActive()
  return self.m_bTempProgressActive ~= false
end

function BoostChargeDiscoBoostHandler:GetItemSpreadTrail()
  local buffIcon = self:GetPropertyIcon()
  local prefabName
  if buffIcon == "disco1" then
    prefabName = UIPrefabConfigName.effect_boostchargedisco_spark_pinktrail
  elseif buffIcon == "disco2" then
    prefabName = UIPrefabConfigName.effect_boostchargedisco_spark_trail
  else
    prefabName = UIPrefabConfigName.effect_boostchargedisco_spark_caisetrail
  end
  return prefabName
end

function BoostChargeDiscoBoostHandler:GetItemSpreadArriveEffect()
  local buffIcon = self:GetPropertyIcon()
  local prefabName
  if buffIcon == "disco1" then
    prefabName = UIPrefabConfigName.effect_boostchargedisco_pinkarrive
  elseif buffIcon == "disco2" then
    prefabName = UIPrefabConfigName.effect_boostchargedisco_arrive
  else
    prefabName = UIPrefabConfigName.effect_boostchargedisco_caisearrive
  end
  return prefabName
end

function BoostChargeDiscoBoostHandler:GetHideItemSpreadTagPrefab(itemModel)
  local flyPrefab
  if GM.EnergyBoostModel:CanEnergyBoost(itemModel:GetType()) then
    local num = GM.EnergyBoostModel:GetEnergyBoostCostNum()
    if num == 2 then
      flyPrefab = UIPrefabConfigName.disco_effect_daoju_tishi_3_jiaobiao_hong
    elseif num == 4 then
      flyPrefab = UIPrefabConfigName.disco_effect_daoju_tishi_3_jiaobiao_zi
    elseif num == 8 then
      flyPrefab = UIPrefabConfigName.disco_effect_daoju_tishi_4
    end
  else
    flyPrefab = UIPrefabConfigName.disco_effect_daoju_tishi_1_jiaobiao_huang
  end
  return flyPrefab
end
