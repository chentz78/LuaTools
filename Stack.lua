--[[
From http://en.wikipedia.org/wiki/Stack_%28abstract_data_type%29
Basic idea is LIFO
]]
local Stack = {}
local List = require("List")

local mt = {__index=Stack}

local function modelInternal() return {lst=List.new(), id='Stack'} end

function Stack.new()
  return setmetatable(modelInternal(), mt)
end

function Stack.push(self, e)
  self.lst:pushleft(e)
end

function Stack.pop(self)
	return self.lst:popleft()
end

return Stack