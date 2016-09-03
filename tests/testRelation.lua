local Rel = require("Relation")
local Util = require("Util")

context("Basic Relations tests", function()
  test("Basic properties of Empty Relations", function()
    local r1, r2, r3 = Rel.new(), Rel.new(), Rel.new()
    assert_equal(r1:card(), 0)
    assert_equal(r2:card(), 0)
    assert_equal(#r1, #r2)
    assert_true(r1 == r2) --Equality
    assert_true(r2 == r1) --Comutativity
    assert_true(r1==r2 and r2==r3 and r1==r3) --Transitivity
  end)
  
  context("Basic properties of not Empty Relations", function()
    test("With relations of same elements", function()
      local r1 = Rel.new()
      r1(1,2)
      local r2, r3 = Rel.new(r1), Rel.new(r1)
      assert_true(r1 == r2) --Equality
      assert_false(r1 ~= r2) --not Equality
      assert_true(r2 == r1) --Commutativity
      assert_true(r1==r2 and r2==r3 and r1==r3) --Transitivity
    end)
    test("With relation of different elements", function()
      local r1, r2, r3 = Rel.new(),Rel.new(),Rel.new() 
      r1(1,2)
      r1(2,1)
      
      r2(2,1)
      r2(3,4)
      
      r3(3,4)
      r3(4,3)
      
      assert_true(r1 == r1)
      assert_false(r1 ~= r1)
      
      assert_false(r1 == r2) --Equality
      assert_true(r1 ~= r2) --not Equality
      assert_false(r2 == r1) --Comutativity
      assert_false(r1==r2 and r2==r3 and r1==r3) --Transitivity
      
      local ident = Rel.new()
      ident(1,1)
      ident(2,2)
      local cr = ident .. ident
      assert_equal(cr, ident)
      
      r1 = Rel.new()
      r1("S","N")
      r1("N","B")
      r1("B","A")
      r1("A","N")
      assert_not_equal(r1, r1..r1)
      
      assert_false(r1 == nil)
      assert_false(r1 == 1)
    end)
    test("Domain and Range in Relations", function()
      local r1, r2, r3 = Rel.new(),Rel.new(),Rel.new()
      r1("a","b")
      r1("b","b")
      r1("b","c")
      
      r2("b","d")
      r2("b","e")
      r2("c","c")
      
      assert_not_nil(r1:domain())
      assert_not_nil(r2:domain())
      
      assert_not_nil(r1:range())
      assert_not_nil(r2:range())
      
      assert_equal((r1:domain() * r2:domain()):card(), 1) 
      assert_equal((r1:range() * r2:range()):card(), 1)
    end)
    test("subscript in Relations", function()
      local r1, r2, r3 = Rel.new(),Rel.new(),Rel.new() 
      r1(1,2)
      r1(1,1)
      r1(2,5)
      r2(2,1)
      r3(3,4)
      r3("a","b")
      
      assert_not_nil(r1%1)
      assert_not_nil(r1%2)
      assert_nil(r1%3)
      assert_nil(r1%"a")
      
      assert_not_nil(r2%2)
      assert_nil(r2%3)
      
      assert_not_nil(r3%3)
      assert_nil(r3%5)
      assert_not_nil(r3%"a")
      
      
      assert_not_nil((r1%1):inSet(2))
      assert_not_nil((r1%1):inSet(1))
      assert_not_nil((r1%2):inSet(5))
      assert_not_nil((r2%2):inSet(1))
      assert_not_nil((r3%3):inSet(4))
      assert_not_nil((r3%"a"):inSet("b"))
      
    end)
    test("tostring Relations", function()
      local r1, r2 = Rel.new()
      r1(1,2)
      r1(1,3)
      r2 = Rel.new(r1)
      r2(2,3)
      assert_not_nil(r1:tostring())
      assert_not_nil(r2:tostring())
      --print(r1)
      assert_equal(r1:tostring(), "{<1,2>; <1,3>}")
    end)
  end)  
end)

context("Closure over Relations", function()
  test("composition of Relations", function()
    local r1,r2,r3
    
    r1 = Rel.new()
    assert_not_nil(r1)
    r1("a","b")
    r1("b","b")
    r1("b","c")
    
    r2 = Rel.new()
    assert_not_nil(r2)
    r2("b","d")
    r2("b","e")
    r2("c","c")
    
    r3 = Rel.new()
    assert_not_nil(r3)
    r3("a","d")
    r3("a","e")
    r3("b","d")
    r3("b","e")
    r3("b","c")
    
    local cr = r1 .. r2
    
    assert_not_nil(cr)
    assert_equal(cr:domain(), r1:domain())
    assert_equal(cr:range(), r2:range())
    
    assert_true(cr == r3)
    
    assert_equal(r1 .. r2, r1:composition(r2))
    assert_nil(r3 .. r3)
    
    r1 = Rel.new()
    r1("S","N")
    r1("N","B")
    r1("B","A")
    r1("A","N")
    
    r3 = Rel.new()
    r3("S","B")
    r3("N","A")
    r3("B","N")
    r3("A","B")
    
    assert_not_equal(r1, r1..r1)
    assert_equal(r1..r1, r3)
  end)
  test("Power of Relations", function()
    local r1 = Rel.new()
    assert_not_nil(r1)
    r1("a","b")
    r1("b","b")
    r1("b","c")
    assert_not_nil(r1^1)
    assert_not_nil(r1^2)
    assert_not_nil(r1^3)
    
    assert_equal(r1^1, r1)
    assert_equal(r1^2, r1 .. r1)
    assert_equal(r1^3, r1 .. r1 .. r1)
    assert_equal(r1^4, r1 .. r1 .. r1 .. r1)
    assert_equal(r1^4, r1^2)
    local r,i = r1:power(4)
    assert_equal(i,2) 
  end)
  test("Transitive Closure of Relations", function()
    local r1 = Rel.new()
    assert_not_nil(r1)
    r1("a","b")
    r1("b","b")
    r1("b","c")
    assert_not_nil(r1^2)
    
    assert_equal(r1+1, r1)
    assert_equal(r1+2, (r1^1) + (r1^2))
    assert_equal(r1+3, (r1^1) + (r1^2) + (r1^3))
    assert_equal(r1+4, (r1^1) + (r1^2) + (r1^3) + (r1^4))
    assert_equal(r1+4, r1+2)
    assert_equal(r1+0, r1+2)
    
    r1 = Rel.new()
    r1("S","N")
    r1("N","B")
    r1("B","A")
    r1("A","N")
    assert_not_nil(r1+0)
    assert_equal(r1+0, r1+3)
  end)
end)

context("Iterators", function()
  test("pairs and setIterator", function()
    local r1 = Rel.new()
    
    r1("v1","v2")
    r1("v1","v4")
    
    r1("v2","v5")
    r1("v2","v4")
    
    r1("v3","v1")
    r1("v3","v6")
    
    r1("v4","v3")
    r1("v4","v5")
    r1("v4","v6")
    r1("v4","v7")
    
    r1("v5","v7")
    
    r1("v7","v6")
    assert_equal(r1:card(), 12)
    local d,r = r1:domain(), r1:range()
    for k,v in pairs(r1) do
      assert_true(d:inSet(k))
      assert_true(r:inSet(v))
    end
    
    for k,v in r1:getSetIteration() do
      assert_true(d:inSet(k))
      assert_not_nil(r * v)
    end
  end)
  test("Sort Iterators", function()
    local r1 = Rel.new()
    
    r1("v1","v2")
    r1("v1","v4")
    
    r1("v2","v5")
    r1("v2","v4")
    
    r1("v3","v1")
    r1("v3","v6")
    
    r1("v4","v3")
    r1("v4","v5")
    r1("v4","v6")
    r1("v4","v7")
    
    r1("v5","v7")
    
    r1("v7","v6")
    assert_equal(r1:card(), 12)
    local d,r = r1:domain(), r1:range()
    
    local seq = {}
    
    for k,v in r1:getSetIterationSort() do
      assert_true(d:inSet(k))
      assert_not_nil(r * v)
      seq[#seq+1] = k
    end
    
    assert_equal(seq[1], "v1")
    assert_equal(seq[#seq-1], "v5")
    assert_equal(seq[#seq], "v7")
  end)
end)

context("Graph Operations", function()
  test("BFS", function()
    local r1 = Rel.new()
    
    r1("v1","v2")
    r1("v1","v4")
    
    r1("v2","v5")
    r1("v2","v4")
    
    r1("v3","v1")
    r1("v3","v6")
    
    r1("v4","v3")
    r1("v4","v5")
    r1("v4","v6")
    r1("v4","v7")
    
    r1("v5","v7")
    
    r1("v7","v6")
    assert_equal(r1:card(), 12)
    
    local seq = {}
    local lastIdx = -1
    local ret = r1:BFS("v3", function (elem, index)
      seq[#seq+1] = elem
      lastIdx = index
      return true
    end)
    
    print(Util.tostring(seq))
    assert_equal(#seq,(r1:domain()+r1:range()):card())
    assert_equal(lastIdx, 3)
    assert_equal(seq[1], "v3")
    assert_equal(seq[#seq-1], "v5")
    assert_equal(seq[#seq], "v7")
  end)
  test("Shortest Path", function()
    local r1 = Rel.new()
    
    r1("v1","v2")
    r1("v1","v4")
    
    r1("v2","v5")
    r1("v2","v4")
    
    r1("v3","v1")
    r1("v3","v6")
    
    r1("v4","v3")
    r1("v4","v5")
    r1("v4","v6")
    r1("v4","v7")
    
    r1("v5","v7")
    
    r1("v7","v6")
    assert_equal(r1:card(), 12)
    
    local pl = r1:shortestPath("v3","v3")
    assert_equal(pl, 0)
    pl = r1:shortestPath("v3","v1")
    assert_equal(pl, 1)
    pl = r1:shortestPath("v3","v7")
    assert_equal(pl, 3)
  end)
end)