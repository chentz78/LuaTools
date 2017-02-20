--- A set implementation.
-- Basic Set usage
--    local s1, s2, s3 = Set.new{"A"}, Set.new("A"), Set.new("A")
--    print(s1:card())
--    ==> 1
--    print(s2:card())
--    ==> 1
--    print(#s1 == #s2) -- Working on Lua 5.2 and above
--    ==> true
--    print(s1 == s2) --Equality
--    ==> true
--    print(s1 ~= s2)
--    ==> false
--    print(s2 == s1) --Comutativity
--    ==> true
--    print(s1==s2 and s2==s3 and s1==s3) --Transitivity
--    ==> true
--    print(s1 + s2)
--    ==> {"A"}
--    print(s1 + Set.new{"A","B"})
--    ==> {"A"}
-- 
-- Iterate over a set
--    local s = Set.New{'A','B','C'}
--    --Unsorted iterator
--    for e in pairs(s) do
--      print(e)
--    end
--    
--    --Sorted iterator
--    for e in s:getSortIterator() do
--      print(e)
--    end
--
-- @author Cleverton Hentz
--
-- Dependencies: `dbg`, `Util`
-- @module Set

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
--- iterate over a set without an order.
-- @within metamethods
-- @function Set.__pairs
-- @see Set.getSortIterator
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

--- Create a new Set object.
-- It create a new set object based on the parameter.
-- @param l Source data. Could be nil, table or another Set
-- @return a new set
-- @usage local emptyS = Set.New()
-- @usage local s1 = Set.New{1,2,3,4,4}
--local s1Clone = Set.New(s1)

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

--- union of sets.
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

--- intersection of sets.
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

--- difference of sets.
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

--- Set membership.
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

--- set cardinality
function Set.card(set)
  return set.count
end

--- product of sets
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

--- equality between sets
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

--- Convert the set to i-based table
function Set.table(set)
  local res = {}
  for e in pairs(set.s) do res[#res + 1] = e end
  return res
end

--- Element inclusion
-- @param set The set
-- @param e The element
-- @return The reference to the set
-- @return `true` if `e` was included and `false` otherwise.
function Set.include(set, e)
  --print("Set.include:", set, e)
  if not set.s[e] then
    set.s[e] = true
    set.count = set.count+1
    return set, true
  end
  
  return set, false
end

--- Element exclusion
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

--- Convert a set to string
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

--- get the first set element
function Set.first(set)
  return internalNext(set, nil)
end

--- get the highest element in the set
function Set.max(set)
  local r = set:first()
  for k in pairs(set) do
    if k > r then
      r = k
    end
  end
  return r
end

--- get the lowest element in the set
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

--- get a sorted iterator
function Set.getSortIterator(set)
  return intNextSort(set), set, nil
end

--- Check if an object is a set
function Set.isASet(obj)
  return isASet(obj)
end

--- union of sets.
-- @within metamethods
-- @function Set.__add
-- @see Set.union
mt.__add = Set.union

--- difference of sets.
-- @within metamethods
-- @function Set.__sub
-- @see Set.diff
mt.__sub = Set.diff

--- equality of sets.
-- @within metamethods
-- @function Set.__eq
-- @see Set.equality
mt.__eq  = Set.equality

--- intersection of sets.
-- @within metamethods
-- @function Set.__mul
-- @see Set.intersection
mt.__mul = Set.intersection

--- convert a set to string.
-- @within metamethods
-- @function Set.__tostring
-- @see Set.tostring
mt.__tostring = Set.tostring

--- add a element to the set.
-- @within metamethods
-- @function Set.__call
-- @see Set.include
mt.__call = Set.include

--- card of the set.
-- Only work with Lua 5.3+.
-- @within metamethods
-- @function Set.__len
-- @see Set.card
mt.__len = Set.card --> Bug in version Lua 5.2.3

return Set
