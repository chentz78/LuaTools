local Util = require("Util")

local Stats = {}

local function pSerieRange(serie, idx, len, fProc)
  local sPos = len
  for i=sPos,idx do
    if not fProc(i, serie[i]) then return false end
  end
  return true
end

function Stats.SMA(serie, len, idx)
  --print(idx,len)
  if len-idx > 0 then return nil end
  
  local r = 0
  for i=(idx-len)+1,idx do
    r = r + serie[i]
  end
  return r/len
end

function Stats.EMA(serie, len, idx)
  --print(idx,len)
  if idx < len then return nil end
  
  local mult = 2/(len+1)
  
  local lastEMA = Stats.SMA(serie,len,idx)
  if len == idx then return lastEMA end
  
  for i=len,idx do
    --print(i,lastEMA,idx, len)
    if i == len then
      lastEMA = Stats.SMA(serie,len,i)
    else
      lastEMA = ((serie[i] - lastEMA) * mult) + lastEMA
    end
  end
  return lastEMA
end

function Stats.MACD(serie, fastLen,slowLen,sigLen, idx)
  if (fastLen >= slowLen) or
     (sigLen > slowLen) then error("Stats.MACD: Invalid args configuration!") end
     
  local minLen = math.max(fastLen,slowLen)
  
  if idx < minLen then return nil end

  local macdSerie = {}
  --local maFast, maSlow
  pSerieRange(serie, idx, sigLen, function(i,v)
    local maFast = Stats.EMA(serie, fastLen, i)
    local maSlow = Stats.EMA(serie, slowLen, i)
    if not (maFast and maSlow) then return true end
    local r = maFast - maSlow
    --print(i,v,maFast, maSlow, r)
    macdSerie[#macdSerie+1] = r
    return true
  end)
  
  local macd = macdSerie[#macdSerie]
  --[[
  local maFast = Stats.EMA(serie, fastLen, idx)
  local maSlow = Stats.EMA(serie, slowLen, idx)
  local macd = maFast - maSlow
  ]]
  --print(#macdSerie)
  local sig = Stats.EMA(macdSerie, sigLen, #macdSerie)
  local hist
  if sig then hist = macd - sig end
  
  return macd, sig, hist
end

function Stats.incSMA(len)
  local smaTab = {}
  local lIdx = 1
  local inc = Util.incGen(1)
  
  return function (val)
    local i = inc()
    smaTab[lIdx] = val
    if lIdx >= len then lIdx = 1 
    else lIdx = lIdx + 1 end
    
    local r = 0
    for _,v in ipairs(smaTab) do
      r = r + v
    end
    if i < len then return nil end
    return r/#smaTab
  end
end

--[[
Source: http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:moving_averages
Multiplier: (2 / (Time periods + 1) ) = (2 / (10 + 1) ) = 0.1818 (18.18%)
EMA: {Close - EMA(previous day)} x multiplier + EMA(previous day).
]]
function Stats.incEMA(len)
  local mult = 2/(len+1)
  local lastEMA = nil
  local inc = Util.incGen(1)
  local sma = Stats.incSMA(len)
  
  return function (val)
    local i = inc()
    --print("i",i)
    if i <= len then
      local smaVal = sma(val)
      if i < len then return nil end
      if i == len and not lastEMA then
        lastEMA = smaVal
        return lastEMA
      end
    end
    
    lastEMA = ((val - lastEMA) * mult) + lastEMA
    
    return lastEMA
  end
end

--[[
Source: http://stockcharts.com/school/doku.php?id=chart_school:technical_indicators:moving_average_convergence_divergence_macd
MACD Line: (12-day EMA - 26-day EMA)
Signal Line: 9-day EMA of MACD Line
MACD Histogram: MACD Line - Signal Line
]]
function Stats.incMACD(fastLen,slowLen,sigLen)
  if (fastLen >= slowLen) or
     (sigLen > slowLen) then error("Stats.MACD: Invalid args configuration!") end
  local maFast = Stats.incEMA(fastLen)
  local maSlow = Stats.incEMA(slowLen)
  local maSig = Stats.incEMA(sigLen)
  local minLen = math.max(fastLen,slowLen)
  
  local inc = Util.incGen(1)
  
  return function(v)
    local i = inc()
    local mf,ms = maFast(v), maSlow(v)
    
    if i < minLen then return nil end
    
    local macd, sig, hist
    macd = mf - ms
    sig = maSig(macd)
    if sig then hist = macd - sig end
    
    return macd, sig, hist
  end
end

function Stats.Highest(len)
  local lastVals = {}
  local inc = Util.incGen(1)
  
  return function (val)
    local i = inc()
    local idx = i % len
    if idx == 0 then idx = len end
    
    lastVals[idx] = val
    
    local r = lastVals[1]
    for _,v in ipairs(lastVals) do
      r = math.max(r,v)
    end
    return r
  end
end

function Stats.Lowest(len)
  local lastVals = {}
  local inc = Util.incGen(1)
  
  return function (val)
    local i = inc()
    local idx = i % len
    if idx == 0 then idx = len end
    
    lastVals[idx] = val
    
    local r = lastVals[1]
    for _,v in ipairs(lastVals) do
      r = math.min(r,v)
    end
    return r
  end
end

return Stats