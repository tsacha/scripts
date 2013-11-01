#!/usr/bin/env ruby
require 'openssl'
require 'digest/sha1'
require 'cgi'
require 'optparse'
require 'net/http'
require 'json'
require 'date'

today = false
OptionParser.new do |opts|
  opts.banner = "Usage: allocine.rb [options]"

  opts.on("--[no-]today", "Display only movie times for today") do |v|
    today = v
  end
end.parse!
 
now = DateTime.now
tomorrow = (now.to_time+86400).to_date

# AlloCine parameters
api_url = 'http://api.allocine.fr/rest/v3'
partner_key = '100043982026'
secret_key = '29d185d98c984a359e6e6f26a0474269'

sed = now.strftime('%Y%m%d')

# Katorza coordinates
lat = "47.2135720"
long = "-1.5625550"
radius = "1"

method = "showtimelist";
params = "partner="+partner_key+"&lat="+lat+"&long="+long+"&format=json"

# URL generation
sig = CGI.escape(Digest::SHA1.base64digest(secret_key+params+'&sed='+sed));
query_url = api_url+"/"+method+"?"+params+'&sed='+sed+'&sig='+sig;

uri = URI.parse(query_url)
response = Net::HTTP.get_response(uri)

decoded = JSON.parse(response.body)
movies = decoded['feed']['theaterShowtimes'][0]['movieShowtimes']

movies.each do |f|
  title = f['onShow']['movie']['title']
  print title+"\n"
  f['scr'].each do |s|
    s['t'].each do |h|
      session = DateTime.parse("#{s['d']}+" "+#{h['$']}", "%Y-%m-%d %H:%M")
      if session > now && ((today && session < tomorrow) || !today)
        puts session.strftime("%Y-%m-%d %H:%M\n");
      end
    end
  end
end
