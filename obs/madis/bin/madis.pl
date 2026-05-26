#!/usr/bin/perl 
use strict;
use DBI;
use Getopt::Std;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Setup command line options:
#  -d date (UTC, YYMMDDHH, default = current)
#  -h hour (UTC, default = current)
#  -c cdot (process CDOT data only, yes = 1, default = 0)

use vars qw($opt_d $opt_h $opt_c);
getopt('dhc');

my $cdot = 0;
$cdot = 1 if (defined $opt_c);

my $outdir = "/home/caic/caic/rtsys/obs/madis/data/csv";

my @stid = qw(
              CAABP
              CAABM
              CAABT
              CACL9
              CALOG
              CANWD
              CAHPK
              CAAXB
              CAAXH
              CAAXM
              CAAXT
              CAAXW
              CAALP
              CABLD
              CABRN
              CAELK
              CAALT
              CATLS
              CAHSB
              CABP6
              CABP8
              CAABR
              CABTP
              CACMP
              CACBP
              CACWP
              CADGP
              CAEGE
              CAKDL
              CALCK
              CALVP
              CAMLP
              CAMON
              CARIC
              CAVLP
              CAWCP
              CAELT
              CABLG
              CACIN
              CALPG
              CAMCR
              CAWGH
              CAWWC
              CACB1
              CASCP
              CAIRW
              CAGMS
              CAKSS
              CAKWP
              CAKWS
              CAMNP
              CACNM
              CABPK
              CAFLC
              CAVBS
              CAVCB
              CAVMM
              CAVPQ
              CATEL
              CADYN
              CAGDH
              CAPBA
              MSMIN
             );

@stid = qw(CABLG CACIN) if ($cdot);

my $msg = -99;

# Determine default time based on current UTC time.

my $time = time;
my ($hh, $dd, $mm, $yyyy) = (gmtime($time))[2,3,4,5,6];
$yyyy += 1900;
++$mm;

# Override default times based on command line options, if present.

if (defined $opt_d) {
  $_ = $opt_d;
  if (/^(\d\d)(\d\d)(\d\d)(\d\d)$/) {
    $yyyy = $1;
    $mm = $2;
    $dd = $3;
    $hh = $4;
    $yyyy += 2000;
  } else {
    print "Invalid date format - YYMMDDHH\n";
    exit;
  }
} elsif (defined $opt_h) {
  $hh = $opt_h;
}
my $dbtime = sprintf("%04d-%02d-%02d %02d:00",$yyyy,$mm,$dd,$hh);
my $etime  = sprintf("%04d-%02d-%02d %02d:59",$yyyy,$mm,$dd,$hh);
print "$dbtime\n";

my ($n,$stn,%stid,$stime,%stime,$key
   ,$tp,$rh,$spd,$dir,$gust,$mslp,$pcp1m,$pcp5m,$pcp,$sn24,$snto
   ,%tp,%rh,%spd,%dir,%gust,%mslp,%pcp1m,%pcp5m,%pcp,%sn24,%snto);

my ($dbname,$user,$password,$host,$db,$query,$table_output,$nrows);

# Connect to the weather database.

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

print "Connecting to local database: $dbname as user: $user\n";
$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);
exit if (! $db);

# Loop through each station and query database.

