#!/usr/bin/env ruby 

require 'date'
require 'json'

TIMES = JSON.parse(File.read(File.expand_path('../sun-yyj.json', __FILE__)))['sunsets']
SETTINGS = {
  'twilight' => 'sunrise',
  'sunrise'  => 'morning',
  'sunset'  => 'sunset',
  'night'  => 'night',
}

date = Date.today
month = date.month.to_s
day = date.day.to_s
if times = TIMES[month][day]
  time = Time.now
  hour, min = time.hour, time.min
  padded_min = min < 10 ? "0#{min}" : "#{min}"
  now = "#{hour}:#{padded_min}"
  if found = times.detect { |k, v| now == v }
    name = found[0]
    if setting = SETTINGS[name]
      puts "lights #{setting} - 3000"
      exec "lights #{setting} - 3000"
    else
      raise "Unsure how to change lights for \"#{name}\""
    end
  end
else
  raise "Cannot find today's date (#{date}) in times: #{times.inspect}"
end
