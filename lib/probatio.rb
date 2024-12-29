
#
# probatio.rb

require 'set'
require 'stringio'
require 'colorato'

require 'probatio/more'


module Probatio

  VERSION = '1.0.0'

  class << self

    attr_reader :c # colours or not
    attr_reader :seed, :rng

    def mono?; !! @mono; end

    def run(run_opts)

      @c =
        run_opts[:mono] ? Colorato.no_colours :
        run_opts[:colour] ? Colorato.colours :
        ( ! $stdout.tty?) ? Colorato.no_colours :
        Colorato.colours

      @seed = run_opts[:seed]
      @rng = Random.new(@seed)

      Probatio.despatch(:pre, run_opts)

      #
      # construct tree

      root_group = Group.new(nil, __FILE__, '_', {}, nil)

      run_opts[:filez] = []
      run_opts[:filen] = []

      (run_opts[:dirs] || []).each do |dir|

        (
          Dir[File.join(dir, '**', '*_helper.rb')] +
          Dir[File.join(dir, '**', '*_helpers.rb')]
        ).each do |path|

          read_helper_file(root_group, path)
        end

        (
          Dir[File.join(dir, '**', '*_test.rb')] +
          Dir[File.join(dir, '**', '*_tests.rb')]
        ).each do |path|

          run_opts[:filez] << path

          read_test_file(root_group, path)
        end
      end

      (run_opts[:files] || []).each do |path|

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

      puts " r " + run_opts.inspect if $DEBUG

      #
      # run

      puts "---\n" + root_group.to_s + "\n---\n" if $DEBUG
      if run_opts[:print] then; puts root_group.to_s; exit 0; end

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

      puts '  ' + [ :despatch, en, ev.node && ev.node.full_name ].inspect \
        if $DEBUG

      @plugouts ||= @plugins.reverse

      (ev.leave? ? @plugouts : @plugins).each do |plugin|

        plugin.record(ev) if plugin.respond_to?(:record)
        plugin.send(me, ev) if plugin.respond_to?(me)
      end
    end

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
  end

  class Node

    attr_reader :parent, :path, :opts, :block, :children

    def initialize(parent, path, name, opts, block)

      @parent = parent
      @path = path
      @name = name
      @opts = opts
      @block = block

      @children = []
    end

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

      i = parent && parent.children.index(self)
      n = i && parent.children[i + 1]

      n ? n.line - 1 : 9_999_999
    end

    def location

      "#{@path}:#{line}"
    end

    def to_s(opts={})

      out = opts[:out] || StringIO.new
      opts1 = opts.merge(out: out)

      ind = '  ' * depth
      nam = @name ? ' ' + @name.inspect : ''
      nos = @opts.any? ? ' ' + @opts.inspect : ''
      pali = ' ' + location; pali = '' if pali.end_with?(':')

      out << "#{ind}#{type}#{nam}#{nos}#{pali}\n"

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

    protected

    def exclude?(run_opts); false; end
  end

  class Group < Node

    def path=(pat)

      @path0 ||= @path
      @path = pat
    end
      # so it can be set when groups are "re-opened"...

    def initialize(parent_group, path, name, opts, block)

      super(parent_group, path, name, opts, block)

      add_block(block)
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
        #shuffle(tests) + shuffle(groups) +
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

    def group(name, opts={}, &block)

      if g = @children.find { |e| e.is_a?(Probatio::Group) && e.name == name }
        g.path = @path
        g.add_block(block)
      else
        @children << Probatio::Group.new(self, @path, name, opts, block)
      end
    end

    def test(name, opts={}, &block)

      @children << Probatio::Test.new(self, @path, name, opts, block)
    end

    def befores

      (@parent ? @parent.befores : []) +
      @children.select { |c| c.is_a?(Probatio::Before) }
    end

    def afters

      (@parent ? @parent.afters : []) +
      @children.select { |c| c.is_a?(Probatio::After) }
    end

    ATTRS = %i[ @parent @name @group_opts @path @children ].freeze

    def context(h={})

      instance_variables
        .each { |k|
          h[k] = instance_variable_get(k) unless ATTRS.include?(k) }
      @parent.context(h) if @parent

      h
    end

    METHS = %i[ _group _setup _teardown _before _after _test ].freeze

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

    protected

    def setups; @children.select { |c| c.is_a?(Probatio::Setup) }; end
    def teardowns; @children.select { |c| c.is_a?(Probatio::Teardown) }; end

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

  class Test < Leaf

    alias group parent

    def run(run_opts)

      return Probatio.despatch(:test_excluded, self) \
        if exclude?(run_opts)

      return Probatio.despatch(:test_pending, self) \
        if opts[:pending]

      c = Probatio::Context.new(group)

      group.befores.each { |b| c.run(b, run_opts) }

      c.run(self, run_opts)

      group.afters.each { |a| c.run(a, run_opts) }
    end

    def skip?(run_opts)

      opts[:pending] ||
      exclude?(run_opts)
    end

    protected

    def exclude?(run_opts)

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
      path == fpath &&
        fline >= line && fline <= last_line
    end
  end

  class Context

    def initialize(group)

      group.context.each { |k, v| instance_variable_set(k, v) }
    end

    def run(child, run_opts)

      return Probatio.despatch("#{child.type}_pending", self, child, run_opts) \
        if child.opts[:pending]

      begin

        @__child = child

        Probatio.despatch("#{child.type}_enter", self, child, run_opts)

        r =
          run_opts[:dry] ? nil :
          instance_eval(&child.block)

        Probatio.despatch(:test_succeed, self, child) \
          if r != :pending && child.type == 'test'

      rescue AssertionError

        #Probatio.despatch(:test_fail, self, child)
          # done in the assertion implementation...

        # keeping calm and carrying on...

      ensure

        Probatio.despatch("#{child.type}_leave", self, child, run_opts)
      end
    end

    require 'probatio/assertions'
      #
      # where assert_* methods are defined...
  end

  class AssertionError < StandardError

    attr_reader :test, :file, :line
    attr_accessor :nested_error

    def initialize(error_or_message, test, file, line)

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
        when String, Exception then @error = d
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