foreach (@stid) {
  $stn = $_;
  $stid{$stn} = $stn;

  $query = "select time,temp,rh,wspd,wdir,gust,mslp from $wxtable where time>='$dbtime' and time<='$etime' and staname='$stn'";
  $table_output = $db->prepare($query);
  $table_output->execute;
  $nrows = $table_output->rows;
  $nrows = 0 if ($nrows > 999999);

  for ($n=0; $n<$nrows; $n++) {
    ($stime,$tp,$rh,$spd,$dir,$gust,$mslp) = $table_output->fetchrow;
    $key = "$stn$stime";
    $stime{$key} = $stime;
    $tp{$key} = $tp/10 if (defined $tp);
    $rh{$key} = $rh if (defined $rh);
    $spd{$key} = $spd/10 if (defined $spd);
    $dir{$key} = $dir if (defined $dir);
    $gust{$key} = $gust/10 if (defined $gust);
    $mslp{$key} = $mslp*0.02953 if (defined $mslp);  # mb -> in
  }

  $query = "select time,pcp1m,pcp5m,pcp1 from $hydrotable where time>='$dbtime' and time<='$etime' and staname='$stn'";
  $table_output = $db->prepare($query);
  $table_output->execute;
  $nrows = $table_output->rows;
  $nrows = 0 if ($nrows > 999999);

  for ($n=0; $n<$nrows; $n++) {
    ($stime,$pcp1m,$pcp5m,$pcp) = $table_output->fetchrow;
    $key = "$stn$stime";
    $stime{$key} = $stime;
    $pcp1m{$key} = $pcp1m/1000 if (defined $pcp1m);
    $pcp5m{$key} = $pcp5m/1000 if (defined $pcp5m);
    $pcp{$key} = $pcp/100 if (defined $pcp);
  }

  $query = "select time,snow24h,depth from $snowtable where time>='$dbtime' and time<='$etime' and staname='$stn'";
  $table_output = $db->prepare($query);
  $table_output->execute;
  $nrows = $table_output->rows;
  $nrows = 0 if ($nrows > 999999);

  for ($n=0; $n<$nrows; $n++) {
    ($stime,$sn24,$snto) = $table_output->fetchrow;
    $key = "$stn$stime";
    $stime{$key} = $stime;
    $sn24{$key} = $sn24/10 if (defined $sn24);
    $snto{$key} = $snto/10 if (defined $snto);
  }
}

$table_output->finish;
$db->disconnect;

$mm = "0$mm" while(length($mm) < 2);
$dd = "0$dd" while(length($dd) < 2);
$hh = "0$hh" while(length($hh) < 2);
my $outfile = "$outdir/$yyyy-$mm-$dd-$hh"."00.csv";

my $date;
print "$outfile\n";
open(OUT,">$outfile");
print OUT "id,date,temp(F),rh(%),spd(mph),dir(deg),gust(mph),mslp(inHg),precip1h(in),precip1m(in),precip5m(in),snowdepth(in),snow24h(in)\n";
foreach $key (sort keys %stime) {
  $date = $stime{$key};
  $date =~ s/-/\//g;
  $tp{$key} = $msg if (! defined($tp{$key}));
  $rh{$key} = $msg if (! defined($rh{$key}));
  $spd{$key} = $msg if (! defined($spd{$key}));
  $dir{$key} = $msg if (! defined($dir{$key}));
  $gust{$key} = $msg if (! defined($gust{$key}));
  $mslp{$key} = $msg if (! defined($mslp{$key}));
  if (defined($pcp1m{$key})) {
    $pcp1m{$key} = 0 if ($pcp1m{$key} < 0);
  } else {
    $pcp1m{$key} = $msg;
  }
  if (defined($pcp5m{$key})) {
    $pcp5m{$key} = 0 if ($pcp5m{$key} < 0);
  } else {
    $pcp5m{$key} = $msg;
  }
  if (defined($pcp{$key})) {
    $pcp{$key} = 0 if ($pcp{$key} < 0);
  } else {
    $pcp{$key} = $msg;
  }
  if (defined($snto{$key})) {
    $snto{$key} = $msg if ($snto{$key} < 0);
  } else {
    $snto{$key} = $msg;
  }
  if (defined($sn24{$key})) {
    $sn24{$key} = $msg if ($sn24{$key} < 0);
  } else {
    $sn24{$key} = $msg;
  }
  $pcp{$key} = $msg if (substr($key,0,5) eq "CAIRW");
  if ($tp{$key}>$msg || $rh{$key}>$msg || $spd{$key}>$msg || $dir{$key}>$msg || $gust{$key}>$msg || $mslp{$key}>$msg || $pcp{$key}>$msg || $snto{$key}>$msg || $sn24{$key}>$msg || $pcp1m{$key}>$msg || $pcp5m{$key}>$msg) {
    printf OUT "%-5s,%19s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,",substr($key,0,5),$date,$tp{$key},$rh{$key},$spd{$key},$dir{$key},$gust{$key},$mslp{$key},$pcp{$key};
    if ($pcp1m{$key} > $msg) {
      printf OUT "%.3f,",$pcp1m{$key}
    } else {
      printf OUT "%.2f,",$pcp1m{$key}
    }
    if ($pcp5m{$key} > $msg) {
      printf OUT "%.3f,",$pcp5m{$key}
    } else {
      printf OUT "%.2f,",$pcp5m{$key}
    }
    printf OUT "%.2f,%.2f\n",$snto{$key},$sn24{$key};
  }
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
