--[[
From http://en.wikipedia.org/wiki/Queue_%28abstract_data_type%29
Basic idea is FIFO
]]
local Queue = {}
local List = require("List")

local mt = {__index=Queue}

local function modelInternal() return {lst=List.new(), id='Queue'} end

function Queue.new()
  return setmetatable(modelInternal(), mt)
end

function Queue.enqueue(self, e)
  self.lst:pushleft(e)
end

function Queue.dequeue(self)
	return self.lst:popright()
end

function Queue.empty(self)
  return self.lst:empty()
end

return Queue