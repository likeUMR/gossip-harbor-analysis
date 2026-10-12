SDKHelper = {}
SDKHelper.__index = SDKHelper
local EUpdateInfoStep = {
  None = 0,
  DeviceInfo = 1,
  UserInfo = 2,
  GroupInfo = 3
}

function SDKHelper:Init()
  self.m_SDKManager = CS.OneSDK.SDKManager.Instance
  self.m_purchaseClient = self.m_SDKManager.purchaseClient
  self.m_bHasUnreadCSMsg = false
  self.m_purchaseTokens = {}
  self.wechatHelper = setmetatable({}, SDKWechatHelper)
  self.wechatHelper:Init()
  self.douyinHelper = setmetatable({}, SDKDouyinHelper)
  self.douyinHelper:Init()
  self:_RegisterCSharpHandlers()
  self:_RegisterHandlers()
  self.m_appleClientSecret = "eyJhbGciOiJFUzI1NiIsImtpZCI6Ijk5R0hCM044OFgifQ.eyJpc3MiOiJBUjhOWkNIM0dXIiwiaWF0IjoxNzg0NTE2NDAwLCJleHAiOjE4MDAyOTM0MDAsImF1ZCI6Imh0dHBzOi8vYXBwbGVpZC5hcHBsZS5jb20iLCJzdWIiOiJjb20ubWVyZ2VnYW1lLmljb29raWUifQ.L153o1EIJRTPCGWTQe28o9m5B0Ou5A3fe9ADKWBFjhXN5JVB8YStuk9gFjyrKRTvZPkTOF3aVcwpVCqlKclgvQ"
  self.m_updateInfoStep = EUpdateInfoStep.None
  Scheduler.Schedule(self.AiHelpUpdateUserInfoInScheduler, self)
  Log.Info("[Event] AddListener: EEventType.EnterMainScene")
  if MINIGAME_ALIPAY then
    EventDispatcher.AddListener(EEventType.LevelUp, self, self._OnLevelUp)
    EventDispatcher.AddListener(EEventType.OrderFinished, self, self._OnOrderFinished)
    EventDispatcher.AddListener(EEventType.ItemMerged, self, self._OnItemMerged)
  end
  if MINIGAME_WECHAT then
    XyxManager.Instance:AddDirectAdStatusChangeCallback(function(json)
      Log.Info("AddDirectAdStatusChangeCallback:" .. tostring(json))
    end)
  end
end

function SDKHelper:Destroy()
  EventDispatcher.RemoveTarget(self)
  self:_RemoveHandlers()
  self.m_purchaseClient = nil
  self.wechatHelper:Destroy()
  self.wechatHelper = nil
  self.douyinHelper:Destroy()
  self.douyinHelper = nil
end

function SDKHelper:GetAdManager()
  return self.m_SDKManager.adManager
end

function SDKHelper:SetAppleClientSecret(clientSecret)
  self.m_appleClientSecret = clientSecret
end

function SDKHelper:_RegisterHandlers()
  local SYMBOL = "+"
  self:_UpdateHandlers(SYMBOL)
  self.m_SDKManager.hasRegisterHandlers = true
end

function SDKHelper:_RemoveHandlers()
  local SYMBOL = "-"
  self:_UpdateHandlers(SYMBOL)
end

function SDKHelper:_UpdateHandlers(SYMBOL)
  self.m_SDKManager:LuaOnPurchased(SYMBOL, self.m_funcPurchaseOnPurchasedCallback)
  self.m_SDKManager:LuaOnRestored(SYMBOL, self.m_funcOnRestoredCallback)
  self.m_SDKManager:LuaOnPurchaseUpdated(SYMBOL, self.m_funcPurchaseOnUpdatedCallback)
  self.m_SDKManager:LuaOnLogin(SYMBOL, self.m_funcOnLoginCallback)
  self.m_SDKManager:LuaOnAdClose(SYMBOL, self.m_funcOnAdCloseCallback)
  self.m_SDKManager:LuaOnAdEarned(SYMBOL, self.m_funcOnAdEarnedCallback)
  self.m_SDKManager:LuaOnMessageCountArrived(SYMBOL, self.m_funcOnAiHelpMessageCountArrivedCallback)
  self.m_SDKManager:LuaOnInstallReferrerReceived(SYMBOL, self.m_funcOnInstallReferrerReceivedCallback)
  if GLOBAL_APP then
    self.m_SDKManager:LuaOnDeepLinkReceived(SYMBOL, self.m_funcOnDeepLinkCallback)
  end
