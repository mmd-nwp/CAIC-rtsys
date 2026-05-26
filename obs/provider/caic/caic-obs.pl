#!/usr/bin/perl
use strict;
use DBI;
use Getopt::Std;
use List::Util qw[min max];
use DateTime;
use Scalar::Util qw(looks_like_number);
use lib "/home/caic/caic/rtsys/obs/static/dbinfo";
use dbInfo;

# Setup command line options:
#  -d end date (YYMMDDHH (UTC), default = current)
#  -h end hour (UTC, default = current)
#  -o specify a single station 
#  -r replace existing data (0 = no, 1 = yes, default = 0)
#  -s span (hours, 0 = all, default = 24)

use vars qw($opt_d $opt_h $opt_o $opt_r $opt_s);
getopt('dhors');

my $wxstn = "";
$wxstn = $opt_o if (defined($opt_o));

my $replace = 0;
$replace = $opt_r if (defined($opt_r));
my $insert = "insert ignore";
$insert = "replace" if ($replace);

my $span = 24;
$span = $opt_s if (defined($opt_s));
my $tail = ($span+1)*12;
$span *= 3600;

my $data = "/home/caic/caic/rtsys/obs/data";
my $work = "/home/caic/caic/rtsys/obs/work";

my %stinfo = (
  ABASINMID   => [ qw( CAABM MST a-basin/a-basin_abvl/1-hour.dat                                            )],
  ABASINPALI  => [ qw( CAABP MST a-basin/a-basin_abp/1-hour.dat                                             )],
  ABASINTOP   => [ qw( CAABT MST a-basin/a-basin_abw/1-hour.dat                                             )],
  ABRAHMS     => [ qw( CAABR UTC caic/abrams/1-hour.dat                                                     )],
  AJAXBELL    => [ qw( CAAXB CST aspen_ski_co/aspen_mountain_sa/aspen_mountain_sa_bell/1-hour.dat           )],
  AJAXEAST    => [ qw( CAAXE MDT aspen_ski_co/aspen_mountain_sa/aspen_mountain_sa_fareast_wind/1-hour.dat   )],
  AJAXHEROS   => [ qw( CAAXH MDT aspen_ski_co/aspen_mountain_sa/aspen_mountain_sa_heros/1-hour.dat          )],
  AJAXMID     => [ qw( CAAXM MDT aspen_ski_co/aspen_mountain_sa/aspen_mountain_sa_midway/1-hour.dat         )],
  AJAXTOP     => [ qw( CAAXT MDT aspen_ski_co/aspen_mountain_sa/aspen_mountain_sa_top/1-hour.dat            )],
  AJAXTOPW    => [ qw( CAAXW MDT aspen_ski_co/aspen_mountain_sa/aspen_mountain_sa_top_wind/1-hour.dat       )],
  BERTHOUDPAS => [ qw( CABTP CST caic/berthoud_pass/1-hour.dat                                              )],
  BLUEGULCH   => [ qw( CABLG MST cdot/gwc_blue_gulch/5-minute.dat                                           )],
  BOTTLEPEAK  => [ qw( CABPK MST rocky_mountain_research_station/bottle_peak/10-minute.dat                  )],
  BRECKHSB    => [ qw( CAHSB MDT breckenridge_sa/breck_horseshoe_bowl/1-hour.dat                            )],
  BRECKPEAK6  => [ qw( CABP6 MDT breckenridge_sa/breck_peak_6/1-hour.dat                                    )],
  BRECKPEAK8  => [ qw( CABP8 MDT breckenridge_sa/breck_peak_8/1-hour.dat                                    )],
  CAMERONPASS => [ qw( CACMP MST caic/cameron_pass/10-minute.dat                                            )],
  CMCRIDGE    => [ qw( CACMR MST cmc/cmc_ridge/1-hour.dat                                                   )],
  CMCSTUDY    => [ qw( CACMS MST cmc/cmc_base/1-hour.dat                                                    )],
  CINNAMON    => [ qw( CACIN MST cdot/gwc_cinnamon/5-minute.dat                                             )],
  CINNAMONMTN => [ qw( CACNM MST rocky_mountain_biological_lab/15-minute.dat                                )],
  CEDAREDGEWP => [ qw( CAMR1 MST cloud_seeder/milk_creek/15-minute.dat                                      )],
  COALBNKPASS => [ qw( CACBP UTC caic/coalbank_pass/1-hour.dat                                              )],
  CRESTEDBTE1 => [ qw( CACB1 MST crested_butte_mountain_resort/15-minute.dat                                )],
  DOUGLASPASS => [ qw( CADGP MST caic/douglas_pass/1-hour.dat                                               )],
  DYNAMO      => [ qw( CADYN MDT telluride_ski_area/telluride_ski_area_dynamo/1-hour.dat                    )],
  EAGLE       => [ qw( CAEGE UTC caic/eagle/1-hour.dat                                                      )],
  ELKTON      => [ qw( CAELT MST cbac/elkton/1-hour.dat                                                     )],
  FOOLCREEK   => [ qw( CAFLC MST rocky_mountain_research_station/fool_creek/10-minute.dat                   )],
  GOLDHILL    => [ qw( CAGDH MDT telluride_ski_area/telluride_ski_area_gold_hill/1-hour.dat                 )],
  GRANDMESA   => [ qw( CAGMS MST jpl/grand_mesa_skyway_point/1-hour.dat                                     )],
  GMLODGE     => [ qw( CALPG MST cloud_seeder/grand_mesa_lodge/1-hour.dat                                   )],
  HLANDSCLD9  => [ qw( CACL9 MDT aspen_ski_co/aspen_highlands_sa/aspen_highlands_sa_Cloud9/1-hour.dat       )],
  HLANDSLOGE  => [ qw( CALOG MDT aspen_ski_co/aspen_highlands_sa/aspen_highlands_sa_loge/1-hour.dat         )],
  HLANDSNWOOD => [ qw( CANWD MDT aspen_ski_co/aspen_highlands_sa/aspen_highlands_sa_northwood/1-hour.dat    )],
  HLANDSPEAK  => [ qw( CAHPK MDT aspen_ski_co/aspen_highlands_sa/aspen_highlands_sa_peak/1-hour.dat         )],
  IRWIN       => [ qw( CAIRW CST cs_irwin/irwin_study_plot/1-hour.dat                                       )],
  KENDALL     => [ qw( CAKDL UTC caic/kendall/1-hour.dat                                                    )],
  KEYSTONESS  => [ qw( CAKSS MDT keystone_sa/snow_study/1-hour.dat                                          )],
  KEYSTONEWAP => [ qw( CAKWP MDT keystone_sa/wapiti/1-hour.dat                                              )],
  KEYSTONEWS  => [ qw( CAKWS MDT keystone_sa/wind_study/1-hour.dat                                          )],
  LEWISCREEK  => [ qw( CALCK MST caic/lewis_creek/1-hour.dat                                                )],
  LOVELANDPAS => [ qw( CALVP CST caic/loveland/1-hour.dat                                                   )],
  MOLASPASS   => [ qw( CAMLP CST caic/molas_pass/molas_pass.dat                                             )],
  MONARCHPASS => [ qw( CAMNP MST monarch_sa/1-hour.dat                                                      )],
  MONUMENT    => [ qw( CAMON MST caic/monument/1-hour.dat                                                   )],
  PBASIN      => [ qw( CAPBA MDT telluride_ski_area/telluride_ski_area_pbasin/1-hour.dat                    )],
  PUTNEY      => [ qw( CAPTY MST csas/csas_putney/1-hour.dat                                                )],
  RICO        => [ qw( CARIC MST caic/rico/1-hour.dat                                                       )],
  SCARP       => [ qw( CASCP CST cs_irwin/irwin_scarp_ridge/1-hour.dat                                      )],
  SENBECK     => [ qw( CASBK MST csas/csas_senator_beck/1-hour.dat                                          )],
  SNOMASSBLD  => [ qw( CABLD MDT aspen_ski_co/aspen_snowmass_sa/aspen_snowmass_sa_baldy/1-hour.dat          )],
  SNOMASSBRN  => [ qw( CABRN MDT aspen_ski_co/aspen_snowmass_sa/aspen_snowmass_sa_burn/1-hour.dat           )],
  SNOMASSTLS  => [ qw( CATLS MDT aspen_ski_co/aspen_snowmass_sa/aspen_snowmass_sa_timberline/1-hour.dat     )],
  SNOMASSALT  => [ qw( CAALT MDT aspen_ski_co/aspen_snowmass_sa/aspen_snowmass_sa_mid/1-hour.dat            )],
  SNOMASSELK  => [ qw( CAELK MDT aspen_ski_co/aspen_snowmass_sa/aspen_snowmass_sa_elk/1-hour.dat            )],
  SNOMASSSMB  => [ qw( CASMB MDT bou_wx/smb.dat                                                             )],
  SNOMASSALP  => [ qw( CAALP MDT aspen_ski_co/aspen_snowmass_sa/aspen_snowmass_sa_alpine/1-hour.dat         )],
  STEAMBOAT   => [ qw( CA42R UTC caic/steamboat_lake/1-hour.dat                                             )],
  SWAMPANGEL  => [ qw( CASWP MST csas/csas_swamp_angle/1-hour.dat                                           )],
  TELLURIDE   => [ qw( CATEL MDT telluride_ski_area/telluride_ski_area_phq/1-hour.dat                       )],
  VAILBLUESKY => [ qw( CAVBS MDT vail_sa/blue_sky/1-hour.dat                                                )],
  VAILCHINABL => [ qw( CAVCB MDT vail_sa/china_bowl/1-hour.dat                                              )],
  VAILMIDMTN  => [ qw( CAVMM MDT vail_sa/mid_mountain/1-hour.dat                                            )],
  VAILPHQ     => [ qw( CAVPQ MDT vail_sa/phq/1-hour.dat                                                     )],
  VAILPASS    => [ qw( CAVLP UTC caic/vail_pass/1-hour.dat                                                  )],
  WHITEWATER  => [ qw( CAWWC CST cloud_seeder/whitewater/15-minute.dat                                      )],
  WOLFCREEKPS => [ qw( CAWCP MST caic/wolf_creek_ski_area/wolf_creek_ski_area.dat                           )],
);

