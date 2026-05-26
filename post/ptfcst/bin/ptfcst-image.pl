#!/usr/bin/perl
use strict;
use URI::Escape;
use Getopt::Std;

# Generate point forecast images using localhost web server.

# Setup command line options:
#    -t initial time (yymmddhh, default = current)
#    -m model id (default wrf)
#    -d domain (default = caic)
#    -r grid spacing (default = 4km)
#    -u units (e - english or m - metric, default = e)
#    -i image type (p - point fcst, s - cloud seed fcst, default p)

use vars qw($opt_t $opt_m $opt_d $opt_r $opt_u $opt_i);
getopt('tmdrui');

#my $host = "10.1.10.100";
my $host = "localhost";
#my $host = "nwp.mtnweather.info";

my $domain = "caic";
$domain = $opt_d if defined($opt_d);
my $res = "4km";
$res = $opt_r if defined($opt_r);
my $wres = $res;
$wres = "2km" if ($wres eq "6km");
$wres = "4km" if ($wres eq "12km");

my $model = "wrf";
$model = $opt_m if defined ($opt_m);
$wres = "12km" if ($model eq "nam");

my $unit = "e";
$unit = $opt_u if ($opt_u);

my $type = "p";
$type = $opt_i if ($opt_i);

# Determine default times based on current time.

my $time = time;
my ($yyyy, $yy, $mm, $dd, $hh);
if (defined ($opt_t)) {
  $yy = substr($opt_t,0,2);
  $mm = substr($opt_t,2,2);
  $dd = substr($opt_t,4,2);
  $hh = substr($opt_t,6,2);
  $yyyy = 2000 + $yy;
} else {
  ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
  $mm = "0".$mm while(length($mm)<2);
  $dd = "0".$dd while(length($dd)<2);
  $hh = "0".$hh while(length($hh)<2);
}
my $webdate = "$yyyy-$mm-$dd-$hh"."00";
my $webdir = "/web/$domain/$wres/$model/points/$webdate";
print("$webdir\n");

my (@vars,$dom,$stn,$title,$cmd);
open(IN,"$webdir/ptfcst.txt");
while(<IN>) {
  (@vars) = split;
  $dom = $vars[0];
  next if ($dom eq "01" && ($res eq "4km" || $res eq "2km"));
  next if ($dom eq "02" && ($res eq "12km" || $res eq "6km"));
  $stn = $vars[1];
  $title = substr($_,33,-1);
  $title =~ s/\s+$//;
  $title = uri_escape($title);
  if ($type eq "s") {
    $cmd = "wget --no-check-certificate 'https://$host/ptfcst/seedplot.php?st=$stn&title=$title&model=$model&date=$webdate&res=$res' -O $webdir/$stn-seed.png";
  } else {
    $cmd = "wget --no-check-certificate 'https://$host/ptfcst/fcstplot.php?st=$stn&title=$title&model=$model&date=$webdate&res=$res' -O $webdir/$stn-$unit.png";
  }
  system($cmd);
}
close(IN);

exit;
