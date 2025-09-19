
#
# probatio/errors.rb

module Probatio

  class AssertionError < StandardError

    attr_reader :assertion, :arguments, :test, :file, :line
    attr_accessor :nested_error

    alias path file

    def initialize(assertion, arguments, error_or_message, test, file, line)

      @assertion = assertion
      @arguments = arguments

      @test = test

      @file = file
      @line = line

      if error_or_message.is_a?(String)
        @msg = error_or_message
      else
        @msg = "error while asserting: " + error_or_message.message
        @nested_error = error_or_message
      end

      super(@msg)
    end

    def location

      [ @file, @line ]
    end

    def loc

      location.map(&:to_s).join(':')
    end

    def to_s

      "#{self.class.name}: #{@msg}"
    end

    def trail

      @test.trail + "\n" +
      Probatio.c.red("#{'  ' * (test.depth + 1)}#{loc} --> #{@msg}")
    end

    def source_line

      @source_line ||=
        File.readlines(@file)[@line - 1]
    end

    def source_lines

      @source_lines ||=
        Probatio::AssertionError.select_source_lines(@file, @line)
    end

    def summary(indent='')

      nl = "\n" + indent

      tw = Probatio.term_width - 4 - indent.length

      as =
        @arguments.find { |a| a.inspect.length > tw } ?
          @arguments.collect { |a|
            if (s0 = a.inspect).length < tw
              nl + '    ' + s0 + "\n"
            else
              s1 = StringIO.new; PP.pp(a, s1, tw)
              qualify_argument(a) + "\n" +
              indent + s1.string.gsub(/^(.*)$/) { "    #{$1}" }
            end } :
        @arguments.collect(&:inspect)

      s = StringIO.new
      s << indent << @assertion << ':'

      case @arguments.collect(&:class)
      when [ Hash, Hash ]
        as.each_with_index { |a, i| s << nl << '  %d: %s' % [ i, a ] }
        output_hash_diff(indent, s)
      when [ String, String ]
        output_string_diff(indent, s)
      else
        as.each_with_index { |a, i| s << nl << '  %d: %s' % [ i, a ] }
      end

      s.string
    end

    class << self

      def select_source_lines(path, line)

        return [] unless path

        File.readlines(path).each_with_index.to_a[line - 1..-1]
          .map { |l, i| [ i + 1, l.rstrip ] }
          .take_while { |_, l|
            l = l.strip
            l.length > 0 && l != 'end' && l != '}' }
      end
    end

    protected

    def output_hash_diff(indent, s)

      nl = "\n" + indent

      c = Probatio.c

      d0 = @arguments[0].to_a - @arguments[1].to_a
      d1 = @arguments[1].to_a - @arguments[0].to_a

      dh = {}
        d0.each { |k, v| dh[k] = [ v, nil ] }
        d1.each { |k, v| dv = (dh[k] ||= [ nil, nil ]); dv[1] = v }

      s << nl << '  Hash diff:'
      dh.each do |k, (v0, v1)|
        s << nl << '    ' << c.yellow(k.inspect) << c.dg << ' =>'
        s << nl << '      ' << c.white(0) << c.dg << ': ' << v0.inspect
        s << " -- has_key? #{@arguments[0].has_key?(k)}" if v0 == nil
        s << nl << '      ' << c.white(1) << c.dg << ': ' << v1.inspect
        s << " -- has_key? #{@arguments[1].has_key?(k)}" if v1 == nil
      end
    end

    def output_string_diff(indent, s)

      nl = "\n"

      a0, a1 = @arguments

      sep = "\n" + ('-' * 63)
      c = Probatio.c

      s <<
        sep << " length: #{a0.length}\n" << c.yellow << a0 << c.dark_grey <<
        sep << " length: #{a1.length}\n" << c.yellow << a1 << c.dark_grey <<
        sep

      ls0, ls1 = @arguments.map(&:lines)

      diff = Diff::LCS.sdiff(ls0, ls1).collect(&:to_a)

      maxl = diff
        .inject([]) { |a, d| a << d[1][0]; a << d[2][0]; a }
        .max.to_s.length
      forl = "%0#{maxl}d"

      s << nl << c.dg << sep
      diff.each do |d|
        if d[0] == '='
          s << nl << c.dg << '= ' << (forl % d[1][0]) << ' ' << d[1][1].rstrip
        elsif d[0] == '+'
#s << nl << d.inspect
          s << nl << c.gn << '+ ' << (forl % d[2][0]) << ' ' << d[2][1].strip
        elsif d[0] == '-'
#s << nl << d.inspect
          s << nl << c.rd << '- ' << (forl % d[1][0]) << ' ' << d[1][1].strip
        else # '!'
          a, b = d[1], d[2]
          s << nl << c.y << '! ' << (forl % a[0]) << ' ' << a[1].strip
          s << nl << c.y << '  ' << (forl % b[0]) << ' ' << b[1].strip
        end
      end
      s << c.dg << sep << c.reset
    end

    def qualify_argument(a)

      '<' +
      a.class.to_s +
      (a.respond_to?(:size) ? " size:#{a.size}" : '') +
      '>'
    end
  end

  module ExtraErrorMethods

    attr_accessor :test

    def path; test.path; end
    def location; [ path, line ]; end
    def loc; location.map(&:to_s).join(':'); end

    def trail

      msg = "#{self.class}: #{self.message.inspect}"

      @test.trail + "\n" +
      Probatio.c.red("#{'  ' * (test.depth + 1)}#{loc} --> #{msg}")
    end

    def source_lines

      @source_lines ||=
        Probatio::AssertionError.select_source_lines(test.path, line)
    end

    def summary(indent='')

      o = StringIO.new

      o << self.class.name << ': ' << self.message.inspect << "\n"

      i = backtrace.index { |l| l.match?(/\/lib\/probatio\.rb:/) } || -1

      backtrace[0..i]
        .inject(o) { |o, l| o << indent << l << "\n" }

      o.string
    end

    def line

      backtrace.each do |l|

        ss = l.split(':')

        next unless ss.find { |e| e == test.path }
        return ss.find { |e| e.match?(/^\d+$/) }.to_i
      end

      -1
    end
  end
end

