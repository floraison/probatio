
#
# probatio/more.rb

module Probatio; class << self

  def monow; @ts = Process.clock_gettime(Process::CLOCK_MONOTONIC); end
  def monow_and_delta; ts0, ts1 = @ts, monow; [ ts1, ts1 - (ts0 || ts1) ]; end

  def seconds_to_time_s(f)

    i = f.to_i
    d = i / (24 * 3600); i = i % (24 * 3600)
    h = i / 3600; i = i % 3600
    m = i / 60; i = i % 60
    s = i

    ms = ((
      f < 1 ? '%0.6f' :
      f < 60 ? '%0.3f' :
      ''
        ) % (f % 1.0))[2..-1] || ''
    ms = ms.insert(3, '_') if ms.length > 3

    [ d > 0 ? "#{d}d" : nil,
      h > 0 ? "#{h}h" : nil,
      m > 0 ? "#{m}m" : nil,
      "#{s}s",
      "#{ms}" ].compact.join('')
  end
  alias to_time_s seconds_to_time_s


  def to_rexes_and_strs(a)

    a && a.collect { |e| to_rex_or_str(e) }
  end

  def to_rex_or_str(s)

    m = s.match(/^\/(.+)\/([imx]*)$/); return s unless m

    pat = m[1]; opts = m[2]

    ropts = opts.each_char.inject(0) { |r, c|
      case c
      when 'i' then r |= Regexp::IGNORECASE
      #when 'm' then r |= Regexp::MULTILINE
      when 'x' then r |= Regexp::EXTENDED
      else r; end }

    Regexp.new(pat, ropts)
  end

  #def pp(h, out)
  #  out << "{\n"
  #  h.each do |k, v|
  #    out << k << ":\n"
  #    do_pp(v, '  ', out)
  #    out << "\n"
  #  end
  #  out << "}\n"
  #  nil
  #end

  #protected

  #def do_pp(x, indent, out)
  #  s0 = indent + x.inspect
  #  if s0.length < 80
  #    out << s0
  #  elsif x.is_a?(Array)
  #    x.each_with_index do |e, i|
  #    end
  #  end
  #end
end; end

