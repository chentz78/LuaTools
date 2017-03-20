--- A relation implementation.
-- @author Cleverton Hentz
--
-- Dependencies: `Set`, `Queue`, `dbg`, `Util`
-- @module Relation

local Relation = {}

local Debug = require("dbg")
dbg = Debug:new()

local Set = require("Set")
local Queue = require("Queue")
local Util = require("Util")

--dbg.tableOpen = to
--dbg.tableClose = tc
--dbg.tableSep = ts
--dbg.itemOpen = ''
--dbg.itemClose = ''
--dbg.keyOpen = ''
--dbg.keyClose = ''

local function modelInternal() return {relSet={},count=0,id='Relation'} end

local function isARelation(obj)
  return (type(obj) == 'table' and obj.id and obj.id == 'Relation')
end

local function intNextSetKeySort(rel)
  local lKSort = Util.getOrderIndex(rel.relSet)
  --print("intNextSetKeySort", Util.tostring(lKSort))
  local lIdx = Util.incGen(1)
  return function (r, key)
    local k = lKSort[lIdx(true)]
    local val = r.relSet[k]
    lIdx()
    --print("intNextSetKeySort:f", key, k, val)
    return k, val
  end
end

local function internalNext(rel, iterSet)
  --print("internalnext")
  if iterSet then
    return function (r, key) return next(r.relSet, key) end
  end
  
  local coWrp = function(set)
    return coroutine.create(function()
      for e in pairs(set) do
        coroutine.yield(e)
      end
    end)
  end
  local nKey, nSet = next(rel.relSet, nil)
  nSet = coWrp(nSet)
  return function(r, key)
    --print("internalnext, internal", rel, key)
    local cKey, cVal = coroutine.resume(nSet)
    if not cVal or 
      coroutine.status(nSet) == "dead" then
      nKey, nSet = next(rel.relSet, nKey)
      if not nKey then return nil end
      nSet = coWrp(nSet)
      cKey, cVal = coroutine.resume(nSet)
    end
    cKey = nKey
    
    return cKey, cVal
  end
end

local mt = {__index=Relation,
--- iterate over a relation without an order.
-- @within metamethods
-- @function Relation.__pairs
-- @see Relation.getSetIterationSort
            __pairs=function(t)
              return internalNext(t), t, nil
            end,
            
--- Include a element in the relation.
-- @within metamethods
-- @function Relation.__call
-- @see Relation.include
            __call=function (f, ...)
              --local args = {...}
              --if #args > 0 then
                return Relation.include(f, ...)
              --else
              --  return Relation.tostring(f)
              --end
            end,

--- Could be union or transitive closure, depends on the second operand.
-- @within metamethods
-- @function Relation.__add
-- @see Relation.union
-- @see Relation.transitiveClosure
            __add=function (op1,op2)
              --print("__add:", op1, op2, type(op2))
              if isARelation(op1) then
                if isARelation(op2) then
                  return op1:union(op2)
                elseif type(op2) == 'number' then
                  return op1:transitiveClosure(op2)
                end
              end
            end
}

local function cloneRel(r)
  return Util.copy(r)
end

local function internalAdd(rel, key, val, isSetBasedValue)
  if not key then return false end
  
  local valKSet = rel.relSet[key]
  --print("internalAdd:",rel, key, val, isSetBasedValue, valKSet)
  local c = rel.count
  if isSetBasedValue then
    if valKSet then
      c = c-valKSet:card()
      valKSet = valKSet + val
      c = c+valKSet:card()
      rel.relSet[key] = valKSet
    else
      rel.relSet[key] = Set.new(val)
      c = c + val:card()
    end
  else
    if valKSet then
      local a,b = valKSet:include(val)
      if b then c = c+1 end
    else 
      rel.relSet[key] = Set.new{val}
      c = c+1
    end
  end
  rel.count = c
  return true
end

local function intResetStorage(rel)
  rel.count = 0
  rel.relSet = {}
  return true
end

