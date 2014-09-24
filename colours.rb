#!/usr/bin/env ruby

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
    red = (255 * red.to_f).to_i
    green = (255 * green.to_f).to_i
    blue = (255 * blue.to_f).to_i
  end
  hex = [red, green, blue].map {|n| to_hex(n) }.join
end

redf ||= red.to_f / 255
greenf ||= green.to_f / 255
bluef ||=  blue.to_f / 255

puts '#' + hex
puts "RGB (#{red}, #{green}, #{blue})"
puts "Red:#{redf} green:#{greenf} blue:#{bluef}"
