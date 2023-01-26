#!/usr/bin/env ruby -w

require 'csv'

HEADERS = %w[device_name sessions].freeze

DEVICES_PATH = File.join(__dir__, 'supported_devices.csv')

# Maps device model to name using Google's giant CSV that lives alongside this file.
DEVICE_MAP = CSV.foreach(DEVICES_PATH).each_with_object({}) do |row, map|
  # skip the first header row
  next if row[0] == 'Retail Branding'

  # columns: Retail Branding (maker), Marketing Name, Device (unused), Model
  maker = row[0]
  name = row[1]
  model = row[3]
  map[model] = "#{maker} #{name}"
end

def main
  in_csv = CSV.new(ARGF)
  sessions_by_device = count_devices(in_csv)
  render_csv(sessions_by_device)
end

def zero_hash
  Hash.new { |_k, _v| 0 }
end

def count_devices(in_csv)
  # skip the first header row
  in_csv.drop(1).each_with_object(zero_hash) do |row, h|
    # devices come in a raw model and we have to look up the marketing name for each one
    # e.g. SM-S908N and SM-S908U are 2 of 9 models of the Galaxy S22 Ultra line
    device_model = row[0]
    device_name = DEVICE_MAP[device_model] || device_model

    # Skip things that are obviously not Android
    next if device_name =~ /iphone|ipad/i

    h[device_name] += 1
  end
end

def render_csv(sessions_by_device)
  puts CSV.generate_line(HEADERS)
  sessions_by_device
    .sort_by { |_device, sessions| sessions }
    .reverse
    .each do |device_name, sessions|
      out_row = [device_name, sessions]
      puts CSV.generate_line(out_row)
    end
end

main if $PROGRAM_NAME == __FILE__
