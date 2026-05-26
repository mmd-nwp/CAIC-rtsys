#!/usr/bin/perl -w
require 5.002;   
use strict;
use Getopt::Std;
use Socket;

# Setup command line options:
#    -m model name (default = gfs)
#    -d init date (yyyymmddhh, default = latest)
#    -n max fcst (default = model dependent)
#    -p process "p" previous init time (default = 0)

use vars qw($opt_m $opt_d $opt_n $opt_p);
getopt('mgdnp');

# Define default values and over with any specified options.

my $model = "gfs";
$model = $opt_m if (defined $opt_m);

# Define directory locations.

my $home = "/home/caic/caic/rtsys/download";

# Check to see if this script is already running.
#   If it is, then do not start another script.

my $lock = "$home/lock/$model"."_download.lock";
if (-e $lock) {
  exit;
} else {
  open(TMP,">$lock");
  close(TMP);
}

# Define model dependent information.

my (%host,%hostip,%ftpdir,%maxfcst,%fcstinc,%fcstfrq,%user,%pass,%outdir);

# HRRR.

$host   {"hrrr"} = "https://nomads.ncep.noaa.gov";
#$host   {"hrrr"} = "ftp://ftp.ncep.noaa.gov";
$hostip {"hrrr"} = "140.90.101.48";
$ftpdir {"hrrr"} = "pub/data/nccf/com/$model/prod";
$maxfcst{"hrrr"} = 48;
$fcstinc{"hrrr"} = 1;
$fcstfrq{"hrrr"} = 6;
$user   {"hrrr"} = "";
$pass   {"hrrr"} = "";
$outdir {"hrrr"} = "/data/noaaport/grids/$model/grib2";

# NAM.

#$host   {"nam"} = "https://www.ftp.ncep.noaa.gov";
#$ftpdir {"nam"} = "data/nccf/com/$model/prod";

$host   {"nam"} = "https://nomads.ncep.noaa.gov";
#$host   {"nam"} = "ftp://ftp.ncep.noaa.gov";
$ftpdir {"nam"} = "pub/data/nccf/com/$model/prod";

$hostip {"nam"} = "140.90.101.48";
$maxfcst{"nam"} = 84;
$fcstinc{"nam"} = 3;
$fcstfrq{"nam"} = 6;
$user   {"nam"} = "";
$pass   {"nam"} = "";
$outdir {"nam"} = "/data/noaaport/grids/$model/grib2";

# GFS.

#$host   {"gfs"} = "ftp://ftp.ncep.noaa.gov";
# Nomads.
$host   {"gfs"} = "https://nomads.ncep.noaa.gov";
#$hostip {"gfs"} = "140.90.101.48";
$ftpdir {"gfs"} = "pub/data/nccf/com/$model/prod";
# Google.
#$host   {"gfs"} = "https://storage.googleapis.com";
#$ftpdir {"gfs"} = "global-forecast-system";
$maxfcst{"gfs"} = 240;
$fcstinc{"gfs"} = 3;
$fcstfrq{"gfs"} = 6;
$user   {"gfs"} = "";
$pass   {"gfs"} = "";
$outdir {"gfs"} = "/data/noaaport/grids/$model/grib2";

# Blend.

$host   {"nbm"} = "https://nomads.ncep.noaa.gov";
#$hostip {"nbm"} = "140.90.101.48";
$ftpdir {"nbm"} = "pub/data/nccf/com/blend/prod";
$maxfcst{"nbm"} = 84;
$fcstinc{"nbm"} = 1;
$fcstfrq{"nbm"} = 1;
$user   {"nbm"} = "";
$pass   {"nbm"} = "";
$outdir {"nbm"} = "/data/noaaport/grids/$model/grib2";

# RRFS.

# Google.
$host   {"rrfs"} = "https://noaa-rrfs-pds.s3.amazonaws.com";
$ftpdir {"rrfs"} = "rrfs_public";
$maxfcst{"rrfs"} = 84;
$fcstinc{"rrfs"} = 3;
$fcstfrq{"rrfs"} = 6;
$user   {"rrfs"} = "";
$pass   {"rrfs"} = "";
$outdir {"rrfs"} = "/data/noaaport/grids/$model/grib2";

