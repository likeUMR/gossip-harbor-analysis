local Sec2Day = _ENV.Sec2Day
local RatioPreciseScale = 100
BubbleDecreaseModel = {}
BubbleDecreaseModel.__index = BubbleDecreaseModel

function BubbleDecreaseModel:Init()
  EventDispatcher.AddListener(EEventType.LoginFinished, self, self.OnLoginFinished)
  EventDispatcher.AddListener(EEventType.BubbleBroken, self, self.OnBubbleBroken)
end

function BubbleDecreaseModel:LoadServerConfig()
  self.m_bGeneralConfEnabled = GM.ConfigModel:IsServerControlOpen(EGeneralConfType.BubbleDecrease)
  local md5 = GM.ConfigModel:GetServerConfigMD5(ServerConfigKey.BubbleDecreaseConfig)
  if md5 == self.m_md5 then
    return
  end
  self.m_md5 = md5
  if GameConfig.IsTestMode() then
    self.m_strTestConfig = ""
  end
  local configs = GM.ConfigModel:GetServerConfig(ServerConfigKey.BubbleDecreaseConfig)
  self.m_arrDays = {}
  self.m_mapDay2DecreaseRatio = {}
  if not Table.IsEmpty(configs) then
    for _, config in ipairs(configs) do
      self.m_arrDays[#self.m_arrDays + 1] = config.no_purchase_days
      self.m_mapDay2DecreaseRatio[config.no_purchase_days] = config.decrease_ratio
    end
    table.sort(self.m_arrDays)
    if GameConfig.IsTestMode() then
      for _, day in ipairs(self.m_arrDays) do
        self.m_strTestConfig = self.m_strTestConfig .. "\n" .. day .. ":" .. self.m_mapDay2DecreaseRatio[day] / RatioPreciseScale
      end
    end
  end
end

function BubbleDecreaseModel:OnLoginFinished(msg)
  if msg.bSuccess then
    self:_Try2UpdateNoPurchaseBubbleLoginDays()
  end
end

function BubbleDecreaseModel:OnSyncDataFinished()
  self:_Try2UpdateNoPurchaseBubbleLoginDays()
end

function BubbleDecreaseModel:_Try2UpdateNoPurchaseBubbleLoginDays()
  local serverTime = GM.GameModel:GetServerTime()
  local noPurchaseBubbleLastLoginTimeStamp = GM.MiscModel:GetBubbleNoPurchaseLastLoginTimeStampInNumber()
  if noPurchaseBubbleLastLoginTimeStamp // Sec2Day ~= serverTime // Sec2Day then
    GM.MiscModel:SetBubbleNoPurchaseLastLoginTimeStamp(serverTime)
    GM.MiscModel:SetBubbleNoPurchaseLoginDays(GM.MiscModel:GetBubbleNoPurchaseLoginDaysInNumber() + 1)
  end
end

function BubbleDecreaseModel:OnBubbleBroken(msg)
  if not msg.IsFree and msg.Cost and msg.Cost > 0 then
    GM.MiscModel:SetBubbleNoPurchaseLoginDays(0)
  end
end

function BubbleDecreaseModel:GetBubbleDecreaseRatio()
  local noPurchaseBubbleLoginDays = GM.MiscModel:GetBubbleNoPurchaseLoginDaysInNumber()
  if not self.m_bGeneralConfEnabled or Table.IsEmpty(self.m_arrDays) or noPurchaseBubbleLoginDays <= 0 then
    return 1
  end
  local selectedDayIndex = -1
  for i, day in ipairs(self.m_arrDays) do
    if day < noPurchaseBubbleLoginDays then
      selectedDayIndex = i
    end
  end
  if selectedDayIndex == -1 then
    return 1
  end
  return self.m_mapDay2DecreaseRatio[self.m_arrDays[selectedDayIndex]] / RatioPreciseScale
end

function BubbleDecreaseModel:GetTestInfo()
  return "\233\133\141\231\189\174\230\152\175\229\144\166\229\188\128\229\144\175:" .. tostring(self.m_bGeneralConfEnabled) .. "\n\229\189\147\229\137\141\233\133\141\231\189\174\229\134\133\229\174\185:" .. (StringUtil.IsNilOrEmpty(self.m_strTestConfig) and "\230\151\160" or self.m_strTestConfig) .. "\n\229\189\147\229\137\141\230\156\170\232\180\173\228\185\176\230\179\161\230\179\161\231\154\132\231\180\175\231\167\175\231\153\187\229\189\149\229\164\169\230\149\176:" .. tostring(GM.MiscModel:GetBubbleNoPurchaseLoginDaysInNumber()) .. "\n\229\189\147\229\137\141\232\161\176\229\135\143\230\175\148\228\190\139:" .. tostring(self:GetBubbleDecreaseRatio()) .. (not StringUtil.IsNilOrEmpty(self.m_lastMergeBubbleTestInfo) and [[

----------------
]] .. self.m_lastMergeBubbleTestInfo or "")
end

function BubbleDecreaseModel:RecordBubbleDecreaseInfo(info)
  self.m_lastMergeBubbleTestInfo = info
end
