
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
end

class Probatio::Section

  include Probatio::Helpers
end

class Probatio::Context

  include Probatio::Helpers
end

