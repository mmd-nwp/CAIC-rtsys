#!/usr/bin/perl
use strict;
use Getopt::Std;

# Command line options:
#   -d model date (yyyy-mm-dd-hh)
#   -m model (default=ndfd)

use vars qw($opt_d $opt_m);
getopt('dm');

my $model = "ndfd";
$model = $opt_m if defined($opt_m);
if ($model ne "ndfd" && $model ne "nbm" && $model ne "wrf4km" && $model ne "wrf2km") {
  print "$model model is not allowed.\n";
  exit;
}

my $date;
if (defined $opt_d) {
  $date = $opt_d;
} else {
  print "Date must be defined\n";
  exit;
}

my $fcstdir = "/home/caic/caic/rtsys/post/ptfcst";

my %bc_zone = qw(
                 LVLNDPASS  0
                 BERTHPASS  0
                 TUNNELS    0
                 VAIL_PASS  0
                 CAMERONPCO 0
                 LONETREEBL 0
                 CLIFFS     0
                 DOUGLASPAS 0
                 GWCSOUTH   0
                 GWCNORTH   0
                 BLUECANYON 0
                 INDYPASSW  0
                 CRESTBOWL  0
                 BIGSLIDE   0
                 SWITCHBACK 0
                 BUCKEYE    0
                 MTZION     0
                 YCHUTES    0
                 INDEPPASS  0
                 STARMTN    0
                 ENGINEERS  0
                 LIMECREEK  0
                 CHAMPIONPT 0
                 MILLCREEK  0
                 BLUEPOINT  0
                 TRICOPEAK  0
                 MTABRAMS   0
                 MOTHERCLIN 0
                 PETERSON   0
                 SNOWSPUR   0
                 WHITELIZ   0
                 OPHIRROAD  0
                 WOLFCKPASS 0
                 SLUMGULPAS 0
                 CUMBRESPAS 0
                 BCDOUGLASP 0
                 BCBISONLAK 0
                 BCRIPPLECR 0
                 BCBUFFPASS 0
                 BCSTEAMBOA 0
                 BCMOUNTZIR 0
                 BCSANDMOUN 0
                 BCMTWERNER 0
                 BCRABBITEA 0
                 BCMEDICINE 0
                 BCSOUTHDIA 0
                 BCPARKVIEW 0
                 BCFLATTOP  0
                 BCARAPAHOL 0
                 BCBERTHOUD 0
                 BCLOVELAND 0
                 BCELLIOTRI 0
                 BCSHRINEMO 0
                 BCPITKINLA 0
                 BCVAIL8K   0
                 BCGROUSEMO 0
                 BCBRECKENR 0
                 BCMOUNTTHO 0
                 BCMOUNTNAS 0
                 BCFREMONTP 0
                 BCUNCLEBUD 0
                 BCGORDONGU 0
                 BCHOOSIERP 0
                 BCWESTONPA 0
                 BCPIKESPEA 0
                 BCINDEPEND 0
                 BCCOTTONWO 0
                 BCTINCUPPA 0
                 BCMONARCHP 0
                 BCASPEN8K  0
                 BCCATHEDRA 0
                 BCHIGHLAND 0
                 BCHUNTSMAN 0
                 BCCRESTEDB 0
                 BCCINNAMON 0
                 BCRASPBERR 0
                 BCWESTELK  0
                 BCMATCHLES 0
                 BCFRIENDSH 0
                 BCANTHRACI 0
                 BCISLANDLA 0
                 BCWINDYPOI 0
                 BCTELLURID 0
                 BCWILSONPE 0
                 BCPALMYRAP 0
                 BCOURAY8K  0
                 BCYANKEEBO 0
                 BCUNCOMPAH 0
                 BCSLUMGULL 0
                 BCSUNSHINE 0
                 BCLAGARITA 0
                 BCRICO9K   0
                 BCEXPECTAT 0
                 BCOPHIRPAS 0
                 BCWESTRIVE 0
                 BCTRICOPEA 0
                 BCSILVERTO 0
                 BCEUREKAMO 0
                 BCSULTANCR 0
                 BCENGINEER 0
                 BCCHICAGOB 0
                 BCRIOGRAND 0
                 BCPURGATOR 0
                 BCCOLUMBUS 0
                 BCENDLICHM 0
                 BCWOLFCREE 0
                 BCCUMBRES  0
                 BCSOUTHCOL 0
                 BCBLANCAPE 0
                );

