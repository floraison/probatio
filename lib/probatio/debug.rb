
#
# probatio/debug.rb

module Probatio

  module DebugMethods

    def debug(*as, &block)

      return unless $DEBUG

      $stderr.print $_PROBATIO_COLOURS.green
      $stderr.puts(*as) if as.any?
      $stderr.puts block.call if block
      $stderr.print $_PROBATIO_COLOURS.reset
    end

    alias dbg debug
  end

  class << self

    include DebugMethods
  end
end

