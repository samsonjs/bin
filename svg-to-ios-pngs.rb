#!/usr/bin/env ruby -w

svg_path = ARGV.shift
png_path = ARGV.shift

png_test_path = "/tmp/identify.png"
File.unlink(png_test_path) if File.exist?(png_test_path)
puts `inkscape -z -e '#{png_test_path}' -d 72 '#{svg_path}'`
info = `identify '#{png_test_path}'`
File.unlink(png_test_path) if File.exist?(png_test_path)
dimensions = info.split[2]
width, height = dimensions.split('x').map(&:to_i)
if width == 0 || height == 0
  $stderr.puts "Failed to get SVG dimensions"
  exit 1
end

name = File.basename(svg_path).sub /\.svg$/, ''

png_2x_path = File.join(png_path, "#{name}@2x.png")
puts `inkscape -z -e '#{png_2x_path}' -w #{2 * width} -h #{2 * height} -d 72 '#{svg_path}'`

png_3x_path = File.join(png_path, "#{name}@3x.png")
puts `inkscape -z -e '#{png_3x_path}' -w #{3 * width} -h #{3 * height} -d 27 '#{svg_path}'`
