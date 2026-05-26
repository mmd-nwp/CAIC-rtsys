#!/bin/sh

if [ ! -t 0 ]; then
  source /opt/intel/oneapi/setvars.sh
fi

ulimit -s unlimited

if [ $# -ne 2 ]; then
  echo "Usage:  nceppost.sh 'domain' 'model'"
  exit 1
fi

domain=$1
model=$2
finc=3

root=/home/caic/caic/rtsys/post

rundate=current
#rundate=260301800

if [ $rundate == "current" ]; then
  hour=`date -u -d "2 hours ago" +%H`
  diff=`expr $hour % 6`
  diff=`expr $diff + 2`
  rundate=`date -u -d "$diff hours ago" +%y%j%H00`
fi
echo $rundate

# Generate webdate from rundate.

days1=31
days2=28
days3=31
days4=30
days5=31
days6=30
days7=31
days8=31
days9=30
days10=31
days11=30
days12=31

year=`expr $rundate / 10000000`
year=`expr $year + 2000`
day=`expr $rundate % 10000000`
day=`expr $day / 10000`
if [ `expr $year % 4` -eq 0 ]; then
   days2=29
fi
month=1
days=$(eval echo "\$days$month")
while [ $day -gt $days ]; do
   day=`expr $day - $days`
   month=`expr $month + 1`
   days=$(eval echo "\$days$month")
done
hour=`expr $rundate % 10000`
hour=`expr $hour / 100`
while [ ${#month} -lt 2 ]; do month="0$month"; done
while [ ${#day} -lt 2 ]; do day="0$day"; done
while [ ${#hour} -lt 2 ]; do hour="0$hour"; done
webdate=$year-$month-$day-$hour"00"
echo $webdate

year=`expr $year - 2000`
ptdate=$year$month$day$hour

ngrid=1
res1=12km
mdir=/model/$domain/$res1/$model/$rundate
wdir1=/web/caic/$res1/$model
lapsdataroot1=/model/$domain/$res1/laps

if [ $domain == "caic" ]; then
  ngrid=2
  res2=4km
  lapsdataroot2=/model/$domain/$res2/laps
  pdir1=$wdir1/points
  xdir1=$wdir1/xsec
  sdir1=$wdir1/sndg
  mkdir -p $mdir/ptfcst
  mkdir -p $mdir/timeht
  mkdir -p $mdir/sndg
  mkdir -p $pdir1/$webdate
  mkdir -p $xdir1/$webdate
  mkdir -p $sdir1/$webdate
fi

# Wait for first grib file to arrive.

firstfile=/data/noaaport/grids/$model/grib2/$rundate"0000"
if [ $model == "nam" ]; then
  lastfile=/model/$domain/$res1/laps/lapsprd/fsf/nam/$rundate"_08400.fsf"
  nfile=29
elif [ $model == "gfs" ]; then
  lastfile=/model/$domain/$res1/laps/lapsprd/fsf/gfs/$rundate"_24000.fsf"
  nfile=81
fi

time_out=14400
elapsed=0
while [ ! -e $firstfile ]; do
  if [ $elapsed -gt $time_out ]
  then
    echo NCEP post-processing timed out.
    echo firstfile: $firstfile $elapsed $time_out
    exit 0
  fi
  sleep 30
  elapsed=`expr $elapsed + 30`
done

# Run model post-processing code.

export OMP_NUM_THREADS=2
freq_check=60
grib=0
delay=0
dbwrite=0

while [ ! -e $lastfile ]; do

if [ $domain == "conus" ]; then

$root/exe/mdlpost.exe << endin
$domain
$ngrid
$res1
$lapsdataroot1
$model
$rundate
0 $nfile $finc




$root/image/bin/mdlimage.sh
$grib
$delay
$dbwrite
endin

else

$root/exe/mdlpost.exe << endin
$domain
$ngrid
$res1
$lapsdataroot1
$res2
$lapsdataroot2
$model
$rundate
0 $nfile $finc
$root/static/ptfcst.txt
$root/static/timeht.txt
$root/static/sndg.txt
$root/bin/filldb.pl
$root/image/bin/mdlimage.sh
$grib
$delay
$dbwrite
endin

fi

if [ $elapsed -gt $time_out ]; then
   echo NCEP post-processing timed out.
   exit 1
fi

if [ ! -e $lastfile ]; then
  sleep $freq_check
  elapsed=`expr $elapsed + $freq_check`
fi

done

if [ $domain == "conus" ]; then
  exit 0
fi

# Generate point forecast text files and graphs for web directory.

cp $mdir/ptfcst/ptfcst.txt $pdir1/$webdate
/usr/bin/perl $root/ptfcst/bin/ptfcst.pl -t $ptdate -m $model -d $domain -r $res1 -n85
/usr/bin/perl $root/ptfcst/bin/ptfcst-image.pl -t $ptdate -m $model -r $res1
/usr/bin/perl $root/ptfcst/bin/ptfcst-image.pl -t $ptdate -m $model -r $res2

cd $pdir1
rm -rf current
ln -fs $webdate current

# Generate time-hight images for web directory.

nfcst=84

cp $mdir/timeht/timeht.txt $xdir1/$webdate
$root/bin/hov_nam.csh $year $month $day $hour $nfcst $rundate $xdir1/$webdate $model $domain $res2

cd $xdir1
rm -rf current
ln -fs $webdate current

# Forecast soundings are created by post-proc. Set current link here.

cd $sdir1
rm -rf current
ln -fs $webdate current

exit 0
