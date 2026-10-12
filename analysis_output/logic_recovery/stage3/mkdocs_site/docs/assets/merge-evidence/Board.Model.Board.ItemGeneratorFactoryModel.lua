ItemGeneratorFactoryModel = {}
ItemGeneratorFactoryModel.__index = ItemGeneratorFactoryModel
ItemGeneratorFactoryType = {
  "104",
  "404",
  "705",
  "1006",
  "1205",
  "1705"
}

function ItemGeneratorFactoryModel.Create()
  local model = setmetatable({}, ItemGeneratorFactoryModel)
  model:Init()
  return model
end

function ItemGeneratorFactoryModel:Init()
  local chainId
  self.m_mapChainId = {}
  self.m_mapMaxScore = {}
  local maxScore = 0
  local n = 1
  for _, type in ipairs(ItemGeneratorFactoryType) do
    chainId = tostring(tonumber(type) // 100)
    self.m_mapChainId[chainId] = type
    n = tonumber(type) % 100
    maxScore = 2 ^ (n - 1)
    self.m_mapMaxScore[type] = math.floor(maxScore)
  end
  EventDispatcher.AddListener(EEventType.LoginFinished, self, self._OnLoginFinished)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
  EventDispatcher.AddListener(EEventType.GameModeChangeFinished, self, self._OnGameModeChangeFinished)
end

function ItemGeneratorFactoryModel:_OnGameModeChangeFinished()
  if GM.SceneManager:GetGameMode() == EGameMode.Main then
    self:CheckCobweb()
  end
end

function ItemGeneratorFactoryModel:LateInit()
  self:_UpdateUnLockState()
  self.m_data = self:GetData()
  local genData = self.m_data.genData
  if not Table.IsEmpty(genData) then
    for genType, _ in pairs(genData) do
      self:TryReward(genType)
    end
  end
  self:_TryReturnItem()
  self.m_bOpen = self:IsOpen()
  self:_LogStart(self.m_bOpen)
  self.m_bLateInit = true
end

function ItemGeneratorFactoryModel:OnSceneViewLoaded()
  self.m_bSceneViewLoaded = true
end

function ItemGeneratorFactoryModel:_OnLoginFinished()
  if not self.m_bLateInit or not self.m_bSceneViewLoaded then
    return
  end
  self:_UpdateOpenState()
  self:_TryReturnItem()
end

function ItemGeneratorFactoryModel:_OnItemMerged(msg)
  if not GM.ConfigModel:IsServerControlOpen(EGeneralConfType.GeneratorFactory) then
    return false
  end
  if self.m_isAllUnlock then
    return
  end
  local item = msg.New
  local itemType = item:GetType()
  if Table.Contain(ItemGeneratorFactoryType, itemType) then
    self:_UpdateOpenState()
  end
end

function ItemGeneratorFactoryModel:_LogStart(bOpen)
  local recordState = self.m_data.state or 0
  local curState = bOpen and 1 or 0
  if recordState == curState then
    return
  end
  self.m_data.state = curState
  if bOpen then
    GM.BIManager:LogAction(EBIType.GeneratorFactoryStart)
  end
  self:SaveData()
end

function ItemGeneratorFactoryModel:UpdateInventoryEntryRedTip()
  local bRedTip = self:CanMerge() and self.m_bOpen
  local sceneView = GM.UIManager:GetOpenedTopViewByType(EViewType.SceneView)
  local inventoryBtn = sceneView:GetHudButton(ESceneViewHudButtonKey.Inventory)
  inventoryBtn:UpdateRedPoint(bRedTip)
end

function ItemGeneratorFactoryModel:IsOpen()
  if not GM.ConfigModel:IsServerControlOpen(EGeneralConfType.GeneratorFactory) then
    return false
  end
  self:_UpdateUnLockState()
  return self.m_isAllUnlock
end

function ItemGeneratorFactoryModel:CheckCobweb()
  if not self:IsOpen() then
    return
  end
  local boardModel = GM.MainBoardModel
  if boardModel == nil or MainBoardView.GetInstance() == nil then
    return
  end
  if self.m_data.CheckCobweb == nil then
    self.m_data.CheckCobweb = true
    self:SaveData()
  end
  local anyReplaced = false
  for position in boardModel:GetValidPositionIterator() do
    local item = boardModel:GetItem(position)
    if item ~= nil then
      local itemCobweb = item:GetComponent(ItemCobweb)
      if itemCobweb ~= nil then
        local innerCode = itemCobweb:GetInnerItemCode()
        if boardModel:IsGeneratorFactoryItem(innerCode) then
          anyReplaced = true
          local new = boardModel:ReplaceItem(item, innerCode, false)
          boardModel.event:Call(BoardEventType.ReplaceItem, {oldItem = item, newItem = new})
          GM.BIManager:LogAction(EBIType.GeneratorFactoryCobwebChange, innerCode)
        end
      elseif item:GetComponent(ItemPaperBox) then
        local innerCode = item:GetComponent(ItemPaperBox):GetInnerItemCode()
        innerCode = innerCode:match(".*#(.*)") or innerCode
        if boardModel:IsGeneratorFactoryItem(innerCode) then
          anyReplaced = true
          local new = boardModel:ReplaceItem(item, innerCode, false)
          boardModel.event:Call(BoardEventType.ReplaceItem, {oldItem = item, newItem = new})
          local reward = boardModel:GetPaperBoxExtraReward(position)
          if not Table.IsEmpty(reward) then
            RewardApi.AcquireRewards({reward}, EPropertySource.Give, EBIType.GeneratorFactoryCobwebChangeReward, nil, EGameMode.Main, CacheItemType.Type2)
          end
          GM.BIManager:LogAction(EBIType.GeneratorFactoryCobwebChange, innerCode)
        end
      end
    end
  end
  if anyReplaced then
    boardModel:CountItemsCode()
    boardModel:UpdateOrderState()
  end
end

function ItemGeneratorFactoryModel:_UpdateOpenState()
  local bOpen = self:IsOpen()
  if self.m_bOpen ~= bOpen then
    self.m_bOpen = bOpen
    if self.m_bOpen then
      self:CheckCobweb()
    end
    EventDispatcher.DispatchEvent(EEventType.GeneratorFactoryStateChanged, self.m_bOpen)
    self:UpdateInventoryEntryRedTip()
  end
  self:_LogStart(bOpen)
end

function ItemGeneratorFactoryModel:IsGeneratorFactoryItem(type)
  local chainId = GM.ItemDataModel:GetChainId(type)
  if not StringUtil.IsNilOrEmpty(chainId) then
    local genType = self.m_mapChainId[chainId]
    if not StringUtil.IsNilOrEmpty(genType) then
      return tonumber(genType) > tonumber(type)
    end
  end
  return false
end

function ItemGeneratorFactoryModel:StoreItem(type)
  local chainId = GM.ItemDataModel:GetChainId(type)
  if StringUtil.IsNilOrEmpty(chainId) then
    return
  end
  local genType = self.m_mapChainId[chainId]
  if StringUtil.IsNilOrEmpty(genType) then
    return
  end
  local genData = self.m_data.genData or {}
  genData[genType] = genData[genType] or {}
  genData[genType].items = genData[genType].items or {}
  genData[genType].items[type] = genData[genType].items[type] or 0
  genData[genType].items[type] = genData[genType].items[type] + 1
  self.m_data.genData = genData
  self:SaveData()
  self:UpdateInventoryEntryRedTip()
  GM.BIManager:LogAction(EBIType.GeneratorFactoryCollect, type)
end

function ItemGeneratorFactoryModel:AddScore(genType, itemType)
  local genData = self.m_data.genData or {}
  if genData[genType] ~= nil and genData[genType].items ~= nil and genData[genType].items[itemType] > 0 then
    genData[genType].items[itemType] = genData[genType].items[itemType] - 1
    local n = tonumber(itemType) % 100
    local score = 2 ^ (n - 1)
    genData[genType] = genData[genType] or {}
    genData[genType].score = genData[genType].score or 0
    genData[genType].score = genData[genType].score + score
    self.m_data.genData = genData
    self:SaveData()
    local maxScore = self.m_mapMaxScore[genType]
    GM.BIManager:LogAction(EBIType.GeneratorFactoryAddScore, {
      targetType = genType,
      itemType = itemType,
      progress = string.format("%d/%d", genData[genType].score, maxScore),
      isComplete = maxScore <= genData[genType].score
    })
    return score, maxScore <= genData[genType].score
  end
  return nil
end

function ItemGeneratorFactoryModel:CanMerge()
  if Table.IsEmpty(self.m_data) then
    return false
  end
  local genData = self.m_data.genData
  if Table.IsEmpty(genData) then
    return false
  end
  for genType, tbData in pairs(genData) do
    if self:_CanMerge(genType, tbData) then
      return true
    end
  end
  return false
end

function ItemGeneratorFactoryModel:_CanMerge(genType, tbData)
  if Table.IsEmpty(tbData) then
    return false
  end
  local score = tbData.score or 0
  local itemScore = 0
  if not Table.IsEmpty(tbData.items) then
    for k, ct in pairs(tbData.items) do
      local n = tonumber(k) % 100
      itemScore = itemScore + 2 ^ (n - 1) * ct
    end
  end
  local maxScore = self.m_mapMaxScore[genType]
  return maxScore <= score + itemScore
end

function ItemGeneratorFactoryModel:TryReward(genType)
  local genData = self.m_data.genData or {}
  if genData[genType] ~= nil and genData[genType].score ~= nil and genData[genType].score >= self.m_mapMaxScore[genType] then
    genData[genType].score = genData[genType].score - self.m_mapMaxScore[genType]
    local rewards = {
      {
        [PROPERTY_TYPE] = genType,
        [PROPERTY_COUNT] = 1
      }
    }
    RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, EBIType.GeneratorFactoryMergeReward, EGameMode.Main, CacheItemType.Type2)
    self:SaveData()
    return true
  end
  return false
