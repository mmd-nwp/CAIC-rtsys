#!/usr/bin/perl
use strict;
use DBI;
use NetCDF;
use Getopt::Std;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Command line options:
#  -d initial date (yyyymmdd_hhmn, default = current)
#  -t data type (all,metar,mesonet,hydro,snow, default = all)

use vars qw($opt_d $opt_t);
getopt('dt');

# Define directories.

my $root = "/home/caic/caic/rtsys/obs/provider/madis";
my ($madisdir) = &dbInfo::madisDir();

# Determine the time from argument or current time (default).

my $time = time;
my ($yyyy,$mm,$dd,$hh,$mn,%atime);
if ($opt_d) {
  $yyyy = substr($opt_d,0,4);
  $mm = substr($opt_d,4,2);
  $dd = substr($opt_d,6,2);
  $hh = substr($opt_d,9,2);
  $mn = substr($opt_d,11,2);
} else {
  ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
  $mm = "0".$mm while(length($mm)<2);
  $dd = "0".$dd while(length($dd)<2);
  $hh = "0".$hh while(length($hh)<2);
  $mn = "00";
}
my $madistime = "$yyyy$mm$dd"."_$hh$mn";
my $time = &time_to_unix($mm, $dd, $yyyy, $hh, $mn);
my $atime = sprintf("%04d-%02d-%02d %02d:%02d:%02d",$yyyy,$mm,$dd,$hh,$mn,0);

# Determine data type.

my $datatype = "all";
if ($opt_t) {
  $datatype = $opt_t;
  $datatype = "all" if ($datatype ne "metar" && $datatype ne "mesonet"
                     && $datatype ne "hydro" && $datatype ne "snow");
}

# Define variables.

my ($filename,$ncid,$nid,$icode
   ,$name,$namelen,$nstn,@start,@count,@stations
   ,$strlen,$i,$j,@stnid,$station,$ct,$key
   ,@obtime,@lat,@lon,@provider,@snotel,$n,%stnid,$otime
   ,$tp,@tp,@tp1,%tp
   ,$td,@td,@td1,%td
   ,$rh,@rh,@rh1,%rh
   ,$sp,@sp,%sp
   ,$di,@di,%di
   ,$gs,@gs,%gs
   ,$gsdi,@gsdi,%gsdi
   ,$tpmx,@tpmx,%tpmx
   ,$tpmn,@tpmn,%tpmn
   ,$pcp1,@pcp1,%pcp1
   ,$pcp3,@pcp3,%pcp3
   ,$pcp6,@pcp6,%pcp6
   ,$pcp12,@pcp12,%pcp12
   ,$pcp24,@pcp24,%pcp24
   ,$pcpac,@pcpac,%pcpac
   ,$depth,@depth,%depth
   ,$snowwater,@snowwater,%snowwater
   ,$snow24h,@snow24h,%snow24h
   ,$snowwater24h,@snowwater24h,%snowwater24h
   ,$vis,@vis,%vis
   ,$slp,@slp,%slp
   ,@wx,%wx);

@start = (0,0,0,0,0,0,0);

