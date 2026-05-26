#!/usr/bin/perl
use strict;
use DBI;

# Define directories.

my $root = "/home/caic/obs";
my $stntable = "$root/static/csv/wy-stations.csv";
my $remote = 1;

# Define zone codes.

my %zonecode;
$zonecode{"SierraMadre"} = 1;
$zonecode{"MedBow"} = 2;
$zonecode{"UpperPlatte"} = 3;

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

# Connect to the avalanche.org database.

#my $host = "db-proxy.avalanche.state.co.us";
#my $dbport = 3306;
#my $dbname = "caicobs";
#my $user = "caic";
#my $password = "sn0wst0rm";

my $host = "127.0.0.1";
my $dbport = 3306;
my $dbname = "weather";
my $user = "caic";
my $password = "steepndeep";

#my $db = DBI->connect("DBI:mysql:$dbname:$host:$dbport;mysql_ssl=1", $user, $password);
my $db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Fill station data into StnList table.
# Create table if it does not exist.

my $table = "WyStnList";
#my $table = "FACStnList";

my $sql = qq{drop table $table};
my $sth = $db->do($sql);

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
