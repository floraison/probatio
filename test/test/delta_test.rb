
#
# test/delta_test.rb

group 'delta' do

  before do
    p :before_d
  end
  after do
    p :after_d
  end

  group 'delta1' do

    before do
      p :before_d1
    end
    after do
      p :after_d1
    end

    test 'd1a' do
      p :__test_d1a
    end
    test 'd1b' do
      p :__test_d1b
    end
  end
end

