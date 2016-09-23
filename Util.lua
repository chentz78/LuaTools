local SHA = require("sha2")

local Util = {}

-- [[==Table related functions ==]]

function Util.emptyTable(t)
  if next(t) then return false end
  return true
end

function Util.sizeTable(t, index)
  if index then return #t end
  
  local i = 0
  for k,v in pairs(t) do
    i = i+1
  end
  return i
end

function Util.map(tab, func, idxSort)
  if not (tab and func) then error(string.format("map: Invalid arguments! %s - %s",tab, func)) end
  --print("Util.map")
  local ret = {}
  --local t = Util.copy(tab)
  local t = tab
  if idxSort then
    local v
    for i,k in ipairs(idxSort) do
      v = t[k]
      --print("sort",i,k,v)
      if not v then error("map: Invalid key from idxSort! Key '"..k.."' not found.") end
      ret[k] = func(k,v)
    end
  else
    for k,v in pairs(t) do
      ret[k] = func(k,v)
    end
  end
  
  return ret
end

function Util.any(tab, func)
  if not (tab or func) then error("Util.any: Invalid arguments!",tab, func) end
  
  local lAny = false
  local lfSts,lfRet
  local lRList = {}
  
  for k,v in pairs(tab) do
    --print(k,v)
    lfSts, lfRet = func(k,v)
    if lfSts then lRList[k] = lfRet
    else lRList[k] = v end
    
    if not lAny and lfSts then lAny = true end
  end
  
  return lAny, lRList
end

