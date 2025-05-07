
#
# probatio/assertions.rb

class Probatio::Context

  # Beware: ws.any? returns false when ws == [ false ]

  def assert_nil(*as)

    do_assert(as, 'nil') { |a| a == nil }
  end

  def assert_not_nil(*as)

    do_assert(as, 'not nil') { |a| a != nil }
  end

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

  def assert_any(*as)

    do_assert(as, 'any') { |a| a.respond_to?(:size) && a.size > 0 }
  end

  def assert_empty(*as)

    do_assert(as, 'empty') { |a| a.respond_to?(:size) && a.size == 0 }
  end

  def assert_equal(*as)

    do_assert(as, 'equal') { |a| a == as[0] }
  end

  def assert_match(*as)

    strings, others = as.partition { |a| a.is_a?(String) }
    rex = others.find { |o| o.is_a?(Regexp) } || strings.pop

    do_assert(strings, 'matched') { |s| s.match?(rex) }
  end

  def assert_start_with(*as)

    fail ArgumentError.new(
      "assert_start_with expects strings, not #{x.inspect}") \
        if as.find { |a| ! a.is_a?(String) }

    sta = as.inject { |s, a| s.length < a.length ? s : a }

    do_assert(as.filter { |a| a != sta }, 'starting with') { |a|
      a.start_with?(sta) }
  end

  def assert_end_with(*as)

    fail ArgumentError.new(
      "assert_end_with expects strings, not #{x.inspect}") \
        if as.find { |a| ! a.is_a?(String) }

    sta = as.inject { |s, a| s.length < a.length ? s : a }

    do_assert(as.filter { |a| a != sta }, 'ending with') { |a|
      a.end_with?(sta) }
  end

  def assert_include(*as)

    ai =
      as.index { |a| a.is_a?(Array) } ||
      fail(ArgumentError.new("assert_include found no array"))

    arr = as.delete_at(ai)

    do_assert(as, 'included') { |e| arr.include?(e) }
  end

  def assert_size(*as)

    ai =
      as.index { |a| a.is_a?(Integer) && a >= 0 } ||
      fail(ArgumentError.new("assert_size found no integer >= 0"))

    sz = as.delete_at(ai)

    as = as.collect { |a| a.respond_to?(:size) ? a.size : a.class }

    do_assert(as, "size #{sz}") { |a| a == sz }
  end
  alias assert_count assert_size

  def assert_hashy(*as)

    do_assert(as[0].to_a, 'hashy equal') { |k, v| k == v }
  end

  def assert_instance_of(*as)

    moc = as.find { |a| a.is_a?(Module) }
    as.delete(moc)

    do_assert(as, 'instance of') { |e| e.is_a?(moc) }
  end
  alias assert_is_a assert_instance_of

  def assert_error(*as, &block)

    block = block || as.find { |a| a.is_a?(Proc) }
    as.delete(block)

    fail ArgumentError.new("assert_error expects a block or a proc") \
      unless block

    err = nil;
      begin; block.call; rescue => err; end

    return "no error raised" unless err.is_a?(StandardError)

    s = nil

    as.each do |a|

      s ||=
        case a
        when String
          if err.message != a
            msg = err.message.sub(/\s*Did you mean\?.+/, '')
            "error message #{msg.inspect} is not #{a.inspect}"
          else
            nil
          end
        when Regexp
          ! err.message.match(a) ?
            "error message #{err.message} did not match #{a.inspect}" : nil
        when Module
          ! err.is_a?(a) ?
            "error is of class #{err.class} not #{a.name}" : nil
        else
          fail ArgumentError.new("assert_error cannot fathom #{a.inspect}")
        end
    end

    do_assert_(as) { s }
  end

  def assert_not_error(*as, &block)

    block = block || as.find { |a| a.is_a?(Proc) }

    err = nil;
      begin; block.call; rescue => err; end

    do_assert_([]) {
      err && "no error expected but returned #{err.class} #{err.name}" }
  end
  alias assert_no_error assert_not_error

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

    #elsif count[:arrays] > 0
    #  assert_include(*as)

    else

      assert_equal(*as)
    end
  end

  protected

  def do_assert(as, msg, &block)

    do_assert_(as) do

      rs, ws = as.partition(&block)
      wi = ws.empty? ? -1 : as.index(ws.first)

      wi == -1 ? true :
      "not #{msg}: arg[#{wi}]: #{val_to_s(ws.first)}"
    end
  end

  def do_assert_(as, &block)

    Probatio.despatch(:assertion_enter, self, @__child)

    case r =
      begin; block.call; rescue => err; err; end

    when StandardError, Hash, String

      aerr = make_assertion_error(as, r)

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

  def make_assertion_error(arguments, result)

    Probatio::AssertionError
      .new(
        extract_assert_method(caller),
        arguments,
        result,
        @__child,
        *extract_file_and_line(caller))
  end

  def extract_file_and_line(backtrace)

    #l = backtrace.find { |l|
    #  ! l.index('lib/probatio/assertions.rb') &&
    #  ! l.index('_helper.rb') }
    l = backtrace.find { |l| l.index('_test.rb') }

    m = l && l.match(/([^:]+):(\d+)/)
    m && [ m[1], m[2].to_i ]
  end

  def extract_assert_method(backtrace)

    backtrace.inject(nil) { |r, l|
      r ||
      begin
        m = l.match(/[^a-zA-Z_](assert_[a-z0-9_]+)/)
        m && m[1]
      end }
  end

  MAX_VS_LENGTH = 42

  def val_to_s(v)

    vs = v.inspect
    vs = vs[0, MAX_VS_LENGTH - 1] + '…' if vs.length > MAX_VS_LENGTH

    ">#{vs}<"
  end
end

