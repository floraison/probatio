
#
# probatio/reporters


class Probatio::Reporter

  def on_start(ev)

    @successes = []
    @failures = []
  end
end

class Probatio::DotReporter < Probatio::Reporter

  def on_start(ev)

    super(ev)
  end

  def on_test_succeed(ev)

    print '.'
    @successes << ev
  end

  def on_test_fail(ev)

    print 'x'
    @failures << ev
  end

  def on_over(ev)

    puts
    @failures.each do |ev|
      puts "---"
      #puts ev.leaf.parent.to_s
      #puts ev.leaf.head
      puts ev.leaf.trail
      puts ev.depth
      puts ev.error.inspect
    end
  end
end

Probatio.plug(Probatio::DotReporter.new)

