
#
# probatio/plug.rb


module Probatio; class << self

  def plugins; @plugins; end

  def plug(x, position=:last)

    @plugins.insert(determine_plugin_pos(position), x)
    @plugouts = nil
  end

  def unplug(old)

    i =
      plug_index(old) ||
      fail(ArgumentError.new("Cannot locate plugin to remove"))

    @plugins.delete_at(i)
    @plugouts = nil
  end

  def replug(old, new)

    i =
      plug_index(old) ||
      fail(ArgumentError.new("Cannot locate plugin to replace"))

    @plugins[i] = new
    @plugouts = nil
  end

  protected

  def plugin_index(x)

    return x \
      if x.is_a?(Integer)
    return @plugins.index { |pl| pl.respond_to?(x) } \
      if x.is_a?(Symbol) || x.is_a?(String)

    i = @plugins.index(x); return i if i

    return @plugins.index { |pl| pl.is_a?(x) } if x.is_a?(Module)

    nil
  end
end; end

