PairEvent = {}
PairEvent.__index = PairEvent

function handler(obj, method, gameObject, name)
  gameObject = gameObject or obj.gameObject
  if name == nil then
    name = gameObject and gameObject.name or ""
  end
  return function(...)
    if gameObject and gameObject:IsNull() then
      Log.Warning("pair event view has been destroyed, object name " .. name)
      return
    end
    method(obj, ...)
  end
end

function PairEvent.Create(source)
  local newEvent = setmetatable({}, PairEvent)
  newEvent._source = source
  newEvent._handlers = {}
  return newEvent
end

function PairEvent:AddHandler(evt, handler)
  local handlers = self._handlers[evt]
  if handlers == nil then
    handlers = {}
    self._handlers[evt] = handlers
  end
  handlers[#handlers + 1] = handler
end

function PairEvent:RemoveHandler(evt, handler)
  local handlers = self._handlers[evt]
  if handlers then
    for i, v in ipairs(handlers) do
      if v == handler then
        table.remove(handlers, i)
        return
      end
    end
  end
end

function PairEvent:Call(evt, message)
  local handlers = self._handlers[evt]
  if handlers then
    for i = 1, #handlers do
      handlers[i](message)
    end
  end
end

function AddHandlerAndRecordMap(pairEvent, evt, handlerArgs)
  if pairEvent == nil or evt == nil or handlerArgs == nil or handlerArgs.obj == nil or handlerArgs.method == nil then
    return
  end
  local handler = handler(handlerArgs.obj, handlerArgs.method, handlerArgs.gameObject, handlerArgs.name)
  pairEvent:AddHandler(evt, handler)
  handlerArgs.obj.m_mapPairEventHandlers = handlerArgs.obj.m_mapPairEventHandlers or {}
  handlerArgs.obj.m_mapPairEventHandlers[evt] = handler
end

function RemoveAllHandlers(pairEvent, handlerObj)
  if pairEvent == nil or handlerObj == nil or handlerObj.m_mapPairEventHandlers == nil then
    return
  end
  for event, handler in pairs(handlerObj.m_mapPairEventHandlers) do
    pairEvent:RemoveHandler(event, handler)
  end
  handlerObj.m_mapPairEventHandlers = nil
end
