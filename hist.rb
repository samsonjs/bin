#!/usr/bin/env ruby
# Project  Name: None
# File / Folder: hist.rb
# File Language: ruby
# Copyright (C): 2006 heptadecagram
# First  Author: heptadecagram
# First Created: 2006.03.13 20:14:58
# Last Modifier: heptadecagram
# Last Modified: 2008.05.02

command = {}
execution = {}
$total = 0

IO.foreach('/Users/sjs/config/zsh/zhistory') do |line|
  line.chomp! =~ /^:\s\d+:\d+;((\S+).*)$/
  next if $1.nil? || $2.nil?
  execution[$1] = 1 + execution[$1].to_i
  command[$2] = 1 + command[$2].to_i
  $total += 1
end

puts $total

execution = execution.select {|a,b| b.to_f / $total > 0.01}
command = command.select {|a,b| b.to_f / $total > 0.01}

Max_length = execution.sort_by {|a| a[0].length }.reverse[0][0].length

def print_hash(hash)
	sorted = hash.sort {|a,b| b[1] <=> a[1] }
	sorted.each do |cmd,value|
		printf " %#{Max_length}s: %3d(%.2f%%)\n", cmd, value, value.to_f / $total
	end
end


puts "Executions:\n"
print_hash(execution)
puts "Commands:\n"
print_hash(command)
