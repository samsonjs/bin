#!/usr/bin/env ruby
#
# colours.rb - Convert between color formats (hex, RGB, UIColor)
#
# Converts between hex colors and RGB values, with output in multiple formats
# including CSS, UIColor (iOS/macOS), and normalized float values.
#
# Usage: colours.rb <hex-color>
#        colours.rb <red> <green> <blue>
#
# Examples:
#   colours.rb "#ff0000"
#   colours.rb ff0000
#   colours.rb 255 0 0
#   colours.rb 1.0 0.0 0.0

if ARGV.empty? || ARGV.include?('-h') || ARGV.include?('--help')
  puts "Usage: #{File.basename(__FILE__)} <hex-color>"
  puts "       #{File.basename(__FILE__)} <red> <green> <blue>"
  puts ""
  puts "Convert between color formats (hex, RGB, UIColor)"
  puts ""
  puts "Examples:"
  puts "  #{File.basename(__FILE__)} \"#ff0000\""
  puts "  #{File.basename(__FILE__)} ff0000"
  puts "  #{File.basename(__FILE__)} 255 0 0"
  puts "  #{File.basename(__FILE__)} 1.0 0.0 0.0"
  exit 0
end

hex = ''
rgb = []
red = green = blue = 0

def to_hex n
  s = n.to_i.to_s(16)
  s.length == 1 ? '0' + s : s
end

if ARGV.size == 1
  hex = ARGV.first[0,1] == '#' ? ARGV.first[1..-1] : ARGV.first
  red = hex[0,2].to_i(16)
  green = hex[2,2].to_i(16)
  blue = hex[4,2].to_i(16)
  rgb = [red, green, blue]
elsif ARGV.size == 3
  rgb = ARGV[0..2]
  red,green,blue = *rgb
  if red.index('.') || green.index('.') || blue.index('.')
    redf, greenf, bluef = red, green, blue
    red = (255 * red.to_f).round
    green = (255 * green.to_f).round
    blue = (255 * blue.to_f).round
  end
  hex = [red, green, blue].map {|n| to_hex(n) }.join
end

redf ||= red.to_f / 255
greenf ||= green.to_f / 255
bluef ||=  blue.to_f / 255

puts "Red: #{red} / #{redf}"
puts "Green: #{green} / #{greenf}"
puts "Blue: #{blue} / #{bluef}"
puts

puts '#' + hex
puts "rgb(#{red}, #{green}, #{blue})"
puts

if red == green && green == blue
  puts "[UIColor colorWithWhite:#{'%0.3g' % redf} alpha:1]"
  puts "UIColor(white: #{'%0.3g' % redf}, alpha: 1)"
end

puts "[UIColor colorWithRed:#{red}/255.0 green:#{green}/255.0 blue:#{blue}/255.0 alpha:1]"
puts "UIColor(red: #{red}/255.0, green: #{green}/255.0, blue: #{blue}/255.0, alpha: 1)"
