
#
# probatio.rb

require 'pp'
require 'set'
require 'stringio'
require 'io/console'

require 'colorato'

require 'probatio/debug'
require 'probatio/more'


module Probatio

  VERSION = '1.1.0'

  class << self

    attr_reader :seed, :rng
    attr_reader :map

    def c; $_PROBATIO_COLOURS; end

    def run(run_opts)

      @seed = run_opts[:seed]
      @rng = Random.new(@seed)

      Probatio.despatch(:pre, run_opts)

      #
      # construct tree

      root_group = Group.new(nil, __FILE__, '_', {}, nil)

      run_opts[:dirs] ||= []
      run_opts[:files] ||= []

      run_opts[:filez] = []
      run_opts[:filen] = []

      helpers = locate(run_opts, '*_helper.rb', '*_helpers.rb')
      setups = locate(run_opts, 'setup.rb', '*_setup.rb')

      dbg_s do
        " / dirs:     #{run_opts[:dirs].inspect}\n" +
        " / files:    #{run_opts[:files].inspect}\n" +
        " / helpers:  #{helpers.inspect}\n" +
        " / setups:   #{setups.inspect}\n"
      end

      # helpers and setups...

      helpers.each do |path|

        read_helper_file(root_group, path)
      end

      setups.each do |path|

        run_opts[:filez] << path
        read_test_file(root_group, path)
      end

      # tests from dirs...

      run_opts[:dirs].each do |dir|

        ( Dir[File.join(dir, '**', '*_test.rb')] +
          Dir[File.join(dir, '**', '*_tests.rb')]

        ).each do |path|

          run_opts[:filez] << path
          read_test_file(root_group, path)
        end
      end

      # tests from files...

      run_opts[:files].each do |path|

        colons = path.split(':')
        fpath = colons.shift

        if colons.empty?
          run_opts[:filez] << path
        else
          colons.each do |lnum|
            lnum = lnum.match?(/^\d+$/) ? lnum.to_i : false
            run_opts[:filen] << [ fpath, lnum ] if lnum
          end
        end

        read_test_file(root_group, fpath)
      end

      run_opts[:filen] = rework_filen(root_group, run_opts)

      dbg_s { Cerata.vertical_h_to_s(run_opts, ' run_opts| ') }

      #
      # print or map

      if run_opts[:print]

        puts root_group.to_s

        exit 0
      end

      if run_opts[:map]

        root_group.map.each do |path, groups|
          puts ". #{Probatio.c.green(path)}"
          groups.each do |l0, l1, g|
            puts "  #{Probatio.c.dark_grey('%4d %4d')}  %s" % [ l0, l1, g.head ]
          end
        end

        exit 0
      end

      #
      # run

      dbg_s { "---\n" + root_group.to_s + "\n---\n" }

      Probatio.despatch(:start, root_group, run_opts)

      root_group.run(run_opts)

      Probatio.despatch(:over, root_group, run_opts)

      Probatio.despatch(:exit, root_group, run_opts)
        # some plugin will catch that and do `exit 0` or `exit 1`...
    end

    def init

      @read = Set.new

      @plugins = []
      @plugouts = nil
    end

    def despatch(event_name, *details)

#p [ :despatch, event_name ]
      en = event_name.to_sym
      me = "on_#{event_name}"
      ev = Probatio::Event.new(en, details)
