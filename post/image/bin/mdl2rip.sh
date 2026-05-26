#!/bin/sh

root=/home/caic/caic/rtsys/post/image

domain=$1
res=$2
model=$3
date=$4
fcst=$5
if [ $res == "12km" ]; then
  longtimestep=60
  if [ $domain == "caic" ]; then
    lat0=39.4
    lon0=-108.6        
  else
    lat0=41.0
    lon0=-98.0
  fi 
elif [ $res == "7p5km" ]; then
  longtimestep=60
  lat0=39.4
  lon0=-108.6        
elif [ $res == "2p5km" ]; then
  longtimestep=12
  lat0=39.11378         
  lon0=-106.8894         
else
  longtimestep=12
  lat0=39.14778
  lon0=-106.8460         
fi

if [ $fcst -lt 10 ]; then
   fcst=00$fcst
elif [ $fcst -lt 100 ]; then
   fcst=0$fcst
fi

date=$date"_"$fcst"00"

echo Creating fsf rip file for $date
$root/exe/mdl2rip.exe << endin
$domain
$res
$model
$lat0 $lon0 $longtimestep
$date
endin

exit 0
