
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
  def pending_count; @events.count { |e| e.name == 'test_pending' }; end

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
      puts c.dark_grey("  ¯\\_(ツ)_/¯")
    else
      puts
    end

    recorder.failures.each do |ev|

      #puts
      puts '-' * [ Probatio.term_width, 80 ].min
      #puts ev.leaf.parent.to_s
      #puts ev.leaf.head
      #puts ev.leaf.trail
      puts ev.error.trail
      puts
      #puts "%4d %s" % [ ev.error.line, c.dark_grey(ev.error.source_line) ]
      #puts c.dark_grey(ev.error.path)
      ev.error.source_lines.each do |i, l|
        puts "%4s %s" % [
          i == ev.error.line ? c.underlined(i.to_s) :
          i % 5 == 0 ? c.dark_grey(i.to_s) :
          c.white(i.to_s),
          i == ev.error.line ? c.yellow(l) : c.dark_grey(l) ]
      end
      puts; puts c.dark_grey(ev.error.summary('  '))
      #puts ev.error.inspect
      #puts '.'
      #puts ev.to_s
      #puts
    end
    #puts '-' * 80 if recorder.failures.any?

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

    flh = r.failed_tests.collect(&:to_h).each { |h| h.delete(:n) }
    fls = Cerata.table_to_s(flh, '  ')

    rb = {}
      #
    rv =
      File.exist?('.ruby-version') &&
      File.readlines('.ruby-version').find { |l| ! l.strip.start_with?('#') }
      #
    rb[:v] = ".ruby-version:#{rv.strip}" if rv
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

    File.open(Probatio.opath, 'wb') do |o|
      o << '# ' << Probatio.opath << "\n"
      o << "{\n"
      o << "argv: " << Cerata.horizontal_a_to_s(ARGV) << ",\n"
      o << "failures:\n"
      #o << "  [\n"
      #fls.each { |fl| o << '  ' << fl << ",\n" }
      #o << "  ],\n"
      o << fls << ",\n"
      o << "duration: #{Probatio.to_time_s(r.total_duration).inspect},\n"
      o << "probatio: { v: #{Probatio::VERSION.inspect} },\n"
      o << "ruby:\n#{rb},\n"
      o << "some_env:\n#{env},\n"
      o << "}\n"
    end
  end
end

module Probatio

  # For easy override...
  #
  def self._beep

    STDOUT.print("\a")
  end

  def self.beep(count=1)

    (count || 0).times { Probatio._beep; sleep 0.5 }
  end
end

class Probatio::Beeper

  def on_exit(ev)

    Probatio.beep(ev.opts[:beeps] || 0)
  end
end

class Probatio::Exitter

  def on_exit(ev)

    exit 1 if Probatio.recorder_plugin.failure_count > 0
    exit 0
  end
end

Probatio.plug(Probatio::Recorder.new)
Probatio.plug(Probatio::Chronometer.new)
Probatio.plug(Probatio::DotReporter.new)
Probatio.plug(Probatio::VanillaSummarizer.new)
Probatio.plug(Probatio::ProbaOutputter.new)
Probatio.plug(Probatio::Beeper.new)
Probatio.plug(Probatio::Exitter.new)

