
#
# probatio.rb

module Probatio

  VERSION = '1.0.0'

  class << self

    def run(run_opts)

      root_group = Group.new('_', {})

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

      group.instance_eval(File.read(path))
    end
  end

  class Group

    def initialize(name, group_opts, &block)

      @name = name
      @group_opts = group_opts

      @children = []

      instance_eval(&block) if block
    end

    def run(run_opts)

puts "-" * 80
pp self
    end

    def before(name, opts={}, &block)
      @children << Before.new(name, opts, &block)
    end
    def after(name, opts={}, &block)
      @children << After.new(name, opts, &block)
    end
    def around(name, opts={}, &block)
      @children << Around.new(name, opts, &block)
    end

    def group(name, opts={}, &block)
      @children << Group.new(name, opts, &block)
    end
    def test(name, opts={}, &block)
      @children << Test.new(name, opts, &block)
    end
  end

  class Child
    attr_reader :name, :opts, :block
    def initialize(name, opts, &block)
      @name = name
      @opts = opts
      @block = block
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
  class Around < Child
    def run(run_opts)
    end
  end

  class Test < Child
    def run(run_opts)
    end
  end
end

