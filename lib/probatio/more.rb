
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
end; end


module Cerata; class << self

  # TODO deal with double width characters...

  def horizontal_a_to_s(a, indent='')

    o = StringIO.new

    o << indent << '[ '
    a1 = a.dup; while e = a1.shift
      o << e.inspect
      o << ', ' if a1.any?
    end
    o << ' ]'

    o.string
  end

  def horizontal_h_to_s(h, indent='')

    o = StringIO.new

    o << indent << '{ '
    kvs = h.to_a; while kv = kvs.shift
      o << "#{kv.first}: " << kv[1].inspect
      o << ', ' if kvs.any?
    end
    o << ' }'

    o.string
  end

  def vertical_h_to_s(h, indent='')

    o = StringIO.new

    o << indent << "{\n"
    h.each { |k, v| o << indent << "#{k}: " << v.inspect << ",\n" }
    o << indent << '}'

    o.string
  end

  # A "table" here is an array of hashes
  #
  def table_to_s(a, indent='')

    all_keys =
      a.collect { |h| h.keys }.flatten.uniq.map(&:to_s)
    key_widths =
      all_keys.inject({}) { |h, k| h[k] = k.length; h }
    val_widths =
      a.inject({}) { |w, h|
        h.each { |k, v| k = k.to_s; w[k] = [ w[k] || 0, v.inspect.length ].max }
        w }

    o = StringIO.new

    o << indent << "[\n"

    a.each do |h|
      o << indent << '{ '
      kvs = h.to_a; while kv = kvs.shift
        k, v = kv[0].to_s, kv[1].inspect
        kl, vl = key_widths[k], val_widths[k]
        kf = "%#{kl}s"
        vf = v.start_with?('"') ? "%#{vl}s" : "%-#{vl}s"
        o << ("#{kf}: #{vf}" % [ k, v ])
        o << ', ' if kvs.any?
      end
      o << " },\n"
    end

    o << indent << ']'

    o.string
  end
end; end

