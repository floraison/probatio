
before :all do
end

group 'this' do
  before :all do
  end
  around :tag do
    yield
  end
  test 'that' do
    assert blue matches(/dark/)
  end
  group 'other' do
    test 'toto' do
    end
  end
end

