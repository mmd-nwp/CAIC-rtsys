#!/usr/bin/perl
use strict;

use DBI;
use Getopt::Std;

# Generate WRF point forecast table.
# This table is used by bc-fcst.pl to generate xml file 
#   for point forecast summary website.
           
# Command line options:
#  -n number of hours (default = 84)
#  -t initial time (yymmddhh, default = current)
#  -m model id (default wrf)
#  -d domain (default = caic)
#  -r grid spacing (default = 4km)
#  -u units (e - english or m - metric, default = e)

use vars qw($opt_n $opt_t $opt_m $opt_d $opt_r $opt_u);
getopt('ntmdru');

my $root = "/home/caic/caic/rtsys/post/ptfcst";

my @headers = ("   Today   "
              ,"  Tonight  "
              ," Tomorrow  "
              ," Tom Night "
              ,"   Day 2   "
              ,"Day2 Night "
              ,"   Day 3   "
              ,"Day3 Night "
              );

my @months = qw(dum Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

# Specify the length of point forecast (default = 84 hours)

my $nfcst = 84;
$nfcst = $opt_n if defined($opt_n);

# Setup the model domain 

my $domain = "caic";
$domain = $opt_d if defined($opt_d);
my $res = "4km";
$res = $opt_r if defined($opt_r);

# Setup the model (default wrf)

my $modelid = "wrf";
$modelid = $opt_m if defined($opt_m);
my $cmodelid = uc($modelid);

# Setup the unit flag

my $unit = "e";
$unit = $opt_u if defined($opt_u);

# Determine the time from argument or current time (default).

my $time = time;
my ($yyyy, $yy, $mm, $dd, $hh);
if ($opt_t) {
   $yy = substr($opt_t,0,2);
   $mm = substr($opt_t,2,2);
   $dd = substr($opt_t,4,2);
   $hh = substr($opt_t,6,2);
   $yyyy = 2000 + $yy;
} else {
   ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
   $mm = "0".$mm while(length($mm)<2);
   $dd = "0".$dd while(length($dd)<2);
   $hh = "0".$hh while(length($hh)<2);
}
my $stamp = "$months[$mm] $dd, $yyyy $hh:00 GMT";
my $starttime = &time_to_unix($mm, $dd, $yyyy, $hh);

# Root and model directories.

my $tbldir = "$root/namelist";

# PI and radians to degrees.

my $pi  = atan2(1,1) * 4;
my $r2d = 180 / $pi;

# Read station table.

my (@vars,$key,$n,@stn,%grid,%lat,%lon,%i,%j);
my $cmmnd;

# Read the station table.

open(IN,"$tbldir/ptfcst.txt");
while(<IN>) {
   (@vars) = split;
   $key = $vars[0];
   push(@stn,$key);
   $lat{$key} = $vars[1];
   $lon{$key} = $vars[2];
}
close(IN);
my $nsta = @stn;

$tbldir = "$root/table/$yyyy-$mm-$dd-$hh";
print "tbldir = $tbldir\n";
mkdir("$tbldir",0755) if (! -e "$tbldir");
$tbldir = "$tbldir/wrf$res.txt";

# Connect to the ptfcst database.

#my $host = "10.0.0.100";
#my $dbName = "weather";
my $host = "localhost";
my $dbName = "ptfcst";
my $userName = "caic";
my $password = "steepndeep";

print "Connecting to database: $dbName as user: $userName\n";
my $db = DBI->connect("DBI:mysql:$dbName:$host", $userName, $password);

# Read fcst table.

my ($inittime,$valtime,$title,$time1,$time2);

$mm = "0".$mm while(length($mm)<2);
$dd = "0".$dd while(length($dd)<2);
my $table = "NwpOutput$yyyy$mm$dd";
my $inittime = "$yyyy-$mm-$dd $hh:00:00";
my $starthh = $hh;
my $query;
$query = "select staname,validtime,ltemp," .
         "uwnd,vwnd,gust,rnto,snto," .
         "visib,clg,pcptyp,cldpct from $table " .
         "where inittime=\"$inittime\" " .
         "and modelid=\"$modelid\" " .
         "and domain=\"$domain\" " .
         "and res=\"$res\"\n";

my $table_output = $db->prepare($query);
$table_output->execute;

my $nrows = $table_output->rows;
$nrows = 0 if ($nrows > 999999);
print "There are $nrows entries in $table.\n";

my $maxfcst = -1;
my ($n,$p,$staname,$vtime,$tp,$tpm,$rh,$rhm,$uw,$vw
   ,$sp,$di,$gst,$cei,$vis,$wx,$rain,$snow,$accum
   ,$vis,$pty,$cld,$wsp
   ,$ry,$rm,$rd,$rh,$limit
   ,$valtime,$fcst,$sfcst,$keym1,%staname,%tpf,%tpm
   ,%uw,%vw,%spf,%dif,%gst,%raf,%snf
   ,%vis,%cei,%wx,%cld
   ,$header,$sep);
for ($n=0; $n<$nrows; $n++) {
   ($staname,$vtime,$tp,$uw,$vw,$gst,$rain,$snow,
       $vis,$cei,$pty,$cld) = $table_output->fetchrow;
   $ry = substr($vtime, 0,4);
   $rm = substr($vtime, 5,2);
   $rd = substr($vtime, 8,2);
   $rh = substr($vtime,11,2);
   $valtime = &time_to_unix($rm, $rd, $ry, $rh);
   $fcst = ($valtime - $starttime) / 3600;
print "$fcst $rain $snow\n" if ($staname eq "SISTERS");
   if ($fcst >= 0 && $fcst <= $nfcst) {
      $maxfcst = $fcst if ($fcst > $maxfcst);
      $staname{$staname} = $staname;
      $fcst = "0".$fcst while(length($fcst)<4);
      $key = "$fcst$staname";
      $tp *= 0.1;
      $tp = $tp * 1.8 + 32 if ($unit eq "e");
      $tpf{$key} = $tp;
      $uw *= 0.1;
      $vw *= 0.1;
      $uw *= 2.237 if ($unit eq 'e');
      $uw *= 3.6   if ($unit eq 'm');  #km/hr
      $vw *= 2.237 if ($unit eq 'e');
      $vw *= 3.6   if ($unit eq 'm');  #km/hr
      $uw{$key} = $uw;
      $vw{$key} = $vw;
      $spf{$key} = sqrt($uw**2 + $vw**2);
      $dif{$key} = atan2(-$uw,-$vw) * $r2d;
      $dif{$key} += 360 if ($dif{$key} < 0);
      $gst{$key} = $gst * 0.2237;
      $raf{$key} = $rain * 0.001;
      $snf{$key} = $snow * 0.001;
      if ($unit eq "m") {
         $gst{$key} *= 3.6;
         $raf{$key} *= 2.54;
         $snf{$key} *= 2.54;
      } else {
         $gst{$key} *= 2.237;
      }
      $vis{$key} = $vis * 0.01;
      $cei{$key} = $cei;
      if ($cei{$key} > 600) {
         $cei{$key} = 999;
      } elsif ($unit eq "m") {
         $cei{$key} /= 3.2808;
      }
      if ($pty == 0) {
         if ($vis{$key} < 3) {
            $wx{$key} = "FOG";
         } elsif ($vis{$key} < 7) {
            $wx{$key} = "HAZE";
         } elsif ($cld < 10 && $cei == 999) {
            $wx{$key} = "CLEAR";
         } elsif ($cld < 30) {
            $wx{$key} = "ISOCLOUD";
         } elsif ($cld < 70) {
            $wx{$key} = "PTLYCLDY";
         } elsif ($cld < 90) {
            $wx{$key} = "MSLYCLDY";
         } else {
            $wx{$key} = "CLOUDY";
         }
      } elsif ($pty == 1 || $pty == 6) {
         $wx{$key} = "RAIN";
      } elsif ($pty == 2 || $pty == 8 || $pty == 12) {
         $wx{$key} = "SNOW";
      } elsif ($pty == 3 || $pty == 7 || $pty == 9 || $pty == 14) {
         $wx{$key} = "ICE";
      } elsif ($pty == 4 || $pty == 5) {
         if ($tp < 40.) {
            $wx{$key} = "RAINSNOW";
         } else {
            $wx{$key} = "RAIN";
         }
      } elsif ($pty == 10 || $pty == 11 || $pty == 13) {
         $wx{$key} = "FRZRAIN";
      } else {
         $wx{$key} = "        ";
      }
      $vis{$key} *= 1.609 if ($unit eq "m");
      $vis{$key} = 99.9 if ($vis{$key} > 99.9);
      $cld{$key} = $cld;
   }
}
$table_output->finish;

# Disconect from the db.

$db->disconnect;

exit if ($maxfcst < 0);

# Print point-moca.

my $tdiff = 25200;
my ($period,$hitp,$lotp,$avtp,$avtd
   ,$train,$tsnow
   ,$hisp,$losp,$avsp,$avuw,$avvw,$hidir,$lodir,@avdir,$avcld,$higs,$logs,$avgs
   ,@avtp,@hitp,@lotp,@avsp,@hisp,@losp,@lodir,@hidir,@higs,@logs,@avgs,@cld,@rain,@snow
   ,$lat,$lon,$lstaname,$res);

open(OUT,">$tbldir");
print OUT "   $stamp\n";
for ($n=0; $n<=$nsta; $n++) {
   $staname = $stn[$n];

   $lstaname = $staname;
   $lstaname = $lstaname." " while(length($lstaname)<11);
   $lat = $lat{$staname};
   $lon = $lon{$staname};

   $avtp = 0;
   $hitp = -999;
   $lotp =  999;
   $avsp = 0;
   $hisp = -999;
   $losp =  999;
   $avgs = 0;
   $higs = -999;
   $logs =  999;
   $avuw = 0;
   $avvw = 0;
   $avcld = 0;
   $train = 0;
   $tsnow = 0;
   $period = 0;

   if ($starthh eq "00" || $starthh eq "12") {
      $sfcst = 0;
   } else {
      $sfcst = 6;
   }

   for ($fcst=$sfcst; $fcst<=$maxfcst; $fcst++) {
#     $valtime = $starttime + $fcst*3600 - $tdiff;
#     ($yyyy, $mm, $dd, $hh) = &unix_to_time($valtime);
#     $mm   = "0".$mm while(length($mm)<2);
#     $dd   = "0".$dd while(length($dd)<2);
#     $hh   = "0".$hh while(length($hh)<2);
      $fcst = "0".$fcst while(length($fcst)<4);
      $key  = "$fcst"."$staname";
      $cei  = $cei{$key};
      $vis  = &nint($vis{$key}*10)/10;
      $wx   = $wx{$key};
      $wx   = $wx." " while(length($wx)<8);
      $cld{$key} = 0 if ($cld{$key} < 0);
      $cld{$key} = 100 if ($cld{$key} > 100);
      $train += $raf{$key};

      if (($fcst-$sfcst)%12 == 0 && $sfcst != $fcst) {
print "period: $period $fcst\n" if ($n == 0);
         $hitp  = $tpf{$key} if ($tpf{$key} > $hitp);
         $hisp  = $spf{$key} if ($spf{$key} > $hisp);
         $hidir = $dif{$key} if ($dif{$key} > $hidir);
         $higs  = $gst{$key} if ($gst{$key} > $higs);
         $lotp  = $tpf{$key} if ($tpf{$key} < $lotp);
         $losp  = $spf{$key} if ($spf{$key} < $losp);
         $lodir = $dif{$key} if ($dif{$key} < $lodir);
         $logs  = $gst{$key} if ($gst{$key} < $logs);
         $avtp  += $tpf{$key};
         $avtp  /= 13;
         $avsp  += $spf{$key};
         $avsp  /= 13;
         $avuw  += $uw{$key};
         $avuw  /= 13;
         $avvw  += $vw{$key};
         $avvw  /= 13;
         $avcld += $cld{$key};
         $avcld /= 13;
         $avgs  += $gst{$key};
         $avgs  /= 13;
         $avtp [$period] = $avtp;
         $hitp [$period] = $hitp;
         $lotp [$period] = $lotp;
         $avsp [$period] = $avsp;
         $hisp [$period] = $hisp;
         $losp [$period] = $losp;
         if ($avuw == 0 && $avvw == 0) {
            $avdir[$period] = 0;
         } else {
            $avdir[$period] = atan2(-$avuw,-$avvw) * $r2d;
            $avdir[$period] += 360 if ($avdir[$period] < 0);
         }
         if ($hidir-$lodir > 180) {
            $lodir[$period] = $hidir;
            $hidir[$period] = $lodir;
         } else {
            $hidir[$period] = $hidir;
            $lodir[$period] = $lodir;
         }
         $avgs [$period] = $avgs;
         $higs [$period] = $higs;
         $logs [$period] = $logs;
         if ($avcld < 10) {
            $cld[$period] = "CLEAR";
         } elsif ($avcld < 25) {
            $cld[$period] = "FEW";
         } elsif ($avcld < 50) {
            $cld[$period] = "SCATTERED";
         } elsif ($avcld < 90) {
            $cld[$period] = "BROKEN";
         } else {
            $cld[$period] = "OVERCAST";
         }
         $rain [$period] = $train;
         $snow [$period] = $snf{$key} - $tsnow;
         $train = 0;
         $tsnow = $snf{$key};
         $avtp  = $tpf{$key};
         $avsp  = $spf{$key};
         $avuw  = $uw{$key};
         $avvw  = $vw{$key};
         $avgs  = $gst{$key};
         $hitp  = $tpf{$key};
         $hisp  = $spf{$key};
         $hidir = $dif{$key};
         $higs  = $gst{$key};
         $lotp  = $tpf{$key};
         $losp  = $spf{$key};
         $lodir = $dif{$key};
         $avcld = $cld{$key};
         ++$period;
      } else {
         $avtp  += $tpf{$key};
         $avsp  += $spf{$key};
         $avuw  += $uw{$key};
         $avvw  += $vw{$key};
         $avgs  += $gst{$key};
         $avcld += $cld{$key};
         $hitp  = $tpf{$key} if ($tpf{$key} > $hitp);
         $hisp  = $spf{$key} if ($spf{$key} > $hisp);
         $hidir = $dif{$key} if ($dif{$key} > $hidir);
         $higs  = $gst{$key} if ($gst{$key} > $higs);
         $lotp  = $tpf{$key} if ($tpf{$key} < $lotp);
         $losp  = $spf{$key} if ($spf{$key} < $losp);
         $lodir = $dif{$key} if ($dif{$key} < $lodir);
         $logs  = $gst{$key} if ($gst{$key} < $logs);
      }
   }

# Print to table.

   $header = "----------------";
   for ($p=0; $p<$period; $p++) {
      $header .= "------------";
   }
   $sep = "---------------";
   for ($p=0; $p<$period; $p++) {
      $sep .= "+-----------";
   }
   $sep .="|";

   print OUT "$header\n";
   push(@headers) if ($starthh eq "12" || $starthh eq "18");
   printf OUT "%14s |",$lstaname;
   for ($p=0; $p<$period; $p++) {
      printf OUT "%11s|",$headers[$p];
   }
   printf OUT "\n";

   print OUT "$sep\n";
   printf OUT "Temperature WRF|";
   for ($p=0; $p<$period; $p++) {
      printf OUT "%3.0f %3.0f %3.0f|",$avtp[$p] ,$lotp[$p] ,$hitp[$p];
   }
   printf OUT "\n";

   print OUT "$sep\n";
   printf OUT "Wind Speed  WRF|";
   for ($p=0; $p<$period; $p++) {
      printf OUT "%3.0f %3.0f %3.0f|",$avsp[$p] ,$losp[$p] ,$hisp[$p];
   }
   printf OUT "\n";

   print OUT "$sep\n";
   printf OUT "Wind Gust   WRF|";
   for ($p=0; $p<$period; $p++) {
      printf OUT "%3.0f %3.0f %3.0f|",$avgs[$p] ,$logs[$p] ,$higs[$p];
   }
   printf OUT "\n";

   print OUT "$sep\n";
   printf OUT "Wind Dir    WRF|";
   for ($p=0; $p<$period; $p++) {
      printf OUT "%3.0f %3.0f %3.0f|",$avdir[$p],$lodir[$p],$hidir[$p];
   }
   printf OUT "\n";

   print OUT "$sep\n";
   printf OUT "Sky Cover   WRF|";
   for ($p=0; $p<$period; $p++) {
      printf OUT "%10s |",$cld[$p];
   }
   printf OUT "\n";

   print OUT "$sep\n";
   printf OUT "Precip/Snow WRF|";
   for ($p=0; $p<$period; $p++) {
      printf OUT "%5.2f%5.1f |",$rain[$p],$snow[$p];
print "$p $rain[$p] $snow[$p]\n" if ($staname eq "SISTERS");
   }
   printf OUT "\n";
   print OUT "$header\n";
}
close(OUT);

exit;

#===============================================================================
# &time_to_unix: Calculate unix time from month, day, year, hour, min, sec
# Arguments: month, day, year (4 digit), hour, min, sec
# Returns: unix time
#===============================================================================
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
# &unix_to_time: Calculate month, day, year, hour, min, sec from unix time
# Arguments: unix time
# Returns: month, day, year, hour, min, sec
#===============================================================================
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
sub nint {
	my ($z) = @_;
	return ($z>0)? int($z+0.5) : int($z-0.5);
}
1;
