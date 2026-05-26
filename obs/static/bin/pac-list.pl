#!/usr/bin/perl
use strict;
use DBI;

# Define directories.

my $root = "/home/caic/obs";
my $stntable = "$root/static/csv/pac-stations.csv";

# Define zone codes.

my %zonecode;
$zonecode{"Payette AC"} = 1;

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
my $host = "caic-production.cluster-chr8k2bswsyh.us-west-2.rds.amazonaws.com";
my $dbport = 3306;
my $dbname = "caicobs";
my $user = "caic";
my $password = "sn0wst0rm";

#my $host = "127.0.0.1";
#my $dbport = 3306;
#my $dbname = "weather";
#my $user = "caic";
#my $password = "steepndeep";

my $db = DBI->connect("DBI:mysql:$dbname:$host:$dbport", $user, $password);
#my $db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Fill station data into StnList table.
# Create table if it does not exist.

my $table = "StnList_PAC";
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