if ($datatype eq "metar" || $datatype eq "all") {

# Uncompress the metar netcdf file into the work area.

system("gunzip -fc $madisdir/metar/netcdf/$madistime.gz > $root/work/$madistime.metar");

# Open the metar netcdf file.

$filename = "$root/work/$madistime.metar";
$ncid = NetCDF::open("$filename",NetCDF::NOWRITE);
if ($ncid <= 0) {
  print "Could not open metar $filename\n";
  exit;
}

# Read number of available observations.

$nid = NetCDF::dimid($ncid,"recNum" ) ;
$icode = NetCDF::diminq($ncid,$nid,$name,$nstn) ;

print "No. of metar stations: $nstn\n";

# Read metar data.

$nid = NetCDF::dimid($ncid,"maxStaNamLen");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"stationName");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $stnid[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

@count = ($nstn,1,1,1,1,1,1);
$nid = NetCDF::varid($ncid,"timeNominal");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@obtime);
$nid = NetCDF::varid($ncid,"latitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lat);
$nid = NetCDF::varid($ncid,"longitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lon);
$nid = NetCDF::varid($ncid,"temperature");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@tp);
$nid = NetCDF::varid($ncid,"tempFromTenths");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@tp1);
$nid = NetCDF::varid($ncid,"dewpoint");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@td);
$nid = NetCDF::varid($ncid,"dpFromTenths");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@td1);
$nid = NetCDF::varid($ncid,"windSpeed");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@sp);
$nid = NetCDF::varid($ncid,"windDir");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@di);
$nid = NetCDF::varid($ncid,"windGust");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@gs);
$nid = NetCDF::varid($ncid,"maxTemp24Hour");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@tpmx);
$nid = NetCDF::varid($ncid,"minTemp24Hour");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@tpmn);
$nid = NetCDF::varid($ncid,"precip1Hour");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp1);
$nid = NetCDF::varid($ncid,"precip3Hour");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp3);
$nid = NetCDF::varid($ncid,"precip6Hour");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp6);
$nid = NetCDF::varid($ncid,"precip24Hour");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp24);
$nid = NetCDF::varid($ncid,"snowCover");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@depth);
$nid = NetCDF::varid($ncid,"seaLevelPress");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@slp);

$icode = NetCDF::close($ncid);

unlink "$root/work/$madistime.metar";

# Fill weather variables into hash for stations defined in station table.

for ($i=0; $i<$nstn; $i++) {
  if (($lat[$i] > 36.9 && $lat[$i] < 41.5 && $lon[$i] > -111.0 && $lon[$i] < -105.4) 
  ||  ($lat[$i] > 38.4 && $lat[$i] < 39.7 && $lon[$i] > -120.6 && $lon[$i] < -119.7)
  ||  ($lat[$i] > 44.3 && $lat[$i] < 45.4 && $lon[$i] > -116.5 && $lon[$i] < -115.4)
  ||  ($lat[$i] > 47.1 && $lat[$i] < 49.0 && $lon[$i] > -114.9 && $lon[$i] < -113.0)) {
    $key = "$obtime[$i]$stnid[$i]";
    $stnid{$key} = $stnid[$i];
    $atime{$key} = $atime;
    $tp[$i] = $tp1[$i] if ($tp1[$i] < 400);
    if ($tp[$i] <= 400) { # Temperature (0.1 F)
      $tp{$key} = nint(($tp[$i] - 273.15) * 18 + 320);
    }
    $td[$i] = $td1[$i] if ($td1[$i] < 400);
    if ($td[$i] <= 400) { # Dewpoint (0.1 F)
      $td{$key} = nint(($td[$i] - 273.15) * 18 + 320);
    }
    if (defined $tp{$key} && defined $td{$key}) {
      $rh{$key} = nint(&td2rh($tp[$i],$td[$i]));
      $rh{$key} = 100 if ($rh{$key} > 100);
      $rh{$key} = 0 if ($rh{$key} < 0);
    }
    if ($sp[$i] >= 0 && $sp[$i] <= 100) { # Wind speed (0.1 mph)
      $sp{$key} = nint($sp[$i] * 22.37);
    }
    if ($di[$i] >= 0 && $di[$i] <= 360) { # Wind direction (deg)
      $di{$key} = nint($di[$i]);
    }
    if ($gs[$i] >= 0 && $gs[$i] <= 100) { # Wind gust (0.1 mph)
      $gs{$key} = nint($gs[$i] * 22.37);
    }
    if ($tpmx[$i] <= 400) { # Max temperature (0.1 F)
      $tpmx{$key} = nint(($tpmx[$i] - 273.15) * 18 + 320);
    }
    if ($tpmn[$i] <= 400) { # Min temperature (0.1 F)
      $tpmn{$key} = nint(($tpmn[$i] - 273.15) * 18 + 320);
    }
    if ($pcp1[$i] >= 0 && $pcp1[$i] <= 1) { # 1 hour precip (0.01 in)
      $pcp1{$key} = nint($pcp1[$i] / 0.000254);
    }
    if ($pcp3[$i] >= 0 && $pcp3[$i] <= 1) { # 3 hour precip (0.01 in)
      $pcp3{$key} = nint($pcp3[$i] / 0.000254);
    }
    if ($pcp6[$i] >= 0 && $pcp6[$i] <= 1) { # 6 hour precip (0.01 in)
      $pcp6{$key} = nint($pcp6[$i] / 0.000254);
    }
    if ($pcp24[$i] >= 0 && $pcp24[$i] <= 1) { # 24 hour precip (0.01 in)
      $pcp24{$key} = nint($pcp24[$i] / 0.000254);
    }
    if ($depth[$i] >= 0 && $depth[$i] <= 10) { # Snow depth (0.1 in)
      $depth{$key} = nint($depth[$i] / 0.00254);
    }
    if ($slp[$i] > 10000 && $slp[$i] <= 1000000) { # Mean sea level press (mb)
      $slp{$key} = nint($slp[$i] / 100);
    }
  }
}

} # End metar data.

