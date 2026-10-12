TaskEventProgressGainModule = setmetatable({}, BaseActivityModule)
TaskEventProgressGainModule.__index = TaskEventProgressGainModule
TaskEventProgressGainModule.TaskOper = {
  Add = "add",
  Update = "update",
  RefreshBook = "refresh_book",
  UpdateBook = "update_book"
}
TaskEventType = {
  OrderFinish = "order",
  GoldAcquire = "gold",
  ItemMerge = "merge",
  ItemMerge3 = "merge_3",
  ItemMerge4 = "merge_4",
  ItemMerge5 = "merge_5",
  ItemMerge6 = "merge_6",
  ItemMerge7 = "merge_7",
  ItemMerge8 = "merge_8",
  ItemMerge9 = "merge_9",
  ItemMerge10 = "merge_10",
  DecorToken = "deco",
  CardGain = "card",
  OneStarCard = "card_1star",
  TwoStarCard = "card_2star",
  ThreeStarCard = "card_3star",
  FourStarCard = "card_4star",
  FiveStarCard = "card_5star",
  GemConsume = "gem",
  Login = "login",
  Payment = "pay",
  HammerUse = "search",
  DigPropUse = "mineral",
  OrderBoost = "smile",
  UseFarmToken = "farm",
  UseFreeFallToken = "freefall",
  UseBreakToken = "break",
  UseStickerToken = "sticker",
  UIBoardItemUnlock = "item_unlock_",
  UIBoardItemAcquire = "item_acquire_",
  UIBoardItemUnlock_adv = "item_unlock_adventure",
  UIBoardItemAcquire_adv = "item_acquire_adventure",
  UIBoardItemUnlock_mtb = "item_unlock_multiboards",
  UIBoardItemAcquire_mtb = "item_acquire_multiboards",
  UIBoardItemUnlock_pb = "item_unlock_pureboard",
  FreefallTargetBeaten = "freefall_target_beaten",
  FreefallUnlockMedal = "freefall_medal",
  RacoonFinish = "racoon",
  Medal = "medal",
  MainTask = "main_task",
  WeeklyStar = "weekly_star",
  CoinRaceLevel = "coin_race_level",
  WipeoutLevel = "wipeout_level",
  MineralLevel = "mineral_level",
  MineralBookItem = "mineral_book_item",
  MineralBookAny = "mineral_book_any",
  FarmBookItem = "farm_book_item",
  FarmBookAny = "farm_book_any",
  AdventureBookItem = "adventure_book_item",
  AdventureBookAny = "adventure_book_any",
  MtbBookItem = "mtb_book_item",
  MtbBookAny = "mtb_book_any",
  PassLevel = "pass_level",
  MainDecoAny = "main_deco_any",
  CookingFrenzyRuby = "cooking_frenzy_ruby",
  CashDashLevel = "cash_dash_level",
  MapExploreMain = "map_explore_main",
  MapExploreAll = "map_explore_all",
  PairWorkProgress = "pair_work_progress",
  SuperWheelSpin = "super_wheel_spin",
  MineralBookChain = "mineral_book_chain",
  FarmBookChain = "farm_book_chain",
  AdventureBookChain = "adventure_book_chain",
  MtbBookChain = "mtb_book_chain",
  Energy = "energy",
  Bubble = "bubble",
  MapExploreEnergy = "streak_task_mpx",
  Item = "item",
  Level = "level",
  Unlock = "unlock",
  Complete = "complete"
}

function TaskEventProgressGainModule.Create()
  local eleModel = setmetatable({}, TaskEventProgressGainModule)
  eleModel:Init()
  return eleModel
end

