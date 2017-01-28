local Set = require("Set")
local Rel = require("Relation")
local Util = require("Util")

--- Unpack compatibility with Lua 5.3 and 5.X
local unpack = unpack or table.unpack

local MetaInfo = {}

--- Table of operators constants 
MetaInfo.cOper = {
  term = "terminal",
  range = "range",
  emp = "empty",
  zm = "ZeroOrMore",
  neg = "negation",
  opt= "optional",
  om = "oneOrMore",
  oms = "oneOrMoreSep",
  seq = "seq",
  alt = "alt",
  nt = "non_terminal",
  idInc = "idInc"
}

local opIdentSet_Simple = Set.new{"terminal","non_terminal","empty"}

function MetaInfo.tostring(mi)
  if not mi then return nil end
  
  local ret = mi.opIdent.."(%s)"
  
  --print(opIdentSet_Simple)
  --print(opIdentSet_Simple:inSet(mi.opIdent))
  if opIdentSet_Simple:inSet(mi.opIdent) then
    if mi.params[1] == "" or not mi.params[1] then return string.format(ret, '')
    else return string.format(ret, '"'..mi.params[1]..'"') end
  elseif mi.opIdent == MetaInfo.cOper.range then
    --print("MetaInfo.tostring: mi.p1, mi.p2", Util.tostring(mi.params[1]), mi.params[2])
    assert(mi.params[1],"MetaInfo.tostring: Invalid range!")
    assert(mi.params[2],"MetaInfo.tostring: Invalid range!")
    return string.format(ret, '"'.. mi.params[1] ..'","'.. mi.params[2] ..'"')
  else
    local pStr = ""
    local sParams = #mi.params
    for k,v in ipairs(mi.params) do
      if not (type(v) == "table") then
        --print(v, type(v), ret)
        pStr = pStr .. '"'..tostring(v)..'"'
      else pStr = pStr .. v:tostring() end
      
      if k ~= sParams then pStr = pStr .. "," end
    end
    return string.format(ret, pStr)
  end
end

function MetaInfo.new(idx, opId, opFunc, ...)
  --print("metaInfo:", opId, opFunc, {...})
  --return opFunc --Turn off the meta-info
  if type(idx) == "string" then error("MetaInfo: Invalid idx value!") end
  
  local retTab = {index=idx,opIdent=opId,opPatt=opFunc,params={...}}
  
  retTab = setmetatable(retTab,{
      __index=MetaInfo,
      __call = function (f, ...)
        return f.opPatt(...)
      end
    })
  return retTab
end

function MetaInfo.visitor(pattIdent, func, ntProd, patt, ...)
  local addParams = {...}
  local fRec = function(k,p)
    --print("fRec1:", p)
    if type(p) == "table" then
      --print("fRec2:", p, p.opIdent)
      return MetaInfo.visitor(pattIdent, func, ntProd, p, unpack(addParams))
    else return false, p end
  end
  
  --print("visitor",ntProd, pattIdent, patt, patt.opIdent)
  
  if not patt.opIdent then
    print("error:", dbg:tostring(patt))
    --dbg:echo(patt.params)
    error(string.format("Invalid opIdent: %s", ntProd))
  end
  
  if string.find(patt.opIdent, pattIdent) then
    return func(ntProd, patt, ...)
  elseif patt.opIdent == MetaInfo.cOper.term or
         patt.opIdent == MetaInfo.cOper.idInc or
         patt.opIdent == MetaInfo.cOper.emp or 
         patt.opIdent == MetaInfo.cOper.nt or
         patt.opIdent == MetaInfo.cOper.range then
    return false, patt
  else
    local lRet, lParams = Util.any(patt.params, fRec)
    if lRet then
      return lRet, MetaInfo.new(patt.index, patt.opIdent, patt.opPatt, unpack(lParams))
    else
      return false, patt
    end
  end
end

