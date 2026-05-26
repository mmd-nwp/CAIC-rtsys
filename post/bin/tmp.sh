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

# Generate time-hight images for web directory.

fcsts=`ls $mdir/wrfout_d01_*`

nfcst=-1
for fcst in $fcsts
do
  nfcst=`expr $nfcst + 1`
done

echo cp $mdir/timeht/timeht.txt $xdir2/$webdate
$root/bin/hov_wrf.csh $year $month $day $hour $nfcst $rundate $xdir2/$webdate $model $domain $res2

exit 0

cd $xdir2
rm -rf current
ln -fs $webdate current

# Fill db with forecast grids.

#$root/post/bin/dbfcst.sh

# Update snowpack input files.

#/usr/bin/perl $root/snowpack/runs/bin/spwrf.pl -t $ptdate

exit 0