if ($datatype eq "mesonet" || $datatype eq "all") {

# Uncompress the mesonet netcdf file into the work area.

system("gunzip -fc $madisdir/mesonet/netcdf/$madistime.gz > $root/work/$madistime.mesonet");

# Open the mesonet netcdf file.

$filename = "$root/work/$madistime.mesonet";
$ncid = NetCDF::open("$filename",NetCDF::NOWRITE);
if ($ncid <= 0) {
  print "Could not open mesonet $filename\n";
  exit;
}

# Read number of available observations.

$nid = NetCDF::dimid($ncid,"recNum" ) ;
$icode = NetCDF::diminq($ncid,$nid,$name,$nstn) ;

print "No. of mesonet stations: $nstn\n";

# Read mesonet data.

$nid = NetCDF::dimid($ncid,"maxStaIdLen");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"stationId");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@stnid = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $stnid[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

$nid = NetCDF::dimid($ncid,"maxStaTypeLen");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"dataProvider");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@provider = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $provider[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

$nid = NetCDF::dimid($ncid,"maxNameLength");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"stationName");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@snotel = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $snotel[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

@count = ($nstn,1,1,1,1,1,1);
$nid = NetCDF::varid($ncid,"observationTime");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@obtime);
$nid = NetCDF::varid($ncid,"latitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lat);
$nid = NetCDF::varid($ncid,"longitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lon);
$nid = NetCDF::varid($ncid,"temperature");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@tp);
$nid = NetCDF::varid($ncid,"dewpoint");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@td);
$nid = NetCDF::varid($ncid,"relHumidity");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@rh);
$nid = NetCDF::varid($ncid,"windSpeed");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@sp);
$nid = NetCDF::varid($ncid,"windDir");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@di);
$nid = NetCDF::varid($ncid,"windGust");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@gs);
$nid = NetCDF::varid($ncid,"windDirMax");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@gsdi);
$nid = NetCDF::varid($ncid,"visibility");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@vis);
$nid = NetCDF::varid($ncid,"seaLevelPressure");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@slp);
$nid = NetCDF::varid($ncid,"precipAccum");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcpac);

$icode = NetCDF::close($ncid);

unlink "$root/work/$madistime.mesonet";

# Fill weather variables into hash for stations defined in station table.

