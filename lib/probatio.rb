
#
# probatio.rb

require 'stringio'


module Probatio

  VERSION = '1.0.0'

  class << self

    def run(run_opts)

      Probatio.despatch(:start, run_opts)

      root_group = Group.new(nil, __FILE__, '_', {}, nil)

      dir = run_opts[:dir]

      Dir[File.join(dir, '**', '*_helper.rb')].each do |path|

        read_helper_file(root_group, path)
      end

      Dir[File.join(dir, '**', '*_test.rb')].each do |path|

        read_test_file(root_group, path)
      end

      root_group.run(run_opts)

      Probatio.despatch(:over, run_opts)
    end

    def init

      @plugins = []
      @plugouts = nil
    end

    def plugins; @plugins; end

    def plug(x)

      @plugins << x
      @plugouts = nil
    end

    def despatch(event_name, *details)

#p [ :despatch, event_name ]
      m = "on_#{event_name}"
      ev = Probatio::Event.new(event_name.to_sym, details)
#p [ :despatch, event_name, ev.delta ]
p [ :despatch, event_name, (ev.node.full_name rescue nil) ]

      @plugouts ||= @plugins.reverse

      (ev.direction == :leave ? @plugins : @plugouts).each do |plugin|

        plugin.record(ev) if plugin.respond_to?(:record)
        plugin.send(m, ev) if plugin.respond_to?(m)
      end
    end

    def monow; @ts = Process.clock_gettime(Process::CLOCK_MONOTONIC); end
    def monow_and_delta; ts0, ts1 = @ts, monow; [ ts1, ts1 - (ts0 || ts1) ]; end

    protected

    def read_helper_file(group, path)

      Kernel.load(path)
    end

    def read_test_file(group, path)

      group.add_file(path)
    end
  end

  self.init

  class Node

    attr_reader :parent, :path, :name, :opts, :block, :children

    def initialize(parent, path, name, opts, block)

      @parent = parent
      @path = path
      @name = name
      @opts = opts
      @block = block

      @children = []
    end

    def type; self.class.name.split('::').last.downcase; end

    def depth; parent ? parent.depth + 1 : 0; end

    def name; @name || type; end
    def array_name; parent ? parent.array_name + [ name ] : [ name ]; end
    def full_name; array_name.join(' '); end

    def to_s(opts={})

      out = opts[:out] || StringIO.new
      opts1 = opts.merge(out: out)

      ind = '  ' * depth
      nam = @name ? ' ' + @name.inspect : ''
      nos = @opts.any? ? ' ' + @opts.inspect : ''
      _, li = @block.source_location rescue nil
      pali = @path ? " #{@path}:#{li}" : ''

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

      instance_eval(File.read(path))
    end

    def run(run_opts)

      Probatio.despatch(:group_enter, self)

      setups.each { |s| s.run(run_opts) }

      tests.each do |t|

        c = Probatio::Context.new(self)

        befores.each { |b| c.run(b, run_opts) }

        c.run(t, run_opts)

        afters.each { |a| c.run(a, run_opts) }
      end

      groups.each { |g| g.run(run_opts) }

      teardowns.each { |s| s.run(run_opts) }

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

    protected

    def setups; @children.select { |c| c.is_a?(Probatio::Setup) }; end
    def teardowns; @children.select { |c| c.is_a?(Probatio::Teardown) }; end

    def test_and_groups
      @children.select { |c|
        c.is_a?(Probatio::Test) || c.is_a?(Probatio::Group) }
    end
    def tests; @children.select { |c| c.is_a?(Probatio::Test) }; end
    def groups; @children.select { |c| c.is_a?(Probatio::Group) }; end
  end

  class Leaf < Node

    def run(run_opts)

      Probatio.despatch("#{type}_enter", self)

      @parent.instance_eval(&@block)

      Probatio.despatch("#{type}_leave", self)
    end
  end

  class Setup < Leaf; end
  class Teardown < Leaf; end

  class Before < Leaf; end
  class After < Leaf; end

  class Test < Leaf; end

  class Context

    def initialize(group)

      group.context.each { |k, v| instance_variable_set(k, v) }
    end

    def run(child, run_opts)

      @__child = child

      Probatio.despatch("#{child.type}_enter", self, child, run_opts)

      instance_eval(&child.block)

    rescue AssertionError => aerr

      # keeping calm and carrying on...

    ensure

      Probatio.despatch("#{child.type}_leave", self, child, run_opts)
    end

    require 'probatio/assertions'
      #
      # where assert_* methods are defined...
  end

  class AssertionError < StandardError

    attr_accessor :nested_error

    def initialize(error_or_message)

      if error_or_message.is_a?(String)
        super(message)
      else
        super("error while asserting: " + error_or_message.message)
        @nested_error = error_or_message
      end
    end
  end

  class Event

    attr_reader :tstamp, :delta
    attr_reader :name, :opts, :context, :group, :leaf, :error

    def initialize(name, details)

      @tstamp, @delta = Probatio.monow_and_delta

      @name = name

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

    def direction; name.to_s.end_with?('_leave') ? :leave : :enter; end
    def node; @leaf || @group; end
    def depth; node.depth rescue 0; end
  end
end

require 'probatio/reporters'
  #
  # reporters are plugins that listen to dispatches and report

