#!/usr/bin/perl
use strict;
use DBI;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

my ($db,$query,$sth
   ,$stid,$date,$tp,$td,$rh,$spd,$dir,$gust);

open(IN,"/home/caic/caic/rtsys/obs/provider/keystone/data/pws.txt");
my $input = do {local $/; <IN> };
close(IN);

$date = substr($input,0,16);
my @words = split(' ',$input);
$tp = $words[2];
$td = $words[3];
$rh = $words[4];
$spd = $words[5];
$dir = $words[6];
$gust = $words[7];

# Connect to the weather database.

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

my $stid = "CAKEY";
$query = "insert ignore into $wxtable set staname='$stid', time='$date'";
$query = "$query".", temp=$tp";
$query = "$query".", dewp=$td";
$query = "$query".", rh=$rh";
$query = "$query".", wspd=$spd";
$query = "$query".", wdir=$dir";
$query = "$query".", gust=$gust";

$sth = $db->prepare($query);
$sth->execute;
$sth->finish;

$db->disconnect;

exit;