# Determine default time based on current time (server uses UTC).

my $time = time;
$time -= $time%3600;

# Override default times based on command line options, if present.

my ($yyyy, $yy, $mm, $dd, $jjj, $hh, $mn, $dt);
if (defined $opt_d) {
  $_ = $opt_d;
  if (/^(\d\d)(\d\d)(\d\d)(\d\d)$/) {
    $yy = $1;
    $mm = $2;
    $dd = $3;
    $hh = $4;
    $yyyy = $yy + 2000;
  } else {
    print "Invalid date format - YYMMDDHH\n";
    exit;
  }
  $time = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
} elsif (defined $opt_h) {
  ($yyyy, $mm, $dd) = &unix_to_time($time);
  $hh = $opt_h;
  $time = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
}

# Define local time from Greenwich time.

($yyyy, $mm, $dd, $hh) = &unix_to_time($time);
my $timezone = 'UTC'; 
eval{
  $dt = DateTime->new(
    year => $yyyy,
    month => $mm,
    day => $dd,
    hour => $hh,
    time_zone => $timezone, 
  );
};

$dt->set_time_zone('America/Denver');
$yyyy = $dt->year;
$mm = $dt->month;
$dd = $dt->day;
$hh = $dt->hour;
print "$yyyy-$mm-$dd $hh\n";
my $ltime = &time_to_unix($mm,$dd,$yyyy,$hh,0,0);
$jjj = &julian($yyyy, $mm, $dd);

# Loop through each station and parse data for designated times.

my ($stn,%stn,$name,$check,$date,$obtime,$dbtime,$key,$n,$stid,$sttz,$file,@words,$inc
   ,%tp,$tpk,%tpmx,%tpmn,%td,%rh,%spd,%dir,%gust,%mslp
   ,%pcp,%pcp1m,%pcp5m,%pcp24,%pcpac,%spr,%snto,%volt,%sn24,%swe,%swe24,%swi,%swo,%lwi,%lwo,%net);

