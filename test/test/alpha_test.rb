
setup do

  @ur = 'ur'
end

group 'alpha' do

  setup do
    @string = 'Nada'
  end
  teardown do
  end

  _before do
    @string = 'Heartbreak'
  end

  after do
  end

  test 'one' do

    assert_match 'Lionhearz', /heart/i
  end

  test 'two' do

    assert @string, /heart/i
    assert_match @string, /heart/i
  end

  _test 'three' do

    # pending
  end

  test 'four' do

    assert true
  end

  test 'five' do

    assert false => false
  end

  test 'error' do

    assert_error(
      lambda { raise "nada" },
      StandardError)

  end
end

