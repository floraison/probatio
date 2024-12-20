
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
    end

    def plugins; @plugins; end

    def plug(x)

      @plugins << x
    end

    def despatch(event_name, *details)

#p [ :despatch, event_name ]
      m = "on_#{event_name}"
      ev = Probatio::Event.new(event_name.to_sym, details)

      @plugins.each do |plugin|
        plugin.send(m, ev) if plugin.respond_to?(m)
      end
    end

    def monow; Process.clock_gettime(Process::CLOCK_MONOTONIC); end

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

    def to_s(opts={})

      out = opts[:out] || StringIO.new
      ind = opts[:indent] || ''
      nam = @name ? ' ' + @name.inspect : ''
      nos = @opts.any? ? ' ' + @opts.inspect : ''
      _, lin = @block.source_location
      out << "#{ind}#{type}#{nam}#{nos} #{@path}:#{lin}\n"

      @children.each do |c|
        c.to_s(opts.merge(out: out, indent: ind + '  '))
      end unless opts[:head]

      opts[:out] ? nil : out.string.strip
    end

    def head(opts={}); to_s(opts.merge(head: true)).strip; end
  end

  class Group < Node

    attr_accessor :path
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
    ensure
      Probatio.despatch("#{child.type}_leave", self, child, run_opts)
    end

    def assert(*as)

      do_assert do

        as.all? { |a| a == as[0] } ||
        "no equal"
      end
    end

    def assert_match(*as)

      do_assert do

        strings, others = as.partition { |a| a.is_a?(String) }
        rex = others.find { |o| o.is_a?(Regexp) } || strings.pop

        strings.all? { |s| s.match?(rex) } ||
        "no match"
      end
    end

    protected

    def do_assert(&block)

      r =
        begin
          block.call
        rescue => err
          err
        end

      if r.is_a?(StandardError) || r.is_a?(String)

        Probatio.despatch(:test_fail, self, @__child, r)

        fail AssertionError.new(r)

      elsif r.is_a?(Exception)

        raise r
      end

      Probatio.despatch(:test_succeed, self, @__child)

      true # end on a positive note...
    end
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

    attr_reader :tstamp
    attr_reader :name, :opts, :context, :group, :leaf, :error

    def initialize(name, details)

      @tstamp = Probatio.monow

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
  end
end

module Probatio::DotReporter

  class << self

    def on_start(ev)

      @successes = []
      @failures = []
    end

    def on_test_succeed(ev)

      print '.'
      @successes << ev
    end

    def on_test_fail(ev)

      print 'x'
      @failures << ev
    end

    def on_over(ev)

      puts
      @failures.each do |ev|
        puts "---"
        puts ev.leaf.parent.to_s
        puts ev.leaf.head
      end
    end
  end
end

Probatio.plug(Probatio::DotReporter)

