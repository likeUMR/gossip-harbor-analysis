BaseActionBoardModel = setmetatable({}, BaseBoardModel)
BaseActionBoardModel.__index = BaseActionBoardModel

function BaseActionBoardModel:_LogCacheItems(info)
end

function BaseActionBoardModel:CacheItems(cachedItemCodes, type, mapCacheItemId)
  self.m_itemCacheModel:PushItems(cachedItemCodes, type or self.CacheItemType, mapCacheItemId)
  self:_LogCacheItems({items = cachedItemCodes})
  EventDispatcher.DispatchEvent(EEventType.CacheItems, {
    boardType = self.BoardType
  })
end

function BaseActionBoardModel:CacheItemsFromBoard(items, type)
  local mapCacheItemId = {}
  local itemCodes = {}
  for i, item in ipairs(items) do
    local id = item:GetId()
    if self.m_itemManager:GetItem(id) == item then
      local code = item:GetCode()
      itemCodes[#itemCodes + 1] = item:GetCode()
      mapCacheItemId[#itemCodes] = id
      self:_SetItem(item:GetPosition(), nil, false)
      GM.BIManager:LogAction(EBIType.CacheItemFromBoard, {
        code = code,
        id = id,
        boardType = self.BoardType
      })
    end
  end
  self.m_itemCacheModel:PushItems(itemCodes, type or self.CacheItemType, mapCacheItemId)
  self:_LogCacheItems({items = itemCodes, fromb = true})
  EventDispatcher.DispatchEvent(EEventType.CacheItems, {
    boardType = self.BoardType
  })
end

function BaseActionBoardModel:CacheItemFromSpread(cachedItemCodes, spreadItem)
  self.m_itemCacheModel:PushItems(cachedItemCodes, self.CacheItemType)
  self:_LogCacheItems({items = cachedItemCodes, autoSpread = true})
  self.event:Call(BoardEventType.CacheItemFromSpread, {Source = spreadItem, CachedItems = cachedItemCodes})
  EventDispatcher.DispatchEvent(EEventType.CacheItems, {
    boardType = self.BoardType
  })
end

function BaseActionBoardModel:PopCachedItem()
  if self:IsBoardFull() then
    return false
  end
  local position = self:FindEmptyPositionInValidOrder()
  if position == nil then
    return false
  end
  local code, cachedItemId = self.m_itemCacheModel:PopItem()
  if StringUtil.IsNilOrEmpty(code) then
    Log.Assert(false, "code\228\184\141\232\131\189\228\184\186\231\169\186")
    return false
  end
  local newItem
  if not StringUtil.IsNilOrEmpty(cachedItemId) then
    newItem = self.m_itemManager:GetItem(cachedItemId)
    if newItem == nil or newItem:GetCode() ~= code then
      GM.BIManager:LogErrorInfo(EBIType.CacheItemIdDiffer, "code:" .. tostring(code) .. " cache:" .. tostring(newItem ~= nil and newItem:GetCode() or nil) .. " boardType:" .. tostring(self.BoardType))
      position = self:_TryGetNewPosition(code) or position
      newItem = self:GenerateItem(position, code)
    else
      position = self:_TryGetNewPosition(newItem:GetType()) or position
      self:_SetItem(position, newItem)
      newItem:SetPosition(position)
      if self.m_mergeAllIgnoredItems ~= nil then
        self.m_mergeAllIgnoredItems[newItem] = true
      end
    end
  else
    position = self:_TryGetNewPosition(code) or position
    newItem = self:GenerateItem(position, code)
  end
  local message = {New = newItem}
  EventDispatcher.DispatchEvent(EEventType.PopCachedItem, message)
  self.event:Call(BoardEventType.PopCachedItem, message)
  self:_PostProcessOnPopCachedItem(code, cachedItemId)
  return true
end

function BaseActionBoardModel:_TryGetNewPosition(newItemCode)
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.ItemLandOpt) then
    return self:FindEmptySpreadPosition(newItemCode)
  end
end

function BaseActionBoardModel:_PostProcessOnPopCachedItem()
end

function BaseActionBoardModel:RemoveCachedItem(index)
  return self.m_itemCacheModel:RemoveItem(index)
end

function BaseActionBoardModel:GetCachedItem(index)
  return self.m_itemCacheModel:GetItem(index)
end

function BaseActionBoardModel:GetCachedItemCount()
  return self.m_itemCacheModel:GetItemCount()
end

function BaseActionBoardModel:GetAllCacheItems()
  return self.m_itemCacheModel:GetAllCacheItems()
end

function BaseActionBoardModel:GetItemCacheModel()
  return self.m_itemCacheModel
end

function BaseActionBoardModel:GetCachedItems()
  return self.m_itemCacheModel:GetAllCachedItemsWithSort()
end

function BaseActionBoardModel:SaveItemProperty(item)
  self.m_itemManager:SetItem(item)
end

function BaseActionBoardModel:_RemoveItemProperty(item)
  if item == nil then
    Log.Error("remove item is nil")
    return
  end
  local position = item:GetPosition()
  if position ~= nil and self.m_itemLayerModel:GetItem(item:GetPosition()) == item then
    Log.Error("Should remove from ItemLayerModel BEFORE remove from ItemManager. type:" .. tostring(item:GetType()) .. " pos:" .. tostring(item:GetPosition()))
  end
  self.m_itemManager:RemoveItem(item:GetId())
end

function BaseActionBoardModel:GetCodeCountMap(includeBoard, includeCache, includeStore)
  local codeCountMap = BaseBoardModel.GetCodeCountMap(self, includeBoard, includeCache, includeStore)
  includeCache = includeCache ~= false
  if includeCache then
    for i = 1, self:GetCachedItemCount() do
      local code = self:GetCachedItem(i)
      if code ~= nil then
        if codeCountMap[code] == nil then
          codeCountMap[code] = 0
        end
        codeCountMap[code] = codeCountMap[code] + 1
      end
    end
  end
  return codeCountMap
end

function BaseActionBoardModel:CollectBoardPropertyRewardsWithoutConvert()
  local rewards = {}
  for position in self:GetValidPositionIterator() do
    rewards = self:_CalculateItemCollectRewards(self:GetItem(position), rewards, 1)
  end
  return rewards
end

function BaseActionBoardModel:_CalculateItemCollectRewards(item, rewards, itemCount)
  itemCount = itemCount or 1
  if item ~= nil and 0 < itemCount then
    local logTable = {}
    local collectTb = item:GetComponent(ItemCollectable)
    if collectTb then
      local collectRewards = collectTb:GetRewards()
      for _, v in pairs(collectRewards) do
        v[PROPERTY_COUNT] = v[PROPERTY_COUNT] * itemCount
        if GameConfig.IsTestMode() and logTable then
          table.insert(logTable, "\230\148\182\233\155\134\230\163\139\229\173\144\229\165\150\229\138\177\239\188\154\229\165\150\229\138\177\231\177\187\229\158\139 = " .. v[PROPERTY_TYPE] .. ", \229\165\150\229\138\177\230\149\176\233\135\143 = " .. v[PROPERTY_COUNT])
        end
      end
      rewards = RewardApi.MergeRewards(rewards, collectRewards)
    end
    local itemSpread = item:GetComponent(ItemSpread)
    if itemSpread and itemSpread:IsDisposable() then
      local arrCw = itemSpread:GetCodeWeightPairs()
      local spreadtype = itemSpread:GetWeightType()
      if spreadtype == 1 then
        local count = itemSpread:GetSpreadMaxNum() - itemSpread:GetSpreadCount()
        local sumweight = 0.0
        for _, v in ipairs(arrCw) do
          sumweight = sumweight + v.Weight
        end
        for _, v in ipairs(arrCw) do
          if 0 < v.Weight then
            if ItemModelFactory.GetCodePrefixTargetType(v.Code) == ItemType.RewardBubble then
              local innerRewardType = ItemModelFactory.GetInnerType(v.Code)
              local arrTemp = {
                {
                  [PROPERTY_TYPE] = innerRewardType,
                  [PROPERTY_COUNT] = math.ceil(v.Weight * count / sumweight) * itemCount
                }
              }
              rewards = RewardApi.MergeRewards(rewards, arrTemp)
              if GameConfig.IsTestMode() and logTable then
                table.insert(logTable, "\229\150\183\229\143\145\230\163\139\229\173\144\229\165\150\229\138\177\239\188\136Spread_WeightType = " .. spreadtype .. "--RewardBubble\239\188\137\239\188\154\229\165\150\229\138\177\231\177\187\229\158\139 = " .. innerRewardType .. ", \229\165\150\229\138\177\230\149\176\233\135\143 = " .. arrTemp[1][PROPERTY_COUNT])
                table.insert(logTable, "    \229\165\150\229\138\177\230\149\176\233\135\143[" .. arrTemp[1][PROPERTY_COUNT] .. "] =  (\230\157\131\233\135\141[" .. v.Weight .. "] * \229\137\169\228\189\153\229\150\183\229\143\145\230\149\176\233\135\143[" .. count .. "] / \230\128\187\230\157\131\233\135\141[" .. sumweight .. "]) * \230\163\139\229\173\144\230\149\176\233\135\143[" .. itemCount .. "]")
              end
            else
              local itemConfig = GM.ItemDataModel:GetModelConfig(v.Code, true)
              local arrRwds = ConfigUtil.GetCurrencyFromArrStr(itemConfig.CollectRewards)
              if not Table.IsEmpty(arrRwds) then
                for _, v1 in ipairs(arrRwds) do
                  v1[PROPERTY_COUNT] = math.ceil(v1[PROPERTY_COUNT] * v.Weight * count / sumweight) * itemCount
                  if GameConfig.IsTestMode() and logTable then
                    table.insert(logTable, "\229\150\183\229\143\145\230\163\139\229\173\144\229\165\150\229\138\177\239\188\136Spread_WeightType = " .. spreadtype .. "\239\188\137\239\188\154\229\165\150\229\138\177\231\177\187\229\158\139 = " .. v1[PROPERTY_TYPE] .. ", \229\165\150\229\138\177\230\149\176\233\135\143 = " .. v1[PROPERTY_COUNT])
                    table.insert(logTable, "    \229\165\150\229\138\177\230\149\176\233\135\143[" .. v1[PROPERTY_COUNT] .. "] =  (\230\157\131\233\135\141[" .. v.Weight .. "] * \229\137\169\228\189\153\229\150\183\229\143\145\230\149\176\233\135\143[" .. count .. "] / \230\128\187\230\157\131\233\135\141[" .. sumweight .. "]) * \230\163\139\229\173\144\230\149\176\233\135\143[" .. itemCount .. "]")
                  end
                end
                rewards = RewardApi.MergeRewards(rewards, arrRwds)
              end
            end
          end
        end
      else
        for _, v in ipairs(arrCw) do
          if 0 < v.Weight then
            local prefixItemType = ItemModelFactory.GetCodePrefixTargetType(v.Code)
            if prefixItemType == ItemType.RewardBubble then
              local innerRewardType = ItemModelFactory.GetInnerType(v.Code)
              local arrTemp = {
                {
                  [PROPERTY_TYPE] = innerRewardType,
                  [PROPERTY_COUNT] = v.Weight * itemCount
                }
              }
              rewards = RewardApi.MergeRewards(rewards, arrTemp)
              if GameConfig.IsTestMode() and logTable then
                table.insert(logTable, "\229\150\183\229\143\145\230\163\139\229\173\144\229\165\150\229\138\177\239\188\136Spread_WeightType = " .. spreadtype .. "\232\135\170\229\135\143\229\150\183\229\143\145\230\168\161\229\188\143--RewardBubble\239\188\137\239\188\154\229\165\150\229\138\177\231\177\187\229\158\139 = " .. innerRewardType .. ", \229\165\150\229\138\177\230\149\176\233\135\143 = " .. arrTemp[1][PROPERTY_COUNT])
                table.insert(logTable, "    \229\165\150\229\138\177\230\149\176\233\135\143[" .. arrTemp[1][PROPERTY_COUNT] .. "] = \230\157\131\233\135\141[" .. v.Weight .. "] * \230\163\139\229\173\144\230\149\176\233\135\143[" .. itemCount .. "]")
              end
            elseif prefixItemType == nil then
              local itemConfig = GM.ItemDataModel:GetModelConfig(v.Code, true)
              local arrRwds = ConfigUtil.GetCurrencyFromArrStr(itemConfig.CollectRewards)
              if not Table.IsEmpty(arrRwds) then
                for _, v1 in ipairs(arrRwds) do
                  local configCount = v1[PROPERTY_COUNT]
                  v1[PROPERTY_COUNT] = configCount * v.Weight * itemCount
                  if GameConfig.IsTestMode() and logTable then
                    table.insert(logTable, "\229\150\183\229\143\145\230\163\139\229\173\144\229\165\150\229\138\177\239\188\136Spread_WeightType = " .. spreadtype .. "\232\135\170\229\135\143\229\150\183\229\143\145\230\168\161\229\188\143\239\188\137\239\188\154\229\165\150\229\138\177\231\177\187\229\158\139 = " .. v1[PROPERTY_TYPE] .. ", \229\165\150\229\138\177\230\149\176\233\135\143 = " .. v1[PROPERTY_COUNT])
                    table.insert(logTable, "    \229\165\150\229\138\177\230\149\176\233\135\143[" .. v1[PROPERTY_COUNT] .. "] = \233\133\141\231\189\174\230\149\176\233\135\143[" .. configCount .. "] * \230\157\131\233\135\141[" .. v.Weight .. "] * \230\163\139\229\173\144\230\149\176\233\135\143[" .. itemCount .. "]")
                  end
                end
                rewards = RewardApi.MergeRewards(rewards, arrRwds)
              elseif GameConfig.IsTestMode() and logTable then
                table.insert(logTable, "\229\150\183\229\143\145\230\163\139\229\173\144\229\165\150\229\138\177(Spread_WeightType = " .. spreadtype .. "\232\135\170\229\135\143\229\150\183\229\143\145\230\168\161\229\188\143\239\188\137\239\188\154\229\165\150\229\138\177\231\177\187\229\158\139 = " .. v.Code .. " \229\177\158\228\186\142\229\133\182\228\187\150\231\137\185\230\174\138\229\137\141\231\188\128\230\163\139\229\173\144\229\165\150\229\138\177\239\188\140\229\183\178\229\191\189\231\149\165")
              end
            end
          end
        end
      end
    end
    if GameConfig.IsTestMode() and not Table.IsEmpty(logTable) and logTable then
      table.insert(logTable, 1, "\230\163\139\229\173\144\229\155\158\230\148\182\232\175\166\231\187\134\228\191\161\230\129\175\239\188\154\230\163\139\229\173\144[" .. item:GetCode() .. "], \230\163\139\229\173\144\230\149\176\233\135\143[" .. itemCount .. "]")
      table.insert(logTable, "--------------------------------------------------------")
      Log.Info(table.concat(logTable, "\n"))
    end
  end
  return rewards
end

function BaseActionBoardModel:GetPromptConfig()
  return self.m_promptConfig
end

function BaseActionBoardModel:InitPaperBoxRewardConfig(needRecordAppear)
  self.m_paperboxExtraRewardMap = Table.DeepCopy(self:GetPaperBoxRewardConfig())
  if Table.IsEmpty(self.m_paperboxExtraRewardMap) then
    return
  end
  if GameConfig.IsTestMode() then
    local VerticalTiles = self:GetPaperBoxRewardVerticalTiles()
    if #self.m_paperboxExtraRewardMap ~= VerticalTiles then
      Log.Error(self.BoardType .. "[PaperboxExtraRewardConfig]\232\161\140\230\149\176\228\184\141\228\184\186" .. VerticalTiles)
    end
    for index, row in ipairs(self.m_paperboxExtraRewardMap) do
      if #row ~= self.HorizontalTiles then
        Log.Error(self.BoardType .. "[PaperboxExtraRewardConfig]\231\172\172" .. index .. "\232\161\140\229\136\151\230\149\176\228\184\141\228\184\186" .. self.HorizontalTiles)
      end
    end
  end
  self.m_paperboxExtraRewardAppearMap = {}
  for y, row in ipairs(self.m_paperboxExtraRewardMap) do
    self.m_paperboxExtraRewardAppearMap[y] = {}
    for x, configStr in ipairs(row) do
      if not StringUtil.IsNilOrEmpty(self.m_paperboxExtraRewardMap[y][x]) and self.m_paperboxExtraRewardMap[y][x] ~= "0" then
        self.m_paperboxExtraRewardMap[y][x] = ConfigUtil.GetCurrencyFromStr(configStr)
      else
        self.m_paperboxExtraRewardMap[y][x] = nil
      end
      self.m_paperboxExtraRewardAppearMap[y][x] = needRecordAppear
    end
  end
end

function BaseActionBoardModel:GetPaperBoxRewardConfig()
end

function BaseActionBoardModel:GetPaperBoxRewardVerticalTiles()
  return self.VerticalTiles
end

function BaseActionBoardModel:GetPaperBoxRewardPosition(boardPos)
  return boardPos
end

function BaseActionBoardModel:GetPaperBoxExtraReward(boardPos)
  boardPos = self:GetPaperBoxRewardPosition(boardPos)
  return self.m_paperboxExtraRewardMap and self.m_paperboxExtraRewardMap[boardPos:GetY()] and self.m_paperboxExtraRewardMap[boardPos:GetY()][boardPos:GetX()] or nil
end

function BaseActionBoardModel:IsPaperBoxExtraRewardFirstAppear(boardPos)
  boardPos = self:GetPaperBoxRewardPosition(boardPos)
  return self.m_paperboxExtraRewardAppearMap and self.m_paperboxExtraRewardAppearMap[boardPos:GetY()] and self.m_paperboxExtraRewardAppearMap[boardPos:GetY()][boardPos:GetX()] or nil
end

function BaseActionBoardModel:SetPaperBoxExtraRewardAppeared(boardPos)
  boardPos = self:GetPaperBoxRewardPosition(boardPos)
  self.m_paperboxExtraRewardAppearMap[boardPos:GetY()][boardPos:GetX()] = false
end

function BaseActionBoardModel:_PostProcessCollapseItem(boardPos, msg)
  local extraReward = self:GetPaperBoxExtraReward(boardPos)
  if extraReward then
    RewardApi.AcquireRewardsLogic({extraReward}, EPropertySource.Give, EBIType.CollapseItemReward, EGameMode.Main, CacheItemType.Type2, self.BoardType)
    GM.BIManager:LogAction(EBIType.CollapseItemReward, {
      pos = tostring(self:GetPaperBoxRewardPosition(boardPos)),
      rwd = ConfigUtil.GetCurrencyStr(extraReward),
      boardType = self.BoardType
    })
    msg.CollapseReward = extraReward
  end
end
