#!/bin/sh

if [ $# -lt 1 ]; then
  echo "Usage:  iptfcst-wrf.sh 'res [2km] 'rundate [221051200]' 'ptdate [2022-02-15-1200]'"
  exit 1
fi

res=$1

# Check for input run time.
#   Otherwise use previous 6-hour run time.

if [ $# -eq 3 ]; then
  rundate=$2
  ptdate=$3
else
  hour=`date -u +%H`
  diff=`expr $hour % 6`
  diff=`expr $diff + 6`
  rundate=`date -u -d "$diff hours ago" +%y%j%H`"00"
  ptdate=`date -u -d "$diff hours ago" +%Y-%m-%d-%H`"00"
  echo $rundate $ptdate
fi

model=wrf$res
yyyy=${ptdate:0:4}
mm=${ptdate:5:2}
dd=${ptdate:8:2}

aws="caic@looper-origin.avalanche.state.co.us"
awsdir=/ebs/caic/incoming/point-forecasts/$yyyy/$mm/$dd
ptfdir=/ebs/caic/incoming/point-forecasts/grids

source /opt/intel/oneapi/setvars.sh

root=/home/caic/caic/rtsys/post/ptfcst
lapsdataroot=/model/caic/$res/laps
fcst=`ls $lapsdataroot/lapsprd/fsf/wrf/$rundate* | wc -l`

inc=1

cd $root/data

$root/exe/iptfcst-wrf.exe << endin
$model
$lapsdataroot
$rundate
$fcst $inc
endin

cat $model-$rundate".csv" | tr -d "[:blank:]" > $model-$ptdate".csv"
cp $model-$ptdate".csv" /home/www/html/iptfcst/grids
gzip -f $model-$ptdate".csv"
ssh $aws mkdir -p $awsdir
scp $model-$ptdate".csv.gz" $aws:$awsdir
ssh $aws cp $awsdir/$model-$ptdate".csv.gz" $ptfdir
ssh $aws gunzip -f $ptfdir/$model-$ptdate".csv.gz"
rm $model-$rundate".csv" $model-$ptdate".csv.gz"

exit 0
