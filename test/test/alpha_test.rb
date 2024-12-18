
group 'alpha' do

  before :each do

    @string = 'Heartbreak'
  end

  test 'one' do

    assert 'Lionheart', matches(/heart/i)
  end

  test 'two' do

    assert @string, matches(/heart/i)
    #assert @string { matches(/heart/i) }
  end
end

