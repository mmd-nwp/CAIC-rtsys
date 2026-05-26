#!/usr/bin/perl
use strict;
use DBI;
use JSON;
use Getopt::Std;
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Command line options:
#  -r fill remote database (1 = yes, 0 = no, default = no)

use vars qw($opt_r);
getopt('r');

# Determine default time based on current time.

my $time = time;
my ($yyyy, $mm, $dd);
($dd, $mm, $yyyy) = (localtime($time))[3,4,5];
$yyyy += 1900;
++$mm;
$dd = "0$dd" while(length($dd) < 2);
$mm = "0$mm" while(length($mm) < 2);
my $dbtime = "$yyyy-$mm-$dd";

# Define directories.

my $root = "/home/caic/caic/rtsys/obs/provider/snocountry/data";

# Define db station names.

my %stid = ('Arapahoe Basin' => 'CSCAB'
           ,'Ashcroft Ski Touring' => 'CSCAS'
           ,'Aspen Highlands' => 'CSCAH'
           ,'Aspen Mountain' => 'CSCAM'
           ,'Aspen Snowmass Nordic Trail System' => 'CSCSN'
           ,'Beaver Creek' => 'VABCR'
           ,'Bluebird Backcountry' => 'CSCBB'
           ,'Breckenridge' => 'VABRK'
           ,'Buttermilk' => 'CSCBM'
           ,'Cooper/Chicago Ridge' => 'CSCSC'
           ,'Copper Mountain Resort' => 'CSCCM'
           ,'Crested Butte Mountain Resort' => 'CSCCB'
           ,'Crested Butte Nordic Center' => 'CSCCN'
           ,'Echo Mountain' => 'CSCEM'
           ,'Eldora Mountain Resort' => 'CSCEL'
           ,'Granby Ranch' => 'CSCGR'
           ,'Hesperus Ski Area' => 'CSCHE'
           ,'Howelsen Hill Ski Area' => 'CSCHO'
           ,'Irwin Catskiing by Eleven' => 'CSCIR'
           ,'Kendall Mountain' => 'CSCKM'
           ,'Keystone Resort' => 'VAKEY'
           ,'Loveland Ski Area' => 'CSCLV'
           ,'Monarch Mountain' => 'CSCMM'
           ,'Powderhorn Mountain Resort' => 'CSCPH'
           ,'Purgatory Resort' => 'CSCPD'
           ,'Silverton Mountain' => 'CSCSI'
           ,'Snow Mountain Ranch' => 'CSCSR'
           ,'Snowmass' => 'CSCSM'
           ,'Steamboat' => 'CSCSB'
           ,'Sunlight Mountain Resort' => 'CSCSL'
           ,'Telluride Ski Resort' => 'CSCTR'
           ,'Vail Mountain Resort' => 'VAVAI'
           ,'Vail Nordic Center' => 'CSCVN'
           ,'Winter Park Resort' => 'CSCWP'
           ,'Wolf Creek Ski Area' => 'CSCWC'
           );


# Read and parse the JSON file.

my $file = "$root/snowreport.json";
my $wxdata = do {
  open my $fh, '<', $file;
  local $/;
  decode_json(<$fh>);
};

my ($stid,$key,$update,$hh,$mn
   ,$obtime,$atime,%atime
   ,%hs,%hn24);
foreach my $stn (@{$wxdata->{items}}) {
  $obtime = substr($stn->{reportDateTime},0,10);
  next if ($obtime ne $dbtime);
  $stid = $stid{$stn->{resortName}};
  $hn24{$stid} = $stn->{newSnowMin};
  $hn24{$stid} = 0 if ($hn24{$stid} eq '');
  $hn24{$stid} *= 10;
  $hs{$stid} = $stn->{avgBaseDepthMin};
  if ($hs{$stid} eq '') {
    $hs{$stid} = 9999;
  } else {
    $hs{$stid} *= 10;
  }
# print "$stid $obtime $hn24{$stid} $hs{$stid}\n";
}

my ($db,$table,$sql,$sth,$sth1);

# Connect to the weather database.

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

print "Connecting to database: $dbname as user: $user\n";
$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Fill weather data into DailyWX table.

my $swe = 9999;

# Prepare to populate.

$sql = qq{
  REPLACE INTO $dailytable (date, staname, hn24, hs, swe)
  VALUES (?,?,?,?,?)
};
$sth = $db->prepare($sql);

# Populate the table.

foreach (sort keys(%hn24)) {
  $sth->execute(
    $dbtime,$_,$hn24{$_},$hs{$_},$swe
  );
}

# Disconnect from the db.

$db->disconnect;

exit;
