#!/bin/sh

root=/home/caic/caic/rtsys/obs/provider/usgs
sdate=`date -d "1 day ago" +%Y-%m-%d`
edate=`date +%Y-%m-%d`

cd $root/data

wget -O berthoudpass.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=394759105464101&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s berthoudpass

wget -O senbeck.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=375429107433201&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s senbeck

wget -O lakeirwin.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=385315107063001&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s lakeirwin

wget -O blueridge.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=395709105582701&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s blueridge

wget -O devilsthumb.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=395811105480401&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s devilsthumb

wget -O ranchmeadow.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=395448105453601&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s ranchmeadow

wget -O indypass.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=390622106343001&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s indypass

wget -O chairmtn.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=390447107175001&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s chairmtn

wget -O ptarmigan.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=392954106162501&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s ptarmigan

wget -O huntercreek.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=391326106452601&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s huntercreek

wget -O cameronpass.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=402945105543801&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s cameronpass

wget -O bossbasin.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=392820106154601&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s bossbasin

wget -O taylorpass.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=390012106455401&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s taylorpass

wget -O lakeirwin.csv "https://waterdata.usgs.gov/nwis/uv?cb_00020=on&cb_00025=on&cb_00035=on&cb_00036=on&cb_00052=on&cb_72174=on&cb_72175=on&cb_72185=on&cb_72186=on&cb_72189=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72253=on&cb_72341=on&cb_72392=on&cb_72393=on&cb_72394=on&cb_72405=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&cb_74207=on&format=rdb&site_no=385303107060301&period=&begin_date=$sdate&end_date=$edate"

/usr/bin/perl $root/usgs.pl -s lakeirwin

exit 0
