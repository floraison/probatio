
#
# probatio/plugins.rb

class Probatio::Recorder

  def record(ev)

    (@events ||= []) << ev
  end

  def failures

    @events.select { |ev| ev.name == 'test_fail' }
  end

  def successes

    @events.select { |ev| ev.name == 'test_succeed' }
  end
end

class Probatio::DotReporter

  def on_test_succeed(ev)

    print '.'
  end

  def on_test_fail(ev)

    print 'x'
  end
end

class Probatio::VanillaSummarizer

  def on_over(ev)

    recorder = Probatio.plugins.find { |pl| pl.respond_to?(:failures) }
    return unless recorder

    puts
    recorder.failures.each do |ev|
      puts "---"
      #puts ev.leaf.parent.to_s
      #puts ev.leaf.head
      puts ev.leaf.trail
      puts ev.depth
      puts ev.error.inspect
    end
  end
end

Probatio.plug(Probatio::Recorder.new)
Probatio.plug(Probatio::DotReporter.new)
Probatio.plug(Probatio::VanillaSummarizer.new)

