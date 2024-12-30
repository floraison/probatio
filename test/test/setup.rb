
#
# setup.rb and *_setup.rb files accept `group`, `setup`, `teardown`
# (and also `before` and `after` but that makes less sense

setup do

  #puts "SETUP!"
  #pp ENV
end

teardown do
end

test 'not considered' do

  # test blocks are not considered in setup.rb or *_setup.rb

  puts "TEST." * 10
end

