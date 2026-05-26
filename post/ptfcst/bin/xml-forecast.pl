#!/usr/bin/perl
use strict;
use Getopt::Std;

# Command line options:
#   -d model date (yyyy-mm-dd-hhmm)
#   -m model (default=ndfd)
#   -z zone (old or new, default=old)

use vars qw($opt_d $opt_m $opt_z);
getopt('dmz');

my $model = "ndfd";
$model = $opt_m if defined($opt_m);
if ($model ne "ndfd" && $model ne "nbm" && $model ne "wrf4km" && $model ne "wrf2km") {
  print "$model model is not allowed.\n";
  exit;
}

my $zone = "old";
if (defined($opt_z)) {
  $zone = "new" if ($opt_z eq "new");
}

my $date;
if (defined $opt_d) {
  $date = $opt_d;
} else {
  print "Date must be defined\n";
  exit;
}

my $fcstdir = "/home/caic/caic/rtsys/post/ptfcst";

my (%bc_zone,%hw_zone);
if ($zone eq "old") {

  %bc_zone = qw(
                PARKRANGE   0 
                BERTHPASS   1
                LVLNDPASS   2
                MONARCHPAS  3
                INDEPPASS   4 
                SCHOFIELD   5
                GRAND_MESA  6
                RMP         7
                WOLFCKPASS  8
                SANGRERNGE  9
                CAMERONPCO -1
                R_MCLURE   -1
                BATTLEMTN  -1
                GLENWDCAN  -1
                DOUGLASPAS -1
                SLUMGULPAS -1
                LIZHEADPAS -1
                VAIL_PASS  -1
                TUNNELS    -1
                FREMONTPAS -1
                TWINLAKES  -1
                CUMBRESPAS -1
               );

  %hw_zone = qw(
                PARKRANGE  -1 
                BERTHPASS   1
                LVLNDPASS   2
                MONARCHPAS 14
                INDEPPASS   7 
                SCHOFIELD  -1
                GRAND_MESA 11
                RMP        17
                WOLFCKPASS 15
                SANGRERNGE -1
                CAMERONPCO  0
                R_MCLURE    9
                BATTLEMTN   6
                GLENWDCAN  10
                DOUGLASPAS 12
                SLUMGULPAS 13
                LIZHEADPAS 18
                VAIL_PASS   4
                TUNNELS     3
                FREMONTPAS  5
                TWINLAKES   8
                CUMBRESPAS 16
               );

} else {

  %bc_zone = qw(
                ZONE100 100
                ZONE101 101
                ZONE102 102
                ZONE103 103
                ZONE104 104
                ZONE105 105
                ZONE106 106
                ZONE107 107
                ZONE108 108
                ZONE109 109
                ZONE110 110
                ZONE111 111
                ZONE112 112
                ZONE113 113
                ZONE114 114
                ZONE115 115
                ZONE116 116
                ZONE117 117
                ZONE118 118
                ZONE119 119
                ZONE120 120
               );

  %hw_zone = qw(
                ZONE100 -1
                ZONE101 -1
                ZONE102 -1
                ZONE103 -1
                ZONE104 -1
                ZONE105 -1
                ZONE106 -1
                ZONE107 -1
                ZONE108 -1
                ZONE109 -1
                ZONE110 -1
                ZONE111 -1
                ZONE112 -1
                ZONE113 -1
                ZONE114 -1
                ZONE115 -1
                ZONE116 -1
                ZONE117 -1
                ZONE118 -1
                ZONE119 -1
                ZONE120 -1
               );

}

my %sky = qw(
             CLEAR     CL
             FEW       CM
             SCATTERED PC
             BROKEN    MC
             OVERCAST  OV
            );

my @times = ("0","1","2","3");

# Set fcst file name dependent on model.

my $mdl = 0;
my $mos = 0;
my $combined = 0;
my $offset = 0;
my $period = "am";
my ($fcstfile,$hh);
$fcstfile = "$fcstdir/table/$date/$model".".txt";
if (-e $fcstfile) {
  if (substr($model,0,3) eq "wrf") {
    if (! &checkwrf($fcstfile)) {
      print "$fcstfile is incomplete.\n";
      exit;
    }
  } else {
    if (! &checknws($fcstfile)) {
      print "$fcstfile is incomplete.\n";
      exit;
    }
  }
} else {
  print "$fcstfile not found.\n";
  exit;
}
my $perflag = "day";
$hh = substr($date,11,2);
if ($hh > 13 && ($model eq "ndfd" || $model eq "nbm")) {
  $offset = 1;
  $perflag = "night";
}
if ($hh >= 12 && substr($model,0,3) eq "wrf") {
  $period = "pm";
  $perflag = "night";
}
print "$fcstfile $mdl $mos $combined $offset $period\n";

