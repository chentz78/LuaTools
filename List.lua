--[[
From  http://www.lua.org/pil/11.4.html
]]
local List = {}

local function internalNext(list, key)
  local nK = key
  if not nK then
    nK = list.first
  else
    nK=nK+1
  end
  
  if nK > list.last then return nil end
  
  return nK,list[nK]
end

local mt = {__index=List,
            __pairs=function(t)
              return internalNext, t, nil
            end}

local function modelInternal() return {first = 0, last = -1, id='List'} end

function List.new()
  local lst = setmetatable(modelInternal(), mt)
  return lst
end

function List.pushleft(list, value)
  local first = list.first - 1
  list.first = first
  list[first] = value
end

function List.pushright(list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end
         
function List.popleft(list)
  local first = list.first
  if first > list.last then error("list is empty") end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end

function List.popright(list)
  local last = list.last
  if list.first > last then error("list is empty") end
  local value = list[last]
  list[last] = nil         -- to allow garbage collection
  list.last = last - 1
  return value
end

function List.empty(list)
  return list:count()<1
end

function List.count(list)
  return (list.last-list.first)+1
end

return List