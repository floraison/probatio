
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
            File.readlines(path).each do |l|
              f.write(
                l
                  .gsub(/\A(\s*)describe(\s+)/) { "#{$1}group#{$2}" }
                  .gsub(/\A(\s*)context(\s+)/) { "#{$1}group#{$2}" }
                  .gsub(/\A(\s*)it(\s+)/) { "#{$1}test#{$2}" }
                  .gsub(/\A(\s*)expect(\(|\s)/) { "#{$1}assert#{$2}" }
                  .gsub(/\n?\)\.to (eq|match)\(/) { ', ' }
              )
            end
          end

          puts c.dark_gray("    .. wrote to #{c.light_green(p1)}")
        end
    end
  end
end

