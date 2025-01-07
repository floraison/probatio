
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

  test 'assert_start_with' do
    assert_start_with('one', 'one two three')
    assert_start_with('one', '1 two three')
  end
  test 'assert_end_with' do
    assert_end_with('three', 'one two three')
    assert_end_with('3', '1 two three')
  end
end

group Probatio do

  test String do

    assert_equal 1, 2
  end
end

