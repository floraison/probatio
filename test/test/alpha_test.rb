
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

    p :one
    p @string
    #assert 'Lionheart', matches(/heart/i)
  end

  test 'two' do

    p :two
    #assert @string, matches(/heart/i)
    #assert @string { matches(/heart/i) }
  end
end

