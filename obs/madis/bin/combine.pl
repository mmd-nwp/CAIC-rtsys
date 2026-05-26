#!/usr/bin/perl 
use strict;
use Getopt::Std;

# Setup command line options:
#  -d date (MST, YYMMDDHH, default = current)
#  -h hour (MST, default = current)
#  -n number of files to look back into (default = 13)

use vars qw($opt_d $opt_h $opt_n);
getopt('dhn');

my $data   = "/home/caic/caic/rtsys/obs/madis/data";
my $csvdir = "$data/csv";
my $outdir = "$data/madis";

# Determine default time based on current time.

my $time = time;
my ($yyyy, $yy, $mm, $dd, $hh);
($yyyy, $mm, $dd, $hh) = &unix_to_time($time);

# Override default times based on command line options, if present.

if (defined $opt_d) {
  $_ = $opt_d;
  if (/^(\d\d)(\d\d)(\d\d)(\d\d)$/) {
    $yy = $1;
    $mm = $2;
    $dd = $3;
    $hh = $4;
    $yyyy = $yy + 2000;
  } else {
    print "Invalid date format - YYMMDDHH\n";
    exit;
  }
} elsif (defined $opt_h) {
  $hh = $opt_h;
}

my $ntime = 13;
$ntime = $opt_n if defined ($opt_n);

$mm = "0$mm" while(length($mm) < 2);
$dd = "0$dd" while(length($dd) < 2);
$hh = "0$hh" while(length($hh) < 2);

my @file;
$file[0] = "$csvdir/$yyyy-$mm-$dd-$hh"."00.csv";

$time = &time_to_unix($mm, $dd, $yyyy, $hh);
my $n;
for ($n=1; $n<$ntime; ++$n) {

   $time -= 3600;
   ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);

   $mm = "0$mm" while(length($mm) < 2);
   $dd = "0$dd" while(length($dd) < 2);
   $hh = "0$hh" while(length($hh) < 2);

   $file[$n] = "$csvdir/$yyyy-$mm-$dd-$hh"."00.csv";
}

my ($line,$pos,$header_atm,$header_snow,@words,$date,$stn,$key,%atm,%snow);
for ($n=0; $n<$ntime; ++$n) {
   $line = 0;
   open(IN,$file[$n]);
   while(<IN>) {
      $pos = rindex("$_",",");
      $pos = rindex("$_",",",$pos-1);
      if ($line == 0) {
         $header_atm = substr("$_",0,$pos);
         $header_snow= "id,date,".substr("$_",$pos+1);
      } else {
         @words = split(",");
         $stn = $words[0];
         $date = $words[1];
         $key = "$stn$date";
         $atm{$key} = substr("$_",0,$pos);
         $snow{$key}= "$stn,$date,".substr("$_",$pos+1);
      }
      ++$line;
   }
   close(IN);
}

open(OUT,">$outdir/CAIC_ATM.dat");
print OUT "$header_atm\n";
foreach $key (sort keys %atm) {
   print OUT "$atm{$key}\n";
}
close(OUT);

open(OUT,">$outdir/CAIC_SNOW.dat");
print OUT "$header_snow";
foreach $key (sort keys %snow) {
   next if (substr($snow{$key},-14,13) eq "-99.00,-99.00");
   print OUT "$snow{$key}";
}
close(OUT);

exit;

#===============================================================================

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

    my @answer = ($y, $m, $d, int($utm/3600), int(($utm%3600)/60), int($utm%60));

    @answer
}
1;

#===============================================================================

# &time_to_unix: Calculate unix time from month, day, year, hour, min, sec
# Arguments: month, day, year (4 digit), hour, min, sec
# Returns: unix time

sub time_to_unix {
   my($month, $day, $year, $hour, $minute, $second) = @_;
   my($b, $g, $d, $e, $f, $today);

   $b = int ( ($month - 14) / 12 );
   $g = $year + 4900 + $b;
   $b = $month - 2 - 12*$b;

   $d = int( (1461*($g-100))/4);
   $e = int( (367*$b)/12);
   $f = int( (3*int($g/100))/4);

   $today = $d + $e - $f + $day - 2432076;

   86400*($today-40587) + 3600*$hour + 60*$minute + $second;
}
1;

#===============================================================================

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

#===============================================================================

sub JJJ2MMDD {
   my($jjj,$yy) = @_;
   my(@daysinmon) = (31,0,31,30,31,30,31,31,30,31,30,31);
   my(@mmmdd) = (-1,-1);
   $yy=1900+$yy if($yy<100);

   my($leap) = $yy%4;
   my($jmax);
   if($leap==0){
      $jmax = 366;
      $daysinmon[1]=29;
   }else{
      $jmax = 365;
      $daysinmon[1]=28;
   }
   if($jjj<1 || $jjj > $jmax){
      print STDERR "Invalid Julian date passed to JJJ2MMDD\n";
      return @mmmdd;
   }

# Addition of 0 removes any leading zeros

   $mmmdd[0]=1+0;
   $mmmdd[1]=$jjj+0;
   while($mmmdd[1] > $daysinmon[$mmmdd[0]-1]){
      $mmmdd[1] = $mmmdd[1]-$daysinmon[$mmmdd[0]-1];
      $mmmdd[0]++;
   }
   return @mmmdd;
}1;
