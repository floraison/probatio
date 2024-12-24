
#
# probatio/plugins.rb

class Probatio::Recorder

  attr_reader :events

  def record(ev)

    (@events ||= []) << ev
  end

  def failures; @events.select { |ev| ev.name == 'test_fail' }; end
  def successes; @events.select { |ev| ev.name == 'test_succeed' }; end

  def test_leave_event(test_node)

    @events.find { |e|
      e.name == 'test_leave' &&
      e.node_full_name == test_node.full_name }
  end
end

module Probatio

  class << self

    def recorder_plugin

      @plugins.find { |pl| pl.respond_to?(:events) }
    end
  end
end

class Probatio::Chronometer

  def record(ev)

    # compute ev.leave_delta if ev is a "leave"

    if ev.enter?

      (@enters ||= []) << ev

    elsif ev.leave?

      e = @enters.pop

      fail "ev mismatch #{ev.name} vs #{e.name}" \
        if ( ! e) || (ev.type != e.type)

      ev.leave_delta = ev.tstamp - e.tstamp
    end
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
      puts "."
      puts ev.to_s
    end
  end
end

Probatio.plug(Probatio::Recorder.new)
Probatio.plug(Probatio::Chronometer.new)
Probatio.plug(Probatio::DotReporter.new)
Probatio.plug(Probatio::VanillaSummarizer.new)

