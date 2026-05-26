#!/usr/bin/perl -w
use strict;
use Getopt::Std;

# Setup command line options:
#    -p number of days to save data files or if negative then number of 
#       subdirectories to save (default = 7 days).
#    -d directory for purging (default = /home/caic/caic/rtsys/post/ptfcst/table)

use vars qw($opt_p $opt_d);
getopt('pd');

my $time = time;

my $purge = 7;
$purge = $opt_p if ($opt_p);

my $runs = "/home/caic/caic/rtsys/post/ptfcst/table";
$runs = $opt_d if ($opt_d);

my (@rundir,$nrundir,$n,$py,$pm,$pd,$ph,$runtime);

opendir(RUNS,$runs);
@rundir = sort(grep(/^\d{4}/, readdir(RUNS)));
closedir(RUNS);
$nrundir = @rundir;
if ($purge < 0) {
   $purge = int(-$purge);
   print "    > Keep $purge model runs.\n";
   for ($n=0;$n<$nrundir-$purge;$n++) {
      print "      Removing $runs/$rundir[$n]\n";
      system("rm -rf $runs/$rundir[$n]");
   }
} else {
   print "    > Keep model runs that are less than $purge days old.\n";
   $purge *= 3600;
   $purge *= 24;
   foreach (@rundir) {
      if (/(\d{4})-(\d{2})-(\d{2})-(\d{2})/) {
         $py = $1;
         $pm = $2;
         $pd = $3;
         $ph = $4;
         $runtime = &time_to_unix($pm,$pd,$py,$ph,0,0);
         if ($time-$runtime > $purge) {
            print "      Removing $runs/$_\n";
            system("rm -rf $runs/$_");
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