function MetaInfo.mapEachRule(g, f, tSort)
  if not g or not f then error("MetaInfo.mapEachRule: Invalid arguments.") end
  
  local fun = function(key,value)
    --print("MetaInfo.mapEachRule",key,g.startSymbol)
    if key == "startSymbol" then
      --print("MetaInfo.mapEachRule",key,"1")
      return value
    end
    --print("MetaInfo.mapEachRule",key,"2")
    
    if value.opIdent == MetaInfo.cOper.alt then
      local sVal
      for i=1,#value.params do
        value.params[i] = f(key, value.params[i])
      end
      return value
    else    
      return f(key, value)
    end
  end
  return Util.map(g, fun, tSort)
end

function MetaInfo.extractNTxTerms(g, gSort)
  local rRel = Rel.new()
  local eachRuleFun = function(nt, patt)
    --Detect the terminals
    local f = function(n,p)
      rRel(nt, p.params[1])
      return false, p
    end
    
    MetaInfo.visitor('^'..MetaInfo.cOper.term, f, nt, patt)
    
    return patt
  end
  
  MetaInfo.mapEachRule(g, eachRuleFun, gSort)
  return rRel
end

function MetaInfo.extractStructures(g, prefix, gSort, upIndex, IgnoreOps)
  local rPId = Rel.new()
  local rSym = Rel.new()
  local prodInc = Util.incGen(1)
  local sTerm = Set.new{}
  
  --First, index the rules
  local eachRuleFun = function(nt, patt)
    local idx = prodInc()
    --print(nt,idx)
    patt.index = idx
    if prefix then idx = prefix..idx end
      
    rPId(nt,idx)
    return patt
  end
  
  local retG = MetaInfo.mapEachRule(g, eachRuleFun, gSort)
  --print("Index grammar result", Util.hashCode(retG))
  
  local ExcNT, newG = nil, retG
  if IgnoreOps and #IgnoreOps > 0 then
    --print("extractStructures:IgnoreOps")
    local sOps = Set.new(IgnoreOps)
    ExcNT = Set.new{}
    local f = function (ntProd, patt)
      --print("IgnoreOps:", patt.opIdent, "On "..ntProd)
      MetaInfo.visitor(MetaInfo.cOper.nt, function(a1,b1) ExcNT:include(b1.params[1]); return true, b1 end, ntProd, patt)
      
      local p = terminal("<"..patt.opIdent..">", true)
      p.index = patt.index
      return true, p
    end
    
    eachRuleFun = function(nt, patt)
      local vRet, vResult
      local lastPatt = patt
      for op in pairs(sOps) do
        --print("Applying", op,"in",nt)
        vRet, vResult = MetaInfo.visitor(op, f, nt, lastPatt)
        if vRet then lastPatt = vResult end
      end
      
      return lastPatt
    end
  
    newG = MetaInfo.mapEachRule(Util.copy(retG), eachRuleFun, gSort)
    --print("Remove Ops grammar result", Util.hashCode(newG))
  end
  
  --Thrid, generate rules
  eachRuleFun = function(nt, patt)
      --print(nt, patt:tostring())
      local cPId
      if prefix then cPId = prefix..patt.index
      else cPId = patt.index end
      
      
      local f = function(n, p)
        rSym(cPId, p.params[1])
        return false, p
      end
      
      local vRet, vResult = MetaInfo.visitor(MetaInfo.cOper.nt, f, nt, patt)
      
      --Detect the terminals
      f = function(n,p)
        --print(n, p.params[1])
        sTerm:include(p.params[1])
        return false, p
      end
      
      MetaInfo.visitor('^'..MetaInfo.cOper.term, f, nt, patt)
      
      return patt
  end
  
  MetaInfo.mapEachRule(newG, eachRuleFun, gSort)
  --print(rSym:card(), Util.tostring(rSym))
  return retG, rPId, rSym, ExcNT, sTerm
end

