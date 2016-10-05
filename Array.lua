--- Realy simple array implementation.
-- Simple example
--    local Array = require("Array")
--    local ar = Array.new{1,2,3,4}
--    print(ar) 

local Array = {}

local Debug = require("dbg")
dbg = Debug:new()

local mt = {}

function Array.new(l)
  local arr = {}
  
	setmetatable(arr, mt)
	if l then	
	  if type(l) == "table" then    
      for i, v in ipairs(l) do arr[i] = v end
    elseif l then
      arr[1] = l
    end
  end
  
	return arr
end

function Array.concat(a,b)
  local res = Array.new{}
	for i, k in ipairs(a) do res[i] = k end
	for i, k in ipairs(b) do
	  res[#res+1] = k
	end
	return res
end

function Array.configToString(to, tc, ts)
  dbg.tableOpen = to
	dbg.tableClose = tc
	dbg.tableSep = ts
	dbg.itemOpen = '"'
	dbg.itemClose = '"'
	dbg.keyOpen = '['
	dbg.keyClose = ']'
end

function Array.tostring(arr)
  local rsl = dbg.tableOpen
	local sep = ''
  for i, v in ipairs(arr) do
	  rsl = dbg:tostringTableLine(rsl, sep, i, v)
	  --print(dbg.keyOpen,"-",rsl)
		sep = dbg.tableSep
	end
	return rsl .. dbg.tableClose
end

function Array.print(s)
  print(Array.tostring(s))
end

mt.__add = Array.concat
--mt.__mul = Array.product
--mt.__sub = Array.diff
mt.__tostring = Array.tostring

return Array
