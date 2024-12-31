
#
# probatio/debug.rb

module Probatio

  module DebugMethods

    def debug(*as, &block)

      return unless $DEBUG

      print Probatio.c.green
      puts(*as) if as.any?
      puts block.call if block
      print Probatio.c.reset
    end

    alias dbg debug
  end

  class << self

    include DebugMethods
  end
end

