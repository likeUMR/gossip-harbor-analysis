GooglePgsManager = {}
GooglePgsManager.__index = GooglePgsManager
EAchievementStatus = {
  UNLOCKED = 0,
  REVEALED = 1,
  HIDDEN = 2
}
EAchievementType = {STANDARD = 0, INCREMENTAL = 1}
local orderAchievementsKey = {
  "CgkI3YvxrpUIEAIQAQ",
  "CgkI3YvxrpUIEAIQAg",
  "CgkI3YvxrpUIEAIQAw",
  "CgkI3YvxrpUIEAIQBA",
  "CgkI3YvxrpUIEAIQBQ",
  "CgkI3YvxrpUIEAIQBg"
}
local dayAchievements = {
  {
    id = "CgkI3YvxrpUIEAIQBw",
    days = 1
  },
  {
    id = "CgkI3YvxrpUIEAIQCA",
    days = 2
  },
  {
    id = "CgkI3YvxrpUIEAIQCQ",
    days = 20
  },
  {
    id = "CgkI3YvxrpUIEAIQCg",
    days = 100
  },
  {
    id = "CgkI3YvxrpUIEAIQCw",
    days = 200
  }
}
local levelAchievements = {
  {
    id = "CgkI3YvxrpUIEAIQDA",
    level = 6
  }
}
local albumAchievementsKeys = {
  "CgkI3YvxrpUIEAIQDg",
  "CgkI3YvxrpUIEAIQDw"
}
local collectionAchievements = {
  {
    id = "CgkI3YvxrpUIEAIQEA",
    count = 2
  },
  {
    id = "CgkI3YvxrpUIEAIQEQ",
    count = 4
  }
}

function GooglePgsManager:Init()
  CSGooglePgsClient:Init()
  self:CheckAuthenticated(function(success, data)
    if success then
      self:GetAchievements(true)
    end
  end)
  EventDispatcher.AddListener(EEventType.EnterMainScene, self, self._OnEnterMainScene)
  EventDispatcher.AddListener(EEventType.LevelUp, self, self._OnLevelUp)
  EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
  EventDispatcher.AddListener(EEventType.MainTaskFinished, self, self._OnTaskFinished)
  EventDispatcher.AddListener(EEventType.AlbumGradeCompleted, self, self._OnAlbumCompleted)
  EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
  EventDispatcher.AddListener(EEventType.PropertyAcquired, self, self._OnPropertyAcquired)
  EventDispatcher.AddListener(EEventType.OrderBoostSmileAddScore, self, self._OnOrderBoostSmileAddScore)
end

function GooglePgsManager:_OnEnterMainScene()
  if self.m_achievementsProgress ~= nil then
    self:_CheckStatsAchievements()
  else
    self:CheckAuthenticated(function(success, data)
      if success then
        self:GetAchievements(true, function()
          if GM == nil then
            return
          end
          self:_CheckStatsAchievements()
        end)
      end
    end)
  end
  self:RecordGameStatsUserLevel()
end

function GooglePgsManager:LateUpdate()
  if self.m_bNeedRefreshAchievements and not self.m_bGettingAchievements then
    self:GetAchievements()
    self.m_bNeedRefreshAchievements = nil
  end
end

function GooglePgsManager:CheckAuthenticated(callback)
  CSGooglePgsClient:CheckAuth(function(success, data)
    if success then
      Log.Info("[GooglePgsManager] CheckAuthenticated success:" .. tostring(data))
    else
      Log.Warning("[GooglePgsManager] CheckAuthenticated failed:" .. tostring(data))
    end
    if callback then
      callback(success, data)
    end
  end)
end

function GooglePgsManager:SignIn(callback)
  CSGooglePgsClient:Login(function(success, data)
    if success then
      Log.Info("[GooglePgsManager] SignIn success:" .. tostring(data))
      self:GetAchievements(true)
    else
      Log.Warning("[GooglePgsManager] SignIn failed:" .. tostring(data))
    end
    if callback then
      callback(success, data)
    end
  end)
end

function GooglePgsManager:_OnOrderFinished(msg)
  self:IncreaseAchievements(orderAchievementsKey)
  self:RecordGameStatsOrderAmount()
end

function GooglePgsManager:_OnLevelUp()
  local curLevel = GM.LevelModel:GetCurrentLevel()
  self:CheckLevelAchievements(curLevel)
  self:RecordGameStatsUserLevel()
end

function GooglePgsManager:_OnTaskFinished(data)
  self:CheckTimelineAchievements()
end

function GooglePgsManager:_OnAlbumCompleted(count)
  self:IncreaseAchievements(albumAchievementsKeys)
  self:CheckCollectionAchievements(count)
  self:RecordGameStatsAlbumComplete()
end

function GooglePgsManager:_OnItemMerged(msg)
  self:RecordGameStatsMerge()
end

function GooglePgsManager:_OnPropertyAcquired(msg)
  for _, propertyData in ipairs(msg.arrProperties) do
    if (propertyData[PROPERTY_TYPE] == EPropertyType.Gold or propertyData[PROPERTY_TYPE] == EPropertyType.BakeOutToken) and propertyData[PROPERTY_COUNT] ~= nil and propertyData[PROPERTY_COUNT] > 0 then
      self:RecordGameStatsCoinAcquired(propertyData[PROPERTY_COUNT])
    end
  end
end

function GooglePgsManager:_OnOrderBoostSmileAddScore(msg)
  self:RecordGameStatsSmileAcquired(msg)
end

