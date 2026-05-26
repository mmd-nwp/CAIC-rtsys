#!/usr/bin/perl
use strict;
use Scalar::Util qw(looks_like_number);
use DBI;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

my $obsfile = "/home/caic/caic/rtsys/obs/provider/aspen/data/aspen.txt";

# Determine current time.

my $stime = time(); # Greenwich time.
my ($lyyy) = &unix_to_time($stime);

# Read and extract the data.

my ($yyyy,$mm,$dd,$hh,$gyyy,$gm,$gd,$gh,$daylight,$otime);

open(FH, '<', $obsfile) or die $!;

my (@words,$dt,@dbtime,$dbtime
   ,@top_tp1,@top_tp2,@top_rh,@top_hn24,@top_hs
   ,@wind_spd,@wind_dir,@wind_gust
   ,@mid_tp1,@mid_tp2,@mid_rh,@mid_hn24,@mid_hs
   ,$tp,$rh,$spd,$dir,$gust,$hn24,$hs,$td);
my $nt = -1;
while(<FH>){
  last if ($nt > 0 && length eq 2);
  if (substr($_,0,3) eq "---") {
    ++$nt;
    next;
  }
  next if ($nt < 0);
  @words = split;
  $dbtime[$nt] = "$words[0]-$words[1]";
  $yyyy = $lyyy;
  --$yyyy if ($dbtime[$nt] eq "12-31");
  $dbtime[$nt] = "$yyyy-$dbtime[$nt] ".substr($words[2],0,2);
  $top_tp1[$nt] = substr($_,21,3);
  $top_tp2[$nt] = substr($_,29,3);
  $top_rh[$nt] = substr($_,37,3);
  $top_hn24[$nt] = substr($_,44,4);
  $top_hs[$nt] = substr($_,53,3);
  $wind_spd[$nt] = substr($_,61,3);
  $wind_gust[$nt] = substr($_,69,3);
  $wind_dir[$nt] = substr($_,77,3);
  $mid_tp1[$nt] = substr($_,93,3);
  $mid_tp2[$nt] = substr($_,101,3);
  $mid_rh[$nt] = substr($_,109,3);
  $mid_hn24[$nt] = substr($_,118,2);
  $mid_hs[$nt] = substr($_,125,3);
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

my ($n,$query,$table_input,$stid);
for ($n=0; $n<$nt; $n++) {
  $yyyy = substr($dbtime[$n],0,4);
  $mm = substr($dbtime[$n],5,2);
  $dd = substr($dbtime[$n],8,2);
  $hh = substr($dbtime[$n],11,2);
  $otime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0) + 25200;  # MST to UTC
# $otime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0) + 21600;  # MDT to UTC
  ($yyyy,$mm,$dd,$hh) = &unix_to_time($otime);
  $dbtime = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,0,0);

# Ajax top.

  if (looks_like_number($top_tp1[$n])) {
    $tp = ($top_tp1[$n] + $top_tp2[$n]) / 2;
    $rh = $top_rh[$n];
    $td = &rh2td($tp,$rh);
    $tp = &nint($tp * 10); 
    $td = &nint($td * 10); 
    $rh = &nint($rh);

    $stid = "CAAXT";
    $query = "insert into $wxtable (staname,time,temp,dewp,rh) values (";
    $query .= "'$stid'";
    $query .= ",'$dbtime'";
    $query .= ",$tp";
    $query .= ",$td";
    $query .= ",$rh";
    $query .= ")";
    $query .= " on duplicate key update";
    $query .= " temp=values(temp)";
    $query .= ",dewp=values(dewp)";
    $query .= ",rh=values(rh)";
#   print "$query\n";

    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
  }

  if (looks_like_number($top_hn24[$n])) {
    $hn24 = &nint($top_hn24[$n] * 10);
    $hn24 = 0 if ($hn24 < 0);
    $hs = &nint($top_hs[$n] * 10);
    $hs = 0 if ($hs < 0);

    $query = "insert into $snowtable (staname,time,snow24h,depth) values (";
    $query .= "'$stid'";
    $query .= ",'$dbtime'";
    $query .= ",$hn24";
    $query .= ",$hs";
    $query .= ")";
    $query .= " on duplicate key update";
    $query .= " snow24h=values(snow24h)";
    $query .= ",depth=values(depth)";
#   print "$query\n";

    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
  }

