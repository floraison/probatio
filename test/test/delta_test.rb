
#
# test/delta_test.rb

group 'delta' do

  before do
    p :before_d
  end
  after do
    p :after_d
  end
  #around do
  #  p :aB
  #  block.yield
  #  p :aA
  #end

  group 'delta0' do

    test 'd0a' do
      p :__test_d0a
    end
  end

  group 'delta1' do

    before do
      p :before_d1
    end
    after do
      p :after_d1
    end

    around do
      p :around_0_before
      block.yield
      p :around_0_after
    end

    around do
      p :around_1_before
      block.yield
      p :around_1_after
    end

    test 'd1a' do
      p :__test_d1a
    end
    test 'd1b' do
      p :__test_d1b
    end
  end
end

