
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

      assert_nil nil
      assert_not_nil [], 1

      assert_true true
      assert_false 1 > 2

      assert_truthy "yes", "no"
      assert_trueish "yes", "no"
      assert_falsy nil, false
      assert_falsey nil, false
      assert_falseish nil, false

      assert_equal 'one', 'o' + 'ne'
        # checks that all its arguments are equal

      assert_match 'one', /^one$/
        # checks that it receives a regex and one or more strings
        # and that all those strings match the regex

      assert_start_with 'one', 'one two or three'
        # checks that the shortest string is the start of the remaining string
        # arguments
      assert_end_with 'three', 'one two or three'
        # checks that the shortest string is the end of the remaining string
        # arguments

      assert_include 1, [ 1, 'two' ]
        # checks that the first array argument includes all other arguments

      assert_error(ArgumentError) { do_this_or_that() }
        # checks that the given block raises an ArgumentError
      assert_error(ArgumentError, /bad/) { do_this_or_that() }
        # checks that the given block raises an ArgumentError and
        # the error message matches the /bad/ regexp
      assert_error lambda { do_this_or_that() }, ArgumentError
        # checks that the given Proc raises an ArgumentError
      assert_error lambda { do_this_or_that() }, ArgumentError, 'bad'
        # checks that the given Proc raises an ArgumentError and
        # the error message == "bad"

      assert_hashy(
        this_thing => 1,
        that_thing => 'two')
          # combines two assert_equals in one

      assert_instance_of 1, Integer
      assert_is_a Integer, 123
        # checks that value or set of values are of a given of class

      assert 1, 1
        # behaves like assert_equal
      assert 'one', /one/i
        # behaves like assert_match
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

group 'core', 'sub-core', 'sub-sub-core' do
  #
  # it's OK to specifiy a path of group names

  test 'this' do
  end
end

group 'core < sub-core < sub-sub-core' do
  #
  # this is also ok...

  test 'that' do
  end
end