# Ajax wind.

  if (looks_like_number($wind_spd[$n])) {
    $spd = &nint($wind_spd[$n] * 10);
    $gust = &nint($wind_gust[$n] * 10);
    if ($wind_dir[$n] eq "  N") {
      $dir = 0;
    } elsif ($wind_dir[$n] eq "NNE") {
      $dir = 23;
    } elsif ($wind_dir[$n] eq " NE") {
      $dir = 45;
    } elsif ($wind_dir[$n] eq "ENE") {
      $dir = 68;
    } elsif ($wind_dir[$n] eq "  E") {
      $dir = 90;
    } elsif ($wind_dir[$n] eq "ESE") {
      $dir = 113;
    } elsif ($wind_dir[$n] eq " SE") {
      $dir = 135;
    } elsif ($wind_dir[$n] eq "SSE") {
      $dir = 158;
    } elsif ($wind_dir[$n] eq "  S") {
      $dir = 180;
    } elsif ($wind_dir[$n] eq "SSW") {
      $dir = 203;
    } elsif ($wind_dir[$n] eq " SW") {
      $dir = 225;
    } elsif ($wind_dir[$n] eq "WSW") {
      $dir = 248;
    } elsif ($wind_dir[$n] eq "  W") {
      $dir = 270;
    } elsif ($wind_dir[$n] eq "WNW") {
      $dir = 293;
    } elsif ($wind_dir[$n] eq " NW") {
      $dir = 315;
    } elsif ($wind_dir[$n] eq "NNW") {
      $dir = 338;
    }

    $stid = "CAAXW";
    $query = "insert into $wxtable (staname,time,wspd,wdir,gust) values (";
    $query .= "'$stid'";
    $query .= ",'$dbtime'";
    $query .= ",$spd";
    $query .= ",$dir";
    $query .= ",$gust";
    $query .= ")";
    $query .= " on duplicate key update";
    $query .= " wspd=values(wspd)";
    $query .= ",wdir=values(wdir)";
    $query .= ",gust=values(gust)";
#   print "$query\n";

    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
  }

# Ajax mid.

  if (looks_like_number($mid_tp1[$n])) {
    $tp = ($mid_tp1[$n] + $mid_tp2[$n]) / 2;
    $rh = $mid_rh[$n];
    $td = &rh2td($tp,$rh);
    $tp = &nint($tp * 10); 
    $td = &nint($td * 10); 
    $rh = &nint($rh);

    $stid = "CAAXM";
    $query = "insert into $wxtable (staname,time,temp,dewp,rh) values (";
    $query .= "'$stid'";
    $query .= ",'$dbtime'";
    $query .= ",$tp";
    $query .= ",$td";
    $query .= ",$rh";
    $query .= ")";
    $query .= " on duplicate key update";
    $query .= " temp=values(temp)";
    $query .= ",dewp=values(dewp)";
    $query .= ",rh=values(rh)";
#   print "$query\n";

    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
  }

  if (looks_like_number($mid_hn24[$n])) {
    $hn24 = &nint($mid_hn24[$n] * 10);
    $hn24 = 0 if ($hn24 < 0);
    $hs = &nint($mid_hs[$n] * 10);
    $hs = 0 if ($hs < 0);

    $query = "insert into $snowtable (staname,time,snow24h,depth) values (";
    $query .= "'$stid'";
    $query .= ",'$dbtime'";
    $query .= ",$hn24";
    $query .= ",$hs";
    $query .= ")";
    $query .= " on duplicate key update";
    $query .= " snow24h=values(snow24h)";
    $query .= ",depth=values(depth)";
#   print "$query\n";

    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
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

# Compute dew point from temperature (F) and RH (percent).

  my ($t, $rh) = @_;
  my $rvolv = 0.0001846;  # rv/lv (461.5/2.5e6)
  my $td;

  if (looks_like_number($t) && looks_like_number($rh)) {

    my $tpk = ($t - 32 / 1.8) + 273.15;
    my $rhp = $rh / 100;
    $rhp = 1 if ($rhp > 1);
    $td = $tpk / ((-$rvolv * log($rhp) * $tpk) + 1);
    $td = $tpk if ($td > $tpk);
    $td = (($td - 273.15) * 1.8) + 32; 
  } else {
    $td = "";
  }
  $td;
}
1;
