
group 'core' do

  setup do
    # occurs once before tests and sub-groups in group 'core'
  end
  teadowm do
    # occurs once after tests and sub-groups in group 'core'
  end

  group 'alpha' do

    before do
      # is run in the separate test context before _each_ test
    end
    after do
      # is run in the separate test context after _each_ test
    end

    test 'one' do

      MyLib.do_this_or_that()

      assert_equal 'one', 'o' + 'ne'
        # checks that all its arguments are equal

      assert_match 'one', /^one$/
        # checks that it receives a regex and one or more strings
        # and that all those strings match the regex

      assert_include 1, [ 1, 'two' ]
        # checks that the first array argument includes all other arguments

      assert 1, 1
        # behaves like assert_equal
      assert 'one', /one/i
        # behaves like assert_match
      assert 'one', [ 'one', 'two' ]
        # behaves like assert_include
      assert 11 => '10'.to_i + 1
        # assert equality between key and value
      assert 'one' => 'on' + 'e', 'two' => :two.to_s
        # assert equality between keys and values
    end
  end

  group 'bravo' do
  end
end

group 'core' do
  #
  # it's OK to re-open a group to add sub-groups, tests,
  # and setups, teardowns, befores, or afters
  #
  # it's OK to re-open a group in another file, as long
  # as it's the same name at the same point in the name hierarchy

  _test 'not yet' do
    #
    # prefix a test, a group, or other element with _
    # marks it as _pending
  end
end

