#!/usr/bin/perl 
use strict;                               
use DBI;
use Getopt::Std;

# Command line options.
#   -h Help.
#   -k Remove existing model table if it already exists.
#   -t model time (yyyymmddhh_Fffffffff, default is parsed from filename)
#   -m model id (default = parsed from model name)
#   -d model domain (default = caic)
#   -r model grid spacing (default = 4km)

use vars qw($opt_h $opt_k $opt_t $opt_m $opt_d $opt_r);

# Usage info.
 
$| = 1;                                   # Unbuffer std_out.
(my $prog = $0) =~ s%.*/%%;               # Determine program basename.
my $usage = <<EOF;
Usage: $prog [-hd] [-t yyyymmddhh_Fffffffff] [-m modelid] [-d model domain] [-r model grid spacing] model_file
  -h  Help
  -k  Remove existing model table if it already exists.
  -t  Model time (yyyymmddhh_Fffffffff where forecast time is in sec)
  -m  modelid (default = parsed from model file name)
  -d  model domain (default = caic)
  -r model grid spacing (default = 4km)

   model_file name

EOF
 
# Fill variables based on command line options.
 
&getopts('hkt:m:d:r:') || die $usage;
die $usage if defined $opt_h;
die $usage unless ($#ARGV == 0);

my $droptable = 0;
$droptable = 1 if defined $opt_k;

my $infile = $ARGV[0];

my ($yyyy,$jjj,$mm,$dd,$hh,$fcst);
if (defined $opt_t) {
  ($yyyy, $mm, $dd, $hh, $fcst) = $opt_t =~ /(\d{4})(\d{2})(\d{2})(\d{2})_F(\d{1,8})/;
} else {
  ($yyyy, $jjj, $hh, $fcst) = $infile =~ /(\d{4})(\d{3})(\d{2})00_(\d{1,8})/;
  ($mm,$dd) = &JJJ2MMDD($jjj,$yyyy);
}
my $ainittime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $yyyy, $mm, $dd, $hh, 0, 0);
my $inittime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
my $valtime = $inittime + $fcst;
my ($fyyy, $fm, $fd, $fh) = &unix_to_time($valtime);
my $avaltime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $fyyy, $fm, $fd, $fh, 0, 0);

my $modelid;
if (defined $opt_m) {
  $modelid = $opt_m;
} else {
  ($modelid) = $infile =~ /.*\/?.*\.(.*)\..*/;
}

my $domain = "caic";
$domain = $opt_d if defined $opt_d;

my $res = "4km";
$res = $opt_r if defined $opt_r;

print "Model initial time: $ainittime\n";
print "Model fcst time   : $avaltime\n";

# Connect to the weather database.

my ($sql,$sth,$host,$dbname,$username,$password);

$host = "127.0.0.1";
$dbname = "ptfcst";
$username = "caic";
$password = "steepndeep";
 
print "Connecting to database: $dbname as user: $username\n";
my $db = DBI->connect("DBI:mysql:$dbname:$host", $username, $password);

# Create the model forecast table.

$mm = "0".$mm while(length($mm)<2);
$dd = "0".$dd while(length($dd)<2);
my $table = "NwpOutput$yyyy$mm$dd";
if ($droptable) {
  $sql = qq{ DROP TABLE IF EXISTS $table };
  $sth = $db->do($sql);
}

