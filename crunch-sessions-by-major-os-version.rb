#!/usr/bin/env ruby -w

require 'csv'

HEADERS = %w[version sessions].freeze

in_csv = CSV.new(ARGF)
is_header = true

zero_hash = Hash.new { |k, v| 0 }
sessions_by_version = in_csv.inject(zero_hash) do |h, row|
  if is_header
    is_header = false
    next h
  end

  version = row[1]
  sessions = row[2].to_i
  major_version = version.split('.').first
  h[major_version] += sessions
  h
end

puts CSV.generate_line(HEADERS)
sessions_by_version.keys.map(&:to_i).sort.each do |version|
  out_row = [version, sessions_by_version[version.to_s]]
  puts CSV.generate_line(out_row)
end
