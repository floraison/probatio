
group 'alpha' do

  setup do
  end
  teardown do
  end

  before do

    @string = 'Heartbreak'
  end

  after do
  end

  test 'one' do

    assert 'Lionheart', matches(/heart/i)
  end

  test 'two' do

    assert @string, matches(/heart/i)
    #assert @string { matches(/heart/i) }
  end
end

