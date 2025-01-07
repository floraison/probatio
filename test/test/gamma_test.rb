
group 'gamma' do

  test 'assert_equal' do

    assert_equal(
      [ 'abc', 'def' ],
      [ 'abc' ])
    assert_equal(
      [ 'abc', 'def' ],
      [ 'abc' ])
  end

  test 'assert_equal2' do

    a = [ 'a' ] * 25
    b = [ 'bc' ] * 30

    assert_equal a, b
  end
end

