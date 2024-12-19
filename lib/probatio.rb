
#
# probatio.rb

require 'stringio'


module Probatio

  VERSION = '1.0.0'

  class << self

    def run(run_opts)

      root_group = Group.new('_', {}, __FILE__, nil)

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

    def initialize(name, group_opts, path, block)

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
      gos = @group_opts = @group_opts.any? ? ' ' + @group_opts.inspect : ''

      out <<
        "#{ind}group #{@name.inspect}#{gos}\n"

      @children.each do |c|
        c.to_s(opts.merge(out: out, indent: ind + '  '))
      end

      opts[:out] ? nil : out.string
    end

    def run(run_opts)

puts "-" * 80
pp self
puts "." * 80
puts self.to_s
    end

    def before(name, opts={}, &block)
      @children << Probatio::Before.new(name, opts, @path, block)
    end
    def after(name, opts={}, &block)
      @children << Probatio::After.new(name, opts, @path, block)
    end

    def group(name, opts={}, &block)

      if g = @children.find { |e| e.is_a?(Probatio::Group) && e.name == name }
        g.path = @path
        g.add_block(block)
      else
        @children << Probatio::Group.new(name, opts, @path, block)
      end
    end

    def test(name, opts={}, &block)
      @children << Probatio::Test.new(name, opts, @path, block)
    end

    protected
  end

  class Child
    attr_reader :name, :opts, :block
    def initialize(name, opts, path, block)
      @name = name
      @opts = opts
      @path = path
      @block = block
    end
    def to_s(opts={})
      t = self.class.name.split('::').last.downcase
      os = @opts.any? ? ' ' + @opts.inspect : ''
      _, l = block.source_location
      (opts[:out] || $stdout) <<
        "#{opts[:indent]}#{t} #{name.inspect}#{os} #{@path}:#{l}\n"
    end
  end

  class Before < Child
    def run(run_opts)
    end
  end
  class After < Child
    def run(run_opts)
    end
  end

  class Test < Child
    def run(run_opts)
    end
    def assert(value, &block)
      Probatio::Assertion.new(block)
    end
    protected
  end

  class Assertion
    def initialize(value, block)
      @value = value
      @block = block
    end
  end
end