function GooglePgsManager:_CheckStatsAchievements()
  if GM.MainTaskModel:IsAllFinished() then
    self:CheckTimelineAchievements()
  end
  local curLevel = GM.LevelModel:GetCurrentLevel()
  if 1 < curLevel then
    self:CheckLevelAchievements(curLevel)
  end
end

function GooglePgsManager:GetAchievements(refresh, successCallback, retryTime)
  if self.m_bGettingAchievements then
    return
  end
  if IsNil(retryTime) then
    retryTime = 0
  end
  self.m_bGettingAchievements = true
  CSGooglePgsClient:GetAchievements(IsBool(refresh) and refresh or false, function(success, data)
    self.m_bGettingAchievements = nil
    if success then
      Log.Info("[GooglePgsManager] GetAchievements success:" .. tostring(data))
      self.m_achievementsProgress = json.decode(data)
      if successCallback then
        successCallback()
      end
    else
      self:_RetryGetAchievements(refresh, successCallback, retryTime)
      Log.Warning("[GooglePgsManager] GetAchievements failed:" .. tostring(data))
    end
  end)
end

function GooglePgsManager:_RetryGetAchievements(refresh, successCallback, retryTime)
  Log.Info("GooglePgsManager:_RetryGetAchievements")
  if IsNil(self) then
    Log.Info("GooglePgsManager:_RetryGetAchievements:self nil")
    return
  end
  if IsNil(retryTime) then
    Log.Info("retryTime nil")
    return
  end
  if 3 < retryTime then
    Log.Info("GooglePgsManager:_RetryGetAchievements >3")
    return
  end
  retryTime = retryTime + 1
  DelayExecuteFunc(function()
    Log.Info("GooglePgsManager:_RetryGetAchievements delay:" .. tostring(retryTime))
    self:GetAchievements(refresh, successCallback, retryTime)
  end, 2 * retryTime, self)
end

function GooglePgsManager:CheckTimelineAchievements()
  if self.m_achievementsProgress == nil then
    self:GetAchievements()
    return
  end
  local curDay, Id = GM.MainTaskModel:GetCurTaskDayAndId()
  for i, item in ipairs(dayAchievements) do
    local progress = self.m_achievementsProgress[item.id]
    if progress ~= nil and progress.status ~= EAchievementStatus.UNLOCKED and curDay > item.days then
      CSGooglePgsClient:UnlockAchievement(item.id)
      progress.status = EAchievementStatus.UNLOCKED
      self.m_bNeedRefreshAchievements = true
    end
  end
end

function GooglePgsManager:CheckLevelAchievements(level)
  if self.m_achievementsProgress == nil then
    self:GetAchievements()
    return
  end
  if level == nil or level <= 0 then
    return
  end
  for i, item in ipairs(levelAchievements) do
    local progress = self.m_achievementsProgress[item.id]
    if progress ~= nil and progress.status ~= EAchievementStatus.UNLOCKED and level >= item.level then
      CSGooglePgsClient:UnlockAchievement(item.id)
      progress.status = EAchievementStatus.UNLOCKED
      self.m_bNeedRefreshAchievements = true
    end
  end
end

function GooglePgsManager:CheckCollectionAchievements(count)
  if self.m_achievementsProgress == nil then
    self:GetAchievements()
    return
  end
  if count == nil or count <= 0 then
    return
  end
  for i, item in ipairs(collectionAchievements) do
    local progress = self.m_achievementsProgress[item.id]
    if progress ~= nil and progress.status ~= EAchievementStatus.UNLOCKED and count >= item.count then
      CSGooglePgsClient:UnlockAchievement(item.id)
      progress.status = EAchievementStatus.UNLOCKED
      self.m_bNeedRefreshAchievements = true
    end
  end
end

function GooglePgsManager:IncreaseAchievements(achievementsKeys, step)
  if self.m_achievementsProgress == nil then
    self:GetAchievements()
    return
  end
  for i, achievementId in ipairs(achievementsKeys) do
    local progress = self.m_achievementsProgress[achievementId]
    if progress ~= nil and progress.status ~= EAchievementStatus.UNLOCKED then
      CSGooglePgsClient:IncreaseAchievement(achievementId, step or 1)
      progress.step = progress.step + (step or 1)
      if progress.step >= progress.total then
        self.m_bNeedRefreshAchievements = true
      end
    end
  end
end

function GooglePgsManager:ShowAchievementsUI()
  CSGooglePgsClient:ShowAchievementsUI()
end

function GooglePgsManager:Test_FinishOrderAchievements(step)
  self:IncreaseAchievements(orderAchievementsKey, step)
end

function GooglePgsManager:RecordGameStatsOrderAmount()
  CSGooglePgsClient:RecordGameEvent("orderComplete", json.encode({orderAmount = 1}))
end

function GooglePgsManager:RecordGameStatsCoinAcquired(num)
  CSGooglePgsClient:RecordGameEvent("coinAcquired", json.encode({coinAmount = num}))
end

function GooglePgsManager:RecordGameStatsSmileAcquired(num)
  CSGooglePgsClient:RecordGameEvent("smileAcquired", json.encode({smileAmount = num}))
end

function GooglePgsManager:RecordGameStatsMerge()
  CSGooglePgsClient:RecordGameEvent("mergeComplete", json.encode({mergeAmount = 1}))
end

function GooglePgsManager:RecordGameStatsAlbumComplete()
  CSGooglePgsClient:RecordGameEvent("albumComplete", json.encode({albumAmount = 1}))
end

function GooglePgsManager:RecordGameStatsUserLevel()
  CSGooglePgsClient:RecordGameEvent("progressUpdate", json.encode({
    currentProgress = GM.LevelModel:GetCurrentLevel()
  }))
end
