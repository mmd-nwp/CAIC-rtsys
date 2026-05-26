#!/bin/sh

python=/usr/bin/python3.12
root=/home/caic/caic/rtsys

date=`date -u -d "1 hour ago" +%Y%m%d%H`
json=`date -u -d "1 hour ago" +%y%j%H00`
hour=`date -u -d "1 hour ago" +%H`
diff=`expr $hour % 6`

# Download NBM grids.

perl $root/download/bin/model_download.pl -m nbm -p 1

# Generate nbm forecast json files for model dashboard.

echo Generate web file $date

if [ $diff -eq 0 ]; then
$python $root/snowpack/runs/zones/post/python/nbmfcst-grib.py << endin
$json
endin
fi

# Generate point forecasts.

$root/post/ptfcst/bin/ptfcst.sh nbm

exit 0
