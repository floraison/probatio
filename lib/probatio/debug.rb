
#
# probatio/debug.rb

module Probatio

  module DebugMethods

    def debug(*as, &block)

      return unless $_PROBATIO_DEBUG.include?(as.shift)

      $stderr.print $_PROBATIO_COLOURS.green
      $stderr.puts(*as) if as.any?
      $stderr.puts block.call if block
      $stderr.print $_PROBATIO_COLOURS.reset
    end

    def dbg_s(*as, &block)

      debug(:s, *as, &block)
    end

    def dbg_m(*as, &block)

      debug(:m, *as, &block)
    end
  end

  class << self

    include DebugMethods
  end
end

