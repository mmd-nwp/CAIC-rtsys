#!/usr/bin/perl
use strict;
use DBI;

# Define directories.

my $root = "/home/caic/obs";
my $stntable = "$root/static/csv/sac-stations.csv";
my $remote = 1;

# Define zone codes.

my %zonecode;
$zonecode{"Sierra Crest North"} = 1;
$zonecode{"Sierra Crest South"} = 2;
$zonecode{"Carson Range"} = 3;

# Read the station table.

my (@words,$stnid,%stnid,%provider,%zone,%lat,%lon,%elev,%stnname);
open(IN,"$stntable");
while(<IN>) {
  @words = split(",");
  $stnid = $words[0];
  $stnid{$stnid} = $stnid;
  $provider{$stnid} = $words[1];
  $zone{$stnid} = $zonecode{$words[2]};
  $lat{$stnid} = $words[3];
  $lon{$stnid} = $words[4];
  $elev{$stnid} = $words[5];
  $stnname{$stnid} = $words[6];
}
close(IN);

# Connect to the weather database.

my $host = "127.0.0.1";
my $dbname = "weather";
my $user = "caic";
my $password = "steepndeep";

my ($db,$table,$sql,$sth);

print "Connecting to database: $dbname as user: $user\n";
$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Connect to the avalanche.org database.

$host = "db-proxy.avalanche.state.co.us";
my $dbport = 3306;
$dbname = "caicobs";
$user = "caic";
$password = "sn0wst0rm";

$db = DBI->connect("DBI:mysql:$dbname:$host:$dbport;mysql_ssl=1", $user, $password);

# Fill station data into StnList table.
# Create table if it does not exist.

$table = "StnList_SAC";

$sql = qq{drop table $table};
$sth = $db->do($sql);

print "Creating db table with name: $table\n\n";
$sql = qq{
           CREATE TABLE IF NOT EXISTS $table (
            stnid char(10) NOT NULL
           ,zone TINYINT UNSIGNED NOT NULL
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

# Prepare to populate.

$sql = qq{
  REPLACE INTO $table (stnid, zone, provider, lat, lon, elev, stnname)
  VALUES (?,?,?,?,?,?,?)
};
$sth = $db->prepare($sql);

# Populate the table.

foreach (sort keys(%stnid)) {
  $sth->execute(
    $stnid{$_},$zone{$_},$provider{$_},$lat{$_},$lon{$_},$elev{$_},$stnname{$_}
  );
}

# Disconnect from the db.

$db->disconnect;

exit;
