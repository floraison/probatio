
group 'nada' do

  test 'refute scalar' do

    refute false
    refute ! true
    refute true
  end

  test 'refute rex' do

    refute "not a test", /spec/
    refute "not a test", /test/
  end

  test 'refute hashy' do

    refute :a => 1, :b => 'b'
    refute :a => 'a', :b => 'b'
    refute 'a' => 'a', 'b' => 'b'
  end
end