#p [ :despatch, event_name, ev.delta ]

      dbg_m { '  ' + [ :despatch, en, ev.node && ev.node.full_name ].inspect }

      @plugouts ||= @plugins.reverse

      (ev.leave? ? @plugouts : @plugins).each do |plugin|

        plugin.record(ev) if plugin.respond_to?(:record)
        plugin.send(me, ev) if plugin.respond_to?(me)
      end
    end

    def epath; '.probatio-environments.rb'; end
    def opath; '.probatio-output.rb'; end
    def tpath; '.test-point'; end

    protected

    def read_helper_file(group, path)

      return if @read.include?(path); @read.add(path)

      Kernel.load(path)
    end

    def read_test_file(group, path)

      return if @read.include?(path); @read.add(path)

      group.add_file(path)
    end

    def rework_filen(root_group, run_opts)

      run_opts[:filen]
        .inject([]) { |a, fn| a.concat(rework_fn(root_group.map, fn)) }
    end

    def rework_fn(map, fn)

      fmap = map[fn[0]]
      fline = fn[1]

      n = fmap.find { |l0, l1, n| fline >= l0 && (fline <= l1 || l1 < 1) }

      return [ fn ] if n && n[2].is_a?(Probatio::Test)

      # we don't have a test...

      n2 = n[2]
      n2 = n2.parent unless n2.is_a?(Probatio::Group)

      # we have a group, lists all its tests located in the given file...

      n2.all_tests
        .select { |t| t.path == fn[0] }
        .collect { |t| t.path_and_line }
    end

    def locate(run_opts, *suffixes)

      (
        run_opts[:dirs].inject([]) { |a, d|
          a.concat(do_locate(d, suffixes)) } +
        run_opts[:files].inject([]) { |a, f|
          a.concat(do_locate(File.dirname(f), suffixes)) }
      ).uniq.sort
    end

    def do_locate(dir, suffixes)

      return [] if dir == '.'

      fs = suffixes
        .inject([]) { |a, suf| a.concat(Dir[File.join(dir, '**', suf)]) }

      fs.any? ? fs : do_locate(File.dirname(dir), suffixes)
    end
  end

  class Node

    attr_reader :parent, :path, :opts, :block, :children

    def root; @parent ? @parent.root : self; end
    def map; @parent ? @parent.map : (@map ||= {}); end

    def initialize(parent, path, name, opts, block)

      @parent = parent
      @path = path
      @name = name
      @opts = opts
      @block = block

      @children = []

      map_self
    end

    def filename; @filename ||= File.basename(@path); end

    def type; self.class.name.split('::').last.downcase; end
    def test?; type == 'test'; end

    def depth; parent ? parent.depth + 1 : 0; end

    def name; @name || type; end
    def array_name; parent ? parent.array_name + [ name ] : [ name ]; end
    def full_name; array_name.join(' '); end

    def pending?; @opts[:pending]; end

    def line

      (@block.respond_to?(:source_location) ? @block.source_location : [])[1]
    end

    def last_line

      lln = map[path].find { |l0, l1, n| n == self }

      l = lln && lln[1]
      l && l > 0 ? l : 9_999_999
    end

    def path_and_line

      [ @path, line ]
    end

    def location

      "#{@path}:#{line}"
    end

    def to_s(opts={})

      col = Probatio.c
      out = opts[:out] || StringIO.new
      opts1 = opts.merge(out: out)

      pali = location; pali = pali.chop if pali.end_with?(':')

      out << '  ' * depth
      out << col.yellow(type)
      out << (@name ? ' ' + @name.inspect : '')
      out << (@opts.any? ? ' ' + @opts.inspect : '')
      out << ' ' << col.dark_grey(pali)
      out << "\n"

      @children.each { |c| c.to_s(opts1) } unless opts[:head]

      opts[:out] ? nil : out.string.strip
    end

    def head(opts={}); to_s(opts.merge(head: true)).strip; end

    def trail(opts={})

      out = opts[:out] || StringIO.new
      opts1 = opts.merge(out: out, head: true)

      parent.trail(opts1) if parent
      to_s(opts1)

      opts[:out] ? nil : out.string.strip
    end

    def skip?(run_opts); false; end

    def groups

      @children.select { |c| c.is_a?(Probatio::Group) }
    end

    protected

    def exclude?(run_opts); false; end

    def map_self

      l =
        @block_source_location ? @block_source_location[1] :
        @block ? @block.source_location[1] :
        0

      f = (map[path] ||= [])

      f0 = f.last
      f0[1] = (l == 0 ? f0[0] : l - 1) if f0

      f << [ l, 0, self ]
    end
  end

  class Section < Node

    def path=(pat)

      @path0 ||= @path
      @path = pat
    end
      # so it can be set when groups are "re-opened"...

    def initialize(parent_group, path, name, opts, block)

      @block_source_location = block && block.source_location

      super(parent_group, path, name, opts, nil)

      parent_group.add_section(self, block) \
        if self.class == Probatio::Section
    end

    def add_block(block)

      instance_eval(&block) if block
    end

    def add_file(path)

      @path = path

      instance_eval(File.read(path), path, 1)
    end

    def run(run_opts)

      return Probatio.despatch(:group_excluded, self) \
        if exclude?(run_opts)

      return Probatio.despatch(:group_pending, self) \
        if opts[:pending]

      return Probatio.despatch(:group_skipped, self) \
        if skip?(run_opts)

      Probatio.despatch(:group_enter, self)

      (
        setups +
        shuffle(tests_and_groups) +
        teardowns
      ).each { |c| c.run(run_opts) }

      Probatio.despatch(:group_leave, self)
    end

    def setup(opts={}, &block)
      @children << Probatio::Setup.new(self, @path, nil, opts, block)
    end
    def teardown(opts={}, &block)
      @children << Probatio::Teardown.new(self, @path, nil, opts, block)
    end
    def before(opts={}, &block)
      @children << Probatio::Before.new(self, @path, nil, opts, block)
    end
    def after(opts={}, &block)
      @children << Probatio::After.new(self, @path, nil, opts, block)
    end
    def around(opts={}, &block)
      @children << Probatio::Around.new(self, @path, nil, opts, block)
    end

    def arounds

      (@parent ? @parent.arounds : []) +
      group_sections.select { |s| s.is_a?(Probatio::Around) } +
      @children.select { |c| c.is_a?(Probatio::Around) }
    end

    def befores

      (@parent ? @parent.befores : []) +
      group_sections.select { |s| s.is_a?(Probatio::Before) } +
      @children.select { |c| c.is_a?(Probatio::Before) }
    end

    def afters

      (
        (@parent ? @parent.afters : []) +
        group_sections.select { |c| c.is_a?(Probatio::After) } +
        @children.select { |c| c.is_a?(Probatio::After) }
      ).reverse
    end

    ATTRS = %i[ @parent @name @group_opts @path @children ].freeze

    def context(h={})

      fail ArgumentError.new('Probatio says "trailing RSpec context?"') \
        unless h.is_a?(Hash)

      instance_variables
        .each { |k|
          h[k] = instance_variable_get(k) unless ATTRS.include?(k) }
      @parent.context(h) if @parent

      h
    end

    METHS = %i[
      _group _section
        _setup _teardown _before _after
          _test
            ].freeze

    def method_missing(name, *args, &block)

      if METHS.include?(name)

        opts = args.find { |a| a.is_a?(Hash) }
        args << {} unless opts; opts = args.last
        opts[:pending] = true

        send(name.to_s[1..-1], *args, &block)

      else

        super
      end
    end

    def skip?(run_opts)

      opts[:pending] ||
      tests_and_groups.all? { |n| n.skip?(run_opts) }
    end

    def all_tests

      tests + groups.inject([]) { |a, g| a.concat(g.all_tests) }
    end

    def add_section(section, block)

      s = ((@sections ||= {})[section.name] ||= section)
      s.add_block(block)
    end

    protected

    def setups

      group_sections.select { |c| c.is_a?(Probatio::Setup) } +
      @children.select { |c| c.is_a?(Probatio::Setup) }
    end

    def teardowns

      group_sections.select { |c| c.is_a?(Probatio::Teardown) } +
      @children.select { |c| c.is_a?(Probatio::Teardown) }
    end

    def tests_and_groups

      @children.select { |c|
        c.is_a?(Probatio::Test) || c.is_a?(Probatio::Group) }
    end

    def tests; @children.select { |c| c.is_a?(Probatio::Test) }; end
    def groups; @children.select { |c| c.is_a?(Probatio::Group) }; end

    def shuffle(a)

      case Probatio.seed
      when 0 then a
      when -1 then a.reverse
      else a.shuffle(random: Probatio.rng)
      end
    end

    def section_drill

      (@parent ? @parent.section_drill : []) +
      (@sections || {}).values
    end

    def group_sections

      @_group_sections ||=
        section_drill
          .inject([]) { |a, s| a.concat(s.children) if s.name == name; a }
    end
  end

  class Group < Section

    def group(*names, &block)

      opts = names.last.is_a?(Hash) ? names.pop : {}

      names = names
        .collect { |s| s.to_s.split(/\s*(?:\||;|<|>)\s*/) }
        .flatten(1)

      last_name = names.last

      names.inject(self) do |g, name|

        gg = g.groups.find { |e| e.name == name }

        if gg
          gg.path = @path
        else
          gg = Probatio::Group.new(g, @path, name, opts, block)
          g.children << gg
        end

        gg.add_block(block) if name == last_name

        gg
      end
    end

    def section(name, opts={}, &block)

      @children << Probatio::Section.new(self, @path, name.to_s, opts, block) \
        unless opts[:pending]
    end

    def test(name, opts={}, &block)

      @children << Probatio::Test.new(self, @path, name.to_s, opts, block)
    end
  end

  class Leaf < Node

    def run(run_opts)

      return Probatio.despatch("#{type}_excluded", self) \
        if exclude?(run_opts)

      return Probatio.despatch("#{type}_pending", self) \
        if @opts[:pending]

      Probatio.despatch("#{type}_enter", self)

      @parent.instance_eval(&@block)

      Probatio.despatch("#{type}_leave", self)
    end
  end

  class Setup < Leaf; end
  class Teardown < Leaf; end

  class Before < Leaf; end
  class After < Leaf; end
  class Around < Leaf; end

  class Test < Leaf

    alias group parent

    def run(run_opts)

      return Probatio.despatch(:test_excluded, self) \
        if exclude?(run_opts)

      return Probatio.despatch(:test_pending, self) \
        if opts[:pending]

      Probatio::Context.new(group, self).run(run_opts)
    end

    def skip?(run_opts)

      opts[:pending] ||
      exclude?(run_opts)
    end

    protected

    def exclude?(run_opts)

      return true if in_setup?

      if incs = run_opts[:includes]
        return true unless incs.find { |e| do_match?(e) }
      elsif exes = run_opts[:excludes]
        return true if exes.find { |e| do_match?(e) }
      end

      fz = run_opts[:filez]
      return false if fz && fz.include?(@path)

      fns = run_opts[:filen]
      return true if fns && ! fns.find { |pa, li| path_and_line_match?(pa, li) }

      false
    end

    def do_match?(pattern_or_string)

      full_name.match?(pattern_or_string)
    end

    def path_and_line_match?(fpath, fline)

