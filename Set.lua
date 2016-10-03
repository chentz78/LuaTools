local Set = {}

local Debug = require("dbg")
dbg = Debug:new()

local Util = require("Util")

local function internalNext(set, key)
  local k,v = next(set.s, key)
  return k
end

local function intNextSort(set)
  local lKSort = Util.getOrderIndex(set.s)
  local lIdx = Util.incGen(1)
  return function (r, key)
    local k = lKSort[lIdx(true)]
    local val = r.s[k]
    lIdx()
    return k
  end
end

local mt = {__index=Set,
            __pairs=function(t)
              return internalNext, t, nil
            end}

local function modelInternal() return {s={}, count=0,id='Set'} end

local function isASet(obj)
  return (type(obj) == 'table' and obj.id and obj.id == 'Set')
end

local function clone(s)
  return Util.copy(s)
end

local function internalAdd(set, elem)
  if not set.id or (set.id and set.id ~= 'Set') then return false end
  
  if set.s[elem] then return false end
  
  set.s[elem] = true
  set.count = set.count+1
  return true
end

local function internalAddTab(set, tab)
  if type(tab) ~= 'table' then return false end
  
  for _, v in ipairs(tab) do
    internalAdd(set, v)
  end
  return true
end

function Set.new(l)
  --print("Set.new:", l)
  local set = setmetatable(modelInternal(), mt)
  if l then
    if type(l) == "table" and not l.id then
      --print("Set.new:", "table")
      internalAddTab(set, l)
    elseif type(l) == 'table' and l.id == 'Set' then
      --print("Set.new:", "clone")
      set = clone(l)
    elseif l then
      --print("Set.new:", "item")
      internalAdd(set, l)
    end
  end
  return set
end

function Set.union(a,b)
  local res = Set.new{}
  local i = a.count
  for k in pairs(a.s) do res.s[k] = true end
  for k in pairs(b.s) do
    res.s[k] = true
    if not a.s[k] then i = i+1 end
  end
  res.count = i
  return res
end

function Set.intersection(a,b)
  local res = Set.new{}
  local i = 0
  for k in pairs(a.s) do
    res.s[k] = b.s[k]
    if res.s[k] then i = i+1 end
  end
  res.count = i
  return res
end

function Set.diff(a,b)
  if not (a and b) then error("Set.diff:Invalid arguments!") end
  
  local res = Set.new{}
  local i = 0
  for k in pairs(a.s) do
    if not b.s[k] then res.s[k] = true; i = i+1  end
  end
  res.count = i
  return res
end

function Set.inSet(set, e)
  return set.s[e]
end

--[[
function Set.card(set)
  local count=0
  for k in pairs(set) do
    count = count + 1
  end
  return count
end
]]

function Set.card(set)
  return set.count
end

function Set.product(a, b)
  local res = Set.new{}
  local s
  for k in pairs(a.s) do
    for j in pairs(b.s) do
      s = {k,j}
      res.s[s] = true
    end
  end
  res.count = a.count * b.count
  return res
end

function Set.equality(a, b)
  if a.s == b.s then return true end
  local cA, cB = Set.card(a),Set.card(b)
  if cA ~= cB then return false end
  
  for e in pairs(a.s) do
    if not b.s[e] then
      return false
    end
  end
  
  for e in pairs(b.s) do
    if not a.s[e] then
      return false
    end
  end
  return true
end

function Set.table(set)
  local res = {}
  for e in pairs(set.s) do res[#res + 1] = e end
  return res
end

function Set.include(set, e)
  --print("Set.include:", set, e)
  if not set.s[e] then
    set.s[e] = true
    set.count = set.count+1
    return set, true
  end
  
  return set, false
end

function Set.exclude(set, e)
  if empty and set.s == empty.s then
    return set
  end
  
  if set.s[e] then
    set.s[e] = nil
    set.count = set.count-1
  end
  return set
end

function Set.configToString(to, tc, ts)
  dbg.tableOpen = to
  dbg.tableClose = tc
  dbg.tableSep = ts
  dbg.itemOpen = '"'
  dbg.itemClose = '"'
  dbg.keyOpen = '['
  dbg.keyClose = ']'
end

function Set.tostring(set)
  local comp = function (a,b)
    return string.lower(a) < string.lower(b) 
  end
  local l = {}
  for e in pairs(set) do l[#l + 1] = dbg:tostring(e) end
  table.sort(l, comp)
  if #l > 0 then
    return string.format("{'%s'}", table.concat(l,"','"))
  else
    return "{empty}"
  end
end

function Set.first(set)
  return internalNext(set, nil)
end

function Set.max(set)
  local r = set:first()
  for k in pairs(set) do
    if k > r then
      r = k
    end
  end
  return r
end

function Set.min(set)
  local r = set:first()
  for k in pairs(set) do
    if k < r then
      r = k
    end
  end
  return r
end

function Set.internalSet(set)
  return set.s
end

function Set.getSortIterator(set)
  return intNextSort(set), set, nil
end

function Set.isASet(obj)
  return isASet(obj)
end

mt.__add = Set.union
mt.__sub = Set.diff
mt.__eq  = Set.equality
mt.__mul = Set.intersection
mt.__tostring = Set.tostring
--mt.__len = Set.card --> Bug in version Lua 5.2.3

return Set