function MetaInfo.getMaxOfMinSymbol(Prods, MinRel)
  local ret = {}
  
  for k,s in Prods:getSetIteration() do
    --print("MetaInfo.getMaxOfMinSymbol", k,s)
    local m = MinRel:max(s)
    --print("MetaInfo.getMaxOfMinSymbol", k,m)
    ret[k] = m
  end
  
  if not next(ret) then return nil end
  return ret
end

function MetaInfo.getMinSymbolTable(g)
  local ret = {}
  local eachProd = function(ntProd, patt)
    local min
    if patt.opIdent == MetaInfo.cOper.alt then
      local s = Set.new{}
      for i,v in ipairs(patt.params) do
        if not v.MinTreeHeight then return nil end
        s:include(v.MinTreeHeight)
      end
      min = s:min()
    else
      min = patt.MinTreeHeight
    end
    
    if not min then return nil end
    
    ret[ntProd] = min
  end
  
  Util.map(g, eachProd)
  if not next(ret) then return nil end
  
  return ret
end

local function getMinSym(nt,rm,p)
  --print("getMinSym1", nt, rm)
  local rSet = p%nt
  if not rSet then error("getMinSym:Invalid notermianl "..nt) end
  
  local mRel = rm:filterOverRelation(pairs, function(k,v) return rSet:inSet(k) end)
  --print("getMinSym3",mRel)
  if (not mRel) or
     mRel:card() == 0 then return nil end
  
  local r
  --[[
  if rSet:card() > mRel:card() then
    r = rSet - mRel:domain() 
    print("getMinSym4",r)
  end
  ]]
  r = (mRel:range()):min()
  
  --print("getMinSym5",r)
  return r
end

local function reduceRel(PIds, Rules, RulesMin)
  local currRel = Rules
  local rTmp
  local inc = Util.incGen()
  while true do
    inc()
    --print("reduceRel", "point1", inc(true), Util.hashCode(currRel))
    rTmp = currRel:filterOverRelation(Rel.getSetIterationSort, function(k,s)
      --print(k,s)
      if s:card() == 1 then
        local i = getMinSym(s:first(), RulesMin, PIds)
        --print("Case 1", i)
        if i then
          --print("Case 1-Add", i)
          RulesMin(k,i+1)
        end
        return not i
      end
      
      --print("Case 2")
      local i
      local maxI = -1
      for elem in pairs(s) do
        i = getMinSym(elem, RulesMin, PIds)
        if not i then return true end
        
        if maxI < i then maxI = i end
      end
      
      RulesMin(k,maxI+1)
      return false
    end, true)
    
    --print("reduceRel", "point2", inc(true), Util.hashCode(rTmp))
    if (rTmp:card() == 0) or (currRel == rTmp) then
      --print("break")
      break
    else
      currRel = rTmp
    end  
  end
  --print("reduceRel", inc(true)-1)
  return rTmp
end

function MetaInfo.calcMinTreeHeightRules(rPId, rSym)
  --print("MetaInfo.calcMinTreeHeightRules")
  local rEndRules = rPId:range() - rSym:domain()
  rEndRules = rPId:filterOverRelation(pairs, function(k,v) return rEndRules:inSet(v) end)
  --print("MetaInfo.calcMinTreeHeightRules", "rEndRules", Util.hashCode(rEndRules:tostring()))
  
  local rRuleMinHeight = Rel.new()
  --Rules with height 1
  for k,v in pairs(rEndRules) do
    rRuleMinHeight(v,1)
  end
  --print("MetaInfo.calcMinTreeHeightRules", "rRuleMinHeight:1", Util.hashCode(rRuleMinHeight:tostring()))
  
  rTmp = reduceRel(rPId, rSym, rRuleMinHeight)
  --print("MetaInfo.calcMinTreeHeightRules", "rRuleMinHeight:2", Util.hashCode(rRuleMinHeight:tostring()), rTmp)
  if (rTmp:range() - rRuleMinHeight:domain()):card() > 0 then return nil, rTmp
  else return rRuleMinHeight end
end

return MetaInfo