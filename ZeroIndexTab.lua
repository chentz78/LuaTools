--[[
Table version based on zero-based index tables and others features.
Author: Cleverton Hentz
]]

local Util = require("Util")

local ZITab = {}

local function index(t, i)
  --print(t, i, type(i))
  if type(i) == "number" then
    local iIdx = i+1
    return t.iTab[iIdx]
  else
    return rawget(t, i)
  end
end

local function newindex(t, i, v)
  --print(t, i, type(i))
  if type(i) == "number" then
    local iIdx = i+1
    t.iTab[iIdx] = v 
  else
    return rawset(t, i, v)
  end
end

local mt = {__index=index,__newindex=newindex}

local function modelInternal() return {iTab={}, id='ZITab'} end

function ZITab.new(t)
  local zt = setmetatable(modelInternal(), mt)
  if t then
    local idxT = Util.getOrderIndex(t)
    for i=1,#idxT do
      zt.iTab[#zt.iTab+1] = t[idxT[i]]
    end
  end
  return zt
end

function ZITab.copy(p, mIndex)
  return ZITab.new(Util.copy(p.iTab, mIndex))
end

function ZITab.tostring(p, idx)
  local ret = ""
  for i=1,#p.iTab do
    if i == 1 then
      if idx then ret = string.format("%s=%s", i , p.iTab[i])
      else ret = p.iTab[i] end
    else 
      if idx then ret = string.format("%s,%s=%s", ret, i , p.iTab[i])
      else ret = string.format("%s,%s", ret, p.iTab[i]) end
    end
  end
  return "["..ret.."]"
end

function ZITab.len(p)
  return #p.iTab
end

function ZITab.equal(a, b)
  --print("equal",#a,#b)
  if #a ~= #b then return false end
  if #a == 0 and #a == #b then return true end
  
  if a.id == 'ZITab' and b.id == 'ZITab' then
    if #a ~= #b then return false end
  elseif a.id == 'ZITab' then
    for i=1,#b do
      if a.iTab[i] ~= b[i] then return false end  
    end
  end
  
  return true
end

mt.__tostring = ZITab.tostring
mt.__len = ZITab.len
mt.__eq = ZITab.equal

return ZITab