end

function SDKHelper:Purchase(strParam, funcCallback)
  self.m_funcPurchaseCallback = funcCallback
  
  local function func()
    self.m_purchaseClient:Purchase(strParam or "", tostring(GM.UserModel:GetUserId()))
  end
  
  SafeCall(func)
end

function SDKHelper:PurchaseInit(strParam)
  local function func()
    self.m_purchaseClient:Init(strParam or "")
  end
  
  SafeCall(func)
end

function SDKHelper:PurchaseRestore(restoreCallBack, isUserTriggered)
  self.m_funcRestoreCallback = restoreCallBack
  self.m_isUserTriggeredRestore = isUserTriggered
  
  local function func()
    self.m_purchaseClient:Restore()
  end
  
  SafeCall(func)
end

function SDKHelper:PurchaseFinish(strParam)
  local function func()
    self.m_purchaseClient:Finish(strParam)
  end
  
  SafeCall(func)
end

function SDKHelper:_RegisterCSharpHandlers()
  function self.m_funcPurchaseOnPurchasedCallback(client, PurchaseEventArgs)
    local logMsg = {
      "purchaseClient:OnPurchased",
      
      [[

PurchaseStatus = ]],
      PurchaseEventArgs.PurchaseStatus or "nil",
      [[

ProductId = ]],
      PurchaseEventArgs.ProductId or "nil",
      [[

Message = ]],
      PurchaseEventArgs.Message or "nil",
      [[

Data = ]],
      PurchaseEventArgs.Data or "nil",
      [[

Signature = ]],
      PurchaseEventArgs.Signature or "nil",
      [[

OrderId = ]],
      PurchaseEventArgs.OrderId or "nil"
    }
    Log.Info(table.concat(logMsg), LogTag.Purchase)
    if self.m_funcPurchaseCallback then
      if GameConfig.CURRENT_PLATFORM == Channels.GOOGLEPLAY:GetValue() and PurchaseEventArgs.PurchaseStatus == EPurchaseResultStatus.Success then
        local tbData = json.decode(PurchaseEventArgs.Data) or {}
        local purchaseToken = tbData.purchaseToken
        if not StringUtil.IsNilOrEmpty(purchaseToken) then
          if Table.Contain(self.m_purchaseTokens, purchaseToken) then
            GM.BIManager:LogAction(EBIType.IAPOrderUpdate, tbData)
            return
          end
          self.m_purchaseTokens[#self.m_purchaseTokens + 1] = purchaseToken
        end
      end
      self.m_funcPurchaseCallback(PurchaseEventArgs.PurchaseStatus, PurchaseEventArgs.ProductId or "", PurchaseEventArgs.Message or "", PurchaseEventArgs.Data or "", PurchaseEventArgs.Signature or "", PurchaseEventArgs.OrderId or "")
      self.m_funcPurchaseCallback = nil
    end
  end
  
  function self.m_funcOnRestoredCallback(client, PurchaseEventArgs)
    local logMsg = {
      "purchaseClient:OnRestored",
      [[

PurchaseStatus = ]],
      PurchaseEventArgs.PurchaseStatus or "nil",
      [[

ProductId = ]],
      PurchaseEventArgs.ProductId or "nil",
      [[

Message = ]],
      PurchaseEventArgs.Message or "nil",
      [[

Data = ]],
      PurchaseEventArgs.Data or "nil",
      [[

Signature = ]],
      PurchaseEventArgs.Signature or "nil",
      [[

OrderId = ]],
      PurchaseEventArgs.OrderId or "nil"
    }
    Log.Info(table.concat(logMsg), LogTag.Purchase)
    if self.m_funcRestoreCallback then
      self.m_funcRestoreCallback(PurchaseEventArgs.PurchaseStatus, PurchaseEventArgs.ProductId or "", PurchaseEventArgs.Message or "", PurchaseEventArgs.Data or "", PurchaseEventArgs.Signature or "", PurchaseEventArgs.OrderId or "", self.m_isUserTriggeredRestore or false)
      self.m_isUserTriggeredRestore = nil
    end
  end
  
  function self.m_funcPurchaseOnUpdatedCallback(client, MessageEventArgs)
    local logMsg = {
      "purchaseClient:OnUpdated",
      [[

Message = ]],
      MessageEventArgs.Message or "nil"
    }
    GM.InAppPurchaseModel:UpdateInAppPurchaseData(MessageEventArgs.Message or "")
  end
  
  function self.m_funcOnLoginCallback(manager, LoginEventArgs)
    local result = LoginEventArgs.Result
    local eSocialType = GM.AccountManager.eCurrentLoginSocialType
    if not eSocialType then
      return
    end
    if result and eSocialType and eSocialType == ESsoSocialType.Apple then
      self:AppleGenerateToken(LoginEventArgs)
    else
      self:LoginHandler(LoginEventArgs)
    end
  end
  
  function self.m_funcOnAdCloseCallback(manager, adCloseEventArgs)
    local logMsg = {
      "OnAdClose",
      [[

Reward = ]],
      adCloseEventArgs.Reward and "true" or "false",
      [[

Message = ]],
      adCloseEventArgs.Message or "nil"
    }
    Log.Info(table.concat(logMsg))
    if GameConfig.IsTestMode() and PlayerPrefs.GetInt(EPlayerPrefKey.TestDelayAdEnd, 0) == 1 then
      GM.UIManager:ShowPrompt("\232\167\166\229\143\145\229\185\191\229\145\138\230\136\144\229\138\159\229\155\158\232\176\131\229\187\182\230\151\182\230\137\167\232\161\140\239\188\14015\231\167\146\229\144\142\230\137\167\232\161\140")
      DelayExecuteFunc(function()
        GM.UIManager:ShowPrompt("\229\185\191\229\145\138\230\136\144\229\138\159\229\155\158\232\176\1315\231\167\146\229\144\142\230\137\167\232\161\140")
      end, 10, self)
      DelayExecuteFunc(function()
        GM.AdModel:OnAdEnd(adCloseEventArgs)
      end, 15, self)
    else
      GM.AdModel:OnAdEnd(adCloseEventArgs)
    end
  end
  
  function self.m_funcOnAdEarnedCallback(manager, adEarnedEventArgs)
    if GM == nil or not GM.GameModel:HasServerTime() then
      return
    end
    local logMsg = {
      "OnAdEarned",
      [[

Data = ]],
      adEarnedEventArgs.data
    }
    Log.Info(table.concat(logMsg))
    GM.AdModel:OnAdEarned(adEarnedEventArgs)
  end
  
  function self.m_funcOnAiHelpMessageCountArrivedCallback(manager, args)
    self.m_bHasUnreadCSMsg = args.Count > 0
    EventDispatcher.DispatchEvent(EEventType.RefreshSettingStrongTip)
  end
  
  function self.m_funcOnInstallReferrerReceivedCallback(manager, args)
    Log.Info("InstallReferrer Callback")
  end
  
  function self.m_funcOnDeepLinkCallback(manager, args)
    local logMsg = {
      "AppsFlyerManager OnDeepLinkCallback:",
      [[

deepLinkData = ]],
      args.deepLinkData or "nil"
    }
    Log.Info(table.concat(logMsg), LogTag.Default)
    if args == nil or args.deepLinkData == nil or args.deepLinkData == "null" then
      return
    end
    local data = args.deepLinkData
    GM.ShareLinkModel:SetShareLinkData(data)
  end
end

function SDKHelper:LoginHandler(loginEventArgs, refreshToken)
  local result = loginEventArgs.Result
  local socialID = loginEventArgs.UserId
  local authCode = loginEventArgs.AuthCode
  local accessToken = loginEventArgs.AccessToken
  local name = loginEventArgs.Name
  local email = loginEventArgs.Email
  local picture = loginEventArgs.Picture
  local rawResult = loginEventArgs.RawResult
  local log = loginEventArgs.Log
  local eSocialType = GM.AccountManager.eCurrentLoginSocialType
  if not eSocialType then
    return
  end
  local logMsg = {
    "SDKHelper:OnLoginCallback",
    [[

Result = ]],
    tostring(result) or "nil",
    [[

socialType = ]],
    eSocialType or "nil",
    [[

authCode = ]],
    authCode or "nil",
    [[

socialID = ]],
    socialID or "nil",
    [[

AccessToken = ]],
    accessToken or "nil",
    [[

Name = ]],
    name or "nil",
    [[

Email = ]],
    email or "nil",
    [[

Picture = ]],
    picture or "nil",
    [[

RawResult = ]],
    rawResult or "nil",
    [[

Log = ]],
    log or "nil"
  }
  Log.Info("logMsg:" .. table.concat(logMsg))
  GM.BIManager:LogSDKLogin(result, rawResult, log, eSocialType, accessToken, socialID, name, email, picture)
  local pictureUrl
  if not StringUtil.IsNilOrEmpty(socialID) and not StringUtil.IsNilOrEmpty(accessToken) then
    pictureUrl = "https://graph.facebook.com/" .. socialID .. "/picture?type=large&access_token=" .. accessToken
    Log.Info("[SDKHelper] \232\167\163\230\158\144\231\154\132url " .. pictureUrl)
  end
  GM.AccountManager:OnSDKLoginFinished(result, eSocialType, socialID, accessToken, name, email, pictureUrl, refreshToken, log)
end

function SDKHelper:AppleGenerateToken(loginEventArgs)
  local reqCtx = CSNetLibManager:CreateGeneralHttpRequest("https://appleid.apple.com/auth/token", "POST", 5000, 0)
  reqCtx:SetHeader("content-type", "application/x-www-form-urlencoded")
  local body = "client_id=com.mergegame.icookie"
  body = body .. "&client_secret=" .. self.m_appleClientSecret
  body = body .. "&code=" .. (loginEventArgs.AuthCode or "nil")
  body = body .. "&grant_type=authorization_code"
  Log.Info("[SDKHelper] Apple Auth requst body: " .. body)
  reqCtx:AppendBody(body)
  reqCtx:SetCallback(function()
    if GM ~= nil then
      local refreshToken
      if reqCtx.Rcode == ResultCode.Succeeded and reqCtx.RespBody.Bytes > 0 then
        local respBody = reqCtx:GetResponseString()
        Log.Info("Apple Auth Response: " .. respBody, LogTag.Purchase)
        local tokens = json.decode(respBody) or {}
        if tokens.refresh_token ~= nil then
          refreshToken = tokens.refresh_token
          PlayerPrefs.SetString(EPlayerPrefKey.AppleSignInRefreshToken, refreshToken)
        end
      else
        Log.Warning("[SDKHelper] Apple Auth response error: " .. (reqCtx.ErrorMsg or ""))
      end
      self:LoginHandler(loginEventArgs, refreshToken)
    end
  end)
  reqCtx:Send()
end

function SDKHelper:LogOut()
  self:_RevokeLoginTokens()
  if GLOBAL_APP then
    CSFacebookManager:Logout()
  end
  CSLoginClient:Logout()
end

function SDKHelper:_RevokeLoginTokens()
  self:_RevokeAppleToken()
end

function SDKHelper:_RevokeAppleToken()
  local appleToken = PlayerPrefs.GetString(EPlayerPrefKey.AppleSignInRefreshToken, "")
  if DeviceInfo.IsSystemIOS() and appleToken ~= "" then
    PlayerPrefs.SetString(EPlayerPrefKey.AppleSignInRefreshToken, "")
    local reqCtx = CSNetLibManager:CreateGeneralHttpRequest("https://appleid.apple.com/auth/revoke", "POST", 1000, 0)
    reqCtx:SetHeader("content-type", "application/x-www-form-urlencoded")
    local body = "client_id=com.mergegame.icookie"
    body = body .. "&client_secret=" .. self.m_appleClientSecret
    body = body .. "&token=" .. appleToken
    body = body .. "&token_type_hint=refresh_token"
    reqCtx:AppendBody(body)
    reqCtx:SetCallback(function()
      if GM ~= nil then
        if reqCtx.Rcode == ResultCode.Succeeded then
          Log.Info("Apple Auth Revoke Success.", LogTag.Purchase)
        else
          Log.Info("Apple Auth Revoke Failed.", LogTag.Purchase)
        end
      end
    end)
    Log.Info("[SDKHelper] Send Revoke Apple Auth Request.")
    reqCtx:Send()
  end
end

function SDKHelper:AiHelpUpdateUserInfoInScheduler()
  local bUpdateCompleted = self:AiHelpUpdateUserInfo()
  if bUpdateCompleted then
    Scheduler.Unschedule(self.AiHelpUpdateUserInfoInScheduler, self)
  end
end

function SDKHelper:AiHelpUpdateUserInfo()
  if GM == nil then
    return
  end
  if CSAiHelpManager.isInited then
    local userid = GM.UserModel:GetUserId()
    if userid == 0 then
      if self.m_updateInfoStep < EUpdateInfoStep.DeviceInfo then
        self.m_updateInfoStep = EUpdateInfoStep.DeviceInfo
        
        local function func()
          local tags = "channel_" .. tostring(GameConfig.CURRENT_PLATFORM)
          tags = tags .. ",version_" .. GameConfig.GetCurrentVersion()
          local installUUID = GM.UserModel:GetInstallUuid()
          local customData = {
            installUuid = installUUID,
            idfa = tostring(DeviceInfo.GetAdvertisingIdentifier()),
            wifiMAC = DeviceInfo.GetMacAddress(),
            adjust_id = "::" .. "",
            deviceId = DeviceInfo.GetDeviceID(),
            vendorId = DeviceInfo.GetVendorID(),
            openUDID = DeviceInfo.GetOpenUDID()
          }
          if GLOBAL_APP then
            customData.adjust_id = "::" .. tostring(CSAppsFlyerManager:GetAppsFlyerId())
          end
          CSAiHelpManager:UpdateUserInfo(tostring(installUUID), "Before SSO User", tags, json.encode(customData))
          Log.Info("AiHelp Update Device Info Finished!!!")
        end
        
        SafeCall(func)
      end
    elseif GM.GameModel:GetGroupName() == nil then
      if self.m_updateInfoStep < EUpdateInfoStep.UserInfo then
        self.m_updateInfoStep = EUpdateInfoStep.UserInfo
        
        local function func()
          local tags = "channel_" .. tostring(GameConfig.CURRENT_PLATFORM)
          tags = tags .. ",version_" .. GameConfig.GetCurrentVersion()
          local customData = {
            installUuid = GM.UserModel:GetInstallUuid(),
            uid = GM.UserModel:GetUserId(),
            level = GM.LevelModel:GetCurrentLevel(),
            gold = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Gold),
            gem = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Gem),
            exp = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Experience),
            energy = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy)
          }
          CSAiHelpManager:UpdateUserInfo(tostring(GM.UserModel:GetUserId()), tostring(GM.UserProfileModel:GetName(true)) .. "(Before Login)", tags, json.encode(customData))
          Log.Info("AiHelp Update User Info Finished!!!")
        end
        
        SafeCall(func)
      end
    else
      self.m_updateInfoStep = EUpdateInfoStep.GroupInfo
      
      local function func()
        local tags = "channel_" .. tostring(GameConfig.CURRENT_PLATFORM)
        tags = tags .. ",version_" .. GameConfig.GetCurrentVersion()
        if GM.GameModel:NeedChildProtection() then
          tags = tags .. "," .. GM.GameModel:GetChildProtectionState()
        end
        local customData = {
          installUuid = GM.UserModel:GetInstallUuid(),
          uid = GM.UserModel:GetUserId(),
          level = GM.LevelModel:GetCurrentLevel(),
          gold = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Gold),
          gem = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Gem),
          exp = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Experience),
          energy = GM.PropertyDataManager:GetPropertyNum(EPropertyType.Energy),
          group = GM.GameModel:GetGroupName(),
          group_all = GM.GameModel:GetAllGroupName()
        }
        CSAiHelpManager:UpdateUserInfo(tostring(GM.UserModel:GetUserId()), tostring(GM.UserProfileModel:GetName(true)), tags, json.encode(customData))
        Log.Info("AiHelp Update Group Info Finished!!!")
      end
      
      SafeCall(func)
      return true
    end
  end
  return false