function TaskEventProgressGainModule:Init()
  BaseActivityModule.Init(self)
  EventDispatcher.AddListener(EEventType.GoldScoreAcquired, self, self._OnGoldScoreAcquired)
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
  EventDispatcher.AddListener(EEventType.IAPSuccess, self, self._OnIAPSuccess)
  EventDispatcher.AddListener(EEventType.TestModeIAPSuccess, self, self._OnIAPSuccess)
  EventDispatcher.AddListener(EEventType.AlbumCardAcquired, self, self._OnAlbumCardAcquired)
  EventDispatcher.AddListener(EEventType.AlbumOneStarCardAcquired, self, self._OnAlbumOneStarCardAcquired)
  EventDispatcher.AddListener(EEventType.AlbumTwoStarCardAcquired, self, self._OnAlbumTwoStarCardAcquired)
  EventDispatcher.AddListener(EEventType.AlbumThreeStarCardAcquired, self, self._OnAlbumThreeStarCardAcquired)
  EventDispatcher.AddListener(EEventType.AlbumFourStarCardAcquired, self, self._OnAlbumFourStarCardAcquired)
  EventDispatcher.AddListener(EEventType.AlbumFiveStarCardAcquired, self, self._OnAlbumFiveStarCardAcquired)
  EventDispatcher.AddListener(EEventType.UIBoardGeneratedItem, self, self._OnUIBoardGeneratedItem)
  EventDispatcher.AddListener(EEventType.BreakPropUsed, self, self._OnBreakPropUsed)
  EventDispatcher.AddListener(EEventType.DigPropUsed, self, self._OnDigPropUsed)
  EventDispatcher.AddListener(EEventType.FarmPropUsed, self, self._OnFarmPropUsed)
  EventDispatcher.AddListener(EEventType.FreefallTokenUsed, self, self._OnFreefallTokenUsed)
  EventDispatcher.AddListener(EEventType.FreefallTargetBeaten, self, self._OnFreefallTargetBeaten)
  EventDispatcher.AddListener(EEventType.FreefallClearTargetBeatenCount, self, self._OnFreefallClearTargetBeatenCount)
  EventDispatcher.AddListener(EEventType.FreefallUnlockMedal, self, self._OnFreefallMedalUnlocked)
  EventDispatcher.AddListener(EEventType.HitBricksPropUsed, self, self._OnHitBricksPropUsed)
  EventDispatcher.AddListener(EEventType.MainDecorNewTokenNumberChanged, self, self._OnMainDecorNewTokenNumberChanged)
  EventDispatcher.AddListener(EEventType.GemConsumed, self, self._OnGemConsumed)
  EventDispatcher.AddListener(EEventType.OrderBoostSmileAddScore, self, self._OnOrderBoostSmileAddScore)
  EventDispatcher.AddListener(EEventType.StickerUseToken, self, self._OnStickerTokenUsed)
  EventDispatcher.AddListener(EEventType.ChestCustomerOrderFinish, self, self._OnRacoonOrderFinish)
  EventDispatcher.AddListener(EEventType.AlbumUnpackAnimFinished, self, self._DelayShowProgress)
  EventDispatcher.AddListener(EEventType.DigLevelUp, self, self._OnDigLevelUp)
  EventDispatcher.AddListener(EEventType.CoinRaceRoundReward, self, self._OnCoinRaceRoundReward)
  EventDispatcher.AddListener(EEventType.WipeOutRoundReward, self, self._OnWipeOutRoundReward)
  EventDispatcher.AddListener(EEventType.PassActivityLevelUp, self, self._OnPassActivityLevelUp)
  EventDispatcher.AddListener(EEventType.CashDashLevelUp, self, self._OnCashDashLevelUp)
  EventDispatcher.AddListener(EEventType.CookingFrenzyBuffChanged, self, self._OnCookingFrenzyBuffChanged)
  EventDispatcher.AddListener(EEventType.AcquireMedal, self, self._OnAcquireMedal)
  EventDispatcher.AddListener(EEventType.MainTaskFinished, self, self._OnMainTaskFinish)
  EventDispatcher.AddListener(EEventType.AcquireWeeklyStar, self, self._OnAcquireWeeklyStar)
  EventDispatcher.AddListener(EEventType.LightUpBook, self, self._OnLightUpBook)
  EventDispatcher.AddListener(EEventType.RefreshLightUpBook, self, self._OnRefreshLightUpBook)
  EventDispatcher.AddListener(EEventType.UpdateLightUpBook, self, self._OnUpdateLightUpBook)
  EventDispatcher.AddListener(EEventType.MainDecorNewSkinUnlock, self, self._OnMainDecorNewSkinUnlock)
  EventDispatcher.AddListener(EEventType.WheelSpinRound, self, self._OnWheelSpinRound)
  EventDispatcher.AddListener(EEventType.PairWorkAcquireReward, self, self._OnPairWorkAcquireReward)
  EventDispatcher.AddListener(EEventType.MapExploreTask, self, self._OnMapExploreTask)
  EventDispatcher.AddListener(EEventType.MapExploreStar, self, self._OnMapExploreStar)
  EventDispatcher.AddListener(EEventType.MapExploreEndRefresh, self, self._OnMapExploreEndRefresh)
  EventDispatcher.AddListener(EEventType.PropertyConsumed, self, self._OnEnergyConsumed)
  EventDispatcher.AddListener(EEventType.BubbleSpread, self, self._OnBubbleItemSpread)
  EventDispatcher.AddListener(EEventType.LevelUp, self, self._OnLevelUp)
  EventDispatcher.AddListener(EEventType.ItemUnlocked, self, self._OnItemUnlocked)
  EventDispatcher.AddListener(EEventType.MapExploreCostEnergy, self, self._OnMapExploreCostEnergy)
