--[[
--Ref https://msdn.microsoft.com/en-us/library/aa289166%28VS.71%29.aspx
Extracted from jcombinatorics (https://github.com/aisrael/jcombinatorics/blob/master/src/main/java/jcombinatorics/combinations/CombinadicCombinationsGenerator.java)
*  With the license:
*  Java Combinatorics Library
* 
*  Copyright (c) 2009 by Alistair A. Israel.
 
*  See LICENSE.txt.
*
* Created Sep 2, 2009
* - By Cleverton Hentz 2015
]]

local Combinatorics = {}

local tabD = {userdataOpen='[', userdataSepClose=']', userdataSep=': ',
  tableOpen='[', tableClose=']', tableSep=', ', tableEquals='=',
	keyOpen=nil, keyClose='', itemOpen='', itemClose=''
}

local Set = require("Set")
local Util = require("Util")
local zTab = require("ZeroIndexTab")

local BN = require("openssl").bn
local DG = require("openssl").digest

local mt = {__index=Combinatorics}

local function modelInternal() return {elems={}, count=0,id='Combinatorics'} end

--Use of BIGNUM from OpenSSL
function Combinatorics.Fact(n)
  if n < 0 then return BN.number(0) end
  if n == 0 then return BN.number(1) end
  if n <= 2 then return BN.number(n) end
  
  return n * Combinatorics.Fact(n-1)
end

local LMI = BN.number(math.maxinteger or math.pow(10,10))

function Combinatorics.printBigNumber(n)
  if type(n) == "number" or n < LMI then return string.format("%s",n)
  else
    local len = BN.tostring(n):len()-5
    local nDiv = BN.pow(10,len)
    --print(n,BN.bits(n), len)
    --print(nDiv)
    return string.format("%s+e%i",BN.tonumber(BN.div(n,nDiv)), len)
  end
end

local fact = Combinatorics.Fact

function Combinatorics.new(num)
  local p = setmetatable(modelInternal(), mt)
  p.elems = Util.tableGen(num,"p")
  --print(Util.tostring(p.elems))
  p.count = #p.elems
  return p
end

function Combinatorics.tostring(p)
  local l = {}
  for k,e in pairs(p.elems) do l[#l + 1] = Util.tostring(e) end
  table.sort(l)
  if #l > 0 then
    return string.format("[%s]", table.concat(l,","))
  else
    return "[]"
  end
end

function Combinatorics.nPk(n, k)
  if n == 0 and k == n then return 0 end --function is not defined for these values
  
  if (0 <= k and k <= n) then
    return BN.tonumber(fact(BN.number(n)) / fact(BN.number(n-k)))
  end
  
  return 0
end

local function swap(a, x, y)
  --print("swap:Begin", x, y, a)
  local sa = #a
  if (x >= sa or y >= sa) then error(string.format("Swap Error: x:%i, y:%i, size(a):%i.",x,y,sa)) end
  
  --[[
  local t = a[x]
  a[x] = a[y]
  a[y] = t
  ]]
  local ret = a
  ret[x],ret[y] = a[y],a[x] --Lua code
  --print("swap:End", x, y, ret)
  return ret
end

local function reverseRightOf(a, iStart, n)
  --print("reverseRightOf:Begin", iStart, n, a)
  local i,j = iStart+1, n-1
  
  local ret = a
  while (i<j) do
    ret = swap(ret, i,j)
    i = i+1
    j = j-1
  end
  --print("reverseRightOf:End", iStart, n, ret)
  return ret
end

--Compute next set that will be returned.
local function computeNext(a, n, k)
  local i,j = k-1, k
  --print("computeNext:Begin",i,j, a)
  local ret = a
  while (j < n and ret[i] >= ret[j] ) do
    j = j + 1
  end
  
  --print("computeNext:1:",i,j,ret)
  if (j < n) then
    ret = swap(ret, i, j)
  else
    ret = reverseRightOf(ret, i, n)
    i = i - 1
    while (i >= 0 and ret[i] >= ret[i+1]) do
      i = i-1
    end
    
    if i < 0 then return nil end
    
    j = j-1
    while (j > i and ret[i] >= ret[j]) do
      j = j-1
    end
    ret = swap(ret, i, j)
    ret = reverseRightOf(ret, i, n)
  end
  --print("computeNext:End", ret)
  return ret
end

function Combinatorics.SepaPnkGen(n, k)
  if (n < 1) then error("SepaPnkGen: N have to be at least 1!") end
  if (k > n) then error(string.format("SepaPnkGen: Invalid configuration for n:%i and k:%i!", n, k)) end
  
  local a = zTab.new(Util.tableGen(n))
  return function()
    if not a then return nil
    else    
      local ret = zTab.copy(a,k)
      a = computeNext(a,n,k)
      return ret
    end
  end, zTab.copy(a,k)
end

--Combinations
-- Naive Implementation of Binomial Coefficient - http://mathworld.wolfram.com/BinomialCoefficient.html
local function fInternalBinCoeffFact(n,k)
  --print("fInternalBinCoeffFact:",n,k)
  if n < k then return 0
  elseif n == k then return 1
  elseif k == 1 then return n
  else --return Util.round(fact(n) / (fact(k) * fact(n-k)))
    
    --t = os.clock()
    --bFact = fact(n) / (fact(k) * fact(n-k))
    a = fact(n)
    --print("fInternalBinCoeffFact:a",a)
    b = (fact(k) * fact(n-k))
    --print("fInternalBinCoeffFact:b",b)
    c,r = BN.divmod(a, b)
    retC = BN.tostring(c)
    --print("fInternalBinCoeffFact:c len",string.len(retC))
    --print("fInternalBinCoeffFact:c",c)
    --print("fInternalBinCoeffFact:r",r)
    return c
    --print("fInternalBinCoeffFact:",os.clock()-t)
    --Util.round(
    --retC = BN.tonumber(c)
    --[[
    retC = BN.tostring(c)
    print("fInternalBinCoeffFact:c len",string.len(retC))
    print("fInternalBinCoeffFact:",math.maxinteger)
    --if retC > BN.number(math.maxinteger) then
    if string.len(retC) > 90 then
      error("fInternalBinCoeffFact: Invalid range! retC: "..retC)
    end
    retC = tonumber(retC..".0")
    print("fInternalBinCoeffFact:c", BN.tostring(c))
    print("fInternalBinCoeffFact:retC", retC , string.format("%d",retC))
    --print("fInternalBinCoeffFact:c4", string.format("%.0f",tonumber(BN.tostring(c))) )
    return retC
    ]]
  end
end

local function fInternalBinCoeffRecur(n,k)
  if n < k then return 0
  elseif n == k or k == 0 then return 1 end
  --print("fInternalBinCoeffRecur:", n,k)
  return fInternalBinCoeffRecur(n-1,k-1) + fInternalBinCoeffRecur(n-1,k)
end

-- From http://www.geeksforgeeks.org/space-and-time-efficient-binomial-coefficient/
-- http://www.geeksforgeeks.org/dynamic-programming-set-9-binomial-coefficient/
-- Alternative implementation based on primes and a benchmark http://www.luschny.de/math/factorial/FastBinomialFunction.html
local function fInternalBinCoeffImp1(n,k)
  if n < k then return 0
  elseif n == k or k == 0 then return 1 end
  
  local res = BN.number(1)
  
  --Since C(n, k) = C(n, n-k)
  if (k > n-k ) then
    k = n-k
  end
  
  for i=0,k-1 do
    res = res * (n-i)
    res = res / (i+1)
  end
  
  return res
end

--local fInternalCombCount = fInternalBinCoeffFact
local fInternalCombCount = fInternalBinCoeffImp1
--local fInternalCombCount = fInternalCombCountRecur

local retTab = {}
local function fbinCoeff(n,k)
  --print("fbinCoeff:",n,k)
  local val
  if retTab[n] then
    val = retTab[n][k]
    if val then return val end
  end
  
  val = fInternalCombCount(n,k)
  --print("fbinCoeff:val ",val)
  retTab[n] = {}
  retTab[n][k] = val
  return val
end

--https://en.wikipedia.org/wiki/Binomial_coefficient
function Combinatorics.BinCoefficient(n,k)
  if (n < 1) then error("BinCoefficient: N have to be at least 1!") end
  if (k > n) then error(string.format("BinCoefficient: Invalid configuration for n:%i and k:%i!", n, k)) end
  
  --return fbinCoeff(n,k)
  local ret = fbinCoeff(n,k)
  return ret
  --[[
  if ret > BN.number(math.maxinteger) then
    error(string.format("BinCoefficient: Range of n:%i, k:%i is not supported! ret: %s", n,k, ret))
    return ret
  else
    return BN.tonumber(ret)
  end
  ]]
end

--[[
Adapted From https://github.com/aisrael/jcombinatorics/blob/master/src/main/java/jcombinatorics/combinations/CombinadicCombinationsGenerator.java
Autor is Alistair A. Israel.
]]
local function fComb(count, l, n, k)
  --print("fComb", count, l, n, k) 
  local a = zTab.new()
  local m = count - l - 1
  
  local v = n - 1
  local c = fbinCoeff(v,k)
  --print("fComb", c, v, k, m, type(c))
  local deb = 0
  
  --local debugSum = ""
  
  local i = k
  while (i > 0) do
    while (c > m) do
      c = c * (v-i) / v
      v = v-1
    end
    
    m = m - c
    deb = (n-1) - v
    --print("fComb:deb", deb+1, type(deb))
    a[k-i] = deb+1 --Minor adaptation to start from 1 instead 0
    --debugSum = debugSum .. tostring(deb+1)
    i = i -1
    if (v > i) then c = c * (i+1) / (v-i)
    else c = v end
  end
  --print("fComb", a)
  --print("fComb", DG.digest("mdc2",debugSum))
  return a
end

function Combinatorics.CobinationGen(n,k)
  if not (n and k) then error("CobinationGen: Invalid argument!") end
  --print("CobinationGen:", n,k)
  local count = Combinatorics.BinCoefficient(n,k)
  --print("CobinationGen:", count)
  local i = 0
  return function()
    --print("CobinationGen#:", n,k, count)
    if i >= count then return nil
    else    
      local ret = fComb(count, i, n, k)
      --print("CobinationGen#:", i)
      i = i+1
      return ret
    end
  end, count
end

function Combinatorics.CobinationTable(n,k)
  local ret = {}
  local f, len = Combinatorics.CobinationGen(n,k)
  local fr
  for i=1,len do
    fr = f()
    if fr then ret[#ret+1] = fr.iTab end
  end
  return ret
end

function Combinatorics.genBinTruthTable(k)
  local ret = {}
  
  local l = 2^k
  local v,a
  for i=0,l-1 do
    --print(i,l,k)
    v = {}
    for j=k-1,0,-1 do
      a = Util.round(i/(2^j))%2
      --print(a)
      v[#v+1] = a
    end
    ret[#ret+1] = v
  end
  return ret
end

mt.__tostring = Combinatorics.tostring

return Combinatorics