#!/usr/bin/perl
# (c) 2008-09 David Roberts

# this can be tested in http://www.thechrisoshow.com/display_kml/

use Net::Traceroute;
# use Geo::Coder::HostIP; # see http://search.cpan.org/dist/Geo-Coder-HostIP/
use CAIDA::NetGeoClient; # see http://www.caida.org/tools/utilities/netgeo/NGAPI/
use Math::Trig;

$LINE_STEP = 10;

sub placemark {
	my ($name, $lat, $lon) = @_;
	print '<Placemark>';
	print '<name>' . $name . '</name>';
	print '<Point><coordinates>' . $lon . ',' . $lat . ',0</coordinates></Point>';
	print '</Placemark>';
	print "\n";
}

sub dist {
	my ($lat1, $lon1, $lat2, $lon2) = @_;
	
	# haversine formula
	my $a = sin(($lat2 - $lat1)/2.0);
	my $b = sin(($lon2 - $lon1)/2.0);
	my $h = ($a*$a) + cos($lat1) * cos($lat2) * ($b*$b);
	my $theta = 2 * asin(sqrt($h));
	
	return $theta;
}

# TODO draw lines in kml, eg:
# <?xml version="1.0" encoding="UTF-8"?>
# <kml xmlns="http://earth.google.com/kml/2.2">
# 	<Document>
# 		<Placemark>
# 			<LineString>
# 				<coordinates>
# 					lon,lat,0
# 					...
# 				</coordinates>
# 			</LineString>
# 		</Placemark>
# 	</Document>
# </kml>

sub drawline {
	my ($lat1, $lon1, $lat2, $lon2) = @_;
	
	my $lat1 = deg2rad($lat1);
	my $lon1 = deg2rad($lon1);
	my $lat2 = deg2rad($lat2);
	my $lon2 = deg2rad($lon2);
	
	my $d = dist($lat1, $lon1, $lat2, $lon2);
	
	return if $d < 0.001; # don't bother for really short distances
	
	# convert point a to cartesian coordinates
	my $ax = cos($lat1) * cos($lon1);
	my $ay = cos($lat1) * sin($lon1);
	my $az = sin($lat1);
	
	# convert point b to cartesian coordinates
	my $bx = cos($lat2) * cos($lon2);
	my $by = cos($lat2) * sin($lon2);
	my $bz = sin($lat2);
	
	my $line_step = deg2rad(5);
	
	for(my $da = $line_step; $da < $d; $da += $line_step) {
		# $da = distance from point a
		my $db = $d - $da; # distance from point b
		
		# adapted from http://williams.best.vwh.net/avform.html
		my $wa = sin($db) / sin($d); # weighting of point a
		my $wb = sin($da) / sin($d); # weighting of point b
		
		# calculate cartesian coordinates of point
		my $x = $wa * $ax + $wb * $bx;
		my $y = $wa * $ay + $wb * $by;
		my $z = $wa * $az + $wb * $bz;
		
		# convert back to lat/lon
		my $lat = atan2($z, sqrt($x*$x + $y*$y));
		my $lon = atan2($y, $x);
		
		placemark('', rad2deg($lat), rad2deg($lon));
# 		print rad2deg($lon) . ',' . rad2deg($lat) . ',0' . "\n";
	}
}

# my $geo = new Geo::Coder::HostIP; # use HostIP API
my $geo = new CAIDA::NetGeoClient(); # use NetGeo API

print '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
print '<kml xmlns="http://earth.google.com/kml/2.2">' . "\n";

# draw line between two random points
my $lat1 = rand(180) - 90;
my $lon1 = rand(360) - 180;
my $lat2 = rand(180) - 90;
my $lon2 = rand(360) - 180;
placemark('a', $lat1, $lon1);
drawline($lat1, $lon1, $lat2, $lon2);
placemark('b', $lat2, $lon2);

# # draw multi-part line between multiple random points
# my $last_lat = 0;
# my $last_lon = 0;
# for(my $i = 1; $i <= 5; $i++) {
# 	$lat = rand(180) - 90;
# 	$lon = rand(360) - 180;
# 	
# 	drawline($last_lat, $last_lon, $lat, $lon) if($last_lat && $last_lon);
# 	$last_lat = $lat;
# 	$last_lon = $lon;
# 	
# 	placemark(sprintf("%02d", $i), $lat, $lon);
# }

# # draw traceroute path
# warn 'Performing traceroute...';
# my $tr = Net::Traceroute->new(host=> "google.com");
# if($tr->found) {
# 	my $hops = $tr->hops;
# 	
# 	my $last_lat = 0;
# 	my $last_lon = 0;
# 	
# 	for(my $i = 1; $i <= $hops; $i++) {
# 		my $ip = $tr->hop_query_host($i, 0);
# 		next if $ip eq '';
# 		
# 		warn 'Looking up ' . $ip . '...';
# 		my $recordRef = $geo->getLatLong($ip);
# 		my $lat = $recordRef->{LAT};
# 		my $lon = $recordRef->{LONG};
# 		
# 		drawline($last_lat, $last_lon, $lat, $lon) if($last_lat && $last_lon);
# 		$last_lat = $lat;
# 		$last_lon = $lon;
# 		
# 		placemark(sprintf("%02d", $i) . ': ' . $ip, $lat, $lon);
# 	}
# }

print '</kml>' . "\n";
