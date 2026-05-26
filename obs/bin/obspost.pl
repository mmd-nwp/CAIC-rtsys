#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Script to generate:
#   24-h max and min temp for all stations.
#   1-h precip from 5-min precip.
#   24-h precip from 1-h precip.

# Command line options:
#  -t end time (yymmddhh, default = current)
#  -s span (hours, default = 6)
#  -o specify a single station 

use vars qw($opt_t $opt_s $opt_o);
getopt('tso');

my $span = 6;
$span = $opt_s if (defined($opt_s));

my $wxstn = "";
$wxstn = $opt_o if (defined($opt_o));

# Determine the time from argument or current time (default).

my $time = time;
my ($yyyy,$yy,$mm,$dd,$hh,$mn,$starttime,$pcptime,$endtime);
if ($opt_t) {
  $yy = substr($opt_t,0,2);
  $mm = substr($opt_t,2,2);
  $dd = substr($opt_t,4,2);
  $hh = substr($opt_t,6,2);
  $yyyy = 2000 + $yy;
  $time = &time_to_unix($mm, $dd, $yyyy, $hh);
}
($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($time);
$endtime = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,$mn,0);
$starttime = $time - 90000 - 3600*($span-1);
($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($starttime);
$starttime = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,$mn,0);
$pcptime = $time - 3600*$span;
($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($pcptime);
$pcptime = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,$mn,0);

# Define variables.

my ($nrows,$npcp,$n,$p,$r,$c,$ct,$stn,$staname,$stime,$dbtime,$diff,@time,@tp,$tp,$pcp5m,$pcp1,$pcp24,$pcp
   ,$tempmx,$tempmn,$tpmn,$tpmx,$dump);
my ($db,$query,$table_input,$table_output,$pcp_output);

# Connect to the weather database.

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

print "Connecting to local database: $dbname as user: $user\n";
$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Read data from obsWX table and dump max/min temp to db..

if ($wxstn ne "") {
  $query = "select staname,time,temp from $wxtable where staname='$wxstn' and time>='$starttime' and time<='$endtime' order by staname,time";
} else {
  $query = "select staname,time,temp from $wxtable where time>='$starttime' and time<='$endtime' order by staname,time";
}

$table_output = $db->prepare($query);
$table_output->execute;

$nrows = $table_output->rows;
$nrows = 0 if ($nrows > 999999);

my $sth;
$db->begin_work();

$stn = "first";
$ct = 0;
for ($n=0; $n<$nrows; $n++) {
  ($staname,$stime,$tp) = $table_output->fetchrow;
  $stn = $staname if ($stn eq "first");
  if ($staname ne $stn) {
    &dump_mxmn();
    $ct = 0;
    $stn = $staname;
  }
  if (defined $tp) {
    $yyyy = substr($stime,0,4);
    $mm = substr($stime,5,2);
    $dd = substr($stime,8,2);
    $hh = substr($stime,11,2);
    $mn = substr($stime,14,2);
    $time[$ct] = &time_to_unix($mm, $dd, $yyyy, $hh, $mn);
    $tp[$ct] = $tp;
    ++$ct;
  }
}

&dump_mxmn();

$table_output->finish;

# Read data from obsHydro and update 1-h and 24-h accumulated precip.

# Accumulated precip using 5-min obs.

if ($wxstn ne "") {
  $query = "select staname,time,pcp5m from $hydrotable where staname='$wxstn' and time>='$pcptime' and time<='$endtime' order by staname,time";
} else {
  $query = "select staname,time,pcp5m from $hydrotable where time>='$pcptime' and time<='$endtime' order by staname,time";
}

$table_output = $db->prepare($query);
$table_output->execute;
$nrows = $table_output->rows;
$nrows = 0 if ($nrows > 999999);