local function internalAddTable(rel, tab, isSetBasedTab)
  --print("internalAddTable", rel, tab);
  if (not tab) or (tab and (#tab[1] ~= #tab[2])) then return false end
  if rel:card() > 0 then return false end
  
  local k,v
  rel.count = 0
  for i=1,#tab[1] do
    k,v = tab[1][i], tab[2][i]
    if not internalAdd(rel, k, v, isSetBasedTab) then
      intResetStorage(rel)
      return false
    end
  end
  return true
end

function Relation.intRepresentation(rel)
  return rel.relSet
end

--- create a new relation.
function Relation.new(r, isSetBasedTab)
  if not r then return setmetatable(modelInternal(), mt)
  elseif not r.id then -- Normal table
    local nr = setmetatable(modelInternal(), mt)
    if internalAddTable(nr, r, isSetBasedTab) then return nr
    else return nil end
  elseif r.id ~= 'Relation' then return nil end
  
  return cloneRel(r)
end

--- cardinality of the relation.
function Relation.card(rel)
  return rel.count
end

--- include an element on the relation.
function Relation.include(rel, key, val, isSetBasedValue)
  --print("Relation.include", rel, key, val)
  
  local r = internalAdd(rel, key, val, isSetBasedValue)
  return rel, r
end

local function domRel(rel, filter)
  local s = {}
  for k,v in pairs(rel.relSet) do
    if (not filter) or (filter and filter(k)) then
      s[#s+1] = k
    end
  end
  return Set.new(s)
end

--- return the domain of the relation
function Relation.domain(rel)
  return domRel(rel)
end

local function rangeRel(rel, filter)
  local s = Set.new{}
  for k,v in pairs(rel.relSet) do
    for vs,_ in pairs(v:internalSet()) do
      if (not filter) or (filter and filter(vs)) then
        s:include(vs)
      end
    end
  end
  
  return s
end

--- return the range of the relation.
function Relation.range(rel)
  return rangeRel(rel)
end

--- compare if two relatio are equals.
function Relation.equal(r1, r2)
  --print("Relation.equal", r1, r2)
  --Shortcuts
  --print("Relation.equal", "ID")
  if not(r1 and r2) or not(isARelation(r1) and isARelation(r2)) then return false end
  --print("Relation.equal", "relSet")
  if r1.relSet == r2.relSet then return true end
  --print("Relation.equal", "count")
  if r1.count ~= r2.count then return false end
  --print("Relation.equal", "domain")
  if r1:domain() ~= r2:domain() then return false end
  --print("Relation.equal", "range")
  if r1:range() ~= r2:range() then return false end
  
  --print("Relation.equal", "compare elements")
  --compare elements
  local vSetr2
  for k,v in pairs(r1.relSet) do
    vSetr2 = r2.relSet[k]
    --print("Relation.equal", k, v, vSetr2)
    if (not vSetr2) or (v ~= vSetr2) then return false end
  end
  --print("Relation.equal", "true")
  return true
end

--- return only the elements with the key.
function Relation.subscript(rel, key)
  --print("Relation.subscript", key)
  local s
  if type(key) == 'table' and key.id and key.id == 'Set' then
    --print("Relation.subscript", "1")
    if key:card() == 0 then return nil end
    
    s = Set.new{}
    local v
    for k in pairs(key) do
      v = rel.relSet[k]
      if v then
        s = s + v
      end
    end
    
    if s:card() == 0 then s = nil end
  else
    if not rel.relSet[key] then return nil end
    s = Set.new(rel.relSet[key])
  end
  return s 
end

--- union over the relations.
function Relation.union(r1, r2)
  if not(isARelation(r1) and isARelation(r2)) then return nil end
  
  local domU = r1:domain() + r2:domain()
  if domU:card() == 0 then return Relation.new() end
  
  local cr = {{},{}}
  
  local vs1, vs2
  for k,_ in pairs(domU:internalSet()) do
    vs1 = r1.relSet[k]
    vs2 = r2.relSet[k]
    idx = #cr[1]+1
    cr[1][idx] = k
    if vs1 and vs2 then cr[2][idx] = vs1 + vs2
    elseif vs1 then cr[2][idx] = Set.new(vs1)
    elseif vs2 then cr[2][idx] = Set.new(vs2) end
  end
  
  return Relation.new(cr, true)
end

--- composite the relation `r1` with `r2`
function Relation.composition(r1, r2)
  --print("Relation.composition:", r1, r2)
  if not(isARelation(r1) and isARelation(r2)) then return nil end
  
  local interR = r1:range() * r2:domain()
  if interR:card() == 0 then return nil end
  
  --print("Relation.composition:", "intersec r1 and r2", interR)
  
  local cr = {{},{}}
  local iValr2,idx,tS1
  
  for k1,vs1 in pairs(r1.relSet) do
    tS1 = vs1 * interR
    --print("i1:", k1, tS1)
    if tS1:card() > 0 then
      idx = #cr[1]+1
      cr[1][idx] = k1
      cr[2][idx] = Set.new{}
      for v,_ in pairs(tS1:internalSet()) do
        iValr2 = r2.relSet[v]
        --print("i2:",k1, iValr2)
        if iValr2 then cr[2][idx] = cr[2][idx] + Set.new(iValr2) end
      end
    end
  end
  
  --print("Relation.composition:", dbg:tostring(cr))
  return Relation.new(cr, true)
end

--- relation power.
function Relation.power(rel, idx)
  --print("Relation.power", rel, idx)
  local baseR = Relation.new(rel)
  if idx == 1 then return baseR, 1 end
  
  local tmpR
  for i=2,idx do
    --print("Relation.power", i)
    tmpR = rel:composition(baseR)
    --print("Relation.power", i, tmpR)
    if (not tmpR) or (tmpR:equal(baseR)) then return baseR, i-1 end
    
    baseR = tmpR
  end
  
  return baseR, idx
end

--- transitive closure over the relation.
function Relation.transitiveClosure(rel, idx)
  --print("Relation.transitiveClosure", rel, idx)
  local baseR = Relation.new(rel)
  idx = idx or 0
  
  if idx == 1 then return baseR, 1 end
  
  local maxTimes
  if idx < 1 then --Max traditional Transitive closure
    maxTimes = 1000
  else
    maxTimes = idx
  end
  --print("Relation.transitiveClosure", maxTimes)
  local tmpR
  local powerR, pMax
  for i=2,maxTimes do
    --print("Relation.transitiveClosure", i)
    powerR, pMax = rel:power(i)
    --print("Relation.transitiveClosure", i, pMax)
    if pMax < i then return baseR, i-1 end
    
    tmpR = baseR:union(powerR)
    if tmpR:equal(baseR) then return baseR, i-1 end
    
    baseR = tmpR
  end
  
  return baseR, maxTimes
end

--- invert the domain and range on the relation
function Relation.invert(rel)
  if not isARelation(rel) then return nil end
  
  local r = Relation.new()
  for k,v in pairs(rel) do
    internalAdd(r,v,k,false)
  end
  return r
end

--- check if the relation is a function.
function Relation.isFunction(rel)
  if (not rel) or (rel:card() ==0) then return nil end
  
  for k,v in pairs(rel.relSet) do
    if v:card() > 1 then return false end
  end
  return true
end

--- check if the relation has cycles
function Relation.hasDirectCycles(rel, filter)
  if (not rel) or (rel:card() ==0) then return nil end
  
  local r = false
  for k,v in pairs(rel) do
    if k == v then
      r = true
      if not filter then return r
      elseif not filter(k,v) then return r end
    end
  end
  return r
end

function Relation.configToString(to, tc, ts)
  dbg.tableOpen = to
  dbg.tableClose = tc
  dbg.tableSep = ts
end

--- convert the relation into a string.
function Relation.tostring(rel)
  local comp = function (a,b)
    return string.lower(a) < string.lower(b) 
  end
  
  local l = {}
  for k,v in pairs(rel) do
    if type(k) == "string" then k = "'" .. k .. "'" end
    if type(v) == "string" then v = "'" .. v .. "'" end
    l[#l + 1] = string.format("<%s,%s>",k,v)
  end
  table.sort(l, comp)
  if #l > 0 then
    return string.format("{%s}", table.concat(l,"; "))
  else
    return "{empty}"
  end
end

--- get a set-based iterator
function Relation.getSetIteration(rel)
  return internalNext(rel, true), rel, nil
end

--- get a set-based sorted iterator
function Relation.getSetIterationSort(rel)
  return intNextSetKeySort(rel), rel, nil
end

--- get an element-based iterator
function Relation.getElemIteration(rel)
  return internalNext(rel, false), rel, nil
end

--- filter over the relation
function Relation.filterOverRelation(rel, iter, filter, isSetBased)
  --print("Relation.filterOverRelation", rel, iter, filter, isSetBased)
  if not (filter or iter) then return nil end
  
  local ret = Relation.new()
  
  for k,v in iter(rel) do
    if filter(k,v) then internalAdd(ret, k,v,isSetBased) end
    --print(k,v)
  end
  
  return ret
end

--- get the first element
function Relation.first(rel, key)
  if key then
    local r = (rel%key)
    if not r then return nil end
    
    return r:first()
  end
  
  local k,s = internalNext(rel, true)(rel)
  return k, s:first()
end

function Relation.max(rel, key)
  if key then
    local r = (rel%key)
    if not r then return nil end
    
    return r:max()
  end
  
  local m = rel:domain():max()
  return m, (rel%m):max()
end

function Relation.min(rel, key)
  if key then
    local r = (rel%key)
    if not r then return nil end
    
    return r:min()
  end
  
  local m = rel:domain():min()
  return m, (rel%m):min()
end

--- Breadth first search over the relation.
-- Do a breadth first search from `root` over the relation.
-- [Source](http://en.wikipedia.org/wiki/Breadth-first_search)
-- @param rel Relation
-- @param root The root node to the search.
-- @param funItem Function executed over the elements. It has the signature `funItem(elem, topIndex)`.
-- @param retRevPath Save the sequence nodes.
-- @return return the path if `retRevPath` is true.
-- @usage rel:BFS("nRoot", function(elem, topIndex)
--   print(elem, topIndex)
--   return true
-- end)
function Relation.BFS(rel, root, funItem, retRevPath)
  if not (rel and root and funItem) then error("Relation.BFS: Invalid params!") end
  retRevPath = retRevPath or false
  local vertexs = rel:domain()+rel:range()
  local q = Queue.new()
  
  local revPath
  if retRevPath then
    revPath = Relation.new()
  else
    revPath = true
  end
  
  local vDist = {}
  local inf = -1
  
  --Initialization
  for v in pairs(vertexs) do
    if v == root then vDist[v] = 0 
    else vDist[v] = inf end
  end
  --print("Relation.BFS: point 1",q:empty())
  q:enqueue(root)
  --print("Relation.BFS: point 2", q:empty())
  
  local t,u,aE
  local ret = false
  while not q:empty() do
    t = q:dequeue()
    if not funItem(t,vDist[t]) then
      ret = true
      break
    end
    
    aE = rel%t
    if aE then
      for u in aE:getSortIterator() do
        if vDist[u] == inf then
          vDist[u] = vDist[t]+1
          --print("Relation.BFS:",u,t)
          if retRevPath then revPath(u,t) end
          q:enqueue(u)
        end
      end
    end
  end
  --print("Relation.BFS:",revPath)
  if ret then
    return revPath
  else
    return nil
  end
end

--[[
This function should be moved to other module because it's graph related.
From http://www.eecs.wsu.edu/~ananth/CptS223/Lectures/shortestpath.pdf
]]
function Relation.shortestPath(rel, a, b)
  local vertexs = rel:domain() + rel:range()
  --print("Relation.shortestPath", a,b, vertexs)
  --print("Relation.shortestPath",vertexs:inSet(a))
  if not vertexs:inSet(a) or
    (b and not vertexs:inSet(b)) then return nil end
  
  if b then
    --print("Relation.shortestPath: has b")
    local s = rel%a
    if s:inSet(b) then return 1 end
    
    local lastIdx
    local ret = rel:BFS(a, function (elem, index)
      lastIdx = index
      local r = elem ~= b
      --print(elem,r,index)
      return r
    end, true)
  
    if ret then
      return lastIdx, Util.tabInvert(ret:getAleatoryPath(b))
    else return nil end
  else
    --print("Relation.shortestPath: hasn't b")
    local rIndex = Relation.new()
    rel:BFS(a, function (elem, index)
      rIndex(elem,index)
      return true
    end)
  
    return rIndex
  end
end

--- return an aleatory path from `a`. 
function Relation.getAleatoryPath(rel, a)
  --print("Relation.getAleatoryPath",rel,a)
  local curr = a
  local ret = {}
  while curr do
    ret[#ret+1] = curr
    curr = rel%curr
    if not curr then break end
    curr = curr:first()
  end
  return ret
end

--- clone the relation `obj`.
function Relation.clone(obj)
  return cloneRel(obj)
end

--- check if the `obj` is a relation.
function Relation.isARelation(obj)
  return isARelation(obj)
end

--- check if it is empty
function Relation.isEmpty(obj)
  return obj:card() == 0
end

--[[
function Relation.card2(rel)
  local i = 0
  for k,v in pairs(rel) do
    i = i +1
  end
  return i
end
]]

--- equality of relations.
-- @within metamethods
-- @function Relation.__eq
-- @see Relation.equal
mt.__eq  = Relation.equal

--- convert a relation to string.
-- @within metamethods
-- @function Relation.__tostring
-- @see Relation.tostring
mt.__tostring = Relation.tostring

--- Relation composition.
-- @within metamethods
-- @function Relation.__concat
-- @see Relation.composition
mt.__concat = Relation.composition

--- Relation power.
-- @within metamethods
-- @function Relation.__pow
-- @see Relation.power
mt.__pow = Relation.power

--- Relation subscript.
-- @within metamethods
-- @function Relation.__mod
-- @see Relation.subscript
mt.__mod = Relation.subscript

--[[
__add = Relation.union, if a and b are Relations
__add = Relation.transitiveClosure, if a is Relation and b is number
]]

return Relation