print "Creating TABLE with name: $table\n";
$sql = qq{
          CREATE TABLE IF NOT EXISTS $table (
              inittime DATETIME NOT NULL,
              modelid CHAR(3) NOT NULL,
              domain CHAR(10) NOT NULL,
              res CHAR(5) NOT NULL,
              validtime DATETIME NOT NULL,
              staname CHAR(10) NOT NULL,
              mslp SMALLINT UNSIGNED,
              stnpres SMALLINT UNSIGNED,
              temp SMALLINT,
              dewp SMALLINT,
              uwnd SMALLINT,
              vwnd SMALLINT,
              gust SMALLINT UNSIGNED,
              wwnd SMALLINT,
              swrad SMALLINT UNSIGNED,
              swpct TINYINT UNSIGNED DEFAULT NULL,
              lwrad SMALLINT UNSIGNED,
              ltemp SMALLINT,
              luwnd SMALLINT,
              lvwnd SMALLINT,
              gtemp SMALLINT,
              stemp SMALLINT,
              rnto SMALLINT UNSIGNED,
              rntc SMALLINT UNSIGNED,
              snto MEDIUMINT UNSIGNED,
              mixht INT UNSIGNED,
              visib SMALLINT UNSIGNED,
              clg SMALLINT UNSIGNED,
              pcptyp TINYINT UNSIGNED,
              cldpct TINYINT UNSIGNED,
              wetbulb SMALLINT,
              m5ht SMALLINT,
              temp700 SMALLINT,
              clw700 SMALLINT,
              uwnd700 SMALLINT,
              vwnd700 SMALLINT,
              PRIMARY KEY (modelid, domain, res, inittime, validtime, staname),
              INDEX indStd (modelid, domain, res, inittime, validtime, staname)
           )
};
$sth = $db->do($sql);

# Prepare to populate.

my %var;
$sql = qq{
  REPLACE INTO $table (inittime, modelid, domain, res, validtime,
                       staname, mslp, stnpres, temp, dewp, uwnd, vwnd, gust, wwnd, 
                       swrad, swpct, lwrad, ltemp, luwnd, lvwnd, gtemp, stemp,
                       rnto, rntc, snto, mixht, visib, clg, pcptyp, cldpct, wetbulb,
                       m5ht, temp700, clw700, uwnd700, vwnd700)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
};
$sth = $db->prepare($sql);

# Parse the input file.

print "Opening input model file: $infile\n";