end

function ItemGeneratorFactoryModel:GetDefaultIndex()
  local defaultIndex = 1
  local genData = self.m_data.genData
  if Table.IsEmpty(genData) then
    return defaultIndex
  end
  for idx, genType in ipairs(ItemGeneratorFactoryType) do
    local maxScore = self.m_mapMaxScore[genType]
    if genData[genType] ~= nil then
      local score = genData[genType].score or 0
      if genData[genType].items ~= nil then
        for k, ct in pairs(genData[genType].items) do
          local n = tonumber(k) % 100
          score = score + 2 ^ (n - 1) * ct
        end
      end
      if maxScore <= score then
        defaultIndex = idx
        break
      end
    end
  end
  return defaultIndex
end

function ItemGeneratorFactoryModel:GetGenDataByType(type)
  local genData = self.m_data.genData or {}
  return {
    maxScore = self.m_mapMaxScore[type],
    data = genData[type]
  }
end

function ItemGeneratorFactoryModel:GetData()
  local info = GM.MiscModel:GetGeneratorFactoryData()
  if not StringUtil.IsNilOrEmpty(info) then
    info = StringUtil.Replace(info, "@", ",")
    return json.decode(info)
  end
  return {}
end

function ItemGeneratorFactoryModel:SaveData()
  if Table.IsEmpty(self.m_data) then
    return
  end
  GM.MiscModel:SetGeneratorFactoryData(StringUtil.Replace(json.encode(self.m_data), ",", "@"))
