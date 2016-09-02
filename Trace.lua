require ("init")

local Debug = require("dbg")

local Trace = {}

function Trace:new(n)
  local t = {}
	
  setmetatable(t, self)
  self.__index = self
	
	t.Name = n
  return t
end

local function logTrace(self, phase, msg)
  local lev = Debug.Level or LEVEL.ERROR
	if lev.Cod >= LEVEL.TRACE.Cod then
	  local sRet = string.format("%s(%s):%s", phase, self.Name, msg)
    print(sRet)
	end
end

function Trace:beginTrace(...)
  logTrace(self, "Begin", Debug.tostring({...}))
end

function Trace:body(id, msg, ...)
  local args,msgArgs = {...},""
	
	if #args ~= 0 then
	  msgArgs = Debug.tostring(args)
	end
	
  logTrace(self, "Body", string.format("id=%s %s:%s", id, msg, msgArgs))
end

function Trace:endTrace(...)
  logTrace(self, "End", Debug.tostring({...}))
end

return Trace