open (IN, $infile) || die "Cannot open file: $infile\n";
while (<IN>) {
  chomp;
  next if (/^\#/);

  ($var{"stnm"},    $var{"mslp"},    $var{"spr"},     $var{"stp"},
   $var{"std"},     $var{"uwnd"},    $var{"vwnd"},    $var{"gust"},
   $var{"wwnd"},    $var{"swrad"},   $var{"swpct"},   $var{"lwrad"},
   $var{"ltp"},     $var{"luw"},     $var{"lvw"},     $var{"gtp"},
   $var{"dtp"},     $var{"rnto"},    $var{"rntc"},    $var{"snto"},
   $var{"mixht"},   $var{"visib"},   $var{"clg"},     $var{"pty"},
   $var{"cld"},     $var{"wtb"},     $var{"m5ht"},    $var{"temp700"},
   $var{"clw700"},  $var{"uwnd700"}, $var{"vwnd700"}) 
  = split (/\|/, $_, 31);

# Scale data to integers as defined in table creation to save database space.

  &scaledata();

# Populate the table.

  $sth->execute(
    "$ainittime", "$modelid", "$domain", "$res", "$avaltime",
    $var{"stnm"},    $var{"mslp"},    $var{"spr"},     $var{"stp"},
    $var{"std"},     $var{"uwnd"},    $var{"vwnd"},    $var{"gust"},
    $var{"wwnd"},    $var{"swrad"},   $var{"swpct"},   $var{"lwrad"},
    $var{"ltp"},     $var{"luw"},     $var{"lvw"},     $var{"gtp"},
    $var{"dtp"},     $var{"rnto"},    $var{"rntc"},    $var{"snto"},
    $var{"mixht"},   $var{"visib"},   $var{"clg"},     $var{"pty"},
    $var{"cld"},     $var{"wtb"},     $var{"m5ht"},    $var{"temp700"},
    $var{"clw700"},  $var{"uwnd700"}, $var{"vwnd700"}
  );

}

close IN;

# Disconnect from the db.

$db->disconnect;

exit;

#===============================================================================

sub scaledata {

# Gross error check the data and scale to fit into database.

  my $k2c   = -273.15;
  my $mm2in = 0.03937;  #   1/(2.54*10);
  my $m2ft  = 3.28084;  # 100/(2.54*12);
  my $km2mi = 0.62137;

  $var{"stp"} += $k2c;
  $var{"std"} += $k2c;
  $var{"gtp"} += $k2c;
  $var{"dtp"} += $k2c;
  $var{"rnto"} *= $mm2in;
  $var{"rntc"} *= $mm2in;
  $var{"snto"} *= $mm2in;
  $var{"ltp"} += $k2c;
  $var{"visib"} *= $km2mi;
  $var{"mixht"} *= $m2ft;
  $var{"clg"} *= $m2ft;
  $var{"wtb"} += $k2c;
  $var{"temp700"} += $k2c;

# Mean sea-level pressure (mb*10).
  if ($var{"mslp"} < 850 || $var{"mslp"} > 1075) {
    $var{"mslp"} = undef;
  } else {
    $var{"mslp"} = &nint($var{"mslp"} * 10);
  }

# Station pressure (mb*10).
  if ($var{"spr"} < 5 || $var{"spr"} > 1075) {
    $var{"spr"} = undef;
  } else {
    $var{"spr"} = &nint($var{"spr"} * 10);
  }

# Station temperature (C*10).
  if ($var{"stp"} < -89 || $var{"stp"} > 60) {
    $var{"stp"} = undef;
  } else {
    $var{"stp"} = &nint($var{"stp"} * 10);
  }

# Station dewpoint (C*10).
  if ($var{"std"} < -89 || $var{"std"} > 50) {
    $var{"std"} = undef;
  } else {
    $var{"std"} = &nint($var{"std"} * 10);
  }

# U-wind component (m/s*10).
  if ($var{"uwnd"} < -125 || $var{"uwnd"} > 125) {
    $var{"uwnd"} = undef;
  } else {
    $var{"uwnd"} = &nint($var{"uwnd"} * 10);
  }

# V-wind component (m/s*10).
  if ($var{"vwnd"} < -125 || $var{"vwnd"} > 125) {
    $var{"vwnd"} = undef;
  } else {
   $var{"vwnd"} = &nint($var{"vwnd"} * 10);
  }

# Wind gust (m/s*10).
  if ($var{"gust"} < 0 || $var{"gust"} > 100) {
    $var{"gust"} = undef;
  } else {
    $var{"gust"} = &nint($var{"gust"} * 10);
  }

# W-wind component (m/s*100).
  if ($var{"wwnd"} < -100 || $var{"wwnd"} > 100) {
    $var{"wwnd"} = undef;
  } else {
    $var{"wwnd"} = &nint($var{"wwnd"} * 100);
  }

# Ground temperature (C*10).
  if ($var{"gtp"} < -100 || $var{"gtp"} > 100) {
    $var{"gtp"} = undef;
  } else {
    $var{"gtp"} = &nint($var{"gtp"} * 10);
  }

# Soil temperature (C*10).
  if ($var{"dtp"} < -100 || $var{"dtp"} > 100) {
    $var{"dtp"} = undef;
  } else {
    $var{"dtp"} = &nint($var{"dtp"} * 10);
  }

# Shortwave radiation (W/m**2).
  if ($var{"swrad"} < 0 || $var{"swrad"} > 2000) {
    $var{"swrad"} = undef;
  } else {
    $var{"swrad"} = &nint($var{"swrad"});
  }

# Shortwave rad percent (%).
  if ($var{"swpct"} < -0.4 || $var{"swpct"} > 100.4) {
    $var{"swpct"} = undef;
  } else {
    $var{"swpct"} = &nint($var{"swpct"});
  }

# Longwave radation (W/m**2).
  if ($var{"lwrad"} < 0 || $var{"lwrad"} > 2000) {
    $var{"lwrad"} = undef;
  } else {
    $var{"lwrad"} = &nint($var{"lwrad"});
  }

# Total accumulated precip (in*1000).
  if ($var{"rnto"} < 0 || $var{"rnto"} > 60) {
    $var{"rnto"} = undef;
  } else {
    $var{"rnto"} = &nint($var{"rnto"} * 1000)
  }

# Total accumulated convective precip (in*1000).
  if ($var{"rntc"} < 0 || $var{"rntc"} > 60) {
    $var{"rntc"} = undef;
  } else {
    $var{"rntc"} = &nint($var{"rntc"} * 1000)
  }

# Total frozen accumulated precip (in*1000).
  if ($var{"snto"} < 0 || $var{"snto"} > 200) {
    $var{"snto"} = undef;
  } else {
    $var{"snto"} = &nint($var{"snto"} * 1000);
  }

# Low-level model temperature (C*10).
  if ($var{"ltp"} < -89 || $var{"ltp"} > 60) {
    $var{"ltp"} = undef;
  } else {
    $var{"ltp"} = &nint($var{"ltp"} * 10);
  }

# Low-level model U-wind component (m/s*10).
  if ($var{"luw"} < -125 || $var{"luw"} > 125) {
    $var{"luw"} = undef;
  } else {
    $var{"luw"} = &nint($var{"luw"} * 10);
  }

# Low-level model V-wind component (m/s*10).
  if ($var{"lvw"} < -125 || $var{"lvw"} > 125) {
    $var{"lvw"} = undef;
  } else {
    $var{"lvw"} = &nint($var{"lvw"} * 10);
  }

# Mixing height.
  if ($var{"mixht"} < 0 || $var{"mixht"} > 100000) {
    $var{"mixht"} = undef;
  } else {
    $var{"mixht"} = &nint($var{"mixht"});
  }

# Visibility (miles*100).
  $var{"visib"} = -1 if ($var{"visib"} eq "NaN");
  if ($var{"visib"} < 0 || $var{"visib"} > 99) {
    $var{"visib"} = undef;
  } else {
    $var{"visib"} = &nint($var{"visib"} * 100);
  }

# Ceiling (ft/100).
  if ($var{"clg"} < 0 || $var{"clg"} > 60000) {
    $var{"clg"} = undef;
  } else {
    $var{"clg"} = &nint($var{"clg"} / 100);
  }

# Precip type (no changes).

# Cloud cover (%).
  $var{"cld"} = 0 if ($var{"cld"} < 0);
  $var{"cld"} = 100 if ($var{"cld"} > 100);
  $var{"cld"} = &nint($var{"cld"});

# Wet-bulb temperature (C*10).
  if ($var{"wtb"} < -89 || $var{"wtb"} > 60) {
    $var{"wtb"} = undef;
  } else {
    $var{"wtb"} = &nint($var{"wtb"} * 10);
  }

# 700 mb height of -5C isotherm (no changes).

# 700 mb temperature (C*10).
  if ($var{"temp700"} < -89 || $var{"temp700"} > 60) {
    $var{"temp700"} = undef;
  } else {
    $var{"temp700"} = &nint($var{"temp700"} * 10);
  }

# 700 mb cloud water (g/kg*1000).
  if ($var{"clw700"} < 0 || $var{"clw700"} > 0.01) {
    $var{"clw700"} = undef;
  } else {
    $var{"clw700"} = &nint($var{"clw700"} * 1000000);
  }

# 700mb U-wind component (m/s*10).
  if ($var{"uwnd700"} < -125 || $var{"uwnd700"} > 125) {
    $var{"uwnd700"} = undef;
  } else {
    $var{"uwnd700"} = &nint($var{"uwnd700"} * 10);
  }

# V-wind component (m/s*10).
  if ($var{"vwnd700"} < -125 || $var{"vwnd700"} > 125) {
    $var{"vwnd700"} = undef;
  } else {
   $var{"vwnd700"} = &nint($var{"vwnd700"} * 10);
  }

}

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

#===============================================================================

sub nint { my ($z) = @_; return ($z>0)? int($z+0.5) : int($z-0.5); }
