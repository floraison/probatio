
#
# probatio/assertions.rb

class Probatio::Context

  def assert_equal(*as)

    do_assert do

      as.all? { |a| a == as[0] } ||
      "not equal"
    end
  end

  def assert_match(*as)

    do_assert do

      strings, others = as.partition { |a| a.is_a?(String) }
      rex = others.find { |o| o.is_a?(Regexp) } || strings.pop

      strings.all? { |s| s.match?(rex) } ||
      "not matched"
    end
  end

  def assert_include(*as)

    ai =
      as.index { |a| a.is_a?(Array) } ||
      fail(ArgumentError.new("assert_include found no array"))

    arr = as.delete_at(ai)

    do_assert do

      as.all? { |e| arr.include?(e) } ||
      "not included"
    end
  end

  # Checks whether its "_assert_something", if that's the case,
  # just flags the assertion as :pending an moves on
  #
  def method_missing(name, *args, &block)

    n = name.to_s

    if n.start_with?('_assert') && self.respond_to?(n[1..-1])

      Probatio.despatch(:assertion_pending, self, @__child)

      :pending

    else

      super
    end
  end

  # Jack of all trade assert
  #
  def assert(*as)

    count = {
      rexes: 0, hashes: 0, arrays: 0, strings: 0, scalars: 0, others: 0 }

    as.each { |a|
      k =
        case a
        when Regexp then :rexes
        when Hash then :hashes
        when Array then :arrays
        when String then :strings
        else :others; end
      count[k] = count[k] + 1
      count[:scalars] += 1 if %i[ rexes strings ].include?(k) }

    if as.length == 1 && count[:hashes] == 1

      do_assert { as[0].to_a.all? { |k, v| k == v } || "not equal" }

    elsif as.length == 1

      do_assert { as[0] || "not trueish" }

    elsif count[:rexes] == 1 && count[:strings] == as.length - 1

      assert_match(*as)

    elsif count[:arrays] > 0

      assert_include(*as)

    else

      assert_equal(*as)
    end
  end

  protected

  def do_assert(&block)

    Probatio.despatch(:assertion_enter, self, @__child)

    r =
      begin
        block.call
      rescue => err
        err
      end

    if r.is_a?(StandardError) || r.is_a?(String)

      aerr = Probatio::AssertionError.new(r, *extract_file_and_line(caller))

      Probatio.despatch(:test_fail, self, @__child, aerr)

      raise aerr

    elsif r.is_a?(Exception)

      Probatio.despatch(:test_exception, self, @__child, r)

      raise r
    end

    return r if r == :pending
    true

  ensure

    #Probatio.despatch(:test_succeed, self, @__child)
    Probatio.despatch(:assertion_leave, self, @__child)
  end

  def extract_file_and_line(backtrace)

    l = backtrace.find { |l| ! l.index('lib/probatio/assertions.rb') }
    m = l && l.match(/([^:]+):(\d+)/)
    m && [ m[1], m[2].to_i ]
  end
end

