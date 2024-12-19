
setup do
  @ur = 'ur'
end

group 'alpha' do

  setup do
    @string = 'Nada'
  end
  teardown do
  end

  before do

    @string = 'Heartbreak'
  end

  after do
  end

  test 'one' do

    assert_match 'Lionhearz', /heart/i
  end

  test 'two' do

    assert_match @string, /heart/i
  end
end

