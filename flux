#!/usr/bin/env ruby 

require 'date'
require 'json'
require 'optparse'

TIMES = JSON.parse(File.read(File.expand_path('../sun-yyj.json', __FILE__)))['times']
USAGE_TEXT = "Usage: flux [options]"

def main
  options = parse_options
  flux(options)
end

def parse_options
  options = {
    dry_run: false,
    set_current: false,
  }
  OptionParser.new do |opts|
    opts.banner = USAGE_TEXT

    opts.on("-n", "--dry-run", "Don't actually change the lights") do |dry_run|
      options[:dry_run] = dry_run
    end
    opts.on("-c", "--set-current", "Change the lights to the setting that should currently be active") do |current|
      options[:set_current] = current
    end
  end.parse!
  options
end

def flux(options)
  date = Date.today
  month = date.month.to_s
  day = date.day.to_s
  if times = TIMES[month][day]
    times['midnight'] = '22:30'
    puts "sunrise: #{times['sunrise']}"
    puts "morning: #{times['morning']}"
    puts "sunset: #{times['sunset']}"
    puts "night: #{times['night']}"
    puts "midnight: #{times['midnight']}"

    time = Time.now
    hour, min = time.hour, time.min
    padded_min = min < 10 ? "0#{min}" : "#{min}"
    now = "#{hour}:#{padded_min}"
    puts "current time: #{now}"
    found =
      if options[:set_current]
        now = now.sub(':', '').to_i
        if k = times.keys.select { |k| now >= times[k].sub(':', '').to_i }.last
          [k, times[k]]
        end
      else
        times.detect { |k, v| now == v }
      end
    if found
      setting = found[0]
      puts "> exec lights #{setting} - 300"
      exec "lights #{setting} - 300" unless options[:dry_run]
    end
  else
    raise "Cannot find today's date (#{date}) in times: #{TIMES.inspect}"
  end
end

main if $0 == __FILE__
