#!/usr/bin/env ruby

hex = ''
rgb = []
red = green = blue = 0

if ARGV.size == 1
  hex = ARGV.first[0,1] == '#' ? ARGV.first[1..-1] : ARGV.first
  red = hex[0,2].to_i(16)
  green = hex[2,2].to_i(16)
  blue = hex[4,2].to_i(16)
  rgb = [red, green, blue]
elsif ARGV.size == 3
  rgb = ARGV[0..2]
  red,green,blue = *rgb
  hex = rgb.map {|n| n.to_i.to_s(16)}.join
end

puts '#' + hex
puts "RGB (#{red}, #{green}, #{blue})"
puts "Red:#{red.to_f/255} green:#{green.to_f/255} blue:#{blue.to_f/255}"