end

function TaskEventProgressGainModule:AddRegister(model, conditionFunction)
  conditionFunction = conditionFunction or function()
    return model:GetState(false) == ActivityState.Started
  end
  self.m_mapModelInfo[model] = {conditionFunction = conditionFunction}
end

function TaskEventProgressGainModule:RemoveRegister(model)
  self.m_mapModelInfo[model] = nil
end

function TaskEventProgressGainModule:_OnProgressGain(msg)
  if msg.operation == nil then
    msg.operation = TaskEventProgressGainModule.TaskOper.Add
  end
  for model, modelInfo in pairs(self.m_mapModelInfo) do
    if modelInfo.conditionFunction() then
      model:_OnProgressGain(msg)
    end
  end
end

function TaskEventProgressGainModule:_DelayShowProgress()
  for model, modelInfo in pairs(self.m_mapModelInfo) do
    if modelInfo.conditionFunction() and model.delayShowProgress ~= nil then
      model.delayShowProgress()
      model.delayShowProgress = nil
    end
  end
end

function TaskEventProgressGainModule:_OnItemMerged(msg)
  self:_OnProgressGain({
    type = TaskEventType.ItemMerge,
    num = 1,
    mergeItem = msg.New
  })
  self:_OnProgressGain({
    type = TaskEventType.Item,
    num = 1,
    mergeItem = msg.New
  })
  local level = GM.ItemDataModel:GetChainLevel(msg.New:GetType())
  if level == 3 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge3,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  elseif level == 4 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge4,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  elseif level == 5 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge5,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  elseif level == 6 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge6,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  elseif level == 7 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge7,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  elseif level == 8 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge8,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  elseif level == 9 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge9,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  elseif level == 10 then
    self:_OnProgressGain({
      type = TaskEventType.ItemMerge10,
      num = 1,
      mergeItem = msg.New,
      boardType = msg.Source.m_boardModel.BoardType
    })
  end
end

function TaskEventProgressGainModule:_OnOrderFinished(msg)
  self:_OnProgressGain({
    type = TaskEventType.OrderFinish,
    num = 1,
    order = msg.order
  })
  if msg.order.GetInnerType ~= nil and msg.order:GetInnerType() == MainOrderType.TimedOrder then
    self:_OnRacoonOrderFinish(msg)
  end
end

function TaskEventProgressGainModule:_OnIAPSuccess(iapType)
  self:_OnProgressGain({
    type = TaskEventType.Payment,
    num = 1
  })
end

function TaskEventProgressGainModule:_OnGoldScoreAcquired(msg)
  self:_OnProgressGain({
    type = TaskEventType.GoldAcquire,
    num = msg.count,
    scene = msg.scene
  })
end

function TaskEventProgressGainModule:_OnAlbumCardAcquired(msg)
  self:_OnProgressGain({
    type = TaskEventType.CardGain,
    num = 1,
    needwait = msg.isUnpacking
  })
end

function TaskEventProgressGainModule:_OnAlbumOneStarCardAcquired(msg)
  self:_OnProgressGain({
    type = TaskEventType.OneStarCard,
    num = 1,
    needwait = msg.isUnpacking
  })
end

function TaskEventProgressGainModule:_OnAlbumTwoStarCardAcquired(msg)
  self:_OnProgressGain({
    type = TaskEventType.TwoStarCard,
    num = 1,
    needwait = msg.isUnpacking
  })
end

function TaskEventProgressGainModule:_OnAlbumThreeStarCardAcquired(msg)
  self:_OnProgressGain({
    type = TaskEventType.ThreeStarCard,
    num = 1,
    needwait = msg.isUnpacking
  })
end

function TaskEventProgressGainModule:_OnAlbumFourStarCardAcquired(msg)
  self:_OnProgressGain({
    type = TaskEventType.FourStarCard,
    num = 1,
    needwait = msg.isUnpacking
  })
end

