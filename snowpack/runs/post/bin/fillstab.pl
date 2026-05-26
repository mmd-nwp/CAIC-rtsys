#!/usr/bin/perl
use strict;
use DBI;

my $spdir = "/ssd/snowpack/output/2024";

# Determine default time based on current time (server uses UTC).
# Round to latest 6-h increment, which is availability of data.

my $time = time;
$time -= $time%21600;

# Connect to the snowpack database.

my %attr = (RaiseError=>1,  # error handling enabled 
            AutoCommit=>0); # transaction enabled

my $host="127.0.0.1";
my $dbname = "weather";
my $user = "caic";
my $password = "steepndeep";
my $dbname = "snowpack";

print "Connecting to database: $dbname as user: $user\n";
my $db = DBI->connect("DBI:MariaDB:$dbname:$host", $user, $password);
die "Failed to connect to MySQL database:DBI->errstr()" unless($db);

# Read zones/station information.

my $table = "zones_2km";
my $query = "select id,zone,lat,lon,elev from $table order by id";

my $station_output = $db->prepare($query);
$station_output->execute;

print "Reading station table: $table\n";
my $nsta = $station_output->rows;
$nsta = 0 if ($nsta > 999999);
print "  There are $nsta entries in $table.\n\n";

my ($id,$zone,$lat,$lon,$elev,$ns,$stabfile
   ,@words,$data,$i,$dbtime
   ,$sk38ind,$sk38,$stabclassind,$stabclass,$stabind5ind,$stabind5,$ssiind,$ssi,$hn24ind,$hn24
   ,$query,$table_input);

my $table = "snowStab";
my $aspect = "F";

for ($ns=0; $ns<$nsta; $ns++) {
  ($id,$zone,$lat,$lon,$elev) = $station_output->fetchrow;
  next if ($elev < 2800);
  $zone = "0".$zone while(length($zone)<3);
  $id = "0".$id while(length($id)<6);
  $stabfile = "$spdir/zone$zone/$id/$id"."_res.smet";
  print "$stabfile\n";
  $data = 0;
  open(IN,$stabfile);
  while(<IN>) {
    @words = split;
    if ($words[0] eq "plot_description") {
      for ($i=0; $i<@words; $i++) {
        $sk38ind = $i-2 if ($words[$i] eq "Sk38_skier_stability_index");
        $stabclassind = $i-2 if ($words[$i] eq "stability_class");
        $ssiind = $i-2 if ($words[$i] eq "structural_stability_index");
        $stabind5ind = $i-2 if ($words[$i] eq "stability_index_5");
        $hn24ind = $i-2 if ($words[$i] eq "24h_height_of_new_snow");
      }
    }
    if ($words[0] eq "[DATA]") {
      $data = 1;
      next;
    }
    if ($data) {
      $dbtime = "$words[0]";
      $dbtime =~ s/T/ /;
      $sk38 = &nint($words[$sk38ind]*100);
      $sk38 = 9999 if ($sk38 < 0);
      $stabclass = &nint($words[$stabclassind]);
      $ssi = &nint($words[$ssiind]*1000);
      $ssi = 9999 if ($ssi < 0);
      $stabind5 = &nint($words[$stabind5ind]*1000);
      $stabind5 = 9999 if ($stabind5 < 0);
      $hn24 = &nint($words[$hn24ind]*3.93701);
      $query = "replace into $table set id='$id', time='$dbtime', aspect='$aspect', SK38=$sk38, stabClass=$stabclass, SSI=$ssi, stabIndex5=$stabind5, hn24 = $hn24";
#     print "$query\n";
      $table_input = $db->prepare($query);
      $table_input->execute;
      $table_input->finish;
    }
  }
  close(IN);
}

# Disconect from the db.

$station_output->finish;
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
