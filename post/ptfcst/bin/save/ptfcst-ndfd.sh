#!/bin/sh

if [ ! -t 0 ]; then
  source /opt/intel/oneapi/setvars.sh
fi

root=/home/caic/caic/rtsys/post/ptfcst
pfile=$root/namelist/ptfcst.txt

date=`date -u +%y%j%H00`
data=`date -u +%Y-%m-%d-%H`
#date=232740300
#data=2023-10-01-03
#/bin/mkdir -p $root/table/$data

# Parse gridded data into point forecast table.

#$root/exe/ptfcst-ndfd.exe << endin
#$date
#$pfile
#$root/table/$data
#endin

# Create forecast xml file.

#/usr/bin/perl $root/bin/bc-fcst.pl -d $data 

# Push xml file to avalanche.state.co.us machine.

#scp /home/www/html/wxdata/nwsforecast.xml caic@jump.avalanche.state.co.us:/ebs/caic/wxdata
#scp /home/www/html/wxdata/nwsforecast-new.xml caic@jump.avalanche.state.co.us:/ebs/caic/wxdata

# Initiate new db approach.

#cd /data/noaaport/grids/ndfd/grib2
#cat period1/* period2/* > ndfd.grb2

root=/home/caic/caic/rtsys/post/ptfcst-summary
date=`date -u +%Y%m%d%H`
python3.12 $root/bin/ptfcst.py --model ndfd --time $date
python3.12 $root/bin/ptfcst-summary.py --model ndfd --time $date

# Purge table text files.

/usr/bin/perl $root/bin/purge-table.pl

exit 0
