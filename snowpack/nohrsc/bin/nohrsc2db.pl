#!/usr/bin/perl
use strict;
use NetCDF;
use DBI;
use Getopt::Std;
use List::Util qw(max);
require "/home/caic/caic/rtsys/snowpack/nohrsc/lib/map_utils.pm";

# Code to read NOHRSC HS data, interpolate to WRF zone locations,
#    and store into MySQL database.
# Saved variables are:
#    HS (hs) in tenths in

# Command line options:
#    -r WRF resolution (default = 2km)
#    -d date (UTC yymmdd, default=current)

use vars qw($opt_r $opt_d);
getopt('rd');

# Define directories.

my $hsdir = "/data/noaaport/grids/nohrsc/netcdf";

# Determine default times based on current time.

my $time = time;
my ($yyyy, $yy, $mm, $dd, $hh);
if (defined ($opt_d)) {
   $yy = substr($opt_d,0,2);
   $mm = substr($opt_d,2,2);
   $dd = substr($opt_d,4,2);
   $yyyy = 2000 + $yy;
} else {
   ($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
   $mm = "0".$mm while(length($mm)<2);
   $dd = "0".$dd while(length($dd)<2);
}
$hh = "12";

my $res = "2km";
$res = $opt_r if ($opt_r);

# Read the NOHRSC HS netcdf file.

my ($nid,$ncid,$var,$nx,$ny);

#my $time = "2022-11-21 12:00";
my $time = "$yyyy-$mm-$dd $hh:00";
my $cdffile = "$hsdir/$yyyy$mm$dd.nc";
print "HS <== $cdffile\n";
$ncid=NetCDF::open("$cdffile",NetCDF::NOWRITE);

$var = "lon";
$nid=NetCDF::dimid($ncid, $var);
NetCDF::diminq($ncid, $nid, $var, $nx);
$var = "lat";
$nid=NetCDF::dimid($ncid, $var);
NetCDF::diminq($ncid, $nid, $var, $ny);

# Read lat, lon fields.

my (@start,@count,@lat,@lon,@hs);

@start = (0);
@count = ($nx);
$nid=NetCDF::varid($ncid,"lon");
NetCDF::varget($ncid,$nid,[@start],[@count],\@lon);

@start = (0);
@count = ($ny);
$nid=NetCDF::varid($ncid,"lat");
NetCDF::varget($ncid,$nid,[@start],[@count],\@lat);

# Setup grid projection.

my $dx = ($lon[$nx-1] - $lon[0]) / ($nx - 1);
my $dy = ($lat[$ny-1] - $lat[0]) / ($ny - 1);

my %proj = &map_utils::map_set("LL",$lat[0],$lon[0],1.0,1.0,0,$dx,$dy,0,$nx,$ny);

# Read gridded data.

@start = (0,0);
@count = ($ny,$nx);

$nid=NetCDF::varid($ncid,"Band1");
NetCDF::varget($ncid,$nid,[@start],[@count],\@hs);
my $n;
for ($n=0; $n<$nx*$ny; $n++) {
  $hs[$n] = 0 if ($hs[$n] < 0);
}

NetCDF::close($ncid);

# Specify database name and user.

my $host = "127.0.0.1";
my $dbName = "snowpack";
my $userName = "caic";
my $password = "steepndeep";

# Connect to the snowpack database.

print "Connecting to database: $dbName as user: $userName\n";
my $db = DBI->connect("DBI:MariaDB:$dbName:$host", $userName, $password,{AutoCommit => 0});

# Read WRF point locations from db.

my $table = "zones_$res";
my $query = "select id, lat, lon from $table";
$query .= " where (mod(id, 2) = 0 and mod(floor(id/231), 2) = 0 and zone=1) or zone=2" if ($res eq "bsu");

my $table_output = $db->prepare($query);
$table_output->execute;

my $nrows = $table_output->rows;
$nrows = 0 if ($nrows > 999999);
print "There are $nrows entries in $table.\n";

my $sql = qq{replace into snowAnal
         (time, ptId, wrfRes, analType, snowDepth, snowDepthmax, snowDepthmax1)
          values (?, ?, ?, ?, ?, ?, ?)};

my ($ptid,$ptlat,$ptlon,$i,$j,$hs,$hsmax,$hsmax1,$sth,$ct,@numbers);
for ($n=0; $n<$nrows; $n++) {
  ($ptid, $ptlat, $ptlon) = $table_output->fetchrow;

# Interpolate HS data to grid point locations.

  ($i,$j) = &map_utils::latlon_to_ij($ptlat,$ptlon,%proj);
  --$i;
  --$j;
  $hs = &nint(&gdtost(\@hs,$nx,$ny,$i,$j)/2.54);  # Inches * 10
  $hs = 0 if ($hs < 0);
  
  $ct = &nint($i) + (&nint($j)*$nx);
  $ct -= $nx;
  @numbers = (@hs[$ct        -1],@hs[$ct        ],@hs[$ct        +1],@hs[$ct        +2]
             ,@hs[$ct+   $nx -1],@hs[$ct+   $nx ],@hs[$ct+$nx    +1],@hs[$ct+   $nx +2]
             ,@hs[$ct+(2*$nx)-1],@hs[$ct+(2*$nx)],@hs[$ct+(2*$nx)+1],@hs[$ct+(2*$nx)+2]
             ,@hs[$ct+(3*$nx)-1],@hs[$ct+(3*$nx)],@hs[$ct+(3*$nx)+1],@hs[$ct+(3*$nx)+2]
  );
  $hsmax = max @numbers;
  $hsmax = &nint($hsmax/2.54);

  $ct = &nint($i) + (&nint($j)*$nx);
  @numbers = (@hs[$ct],@hs[$ct+1],@hs[$ct+$nx],@hs[$ct+$nx+1]);
  $hsmax1 = max @numbers;
  $hsmax1 = &nint($hsmax1/2.54);

# print "$ptlat $ptlon $hs\n";
  $sth = $db->prepare($sql);
  $sth->execute("$time", $ptid, "$res", "nohrsc", $hs, $hsmax, $hsmax1);
}
print "Start db commit\n";
$db->commit(); 
$table_output->finish;
print "Finish db commit\n";

# Disconect from the db.

$db->disconnect;

exit;

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
}1;

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

