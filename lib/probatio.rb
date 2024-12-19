
#
# probatio.rb

require 'stringio'


module Probatio

  VERSION = '1.0.0'

  class << self

    def run(run_opts)

      root_group = Group.new(nil, '_', {}, __FILE__, nil)

      dir = run_opts[:dir]

      Dir[File.join(dir, '**', '*_helper.rb')].each do |path|

        read_helper_file(root_group, path)
      end

      Dir[File.join(dir, '**', '*_test.rb')].each do |path|

        read_test_file(root_group, path)
      end

      root_group.run(run_opts)
    end

    protected

    def read_helper_file(group, path)

      Kernel.load(path)
    end

    def read_test_file(group, path)

      group.add_file(path)
    end
  end

  class Group

    attr_reader :name
    attr_accessor :path

    def initialize(parent_group, name, group_opts, path, block)

      @parent = parent_group

      @name = name
      @group_opts = group_opts
      @path = path

      @children = []

      add_block(block)
    end

    def add_block(block)

      instance_eval(&block) if block
    end

    def add_file(path)

      @path = path

      instance_eval(File.read(path))
    end

    def to_s(opts={})

      out = opts[:out] || StringIO.new
      ind = opts[:indent] || ''
      gos = @group_opts.any? ? ' ' + @group_opts.inspect : ''

      out <<
        "#{ind}group #{@name.inspect}#{gos}\n"

      @children.each do |c|
        c.to_s(opts.merge(out: out, indent: ind + '  '))
      end

      opts[:out] ? nil : out.string
    end

    def run(run_opts)

#puts "-" * 80; pp self
puts "." * 80; puts self.to_s
#p [
#  :setups, setups.count, :tests, tests.count, :groups, groups.count,
#  :teardowns, teardowns.count ]
#      setups.each { |s| s.run(run_opts) }
#      tests.each { |t| t.run(run_opts) }
#      groups.each { |g| g.run(run_opts) }
#      teardowns.each { |d| d.run(run_opts) }

      run_opts[:results] ||= []

      setups.each { |s| s.run(run_opts) }

      tests.each do |t|

        befores.each { |b| b.run(run_opts) }

        t.run(run_opts)

        afters.each { |a| a.run(run_opts) }
      end

      groups.each { |g| g.run(run_opts) }

      teardowns.each { |s| s.run(run_opts) }

      p [ :results, run_opts[:results] ]
    end

    def setup(opts={}, &block)
      @children << Probatio::Setup.new(self, nil, opts, @path, block)
    end
    def teardown(opts={}, &block)
      @children << Probatio::Teardown.new(self, nil, opts, @path, block)
    end
    def before(opts={}, &block)
      @children << Probatio::Before.new(self, nil, opts, @path, block)
    end
    def after(opts={}, &block)
      @children << Probatio::After.new(self, nil, opts, @path, block)
    end

    def group(name, opts={}, &block)

      if g = @children.find { |e| e.is_a?(Probatio::Group) && e.name == name }
        g.path = @path
        g.add_block(block)
      else
        @children << Probatio::Group.new(self, name, opts, @path, block)
      end
    end

    def test(name, opts={}, &block)
      @children << Probatio::Test.new(self, name, opts, @path, block)
    end

    def befores

      (@parent ? @parent.befores : []) +
      @children.select { |c| c.is_a?(Probatio::Before) }
    end

    def afters

      (@parent ? @parent.afters : []) +
      @children.select { |c| c.is_a?(Probatio::After) }
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

  class Child

    attr_reader :name, :opts, :block

    def initialize(parent, name, opts, path, block)

      @parent = parent
      @name = name
      @opts = opts
      @path = path
      @block = block
    end

    def to_s(opts={})

      t = self.class.name.split('::').last.downcase
      n = @name ? ' ' + @name.inspect : ''
      os = @opts.any? ? ' ' + @opts.inspect : ''
      _, l = block.source_location

      (opts[:out] || $stdout) <<
        "#{opts[:indent]}#{t}#{n}#{os} #{@path}:#{l}\n"
    end

    def run(run_opts)

      @parent.instance_eval(&@block)
    end
  end

  class Setup < Child; end
  class Teardown < Child; end

  class Before < Child; end
  class After < Child; end

  class Test < Child

    def assert(value, &block)

      Probatio::Assertion.new(self, value, block)
    end
  end

  class Assertion

    def initialize(test, value, block)

      @test = test
      @value = value
      @block = block
    end
  end
end

