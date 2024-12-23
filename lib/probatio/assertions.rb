
#
# probatio/assertions.rb

class Probatio::Context

  def assert(*as)

    do_assert do

      as.all? { |a| a == as[0] } ||
      "no equal"
    end
  end

  def assert_match(*as)

    do_assert do

      strings, others = as.partition { |a| a.is_a?(String) }
      rex = others.find { |o| o.is_a?(Regexp) } || strings.pop

      strings.all? { |s| s.match?(rex) } ||
      "no match"
    end
  end

  def method_missing(name, *args, &block)

    n = name.to_s

    if n.start_with?('_assert') && self.respond_to?(n[1..-1])

      Probatio.despatch(:assertion_pending, self, @__child)

      :pending

    else

      super
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

      Probatio.despatch(:test_fail, self, @__child, r)

      fail Probatio::AssertionError.new(r)

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
end