function Util.getOrderIndex(tab)
  local r = {}
  for k,_ in pairs(tab) do
    r[#r+1] = k
  end
  table.sort(r)
  return r
end

function Util.getOrderValue(tab)
  local vals = {}
  local sortVal = {}
  local ret = {}
  for k,v in pairs(tab) do
    vals[v] = k
    sortVal[#sortVal+1] = v
  end
  
  table.sort(sortVal)
  
  for i,v in ipairs(sortVal) do
    ret[#ret+1] = vals[v]
  end
  
  return ret
end

function Util.tabInvert(tab)
  if (not #tab) or #tab == 0 then return nil end
  
  local r = {}
  for i=#tab,1,-1 do
    r[#r+1] = tab[i]
  end
  return r
end

function Util.tableGen(num,pre,pos)
  local ret = {}
  local e
  --print(num)
  for i=1,num do
    if not pre and not pos then e = i
    elseif not pos then e = string.format("%s%s", pre, i) --pre
    elseif not pre then e = string.format("%s%s", i, pos) --pos
    else e = string.format("%s%s%s", pre, i, pos) end
    ret[#ret+1] = e 
  end
  
  return ret
end

function Util.tableFilter(tab,fCond, shortStop)
  if not (tab and fCond) then error("Util.tableFilter: Invalid parameters!"); end
  
  shortStop = Util.defVal(shortStop, true)
  local ret = {}
  local fI = Util.incGen(1)
  local add,nK,nV
  
  for k,v in pairs(tab) do
    add, nK, nV = fCond(k,v, fI())
    if shortStop and (not add) then return ret
    else
      if add then
        if not nK then ret[k] = v
        else ret[nK] = nV end
      end
    end
  end
  
  return ret
end

-- [[== End of table related functions ==]]


function Util.copy(object,maxIdx)
  if type(object) ~= "table" then
    return object
	else
	  local t = {}
	  local mt = getmetatable(object)
	  local mp,mn = nil, nil
	  if mt then
	    mp = mt.__pairs
	    mn = mt.__next
	    mt.__pairs = nil
	    mt.__next = nil
	  end
	  
	  for _i, v in pairs(object) do
	    if not maxIdx or
	       _i <= maxIdx then
		    t[Util.copy(_i)] = Util.copy(v)
		  end
		end
		if mt then
		  mt.__pairs = mp
		  mt.__next = mn
		end
		return setmetatable(t, mt)
	end
end

function Util.incGen(initSeed)
  local seed = initSeed or 0
  return function (ro)
    if ro then return seed end
    local r = seed
    seed = seed+1
    return r
  end
end

local function tostringTableLine(d, prevStr, sep, k, v)
  local rsl
  if d.keyOpen then
    rsl =  string.format("%s%s%s%s%s%s", prevStr, sep, d.keyOpen, Util.tostring(k,d), d.keyClose, d.tableEquals)
  else
    rsl =  string.format("%s%s", prevStr, sep)
  end
  
	return string.format("%s%s%s%s", rsl, d.itemOpen, Util.tostring(v,d), d.itemClose)
end

function Util.tostring(obj, d)
  local identStr = nil
  if type(d) ~= "table" then
    --print(type(d))
    if type(d) == "string" then identStr = d end
    
    d = {userdataOpen='[', userdataSepClose=']', userdataSep=': ',
      tableOpen='{', tableClose='}', tableSep=', ', tableEquals='=',
			keyOpen='[', keyClose=']', itemOpen='"', itemClose='"'
    }
  end
  
	local mtT, tname, o
	if type(obj) == 'userdata' then
		mtT = getmetatable(obj)
		o = d.userdataOpen
		if mtT and mtT.__index then
			tname = mtT.__index.__typename
			if tname then
				o = o .. tname
			end
		end
		if obj.name then
			if tname and tname == 'WClientWin' then
				o = o .. d.userdataSep .. d:tostring(obj:get_ident())
			else
				o = o .. d.userdataSep .. obj:name()
			end
		end
		return o .. d.userdataClose
	elseif type(obj) == 'table' then
		mtT = getmetatable(obj)
		if mtT and mtT.__tostring then
		  o = mtT.__tostring(obj)
		else
		  o = d.tableOpen
		  sep = ''
		  local idx = Util.getOrderIndex(obj)
		  local v
		  for _,k in ipairs(idx) do
		    v = obj[k]
		    o = tostringTableLine(d, o, sep, k, v)
			  sep = d.tableSep
		  end
		  --[[
		  for k, v in pairs(obj) do
		    o = tostringTableLine(d, o, sep, k, v)
			  sep = d.tableSep
		  end
		  ]]
		  if identStr then o = identStr .. o .. d.tableClose
		  else o = o .. d.tableClose end
		end
		return o
	end
	return tostring(obj)
end

function Util.hashCode(object)
  if type(object) ~= "table" then
    return SHA.hash224(tostring(object))
	else
    return SHA.hash224(Util.tostring(object))
  end
end

function Util.round(v)
  local a, b = math.modf(v)
  if b >= 0.5 then a = a + 1 end 
  return a
end

function Util.percShow(a,b)
  return ((a/b)-1)*100
end

function Util.readContent(fname, func)
  local file = io.open(fname, "r")
  local cnt = nil
  local fI = Util.incGen(0)
  local i
  while true do
    cnt = file:read()
    i = fI()
    if (not cnt) or (not func(cnt,i+1)) then
      break
    end
  end
  file:close()
  return i
end

function Util.splitString(str, sep)
  local ret = {}
  for v in string.gmatch(str, "([^"..sep.."]+)") do
    ret[#ret+1] = v
  end
  
  if #ret > 0 then return ret end
  return nil
end

function Util.truncString(str, cBegin, cEnd, ldots)
  local len = str:len()
  local sep = ldots or '...'
  if cBegin and cEnd then
    if (cBegin+cEnd+sep:len()) >= len then return str end
    
    local strB = str:sub(1,cBegin)
    local strE = str:sub(-cEnd)
    return string.format("%s%s%s", strB, sep, strE)
  end
end

function Util.fileExists(fName)
  if not fName then return false end
  
  local f = io.open(fName,"r")
  if f then
    io.close(f)
    return true
  else
    return false
  end
end

function Util.fact(n)
  if n > 170 then error("Util.fact: Reach the number data type limit.") end
  
  if n < 0 then return 0 end
  if n == 0 then return 1 end
  if n <= 2 then return n end
  
  return n * Util.fact(n-1)
end

function Util.iif(cond, cTrue, cFalse, expVal)
 local rCond, rExpVal, rTrue, rFalse
 if type(cond) == "function" then rCond = cond() else rCond = cond end
 if type(expVal) == "function" then rExpVal = expVal() else rExpVal = expVal end
 if type(cTrue) == "function" then rTrue = cTrue() else rTrue = cTrue end
 if type(cFalse) == "function" then rFalse = cFalse() else rFalse = cFalse end
 
 if (rExpVal and cond == rExpVal) or
    (not rExpVal and cond) then
   return rTrue
 else
   return rFalse
 end
end

function Util.defVal(chkVal, defVal, expVal)
  return Util.iif(chkVal==expVal, defVal, chkVal)
end

return Util