#===============================================================================

sub jjj2mmdd {
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

# &gdtost:  Return stations back-interpolated values ($staval)
#    from uniform grid points using overlapping-quadratics.
# Gridded values of input array are dimensioned $a[nx*ny], where
#    $nx=grid points in x, $ny = grid points in y.
# Station location given in terms of grid relative station x ($stax)
#    and station column ($stay).

sub gdtost {

   my ($a, $nx, $ny, $stax, $stay) = @_;

   my $iy1 = int($stay) - 1;
   my $iy2 = $iy1 + 3;
   my $ix1 = int($stax) - 1;
   my $ix2 = $ix1 + 3;
   my $staval = undef;
   my $fiym2 = $iy1 - 1;
   my $fixm2 = $ix1 - 1;
   my $ii = 0;
   my ($i,$j,$jj,$xx,$yy,@r,@scr,$ct);
   for ($i=$ix1; $i<=$ix2; $i++) {
      ++$ii;
      if ($i >= 0 && $i <= $nx-1) {
         $jj = 0;
         for ($j=$iy1; $j<=$iy2; $j++) {
            ++$jj;
            if ($j >= 0 && $j <= $ny-1) {
#              $ct = $j + ($i*$ny);
               $ct = $i + ($j*$nx);
               $r[$jj] = $$a[$ct];
            }
            else {
               $r[$jj] = undef;
            }
         }
         $yy = $stay - $fiym2;
         if ($yy == 2) {
            $scr[$ii] = $r[2];
         }
         else {
            $scr[$ii] = &binom(1,2,3,4,$r[1],$r[2],$r[3],$r[4],$yy);
         }
      }
      else {
         $scr[$ii] = undef;
      }
   }
   $xx = $stax - $fixm2;
   if ($xx == 2) {
      $staval = $scr[2];
   }
   else {
      $staval = &binom(1,2,3,4,$scr[1],$scr[2],$scr[3],$scr[4],$xx);
   }
 
   return $staval;
}1;

#===============================================================================

sub binom {

   my($x1, $x2, $x3, $x4, $y1, $y2, $y3, $y4, $xxx) = @_;

   my $yyy = undef;

   return $yyy if ($x2 eq undef || $x3 eq undef || $y2 eq undef || $y3 eq undef);

   my $wt1 = ($xxx-$x3) / ($x2-$x3);
   my $wt2 = 1 - $wt1;

   my ($yz11,$yz12,$yz13,$yz22,$yz23,$yz24);

   if ($x4 ne undef && $y4 ne undef) {
      $yz22 = $wt1 * ($xxx-$x4) / ($x2-$x4);
      $yz23 = $wt2 * ($xxx-$x4) / ($x3-$x4);
      $yz24 = ($xxx-$x2) * ($xxx-$x3) / (($x4-$x2) * ($x4-$x3));
   }
   else {
      $yz22 = $wt1;
      $yz23 = $wt2;
      $yz24 = 0;
   }

   if ($x1 ne undef && $y1 ne undef) {
      $yz11 = ($xxx-$x2) * ($xxx-$x3) / (($x1-$x2) * ($x1-$x3));
      $yz12 = $wt1 * ($xxx-$x1) / ($x2-$x1);
      $yz13 = $wt2 * ($xxx-$x1) / ($x3-$x1);
   }
   else {
      $yz11 = 0;
      $yz12 = $wt1;
      $yz13 = $wt2;
   }

   if ($yz11 == 0 && $yz24 == 0) {
      $yyy = ($wt1*$y2) + ($wt2*$y3);
   }
   else {
      $yyy = $wt1 * ($yz11*$y1 + $yz12*$y2 + $yz13*$y3)
           + $wt2 * ($yz22*$y2 + $yz23*$y3 + $yz24*$y4);
   }

   return $yyy;
}1; 

#===============================================================================

sub nint { my ($z) = @_; return ($z>0)? int($z+0.5) : int($z-0.5); }
