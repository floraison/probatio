
#
# probatio/assertions.rb

class Probatio::Context

  # Beware: ws.any? returns false when ws == [ false ]

  def assert_truthy(*as)

    do_assert(as, 'truthy') { |a| !! a }
  end
  alias assert_trueish assert_truthy

  def assert_falsey(*as)

    do_assert(as, 'falsey') { |a| ! a }
  end
  alias assert_falsy assert_falsey
  alias assert_falseish assert_falsey

  def assert_true(*as)

    do_assert(as, 'true') { |a| a == true }
  end

  def assert_false(*as)

    do_assert(as, 'false') { |a| a == false }
  end

  def assert_equal(*as)

    do_assert(as, 'equal') { |a| a == as[0] }
  end

  def assert_match(*as)

    strings, others = as.partition { |a| a.is_a?(String) }
    rex = others.find { |o| o.is_a?(Regexp) } || strings.pop

    do_assert(strings, 'matched') { |s| s.match?(rex) }
  end

  def assert_include(*as)

    ai =
      as.index { |a| a.is_a?(Array) } ||
      fail(ArgumentError.new("assert_include found no array"))

    arr = as.delete_at(ai)

    do_assert(as, 'included') { |e| arr.include?(e) }
  end

  def assert_hashy(*as)

    do_assert_ do

      as[0].to_a.all? { |k, v| k == v } ||
      "not hashy equal"
    end

    do_assert(as[0].to_a, 'hashy equal') { |k, v| k == v }
  end

  def assert_instance_of(*as)

    moc = as.find { |a| a.is_a?(Module) }
    as = as.delete(moc)

    do_assert(as, 'instance of') { |e| e.is_a?(moc) }
  end
  alias assert_is_a assert_instance_of

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

      assert_hashy(*as)

    elsif as.length == 1

      assert_truthy(*as)

    elsif count[:rexes] == 1 && count[:strings] == as.length - 1

      assert_match(*as)

    elsif count[:arrays] > 0

      assert_include(*as)

    else

      assert_equal(*as)
    end
  end

  protected

  def do_assert(as, msg, &block)

    do_assert_ do

      rs, ws = as.partition(&block)
      wi = ws.empty? ? -1 : as.index(ws.first)

      wi == -1 ? true :
      "not #{msg}: arg[#{wi}]: #{val_to_s(ws.first)}"
    end
  end

  def do_assert_(&block)

    Probatio.despatch(:assertion_enter, self, @__child)

    case r =
      begin; block.call; rescue => err; err; end

    when StandardError, Hash, String

      aerr = Probatio::AssertionError
        .new(r, @__child, *extract_file_and_line(caller))

      Probatio.despatch(:test_fail, self, @__child, aerr)

      raise aerr

    when Exception

      Probatio.despatch(:test_exception, self, @__child, r)

      raise r

    when :pending

      :pending

    else

      true
    end

  ensure

    #Probatio.despatch(:test_succeed, self, @__child)
    Probatio.despatch(:assertion_leave, self, @__child)
  end

  def extract_file_and_line(backtrace)

    l = backtrace.find { |l| ! l.index('lib/probatio/assertions.rb') }
    m = l && l.match(/([^:]+):(\d+)/)
    m && [ m[1], m[2].to_i ]
  end

  MAX_VS_LENGTH = 42

  def val_to_s(v)

    vs = v.inspect
    vs = vs[0, MAX_VS_LENGTH - 1] + '…' if vs.length > MAX_VS_LENGTH

    ">#{vs}<"
  end
end