function TaskEventProgressGainModule:_OnAlbumFiveStarCardAcquired(msg)
  self:_OnProgressGain({
    type = TaskEventType.FiveStarCard,
    num = 1,
    needwait = msg.isUnpacking
  })
end

function TaskEventProgressGainModule:_OnUIBoardGeneratedItem(msg)
  self:_OnProgressGain({
    type = TaskEventType.UIBoardItemUnlock .. msg.boardType,
    num = 1,
    item = msg.code
  })
  self:_OnProgressGain({
    type = TaskEventType.UIBoardItemAcquire .. msg.boardType,
    num = 1,
    item = msg.code
  })
end

function TaskEventProgressGainModule:_OnRacoonOrderFinish(msg)
  self:_OnProgressGain({
    type = TaskEventType.RacoonFinish,
    num = 1
  })
end

function TaskEventProgressGainModule:_OnBreakPropUsed(msg)
  self:_OnProgressGain({
    type = TaskEventType.UseBreakToken,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnDigPropUsed(num)
  self:_OnProgressGain({
    type = TaskEventType.DigPropUse,
    num = num
  })
end

function TaskEventProgressGainModule:_OnFarmPropUsed(msg)
  self:_OnProgressGain({
    type = TaskEventType.UseFarmToken,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnFreefallTokenUsed(msg)
  self:_OnProgressGain({
    type = TaskEventType.UseFreeFallToken,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnFreefallTargetBeaten(msg)
  self:_OnProgressGain({
    type = TaskEventType.FreefallTargetBeaten,
    num = msg
  })
end

function TaskEventProgressGainModule:_OnFreefallClearTargetBeatenCount(msg)
  self:_OnProgressGain({
    type = TaskEventType.FreefallTargetBeaten,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = 0
  })
end

function TaskEventProgressGainModule:_OnFreefallMedalUnlocked(msg)
  self:_OnProgressGain({
    type = TaskEventType.FreefallUnlockMedal,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg
  })
end

function TaskEventProgressGainModule:_OnHitBricksPropUsed(msg)
  self:_OnProgressGain({
    type = TaskEventType.HammerUse,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnMainDecorNewTokenNumberChanged(num)
  if 0 < num then
    self:_OnProgressGain({
      type = TaskEventType.DecorToken,
      num = num
    })
  end
end

function TaskEventProgressGainModule:_OnGemConsumed(msg)
  self:_OnProgressGain({
    type = TaskEventType.GemConsume,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnOrderBoostSmileAddScore(num)
  if 0 < num then
    self:_OnProgressGain({
      type = TaskEventType.OrderBoost,
      num = num
    })
  end
end

function TaskEventProgressGainModule:_OnDigLevelUp(msg)
  self:_OnProgressGain({
    type = TaskEventType.MineralLevel,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnCoinRaceRoundReward(msg)
  self:_OnProgressGain({
    type = TaskEventType.CoinRaceLevel,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnWipeOutRoundReward(msg)
  self:_OnProgressGain({
    type = TaskEventType.WipeoutLevel,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnPassActivityLevelUp(msg)
  self:_OnProgressGain({
    type = TaskEventType.PassLevel,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    atype = msg.atype,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnCashDashLevelUp(msg)
  self:_OnProgressGain({
    type = TaskEventType.CashDashLevel,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    atype = msg.atype,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnCookingFrenzyBuffChanged(msg)
  if msg.buffId == "ruby" then
    self:_OnProgressGain({
      type = TaskEventType.CookingFrenzyRuby,
      operation = TaskEventProgressGainModule.TaskOper.Add,
      num = 1
    })
  end
end

function TaskEventProgressGainModule:_OnAcquireMedal(msg)
  self:_OnProgressGain({
    type = TaskEventType.Medal,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnMainTaskFinish(msg)
  self:_OnProgressGain({
    type = TaskEventType.MainTask,
    operation = TaskEventProgressGainModule.TaskOper.Add,
    num = 1
  })
  self:_OnProgressGain({
    type = TaskEventType.Complete,
    operation = TaskEventProgressGainModule.TaskOper.Add,
    num = 1
  })
end

function TaskEventProgressGainModule:_OnAcquireWeeklyStar(msg)
  self:_OnProgressGain({
    type = TaskEventType.WeeklyStar,
    operation = TaskEventProgressGainModule.TaskOper.Add,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnLightUpBook(msg)
  local taskItemType, taskAnyType, taskChainType = self:_GetTaskTypeByActivityType(msg.atype)
  self:_OnProgressGain({
    type = taskItemType,
    operation = TaskEventProgressGainModule.TaskOper.Add,
    atype = msg.atype,
    item = msg.item,
    num = msg.num
  })
  self:_OnProgressGain({
    type = taskAnyType,
    operation = TaskEventProgressGainModule.TaskOper.Add,
    atype = msg.atype,
    num = 1
  })
  self:_OnProgressGain({
    type = taskChainType,
    operation = TaskEventProgressGainModule.TaskOper.UpdateBook,
    atype = msg.atype,
    num = 1
  })
end

function TaskEventProgressGainModule:_OnRefreshLightUpBook(msg)
  local taskItemType, taskAnyType, taskChainType = self:_GetTaskTypeByActivityType(msg.atype)
  self:_OnProgressGain({
    type = taskItemType,
    operation = TaskEventProgressGainModule.TaskOper.RefreshBook,
    atype = msg.atype
  })
  self:_OnProgressGain({
    type = taskAnyType,
    operation = TaskEventProgressGainModule.TaskOper.RefreshBook,
    atype = msg.atype
  })
  self:_OnProgressGain({
    type = taskChainType,
    operation = TaskEventProgressGainModule.TaskOper.RefreshBook,
    atype = msg.atype
  })
end

function TaskEventProgressGainModule:_OnUpdateLightUpBook(msg)
  local taskItemType, taskAnyType, taskChainType = self:_GetTaskTypeByActivityType(msg.atype)
  self:_OnProgressGain({
    type = taskItemType,
    operation = TaskEventProgressGainModule.TaskOper.UpdateBook,
    atype = msg.atype
  })
  self:_OnProgressGain({
    type = taskAnyType,
    operation = TaskEventProgressGainModule.TaskOper.UpdateBook,
    atype = msg.atype
  })
  self:_OnProgressGain({
    type = taskChainType,
    operation = TaskEventProgressGainModule.TaskOper.UpdateBook,
    atype = msg.atype
  })
end

function TaskEventProgressGainModule:_OnMainDecorNewSkinUnlock(msg)
  self:_OnProgressGain({
    type = TaskEventType.MainDecoAny,
    operation = TaskEventProgressGainModule.TaskOper.Add,
    atype = msg.atype,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnWheelSpinRound(msg)
  self:_OnProgressGain({
    type = TaskEventType.SuperWheelSpin,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnPairWorkAcquireReward(msg)
  self:_OnProgressGain({
    type = TaskEventType.PairWorkProgress,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnMapExploreEndRefresh(msg)
  self:_OnProgressGain({
    type = TaskEventType.MapExploreAll,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnMapExploreTask(msg)
  self:_OnProgressGain({
    type = TaskEventType.MapExploreAll,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnMapExploreStar(msg)
  self:_OnProgressGain({
    type = TaskEventType.MapExploreMain,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_OnEnergyConsumed(msg)
  if msg.property[PROPERTY_TYPE] == EPropertyType.Energy then
    self:_OnProgressGain({
      type = TaskEventType.Energy,
      operation = TaskEventProgressGainModule.TaskOper.Add,
      num = msg.property[PROPERTY_COUNT]
    })
  end
end

function TaskEventProgressGainModule:_OnBubbleItemSpread(msg)
  self:_OnProgressGain({
    type = TaskEventType.Bubble,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = 1
  })
end

function TaskEventProgressGainModule:_OnLevelUp(msg)
  self:_OnProgressGain({
    type = TaskEventType.Level,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = msg.level
  })
end

function TaskEventProgressGainModule:_OnItemUnlocked(msg)
  self:_OnProgressGain({
    type = TaskEventType.Unlock,
    operation = TaskEventProgressGainModule.TaskOper.Update,
    num = 1,
    item = msg.type
  })
end

function TaskEventProgressGainModule:_OnMapExploreCostEnergy(msg)
  self:_OnProgressGain({
    type = TaskEventType.MapExploreEnergy,
    operation = TaskEventProgressGainModule.TaskOper.Add,
    num = msg.num
  })
end

function TaskEventProgressGainModule:_GetTaskTypeByActivityType(type)
  local taskItemType = ""
  local taskAnyType = ""
  local taskChainType = ""
  if MultiboardsActivityDefinition[type] then
    taskItemType = TaskEventType.MtbBookItem
    taskAnyType = TaskEventType.MtbBookAny
    taskChainType = TaskEventType.MtbBookChain
  elseif AdventureActivityDefinition[type] then
    taskItemType = TaskEventType.AdventureBookItem
    taskAnyType = TaskEventType.AdventureBookAny
    taskChainType = TaskEventType.AdventureBookChain
  elseif FarmboardActivityDefinition[type] then
    taskItemType = TaskEventType.FarmBookItem
    taskAnyType = TaskEventType.FarmBookAny
    taskChainType = TaskEventType.FarmBookChain
  elseif DigActivityDefinition[type] then
    taskItemType = TaskEventType.MineralBookItem
    taskAnyType = TaskEventType.MineralBookAny
    taskChainType = TaskEventType.MineralBookChain
  end
  return taskItemType, taskAnyType, taskChainType
end

function TaskEventProgressGainModule:_OnStickerTokenUsed(num)
  self:_OnProgressGain({
    type = TaskEventType.UseStickerToken,
    num = num
  })
end

TaskCommonInfoGetter = {}

function TaskCommonInfoGetter.GetIconKey(taskType, itemCode)
  local key = "task_icon_"
  if string.find(taskType, "item_") then
    key = itemCode
  elseif taskType == TaskEventType.Item then
    key = itemCode
  elseif taskType == TaskEventType.Unlock then
    key = itemCode
  elseif taskType == TaskEventType.DigPropUse then
    local model = GM.ActivityManager:GetStartedActivityByDefinition(DigActivityDefinition)
    if model then
      key = model:GetDefinition().TokenImageName
    end
  elseif taskType == TaskEventType.UseFarmToken then
    local farmModel = GM.ActivityManager:GetStartedFarmboardActivity()
    if farmModel then
      key = farmModel:GetDefinition().TokenImageName
    end
  elseif taskType == TaskEventType.GoldAcquire then
    local bakeoutModel = GM.ActivityManager:GetModel(ActivityType.BakeOut)
    if bakeoutModel and bakeoutModel:CanAcquireToken() then
      key = key .. "bakeout"
    else
      key = key .. taskType
    end
  elseif TaskCommonInfoGetter.IsItemMergeTask(taskType) then
    key = key .. "merge"
  else
    key = key .. taskType
  end
  return key
end

function TaskCommonInfoGetter.IsCardGainNStar(taskType)
  if taskType == TaskEventType.OneStarCard or taskType == TaskEventType.TwoStarCard or taskType == TaskEventType.ThreeStarCard or taskType == TaskEventType.FourStarCard or taskType == TaskEventType.FiveStarCard then
    return true
  end
  return false
end

function TaskCommonInfoGetter.IsItemMergeTask(taskType)
  if taskType == TaskEventType.ItemMerge3 or taskType == TaskEventType.ItemMerge4 or taskType == TaskEventType.ItemMerge5 or taskType == TaskEventType.ItemMerge6 or taskType == TaskEventType.ItemMerge7 or taskType == TaskEventType.ItemMerge8 or taskType == TaskEventType.ItemMerge9 or taskType == TaskEventType.ItemMerge10 then
    return true
  end
  return false
end

function TaskCommonInfoGetter.GetHintText(taskType)
  local key
  if string.find(taskType, "unlock_adv") then
    key = "common_task_unlock_adv_hint"
  elseif string.find(taskType, "unlock_multi") then
    key = "common_task_unlock_mtb_hint"
  elseif string.find(taskType, "acquire_adv") then
    key = "common_task_acquire_adv_hint"
  elseif string.find(taskType, "acquire_multi") then
    key = "common_task_acquire_mtb_hint"
  else
    key = "common_task_" .. taskType .. "_hint"
  end
  local hint = GM.GameTextModel:GetText(key)
  return hint
end

function TaskCommonInfoGetter.GetTaskText(taskType, arg1)
  local key = "common_task_"
  if string.find(taskType, "item_unlock_a") then
    key = key .. "unlock_adv"
  elseif string.find(taskType, "item_unlock_m") then
    key = key .. "unlock_mtb"
  elseif string.find(taskType, "item_acquire_a") then
    key = key .. "acquire_adv"
  elseif string.find(taskType, "item_acquire_m") then
    key = key .. "acquire_mtb"
  else
    key = key .. taskType
  end
  local taskTypesWithPluralSupport = {
    TaskEventType.Login
  }
  local suffixSingle = "_single"
  local suffixMultiple = "_multiple"
  if Table.Contain(taskTypesWithPluralSupport, taskType) then
    key = key .. (arg1 == 1 and suffixSingle or suffixMultiple)
  end
  local text = GM.GameTextModel:GetText(key, arg1)
  return text
end