for ($i=0; $i<$nstn; $i++) {
# print "Snotel: $stnid[$i] $lat[$i] $lon[$i] $snotel[$i]\n";
# print "SNOTEL\n" if ($snotel[$i] eq "SNOTEL");
# next if (index($snotel[$i], "SNOTEL") != -1);
  next if (index($provider[$i], "CAIC") != -1);
  next if (substr($stnid{$i},0,3) eq "CSU");
  if (($lat[$i] > 36.9 && $lat[$i] < 41.5 && $lon[$i] > -111.0 && $lon[$i] < -105.4) 
  ||  ($lat[$i] > 38.4 && $lat[$i] < 39.7 && $lon[$i] > -120.6 && $lon[$i] < -119.7)
  ||  ($lat[$i] > 44.3 && $lat[$i] < 45.4 && $lon[$i] > -116.5 && $lon[$i] < -115.4)
  ||  ($lat[$i] > 47.1 && $lat[$i] < 49.0 && $lon[$i] > -114.9 && $lon[$i] < -113.0)
      ) {
    $key = "$obtime[$i]$stnid[$i]";
    $stnid{$key} = $stnid[$i];
    ($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($obtime[$i]);
    $atime{$key} = sprintf("%04d-%02d-%02d %02d:%02d:%02d"
                  ,$yyyy,$mm,$dd,$hh,$mn,0);
    $stnid{$key} = $stnid[$i];
    if ($tp[$i] > 0 && $tp[$i] <= 400) { # Temperature (0.1 F)
      $tp{$key} = nint(($tp[$i] - 273.15) * 18 + 320);
    }
    if ($td[$i] > 0 && $td[$i] <= 400) { # Dewpoint (0.1 F)
      $td{$key} = nint(($td[$i] - 273.15) * 18 + 320);
    }
    if ($rh[$i] > 0 && $rh[$i] <= 100) { # RH (%)
      $rh{$key} = nint($rh[$i]);
    } elsif (defined $tp{$key} && defined $td{$key}) {
      $rh{$key} = nint(&td2rh($tp[$i],$td[$i]));
      $rh{$key} = 100 if ($rh{$key} > 100);
      $rh{$key} = 0 if ($rh{$key} < 0);
    }
# Generate dew point if missing and temp and rh are available.
    if (defined $tp{$key} && defined $rh{$key} && ! defined $td{$key}) {
      $td[$i] = &rh2td($tp[$i],$rh[$i]);
      $td[$i] = $tp[$i] if ($td[$i] > $tp[$i]);
      $td{$key} = nint(($td[$i] - 273.15) * 18 + 320);
    }
    if ($sp[$i] >= 0 && $sp[$i] <= 100) { # Wind speed (0.1 mph)
      $sp{$key} = nint($sp[$i] * 22.37);
    }
    if ($di[$i] >= 0 && $di[$i] <= 360) { # Wind direction (deg)
      $di{$key} = nint($di[$i]);
    }
    if ($gs[$i] >= 0 && $gs[$i] <= 100) { # Wind gust (0.1 mph)
      $gs{$key} = nint($gs[$i] * 22.37);
    }
    if ($gsdi[$i] >= 0 && $gsdi[$i] <= 100) { # Wind gust direction (mph)
      $gsdi{$key} = nint($gsdi[$i]);
    }
    if ($vis[$i] >= 0 && $vis[$i] <= 1000000) { # Visibility (0.1 miles)
      $vis{$key} = nint($vis[$i] * 0.006215);
    }
    if ($slp[$i] > 10000 && $slp[$i] <= 1000000) { # Mean sea level press (mb)
      $slp{$key} = nint($slp[$i] / 100);
    }
    if ($pcpac[$i] >= 0 && $pcpac[$i] <= 1000) { # Precip accum (0.01 in)
      if ($provider[$i] eq "APRSWXNET"
       || $provider[$i] eq "RAWS"
       || $provider[$i] eq "UDFCD") {
        $pcp24{$key} = nint($pcpac[$i] / 0.254);
      } else {
        $pcpac{$key} = nint($pcpac[$i] / 0.254);
      }
    }
  }
}

} # End mesonet data.

my ($db,$sql,$sth);

# Connect to the weather database.

my %attr = (RaiseError=>1,  # error handling enabled 
     AutoCommit=>0); # transaction enabled

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

print "Connecting to local database: $dbname as user: $user\n";
$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

