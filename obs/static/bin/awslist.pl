#!/usr/bin/perl
use strict;
use DBI;

# Define directories.

my $root = "/home/caic/obs";
my $stntable = "$root/static/csv/madis-stations.csv";
my $remote = 1;

# Define zone codes.

my %zonecode;
$zonecode{"Steamboat"} = 1;
$zonecode{"FrontRange"} = 2;
$zonecode{"Vail/Summit"} = 3;
$zonecode{"Sawatch"} = 4;
$zonecode{"Aspen"} = 5;
$zonecode{"Gunnison"} = 6;
$zonecode{"GrandMesa"} = 7;
$zonecode{"NSanJuan"} = 8;
$zonecode{"SSanJuan"} = 9;
$zonecode{"Sangre"} = 10;

# Read the station table.

my (@words,$stnid,%stnid,%provider,%zone,%lat,%lon,%elev,%stnname,%perm);
open(IN,"$stntable");
while(<IN>) {
  @words = split(",");
  $stnid = $words[0];
  $stnid{$stnid} = $stnid;
  $provider{$stnid} = $words[1];
  if (length $words[2]) {
    $zone{$stnid} = $zonecode{$words[2]};
  } else {
    $zone{$stnid} = 0;
  }
  $lat{$stnid} = $words[3];
  $lon{$stnid} = $words[4];
  $elev{$stnid} = $words[5];
  $stnname{$stnid} = $words[6];
  $perm{$stnid} = $words[7];  # Permissions - 0=public, 1=industry/CDOT, 2=CAIC
}
close(IN);

# Connect to the avalanche.org database.

my $host = "db-proxy.avalanche.state.co.us";
my $dbport = 3306;
my $dbname = "caicobs";
my $user = "caic";
my $password = "sn0wst0rm";

my $db1 = DBI->connect("DBI:mysql:$dbname:$host:$dbport;mysql_ssl=1", $user, $password);

# Fill station data into StnList table.
# Create table if it does not exist.

my $table = "StnList";

my $sql = qq{DROP TABLE $table};
my $str = $db1->do($sql) if ($remote);

print "Creating db table with name: $table\n\n";
$sql = qq{
           CREATE TABLE IF NOT EXISTS $table (
            stnid char(10) NOT NULL
           ,zone TINYINT UNSIGNED NOT NULL
           ,perm TINYINT UNSIGNED NOT NULL
           ,provider CHAR(10)
           ,lat FLOAT
           ,lon FLOAT
           ,elev SMALLINT UNSIGNED
           ,stnname CHAR(40)
           ,PRIMARY KEY (stnid, zone)
           ,INDEX indStd (stnid, zone)
         )
};
$str = $db1->do($sql) if ($remote);

# Prepare to populate.

$sql = qq{
  REPLACE INTO $table (stnid, zone, provider, lat, lon, elev, stnname)
  VALUES (?,?,?,?,?,?,?)
};
$str = $db1->prepare($sql) if ($remote);

# Populate the table.

foreach (sort keys(%stnid)) {
  if ($remote) {
    $str->execute(
      $stnid{$_},$zone{$_},$provider{$_},$lat{$_},$lon{$_},$elev{$_},$stnname{$_}
    );
  }
}

# Disconnect from the db.

$db1->disconnect;
exit;
