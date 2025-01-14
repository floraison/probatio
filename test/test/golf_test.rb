
#
# test/golf.rb

section 'golf' do

  around do
    p :around_bf
    block.yield
    p :around_af
  end
end

group 'golf' do

  test 'a' do
    p :__a
  end

  group 'foxbat' do

    test 'b' do
      p :__b
    end
  end
end

