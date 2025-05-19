
#
# probatio/helpers.rb

module Probatio::Helpers

  def beep(count=1)

    Probatio.beep(count || 0)
  end
end

class Probatio::Section

  include Probatio::Helpers
end

class Probatio::Context

  include Probatio::Helpers
end

