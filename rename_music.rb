#!/usr/bin/env ruby
require 'optparse'
require 'fileutils'
require 'shellwords'

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: rename_music.rb [options]"

  options[:music_folder] = "/home/sacha/Music"
  opts.on("-m", "--musicfolder FOLDER", String, "Music folder") do |music_folder|
    options[:music_folder] = music_folder
  end

  options[:try] = false
  opts.on("-n", "--noop", "Dry run") do |noop|
    options[:try] = noop
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
  if File.file?(file)
    ext = file.split('.')[-1]
    if ext == "flac"
      begin
        flac = `metaflac --show-tag=ARTIST --show-tag=ALBUM --show-tag=DATE --show-tag=DISCNUMBER --show-tag=TRACKNUMBER --show-tag=TITLE #{Shellwords.escape(file)} 2> /dev/null`
        raise "#{Shellwords.escape(file)} is not a correct file" if $? != 0

        tags = {}
        flac.each_line do |tag|
          type = tag.split("=")
          tags[type.shift] = type.join("=")[0..-2]
        end

        tags["tracknumber"] = tags["tracknumber"].gsub(/^([0-9])$/,'0\1')
        tags["title"] = tags["title"].gsub(/\//,'\\')
        target_dir = options[:music_folder]+"/"+tags["artist"]+"/"+tags["date"]+" - "+tags["album"]+"/Disc "+tags["discnumber"]
        target_file = tags["tracknumber"]+" - "+tags["title"]+".flac"
        if not File.exists? target_dir and not File.directory? target_dir
          if not options[:try]
            FileUtils.mkdir_p target_dir
          end
          puts "\e\[34mmkdir -p #{target_dir}\e[0m"
        end
        
        if not File.exists? target_dir+"/"+target_file
          if not options[:try]
            File.rename file,target_dir+"/"+target_file
          end
          puts "\e\[32mmv #{file} #{target_dir}/#{target_file}\e[0m"
        end
      rescue Exception => msg
        puts "\e\[31m#{msg}\e[0m"
      end
    end
  end
end

