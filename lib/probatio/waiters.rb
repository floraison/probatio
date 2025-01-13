
#
# probatio/waiters.rb

module Probatio::Waiters

  def wait_until(opts={}, &block)

    timeout = opts[:timeout] || 14
    frequency = opts[:frequency] || 0.1

    start = Probatio.monow

    loop do

      sleep(frequency)

      #return if block.call == true
      r = block.call
      return r if r

      break if Probatio.monow - start > timeout
    end

    fail "timeout after #{timeout}s"
  end
  alias wait_for wait_until
end

class Probatio::Section

  include Probatio::Waiters
end

class Probatio::Context

  include Probatio::Waiters
end

