
#
# test/epsilon.rb

group 'epsilon' do

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

  test 'no db' do
    p :no_db
  end

  group 'with db' do

    test 'a' do
      p :__a
    end
    test 'b' do
      p :__b
    end

    group 'group3' do

      test 'c' do
        p :__c
      end
    end

    group 'with strength', 'group4' do

      test 'd' do
        p :__d
      end
    end
  end

  section 'with strength' do

    around do
      p :with_strength_around_bf
      block.yield
      p :with_strength_around_af
    end
  end

  group 'epsilonws', 'with strength' do

    test 'e' do
      p :__e
    end
  end
end

section 'with db' do

  around do
    p :with_db_around_bf
    block.yield
    p :with_db_around_af
  end

  before do
    p :with_db_before
  end
end
section 'with db' do
  after do
    p :with_db_after
  end
end

group 'with strength' do

  test 'f' do
    p :__f
  end
end

