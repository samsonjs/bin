#!/usr/bin/env ruby -w

require 'fileutils'

ADD_TO_ITUNES_DIR = File.expand_path('~/Music/iTunes/iTunes Media/Automatically Add to iTunes.localized')

def main
  root_dir =
    if ENV['TR_TORRENT_DIR']
      File.join(ENV['TR_TORRENT_DIR'], ENV['TR_TORRENT_NAME'])
    else
      ARGV.shift
    end

  if File.exists?(root_dir)
    puts "* Looking for archives in #{root_dir}..."
    extract_archives(root_dir)

    puts "* Encoding files in #{root_dir}..."
    encode_and_add_to_itunes(root_dir)
  elsif root_dir
    puts "file not found: #{root_dir}"
    exit 1
  else
    puts "error: expected directory in environment variable TR_TORRENT_DIR or as first argument"
    exit 2
  end
end

def extract_archives(dir)
  Dir.foreach(dir) do |filename|
    next if filename == '.' || filename == '..'
    path = File.join(dir, filename)
    if File.directory?(path)
      extract_archives(path)
    elsif filename =~ /\.rar$/
      pwd = Dir.pwd
      Dir.chdir(dir)
      puts "* Extracting #{filename}..."
      `unrar x '#{filename}'`
      Dir.chdir(pwd)
    end
  end
end

def encode_and_add_to_itunes(dir)
  Dir.foreach(dir) do |filename|
    next if filename == '.' || filename == '..'
    path = File.join(dir, filename)
    if File.directory?(path)
      # puts "* Descending into #{path}..."
      encode_and_add_to_itunes(path)
    else
      encoded_path = encode(File.expand_path(dir), filename)
      if encoded_path == :noencode
        puts "* No encoding required for #{path}, adding to iTunes"
        add_to_itunes(path)
      elsif encoded_path
        puts "* Encoded as #{encoded_path}, adding to iTunes"
        add_to_itunes(encoded_path)
        File.unlink(encoded_path)
      else
        # skipped or failed
      end
    end
  end
end

def add_to_itunes(path)
  FileUtils.cp(path, ADD_TO_ITUNES_DIR)
  puts "* Copied #{path} to #{ADD_TO_ITUNES_DIR}"
end

def encode(dir, filename)
  ext = File.extname(filename)
  encoded_path =
    case ext
    when '.m4v', '.mp4', '.mp3', '.m4a'
      :noencode
    when '.mkv'
      # fall back to ffmpeg since the MKV conversion can't handle very many audio formats
      encode_mkv(dir, filename, ext) || encode_video(dir, filename, ext)
    when '.mpg', '.mpeg', '.avi', '.xvid'
      encode_video(dir, filename, ext)
    else
      # puts "* Skipped unknown file type: #{path}"
    end

  encoded_path
end

def encode_mkv(dir, filename, ext)
  encoded_filename = encoded_filename(filename, ext)
  encoded_path = File.join('/tmp', encoded_filename)
  if File.exists?(encoded_path)
    # TODO: option to skill all or remove
    puts "* Skipping #{filename}, it is already encoded"
    encoded_path
  else
    puts "* Converting MKV to MPEG4: #{filename} -> #{encoded_filename}"
    pwd = Dir.pwd
    Dir.chdir('/tmp')
    path = File.join(dir, filename)
    `convert-mkv-to-mp4.sh '#{path}'`
    if $?.success?
      encoded_path
    else
      puts "!! Failed to encode #{filename}"
    end
  end

ensure
  Dir.chdir(pwd) if pwd
end

def encode_video(dir, filename, ext)
  encoded_filename = encoded_filename(filename, ext)
  encoded_path = File.join('/tmp', encoded_filename)
  if File.exists?(encoded_path)
    # TODO: option to skill all or remove
    puts "* Skipping #{filename}, it is already encoded"
    encoded_path
  else
    puts "* Converting #{ext.sub('.', '').upcase} to MPEG4 with ffmpeg: #{filename} -> #{encoded_filename}"
    pwd = Dir.pwd
    Dir.chdir('/tmp')
    path = File.join(dir, filename)
    `ffmpeg -i '#{path}' -vcodec libx264 -r 24 -acodec libfaac '#{encoded_filename}'`
    if $?.success?
      encoded_path
    else
      puts "!! Failed to encode #{filename}"
    end
  end

ensure
  Dir.chdir(pwd) if pwd
end

def encoded_filename(filename, ext)
  filename.sub(/#{ext}$/, '.mp4')
end

main if $0 == __FILE__
