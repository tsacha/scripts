#!/usr/bin/env python
# -*- coding: utf-8 -*-
from optparse import OptionParser
from datetime import datetime, timedelta
from hashlib import sha1
from base64 import b64encode
from urllib.parse import quote
import http.client
import json

parser = OptionParser()
parser.add_option("--today", dest="today", action="store_true")
(options, args) = parser.parse_args()

today = options.today

now = datetime.now()
tomorrow = now+timedelta(days=1)

# AlloCine parameters
api_url = 'api.allocine.fr'
partner_key = '100043982026'
secret_key = '29d185d98c984a359e6e6f26a0474269'

sed = now.strftime('%Y%m%d')

# Katorza coordinates
lat = "47.2135720"
long = "-1.5625550"
radius = "1"

method = "showtimelist"
params = "partner="+partner_key+"&lat="+lat+"&long="+long+"&format=json"

# URL generation
sig = secret_key+params+'&sed='+sed
h = sha1()
h.update(sig.encode('utf-8'))
sig = quote(b64encode(h.digest()).decode('utf-8'))

query = "/rest/v3/"+method+"?"+params+'&sed='+sed+'&sig='+sig;
connection = http.client.HTTPConnection(api_url)
connection.request('GET', query)

response = connection.getresponse().read()
decoded = json.loads(response.decode("utf-8"))
movies = decoded['feed']['theaterShowtimes'][0]['movieShowtimes']

for f in movies:
    title = f['onShow']['movie']['title']
    print(title)
    for s in f['scr']:
        for h in s['t']:
            session = datetime.strptime(s['d']+" "+h['$'], "%Y-%m-%d %H:%M")
            if session > now and ((today and session < tomorrow) or not today):
                print(session.strftime("%Y-%m-%d %H:%M"));
    