foreach $stn (sort keys %stinfo) {
  $stid = $stinfo{$stn}[0];
  next if ($wxstn ne "" && $wxstn ne $stid);
  $sttz = $stinfo{$stn}[1];
  $name = $stinfo{$stn}[2];
  $file = "$data/$name";
  print "$file $stn\n";
  next if (! -e $file);
  system("/usr/bin/tail -n $tail $file > $work/$stid");
  $file = "$work/$stid";
  open(IN,$file);
  while (<IN>) {
    @words = split(',');
    $check = $words[0];

# Check for timestamp validity.

    if (looks_like_number($check)) {
      $yy  = $words[1];
      if (looks_like_number($yy)) {
        next if ($yy < 1990 || $yy > 2100);
        $jjj = $words[2];
        next if ($jjj < 1 || $jjj > 366);
        ($mm, $dd) = &JJJ2MMDD($jjj,$yy);
        $hh  = int($words[3]/100);
        $mn  = $words[3] % 100;
        $inc = $words[0];
      } else {
        next;
      }
    } else {
      $yy  = substr($words[0],1,4);
      if (looks_like_number($yy)) {
        next if ($yy < 1990 || $yy > 2100);
        $mm = substr($words[0],6,2);
        $dd = substr($words[0],9,2);
        $hh = substr($words[0],12,2);
        $mn = substr($words[0],15,2);
      } else {
        next;
      }
    }

# Account for station timezone.

    if ($sttz eq "MST") {
        $timezone = 'America/Phoenix';      # Data is always MST
    } elsif ($sttz eq "MDT") {
        $timezone = 'America/Denver';       # Data is local mountain time
    } elsif ($sttz eq "CST") {
        $timezone = 'America/Mexico_City';  # Data is always MDT (CST)
    } elsif ($sttz eq "UTC") {
        $timezone = 'UTC';                  # Data Greenwich time
    }
    eval{
      $dt = DateTime->new(
        year => $yy,
        month => $mm,
        day => $dd,
        hour => $hh,
        minute => $mn,
        time_zone => $timezone,  
      );
    }; next if $@;
    $dt->set_time_zone('UTC');
    $dbtime = sprintf("%04d-%02d-%02d %02d:%02d",$dt->year,$dt->month,$dt->day,$dt->hour,$dt->minute);
    if ($span) {
      $obtime = &time_to_unix($dt->month,$dt->day,$dt->year,$dt->hour,$dt->minute,0);
      next if ($time-$obtime >= $span);
      next if ($time-$obtime <= -3600);
    }

# Loveland Pass.

    if ($stid eq "CALVP" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $volt{$key} = $words[21];
      $tp{$key}   = $words[23];
      $rh{$key}   = $words[24];
#     $mslp{$key} = $words[28] * 33.8639;  # Convert from inHg to mb
      $spd{$key}  = $words[25];
      $dir{$key}  = $words[26];
      $gust{$key} = $words[28];
      $pcp{$key}  = $words[35];

# Vail Pass.

    } elsif ($stid eq "CAVLP") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[6];
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[9];
      $dir{$key}  = $words[10];
      $gust{$key} = $words[8];
      $snto{$key} = $words[11];
      $volt{$key} = $words[5];

# Berthoud Pass.

    } elsif ($stid eq "CABTP" && $inc == 101) { 
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $volt{$key} = $words[5];
      $tp{$key}   = $words[7];
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[9];
      $gust{$key} = $words[10];
      $dir{$key}  = $words[12];
      $pcp{$key}  = $words[14];

# Eagle and Abrams.

    } elsif ($stid eq "CAEGE" || $stid eq "CAABR") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[4] * 1.8) + 32;
#     $rh{$key}   = $words[9];
      $spd{$key}  = $words[9] * 2.2369;   # Convert from m/s to mph
      $dir{$key}  = $words[11];
      $gust{$key} = $words[16] * 2.2369;   # Convert from m/s to mph
      $volt{$key} = $words[2];

# Kendall.

    } elsif ($stid eq "CAKDL") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[7] * 1.8) + 32;
      $rh{$key}   = $words[12];
      $spd{$key}  = $words[14] * 2.2369;   # Convert from m/s to mph
      $dir{$key}  = $words[16];
      $gust{$key} = $words[21] * 2.2369;   # Convert from m/s to mph
      $volt{$key} = $words[2];

# Molas Pass and Wolf Creek Pass.

    } elsif (($stid eq "CAMLP" || $stid eq "CAWCP"
             ) && $inc == 60) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[4];
      $rh{$key}   = $words[5];
      $spd{$key}  = $words[6];
      $dir{$key}  = $words[7];
      $gust{$key} = $words[8];
      if ($stid eq "CAMLP") {
        $snto{$key} = $words[9];
        $volt{$key} = $words[10];
      } else {
        $volt{$key} = $words[9];
      }

# Monument.

    } elsif ($stid eq "CAMON") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[5];
      $rh{$key}   = $words[6];
      $pcp{$key}  = $words[9];
      $pcpac{$key}= $words[10];
      $snto{$key} = $words[12];
      $sn24{$key} = $words[14];
      $volt{$key} = $words[7];

# Coal Bank Pass.

    } elsif ($stid eq "CACBP" && $inc eq 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[6];
      $rh{$key}   = $words[7];
      $gust{$key} = $words[8];
      $spd{$key}  = $words[9];
      $dir{$key}  = $words[10];
      $snto{$key} = $words[11];
      $pcp{$key}  = $words[13];
#     $pcpac{$key}= $words[12];
      $volt{$key} = $words[5];

# Steamboat Lake

    } elsif ($stid eq "CA42R" && $inc eq 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[5];
      $rh{$key}   = $words[6];
      $spd{$key}  = $words[7];
      $dir{$key}  = $words[8];
      $gust{$key} = $words[9];
      $snto{$key} = $words[10];
      $volt{$key} = $words[11];

# Crested Butte.

    } elsif ($stid eq "CACB1" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $spd{$key}  = $words[5] * 2.2369;    # Convert from m/s to mph
      $dir{$key}  = $words[6];
      $gust{$key} = $words[8] * 2.2369;    # Convert from m/s to mph
      $tp{$key}   = ($words[9] * 1.8) + 32; # Convert from C to F
      $swi{$key}  = $words[10];

# Grand Mesa.

    } elsif ($stid eq "CAGMS") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[7] * 1.8) + 32;
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[10] * 2.2369;   # Convert from m/s to mph
      $dir{$key}  = $words[12];
      $gust{$key} = $words[9] * 2.2369;    # Convert from m/s to mph
      $snto{$key} = $words[19] * 39.3701;  # Convert from m to inches
      $lwi{$key}  = $words[18];
      $swo{$key}  = $words[14];
      $swi{$key}  = $words[16];
      $volt{$key} = $words[20];

