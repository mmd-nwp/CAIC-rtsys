#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;

# Setup command line options:
#  -d end date (YYMMDDHH (UTC), default = current)
#  -h end hour (UTC, default = current)
#  -s span (hours, 0 = all, default = 18)

use vars qw($opt_d $opt_h $opt_s);
getopt('dhs');

my $spdir = "/ssd/snowpack/output/2024";

my $span = 18;
$span = $opt_s if (defined($opt_s));

# Determine default time based on current time (server uses UTC).
# Round to latest 6-h increment, which is availability of data.

my $endtime = time;
$endtime -= $endtime%21600;

# Override default times based on command line options, if present.

my ($yyyy, $yy, $mm, $dd, $hh);
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
  $endtime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
} elsif (defined $opt_h) {
  ($yyyy, $mm, $dd) = &unix_to_time($endtime);
  $hh = $opt_h;
  $endtime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
}

($yyyy, $mm, $dd, $hh) = &unix_to_time($endtime);

my $enddate = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,0,0);
my $starttime = $endtime - $span*3600;
($yyyy, $mm, $dd, $hh) = &unix_to_time($starttime);
my $startdate = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,0,0);
print "$startdate\n";
print "$enddate\n";

# Open output files - one for each time.

my $ct = 0;
my $time = $starttime;
my $fcstdir = "/home/www/html/snowpack/forecasts/snowpack";
my ($date,$spfile,@OUT);
while ($time <= $endtime) {
  ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
  $date = sprintf("%02d%02d%02d%02d",substr($yyyy,2,2),$mm,$dd,$hh);
  $spfile = "$fcstdir/$date.js";
  print "$spfile\n";
  open($OUT[$ct],">$spfile");
  print {$OUT[$ct]} "let snowpack = [\n";
  $time += 21600;
  ++$ct;
}

# Connect to the snowpack database.

my %attr = (RaiseError=>1,  # error handling enabled 
            AutoCommit=>0); # transaction enabled

my $host="127.0.0.1";
my $dbname = "weather";
my $user = "caic";
my $password = "steepndeep";
my $dbname = "snowpack";

print "Connecting to database: $dbname as user: $user\n";
my $db = DBI->connect("DBI:MariaDB:$dbname:$host", $user, $password);
die "Failed to connect to MySQL database:DBI->errstr()" unless($db);

# Read zones/station information.

my $table = "zones_2km";
my $query = "select id,zone,lat,lon,elev from $table order by id";

my $station_output = $db->prepare($query);
$station_output->execute;

print "Reading station table: $table\n";
my $nsta = $station_output->rows;
$nsta = 0 if ($nsta > 999999);
print "  There are $nsta entries in $table.\n\n";

my ($id,$spid,$zone,$lat,$lon,$elev,$ns,$n,$profile
   ,@words,$data,$i,$spdate,$sptime,$file
   ,$nelem,$spmht,$spht,@spht,$spmoist,@spmoist,$loc
   ,$query,$table_input);

for ($ns=0; $ns<$nsta; $ns++) {
  ($id,$zone,$lat,$lon,$elev) = $station_output->fetchrow;
  next if ($elev < 2800);
  $spid = $id;
  $zone = "0".$zone while(length($zone)<3);
  $id = "0".$id while(length($id)<6);
  $profile = "$spdir/zone$zone/$id/$id"."_res.pro";
  print "$profile\n";
  $data = 0;
  open(IN,$profile);
  while(<IN>) {
    @words = split(',',substr($_,0,-1));
    if ($words[0] eq "[DATA]") {
      $data = 1;
      next;
    }
    next if ($data == 0);
    if ($words[0] == "0500") {
      $spdate = "$words[1]";
      $yyyy = substr($spdate,6,4);
      $mm = substr($spdate,3,2);
      $dd = substr($spdate,0,2);
      $hh = substr($spdate,11,2);
      $sptime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
      $data = 1;
      next if ($sptime < $starttime || $sptime > $endtime);
      $data = 2;
      $file = ($sptime - $starttime) / 21600;
    }
    if ($data == 2) {
      if ($words[0] == "0501") {
        $nelem = $words[1];
        for ($n=0; $n<$nelem; $n++) {
          $spht[$n] = $words[$n+2];
        }
        $spht = nint($spht[$nelem-1]/0.254);
      }
      next if ($spht[$nelem-1] < 25);
      if ($words[0] == "0506") {
        $nelem = $words[1];
        $spmht = 0;
        $spmoist = 0;
        for ($n=0; $n<$nelem; $n++) {
          $spmoist[$n] = $words[$n+2];
          if ($spmoist[$n] > 0) {
            if ($n > 0) {
              $spmht = nint(($spht[$nelem-1]-$spht[$n-1])/0.254);
            } else {
              $spmht = nint($spht[$nelem-1]/0.254);
            }
            $spmoist = $spmoist[$n];
            last;
          }
        }
      }
      if ($words[0] == "0512") {
        $loc = 0;
        $nelem = $words[1];
        for ($n=$nelem-1; $n>0; $n--) {
          if (($words[$n+1] - $words[$n+2]) >= 0.5) {
            $loc = nint($spht[$n-1]/0.254);
            last;
          }
        }
        print {$OUT[$file]} "[$spid,$spht,$spmht,$spmoist,$loc],\n";
      }
    }
  }
  close(IN);
  @spht = ();
  @spmoist = ();
}

# Disconect from the db.

$station_output->finish;
$db->disconnect;

# Close output files.

$ct = 0;
$time = $starttime;
while ($time <= $endtime) {
  print {$OUT[$ct]} "];\n";
  close($OUT[$ct]);
  $time += 21600;
  ++$ct;
}

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

################################################################################

sub nint { my ($z) = @_; return ($z>0)? int($z+0.5) : int($z-0.5); }