my %sky = (
            "CLEAR"    ,"CLR"
           ,"FEW"      ,"FEW"
           ,"SCATTERED","SCT"
           ,"BROKEN"   ,"BKN"
           ,"OVERCAST" ,"OVC"
          );

my @times = ("0","1","2","3","4","5","6");

# Set fcst file name dependent on model.

my $mdl = 0;
my $mos = 0;
my $offset = 0;
my $period = "am";
my ($fcstfile,$hh);
if ($model eq "wrf4km" || $model eq "wrf2km") {
  $fcstfile = "$fcstdir/table/$date/$model".".txt";
  if (-e $fcstfile) {
    if (! &checkwrf($fcstfile)) {
      print "$fcstfile is incomplete.\n";
      exit;
    }
  } else {
    print "$fcstfile not found.\n";
    exit;
  }
} else {
  $fcstfile = "$fcstdir/table/$date/$model".".txt";
  if (-e $fcstfile) {
    if (! &checknws($fcstfile)) {
      print "$fcstfile is incomplete.\n";
      exit;
    }
  } else {
    print "$fcstfile not found.\n";
    exit;
  }
}
my $perflag = "day";
$hh = substr($date,11,2);
if ($hh < 12 && ($model eq "ndfd" || $model eq "nbm")) {
  $perflag = "night";
}
if (($hh == 00 || $hh == 18) && substr($model,0,3) eq "wrf") {
  $period = "pm";
  $perflag = "night";
}
print "$fcstfile $mdl $mos $offset $period\n";

# Open output xml file and write header data.

my $xmlfile = "$fcstdir/xml/forecast-$model".".xml";
print "$xmlfile\n";

open(OUT,">$xmlfile");

print OUT "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
print OUT "<WeatherForecast product=\"Avalanche\" ForecastModel=\"$model\" ForecastDate=\"$date\" PeriodFlag=\"$perflag\" >\n";

# Parse out data and call xmlzone to write data to xml file.

my ($strlen,$np,$staname,@temp,@spd,@dir,@sky,@rain,@snow,@gst);
my $line = 0;