end

function ItemGeneratorFactoryModel:RemoveData()
  GM.MiscModel:Clear(EMiscKey.GeneratorFactoryData)
end

function ItemGeneratorFactoryModel:_TryReturnItem()
  if self:IsOpen() or Table.IsEmpty(self.m_data) then
    return
  end
  local tbGenData = self.m_data.genData
  if Table.IsEmpty(tbGenData) then
    return
  end
  local rewards = {}
  for genType, tbData in pairs(tbGenData) do
    if not Table.IsEmpty(tbData.items) then
      for itemType, num in pairs(tbData.items) do
        table.insert(rewards, {
          [PROPERTY_TYPE] = itemType,
          [PROPERTY_COUNT] = num
        })
      end
    end
    local score = tbData.score or 0
    if score >= self.m_mapMaxScore[genType] then
      while score >= self.m_mapMaxScore[genType] do
        score = score - self.m_mapMaxScore[genType]
        table.insert(rewards, {
          [PROPERTY_TYPE] = genType,
          [PROPERTY_COUNT] = 1
        })
      end
    end
    if 0 < score then
      local tmpNum = tonumber(genType)
      local k = tmpNum % 100
      for i = tmpNum - 1, tmpNum - k + 1, -1 do
        local needScore = 2 ^ (i % 100 - 1)
        if score >= needScore then
          score = score - needScore
          table.insert(rewards, {
            [PROPERTY_TYPE] = tostring(i),
            [PROPERTY_COUNT] = 1
          })
        end
      end
    end
  end
  RewardApi.AcquireRewardsLogic(rewards, EPropertySource.Give, EBIType.GeneratorFactoryReturnReward, EGameMode.Main, CacheItemType.Type2)
  self.m_data = {}
  GM.MiscModel:Clear(EMiscKey.GeneratorFactoryData)
end

function ItemGeneratorFactoryModel:_UpdateUnLockState()
  if self.m_isAllUnlock then
    return
  end
  local tmpUnlock = true
  for _, type in ipairs(ItemGeneratorFactoryType) do
    if not GM.ItemDataModel:IsUnlocked(type) then
      tmpUnlock = false
      break
    end
  end
  self.m_isAllUnlock = tmpUnlock
end
