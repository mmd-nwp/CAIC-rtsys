#!/bin/sh

if [ ! -t 0 ]; then
  source /opt/intel/oneapi/setvars.sh
fi

# Check for input run time.
#   Otherwise use current time.

if [ $# -eq 1 ]; then
  ptdate=$1
else
  ptdate=`date -u +%Y-%m-%d-%H`"00"
  echo $ptdate
fi

model=nws
yyyy=${ptdate:0:4}
mm=${ptdate:5:2}
dd=${ptdate:8:2}

aws="caic@looper-origin.avalanche.state.co.us"
awsdir=/ebs/caic/incoming/point-forecasts/$yyyy/$mm/$dd
ptfdir=/ebs/caic/incoming/point-forecasts/grids

root=/home/caic/caic/rtsys/post/ptfcst

cd $root/data

$root/exe/iptfcst-ndfd.exe

cat $model".csv" | sed -r 's/-999//g' | tr -d "[:blank:]" > $model-$ptdate".csv"
cp $model-$ptdate".csv" /home/www/html/iptfcst/grids
gzip -f $model-$ptdate".csv"
ssh $aws mkdir -p $awsdir
scp $model-$ptdate".csv.gz" $aws:$awsdir
ssh $aws cp $awsdir/$model-$ptdate".csv.gz" $ptfdir
ssh $aws gunzip $ptfdir/$model-$ptdate".csv.gz"
rm $model".csv" $model-$ptdate".csv.gz"

exit 0