if ($datatype eq "metar" || $datatype eq "mesonet" || $datatype eq "all") {

# Fill weather data into obsWX table.

# Prepare to populate.

  $sql = qq{
    INSERT IGNORE INTO $wxtable (time, staname, temp, dewp, rh
                        ,wspd, wdir, gust, gdir
                        ,mslp, mxtemp24h, mntemp24h)
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
  };
  $sth = $db->prepare($sql);

# Populate the table.

  $db->begin_work();
  my $ct = 0;
  foreach (sort keys(%stnid)) {
    if (defined($tp{$_}) || defined($td{$_}) || defined($rh{$_})
     || defined($sp{$_}) || defined($di{$_}) || defined($gs{$_})
     || defined($gsdi{$_}) || defined($slp{$_})
     || defined($tpmx{$_}) || defined($tpmn{$_})) {
      $sth->execute(
        $atime{$_},$stnid{$_},$tp{$_},$td{$_},$rh{$_}
       ,$sp{$_},$di{$_},$gs{$_},$gsdi{$_}
       ,$slp{$_},$tpmx{$_},$tpmn{$_}
      );
#     print "$stnid{$_}\n";
      ++$ct;
    }
  }
  print "No. of db WX stations: $ct\n";
  $db->commit();

} # End weather db fill.

if ($datatype eq "hydro" || $datatype eq "all") {

# Uncompress the hydro netcdf file into the work area.

system("gunzip -fc $madisdir/hydro/netcdf/$madistime.gz > $root/work/$madistime.hydro");

# Open the hydro netcdf file.

$filename = "$root/work/$madistime.hydro";
$ncid = NetCDF::open("$filename",NetCDF::NOWRITE);
if ($ncid <= 0) {
  print "Could not open hydro $filename\n";
  exit;
}

# Read number of available observations.

$nid = NetCDF::dimid($ncid,"recNum" ) ;
$icode = NetCDF::diminq($ncid,$nid,$name,$nstn) ;

print "No. of hydro stations: $nstn\n";

# Read hydro data.

$nid = NetCDF::dimid($ncid,"maxStaIdLen");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"stationId");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@stnid = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $stnid[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

$nid = NetCDF::dimid($ncid,"maxNameLength");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"stationName");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@snotel = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $snotel[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

@count = ($nstn,1,1,1,1,1,1);
$nid = NetCDF::varid($ncid,"observationTime");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@obtime);
$nid = NetCDF::varid($ncid,"latitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lat);
$nid = NetCDF::varid($ncid,"longitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lon);
$nid = NetCDF::varid($ncid,"precip1hr");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp1);
$nid = NetCDF::varid($ncid,"precip3hr");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp3);
$nid = NetCDF::varid($ncid,"precip6hr");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp6);
$nid = NetCDF::varid($ncid,"precip24hr");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@pcp24);

$icode = NetCDF::close($ncid);

unlink "$root/work/$madistime.hydro";

# Fill hydro variables into hash for stations defined in station table.

