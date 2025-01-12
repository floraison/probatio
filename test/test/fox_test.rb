
#
# test/fox.rb

group 'fox' do

  before do
    p :before_d
  end
  after do
    p :after_d
  end

  test 'a' do
    p :__a
  end

  group 'foxbat' do

    test 'b' do
      p :__b
    end
  end
end

