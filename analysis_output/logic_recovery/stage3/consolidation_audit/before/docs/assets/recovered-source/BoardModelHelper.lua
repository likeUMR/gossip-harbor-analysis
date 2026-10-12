BoardModelHelper = {}
BoardModelHelper.__index = BoardModelHelper

function BoardModelHelper.GetActiveModel()
  for activityType, activityDefinition in pairs(AdventureActivityDefinition) do
    local adventureActivityMainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if adventureActivityMainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetAdventureActivityBoardView()
    end
  end
  for activityType, activityDefinition in pairs(MultiboardsActivityDefinition) do
    local adventureActivityMainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if adventureActivityMainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetMultiboardsActivityBoardView()
    end
  end
  for activityType, activityDefinition in pairs(FarmboardActivityDefinition) do
    local farmboardMainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if farmboardMainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetFarmboardActivityBoardView()
    end
  end
  for activityType, activityDefinition in pairs(DigActivityDefinition) do
    local digMainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if digMainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetDigBoardView()
    end
  end
  for activityType, activityDefinition in pairs(FreefallActivityDefinition) do
    local extraBoardWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.ExtraBoardWindowPrefabName)
    if extraBoardWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetExtraBoardModel(), GM.ModeViewController:GetFreefallActivityExtraBoardView()
    end
    local mainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if mainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetFreefallActivityBoardView()
    end
  end
  for activityType, activityDefinition in pairs(BreakDefinition) do
    local breakMainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if breakMainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetBreakBoardView()
    end
  end
  for activityType, activityDefinition in pairs(MapExploreActivityDefinition) do
    local mapExploreBoardWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.BoardWindowPrefabName)
    if mapExploreBoardWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetMapExploreActivityBoardView()
    end
  end
  for activityType, activityDefinition in pairs(StickerboardActivityDefinition) do
    local stickerboardMainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if stickerboardMainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetStickerboardActivityBoardView()
    end
  end
  for activityType, activityDefinition in pairs(PureBoardActivityDefinition) do
    local pureboardMainWindow = GM.UIManager:GetOpenedViewByName(activityDefinition.MainWindowPrefabName)
    if pureboardMainWindow ~= nil then
      return GM.ActivityManager:GetModel(activityType):GetBoardModel(), GM.ModeViewController:GetPureBoardView()
    end
  end
  local currentMode = GM.SceneManager:GetGameMode()
  if currentMode == EGameMode.Main then
    return GM.MainBoardModel, MainBoardView.GetInstance()
  end
  return nil, nil
end

function BoardModelHelper.GetModelByGameMode(gameMode)
  if gameMode == EGameMode.Main then
    return GM.MainBoardModel
  else
    local activityModel = BoardModelHelper.GetActivityModelByGameMode(gameMode)
    if activityModel ~= nil then
      return activityModel:GetBoardModel()
    else
      return nil
    end
  end
end

function BoardModelHelper.GetActivityModelByGameMode(gameMode)
  return nil
end

function BoardModelHelper.GetActiveActivityModelEventId()
  local activityModel = BoardModelHelper.GetActivityModelByGameMode(GM.SceneManager:GetGameMode())
  if activityModel then
    return activityModel:GetId()
  end
end

function BoardModelHelper.GetBoardModelByBoardType(boardType)
  local boardModel = BaseActionBoardModel:GetModelInstance(boardType)
  if boardModel ~= nil and boardModel.GetActivityModel ~= nil and boardModel:GetActivityModel().GetBoardModel ~= nil and boardModel:GetActivityModel():GetBoardModel() ~= boardModel then
    return nil
  end
  return boardModel
end

function BoardModelHelper.IsExtraBoard(boardType)
  return boardType == EBoardType.DigBoard or boardType == EBoardType.Multiboards or boardType == EBoardType.Adventure or boardType == EBoardType.Farmboard or boardType == EBoardType.Break or boardType == EBoardType.Stickerboard or boardType == EBoardType.MapExplore or boardType == EBoardType.FreefallExtra or boardType == EBoardType.PureBoard
end

function BoardModelHelper.CalculateLackNumForMergeRequire(code, codeCountMap)
  local chainId = GM.ItemDataModel:GetChainId(code)
  local curLevel = GM.ItemDataModel:GetChainLevel(code)
  local needLevel = curLevel
  local needCount = 1
  for level = curLevel, 1, -1 do
    local curItemType = GM.ItemDataModel:GetTypeByChainAndLevel(chainId, level)
    needCount = needCount * MathUtil.IntPow(2, needLevel - level)
    local curCount = codeCountMap[curItemType] or 0
    if needCount <= curCount then
      codeCountMap[curItemType] = curCount - needCount
      needCount = 0
      break
    else
      codeCountMap[curItemType] = 0
      needCount = needCount - curCount
      needLevel = level
    end
  end
  return needCount
end

function BoardModelHelper.TopLevelReqSatisfied(order, minus)
  local codeCountMap = Table.DeepCopy(GM.MainBoardModel:GetCodeCountMap(true, false, true))
  local requirements = order:GetRequirements()
  local maxLevel = -1
  local code
  for _, req in pairs(requirements) do
    if maxLevel < GM.ItemDataModel:GetChainLevel(req) then
      maxLevel = GM.ItemDataModel:GetChainLevel(req)
      code = req
    end
  end
  if minus then
    maxLevel = maxLevel - minus
  end
  local newCode = GM.ItemDataModel:GetTypeByChainAndLevel(GM.ItemDataModel:GetChainId(code), maxLevel)
  Log.Info("[TopLevelReqSatisfied] check code / newcode: " .. code .. " / " .. newCode)
  return GM.MainBoardModel:HasEnoughItemsToMergeAcquire(newCode, true, false, true)
end
