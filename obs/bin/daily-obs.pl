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

my $time0 = timelocal(0, 0, 0, $dd, $mm-1, $yyyy-1900);
($yyyy, $mm, $dd, $hh) = &unix_to_time($time0);
my $edate = sprintf("%04d-%02d-%02d %02d:00",$yyyy,$mm,$dd,$hh);

($yyyy, $mm, $dd) = &unix_to_time($time0-$lookback*86400);
$time0 = timelocal(0, 0, 0, $dd, $mm-1, $yyyy-1900);
($yyyy, $mm, $dd, $hh) = &unix_to_time($time0);
my $sdate0 = sprintf("%04d-%02d-%02d %02d:00",$yyyy,$mm,$dd,$hh);

# Connect to the weather database.

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

my $db = DBI->connect("DBI:mysql:$dbname;host=$host", $user, $password);

# Read data for each station.

my ($stn,$t,$query,$table_input,$sth,$n,$nrows
   ,$tpct,$spdct,$dirct,$gustct
   ,$sdate,$sndate,$time,$stime,$sntime,$dbdate,$month
   ,$tp,$spd,$dir,$gust,$hs,$swe,$hn24,$hsm1
   ,$tpavg,$tpmax,$tpmin,$spdavg,$uavg,$vavg,$diravg,$gustavg,$gustmax);

my @stn = qw(
             TOWC2 
             STORM 
             COLC2 
             LOTC2 
             CALT9 
             CACMP 
             CABTP 
             KC07
             K0CO
             JNPC2
             RCPC2
             CALVP
             CAVLP
             LBAC2
             BTSC2
             JWRC2
             BLKC2
             CAVCB
             CAABT
             CAABP
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
             CALCK
             KCCU
             VLMC2
             CO126
             CO157
             CO159
             USBTP
             WLLC2
             NEVC2
            );

foreach $stn (@stn) {

  $sdate = $sdate0;
  $time = $time0;
  $hsm1 = 9999;
  for ($t=0; $t<$lookback; $t++) {
    ($yyyy, $mm, $dd) = &unix_to_time($time+86400);
    $time = timelocal(0, 0, 0, $dd, $mm-1, $yyyy-1900);
    ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
    $edate = sprintf("%04d-%02d-%02d %02d:00",$yyyy,$mm,$dd,$hh);
    ($yyyy, $mm, $dd, $hh) = &unix_to_time($time-61200);
    $sndate = sprintf("%04d-%02d-%02d %02d:00",$yyyy,$mm,$dd,$hh);
print "sndate $sndate\n";

# Read weather data.

    $query = "select time,temp,wspd,wdir,gust from $wxtable where time>='$sdate' and time<='$edate' and staname='$stn' order by time";

    $table_input = $db->prepare($query);
    $table_input->execute;

    $nrows = $table_input->rows;
    $nrows = 0 if ($nrows > 999999);
    $tpavg = 0;
    $tpmax = -999;
    $tpmin = 9999;
    $spdavg = 0;
    $uavg = 0;
    $vavg = 0;
    $gustavg = 0;
    $gustmax = -1;
    $tpct = 0;
    $spdct = 0;
    $dirct = 0;
    $gustct = 0;
    for ($n=0; $n<$nrows; $n++) {
      ($stime,$tp,$spd,$dir,$gust) = $table_input->fetchrow;
      if (defined $tp) {
        $tp /= 10;
        $tpavg += $tp;
        $tpmax = $tp if ($tp > $tpmax);
        $tpmin = $tp if ($tp < $tpmin);
        ++$tpct;
      }
      if (defined $spd) {
        $spd /= 10;
        $spdavg += $spd;
        ++$spdct;
        if (defined $dir) {
          $uavg += $spd * -sin($dir/$r2d);
          $vavg += $spd * -cos($dir/$r2d);
          ++$dirct;
        }
      }
      if (defined $gust) {
        $gust /= 10;
        $gustavg += $gust;
        $gustmax = $gust if ($gust > $gustmax);
        ++$gustct;
      }
    }
    $dbdate = substr($sdate,0,10);
    $month = substr($sdate,5,2);
    if ($tpct > 20) {
      $tpavg /= $tpct;
      $tpavg = &nint($tpavg*10);
      $tpmax = &nint($tpmax*10);
      $tpmin = &nint($tpmin*10);
    } else {
      $tpavg = -999;
      $tpmax = -999;
      $tpmin = -999;
    }
    if ($spdct > 20) {
      $spdavg /= $spdct;
      $spdavg = &nint($spdavg*10);
    } else {
      $spdavg = 9999;
    }
    if ($dirct > 20) {
      $diravg = atan2(-$uavg/$dirct,-$vavg/$dirct) * $r2d;
      $diravg += 360 if ($diravg < 0);
      $diravg = &nint($diravg);
    } else {
      $diravg = 9999;
    }
    if ($gustct > 20) {
      $gustavg /= $gustct;
      $gustavg = &nint($gustavg*10);
      $gustmax = &nint($gustmax*10);
    } else {
      $gustavg = 9999;
      $gustmax = 9999;
    }

# Read snow data.

    $query = "select depthQC,snowwater,snow24h from $snowtable where time='$sndate' and staname='$stn'";

    $table_input = $db->prepare($query);
    $table_input->execute;

    $nrows = $table_input->rows;
    $nrows = 0 if ($nrows > 999999);
    $hs = 9999;
    $swe = 9999;
    $hn24 = 9999;
    for ($n=0; $n<$nrows; $n++) {
      ($hs,$swe,$hn24) = $table_input->fetchrow;
      $hs = 9999 if (! defined $hs);
      $swe = 9999 if (! defined $swe);
      $hn24 = 9999 if (! defined $hn24);
    }
    if ($month > 6 && $month <= 13) {
      $hs = 9999 if ($hs > 1000);
    }
    if ($hn24 > 1000) {
      $hn24 = $hs - $hsm1 if ($hs < 9999 && $hsm1 < 9999)
    }
    $hn24 = 0 if ($hn24 < 0);
    $hsm1 = $hs;

# Write daily data.

    $query = "insert into $dailytable (date,staname,tempavg,tempmax,tempmin,spdavg,diravg,gustavg,gustmax,hn24,hs,swe) values (?,?,?,?,?,?,?,?,?,?,?,?) on duplicate key update tempavg=?, tempmax=?, tempmin=?, spdavg=?, diravg=?, gustavg=?, gustmax=?, hn24=?, hs=?, swe=?";
    print "$dbdate $stn\n" ; 
    $sth = $db->prepare($query);
    $sth->execute($dbdate,$stn,$tpavg,$tpmax,$tpmin,$spdavg,$diravg,$gustavg,$gustmax,$hn24,$hs,$swe,$tpavg,$tpmax,$tpmin,$spdavg,$diravg,$gustavg,$gustmax,$hn24,$hs,$swe);
    $sth->finish;

    $table_input->finish;
    $sdate = $edate;
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