# Irwin (Study Plot and Scarp Ridge).

    } elsif ($stid eq "CAIRW" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[8];
      $rh{$key}   = $words[9];
      $spd{$key}  = $words[6];
      $dir{$key}  = $words[7];
      $gust{$key} = $words[5];
#     $pcp{$key}  = $words[19];
#     $pcpac{$key}= $words[13];
      $sn24{$key} = $words[17];
      $snto{$key} = $words[12];
      $volt{$key} = $words[10];

    } elsif ($stid eq "CASCP" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[6];
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[9];
      $dir{$key}  = $words[10];
      $gust{$key} = $words[8];

# Putney.
#  Temp data is provided as min and max from the previous hour.
#   Select the temp that is closest in time to the current hour.

    } elsif ($stid eq "CAPTY") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[6]+$words[7])/2;
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[12];
      $dir{$key}  = $words[14];
      $gust{$key} = $words[9];

# Rico.

    } elsif ($stid eq "CARIC" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[19];
      $rh{$key}   = $words[20];
      $spd{$key}  = $words[24];
      $dir{$key}  = $words[25];
      $gust{$key} = $words[27];
      $pcp{$key}  = $words[22];
      $pcpac{$key}= $words[29];
      $sn24{$key} = $words[28];
      $snto{$key} = $words[21];
      $volt{$key} = $words[17];

# Telluride (PHQ, Dynamo, Gold Hill, PBasin).

    } elsif ($stid eq "CATEL" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[16];
      $rh{$key}   = $words[9];
      $spd{$key}  = $words[10];
      $dir{$key}  = $words[11];
      $gust{$key} = $words[13];
      $sn24{$key} = $words[15];
      $snto{$key} = $words[14];

    } elsif ($stid eq "CADYN" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[8];
      $rh{$key}   = $words[5];
      $spd{$key}  = $words[9];
      $dir{$key}  = $words[10];
      $gust{$key} = $words[12];

    } elsif ($stid eq "CAGDH" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $rh{$key}   = $words[5];
      $tp{$key}   = $words[8];
      $spd{$key}  = $words[9];
      $dir{$key}  = $words[10];
      $gust{$key} = $words[12];

    } elsif ($stid eq "CAPBA" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[11];
      $rh{$key}   = $words[12];
      $sn24{$key} = $words[14];
      $snto{$key} = $words[15];

# Cameron Pass.

    } elsif ($stid eq "CACMP" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[6] * 1.8) + 32;
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[15];  # Upper sensor
      $dir{$key}  = $words[17];  # Upper sensor
      $gust{$key} = $words[16];  # Upper sensor
      $snto{$key} = $words[20];
      $swo{$key}  = $words[21];
      $swi{$key}  = $words[22];
      $lwo{$key}  = $words[23];
      $lwi{$key}  = $words[24];
      $net{$key}  = $words[25];
      $volt{$key} = $words[5];

# Bottle Peak.

    } elsif ($stid eq "CABPK" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[7] * 1.8) + 32;
      $rh{$key}   = $words[10];
      $spd{$key}  = $words[22] * 2.2369;   # Convert from m/s to mph
      $dir{$key}  = $words[28];
      $gust{$key} = $words[23] * 2.2369;   # Convert from m/s to mph
#     $snto{$key} = $words[31] * 0.3937;   # Convert from cm to inches
      $lwo{$key}  = $words[45];
      $lwi{$key}  = $words[44];
      $swo{$key}  = $words[33];
      $swi{$key}  = $words[32];

# Swamp Angel.
#  Two sets of obs are available from the tower (lower and upper).
#  Temp and rh are from lower and winds are from upper.
#  Temp data is provided as min and max from the previous hour.
#   Select the temp that is closest in time to the current hour.
#  Chris Landry has suggested not using wind data, since the site is too sheltered.
#   Wind data added for use with snowpack model.

    } elsif ($stid eq "CASWP") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = (($words[2]+$words[4])/2 * 1.8) + 32;
      $rh{$key}   = $words[6];
      $spd{$key}  = $words[15] * 2.2369;   # Convert from m/s to mph
      $dir{$key}  = $words[17];
      $gust{$key} = $words[13] * 2.2369;   # Convert from m/s to mph
      $pcp{$key}  = $words[32] / 25.4;     # Convert from mm to inches
      $pcpac{$key}= $words[33] / 25.4;     # Convert from mm to inches
      $snto{$key} = $words[30] * 39.37;    # Convert from meters to inches
#     $mslp{$key} = $words[36] * 33.8639;  # Convert from inHg to mb
      $lwo{$key}  = 5.6704e-8 * ($words[25] + 273.15) ** 4;
      $lwi{$key}  = $words[24];
      $swo{$key}  = $words[19];
      $swi{$key}  = $words[21];
      $swe{$key}  = $words[44]* 0.03937;   # Convert from mm to inches

# Senator Beck.

    } elsif ($stid eq "CASBK") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = (($words[2]+$words[4])/2 * 1.8) + 32;
      $rh{$key}   = $words[6];
      $spd{$key}  = $words[9] * 2.2369;   # Convert from m/s to mph
      $dir{$key}  = $words[11];
      $gust{$key} = $words[7] * 2.2369;    # Convert from m/s to mph
