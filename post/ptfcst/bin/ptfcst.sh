#!/bin/sh

python=/usr/bin/python3.12
root=/home/caic/caic/rtsys/post

if [ $# -lt 1 ]; then
  echo "Usage:  ptfcst.sh 'model'"
  exit 1
fi

mdl=$1
wrf="${mdl:0:3}"

if [ $mdl == "hrrr" ] || [ $mdl == "nbm" ]; then
  date=`date -u -d "1 hour ago" +%Y%m%d%H`
  iptf=`date -u -d "1 hour ago" +%y%j%H00`
elif [ $wrf == "wrf" ]; then
  hour=`date -d "3 hours ago" -u +%H`
  diff=`expr $hour % 6`
  diff=`expr $diff + 3`
  date=`date -d "$diff hours ago" -u +%Y%m%d%H`
  iptf=`date -d "$diff hours ago" -u +%y%j%H00`
  res="${mdl:3:3}"
else
  date=`date -u +%Y%m%d%H`
fi

$python $root/ptfcst/bin/ptfcst.py --model $mdl --time $date
$python $root/ptfcst/bin/ptfcst-summary.py --model $mdl --time $date

# Generate interactive point forecast for API.

if [ $mdl == "hrrr" ] || [ $mdl == "nbm" ]; then
  $python $root/iptfcst/bin/build_zarr.py --input "/data/noaaport/grids/$mdl/grib2/$iptf*" --output /data/iptfcst --model $mdl 
elif [ $wrf == "wrf" ]; then
  $python $root/iptfcst/bin/build_zarr.py --input "/model/caic/$res/wrf/$iptf/wrfout_d02_*" --output /data/iptfcst --model $mdl
else # ndfd
  $python $root/iptfcst/bin/build_zarr.py --input "/data/noaaport/grids/ndfd/grib2/ndfd.grb2" --output /data/iptfcst --model $mdl
fi

exit 0
