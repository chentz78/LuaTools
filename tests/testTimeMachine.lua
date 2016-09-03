local TM = require("TimeMachine")

local function newLabels()
  return string.format("%s",os.clock())
end

context("Basic Time Machine tests", function()
  test("Basic properties of TM", function()
    local tm = TM:new()
    assert_not_nil(tm)
    local px = tm:current()
    assert_not_nil(px)
    
    px.Tst1 = "AAA"
    local label = newLabels()
    tm:savePoint(label)
    
    tm:rollBack(label)
    assert_equal(px.Tst1, "AAA")
  end)
end)