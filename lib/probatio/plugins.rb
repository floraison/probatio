
#
# probatio/plugins.rb

module Probatio::Colours

  protected

  def c; Probatio.c; end # colours or not...
end

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

  def total_duration

    @events.last.tstamp - @events.first.tstamp
  end

  def failed_tests; @events.select { |e| e.name == 'test_fail' }; end

  def test_count; @events.count { |e| e.name == 'test_leave' }; end
  def assertion_count; @events.count { |e| e.name == 'assertion_leave' }; end
  def failure_count; @events.count { |e| e.name == 'test_fail' }; end

  def pending_count

    @events.map(&:node).uniq.compact.select(&:pending?).count
  end

  def file_count

    @events.map(&:path).compact.uniq.count
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

module Probatio::SeedReporter

  def on_start(ev)

    puts
    puts "Run options: --seed #{Probatio.seed}"
    puts
  end
end

class Probatio::DotReporter

  include Probatio::Colours
  include Probatio::SeedReporter

  def on_test_succeed(ev)

    print c.dark_grey + '·' + c.reset
  end

  def on_test_fail(ev)

    print c.red + 'x' + c.reset
  end

  def on_test_pending(ev)

    print c.yellow + '.' + c.reset
  end
end

class Probatio::VanillaSummarizer

  def on_over(ev)

    c = Probatio.c # colours or not

    recorder = Probatio.plugins.find { |pl| pl.respond_to?(:failures) }
    return unless recorder

    if recorder.test_count == 0
      puts c.dark_grey + "  ¯\\_(ツ)_/¯" + c.reset
    else
      puts
    end

    recorder.failures.each do |ev|

      puts
      puts '-' * 80
      #puts ev.leaf.parent.to_s
      #puts ev.leaf.head
      puts ev.leaf.trail
      puts ev.depth
      puts ev.error.inspect
      puts '.'
      puts ev.to_s
    end
    puts '-' * 80 if recorder.failures.any?

    r = Probatio.recorder_plugin

    d = r.total_duration

    tc = r.test_count
    ac = r.assertion_count

    fc = r.failure_count; fc = Probatio.c.red(fc.to_s) if fc > 0
    pc = r.pending_count; pc = Probatio.c.yellow(pc.to_s) if pc > 0

    tpc = tc / d
    apc = ac / d

    fic = r.file_count

    puts
    print "Finished in #{Probatio.to_time_s(d)}, "
    print "%0.3f tests/s, %0.3f assertions/s." % [ tpc, apc ]
    puts
    puts
    print "#{tc} test#{s(tc)}, #{ac} assertion#{s(ac)}, "
    print "#{fc} failure#{s(fc)}, #{pc} pending, "
    print "#{fic} file#{s(fic)}."
    puts
    puts
  end

  protected

  def s(count); count == 1 ? '' : 's'; end
end

class Probatio::ProbaOutputter

  require 'rbconfig'

  def on_over(ev)

# TODO unplug if --mute or some switch like that...
    r = Probatio.recorder_plugin

    fls = Cerata.table_to_s(r.failed_tests.collect(&:to_h), '  ')

    rb = {}
    rb[:p] = File.join(
      RbConfig::CONFIG['bindir'],
      RbConfig::CONFIG['ruby_install_name'])
    rb[:d] = RUBY_DESCRIPTION
    rb[:l] = RUBY_PATCHLEVEL
      #
    #rb = Cerata.horizontal_h_to_s(rb)
    rb = Cerata.vertical_h_to_s(rb, '  ')

    env = Cerata.vertical_h_to_s(
      ENV.filter { |k, _|
        k.match?(/^(RUBY_|GEM_|(HOME|PATH|USER|SHELL|PWD)$)/) },
      '  ')

    File.open('.proba-output.rb', 'wb') do |o|
      o << "# .proba-output.rb\n"
      o << "{\n"
      o << "argv: " << Cerata.horizontal_a_to_s(ARGV) << ",\n"
      o << "failures:\n"
      #o << "  [\n"
      #fls.each { |fl| o << '  ' << fl << ",\n" }
      #o << "  ],\n"
      o << fls << ",\n"
      o << "duration: #{Probatio.to_time_s(r.total_duration).inspect},\n"
      o << "pversion: #{Probatio::VERSION.inspect},\n"
      o << "ruby:\n#{rb},\n"
      o << "some_env:\n#{env},\n"
      o << "}\n"
    end
  end
end

Probatio.plug(Probatio::Recorder.new)
Probatio.plug(Probatio::Chronometer.new)
Probatio.plug(Probatio::DotReporter.new)
Probatio.plug(Probatio::VanillaSummarizer.new)
Probatio.plug(Probatio::ProbaOutputter.new)

