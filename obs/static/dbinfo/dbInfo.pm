package dbInfo;
  
sub dbInfo {

  my $host="127.0.0.1";
  my $dbname = "weather";
  my $user = "caic";
  my $password = "steepndeep";

  ($host,$dbname,$user,$password);

}
1;

#===============================================================================

sub dbTables {

  my $wxtable = "obsWX";
  my $hydrotable = "obsHydro";
  my $snowtable = "obsSnow";
  my $solartable = "obsSolar";
  my $batterytable = "obsBattery";
  my $dailytable = "dailyWX";

  ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable);

}
1;

#===============================================================================

sub madisDir {

  my $madisdir = "/data/noaaport/madis";

  ($madisdir);
}
1;
