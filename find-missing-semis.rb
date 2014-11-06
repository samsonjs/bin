#!/usr/bin/env ruby -w

require 'optparse'

USAGE_TEXT = "Usage: find-missing-semis.rb [options] <directory>"

Line = Struct.new(:num, :text)

def main
  options = parse_options
  dir = ARGV.first
  if File.directory?(dir)
    Dir[File.join(dir, '**/*.m')].each do |path|
      find_missing_semis(path, options[:fix])
    end
  else
    puts USAGE_TEXT
    exit 1
  end
end

def parse_options
  options = {
    fix: false,
  }
  OptionParser.new do |opts|
    opts.banner = USAGE_TEXT

    opts.on("-f", "--[no-]fix", "Insert missing semicolons automatically") do |f|
      options[:fix] = f
    end
  end.parse!
  options
end

def find_missing_semis(path, should_fix = false)
  num = 0
  pairs = []
  current_pair = nil
  File.readlines(path).each do |text|
    num += 1
    line = Line.new(num, text)
    if current_pair
      current_pair << line
      pairs << current_pair
    end
    current_pair = [line]
  end

  missing_semicolon_pairs = pairs.select do |l1, l2|
    l1.text =~ /^[-+]/ && l1.text !~ /;$/ && l2.text =~ /^\{/
  end
  missing_semicolon_pairs.each do |l1, l2|
    puts "Missing semicolon at #{path}:#{l1.num}: #{l1.text}"
    if should_fix
      l1.text = l1.text.chomp + ";\n"
    end
  end
  if should_fix && missing_semicolon_pairs.length > 0
    lines = pairs.map(&:first) + [pairs.last.last]
    text = lines.map(&:text).join
    File.open(path, 'w') do |f|
      f.print(text)
    end
  end
end

main if $0 == __FILE__