#     $pcp{$key}  = $words[33] / 25.4;     # Convert from mm to inches
#     $pcpac{$key}= $words[34] / 25.4;     # Convert from mm to inches
      $snto{$key} = $words[30] * 39.37;    # Convert from meters to inches
#     $mslp{$key} = $words[36] * 33.8639;  # Convert from inHg to mb
      $lwo{$key} = 5.6704e-8 * ($words[25] + 273.15) ** 4;
      $lwi{$key} = $words[24];
      $swo{$key} = $words[19];
      $swi{$key} = $words[21];

# A-Basin Summit.

    } elsif ($stid eq "CAABT" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[10];
      $rh{$key}   = $words[11];
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[9];
      $gust{$key} = $words[6];
      $swi{$key}  = $words[13] * 1000;  # Convert from kW to W

# A-Basin Midway (Vacant Lot).

    } elsif ($stid eq "CAABM" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[11];
      $rh{$key}   = $words[13];
      $snto{$key} = $words[16];
#     $pcp{$key}  = $words[15]/25.4;      # Convert from mm to inches
      $pcpac{$key}= $words[19]/25.4;      # Convert from mm to inches
      $sn24{$key} = $words[17];
      $mslp{$key} = $words[15] * 33.8639; # Convert from inHg to mb

# A-Basin Pali.

    } elsif ($stid eq "CAABP" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[13];
      $rh{$key}   = $words[14];
      $spd{$key}  = $words[7];
      $dir{$key}  = $words[8];
      $gust{$key} = $words[10];
      $swo{$key}  = $words[18];
      $swi{$key}  = $words[17];
      $lwo{$key}  = $words[30];
      $lwi{$key}  = $words[29];
      $net{$key}  = $words[28];

# Breck Peak 8, Peak 6, and Horseshoe Bowl.

    } elsif ($stid eq "CABP8" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[9];
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[8];
      $rh{$key}   = $words[11];

    } elsif ($stid eq "CABP6" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[9];
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[8];
      $rh{$key}   = $words[11];

    } elsif ($stid eq "CAHSB" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[9];
      $rh{$key}   = $words[11];
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[8];
      $volt{$key} = $words[10];

# Keystone Snow Study, Wapiti, and Wind Study.

    } elsif ($stid eq "CAKSS" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[7];
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[17] * 2.2369;    # Convert from m/s to mph
      $dir{$key}  = $words[18];
      $gust{$key} = $words[19];
      $snto{$key} = $words[11];
      $sn24{$key} = $words[12];
      $swe{$key}  = $words[13];
      $swe24{$key}= $words[14];
      $volt{$key} = $words[15];

    } elsif ($stid eq "CAKWP" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[12];
      $rh{$key}   = $words[13];
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[7];
      $gust{$key} = $words[9];
      $volt{$key} = $words[14];

    } elsif ($stid eq "CAKWS") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[7];
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[2];
      $dir{$key}  = $words[4];
      $gust{$key} = $words[6];
      $swi{$key}  = $words[9];
      $volt{$key} = $words[14];

# Vail (Bluesky Basin, China Bowl, PHQ, amd Mid-Mountain).

    } elsif ($stid eq "CAVBS" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[5] + $words[6]) / 2;
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[8];
      $dir{$key}  = $words[9];
      $gust{$key} = $words[11];

    } elsif ($stid eq "CAVCB" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[5] + $words[6]) / 2;
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[8];
      $dir{$key}  = $words[9];
      $gust{$key} = $words[11];

    } elsif ($stid eq "CAVPQ" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[5] + $words[6]) / 2;
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[8];
      $dir{$key}  = $words[9];
      $gust{$key} = $words[11];
#     $sn24{$key} = $words[13];
      $snto{$key} = $words[14];
      $pcp{$key}  = $words[15];
      $mslp{$key} = $words[16] * 33.8639;  # Convert from inHg to mb

    } elsif ($stid eq "CAVMM" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[5] + $words[6]) / 2;
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[8];
      $dir{$key}  = $words[9];
      $gust{$key} = $words[11];
      $sn24{$key} = $words[13] if ($words[13] < 24);
      $snto{$key} = $words[14] if ($words[14] < 100);

# Ajax Bell.

    } elsif ($stid eq "CAAXB" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[7];
      $volt{$key} = $words[8];

# Ajax Heros and Far East wind get combined into Far East.

    } elsif ($stid eq "CAAXH") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = (($words[2]+$words[3])/2 * 1.8) + 32;
      $rh{$key}   = $words[4];
      $snto{$key} = $words[6] if (looks_like_number($words[6]));
      $volt{$key} = $words[9];

    } elsif ($stid eq "CAAXE") {
      $key        = "CAAXH$dbtime:00";
      $stn{$key}  = $stn;
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[4];
      $gust{$key} = $words[3];
      $wxstn = "CAAXH" if ($wxstn eq "CAAXE");

# Ajax Midway.

    } elsif ($stid eq "CAAXM" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = (($words[5]+$words[6])/2 * 1.8) + 32;
      $rh{$key}   = $words[7];
      $sn24{$key} = $words[9] * 0.3937;      # Convert from cm to inches
      $snto{$key} = $words[10] * 0.3937;     # Convert from cm to inches
      $volt{$key} = $words[11];

# Ajax Top has two sensors that get combined.

    } elsif ($stid eq "CAAXT" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = (($words[5]+$words[6])/2 * 1.8) + 32;
      $rh{$key}   = $words[7];
      $sn24{$key} = $words[8] * 0.3937;     # Convert from cm to inches
      $snto{$key} = $words[9] * 0.3937;     # Convert from cm to inches
      $volt{$key} = $words[12];
      $wxstn = "CAAXW" if ($wxstn eq "CAAXT");

    } elsif ($stid eq "CAAXW") {
      $key        = "CAAXT$dbtime:00";
      $stn{$key}  = $stn;
      $spd{$key}  = $words[3];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[4];

# Aspen Highlands (Northwoods).

    } elsif ($stid eq "CANWD") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[15];
      $rh{$key}   = $words[16];
      $volt{$key} = $words[2];
      $snto{$key} = $words[6] if ($words[6] < 120);