# Open output xml file and write header data.

my $xmlfile;
if ($zone eq "old") {
  $xmlfile = "$fcstdir/xml/forecast-$model".".xml";
} else {
  $xmlfile = "$fcstdir/xml/forecast-$model"."-new.xml";
}
print "$xmlfile\n";

open(OUT,">$xmlfile");

print OUT "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n";
print OUT "<WeatherForecast product=\"Avalanche\" ForecastModel=\"$model\" ForecastDate=\"$date\" PeriodFlag=\"$perflag\" >\n";

# Parse out data and call xmlzone to write data to xml file.

my ($staname,@temp,@spd,@dir,@sky,@snow);
my $line = 0;

open(IN,$fcstfile);
if ($combined) {

  print "$mdl $mos\n";
  while(<IN>) {
    if ($line%19 == 2) {
      $staname = substr($_,3,10);
      $staname =~ s/\s+$//;
    } elsif ($line%19 == 3+$mdl+$mos) {
      if ($period eq "am") {
        $temp[0] = substr($_,24,3);
        $temp[1] = substr($_,32,3);
        $temp[2] = substr($_,48,3);
        $temp[3] = substr($_,56,3);
        $temp[4] = substr($_,72,3);
      } else {
        $temp[0] = substr($_,20,3);
        $temp[1] = substr($_,36,3);
        $temp[2] = substr($_,44,3);
        $temp[3] = substr($_,60,3);
        $temp[4] = substr($_,68,3);
      }
    } elsif ($line%19 == 7+$mdl) {
      $spd[0] = substr($_,16,3);
      $spd[1] = substr($_,28,3);
      $spd[2] = substr($_,40,3);
      $spd[3] = substr($_,52,3);
      $spd[4] = substr($_,64,3);
    } elsif ($line%19 == 10+$mdl) {
      $dir[0] = substr($_,16,3);
      $dir[1] = substr($_,28,3);
      $dir[2] = substr($_,40,3);
      $dir[3] = substr($_,52,3);
      $dir[4] = substr($_,64,3);
    } elsif ($line%19 == 13+$mdl) {
      $sky[0] = substr($_,17,9);
      $sky[1] = substr($_,29,9);
      $sky[2] = substr($_,41,9);
      $sky[3] = substr($_,53,9);
      $sky[4] = substr($_,65,9);
    } elsif ($line%19 == 16+$mdl) {
      $snow[0] = substr($_,22,4);
      $snow[1] = substr($_,34,4);
      $snow[2] = substr($_,46,4);
      $snow[3] = substr($_,58,4);
      $snow[4] = substr($_,70,4);
    } elsif ($line%19 == 0 && $line != 0) {
      &xmlzone if (defined($bc_zone{$staname}));
    }
    ++$line;
  } 

} elsif (substr($model,0,3) eq "wrf") {

  print "wrf\n";
  --$line;
  while(<IN>) {
    if ($line%15 == 1) {
      $staname = substr($_,3,10);
      $staname =~ s/\s+$//;
    } elsif ($line%15 == 3) {
      if ($period eq "am") {
        $temp[0] = substr($_,24,3);
        $temp[1] = substr($_,32,3);
        $temp[2] = substr($_,48,3);
        $temp[3] = substr($_,56,3);
      } else {
        $temp[0] = substr($_,20,3);
        $temp[1] = substr($_,36,3);
        $temp[2] = substr($_,44,3);
        $temp[3] = substr($_,60,3);
      }
    } elsif ($line%15 == 5) {
      $spd[0] = substr($_,16,3);
      $spd[1] = substr($_,28,3);
      $spd[2] = substr($_,40,3);
      $spd[3] = substr($_,52,3);
    } elsif ($line%15 == 9) {
      $dir[0] = substr($_,16,3);
      $dir[1] = substr($_,28,3);
      $dir[2] = substr($_,40,3);
      $dir[3] = substr($_,52,3);
    } elsif ($line%15 == 11) {
      $sky[0] = substr($_,17,9);
      $sky[1] = substr($_,29,9);
      $sky[2] = substr($_,41,9);
      $sky[3] = substr($_,53,9);
    } elsif ($line%15 == 13) {
      $snow[0] = substr($_,22,4);
      $snow[1] = substr($_,34,4);
      $snow[2] = substr($_,46,4);
      $snow[3] = substr($_,58,4);
      &xmlzone if (defined($bc_zone{$staname}));
    }
    ++$line;
  } 

} else {

  while(<IN>) {
    if ($line%5 == 0) {
      $staname = substr($_,0,10);
      $staname =~ s/\s+$//;
      $temp[0] = substr($_,24,3);
      $temp[1] = substr($_,32,3);
      $temp[2] = substr($_,48,3);
      $temp[3] = substr($_,56,3);
      $temp[4] = substr($_,72,3);
    } elsif ($line%5 == 1) {
      $spd[0] = substr($_,16,3);
      $spd[1] = substr($_,28,3);
      $spd[2] = substr($_,40,3);
      $spd[3] = substr($_,52,3);
      $spd[4] = substr($_,64,3);
    } elsif ($line%5 == 2) {
      $dir[0] = substr($_,16,3);
      $dir[1] = substr($_,28,3);
      $dir[2] = substr($_,40,3);
      $dir[3] = substr($_,52,3);
      $dir[4] = substr($_,64,3);
    } elsif ($line%5 == 3) {
      $sky[0] = substr($_,17,9);
      $sky[1] = substr($_,29,9);
      $sky[2] = substr($_,41,9);
      $sky[3] = substr($_,53,9);
      $sky[4] = substr($_,65,9);
    } elsif ($line%5 == 4) {
      $snow[0] = substr($_,22,4);
      $snow[1] = substr($_,34,4);
      $snow[2] = substr($_,46,4);
      $snow[3] = substr($_,58,4);
      $snow[4] = substr($_,70,4);
      &xmlzone if (defined($bc_zone{$staname}));
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
# Check if the combined (NWS and MM5) text file has useable MM5 data.

sub checkcombined {
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
    } elsif ($line == 5) {
      $temp[0] = substr($_,52,3);
      $temp[1] = substr($_,56,3);
      $temp[2] = substr($_,60,3);
      $mos = 1 if (($temp[0] != 0 || $temp[1] != 0 || $temp[2] != 0));
    } elsif ($line > 5) {
      last;
    }
    ++$line;
  }
  close(IN);

  return $mdl;
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
  my ($n,$min,$max,$temp,$spd,$dir,$sky,$snow);

  print OUT "  <zone bc_zone=\"$bc_zone{$staname}\" hw_zone=\"$hw_zone{$staname}\">\n";
  for ($n=0; $n<4; $n++) {


    $min = $temp[$n+$offset] - 2;
    $max = $min + 5;
    $temp = "$min to $max";
    $min = $spd[$n+$offset] - 5;
    $min = 0 if ($min < 0);
    $max = $min + 10;
    $spd = "$min to $max";
    $dir = &direction($dir[$n+$offset]);
    $sky = $sky[$n+$offset];
    $sky =~ s/^\s+//;
    $snow = $snow[$n+$offset];
    $snow =~ s/^\s+//;
    if ($snow < 0) {
       $snow="-1";
    } elsif ($snow == 0) {
       $snow = "0";
    } elsif ($snow < 0.5) {
       $snow = "0 to 1";
    } else {
       $snow = &nint($snow);
       $min = $snow - 1;
       $max = $snow + 1;
       $snow = "$min to $max";
    }
    print OUT "    <weatherData timePeriod=\"$times[$n]\">\n";
    print OUT "      <temperature>$temp</temperature>\n";
    print OUT "      <windSpeed>$spd</windSpeed>\n";
    print OUT "      <windDirection>$dir</windDirection>\n";
    print OUT "      <cloudCategory>$sky{$sky}</cloudCategory>\n";
    print OUT "      <snow>$snow</snow>\n";
    print OUT "    </weatherData>\n";
  }
  print OUT "  </zone>\n";
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
