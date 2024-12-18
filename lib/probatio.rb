
#
# probatio.rb

module Probatio

  VERSION = '1.0.0'

  class << self

    def run(run_opts)

      root_group = Group.new('_')

      Dir[File.join(opts[:dir], '**', '*_test.rb')].each do |path|

        read_file(root_group, path)
      end

      root_group.run(run_opts)
    end

    protected

    def read_file(group, path)
    end
  end

  class Group

    def initialize(name, group_opts)

      @name = name
      @group_opts = group_opts

      @children = []
    end

    def run(run_opts)
    end
  end

  class Test
  end
end

