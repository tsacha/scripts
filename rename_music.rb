#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'
require 'shellwords'

def rename(options,file,tags)
  ext = file.split('.')[-1]

  if tags["artist"].nil?
    raise "#{File.absolute_path(file)} has not an artist tag"
  end

  if tags["album"].nil?
    raise "#{File.absolute_path(file)} has not an album tag"
  end

  if tags["date"].nil?
    raise "#{File.absolute_path(file)} has not a date tag"
  end

  if tags["tracknumber"].nil?
    raise "#{File.absolute_path(file)} has not a tracknumber tag"
  end

  if tags["title"].nil?
    raise "#{File.absolute_path(file)} has not a title tag"
  end

  tags["tracknumber"] = tags["tracknumber"].gsub(/^([0-9])$/,'0\1')
  tags["title"] = tags["title"].gsub(/\//,'\\')
  tags["date"] = tags["date"].split("-")[0]
  tags["discnumber"] = "1" if tags["discnumber"].nil?

  target_dir = Dir.pwd+"/"+tags["artist"]+"/"+tags["date"]+" - "+tags["album"]+"/Disc "+tags["discnumber"]
  target_file = tags["tracknumber"]+" - "+tags["title"]+"."+ext

  if not File.exists? target_dir and not File.directory? target_dir
    if not options[:try]
      FileUtils.mkdir_p target_dir
    end
    puts "\e\[34mmkdir -p #{target_dir}\e[0m" if options[:verbose]
  end
  
  if not File.exists? target_dir+"/"+target_file
    if not options[:try]
      `git mv #{Shellwords.escape(file)} #{Shellwords.escape(target_dir)}/#{Shellwords.escape(target_file)}`
    end
    puts "\e\[32mgit mv #{Shellwords.escape(file)} #{Shellwords.escape(target_dir)}/#{Shellwords.escape(target_file)}\e[0m" if options[:verbose]
  end
end

begin
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: rename_music.rb [options]"

    options[:try] = false
    opts.on("-n", "--noop", "Dry run") do |noop|
      options[:try] = noop
    end

    options[:verbose] = false
    opts.on("-v", "--verbose", "Verbose output") do |verbose|
      options[:verbose] = verbose
    end

    opts.on("-f", "--folder FOLDER", String, "Folder where operate") do |folder|
      options[:folder] = folder
    end

    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end

  optparse.parse!
  raise OptionParser::MissingArgument if options[:folder].nil?

  Dir.chdir(options[:folder])
  Dir.glob("**/*").each do |file|
    file = File.absolute_path(file)
    if File.file?(file)
      ext = file.split('.')[-1]
      if ext == "mp3"
        tags = {}

        mp3 = `eyeD3 --no-color #{Shellwords.escape(file)} 2> /dev/null`
        raise "#{Shellwords.escape(file)} is not a correct file" if $? != 0

        mp3.each_line do |tag|
          data = tag.scan /^([a-z ]+): (.*?)\t*$/
          if not data.empty?
            key = data[0][0]
            if key == "recording date" then tags["date"] = data[0][1]
            elsif key == "track" then tags["tracknumber"] = data[0][1]
            else tags[key] = data[0][1]
            end
          end
        end
        rename(options,file,tags)
      elsif ext == "flac"
        flac = `metaflac --show-tag=ARTIST --show-tag=ALBUM --show-tag=DATE --show-tag=DISCNUMBER --show-tag=TRACKNUMBER --show-tag=TITLE #{Shellwords.escape(file)} 2> /dev/null`
        raise "#{Shellwords.escape(file)} is not a correct file" if $? != 0

        tags = {}
        flac.each_line do |tag|
          type = tag.split("=")
          tags[type.shift.downcase] = type.join("=")[0..-2]
        end
        rename(options,file,tags)
      else
        if file[-5..-1] != "README" then
          if not options[:try]
            File.delete(file)
          end
          puts "\e\[31mrm #{file}\e[0m" if options[:verbose]
        end
      end
    end
  end

  Dir['**/'].reverse_each { |d| 
    if Dir.entries(d).size == 2
      if not options[:try]
        Dir.rmdir d
      end
      puts "\e\[31mrmdir #{File.absolute_path(d)}\e[0m" if options[:verbose]
    end
  }
rescue Exception => msg
  puts "\e\[31m#{msg}\e[0m"
end