end

function SDKHelper:OpenCustomerCenter(entryId)
  if GM == nil then
    return
  end
  if DeviceInfo.IsSystemIOS() and MINIGAME_WECHAT and GM and GM.InAppPurchaseModel then
    GM.InAppPurchaseModel:IncreaseXyxCheckTimes()
  end
  CSAiHelpManager:OpenCustomerCenter(entryId or "")
  EventDispatcher.DispatchEvent(EEventType.RefreshSettingStrongTip)
end

function SDKHelper:HasUnreadCSMsg()
  return self.m_bHasUnreadCSMsg
end

local function getSubMessageIds()
  if MINIGAME_DOUYIN then
    return {
      "MSG1587396137217280370789059168567",
      "MSG1587396137187278468517597514042",
      "MSG1587396137287278468517597497658"
    }
  end
  if MINIGAME_WECHAT then
    return {
      "kvyK4KYtZHolSsmkv37IfsPw2SS3_jUEXOYzAB2giTw",
      "9tfyNZwpWdL8UX183ZEmjhQw-HNWS68GUp4GbL56cVU",
      "zpdE2eosKKVkOfkwudUeMNU5yZurzn6qsPGwi_0cbOw"
    }
  end
end

local function getDyPlaySubscribeIds()
  if MINIGAME_DOUYIN then
    return {
      "CONTENT12559565570"
    }
  end