# Aspen Highlands (Cloud 9).

    } elsif ($stid eq "CACL9") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[3] * 1.8) + 32;  # Convert from C to F
      $rh{$key}   = $words[4];
#     $pcpac{$key}= $words[12] * 0.03937;    # Convert from mm to inches
#     $sn24{$key} = $words[14] * 0.3937;     # Convert from cm to inches
      $snto{$key} = $words[6];
      $volt{$key} = $words[2];

# Aspen Highlands (Loge).

    } elsif ($stid eq "CALOG") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[4];
      $rh{$key}   = $words[5] if (looks_like_number($words[5]));
      $spd{$key}  = $words[6];
      $dir{$key}  = $words[9];
      $gust{$key} = $words[7];
      $swi{$key}  = $words[11];
      $volt{$key} = $words[2];

# Aspen Highlands (Peak).

    } elsif ($stid eq "CAHPK") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $volt{$key} = $words[2];
      $tp{$key}   = $words[3];
      $rh{$key}   = $words[4];
      $spd{$key}  = $words[5] if ($words[5] < 200);
      $gust{$key} = $words[6] if ($words[6] < 200);
      $dir{$key}  = $words[8] if ($words[7] <= 360);

# Snowmass Alpine.

    } elsif ($stid eq "CAALP") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[3];
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[4];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[5];
      $volt{$key} = $words[2];  

# Snowmass Baldy.

    } elsif ($stid eq "CABLD") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[3];
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[4];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[5];
      $volt{$key} = $words[2];  

# Snowmass Big Burn.

    } elsif ($stid eq "CABRN") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[3];
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[4];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[5] if ($words[5] < 200);
      $volt{$key} = $words[2];

# Snowmass Timberline.

    } elsif ($stid eq "CATLS") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[23];
      $rh{$key}   = $words[24];
      $snto{$key} = $words[6] * 39.37;    # Convert from m to inches
      $sn24{$key} = $words[34];
      $net{$key}  = $words[9];
      $swe24{$key}= $words[35];

# Snowmass Mid-Mtn.

    } elsif ($stid eq "CAALT" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[7] * 1.8) + 32;
#     $sn24{$key} = $words[5] * 0.3937;     # Convert from cm to inches
#     $snto{$key} = $words[6] * 0.3937;     # Convert from cm to inches

# Snowmass Elk Camp.

    } elsif ($stid eq "CAELK") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[3];
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[4];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[5] if ($words[5] < 200);
      $volt{$key} = $words[2];

# Snowmass Base.

    } elsif ($stid eq "CASMB" && $inc == 1) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[4] * 1.8) + 32;
      $rh{$key}   = $words[5];

# Fool Creek.

    } elsif ($stid eq "CAFLC" && $inc == 120) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[13] * 1.8) + 32;
      $rh{$key}   = $words[15];
      $spd{$key}  = $words[26] * 2.2369;   # Convert from m/s to mph
      $dir{$key}  = $words[27];
      $gust{$key} = $words[19] * 2.2369;   # Convert from m/s to mph
      $snto{$key} = $words[44] * 0.3937;   # Convert from cm to inches
      $lwo{$key}  = $words[38];
      $lwi{$key}  = $words[37];
      $swo{$key}  = $words[33];
      $swi{$key}  = $words[32];
      $net{$key}  = $words[39];

# Monarch Ski Area.

    } elsif ($stid eq "CAMNP" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[9];
      $rh{$key}   = $words[11];
      $spd{$key}  = $words[5];
      $dir{$key}  = $words[6];
      $gust{$key} = $words[8];

# CMC - Leadville.

    } elsif ($stid eq "CALXV" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[5];
      $td{$key}   = $words[8];
      $rh{$key}   = $words[9];
      $spd{$key}  = $words[10];
      $dir{$key}  = $words[11];
      $gust{$key} = $words[12];
      $pcp{$key}  = $words[14];
      $pcp24{$key}= $words[15];

# Cloud seeders (Grand Mesa).

    } elsif ($stid eq "CAMR1" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[6] * 1.8) + 32;
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[9];
      $dir{$key}  = $words[8];
      $gust{$key} = $words[10];

    } elsif ($stid eq "CALPG" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[11] * 1.8) + 32;
      $rh{$key}   = $words[12];
      $spd{$key}  = $words[14];
      $dir{$key}  = $words[13];
      $gust{$key} = $words[15];
      $volt{$key} = $words[6];

    } elsif ($stid eq "CAWWC" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[6] * 1.8) + 32;
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[15];
      $dir{$key}  = $words[9];
#     $gust{$key} = $words[24];
#     $pcp{$key}  = $words[16];

    } elsif ($stid eq "CALCK" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[6];
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[8];
      $dir{$key}  = $words[11];
      $gust{$key} = $words[9];
      $volt{$key} = $words[5];

# Ouray Mine.

    } elsif ($stid eq "CAHAY" && substr($words[0],1,4) == $yyyy) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[2];
      $rh{$key}   = ($words[5] + $words[6]) / 2;
      $td{$key}   = $words[7];
      $spd{$key}  = $words[13];
      $dir{$key}  = $words[14];
      $gust{$key} = $words[15];

    } elsif ($stid eq "CASYD" && substr($words[0],1,4) == $yyyy) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[2];
      $rh{$key}   = ($words[5] + $words[6]) / 2;
      $td{$key}   = $words[7];
      $spd{$key}  = $words[13];
      $dir{$key}  = $words[14];
      $gust{$key} = $words[15];

# Mountain Studies.

    } elsif ($stid eq "MSMIN" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[12] * 1.8) + 32;  # Convert from C to F
      $rh{$key}   = $words[13];
      $spd{$key}  = $words[8] * 2.2369;       # Convert from m/s to mph
      $dir{$key}  = $words[6];
      $gust{$key} = $words[9] * 2.2369;       # Convert from m/s to mph
      $snto{$key} = $words[14] * 0.3937;      # Convert from meters to inches

