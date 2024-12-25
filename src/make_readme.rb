
#
# src/make_readme.rb

ls = File.readlines('src/README.md')

ls.each do |l|

  if m = l.match(/^READ\s+(!)?(.+)$/)

    if m[1] == '!'
      puts `#{m[2]}`.strip
    else
      puts File.read(m[2]).strip
    end

  else

    puts l
  end
end

