
#class Probatio::Test
#
#  #
#  # some helper methods
#
#  def say_hello
#
#    puts :hello
#  end
#
#  #include ThoseHelperMethods
#    # cleaner...
#end

#class Probatio::Group
#  def do_before(run_opts)
#  end
#  def do_after(run_opts)
#  end
#end
  #
  # not for now...

#class Probatio::Context
#
#  def assert_foo(*as)
#
#    do_assert do
#
#      strings, others = as.partition { |a| a.is_a?(String) }
#      rex = others.find { |o| o.is_a?(Regexp) } || strings.pop
#
#      strings.all? { |s| s.match?(rex) } ||
#      "no match"
#    end
#  end
#end