# Douglas Pass.

    } elsif ($stid eq "CADGP" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[19];
      $rh{$key}   = $words[20];
      $spd{$key}  = $words[21];
      $dir{$key}  = $words[22];
      $gust{$key} = $words[24];
      $snto{$key} = $words[25];
      $pcp{$key}  = $words[26];
      $sn24{$key} = $words[28];
      $pcp24{$key}= $words[29];
      $volt{$key} = $words[17];

# CBAC Elkton.

    } elsif ($stid eq "CAELT") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[6];
      $rh{$key}   = $words[7];
      $snto{$key} = $words[8];
      $pcp{$key}  = $words[9];
      $spd{$key}  = $words[11];
      $dir{$key}  = $words[12];
      $gust{$key} = $words[14];
      $sn24{$key} = $words[15];
      $volt{$key} = $words[5];

# CDOT Glenwood Canyon Blue Gulch.

    } elsif ($stid eq "CABLG") {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $volt{$key} = $words[5];
      $tp{$key}   = ($words[6] * 1.8) + 32;  # Convert from C to F
      $rh{$key}   = $words[7];
      $spd{$key}  = $words[8];
      $dir{$key}  = $words[10];
      $gust{$key} = $words[9];
      $pcp1m{$key}= $words[11];              # 1-minute precip 
      $pcp5m{$key}= $words[12];              # 5-minute precip 

# RMBL Cinnamon Mountain.

    } elsif ($stid eq "CACNM" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = ($words[5] * 1.8) + 32;
      $rh{$key}   = $words[8];
      $spd{$key}  = $words[13] * 2.2369;    # Convert from m/s to mph
      $gust{$key} = $words[18] * 2.2369;    # Convert from m/s to mph
      $dir{$key}  = $words[14];
      $swi{$key}  = $words[12];
      $volt{$key} = $words[21];

# Cimarron Mountain Club (Study Plot and Ridge).

    } elsif ($stid eq "CACMS" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[11];
      $rh{$key}   = $words[12];
      $td{$key}   = $words[13];
      $sn24{$key} = $words[14];
      $snto{$key} = $words[15];

    } elsif ($stid eq "CACMR" && $inc == 101) {
      $key        = "$stid$dbtime:00";
      $stn{$key}  = $stn;
      $tp{$key}   = $words[8];
      $rh{$key}   = $words[5];
      $spd{$key}  = $words[9];
      $dir{$key}  = $words[10];
      $gust{$key} = $words[12];
    }
  }
  close(IN);
  system("/usr/bin/rm -rf $work/$stid");
}

# Insert parsed data into database.

my ($db,$query,$table_input,$table_output,$nrows);

# Connect to the weather database.

my %attr = (RaiseError=>1,  # error handling enabled 
            AutoCommit=>0); # transaction enabled

my ($host,$dbname,$user,$password) = &dbInfo::dbInfo();
my ($wxtable,$hydrotable,$snowtable,$solartable,$batterytable,$dailytable) = &dbInfo::dbTables();

print "Connecting to local database: $dbname as user: $user\n";
$db = DBI->connect("DBI:mysql:$dbname:$host", $user, $password);

# Write data to database.

