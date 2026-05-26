#!/bin/sh

root=/home/caic/caic/rtsys/obs/madis
perl=/usr/bin/perl

$perl $root/bin/madis.pl

date=`date -u -d "1 hour ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "2 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "3 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "4 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "5 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "6 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "7 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "8 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "9 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "10 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "11 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

date=`date -u -d "12 hours ago" +%y%m%d%H`
$perl $root/bin/madis.pl -d $date

$perl $root/bin/combine.pl

#echo ftp dmadisi.esrl.noaa.gov
#ftp dmadisi.esrl.noaa.gov << endin
#lcd $root/data/madis
#cd ldad
#ascii
#put CAIC_ATM.dat
#put CAIC_SNOW.dat
#quit
#endin

#echo ftp madisinftp.ncep.noaa.gov 
#ftp madisinftp.ncep.noaa.gov << endin
#lcd $root/data/madis
#cd ldad
#ascii
#put CAIC_ATM.dat
#put CAIC_SNOW.dat
#quit
#endin

echo ftp madisinftp.ncep.noaa.gov
/usr/bin/ftp madisinftp.ncep.noaa.gov << endin
lcd $root/data/madis
cd ldad
ascii
put CAIC_ATM.dat
put CAIC_SNOW.dat
quit
endin

exit 0
