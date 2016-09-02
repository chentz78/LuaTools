local BenchTimer = {}

local sCre = "created"
local sRun = "running"
local sStop = "stopped"
local sPause = "paused"

--local Debug = require("dbg")
--dbg = Debug:new()

local mt = {__index=BenchTimer}
            
function BenchTimer.new(gTimer)
  return setmetatable({id="BenchTimer",sCount=0,gBTimer=gTimer,tCount=0,timer=0,state=sCre}, mt)
end

function BenchTimer.start(bt)
  if bt.state == sCre or
     bt.state == sStop then
     bt.state = sRun
     bt.sCount = bt.sCount + 1
     if bt.gBTimer then bt.gBTimer.sCount = bt.gBTimer.sCount + 1 end
     bt.timer = os.clock()
  end
  return true
end

function BenchTimer.pause(bt)
  if bt.state == sRun then
    local ta = os.clock() - bt.timer
    bt.state = sPause
    if not bt.gBTimer then bt.tCount = bt.tCount + ta
    else bt.gBTimer.tCount = bt.gBTimer.tCount + ta end
    return true
  end
  return false
end

function BenchTimer.resume(bt)
  if bt.state == sPause then
    bt.state = sRun
    bt.timer = os.clock()
    return true
  end
  return false
end

function BenchTimer.stop(bt)
  if bt.state == sRun then
    local ta = os.clock()-bt.timer
    bt.state = sStop
    if not bt.gBTimer then bt.tCount = bt.tCount + ta
    else bt.gBTimer.tCount = bt.gBTimer.tCount + ta end 
    return true
  elseif bt.state == sPause then
  end
  return false
end

function BenchTimer.timeSum(bt)
  if bt.gBTimer and bt.state == sCre then
    return false
  end
  
  return true, bt.tCount
end

function BenchTimer.countSum(bt)
  return bt.sCount
end

return BenchTimer