end

function SDKHelper:SubMessage()
  if getSubMessageIds() == nil then
    Log.Error("[SDKHelper]Wrong Subscription platform")
    return
  end
  XyxManager.Instance:SubMessage(getSubMessageIds(), function(code, message)
    Log.Info("SubMessage result: code=" .. tostring(code) .. ", message=" .. message)
  end)
end

function SDKHelper:GetUserInfo()
  if not MINIGAME then
    return
  end
  Log.Info("GetUserInfo start")
  XyxManager.Instance:GetUserInfo(function(code, data)
    Log.Info("GetUserInfo result: code=" .. tostring(code) .. ", data=" .. data)
    if code == 0 then
      local userInfo = json.decode(data) or {}
      local name = userInfo.nickName
      local icon = userInfo.avatarUrl
      if not StringUtil.IsNilOrEmpty(name) and not StringUtil.IsNilOrEmpty(icon) and StringUtil.IsNilOrEmpty(GM.AccountManager:GetMiniGameIcon()) then
        GM.AccountManager:SetAccountNameIcon(name, icon)
        Log.Info("GetUserInfo set name icon: name=" .. name .. ", icon=" .. icon)
        GM.AccountManager:SetMiniGameIcon(icon)
      end
    end
  end)
end

function SDKHelper:TryRequestFeedSubscribe()
  if not MINIGAME_DOUYIN then
    return
  end
  if GM.ConfigModel:IsServerControlOpen(EGeneralConfType.DisableDouYinFeed) then
    return
  end
  if GM.SDKHelper:IsDYNovelRead() then
    return
  end
  if not self.m_bRequestFeed then
    self.m_bRequestFeed = true
    local type = "play"
    local scene = 2
    GM.BIManager:LogNet(EBIType.NetworkCheckAction.DouyinFeed)
    XyxManager.Instance:CheckFeedSubscribeStatus(type, scene, function(code, message)
      local strInfo = "code=" .. tostring(code) .. ", message=" .. message
      Log.Info("CheckFeedSubscribeStatus result: " .. strInfo)
      GM.BIManager:LogNet(EBIType.NetworkCheckAction.DouyinFeed, strInfo)
      if code == 0 then
        message = json.decode(message)
        if message and message.status == false then
          if getDyPlaySubscribeIds() == nil then
            Log.Error("[SDKHelper]Wrong RequestFeedSubscribe")
            return
          end
          XyxManager.Instance:RequestFeedSubscribe(type, scene, getDyPlaySubscribeIds(), function(code, message)
            local strInfo = "code=" .. tostring(code) .. ", message=" .. message
            Log.Info("RequestFeedSubscribe result: " .. strInfo)
            GM.BIManager:LogNet(EBIType.NetworkCheckAction.DouyinFeed, strInfo)
          end)
        end
      end
    end)
  end
