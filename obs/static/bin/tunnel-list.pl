#!/usr/bin/perl
use strict;
use DBI;

# Define directories.

my $root = "/home/caic/caic/rtsys/obs";
my $stntable = "$root/static/csv/tunnel-stations.csv";
my $remote = 0;

# Define zone codes.

my %zonecode;
$zonecode{"Loveland"} = 1;
$zonecode{"Berthoud"} = 2;
$zonecode{"I-70"} = 3;
$zonecode{"Cameron"} = 4;

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

# Connect to the weather database.

my $host = "127.0.0.1";
my $dbname = "weather";
my $user = "caic";
my $password = "steepndeep";

my ($db,$db1,$table,$sql,$sth,$str);

print "Connecting to database: $dbname as user: $user\n";
$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Connect to the avalanche.org database.

$host = "db-proxy.avalanche.state.co.us";
my $dbport = 3306;
$dbname = "caicobs";
$user = "caic";
$password = "sn0wst0rm";

if ($remote) {
  $db1 = DBI->connect("DBI:mysql:$dbname:$host:$dbport;mysql_ssl=1", $user, $password);
  $remote = 0 if (! $db1);
}

# Fill station data into StnList table.
# Create table if it does not exist.

$table = "tunnelStnList";

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
$sth = $db->do($sql);
$str = $db1->do($sql) if ($remote);

# Prepare to populate.

$sql = qq{
  REPLACE INTO $table (stnid, zone, perm, provider, lat, lon, elev, stnname)
  VALUES (?,?,?,?,?,?,?,?)
};
$sth = $db->prepare($sql);
$sql = qq{
  REPLACE INTO $table (stnid, zone, provider, lat, lon, elev, stnname)
  VALUES (?,?,?,?,?,?,?)
};
$str = $db1->prepare($sql) if ($remote);

# Populate the table.

foreach (sort keys(%stnid)) {
  $sth->execute(
    $stnid{$_},$zone{$_},$perm{$_},$provider{$_},$lat{$_},$lon{$_},$elev{$_},$stnname{$_}
  );
  if ($remote) {
    $str->execute(
      $stnid{$_},$zone{$_},$provider{$_},$lat{$_},$lon{$_},$elev{$_},$stnname{$_}
    );
  }
}

# Disconnect from the db.

$db->disconnect;
$db1->disconnect if ($remote);
exit;
