
group 'bravo' do

  test 'addition' do

    assert 2, 1 + 1
    assert_false false
    assert_true true
    assert_trueish 1
    assert_equal 1, 1
    assert_match 'doG', /og/i
    assert_include [ 1, 2, 3 ], 3
    assert_hashy "a" => 'A'.downcase
  end

  test 'assert 0' do

    assert true
    assert false
  end
end

group 'alpha' do

  test 'hello again' do

    assert 2, 3
  end
end

group 'alice' do

  test 'a' do
  end
end

group 'alice', 'bob' do

  test 'b' do

    assert false
  end
end