# GDAS (GFS bufr).

$host   {"gdas"} = "https://nomads.ncep.noaa.gov";
$hostip {"gdas"} = "140.90.101.48";
$ftpdir {"gdas"} = "pub/data/nccf/com/gfs/prod";
$maxfcst{"gdas"} = 0;
$fcstinc{"gdas"} = 6;
$fcstfrq{"gdas"} = 6;
$user   {"gdas"} = "";
$pass   {"gdas"} = "";
$outdir {"gdas"} = "/data/obs/gfs/bufr";

# UKMO.

$host   {"ukmo"} = "ftp.metoffice.gov.uk";
$hostip {"ukmo"} = "151.170.240.90";
$ftpdir {"ukmo"} = "REALTIME";
$maxfcst{"ukmo"} = 168;
$fcstinc{"ukmo"} = 6;
$fcstfrq{"ukmo"} = 6;
$user   {"ukmo"} = "ext_collab_metmalaysia";
$pass   {"ukmo"} = "mdtfj3yj";
$outdir {"ukmo"} = "/data/grids/$model/grib2";

# Fill local variables.

my $host    = $host{$model};
my $hostip  = $hostip{$model};
my $ftpdir  = $ftpdir{$model};
my $maxfcst = $maxfcst{$model};
my $fcstinc = $fcstinc{$model};
my $fcstfrq = $fcstfrq{$model};
my $user    = $user{$model};
my $pass    = $pass{$model};
my $outdir  = $outdir{$model};

$maxfcst = $opt_n if (defined $opt_n);

# Obtain ip address using DNS. If DNS not available use hardwired values.

#my @ips = gethostbyname($host);
#if (@ips) { $host = inet_ntoa($ips[4]); } else { $host = $hostip; }

my $diff = 0;
#my $diff = 7200;
#$diff = 0 if ($model eq "hrrr");
#$diff = 0 if ($model eq "nam");
$diff = $opt_p * $fcstfrq * 3600 if (defined $opt_p); 
my $time = time - $diff;
my ($yyyy, $mm, $dd, $jjj, $hh);
if (defined $opt_d) {
  $yyyy = substr($opt_d,0,4);
  $mm = substr($opt_d,4,2);
  $dd = substr($opt_d,6,2);
  $hh = substr($opt_d,8,2);
} else {
  ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
  $hh -= $hh % $fcstfrq;
}
$jjj = &julian($yyyy, $mm, $dd);

my $yy = $yyyy % 100;
$yy = "0".$yy if(length($yy)<2);
$mm = "0".$mm if(length($mm)<2);
$dd = "0".$dd if(length($dd)<2);
$hh = "0".$hh if(length($hh)<2);
$jjj = "0".$jjj while(length($jjj)<3);

# Create model filenames for download.

my ($mdlfile,$fcst,$query,$targetfile,$options);

# Use wget to retrieve files.
#  - wget will only retrieve new files. 

my $path = "$host/$ftpdir";
$path = "$path/gfs.$yyyy$mm$dd/$hh/atmos" if ($model eq "gfs" || $model eq "gdas");
$path = "$path/blend.$yyyy$mm$dd/$hh/core" if ($model eq "nbm");
$path = "$path/nam.$yyyy$mm$dd" if ($model eq "nam");
$path = "$path/hrrr.$yyyy$mm$dd/conus" if ($model eq "hrrr");
$path = "$path/rrfs.$yyyy$mm$dd/$hh" if ($model eq "rrfs");
$options = "-nv -nd -m --no-check-certificate --no-if-modified-since";
$options = "$options --user=$user --password=$pass" if ($user ne "");

