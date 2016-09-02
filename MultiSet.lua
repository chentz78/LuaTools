local MultiSet = {}

local Debug = require("dbg")

local mt = {}

function MultiSet.new(l, isSet)
  local set = {}
	isSet = isSet or false
	setmetatable(set, mt)
	
	if isSet then
	  for _i, v in pairs(l) do set[_i] = 1 end
	else
	  local val = nil
    for _, v in ipairs(l) do
		  val = set[v]
		  if val then
			  set[v] = val + 1
		  else
		    set[v] = 1
			end
		end
	end
	return set
end

function MultiSet.join(a,b)
  local res = MultiSet.new{}
	local tmp = nil
	for _i, v in pairs(a) do
	  tmp = b[_i]
	  if tmp then
		  res[_i] = v + tmp
		else res[_i] = v end
	end
	
	for _i, v in pairs(b) do
	  tmp = a[_i]
		if not tmp then res[_i] = v end
	end
	return res
end

function MultiSet.configToString(to, tc, ts)
  Debug.tableOpen = to
	Debug.tableClose = tc
	Debug.tableSep = ts
	Debug.itemOpen = '"'
	Debug.itemClose = '"'
	Debug.keyOpen = '['
	Debug.keyClose = ']'
end

function MultiSet.tostring(ms)
  local l = {}
	for _i, v in pairs(ms) do l[#l + 1] = Debug.tostring(_i) .. ":" .. v end
  return Debug.tostring(l)
end

function MultiSet.print(s)
  print(MultiSet.tostring(s))
end

--[[
function MultiSet.union(a,b)
  local res = MultiSet.new{}
	for k in pairs(a) do res[k] = true end
	for k in pairs(b) do res[k] = true end
	return res
end

function MultiSet.intersection(a,b)
  local res = MultiSet.new{}
	for k in pairs(a) do res[k] = b[k] end
	return res
end

function MultiSet.diff(a,b)
  local res = MultiSet.new{}
	for k in pairs(a) do
		if not b[k] then res[k] = true end
	end
	return res
end

function MultiSet.in(e, set)
  return set[e] == true
end

function MultiSet.card(set)
  local count=0
  for k in pairs(set) do
    count = count + 1
  end
  return count
end

function MultiSet.product(a, b)
  local res = MultiSet.new{}
  local s
  for k in pairs(a) do
    for j in pairs(b) do
      s = {k,j}
      res[s] = true
    end
  end
  return res
end

function MultiSet.table(set)
  local res = {}
	for e in pairs(set) do res[#res + 1] = e end
	return res
end

]]

mt.__concat = MultiSet.union
mt.__add = MultiSet.join
mt.__mul = MultiSet.product
mt.__sub = MultiSet.diff
mt.__tostring = MultiSet.tostring

return MultiSet