for ($i=0; $i<$nstn; $i++) {
# next if (index($snotel[$i], "SNOTEL") != -1);
  next if (index($provider[$i], "CAIC") != -1);
  if (($lat[$i] > 36.9 && $lat[$i] < 41.5 && $lon[$i] > -111.0 && $lon[$i] < -105.4) 
  ||  ($lat[$i] > 38.4 && $lat[$i] < 39.7 && $lon[$i] > -120.6 && $lon[$i] < -119.7)
  ||  ($lat[$i] > 44.3 && $lat[$i] < 45.4 && $lon[$i] > -116.5 && $lon[$i] < -115.4)
  ||  ($lat[$i] > 47.1 && $lat[$i] < 49.0 && $lon[$i] > -114.9 && $lon[$i] < -113.0)) {
    $key = "$obtime[$i]$stnid[$i]";
    $stnid{$key} = $stnid[$i];
    ($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($obtime[$i]);
    $atime{$key} = sprintf("%04d-%02d-%02d %02d:%02d:%02d"
                  ,$yyyy,$mm,$dd,$hh,$mn,0);
    if ($pcp1[$i] >= 0 && $pcp1[$i] <= 1000) { # 1 hour precip (0.01 in)
      $pcp1{$key} = nint($pcp1[$i] / 0.254);
    }
    if ($pcp3[$i] >= 0 && $pcp3[$i] <= 1000) { # 3 hour precip (0.01 in)
      $pcp3{$key} = nint($pcp3[$i] / 0.254);
    }
    if ($pcp6[$i] >= 0 && $pcp6[$i] <= 1000) { # 6 hour precip (0.01 in)
      $pcp6{$key} = nint($pcp6[$i] / 0.254);
    }
    if ($pcp24[$i] >= 0 && $pcp24[$i] <= 1000) { # 24 hour precip (0.01 in)
      $pcp24{$key} = nint($pcp24[$i] / 0.254);
    }
  }
}

# Fill hydro data into obsHydro table.

# Prepare to populate.

$sql = qq{
  INSERT IGNORE INTO $hydrotable (time, staname, pcp1, pcp3
                      ,pcp6, pcp12, pcp24, pcpac)
  VALUES (?,?,?,?,?,?,?,?)
};
$sth = $db->prepare($sql);

# Populate the table.

$db->begin_work();
$ct = 0;
foreach (sort keys(%stnid)) {
  if (defined($pcp1{$_}) || defined($pcp3{$_})
   || defined($pcp6{$_}) || defined($pcp12{$_})
   || defined($pcp24{$_}) || defined($pcpac{$_})) {
    $sth->execute(
      $atime{$_},$stnid{$_},$pcp1{$_}
     ,$pcp3{$_},$pcp6{$_},$pcp12{$_},$pcp24{$_}
     ,$pcpac{$_}
    );
    ++$ct;
  }
}
print "No. of db hydro stations: $ct\n";
$db->commit();

} # End hydro data.

if ($datatype eq "snow" || $datatype eq "all") {

# Uncompress the snow netcdf file into the work area.

system("gunzip -fc $madisdir/snow/netcdf/$madistime.gz > $root/work/$madistime.snow");

# Open the snow netcdf file.

$filename = "$root/work/$madistime.snow";
$ncid = NetCDF::open("$filename",NetCDF::NOWRITE);
if ($ncid <= 0) {
  print "Could not open snow  $filename\n";
  exit;
}

# Read number of available observations.

$nid = NetCDF::dimid($ncid,"recNum" ) ;
$icode = NetCDF::diminq($ncid,$nid,$name,$nstn) ;

print "No. of snow stations: $nstn\n";

# Read snow data.

$nid = NetCDF::dimid($ncid,"maxStaIdLen");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"stationId");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@stnid = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  $stnid[$ct] = "";
  for ($j=$i; $j<($i+$namelen); $j++) {
    $stnid[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

$nid = NetCDF::dimid($ncid,"maxStaTypeLen");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);
$nid = NetCDF::varid($ncid,"dataProvider");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@provider = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $provider[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

$nid = NetCDF::dimid($ncid,"maxNameLength");
$icode = NetCDF::diminq($ncid,$nid,$name,$namelen);
@count = ($nstn,$namelen,1,1,1,1,1);

$strlen = "\0" x $namelen;
@stations = ($strlen) x ($nstn);

$nid = NetCDF::varid($ncid,"stationName");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@stations);

@snotel = ();
$ct = 0;
for ($i=0; $i<=$#stations; $i+=$namelen) {
  for ($j=$i; $j<($i+$namelen); $j++) {
    $snotel[$ct] .= chr($stations[$j]) if ($stations[$j] != 0);
  }
  ++$ct;
}

@count = ($nstn,1,1,1,1,1,1);
$nid = NetCDF::varid($ncid,"observationTime");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@obtime);
$nid = NetCDF::varid($ncid,"latitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lat);
$nid = NetCDF::varid($ncid,"longitude");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@lon);
$nid = NetCDF::varid($ncid,"snowDepth");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@depth);
$nid = NetCDF::varid($ncid,"snowfall24h");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@snow24h);
$nid = NetCDF::varid($ncid,"snowWaterEquivDepth");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@snowwater);
$nid = NetCDF::varid($ncid,"snowWaterEquiv24h");
$icode = NetCDF::varget($ncid,$nid,\@start,\@count,\@snowwater24h);

