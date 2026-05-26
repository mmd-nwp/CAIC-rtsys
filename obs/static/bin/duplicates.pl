#!/usr/bin/perl
use strict;
use DBI;

# Define directories.

my $root = "/home/caic/obs";
my $stntable = "$root/static/csv/madis-stations.csv";

# Define zone codes.

my %zonecode;
$zonecode{"Steamboat"} = 1;
$zonecode{"FrontRange"} = 2;
$zonecode{"Vail/Summit"} = 3;
$zonecode{"Sawatch"} = 4;
$zonecode{"Aspen"} = 5;
$zonecode{"Gunnison"} = 6;
$zonecode{"GrandMesa"} = 7;
$zonecode{"NSanJuan"} = 8;
$zonecode{"SSanJuan"} = 9;
$zonecode{"Sangre"} = 10;

# Read the station table.

my (@words,$stnid,%stnid,%provider,%zone,%lat,%lon,%elev,%stnname);
open(IN,"$stntable");
while(<IN>) {
  @words = split(",");
  $stnid = $words[0];
  print "$stnid\n" if (exists($stnid{$stnid}));
  $stnid{$stnid} = $stnid;
  $provider{$stnid} = $words[1];
  if (length $words[2]) {
    $zone{$stnid} = $zonecode{$words[2]};
  } else {
    $zone{$stnid} = 0;
  }
  $lat{$stnid} = $words[3];
  $lon{$stnid} = $words[4];
  $elev{$stnid} = $words[5];
  $stnname{$stnid} = $words[6];
}
close(IN);

exit;
