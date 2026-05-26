#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;
use DateTime;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Setup command line options:
#  -s station name

use vars qw($opt_s);
getopt('s');

my $root = "/home/caic/caic/rtsys/obs/provider/usgs";

# Define db station names.

my %stid = qw(
               berthoudpass USBTP
               senbeck USSBK
               blueridge USBLR
               devilsthumb USDVT
               ranchmeadow USRCM
               indypass USINP
               chairmtn USCHM
               ptarmigan USPTA
               huntercreek USHCR
               cameronpass USCMP
               bossbasin USBBN
               lakeirwin USLIR
               taylorpass USTLP
             );

my ($staname,$stid);
if (defined($opt_s)) {
  $staname = $opt_s;
  $stid = $stid{$staname};
} else {
  print "station name not specified\n";
  exit;
}
my $obsfile = "$root/data/$staname.csv";
print "$obsfile\n";

# Connect to the weather database.

my %attr = (RaiseError=>1,  # error handling enabled 
     AutoCommit=>0); # transaction enabled

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

print "Connecting to local database: $dbname as user: $user\n";
my $db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Read and parse obs data, then insert into db.

my ($yyyy,$mm,$dd,$hh,$gyyy,$gm,$gd,$gh,$daylight,$otime);

open(FH, '<', $obsfile) or die $!;

my (@words,$id,$nid,%index,$tz,$yy,$mm,$dd,$hh,$mn,$dbtime
   ,$query,$table_input
   ,$tp,$rh,$td,$ws,$wd,$pr,$hs,$swe,$swi,$swo,$lwi,$lwo);
my @dbtime;
my $nt = -1;
while(<FH>){
  if (index($_, "agency_cd") == 0) {
    @words = split("\t");
    $nid = 0;
    foreach $id (@words) {
      $index{hs}  = $nid if (substr($id,-5) eq "72189");
      $index{tp}  = $nid if (substr($id,-5) eq "00020");
      $index{wd}  = $nid if (substr($id,-5) eq "00036");
      $index{pr}  = $nid if (substr($id,-5) eq "00025");
      $index{rh}  = $nid if (substr($id,-5) eq "00052");
      $index{ws}  = $nid if (substr($id,-5) eq "00035");
      $index{pr}  = $nid if (substr($id,-5) eq "00025");
      $index{swe} = $nid if (substr($id,-5) eq "72341");
      $index{swi} = $nid if (substr($id,-5) eq "72186");
      $index{swo} = $nid if (substr($id,-5) eq "72185");
      $index{lwi} = $nid if (substr($id,-5) eq "72175");
      $index{lwo} = $nid if (substr($id,-5) eq "72174");
      ++$nid; 
    }
  }
  next if (index($_, "USGS") != 0);
  ++$nt;
  @words = split("\t");
  $tz = $words[3];
  $yy = substr($words[2],0,4);
  $mm = substr($words[2],5,2);
  $dd = substr($words[2],8,2);
  $hh = substr($words[2],11,2);
  $mn = substr($words[2],14,2);
  $otime = &time_to_unix($mm,$dd,$yy,$hh,$mn,0);
  $otime += 25200 if ($tz eq "MST");
  $otime += 21600 if ($tz eq "MDT");
  ($yy, $mm, $dd, $hh, $mn) = &unix_to_time($otime);
  $dbtime = sprintf("%04d-%02d-%02d %02d:%02d",$yy,$mm,$dd,$hh,$mn);
  if (defined($index{hs}))  { $hs  = $words[$index{hs}]; }  else { $hs  = ""; }
  if (defined($index{tp}))  { $tp  = $words[$index{tp}]; }  else { $tp  = ""; }
  if (defined($index{rh}))  { $rh  = $words[$index{rh}]; }  else { $rh  = ""; }
  if (defined($index{ws}))  { $ws  = $words[$index{ws}]; }  else { $ws  = ""; }
  if (defined($index{wd}))  { $wd  = $words[$index{wd}]; }  else { $wd  = ""; }
  if (defined($index{pr}))  { $pr  = $words[$index{pr}]; }  else { $pr  = ""; }
  if (defined($index{swe})) { $swe = $words[$index{swe}]; } else { $swe = ""; }
  if (defined($index{swi})) { $swi = $words[$index{swi}]; } else { $swi = ""; }
  if (defined($index{swo})) { $swo = $words[$index{swo}]; } else { $swo = ""; }
  if (defined($index{lwi})) { $lwi = $words[$index{lwi}]; } else { $lwi = ""; }
  if (defined($index{lwo})) { $lwo = $words[$index{lwo}]; } else { $lwo = ""; }

  $query = "insert ignore into $wxtable set staname='$stid', time='$dbtime'";
  if ($tp ne "" && $rh ne "") {
    $td = &rh2td($tp,$rh);
    $td = &nint($td*18 + 320); 
  } else {
    $td = "";
  }
  if ($tp ne "") {
    $tp = &nint($tp*18 + 320);
    $query .= ", temp=$tp";
  }
  $query .= ", dewp=$td" if ($td ne "");
  if ($rh ne "") {
    $rh = &nint($rh);
    $query .= ", rh=$rh";
  }
  if ($ws ne "") {
    $ws = &nint($ws*10);
    $query .= ", wspd=$ws";
  }
  $query .= ", wdir=$wd" if ($wd ne "");
# if ($pr ne "") {
#   $pr = &nint($pr*0.0393701);
#   $query .= ", mslp=$pr";
# }
# print "$query\n";

  $table_input = $db->prepare($query);
  $table_input->execute;
  $table_input->finish;

  $query = "replace into $snowtable set staname='$stid', time='$dbtime'";
  if ($hs ne "") {
    $hs = &nint($hs*393.701);
    $query .= ", depth=$hs";
  }
  if ($swe ne "") {
    $swe = &nint($swe*3.93701);
    $query .= ", snowwater=$swe";
  }
# print "$query\n";

  $table_input = $db->prepare($query);
  $table_input->execute;
  $table_input->finish;

  $query = "replace into $solartable set staname='$stid', time='$dbtime'";
  if ($swi ne "") {
    if ($swi < 0) {
      $swi = 0;
      $swo = 0;
    }
    $swi = &nint($swi*10);
    $query .= ", swin=$swi";
  }
  if ($swo ne "") {
    $swo = &nint($swo*10);
    $swo = 0 if ($swo < 0);
    $query .= ", swout=$swo" if ($swo < 20000);
  }
  if ($lwi ne "") {
    $lwi = &nint($lwi*10);
    $query .= ", lwin=$lwi";
  }
  if ($lwo ne "") {
    $lwo = &nint($lwo*10);
    $lwo = 0 if ($lwo < 0);
    $query .= ", lwout=$lwo";
  }
# print "$query\n";

  $table_input = $db->prepare($query);
  $table_input->execute;
  $table_input->finish;
}

close(FH);

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

# Compute dew point from temperature (C) and RH (percent).

  my ($t, $rh) = @_;
  my $rvolv = 0.0001846;  # rv/lv (461.5/2.5e6)

  my $tpk = $t + 273.15;
  my $rhp = $rh / 100;
  $rhp = 1 if ($rhp > 1);
  my $td = $tpk / ((-$rvolv * log($rhp) * $tpk) + 1);
  $td = $tpk if ($td > $tpk);
  $td -= 273.15;
  $td;
}
1;
