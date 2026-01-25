
#
# probatio/helpers.rb

module Probatio::Helpers

  def beep(count=1)

    Probatio.beep(count || 0)
  end

  def jruby?

    !! RUBY_PLATFORM.match?(/java/)
  end

  def windows?

    Gem.win_platform?
  end

  def time(&block)

    t0 = Probatio.monow

    block.call

    d = Probatio.monow - t0
    ds = Probatio.to_time_s(d)

    s, l = block.source_location

    puts(
      "\n" +
      Probatio.c.dark_grey +
      "time block at #{s}:#{l} took #{ds}" +
      Probatio.c.reset)
  end
end


class Probatio::Group

  include Probatio::Helpers
end

class Probatio::Section

  include Probatio::Helpers
end

class Probatio::Context

  include Probatio::Helpers
end

