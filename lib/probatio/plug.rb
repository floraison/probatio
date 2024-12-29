
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

  def determine_plugin_pos(pos)

    return pos if pos.is_a?(Integer)

    return 0 if pos == :first
    #return @plugins.length if pos == :last

    h = pos.is_a?(Hash) ? pos : {}

    l = @plugins.length

    if af = h[:after]
      (@plugins.index { |pl| pl == af || (pl.is_a?(af) rescue nil) } || l) + 1
    elsif bf = h[:before]
      (@plugins.index { |pl| pl == bf || (pl.is_a?(bf) rescue nil) } || l)
    else
      l # last resort, put at the end...
    end
  end
end; end

