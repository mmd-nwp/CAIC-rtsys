#!/usr/bin/perl -w
use strict;
use Getopt::Std;

# Setup command line options:
#    -p number of days to save model runs or if negative then number of 
#       runs to save (default = 30 runs).
#    -m model (default = nam)
#    -d directory for purging (default = /data/noaaport/grids)
#    -f data format (default = grib2)

use vars qw($opt_p $opt_m $opt_d $opt_f);
getopt('pmdf');

my $time = time;

my $purge = -30;
$purge = $opt_p if ($opt_p);

my $mdl = "nam";
$mdl = $opt_m if ($opt_m);

my $fmt = "grib2";
$fmt = $opt_f if ($opt_f);

my $runs = "/data/noaaport/grids";
$runs = $opt_d if ($opt_d);
$runs = "$runs/$mdl/$fmt";

my (@rundir,%rundir,$nrundir,$n,$py,$pj,$pm,$pd,$ph,$runtime);

opendir(RUNS,$runs);
@rundir = sort(grep(/^\d{13}/, readdir(RUNS)));
closedir(RUNS);

foreach (@rundir) {
  if (/(\d{9})/) {
    $rundir{$1} = $1;
  }
}
$nrundir = keys %rundir;
@rundir = sort keys %rundir;

if ($purge < 0) {
   $purge = int(-$purge);
   print "    > Keep $purge $mdl model runs.\n";
   for ($n=0;$n<$nrundir-$purge;$n++) {
      print "      Removing $runs/$rundir[$n]\n";
      system("rm -rf $runs/$rundir[$n]*");
   }
} else {
   print "    > Keep $mdl model runs that are less than $purge days old.\n";
   foreach (@rundir) {
      if (/(\d{2})(\d{3})(\d{2})/) {
         $py = $1;
         $pj = $2;
         $ph = $3;
         $py += 2000;
         ($pm,$pd) = &JJJ2MMDD($pj,$py);
         $runtime = &time_to_unix($pm,$pd,$py,$ph,0,0);
         if ($time-$runtime > $purge*3600*24) {
            print "      Removing $runs/$_\n";
            system("rm -rf $runs/$_*");
         }
      }
   }
}

exit;

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