end

function SDKHelper:CheckFeedSubscribeStatus()
  local type = "play"
  local scene = 2
  XyxManager.Instance:CheckFeedSubscribeStatus(type, scene, function(code, message)
    Log.Info("CheckFeedSubscribeStatus result: code=" .. tostring(code) .. ", message=" .. message)
  end)
end

function SDKHelper:RequestFeedSubscribe()
  local type = "play"
  local scene = 2
  if getDyPlaySubscribeIds() == nil then
    Log.Error("[SDKHelper]Wrong RequestFeedSubscribe")
    return
  end
  XyxManager.Instance:RequestFeedSubscribe(type, scene, getDyPlaySubscribeIds(), function(code, message)
    Log.Info("RequestFeedSubscribe result: code=" .. tostring(code) .. ", message=" .. message)
  end)
end

function SDKHelper:_OnLevelUp()
  Log.Info("[SDKHelper] _OnLevelUp:")
  if MINIGAME_ALIPAY and GM.LevelModel:GetCurrentLevel() == 3 then
    CSPlatform:Attr_TrackEvent(AttrEventEnum.Ready21stPay, "")
  end
end

function SDKHelper:_OnOrderFinished(msg)
  Log.Info("[SDKHelper] _OnOrderFinished:" .. tostring(msg))
  self:_AlipayUploadAction("lmct_game_order_every_1", 1)
