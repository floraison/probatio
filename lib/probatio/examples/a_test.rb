
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

      assert 'one', 'o' + 'ne'
      assert_match 'one', /^one$/
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

