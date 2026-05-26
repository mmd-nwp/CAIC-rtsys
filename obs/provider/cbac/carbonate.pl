#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;
use DateTime;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Setup command line options:
#  -l lookback time [hours, default = 6]

use vars qw($opt_l);
getopt('l');

my $obsfile = "/home/caic/caic/rtsys/obs/provider/cbac/data/carbonate.txt";

# Determine current time.

my $stime = time();
$stime -= $stime % 3600;

# Determine lookback time for db ingest.

my $lookback = 6;
$lookback = $opt_l if (defined($opt_l));
$stime -= $lookback*3600;

# Read the data and extract any data after lookback time.

my ($yyyy,$mm,$dd,$hh,$gyyy,$gm,$gd,$gh,$daylight,$otime);

open(FH, '<', $obsfile) or die $!;

my (@words,$dt,@dbtime,@tp,@rh,@spd,@dir,@gust,@pcp,@hs,$tp,$td,$rh,$spd,$dir,$gust,$pcp,$hs);
my $ct = -1;
my $nt = 0;
while(<FH>){
  ++$ct;
  next if ($ct < 3);
  @words = split;
  ($mm,$dd,$yyyy) = split('/',$words[0]);
  ($hh) = split(':',$words[1]);
  $yyyy += 2000;
# $dt = DateTime->new(
#   'year'      => $yyyy,
#   'month'     => $mm,
#   'day'       => $dd,
#   'hour'      => $hh,
#   'time_zone' => 'America/Denver'
# );
# $daylight = $dt->is_dst();
  $otime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
# $otime += 25200 - ($daylight*3600);
# $otime += 25200;
  $otime += 21600;  # Time is always UTC-6
  next if ($otime < $stime);
  ($gyyy, $gm, $gd, $gh) = &unix_to_time($otime);
  $dbtime[$nt] = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$gyyy,$gm,$gd,$gh,0,0);
  $spd[$nt] = $words[2];
  $gust[$nt] = $words[3];
  $dir[$nt] = $words[4];
  $tp[$nt] = $words[5];
  $rh[$nt] = $words[6];
  ++$nt;
}

close(FH);

# Connect to the weather database.

my %attr = (RaiseError=>1,  # error handling enabled 
            AutoCommit=>0); # transaction enabled

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

print "Connecting to local database: $dbname as user: $user\n";
my $db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Insert extracted data into db.

my ($n,$query,$table_input);
my $stid = "CACBH";
for ($n=0; $n<$nt; $n++) {
  $tp = $tp[$n];
  $rh = $rh[$n];
  $td = &rh2td($tp,$rh);
  $tp = &nint($tp * 10); 
  $td = &nint($td * 10); 
  $rh = &nint($rh);
  $spd = &nint($spd[$n] * 10);
  $dir = &nint($dir[$n]);
  $gust = &nint($gust[$n] * 10);

  $query = "replace into $wxtable set staname='$stid', time='$dbtime[$n]'";
  $query .= ", temp=$tp";
  $query .= ", dewp=$td";
  $query .= ", rh=$rh";
  $query .= ", wspd=$spd";
  $query .= ", wdir=$dir";
  $query .= ", gust=$gust";
# print "$query\n";

  $table_input = $db->prepare($query);
  $table_input->execute;
  $table_input->finish;

}

# Disconnect from the db.

$db->disconnect;

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

################################################################################

sub rh2td {

# Compute dew point (F) from temperature (F) and RH (percent).

  my ($t, $rh) = @_;
  my $rvolv = 0.0001846;  # rv/lv (461.5/2.5e6)

  my $tpk = (($t - 32) / 1.8) + 273.15;
  my $rhp = $rh / 100;
  $rhp = 1 if ($rhp > 1);
  my $td = $tpk / ((-$rvolv * log($rhp) * $tpk) + 1);
  $td = $tpk if ($td > $tpk);
  $td = (($td - 273.15) * 1.8) + 32;
  $td;
}
1;
