#!/usr/bin/env ruby
require 'flacinfo'
absolute_path = "/home/sacha/Music"
ARGV.each do |arg|
  Dir.chdir(arg)
  Dir.glob("**/*").each do |file|
    if File.file?(file)
      ext = file.split('.')[-1]
      if ext == "flac"
        flac = FlacInfo.new(file)
        target_dir = absolute_path+"/"+flac.tags["artist"]+"/"+flac.tags["date"]+" - "+flac.tags["album"]+"/Disc "+flac.tags["discnumber"]
        target_file = flac.tags["tracknumber"]+" - "+flac.tags["title"]+".flac"
        if not File.exists? target_dir and not File.directory? target_dir
          Dir.mkdir target_dir
        end
        File.rename file,target_dir+"/"+target_file
      end
    end
  end
end