$icode = NetCDF::close($ncid);

unlink "$root/work/$madistime.snow";

# Fill snow variables into hash for stations defined in station table.

for ($i=0; $i<$nstn; $i++) {
# next if (index($snotel[$i], "SNOTEL") != -1);
  next if (index($provider[$i], "CAIC") != -1);
  if (($lat[$i] > 36.9 && $lat[$i] < 41.5 && $lon[$i] > -111.0 && $lon[$i] < -105.4) 
  ||  ($lat[$i] > 38.4 && $lat[$i] < 39.7 && $lon[$i] > -120.6 && $lon[$i] < -119.7)
  ||  ($lat[$i] > 44.3 && $lat[$i] < 45.4 && $lon[$i] > -116.5 && $lon[$i] < -115.4)
  ||  ($lat[$i] > 47.1 && $lat[$i] < 49.0 && $lon[$i] > -114.9 && $lon[$i] < -113.0)) {
    $key = "$obtime[$i]$stnid[$i]";
    $stnid{$key} = $stnid[$i];
    ($yyyy, $mm, $dd, $hh, $mn) = &unix_to_time($obtime[$i]);
    $atime{$key} = sprintf("%04d-%02d-%02d %02d:%02d:%02d"
                  ,$yyyy,$mm,$dd,$hh,$mn,0);
    if ($depth[$i] >= 0 && $depth[$i] <= 10000) { # Snow depth (0.1 in)
      $depth{$key} = nint($depth[$i] / 2.54);
    }
    if ($snow24h[$i] >= 0 && $snow24h[$i] <= 10000) { # 24h snowfall (0.1 in)
      $snow24h{$key} = nint($snow24h[$i] / 2.54);
    }
    if ($snowwater[$i] >= 0 && $snowwater[$i] <= 2000) { # Snow water (0.01 in)
      $snowwater{$key} = nint($snowwater[$i] / 0.254);
    }
    if ($snowwater24h[$i] >= 0 && $snowwater24h[$i] <= 1000) { # 24h h2o (0.01 in)
      $snowwater24h{$key} = nint($snowwater24h[$i] / 0.254);
    }
  }
}

# Fill snow data into obsSnow table.

# Prepare to populate.

$sql = qq{
  INSERT IGNORE INTO $snowtable (time, staname, depth, snowwater
                      ,snow24h, snowwater24h)
  VALUES (?,?,?,?,?,?)
};
$sth = $db->prepare($sql);

# Populate the table.

$db->begin_work();
$ct = 0;
foreach (sort keys(%stnid)) {
  if (defined($depth{$_}) || defined($snowwater{$_})
   || defined($snow24h{$_}) || defined($snowwater24h{$_})) {
    $sth->execute(
      $atime{$_},$stnid{$_},$depth{$_}
     ,$snowwater{$_}
     ,$snow24h{$_}
     ,$snowwater24h{$_}
    );
    ++$ct;
  }
}
print "No. of db snow stations: $ct\n";
$db->commit();

} # End snow data.

# Disconnect from the db.

$db->disconnect;

exit;

#===============================================================================
#
# &unix_to_time: Calculate month, day, year, hour, min, sec from unix time
# Arguments: unix time
# Returns: month, day, year, hour, min, sec
#

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

################################################################################

sub td2rh {

# Compute RH (%) from temp (K) and dew point (K).

   my ($t, $td) = @_;
   esat($td) / esat($t) * 100;
}
1;

################################################################################

sub esat {

# Compute saturation vapor pressure (mb) from temperature (K).

   my ($t) = @_;

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

################################################################################

sub rh2td {

# Compute dew point from temperature (K) and RH (percent).

  my ($t, $rh) = @_;
  my $rvolv = 0.0001846;  # rv/lv (461.5/2.5e6)

  my $rhp = $rh / 100;
  $rhp = 1 if ($rhp > 1);
  my $td = $t / ((-$rvolv * log($rhp) * $t) + 1);
  $td = $t if ($td > $t);
  $td;
}
1;