open(IN,$fcstfile);
if (substr($model,0,3) eq "wrf") {

  print "wrf\n";
  --$line;
  while(<IN>) {
    $strlen = length;
    if ($line%15 == 1) {
      $staname = substr($_,3,10);
      $staname =~ s/\s+$//;
    } elsif ($line%15 == 3) {
      if ($period eq "am") {
        $temp[0] = substr($_,24,3);
        $temp[1] = substr($_,32,3);
        $temp[2] = substr($_,48,3);
        $temp[3] = substr($_,56,3);
        $temp[4] = substr($_,72,3);
        $temp[5] = substr($_,80,3);
      } else {
        $temp[0] = substr($_,20,3);
        $temp[1] = substr($_,36,3);
        $temp[2] = substr($_,44,3);
        $temp[3] = substr($_,60,3);
        $temp[4] = substr($_,68,3);
        $temp[5] = substr($_,84,3);
      }
    } elsif ($line%15 == 5) {
      $spd[0] = substr($_,16,3);
      $spd[1] = substr($_,28,3);
      $spd[2] = substr($_,40,3);
      $spd[3] = substr($_,52,3);
      $spd[4] = substr($_,64,3);
      $spd[5] = substr($_,76,3);
      $gst[0] = substr($_,24,3);  # Use average gust, which is stored in max speed
      $gst[1] = substr($_,36,3);
      $gst[2] = substr($_,48,3);
      $gst[3] = substr($_,60,3);
      $gst[4] = substr($_,72,3);
      $gst[5] = substr($_,84,3);
#   } elsif ($line%15 == 7) {
#     $gst[0] = substr($_,24,3);
#     $gst[1] = substr($_,36,3);
#     $gst[2] = substr($_,48,3);
#     $gst[3] = substr($_,60,3);
#     $gst[4] = substr($_,72,3);
#     $gst[5] = substr($_,84,3);
#     $gst[0] = substr($_,16,3);  # Use average gust
#     $gst[1] = substr($_,28,3);
#     $gst[2] = substr($_,40,3);
#     $gst[3] = substr($_,52,3);
#     $gst[4] = substr($_,64,3);
#     $gst[5] = substr($_,76,3);
    } elsif ($line%15 == 9) {
      $dir[0] = substr($_,16,3);
      $dir[1] = substr($_,28,3);
      $dir[2] = substr($_,40,3);
      $dir[3] = substr($_,52,3);
      $dir[4] = substr($_,64,3);
      $dir[5] = substr($_,76,3);
    } elsif ($line%15 == 11) {
      $sky[0] = substr($_,17,9);
      $sky[1] = substr($_,29,9);
      $sky[2] = substr($_,41,9);
      $sky[3] = substr($_,53,9);
      $sky[4] = substr($_,65,9);
      $sky[5] = substr($_,77,9);
    } elsif ($line%15 == 13) {
      $rain[0] = substr($_,16,5);
      $rain[1] = substr($_,28,5);
      $rain[2] = substr($_,40,5);
      $rain[3] = substr($_,52,5);
      $rain[4] = substr($_,64,5);
      $rain[5] = substr($_,76,5);
      $snow[0] = substr($_,22,4);
      $snow[1] = substr($_,34,4);
      $snow[2] = substr($_,46,4);
      $snow[3] = substr($_,58,4);
      $snow[4] = substr($_,70,4);
      $snow[5] = substr($_,82,4);
      $np = 4;
      ++$np if ($strlen > 66);
      ++$np if ($strlen > 78);
      ++$np if ($strlen > 90);
      &xmlzone($np) if (defined($bc_zone{$staname}));
    }
    ++$line;
  } 

} else {

  while(<IN>) {
    $strlen = length;
    if ($line%5 == 0) {
      $staname = substr($_,0,10);
      $staname =~ s/\s+$//;
      if ($perflag eq "day") {
        $temp[0] = substr($_,24,3);
        $temp[1] = substr($_,32,3);
        $temp[2] = substr($_,48,3);
        $temp[3] = substr($_,56,3);
        $temp[4] = substr($_,72,3);
        $temp[5] = substr($_,80,3);
      } else {
        $temp[0] = substr($_,20,3);
        $temp[1] = substr($_,36,3);
        $temp[2] = substr($_,44,3);
        $temp[3] = substr($_,60,3);
        $temp[4] = substr($_,68,3);
        $temp[5] = substr($_,84,3);
      }
    } elsif ($line%5 == 1) {
      $spd[0] = substr($_,16,3);
      $spd[1] = substr($_,28,3);
      $spd[2] = substr($_,40,3);
      $spd[3] = substr($_,52,3);
      $spd[4] = substr($_,64,3);
      $spd[5] = substr($_,76,3);
      $gst[0] = substr($_,24,3);  # Use avarage gust, which is stored in max wind speed
      $gst[1] = substr($_,36,3);
      $gst[2] = substr($_,48,3);
      $gst[3] = substr($_,60,3);
      $gst[4] = substr($_,72,3);
      $gst[5] = substr($_,84,3);
    } elsif ($line%5 == 2) {
      $dir[0] = substr($_,16,3);
      $dir[1] = substr($_,28,3);
      $dir[2] = substr($_,40,3);
      $dir[3] = substr($_,52,3);
      $dir[4] = substr($_,64,3);
      $dir[5] = substr($_,76,3);
    } elsif ($line%5 == 3) {
      $sky[0] = substr($_,17,9);
      $sky[1] = substr($_,29,9);
      $sky[2] = substr($_,41,9);
      $sky[3] = substr($_,53,9);
      $sky[4] = substr($_,65,9);
      $sky[5] = substr($_,77,9);
    } elsif ($line%5 == 4) {
      $rain[0] = substr($_,16,5);
      $rain[1] = substr($_,28,5);
      $rain[2] = substr($_,40,5);
      $rain[3] = substr($_,52,5);
      $rain[4] = substr($_,64,5);
      $rain[5] = substr($_,76,5);
      $snow[0] = substr($_,22,4);
      $snow[1] = substr($_,34,4);
      $snow[2] = substr($_,46,4);
      $snow[3] = substr($_,58,4);
      $snow[4] = substr($_,70,4);
      $snow[5] = substr($_,82,4);
      $np = 5 - $offset;
      ++$np if ($strlen > 77);
      &xmlzone($np) if (defined($bc_zone{$staname}));
    }
    ++$line;
  } 

}
close(IN);

print OUT "</WeatherForecast>\n";
close(OUT);

exit;

#===============================================================================
# Check if NWS text file has useable data.

