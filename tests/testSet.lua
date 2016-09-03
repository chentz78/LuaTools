local Set = require("Set")

context("Basic Set tests", function()
  test("Basic properties of Empty Set", function()
    local s1, s2, s3 = Set.new{}, Set.new(), Set.new()
    assert_equal(s1:card(), 0)
    assert_equal(s2:card(), 0)
    assert_equal(#s1, #s2)
    assert_true(s1 == s2) --Equality
    assert_true(s2 == s1) --Comutativity
    assert_true(s1==s2 and s2==s3 and s1==s3) --Transitivity
  end)
  context("Basic properties of not Empty Sets", function()
    test("With sets of same elements", function()
      local s1, s2, s3 = Set.new("A"), Set.new("A"), Set.new("A")
      assert_true(s1 == s2) --Equality
      assert_false(s1 ~= s2) --not Equality
      assert_true(s2 == s1) --Commutativity
      assert_true(s1==s2 and s2==s3 and s1==s3) --Transitivity
    end)
    test("With sets of different elements", function()
      local s1, s2, s3 = Set.new("A"), Set.new("AB"), Set.new("ABC")
      assert_false(s1 == s2) --Equality
      assert_true(s1 ~= s2) --not Equality
      assert_false(s2 == s1) --Comutativity
      assert_false(s1==s2 and s2==s3 and s1==s3) --Transitivity
    end)
    test("Union Set", function()
      local s1, s2, s3 = Set.new("A"), Set.new("AB"), Set.new("ABC")
      local sr = s1+s2
      assert_equal(sr:card(), 2)
      assert_equal((sr+s3):card(), 3)
      sr = s1+s2+s3
      assert_equal(sr:card(), 3)
      sr = s2+s1
      assert_equal(sr:card(), 2)
      assert_equal(s1+s2, Set.new{"AB","A"})
      assert_equal(s2+s3, Set.new{"AB","ABC"})
      assert_equal(s1+s2+s3, Set.new{"AB","ABC","A"})
    end)
    test("Intersection Set", function()
      local s1, s2, s3 = Set.new("A"), Set.new{"A","AB"}, Set.new("ABC")
      local sr = s1*s2
      assert_equal(sr:card(), 1)
      assert_equal((sr*s3):card(), 0)
      sr = s1*s2*s3
      assert_equal(sr:card(), 0)
      sr = s2*s1
      assert_equal(sr:card(), 1)
      assert_equal(s1*s2, Set.new{"A"})
      assert_equal(s2*s3, Set.new())
      assert_equal(s1*s2*s3, Set.new())
    end)
    test("Complement Set", function()
      local s1, s2, s3 = Set.new{"A","B"}, Set.new{"AB","B"}, Set.new{"ABC","B"}
      local sr = s1-s2
      assert_equal(sr:card(), 1)
      assert_equal((sr-s3):card(), 1)
      sr = s1-s2-s3
      assert_equal(sr:card(), 1)
      sr = s2-s1
      assert_equal(sr:card(), 1)
      assert_equal(s1-s2, Set.new{"A"})
      assert_equal(s2-s3, Set.new("AB"))
      assert_equal(s1-s2-s3, Set.new("A"))
    end)
    test("member in Set", function()
      local s1, s2, s3 = Set.new{"A","B"}, Set.new{"AB","B"}, Set.new{"ABC","B"}
      assert_true(s1:inSet("A"))
      assert_true(s1:inSet("B"))
      assert_true(s2:inSet("B"))
      assert_true(s3:inSet("ABC"))
      assert_true((s1+s2):inSet("AB"))
      assert_nil((s1+s2):inSet("C"))
    end)
    test("include in Set", function()
      local s1, s2, s3 = Set.new{"A","B"}, Set.new{"AB","B"}, Set.new{"ABC","B"}
      print(s1, s1:card())
      assert_not_nil(s1)
      assert_not_nil(s1:include("C"))
      assert_equal(s1:card(), 3)
    end)
    test("Set Copy", function()
      local s1,s2 = Set.new{"A","B"}
      s2 = Set.new(s1)
      assert_equal(s1, s2)
      s2:include("C")
      assert_not_equal(s1, s2)
    end)
  end)
end)