LEVEL = {
	ERROR = {Cod=1,Name="Error"},
	TRACE = {Cod=5,Name="Trace"}
}
local Util = require("Util")
local dbg = {}

function dbg.new(d)
  local debugT = {Enabled=false,
             userdataOpen='[', userdataSepClose=']', userdataSep=': ',
             tableOpen='{', tableClose='}', tableSep=', ', tableEquals='=',
						 keyOpen='[', keyClose=']', itemOpen='"', itemClose='"',
             Level=LEVEL.ERROR}
	setmetatable(debugT, d)
	d.__index = d
	return debugT 
end

function dbg.print(d, ...)
  if d.Enabled then
	  print(...)
	end
end

function dbg.echo(d, s)
	d:echon(s)
	d:echon('\n')
end

function dbg.echon(d, s)
	io.stderr:write(d:tostring(s))
end

function dbg.tostringTableLine(d, prevStr, sep, k, v)
  local rsl =  string.format("%s%s%s%s%s%s", prevStr, sep, d.keyOpen, d:tostring(k), d.keyClose, d.tableEquals)
	return string.format("%s%s%s%s", rsl, d.itemOpen, d:tostring(v), d.itemClose)
end

function dbg.tostring(d, obj)
	return Util.tostring(obj, d)
end

return dbg