chdir($outdir);
$fcst = 0;
$fcst = 1 if ($model eq "nbm");
#print "$fcst $maxfcst\n";
while ($fcst <= $maxfcst){
  $fcst = "0".$fcst while(length($fcst)<4);
  if ($model eq "gfs") {
#   if ($fcst le "0084") {
      $mdlfile = "gfs.t$hh"."z.pgrb2.0p25.f".substr($fcst,1,3);
#   } else {
#     $mdlfile = "gfs.t$hh"."z.pgrb2.1p00.f".substr($fcst,1,3);
#   }
    $targetfile = "$yy$jjj$hh"."00$fcst";
  } elsif ($model eq "hrrr") {
    $mdlfile = "hrrr.t$hh"."z.wrfprsf".substr($fcst,2,2).".grib2";
    $targetfile = "$yy$jjj$hh"."00$fcst";
  } elsif ($model eq "nam") {
    $mdlfile = "nam.t$hh"."z.awphys".substr($fcst,2,2).".tm00.grib2";
    $targetfile = "$yy$jjj$hh"."00$fcst";
  } elsif ($model eq "rrfs") {
    $mdlfile = "rrfs.t$hh"."z.prslev.3km.f0".substr($fcst,2,2).".conus.grib2";
    $targetfile = "$yy$jjj$hh"."00$fcst";
  } elsif ($model eq "nbm") {
    if ($fcst > 36 && $fcst%3 != 0) {
      $fcst += $fcstinc;
      next;
    }
    $mdlfile = "blend.t$hh"."z.core.f".substr($fcst,1,3).".co.grib2";
    $targetfile = "$yy$jjj$hh"."00$fcst";
  } elsif ($model eq "gdas") {
    $mdlfile = "gfs.t$hh"."z.prepbufr.unblok.nr";
    $targetfile = "$yy$jjj$hh"."00$fcst";
  } elsif ($model eq "ukmo") {
    $mdlfile = "$yyyy$mm$dd"."T$hh"."00Z_malaysia_".substr($fcst,1,3)."_grib2.gz";
    $targetfile = "$yy$jjj$hh"."00$fcst.gz";
  }

# Retrieve model file.

  symlink("$targetfile","$mdlfile") if (-e $targetfile);
  $query = "wget $options $path/$mdlfile";
  print "$query $targetfile\n";
  system($query);
  rename("$outdir/$mdlfile","$outdir/$targetfile") if (! -l $mdlfile);
  unlink($mdlfile);
  last if (! -e "$outdir/$targetfile");

  $fcst += $fcstinc;
}

unlink $lock;

exit;

#===============================================================================
#
# &unix_to_time: Calculate month, day, year, hour, min, sec from unix time
# Arguments: unix time
# Returns: month, day, year, hour, min, sec

sub unix_to_time {
  my($utm) = @_;
  my($i, $j, $n, $l, $d, $m, $y);

  $n = int($utm/86400);

  $utm -= 86400*$n;
  $l    = $n + 2509157;
  $n    = int((4*$l)/146097);
  $l   -= int( (146097*$n + 3)/4);
  $i    = int( (4000*($l+1))/1461001);
  $l   += 31 - int((1461*$i)/4);
  $j    = int((80*$l)/2447);
  $d    = $l - int( (2447*$j)/80);
  $l    = int($j/11);
  $m    = $j + 2 - 12*$l;
  $y    = 100*($n-49) + $i + $l;

  my @answer = ($y, $m, $d, int($utm/3600), int(($utm%3600)/60), int($utm%60))
;

  @answer
}
1;

#===============================================================================
#
# &julian: Calculate julian day from year, month, day
# Arguments: year, month, day
# Returns: julian day

sub julian {
  my($yr,$mo,$dy) = @_;

  my @ndays=(31,28,31,30,31,30,31,31,30,31,30,31);
  my $i;

  my $julday = 0;
  for ($i = 1; $i < $mo; $i++) {
    $julday = $julday + $ndays[$i-1]
  }

  $julday += $dy;

  ++$julday if ($yr % 4 == 0 && $mo > 2);

  return $julday;
}
1;
