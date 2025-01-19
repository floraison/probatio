
#
# probatio/mangle.rb

module Probatio

  class << self

    def mangle(dirs, files, switches)

      dry = switches['-y'] || switches['--dry']

      (
        dirs.collect { |d| Dir[File.join(d, '**', '*_spec.rb')] }.flatten +
        files.select { |f| f.match?(/_spec\.rb$/) }
      )
        .each do |path|

          puts c.dark_gray(". considering #{c.green(path)}")
          p1 = path[0..-8] + 'test.rb'
          puts c.dark_gray("  .. writing to #{c.light_green(p1)}")

          next if dry

          File.open(p1, 'wb') do |f|
            f.write(
              File.read(path)
                .gsub(/^(\s*)describe(\s+)/) { "#{$1}group#{$2}" }
                .gsub(/^(\s*)context(\s+)/) { "#{$1}group#{$2}" }
                .gsub(/^(\s*)it(\s+)/) { "#{$1}test#{$2}" }
                .gsub(/^(\s*)expect(\(|\s)/) { "#{$1}assert#{$2}" }
                .gsub(/\)\.to (eq|match)\(/) { ', ' }
                .gsub(/\n\s*, */) { ",\n" }
            )
          end

          puts c.dark_gray("    .. wrote to #{c.light_green(p1)}")
        end
    end
  end
end