end

function SDKHelper:_OnItemMerged(msg)
  local EVERY_UPLOAD_COUNT = 5
  local UPLOAD_TOTAL_COUNT = 40
  local mergeDate = PlayerPrefs.GetString(EMiscKey.AlipayMergeDate, "")
  local currentData = TimeUtil.ToDate(GM.GameModel:GetServerTime(), ETimeFormat.YMD)
  Log.Info("[SDKHelper] _OnItemMerged:" .. ",mergeDate=" .. mergeDate .. ",currentData=" .. currentData)
  if mergeDate ~= currentData then
    PlayerPrefs.SetString(EMiscKey.AlipayMergeDate, currentData)
    PlayerPrefs.SetInt(EMiscKey.AlipayMergeCount, 0)
    self.m_itemMergedCount = 0
  end
  local count = PlayerPrefs.GetInt(EMiscKey.AlipayMergeCount, 0)
  if UPLOAD_TOTAL_COUNT <= count then
    Log.Info("Merge count > 40")
    return
  end
  if IsNil(self.m_itemMergedCount) then
    self.m_itemMergedCount = 1
    Log.Info("[SDKHelper] _OnItemMerged:self.m_itemMergedCount nil")
  else
    self.m_itemMergedCount = self.m_itemMergedCount + 1
  end
  Log.Info("[SDKHelper] _OnItemMerged:" .. tostring(self.m_itemMergedCount) .. ",: " .. tostring(msg))
  if EVERY_UPLOAD_COUNT <= self.m_itemMergedCount then
    self.m_itemMergedCount = 0
    count = count + 1
    PlayerPrefs.SetInt(EMiscKey.AlipayMergeCount, count)
  else
    return
  end
  self:_AlipayUploadAction("lmct_game_merge_every_5", 1)
