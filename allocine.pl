#!/usr/bin/env perl
use strict;
use Encode qw(encode);
use DateTime;
use DateTime::Format::Strptime;
use Digest::SHA1 qw(sha1_base64);
use URI::Escape;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use Getopt::Long;

my $now = DateTime->now("time_zone" => "Europe/Paris");
my $tomorrow = DateTime->now->add(days => 1);

# Script options
my $today = 0;

GetOptions ("today" => \$today) # flag
    or die("Error in command line arguments\n");

# AlloCine parameters
my $api_url = 'http://api.allocine.fr/rest/v3';
my $partner_key = '100043982026';
my $secret_key = '29d185d98c984a359e6e6f26a0474269';

my $sed = $now->strftime('%Y%m%d');

# Katorza coordinates
my $lat = "47.2135720";
my $long = "-1.5625550";
my $radius = "1";

my $method = "showtimelist";
my $params = "partner=$partner_key&lat=$lat&long=$long&format=json";

# URL generation
my $sig = uri_escape(sha1_base64($secret_key.$params.'&sed='.$sed));
my $query_url = $api_url."/".$method."?".$params.'&sed='.$sed.'&sig='.$sig."%3D";

my $ua = LWP::UserAgent->new;
$ua->agent("Dalvik/1.6.0 (Linux; U; Android 4.2.2; Nexus 4 Build/JDQ39E)");
$ua->timeout(4);
$ua->env_proxy;


my $response = $ua->get($query_url);
if ($response->is_success) {
    my $decoded = decode_json($response->decoded_content);
    my @movies = @{ $decoded->{"feed"}->{"theaterShowtimes"}->[0]->{"movieShowtimes"} };

    foreach my $f ( @movies ) {
	my $title = encode('utf-8',$f->{"onShow"}->{"movie"}->{"title"});

	print $title."\n";
	foreach my $s ( @{ $f->{"scr"} } ) {
	    foreach my $h ( @{ $s->{"t"} } ) {
		my $session_pattern = new DateTime::Format::Strptime(
		    pattern => "%Y-%m-%d %H:%M",
		    time_zone => 'Europe/Paris'
		    );
		
 		my $session = $session_pattern->parse_datetime($s->{"d"}." ".$h->{"\$"});
		if ($session > $now && (($today && $session < $tomorrow) || !$today)) {
		    print $session->strftime("%Y-%m-%d %H:%M\n");
		}
		
	    }
	}
    }

}

else {
    die $response->status_line;
}
