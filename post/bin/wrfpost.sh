#!/bin/sh

if [ ! -t 0 ]; then
  source /opt/intel/oneapi/setvars.sh
fi

if [ $# -lt 3 ]; then
  echo "Usage:  wrfpost.sh 'domain' 'model' 'res' ['rundate']"
  exit 1
fi

domain=$1
model=$2
res=$3

rundate=current
#rundate=260200600
if [ $# -eq 4 ]; then
  rundate=$4
fi

root=/home/caic/caic/rtsys/post

export OMP_NUM_THREADS=4
export OMP_STACKSIZE=16M

ngrid=2
if [ $res == "4km" ]; then
  res1=12km
  res2=4km
else
  res1=6km
  res2=2km
fi
lapsdataroot1=/model/$domain/$res1/laps
lapsdataroot2=/model/$domain/$res2/laps

mdir=/model/$domain/$res1/$model

wdir1=/web/$domain/$res1/$model
pdir1=$wdir1/points
wdir2=/web/$domain/$res2/$model
pdir2=$wdir2/points
xdir2=$wdir2/xsec
sdir2=$wdir2/sndg

freq_check=120
time_out=21600
grib=0
delay=5
dbwrite=0

if [ $rundate == "current" ]; then
  rundate=`ls -al $mdir/current | awk -F"> " '{print $2}'`
fi

mdir=$mdir/$rundate
lastfile=/model/$domain/$res1/laps/lapsprd/fsf/$model/$rundate"_08400.fsf"

firstfile=$mdir/wrfout_d01_*
set -- $firstfile
firstfile=$1

elapsed=0
while [ ! -e $firstfile ]; do
  if [ $elapsed -gt $time_out ]
  then
    echo WRF post-processing timed out.
    exit 0
  fi
  if [ -r $lastfile ]; then
    exit 0
  fi
  sleep 60
  elapsed=`expr $elapsed + 60`
done

date=`ls $mdir/wrfout_d01_* | awk -Fd01_20 '{ print $2 }'`
set -- $date
date=$1
ymd=`echo $date | awk -F_ '{ print $1 }'`
year=20`echo $ymd | awk -F- '{ print $1 }'`
month=`echo $ymd | awk -F- '{ print $2 }'`
day=`echo $ymd | awk -F- '{ print $3 }'`
ymd=`echo $date | awk -F: '{ print $1 }'`
hour=`echo $ymd | awk -F_ '{ print $2 }'`
webdate=$year-$month-$day-$hour"00"
year=`expr $year - 2000`
ptdate=$year$month$day$hour

mkdir -p $mdir/ptfcst
mkdir -p $mdir/timeht
mkdir -p $mdir/sndg
mkdir -p $pdir1/$webdate
mkdir -p $pdir2/$webdate
mkdir -p $xdir2/$webdate
mkdir -p $sdir2/$webdate

# Run model post-processing code.

while [ ! -r $lastfile ]; do

$root/exe/mdlpost.exe << endin
$domain
$ngrid
$res1
$lapsdataroot1
$res2
$lapsdataroot2
$model
$rundate
0 85 1
$root/static/ptfcst.txt
$root/static/timeht.txt
$root/static/sndg.txt
$root/bin/filldb.pl
$root/image/bin/mdlimage.sh
$grib
$delay
$dbwrite
endin

if [ $elapsed -gt $time_out ]; then
  echo WRF post-processing timed out.
  exit 0
fi
if [ ! -e $lastfile ]; then
  sleep $freq_check
  elapsed=`expr $elapsed + $freq_check`
fi

done

# Generate interactive point forecast (csv files and api) and javascript file for website.

if [ $res == "2km" ]; then
  $root/ptfcst/bin/iptfcst-wrf.sh 6km &
  $root/ptfcst/bin/iptfcst-wrf.sh 2km &
  /home/caic/caic/rtsys/snowpack/runs/zones/post/bin/wrf2fcst.sh $rundate &
# /usr/bin/python3.12 $root/iptfcst/bin/build_zarr.py --input "/model/caic/2km/wrf/$rundate/wrfout_d02_*" --output /data/iptfcst --model wrf2km &
fi

# Change current to new date for forecast soundings.

cd $sdir2
rm -rf current
ln -fs $webdate current

# Generate point forecast text files.

cp $mdir/ptfcst/ptfcst.txt $pdir2/$webdate
/usr/bin/perl $root/ptfcst/bin/ptfcst.pl -t $ptdate -m $model -d $domain -r $res2 -n85

cd $pdir2
rm -rf current
ln -fs $webdate current

# E-mail A-Basin forecast.

sleep 1
$root/ptfcst/bin/abasin.sh $res2  # E-mail A-Basin forecast.
#$root/ptfcst/worldcup/wc.sh      # World Cup

# Generate point forecast and cloud seeder graphs for web directory.

/usr/bin/perl $root/ptfcst/bin/ptfcst-image.pl -t $ptdate -m $model -r $res1
/usr/bin/perl $root/ptfcst/bin/ptfcst-image.pl -t $ptdate -m $model -r $res2
/usr/bin/perl $root/ptfcst/bin/ptfcst-image.pl -t $ptdate -m $model -r $res1 -i s
/usr/bin/perl $root/ptfcst/bin/ptfcst-image.pl -t $ptdate -m $model -r $res2 -i s

# Generate time-hight images for web directory.

fcsts=`ls $mdir/wrfout_d01_*`

nfcst=-1
for fcst in $fcsts
do
  nfcst=`expr $nfcst + 1`
done

cp $mdir/timeht/timeht.txt $xdir2/$webdate
$root/bin/hov_wrf.csh $year $month $day $hour $nfcst $rundate $xdir2/$webdate $model $domain $res2

cd $xdir2
rm -rf current
ln -fs $webdate current

# Fill db with forecast grids.

#$root/post/bin/dbfcst.sh

# Update snowpack input files.

#/usr/bin/perl $root/snowpack/runs/bin/spwrf.pl -t $ptdate

exit 0
