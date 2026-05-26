#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;

# Setup command line options:
#    -n number of hours (default = 85)
#    -t initial time (yymmddhh, default = current)
#    -m model id (default wrf)
#    -d domain (default = caic)
#    -r grid spacing (default = 4km)
#    -u units (e - english or m - metric, default = e)

use vars qw($opt_n $opt_t $opt_m $opt_d $opt_r $opt_u);
getopt('ntmdru');

my $domain = "caic";
$domain = $opt_d if defined($opt_d);
my $res = "4km";
$res = $opt_r if defined($opt_r);

my $modelid = "wrf";
$modelid = $opt_m if defined ($opt_m);
my $webdir = "/web/$domain/$res/$modelid/points";
my $cmodelid = uc($modelid);

my $root   = "/home/caic/caic/rtsys/post/ptfcst/bin";
my $mdldir = "/model/$domain/$res/$modelid";

my $unit = "e";
$unit = $opt_u if ($opt_u);

# Determine default times based on current time.

my $time = time;
my ($yyyy, $yy, $mm, $dd, $hh);
if (defined ($opt_t)) {
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
$webdir = "$webdir/$yyyy-$mm-$dd-$hh"."00";

# Define radians to degrees.

my $pi  = atan2(1,1) * 4;
my $r2d = 180 / $pi;

# Specify length of point forecast (default = 85 hours).

my $nfcst = 85;
$nfcst = $opt_n if defined ($opt_n);

my $starttime = &time_to_unix($mm, $dd, $yyyy, $hh);

my $dst = (localtime($starttime))[8];

# Read station table.

my ($jday,$cycl,@vars,$key,$n,%grid,%lat,%lon,%i,%j,%sht);

$jday = &julian($yyyy, $mm, $dd);
$jday = "0".$jday while(length($jday)<3);
$cycl = substr($yyyy,2,2)."$jday$hh"."00";

my $ngrid = 0;
open(IN,"$webdir/ptfcst.txt");
while(<IN>) {
   (@vars) = split;
   $key = $vars[1];
   $grid{$key} = $vars[0] * 1;
   $lat{$key} = $vars[2];
   $lon{$key} = $vars[3];
   $ngrid = $grid{$key} if ($grid{$key} > $ngrid);
}
close(IN);

for ($n=1; $n<=$ngrid; $n++) {
   open(IN,"$mdldir/$cycl/ptfcst/ptfcst.txt.g$n");
   while(<IN>) {
      (@vars) = split;
      $key = $vars[0];
      $sht{$key} = $vars[4];
      $sht{$key} *= 3.2808 if ($unit eq "e");
      $i{$key} = $vars[5];
      $j{$key} = $vars[6];
   }
   close(IN);
}

# Connect to the ptfcst database.

my $host = "127.0.0.1";
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
my $query;
if ($res eq "4km" || $res eq "12km") {
  $query = "select staname,validtime,res,temp,ltemp,gtemp,dewp,uwnd,vwnd,gust,luwnd,lvwnd,rnto,rntc,snto,visib,clg,pcptyp,cldpct,wetbulb from $table where inittime=\"$inittime\" and modelid=\"$modelid\" and domain=\"$domain\" and (res=\"4km\" or res=\"12km\")\n";
} else {
  $query = "select staname,validtime,res,temp,ltemp,gtemp,dewp,uwnd,vwnd,gust,luwnd,lvwnd,rnto,rntc,snto,visib,clg,pcptyp,cldpct,wetbulb from $table where inittime=\"$inittime\" and modelid=\"$modelid\" and domain=\"$domain\" and (res=\"2km\" or res=\"6km\")\n";
}
#print "$query\n";

my $table_output = $db->prepare($query);
$table_output->execute;

my $nrows = $table_output->rows;
$nrows = 0 if ($nrows > 999999);
print "There are $nrows entries in $table.\n";

my $maxfcst = -1;
my ($n,$staname,$vtime,$sres,$tpf,$tp,$gtp,$td,$rh,$uw,$vw,$luw,$lvw,$sp,$di,$gust,$cei,$wx,$rain,$crain,$snow
   ,$ham,$hah,$ven,$pbl,$puw,$pvw,$psp,$pdi,$vis,$fwi,$pty,$cld,$wtb
   ,$ry,$rm,$rd,$rh,$limit
   ,$valtime,$fcst,$fcstm1,$keym1,%staname,%sres,%tpf,%tdf,%spf,%dif,%gust,%raf,%rcf,%snf,%ham,%hah
   ,%ven,%pbl,%psp,%pdi,%vis,%cei,%fwi,%wx,%wtb);
for ($n=0; $n<$nrows; $n++) {
   ($staname,$vtime,$sres,$tpf,$tp,$gtp,$td,$uw,$vw,$gust,$luw,$lvw,$rain,$crain,$snow,$vis,$cei,$pty,$cld,$wtb) = $table_output->fetchrow;
   $ry = substr($vtime, 0,4);
   $rm = substr($vtime, 5,2);
   $rd = substr($vtime, 8,2);
   $rh = substr($vtime,11,2);
   $valtime = &time_to_unix($rm, $rd, $ry, $rh);
   $fcst = ($valtime - $starttime) / 3600;
   if ($fcst >= 0 && $fcst <= $nfcst) {
      $maxfcst = $fcst if ($fcst > $maxfcst);
      $staname{$staname} = $staname;
      $sres{$staname} = $sres;
      $fcst = "0".$fcst while(length($fcst)<4);
      $key = "$fcst$staname";
      $tpf *= 0.1;
      $tpf = $tpf * 1.8 + 32 if ($unit eq "e");
      $tpf{$key} = $tpf;
      $td *= 0.1;
      $td = $td * 1.8 + 32 if ($unit eq "e");
      $tdf{$key} = $td;
      $tdf{$key} = $tpf{$key} if ($tdf{$key} > $tpf{$key});
      $uw *= 0.1;
      $vw *= 0.1;
      $gust{$key} = $gust * 0.1;
      $spf{$key} = sqrt($uw**2 + $vw**2);
      if ($unit eq 'm') {
        $spf{$key} *= 3.6;    # m/s -> km/h
        $gust{$key} *= 3.6;
      } else {
        $spf{$key} *= 2.237;  # m/s -> mph
        $gust{$key} *= 2.237;
      }
      $gust{$key} = $spf{$key} if ($gust{$key} < $spf{$key});
      $dif{$key} = atan2(-$uw,-$vw) * $r2d;
      $dif{$key} += 360 if ($dif{$key} < 0);
      $wtb *= 0.1;
      $wtb = $wtb * 1.8 + 32 if ($unit eq "e");
      $wtb{$key} = $wtb;
      $raf{$key} = $rain * 0.001;
      $rcf{$key} = $crain * 0.001;
      $snf{$key} = $snow * 0.001;
      if ($unit eq "m") {
         $raf{$key} *= 25.4;
         $rcf{$key} *= 25.4;
         $snf{$key} *= 2.54;
      }
      $vis = 9900 if (! defined $vis);
      $vis{$key} = $vis * 0.01;
      $cei = 999 if (! defined $cei);
      $cei{$key} = $cei;
      if ($cei{$key} > 600) {
         $cei{$key} = 999;
      } elsif ($unit eq "m") {
         $cei{$key} /= 3.2808;
      }
      $tp = $tpf{$key};
      $tp = $tp * 1.8 + 32 if ($unit eq 'm');
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
         if ($raf{$key} < 0.005 && $rcf{$key} > 0) {
            if ($tp > 32.) {
               $wx{$key} = "RAINSHWR";
            } else {
               $wx{$key} = "SNOWSHWR";
            }
         }
      } elsif ($pty == 1 || $pty == 6) {
         $wx{$key} = "RAIN";
      } elsif ($pty == 2 || $pty == 8 || $pty == 12) {
         $wx{$key} = "SNOW";
      } elsif ($pty == 3 || $pty == 7 || $pty == 9 || $pty == 14) {
         $wx{$key} = "ICE";
      } elsif ($pty == 4 || $pty == 5) {
         if ($tp < 40) {
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
   }
}
$table_output->finish;

# Disconect from the db.

$db->disconnect;

exit if ($maxfcst < 0);

# Print point forecasts.

my $tdiff = 25200 - 3600*$dst;
my ($hitp,$lotp,$avtp,$avtd,$mxgust,$hitime,$lotime,$gtime,$lat,$lon,$i,$j,$sht,$lstaname,$dom,$pres);

foreach $staname (keys (%staname)) {

$hitp = -999;
$lotp =  999;
$avtp = 0;
$avtd = 0;
$mxgust = 0;
$lstaname = $staname;
$lstaname = $lstaname." " while(length($lstaname)<11);
$lat = $lat{$staname};
$lon = $lon{$staname};
$dom = $grid{$staname};
$pres = $sres{$staname};
$i = $i{$staname};
$j = $j{$staname};
$sht = $sht{$staname};
my $train = 0;
my $tcrain = 0;

if ($dom > 0) {
open(OUT,">$webdir/$staname.txt");

print OUT "*******************************************************************************\n";
printf OUT "LOCATION: %s     LAT: %7.4f LON: %9.4f       I: %6.2f J: %6.2f\n",$lstaname,$lat,$lon,$i,$j;
if ($unit eq "e") {
  if ($modelid eq "nam") {
    printf OUT "%s       FCST CYCLE: %s                       MODEL ELEVATION: %5i ft\n",$cmodelid,$cycl,$sht;
  } else {
    printf OUT "%s %4.1f km   FCST CYCLE: %s    DOM:  %1i        MODEL ELEVATION: %5i ft\n",$cmodelid,$pres,$cycl,$dom,$sht;
  }
} else {
  if ($modelid eq "nam") {
    printf OUT "%s       FCST CYCLE: %s                        MODEL ELEVATION: %5i m\n",$cmodelid,$cycl,$sht;
  } else {
    printf OUT "%s %4.1f km   FCST CYCLE: %s    DOM:  %1i        MODEL ELEVATION: %5i m\n",$cmodelid,$pres,$cycl,$dom,$sht;
  }
}
print OUT "*******************************************************************************\n";
print OUT "DATE       TIME  TMP DPT RH  WIND   GST CEI VIS  WEATHER  NCPCP CNPCP SNOW WETB\n";
if ($dst) {
  if ($unit eq "e") {
    print OUT "MDT        MDT     F   F  %  Dg\@MPH MPH hft mile             in    in   in    F\n";
  } else {
    print OUT "MDT        MDT     C   C  %  Dg\@KPH KPH h-m  km              mm    mm   cm    C\n";
  }
} else {
  if ($unit eq "e") {
    print OUT "MST        MST     F   F  %  Dg\@MPH MPH hft mile             in    in   in    F\n";
  } else {
    print OUT "MST        MST     C   C  %  Dg\@KPH KPH h-m  km              mm    mm   cm    C\n";
  }
}
print OUT "---------- ----- --- --- --- ------ --- --- ---- -------- ----- ----- ---- ----\n";
my $ct = 0;
for ($fcst=0; $fcst<=$maxfcst; $fcst++) {
   $valtime = $starttime + $fcst*3600 - $tdiff;
   ($yyyy, $mm, $dd, $hh) = &unix_to_time($valtime);
   $mm = "0".$mm while(length($mm)<2);
   $dd = "0".$dd while(length($dd)<2);
   $hh = "0".$hh while(length($hh)<2);
   $fcst = "0".$fcst while(length($fcst)<4);
   $key = "$fcst"."$staname";
   next if (! defined($tpf{$key}));
   ++$ct;
   $tp = nint($tpf{$key});
   $td = nint($tdf{$key});
   $wtb = nint($wtb{$key});
   $wtb = ($tp+$td)/2 if ($wtb > $tp || $wtb < $td);
   $td = $tp if ($td > $tp);
   $rh = &td2rh($tpf{$key},$tdf{$key});
   $sp = nint($spf{$key});
   $di = nint($dif{$key}/10)*10;
   $gust = nint($gust{$key});
   $sp = "0".$sp while(length($sp)<2);
   $di = "0".$di while(length($di)<3);
   $cei = $cei{$key};
   $vis = nint($vis{$key}*10)/10;
   $wx = $wx{$key};
   $wx = $wx." " while(length($wx)<8);
   if ($fcst == 0) {
      $rain = 0;
      $crain = 0;
      $snow = 0;
   } else {
      $rain = nint($raf{$key}*100)/100;
      $crain = nint($rcf{$key}*100)/100;
      $fcstm1 = $fcst - 1;
      $fcstm1 = "0".$fcstm1 while(length($fcstm1)<4);
      $keym1 = "$fcstm1"."$staname";
      $snow = nint(($snf{$key}-$snf{$keym1})*10)/10;
   }
   $train += $rain;
   $tcrain += $crain;
   printf OUT "%s/%s/%s %s:00 %3i %3i %3i %s/%s %3i %3i %4.1f %s %5.2f %5.2f %4.1f %4i\n",$mm,$dd,$yyyy,$hh,$tp,$td,$rh,$di,$sp,$gust,$cei,$vis,$wx,$rain,$crain,$snow,$wtb;
   if ($tpf{$key} > $hitp) {
      $hitp = $tpf{$key};
      $hitime = $valtime;
   }
   if ($tpf{$key} < $lotp) {
      $lotp = $tpf{$key};
      $lotime = $valtime;
   }
   $avtp += $tpf{$key};
   $avtd += $tdf{$key};
   if ($gust{$key} > $mxgust) {
      $mxgust = $gust{$key};
      $gtime = $valtime;
   }
}

$hitp = nint($hitp*10)/10;
$lotp = nint($lotp*10)/10;
$avtp /= $ct;
$avtd /= $ct;
$avtp = nint($avtp*10)/10;
$avtd = nint($avtd*10)/10;
$mxgust = nint($mxgust*10)/10;

print OUT "\nSUMMARY INFORMATION FOR PERIOD\n";
print OUT "--------------------------------------------------\n";
($yyyy, $mm, $dd, $hh) = &unix_to_time($hitime);
$mm = "0".$mm while(length($mm)<2);
$dd = "0".$dd while(length($dd)<2);
$hh = "0".$hh while(length($hh)<2);
printf OUT "HIGH TEMPERATURE:   %5.1f  AT %s/%s/%s $hh:00\n",$hitp,$mm,$dd,$yyyy,$hh;
($yyyy, $mm, $dd, $hh) = &unix_to_time($lotime);
$mm = "0".$mm while(length($mm)<2);
$dd = "0".$dd while(length($dd)<2);
$hh = "0".$hh while(length($hh)<2);
printf OUT "LOW TEMPERATURE:    %5.1f  AT %s/%s/%s $hh:00\n",$lotp,$mm,$dd,$yyyy,$hh;
printf OUT "AVG TEMPERATURE:    %5.1f\n",$avtp;
printf OUT "AVG DEWPOINT:       %5.1f\n",$avtd;
($yyyy, $mm, $dd, $hh) = &unix_to_time($gtime);
$mm = "0".$mm while(length($mm)<2);
$dd = "0".$dd while(length($dd)<2);
$hh = "0".$hh while(length($hh)<2);
printf OUT "MAX WIND GUST:      %5.1f  AT %s/%s/%s $hh:00\n",$mxgust,$mm,$dd,$yyyy,$hh;
printf OUT "TOTAL NC PRECIP:    %5.2f\n",$train;
printf OUT "TOTAL CONV PREC:    %5.2f\n",$tcrain;
$snow = nint($snf{$key}*10)/10;
printf OUT "TOTAL SNOW:         %5.2f\n",$snow;

#print OUT $disc;

close(OUT);
}

}

exit;

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
}1;

################################################################################

sub nint { my ($z) = @_; return ($z>0)? int($z+0.5) : int($z-0.5); }

################################################################################

sub td2rh {

# Compute RH (%) from temp (F) and dew point (F).

   my ($t, $td) = @_;
   my $tc = ($t - 32) / 1.8;
   my $tdc = ($td - 32) / 1.8;
   esat($tdc) / esat($tc) * 100;
}
1;

################################################################################
   
sub esat {
   
# Compute saturation vapor pressure (mb) from temperature (C).
      
   my ($t) = @_;

   $t += 273.15;
   my $p1 = 11.344  - (0.0303998 * $t);
   my $p2 = 3.49149 - (1302.8844 / $t);
   my $c1 = 23.832241 - 5.02808 * log10($t);
   10**($c1 - 1.3816e-7 * 10**$p1 + 8.1328e-3 * 10**$p2 - 2949.076 / $t);
}
1; 

################################################################################

sub log10 {

# Compute log base 10.

   my ($z) = @_;

   0.4342944819 * log($z);
}
1;
