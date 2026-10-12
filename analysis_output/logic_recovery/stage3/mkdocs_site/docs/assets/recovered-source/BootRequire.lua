CHINA_APP = CHINA_APP
CHINA_IOS = CHINA_IOS
MINIGAME = MINIGAME
MINIGAME_WECHAT = MINIGAME_WECHAT
MINIGAME_DOUYIN = MINIGAME_DOUYIN
MINIGAME_ALIPAY = MINIGAME_ALIPAY
GLOBAL_APP = GLOBAL_APP
local formerRequire = require

local function requireErrorHandler(msg)
  Log.Error("[xpcall]require failed:" .. (msg or "nil") .. "\n" .. debug.traceback())
end

function require(path)
  local replacedRequirePath = path
  if GM and GM.ConfigModel then
    replacedRequirePath = GM.ConfigModel:GetReplacesFilePath(path, ".")
  end
  local result, ret = xpcall(formerRequire, requireErrorHandler, replacedRequirePath)
  if result then
    return ret
  else
    return formerRequire(path)
  end
end

package.path = package.path .. ";" .. "Assets/DynamicConfig/?.lua"
require("MainInclude")
math.randomseed(os.time())

function LuaUpdate(dt)
  if not GM then
    return
  end
  if GM.destroying and (not GameConfig.IsTestMode() or not GM.TestModel.testDelayRestart) then
    return
  end
  GM:Update(dt)
  Scheduler.Update(dt)
end

function LuaUpdatePerSecond()
  if not GM or GM.destroying then
    return
  end
  GM:UpdatePerSecond()
end

function LuaLateUpdate()
  if GM.destroying then
    return
  end
  GM:LateUpdate()
end

function LuaOnApplicationFocus(bHasFocus)
  GM:ApplicationFocusChanged(bHasFocus)
  if UNITY_EDITOR and (not GameConfig.IsTestMode() or PlayerPrefs.GetInt(EPlayerPrefKey.TestIgnoreOnFocusReLogin, 0) ~= 1) then
    LuaOnApplicationPause(not bHasFocus)
  end
end

function LuaOnApplicationPause(bPaused)
  if bPaused then
    GM:ApplicationDidEnterBackground()
  else
    GM:ApplicationWillEnterForeground()
  end
end

function LuaDestroy()
  GM:Destroy()
  GM = nil
  EventDispatcher.Clear()
  Scheduler.Clear()
end

function LuaOnResolutionChanged()
  if GM and GM.UIManager then
    GM.UIManager:OnResolutionChanged()
  end
  EventDispatcher.DispatchEvent(EEventType.ResolutionChanged)
end

function CreateLuaComponentByName(gameObject, typename)
  if not _ENV[typename] then
    return nil
  end
  local newComponent = setmetatable({}, _ENV[typename])
  newComponent.gameObject = gameObject
  newComponent.transform = gameObject.transform
  return newComponent
end

function Awake()
  GM = GlobalManager.Create()
  MicrofunLogger:Log("lua - GM init")
  GM:Init()
  if GLOBAL_APP then
    CSFirebaseManager:CrashlyticsSetKeyValue("version", GameConfig.GetCurrentVersion())
    CSFirebaseManager:CrashlyticsSetKeyValue("mode", GameConfig.IsTestMode() and "test" or "prod")
    CSFirebaseManager:SetUserProperty("idfa", DeviceInfo.GetAdvertisingIdentifier())
  end
  Log.Info("LuaManager:minigame:" .. tostring(MINIGAME) .. " global_app:" .. tostring(GLOBAL_APP) .. " china_app:" .. tostring(CHINA_APP) .. " minigame_alipay:" .. tostring(MINIGAME_ALIPAY) .. " minigame_douyin:" .. tostring(MINIGAME_DOUYIN) .. " minigame_wechat:" .. tostring(MINIGAME_WECHAT))
end

function OnBack()
  if GM.EditHud and GM.EditHud.Show then
    GM.EditHud:OnBack()
    return
  end
  if GM.UIManager then
    GM.UIManager:OnBack()
  end
end

function OnAppQuit()
  print("[Lua] Quiting application...")
  Log.Info("[Lua] Quiting application...")
  return 1101
end
