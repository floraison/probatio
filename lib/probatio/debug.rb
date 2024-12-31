
#
# probatio/debug.rb

module Probatio

  module DebugMethods

    def debug(*as, &block)

      return unless $DEBUG

      $stderr.print Probatio.c.green
      $stderr.puts(*as) if as.any?
      $stderr.puts block.call if block
      $stderr.print Probatio.c.reset
    end

    alias dbg debug
  end

  class << self

    include DebugMethods
  end
end

