
group 'bravo' do

  test 'addition' do

    assert 1, 1
  end

  test 'assert 0' do

    assert true
    assert false
  end
end

group 'alpha' do

  test 'hello again' do

    assert 2, 3
  end
end