end

function SDKHelper:_AlipayUploadAction(action_code, retryTime)
  Log.Info("[SDKHelper] _AlipayUploadAction:" .. tostring(action_code))
  if not MINIGAME_ALIPAY then
    Log.Info("[SDKHelper] _AlipayUploadAction:not minigame_alipay")
    return
  end
  local action_finish_date = TimeUtil.ToDate(TimeUtil.GetTimeInSecond(), ETimeFormat.YMDHMS)
  local open_id = DeviceInfo.GetOpenID()
  local action_finish_channel
  local info = XyxManager.Instance:GetLaunchInfo()
  local tbInfo = json.decode(info)
  if Table.IsEmpty(tbInfo) then
    action_finish_channel = "other"
  else
    local query = tbInfo.query
    if not Table.IsEmpty(query) then
      action_finish_channel = query.channel
    end
  end
  if StringUtil.IsNilOrEmpty(action_finish_channel) then
    action_finish_channel = "other"
  end
  Log.Info("[SDKHelper] _AlipayUploadAction: action_finish_date=" .. action_finish_date .. ", open_id=" .. open_id .. ", action_code=" .. action_code .. ", action_finish_channel=" .. action_finish_channel)
  local url = "https://xyx.cliapi.microfun.cn/zhifubao/uploadActionNew/"
  if GameConfig.IsTestMode() then
    url = "https://ctrl-test.china.corp.microfun.cn/zhifubao/uploadActionNew/"
  end
  url = url .. GameConfig.GetGameToken()
  Log.Info("[SDKHelper] _AlipayUploadAction: url=" .. url)
  local reqCtx = CSNetLibManager:CreateGeneralHttpRequest(url, "POST", 1000, 0)
  reqCtx:SetHeader("content-type", "application/x-www-form-urlencoded")
  local body = "action_finish_date=" .. action_finish_date
  body = body .. "&open_id=" .. open_id
  body = body .. "&action_code=" .. action_code
  body = body .. "&action_finish_channel=" .. action_finish_channel
  reqCtx:AppendBody(body)
  GM.BIManager:LogNet(EBIType.NetworkCheckAction.AlipayOrderFinishedRequestStart, body)
  reqCtx:SetCallback(function()
    if reqCtx.Rcode == ResultCode.Succeeded and reqCtx.RespBody.Bytes > 0 then
      local respBody = reqCtx:GetResponseString()
      Log.Info("[SDKHelper] al uploadAction Success: " .. respBody)
      GM.BIManager:LogNet(EBIType.NetworkCheckAction.AlipayOrderFinishedRequestSuccess, respBody)
      local resultData = json.decode(respBody) or {}
      local code = resultData.code
      Log.Info("[SDKHelper] al uploadAction code: " .. tostring(code))
      if code ~= "10000" and code ~= 10000 then
        self:_RetryAlipayUploadAction(action_code, retryTime)
      end
    else
      Log.Info("[SDKHelper] al uploadAction Failed:" .. tostring(reqCtx:GetResponseString()), LogTag.Default)
      self:_RetryAlipayUploadAction(action_code, retryTime)
    end
  end)
  Log.Info("[SDKHelper] al uploadAction Request.")
  reqCtx:Send()