sub checknws {
  my ($fcstfile) = @_;
  my @temp;
  my $valid = 0;

  open(IN,$fcstfile);
  while(<IN>) {
    $temp[0] = substr($_,52,3) + 0;
    $temp[1] = substr($_,56,3) + 0;
    $temp[2] = substr($_,60,3) + 0;
    if ($temp[0] == 0 && $temp[1] == 0 && $temp[2] == 0) {
      $valid = 0
    } else {
      $valid = 1
    };
    last;
  }
  close(IN);

  return $valid;
}

#===============================================================================
# Check if the wrf text file has useable data.

sub checkwrf {
  my ($fcstfile) = @_;
  my @temp;
  my $line = 0;

  open(IN,$fcstfile);
  while(<IN>) {
    if ($line == 4) {
      $temp[0] = substr($_,52,3);
      $temp[1] = substr($_,56,3);
      $temp[2] = substr($_,60,3);
      $mdl = 1 if (($temp[0] != 0 || $temp[1] != 0 || $temp[2] != 0));
    } elsif ($line > 4) {
      last;
    }
    ++$line;
  }
  close(IN);

  return $mdl;
}
  
#===============================================================================

sub xmlzone {
  my ($np) = @_;
  my ($n,$min,$max,$temp,$spd,$gst,$dir,$sky,$rain,$snow);

  print OUT "  <station name=\"$staname\" bc_zone=\"$bc_zone{$staname}\">\n";
  for ($n=0; $n<$np; $n++) {

    $temp = $temp[$n+$offset];
    $temp =~ s/^\s+//;
    $spd = $spd[$n+$offset];
    $spd =~ s/^\s+//;
    $gst = $gst[$n+$offset];
    $gst =~ s/^\s+//;
#   $spd = "$spd"."g$gst" if ($gst+0 > $spd+9);
    $dir = &direction($dir[$n+$offset]);
    $sky = $sky[$n+$offset];
    $sky =~ s/^\s+//;
    $rain = $rain[$n+$offset];
    $rain =~ s/^\s+//;
    $rain = &nint($rain*10)/10;
    $rain = sprintf("%.1f", $rain) if ($rain > 0);
    $snow = $snow[$n+$offset];
    $snow =~ s/^\s+//;
    $snow = &nint($snow);
    print OUT "    <weatherData timePeriod=\"$times[$n]\">\n";
    print OUT "      <temperature>$temp</temperature>\n";
    print OUT "      <windSpeed>$spd</windSpeed>\n";
    print OUT "      <windGust>$gst</windGust>\n";
    print OUT "      <windDirection>$dir</windDirection>\n";
    print OUT "      <cloudCategory>$sky{$sky}</cloudCategory>\n";
    print OUT "      <rain>$rain</rain>\n";
    print OUT "      <snow>$snow</snow>\n";
    print OUT "    </weatherData>\n";
  }
  print OUT "  </station>\n";
}

#===============================================================================

sub direction {
  my ($dir) = @_;
  my $adir;

  if ($dir >= 11.25 && $dir < 33.75) {
    $adir = "NNE";
  } elsif ($dir >= 33.75 && $dir < 56.25) {
    $adir = "NE";
  } elsif ($dir >= 56.25 && $dir < 78.75) {
    $adir = "ENE";
  } elsif ($dir >= 78.75 && $dir < 101.25) {
    $adir = "E";
  } elsif ($dir >= 101.25 && $dir < 123.75) {
    $adir = "ESE";
  } elsif ($dir >= 123.75 && $dir < 146.25) {
    $adir = "SE";
  } elsif ($dir >= 146.25 && $dir < 168.75) {
    $adir = "SSE";
  } elsif ($dir >= 168.75 && $dir < 191.25) {
    $adir = "S";
  } elsif ($dir >= 191.25 && $dir < 213.75) {
    $adir = "SSW";
  } elsif ($dir >= 213.75 && $dir < 236.25) {
    $adir = "SW";
  } elsif ($dir >= 236.25 && $dir < 258.75) {
    $adir = "WSW";
  } elsif ($dir >= 258.75 && $dir < 281.25) {
    $adir = "W";
  } elsif ($dir >= 281.25 && $dir < 303.75) {
    $adir = "WNW";
  } elsif ($dir >= 303.75 && $dir < 326.25) {
    $adir = "NW";
  } elsif ($dir >= 326.25 && $dir < 348.75) {
    $adir = "NNW";
  } else {
    $adir = "N";
  }

  return $adir;
}

#===============================================================================

sub nint($) { my ($z) = @_; return ($z>0)? int($z+0.5) : int($z-0.5); }