#p [ path, line, last_line, '<-->', fpath, fline ]
      line &&
        path == fpath &&
          fline >= line && fline <= last_line
    end

    def in_setup?

      filename == 'setup.rb' || filename.end_with?('_setup.rb')
    end
  end

  class Context

    attr_reader :__group
    attr_reader :__test

    def initialize(group, test)

      @__group = group
      @__test = test

      group.context.each { |k, v| instance_variable_set(k, v) }
    end

    def block; @__block; end

    def run(run_opts)

      _run(@__group.arounds + [ :do_run ], run_opts)
    end

    def __test_name; @__test.name; end
    def __group_name; @__group.name; end

    protected

    def _run(arounds, run_opts)

      if (ar = arounds.shift).is_a?(Probatio::Around)
        do_run(ar, run_opts) { _run(arounds, run_opts) }
      else
        @__group.befores.each { |bf| do_run(bf, run_opts) }
        do_run(@__test, run_opts)
        @__group.afters.each { |af| do_run(af, run_opts) }
      end
    end

    def do_run(child, run_opts, &block)

      fail ArgumentError.new("invalid child opts #{child.opts.inspect}") \
        unless child.opts.is_a?(Hash)

      return Probatio.despatch("#{child.type}_pending", self, child, run_opts) \
        if child.opts[:pending] || child.block.nil?

      begin

        @__child = child
        @__block = block

        Probatio.despatch("#{child.type}_enter", self, child, run_opts)

        r =
          run_opts[:dry] ? nil :
          instance_eval(&child.block)

        Probatio.despatch(:test_succeed, self, child) \
          if r != :pending && child.type == 'test'

      rescue AssertionError

        #Probatio.despatch(:test_fail, self, child)
          # done in the assertion implementation...

      rescue StandardError => serr

        class << serr; include Probatio::ExtraErrorMethods; end
        serr.test = child

        Probatio.despatch(:test_fail, self, child, serr)

      ensure

        Probatio.despatch("#{child.type}_leave", self, child, run_opts)
      end
    end

    require 'probatio/assertions'
      #
      # where assert_* methods are defined...

    require 'probatio/waiters'
      #
      # where wait_* methods are defined...
  end

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

      tw = Probatio.term_width - 4 - indent.length

      as =
        @arguments.find { |a| a.inspect.length > tw } ?
          @arguments.collect { |a|
            if (s0 = a.inspect).length < tw
              "\n#{indent}    " + s0
            else
              s1 = StringIO.new; PP.pp(a, s1, tw)
              qualify_argument(a) + "\n" +
              indent + s1.string.gsub(/^(.*)$/) { "    #{$1}" }
            end } :
        @arguments.collect(&:inspect)

      s = StringIO.new
      s << indent << @assertion << ':'
      as.each_with_index { |a, i| s << "\n#{indent}  %d: %s" % [ i, a ] }

      s.string
    end

    class << self

      def select_source_lines(path, line)

        File.readlines(path).each_with_index.to_a[line - 1..-1]
          .map { |l, i| [ i + 1, l.rstrip ] }
          .take_while { |_, l|
            l = l.strip
            l.length > 0 && l != 'end' && l != '}' }
      end
    end

    protected

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

  class Event

    attr_reader :tstamp, :delta
    attr_reader :name, :opts, :context, :group, :leaf, :error
    attr_accessor :leave_delta

    def initialize(name, details)

      @tstamp, @delta = Probatio.monow_and_delta

      @name = name.to_s

      details.each do |d|
        case d
        when Hash then @opts = d
        when Exception then @error = d
        when Probatio::Leaf then @leaf = d
        when Probatio::Group then @group = d
        when Probatio::Context then @context = d
        else fail ArgumentError.new("cannot fathom #{d.class} #{d.inspect}")
        end
      end
    end

    def direction; @direction ||= name.split('_').last.to_sym; end
    def node; @leaf || @group; end
    def depth; node.depth rescue 0; end

    def type; @name.split('_').first; end
      #
      # which, in the case of assertion != self.node.type ...

    def node_full_name; node && node.full_name; end

    def enter?; direction == :enter; end
    def leave?; direction == :leave; end

    def determine_leave_delta

      lev = Probatio.recorder_plugin.test_leave_event(node)

      lev && lev.leave_delta
    end

    def delta_s

      led = determine_leave_delta
      led ? Probatio.to_time_s(led) : '?'
    end

    def location

      (error && error.respond_to?(:location) && error.location) ||
      (node && node.location)
    end

    def path

      node && node.path
    end

    def to_s

      led = determine_leave_delta

      o = StringIO.new
      o << "<event"
      o << "\n  name=#{name.inspect}"
      o << "\n  node=#{node.full_name.inspect}" if node
      o << "\n  node_type=#{node.type.inspect}" if node
      o << "\n  error=#{error.to_s.inspect}" if error
      o << "\n  location=#{location.map(&:to_s).join(':').inspect}" if node
      o << "\n  delta=\"#{Probatio.to_time_s(delta)}\"" if delta
      o << "\n  leave_delta=\"#{Probatio.to_time_s(led)}\"" if led
      o << " />"

      o.string
    end

    def to_h

      { n: name, p: location[0], l: location[1], t: delta_s }
    end
  end
end


Probatio.init


require 'probatio/plug'
  #
  # when Probatio.plug and friends are defined

require 'probatio/plugins'
  #
  # plugins that listen to dispatches, report, and summarize

