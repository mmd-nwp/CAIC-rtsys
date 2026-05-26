#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;
use Time::Local;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Setup command line options:
#  -d date (YYMMDD (local time), default = current)
#  -l lookback period (days, default = 7 days)

use vars qw($opt_d $opt_l);
getopt('dl');

my $pi  = atan2(1,1) * 4;
my $r2d = 180 / $pi;

# Determine default time based on current time.

my ($yyyy, $yy, $mm, $dd, $jjj, $hh, $mn, $ss);
($ss, $mn, $hh, $dd, $mm, $yyyy) = (localtime(time))[0,1,2,3,4,5,6];
$yyyy += 1900;
++$mm;

# Override default times based on command line option, if present.

if (defined $opt_d) {
  $_ = $opt_d;
  if (/^(\d\d)(\d\d)(\d\d)$/) {
    $yy = $1;
    $mm = $2;
    $dd = $3;
    $yyyy = $yy + 2000;
  } else {
    print "Invalid date format - YYMMDD\n";
    exit;
  }
}

# Override lookback period based on command line option, if present.

my $lookback = 7;
$lookback = $opt_l if (defined $opt_l);

my $time0 = timelocal(0, 0, $hh, $dd, $mm-1, $yyyy-1900);
($yyyy, $mm, $dd, $hh) = &unix_to_time($time0);
my $edate = sprintf("%04d-%02d-%02d %02d:00",$yyyy,$mm,$dd,$hh);

($yyyy, $mm, $dd, $hh) = &unix_to_time($time0-$lookback*86400);
my $sdate = sprintf("%04d-%02d-%02d %02d:00",$yyyy,$mm,$dd,$hh);

# Connect to the weather database.

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

my $db = DBI->connect("DBI:mysql:$dbname;host=$host", $user, $password);

# Read data for each station.

my ($stn,$ct,$query,$table_input,$sth,$m,$n,$nrows
   ,@time,$stime,$dbdate,$month
   ,$hs,@hs,$swe,$hn24,$start,$last,$sct,$act,$ave,$msg,$nmsg,$diff);

my @stn = qw(
             TOWC2 
             STORM 
             COLC2 
             LOTC2 
             CALT9 
             CACMP 
             CABTP 
             KC07
             RCPC2
             CALVP
             CAVLP
             LBAC2
             BTSC2
             JWRC2
             BLKC2
             CAVCB
             CAABT
             CAABM
             CABP6
             CAVPQ
             GZPC2
             CPMC2
             HOOC2
             CAMTZ
             CAMNP
             CACWP
             KMYP
             FMTC2
             BRMC2
             CTEC2
             PRPC2
             CACCK
             SOSC2
             CATLS
             CALOG
             CACL9
             IDPC2
             CAINP
             MCPC2
             CASCP
             CACB1
             CAIRW
             UPTC2
             PKCC2
             CACNM
             CAGMS
             PRVC2
             OVRC2
             MESC2
             CAPTY
             CAEGE
             CAGDH
             RMPC2
             CATEL
             LIZC2
             CAMLP
             CAWCP
             WCSC2
             CMBC2
             CACBP
             VALC2
             CD078
             TCHC2
             UTCC2
             SCYC2
             WSKC2
             MDPC2
             USBTP
             WLLC2
             NEVC2
             JNPC2
             VLMC2
            );

foreach $stn (@stn) {

# Read snow data.

  $query = "select time,depth from $snowtable where time>='$sdate' and time<='$edate' and staname='$stn'";

  $table_input = $db->prepare($query);
  $table_input->execute;

  $nrows = $table_input->rows;
  $nrows = 0 if ($nrows > 999999);
  $ct = 0;
  for ($n=0; $n<$nrows; $n++) {
    ($time[$ct],$hs[$ct]) = $table_input->fetchrow;
    $hs[$ct] = 9999 if (! defined $hs[$ct]);
    ++$ct;
  }
  $table_input->finish;

# Loop through time series and fill in missing data with interpolated data.

  for ($n=0; $n<$ct; $n++) {
    if ($hs[$n] < 9999) {
      $last = $hs[$n];
      last;
    }
  }
  if ($last >= 9999) {
    print "No data for station: $stn\n";
    next;
  }
  $start = $n + 1;

  $msg = 0; 
  for ($n=$start; $n<$ct; $n++) {
    if ($n > $start+24) {
      $ave = 0;
      $act = 0;
      for ($m=$n-24; $m<$n; $m++) {
        if ($hs[$m] < 9999) {
          $ave += $hs[$m];
          ++$act;
        }
      }
      if ($act > 0) {
        $ave /= $act
      } else {
        $ave = 9999;
      }
    }
    $hs[$n] = 9999 if ($hs[$n] > $ave+120 && $ave < 9999);
    if ($hs[$n] >= 9999) {
      $msg = 1;
      next;
    }
    $nmsg = 0;
    if ($msg) {
      $nmsg = $n - $sct - 1;
      if ($nmsg < 25) {
        $diff = ($hs[$sct+$nmsg+1] - $hs[$sct]) / ($nmsg + 1);
        for ($m=$sct+1; $m<=$sct+$nmsg; $m++) {
          $hs[$m] = $hs[$m-1] + $diff;
        }
      }
      $msg = 0;
    }
    $sct = $n;
  }

# if ($month > 6 && $month <= 13) {
#   $hs = 9999 if ($hs > 1000);
# }

# Write QC data data.

  print "$stn\n";
  for ($n=0; $n<$ct; $n++) {
    $hs = &nint($hs[$n]);
    $query = "update $snowtable set depthQC=$hs where time='$time[$n]' and staname='$stn'";
    $sth = $db->prepare($query);
    $sth->execute;
    $sth->finish;
  }
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