$db->begin_work();
my $ctwx = 0;
my $cthydro = 0;
my $ctsnow = 0;
my $ctsolar = 0;
foreach $key (sort keys %stn) {
  $stid = substr($key,0,5);
  $date = substr($key,5);
  if (defined($tp{$key})) {
    if ($tp{$key} >= -60 && $tp{$key} < 110) {
      $tp{$key} = &nint($tp{$key}*10);
    } else {
      $tp{$key} = undef;
    }
  }
  if (defined ($td{$key})) {
    $td{$key} = &nint($td{$key}*10);
    if ($td{$key} >= -60 && $td{$key} < 110) {
      $td{$key} = &nint($td{$key}*10);
    } else {
      $td{$key} = undef;
    }
  } elsif (defined($tp{$key}) && defined($rh{$key})) {
    if ($rh{$key} > 0) {
      $tpk = ($tp{$key}/10 - 32) / 1.8 + 273.15;
      $td{$key} = &rh2td($tpk,$rh{$key});
      $td{$key} = &nint(($td{$key} - 273.15) * 18 + 320);
    }
  }
  $tpmn{$key} = &nint($tpmn{$key}*10) if (defined($tpmn{$key}));
  $tpmx{$key} = &nint($tpmx{$key}*10) if (defined($tpmx{$key}));
  if (defined($rh{$key})) {
    if ($rh{$key} < 0) {
      $rh{$key} = undef;
    } else {
      $rh{$key} = min(&nint($rh{$key}),100);
    }
  }
  if (defined($spd{$key})) {
    if ($spd{$key} >= 0 && $spd{$key} < 200) {
      $spd{$key} = &nint($spd{$key}*10);
    } else {
      $spd{$key} = undef;
    }
  }
  $dir{$key} = &nint($dir{$key}) if (defined($dir{$key}));
  $gust{$key} = &nint($gust{$key}*10) if (defined($gust{$key}));
  $mslp{$key} = &nint($mslp{$key}) if (defined($mslp{$key}));
  if (defined($snto{$key})) {
    $snto{$key} = 0 if ($snto{$key} < 0);
    $snto{$key} = &nint($snto{$key}*10);
  }
  if (defined($sn24{$key})) {
    $sn24{$key} = 0 if ($sn24{$key} < 0);
    $sn24{$key} = &nint($sn24{$key}*10);
  }
  if (defined($pcp1m{$key})) {
    $pcp1m{$key} = 0 if ($pcp1m{$key} < 0);
    $pcp1m{$key} = &nint($pcp1m{$key}*1000);
  }
  if (defined($pcp5m{$key})) {
    $pcp5m{$key} = 0 if ($pcp5m{$key} < 0);
    $pcp5m{$key} = &nint($pcp5m{$key}*1000);
  }
  if (defined($pcp{$key})) {
    $pcp{$key} = 0 if ($pcp{$key} < 0);
    $pcp{$key} = &nint($pcp{$key}*100);
    $pcp{$key} = undef if ($pcp{$key} > 500);
  }
  if (defined($pcp24{$key})) {
    $pcp24{$key} = 0 if ($pcp24{$key} < 0);
    $pcp24{$key} = &nint($pcp24{$key}*100);
    $pcp24{$key} = undef if ($pcp24{$key} > 1000);
  }
  if (defined($pcpac{$key})) {
    $pcpac{$key} = 0 if ($pcpac{$key} < 0);
    $pcpac{$key} = &nint($pcpac{$key}*100);
    $pcpac{$key} = undef if ($pcpac{$key} > 1000);
  }
  if (defined($swe{$key})) {
    $swe{$key} = 0 if ($swe{$key} < 0);
    $swe{$key} = &nint($swe{$key}*100);
  }
  if (defined($swe24{$key})) {
    $swe24{$key} = 0 if ($swe24{$key} < 0);
    $swe24{$key} = &nint($swe24{$key}*100);
  }
  if (defined($swi{$key})) {
    $swi{$key} = 0 if ($swi{$key} < 0);
    $swi{$key} = &nint($swi{$key}*10);
  }
  if (defined($swo{$key})) {
    $swo{$key} = 0 if ($swo{$key} < 0);
    $swo{$key} = &nint($swo{$key}*10);
  }
  if (defined($lwi{$key})) {
    $lwi{$key} = 0 if ($lwi{$key} < 0);
    $lwi{$key} = &nint($lwi{$key}*10);
  }
  if (defined($lwo{$key})) {
    $lwo{$key} = 0 if ($lwo{$key} < 0);
    $lwo{$key} = &nint($lwo{$key}*10);
  }
  $net{$key} = &nint($net{$key}*10) if (defined($net{$key}));
  if (defined($volt{$key})) {
    $volt{$key} = 0 if ($volt{$key} < 0);
    $volt{$key} = &nint($volt{$key}*100);
  }

  $query = "$insert into $wxtable set staname='$stid', time='$date'";
  $query = "$query".", temp=$tp{$key}" if (defined($tp{$key}));
  $query = "$query".", mntemp24h=$tpmn{$key}" if (defined($tpmn{$key}));
  $query = "$query".", mxtemp24h=$tpmx{$key}" if (defined($tpmx{$key}));
  $query = "$query".", dewp=$td{$key}" if (defined($td{$key}));
  $query = "$query".", rh=$rh{$key}" if (defined($rh{$key}));
  $query = "$query".", wspd=$spd{$key}" if (defined($spd{$key}));
  $query = "$query".", wdir=$dir{$key}" if (defined($dir{$key}));
  $query = "$query".", gust=$gust{$key}" if (defined($gust{$key}));
  $query = "$query".", mslp=$mslp{$key}" if (defined($mslp{$key}));
# print"$query\n";

  $table_input = $db->prepare($query);
  $table_input->execute;
  $table_input->finish;
  ++$ctwx;

  if (defined($pcp1m{$key}) || defined($pcp5m{$key}) || defined($pcp{$key}) || defined($pcp24{$key}) || defined($pcpac{$key})) {

    $query = "$insert into $hydrotable set staname='$stid', time='$date'";
    $query = "$query".", pcp1m=$pcp1m{$key}" if (defined($pcp1m{$key}));
    $query = "$query".", pcp5m=$pcp5m{$key}" if (defined($pcp5m{$key}));
    $query = "$query".", pcp1=$pcp{$key}" if (defined($pcp{$key}));
    $query = "$query".", pcp24=$pcp24{$key}" if (defined($pcp24{$key}));
    $query = "$query".", pcpac=$pcpac{$key}" if (defined($pcpac{$key}));
#   print "$query\n";
    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
    ++$cthydro;
  }

  if (defined($snto{$key}) || defined($swe{$key}) || defined($swe24{$key}) || defined($sn24{$key})) {
    $query = "$insert into $snowtable set staname='$stid', time='$date'";
    $query = "$query".", depth=$snto{$key}" if (defined($snto{$key}));
    $query = "$query".", snowwater=$swe{$key}" if (defined($swe{$key}));
    $query = "$query".", snowwater24h=$swe24{$key}" if (defined($swe24{$key}));
    $query = "$query".", snow24h=$sn24{$key}" if (defined($sn24{$key}));
#   print "$query\n";

    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
    ++$ctsnow;
  }

  if (defined($swi{$key}) || defined($swo{$key}) || defined($lwi{$key}) || defined($lwo{$key}) || defined($net{$key})) {
    $query = "$insert into $solartable set staname='$stid', time='$date'";
    $query = "$query".", swin=$swi{$key}" if (defined($swi{$key}));
    $query = "$query".", swout=$swo{$key}" if (defined($swo{$key}));
    $query = "$query".", lwin=$lwi{$key}" if (defined($lwi{$key}));
    $query = "$query".", lwout=$lwo{$key}" if (defined($lwo{$key}));
    $query = "$query".", net=$net{$key}" if (defined($net{$key}));

    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
    ++$ctsolar;
  }

  if (defined($volt{$key})) {
    $query = "$insert into $batterytable set staname='$stid', time='$date'";
    $query = "$query".", voltage=$volt{$key}" if (defined($volt{$key}));
    $table_input = $db->prepare($query);
    $table_input->execute;
    $table_input->finish;
  }
}
$db->commit();

print "No. of local wx stations: $ctwx\n";
print "No. of local hydro stations: $cthydro\n";
print "No. of local snow stations: $ctsnow\n";
print "No. of local solar stations: $ctsolar\n";

# Disconnect from the db.

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

#===============================================================================

# &julian: Calculate julian day from year, month, day
# Arguments: year, month, day
# Returns: julian day

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
}
1;

#===============================================================================

sub JJJ2MMDD {
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

################################################################################

sub nint { my ($z) = @_; return ($z>0)? int($z+0.5) : int($z-0.5); }

################################################################################

sub rh2td {

# Compute dew point from temperature (K) and RH (percent).

  my ($t, $rh) = @_;
  my $rvolv = 0.0001846;  # rv/lv (461.5/2.5e6)

  my $rhp = $rh / 100;
  $rhp = 1 if ($rhp > 1);
  my $td = $t / ((-$rvolv * log($rhp) * $t) + 1);
  $td = $t if ($td > $t);
  $td;
}
1;
