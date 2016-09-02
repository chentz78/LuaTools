local TimeMachine = {}

local Util = require("Util")
local Debug = require("dbg")
dbg = Debug:new()
dbg.Enabled = false

local mt = {}

function TimeMachine.new(self, l)
  local tm = {context={}, save={}}
  setmetatable(tm, self)
  self.__index = self
  if l then
    local copyL = Util.copy(l)
    for _i, v in pairs(copyL) do
      tm.context[_i] = v
    end
  end
  return tm
end

function TimeMachine.current(tm)
  local proxy = {}
  setmetatable(proxy, proxy)
  proxy.__index = function(t, k) return tm.context[k] end
  proxy.__newindex = function(t, k, v) return rawset(tm.context, k, v) end
  return proxy
end

function TimeMachine.savePoint(tm, label)
  label = label or "DEFAULT"
  tm.save[label] = Util.copy(tm.context)
end

function TimeMachine.rollBack(tm, label, notRemove)
  label = label or "DEFAULT"
  local sv = tm.save[label]
  if not sv then
    return false
  end
  
  tm.context = Util.copy(sv)
  if not notRemove and label ~= "DEFAULT" then
    tm.save[label] = nil
  end
  return true
end

return TimeMachine