for ($n=0; $n<$nrows; $n++) {
  ($staname,$stime,$pcp5m) = $table_output->fetchrow;
  if (defined $pcp5m) {

# 1-h accumulation.

    $yyyy = substr($stime,0,4);
    $mm = substr($stime,5,2);
    $dd = substr($stime,8,2);
    $hh = substr($stime,11,2);
    $mn = substr($stime,14,2);
    $time = &time_to_unix($mm,$dd,$yyyy,$hh,$mn,0);
    $time -= 3600;
    ($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($time);
    $dbtime = sprintf("%04d-%02d-%02d %02d:%02d",$yyyy,$mm,$dd,$hh,$mn);
    $query = "select sum(pcp5m) from $hydrotable where time>'$dbtime:00' and time<='$stime' and staname='$staname'";
#   print "$query\n";
    $pcp_output = $db->prepare($query);
    $pcp_output->execute;
    $npcp = $pcp_output->rows;
    $npcp = 0 if ($npcp > 999999);
#   print "$query\n";
    for ($p=0; $p<$npcp; $p++) {
      $pcp = $pcp_output->fetchrow;
    }
    $pcp_output->finish;
    $pcp = &nint($pcp/10);
    $query = "update $hydrotable set pcp1=$pcp where staname='$staname' and time='$stime'";
#   print "$query\n";
    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;

# 24-h accumulation.

    $yyyy = substr($stime,0,4);
    $mm = substr($stime,5,2);
    $dd = substr($stime,8,2);
    $hh = substr($stime,11,2);
    $mn = substr($stime,14,2);
    $time = &time_to_unix($mm,$dd,$yyyy,$hh,$mn,0);
    $time -= 86400;
    ($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($time);
    $dbtime = sprintf("%04d-%02d-%02d %02d:%02d",$yyyy,$mm,$dd,$hh,$mn);
    $query = "select sum(pcp5m) from $hydrotable where time>'$dbtime:00' and time<='$stime' and staname='$staname'";
#   print "$query\n";
    $pcp_output = $db->prepare($query);
    $pcp_output->execute;
    $npcp = $pcp_output->rows;
    $npcp = 0 if ($npcp > 999999);
#   print "$query\n";
    for ($p=0; $p<$npcp; $p++) {
      $pcp = $pcp_output->fetchrow;
    }
    $pcp_output->finish;
    $pcp = &nint($pcp/10);
    $query = "update $hydrotable set pcp24=$pcp where staname='$staname' and time='$stime'";
#   print "$query\n";
    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;

  }

}
$table_output->finish;

# Accumulated precip using 1-h obs.

if ($wxstn ne "") {
  $query = "select staname,time,pcp1,pcp24 from $hydrotable where staname='$wxstn' and time>='$pcptime' and time<='$endtime' order by staname,time";
} else {
  $query = "select staname,time,pcp1 from $hydrotable where time>='$pcptime' and time<='$endtime' order by staname,time";
}

$table_output = $db->prepare($query);
$table_output->execute;
$nrows = $table_output->rows;
$nrows = 0 if ($nrows > 999999);

for ($n=0; $n<$nrows; $n++) {
  ($staname,$stime,$pcp1,$pcp24) = $table_output->fetchrow;
  if (defined $pcp1 && ! defined $pcp24) {
    $yyyy = substr($stime,0,4);
    $mm = substr($stime,5,2);
    $dd = substr($stime,8,2);
    $hh = substr($stime,11,2);
    $mn = substr($stime,14,2);
    $time = &time_to_unix($mm,$dd,$yyyy,$hh,$mn,0);
    $time -= 86400;
    ($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($time);
    $dbtime = sprintf("%04d-%02d-%02d %02d:%02d",$yyyy,$mm,$dd,$hh,$mn);
    $query = "select sum(pcp1) from $hydrotable where time>'$dbtime:00' and time<='$stime' and minute(time)=$mn and staname='$staname'";
#   print "$query\n";
    $pcp_output = $db->prepare($query);
    $pcp_output->execute;
    $npcp = $pcp_output->rows;
    $npcp = 0 if ($npcp > 999999);
    for ($p=0; $p<$npcp; $p++) {
      $pcp = $pcp_output->fetchrow;
    }
    $pcp_output->finish;
    $query = "update $hydrotable set pcp24=$pcp where staname='$staname' and time='$stime'";
#   print "$query\n";
    if ($pcp >= 0 && $pcp < 1000) {
      $table_input = $db->prepare($query);
      $table_input->execute;
      $table_input->finish;
    }
  }
}
$table_output->finish;

$db->commit();
$db->disconnect;

exit;

#===============================================================================
#
# Compute max/min temperature for each station and update database.

sub dump_mxmn {
  for ($r=$ct-1; $r>=0; $r--) {
    &mxmn() if ($time - $time[$r]) < $span*3600;
  }
}

#===============================================================================
#
# Generate max/min for an individual time period.

sub mxmn {
  ($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($time[$r]);
  $dbtime = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,$mn,0);
  $tpmx = -9999;
  $tpmn =  9999;
  for ($c=0; $c<=$r; $c++) {
    $diff = $time[$r]-$time[$c];
    next if ($diff > 86400);
    $tpmx = $tp[$c] if ($tp[$c] > $tpmx);
    $tpmn = $tp[$c] if ($tp[$c] < $tpmn);
    $diff = &nint($diff / 3600);
  }
  return if ($tpmx < -1000);
  $query = "update $wxtable set mxtemp24h='$tpmx', mntemp24h='$tpmn' where staname='$stn' and time='$dbtime'";
  $sth = $db->prepare($query);
  $sth->execute;
}

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

  my @answer = ($y, $m, $d, int($utm/3600), int(($utm%3600)/60), int($utm%60));

  @answer
}
1;

################################################################################
## &time_to_unix: Calculate unix time from month, day, year, hour, min, sec
## Arguments: month, day, year (4 digit), hour, min, sec
## Returns: unix time

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