end

function SDKHelper:_RetryAlipayUploadAction(action_code, retryTime)
  Log.Info("SDKHelper:_RetryAlipayUploadAction")
  if not MINIGAME_ALIPAY then
    Log.Info("SDKHelper:_RetryAlipayUploadAction:not MINIGAME_ALIPAY")
    return
  end
  if IsNil(self) then
    Log.Info("SDKHelper:_RetryAlipayUploadAction:self nil")
    return
  end
  if IsNil(retryTime) then
    Log.Info("retryTime nil")
    return
  end
  if 3 < retryTime then
    Log.Info("SDKHelper:_RetryAlipayUploadAction >3")
    return
  end
  retryTime = retryTime + 1
  DelayExecuteFunc(function()
    Log.Info("SDKHelper:_RetryAlipayUploadAction delay:" .. tostring(retryTime))
    self:_AlipayUploadAction(action_code, retryTime)
  end, 2 * retryTime, self)
end

function SDKHelper:RequestAddHomePage(callback)
  if not callback then
    return
  end
  local open_id = DeviceInfo.GetOpenID()
  local url = "https://xyx.cliapi.microfun.cn/zhifubao/addHomePageConsult/" .. GameConfig.GetGameToken()
  local reqCtx = CSNetLibManager:CreateGeneralHttpRequest(url, "POST", 1000, 0)
  reqCtx:SetHeader("content-type", "application/x-www-form-urlencoded")
  local body = "open_id=" .. open_id
  reqCtx:AppendBody(body)
  GM.BIManager:LogNet(EBIType.NetworkCheckAction.AlipaySetHomeRequestStart, body)
  reqCtx:SetCallback(function()
    if reqCtx.Rcode == ResultCode.Succeeded and reqCtx.RespBody.Bytes > 0 then
      local respBody = reqCtx:GetResponseString()
      local resultData = json.decode(respBody) or {}
      local code = tonumber(resultData.code)
      Log.Info("AddHome:" .. respBody)
      GM.BIManager:LogNet(EBIType.NetworkCheckAction.AlipaySetHomeRequestSuccess, respBody)
      if code == 10000 then
        local tbMsg = json.decode(resultData.msg) or {}
        callback(true, tbMsg.alipay_user_gamecenter_addhomepage_consult_response.consult_result)
      else
        callback(false)
      end
    else
      callback(false)
    end
  end)
  reqCtx:Send()
end

function SDKHelper:IsDYDirectPlay()
  if not MINIGAME_DOUYIN then
    return false
  end
  local launchInfo = XyxManager.Instance:GetLaunchInfo() or "{}"
  launchInfo = json.decode(launchInfo)
  if launchInfo then
    local scene = launchInfo.Scene
    if not StringUtil.IsNilOrEmpty(scene) and StringUtil.EndWith(scene, "3041") then
      local query = launchInfo.Query or {}
      if not Table.IsEmpty(query) and query.feed_game_channel == "2" then
        return true
      end
    end
  end
  return false
end

function SDKHelper:IsDYNovelRead()
  return XyxManager.Instance:GetHost() == "novelread"
end
