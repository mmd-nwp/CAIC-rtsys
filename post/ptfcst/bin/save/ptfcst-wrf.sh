#!/bin/sh

# Generate xml file used by CAIC point forecast summary website.

root=/home/caic/caic/rtsys/post/ptfcst

if [ $# -ne 1 ]; then
  echo "Usage:  ptfcst-wrf.sh 'res'"
  exit 1
fi
res=$1

hour=`date -d "3 hours ago" -u +%H`
diff=`expr $hour % 6`
diff=`expr $diff + 3`

wdir=`date -d "$diff hours ago" -u +%Y-%m-%d-%H`
hour=`date -d "$diff hours ago" -u +%H`
date=`date -d "$diff hours ago" -u +%y%m%d%H`
dbdate=`date -d "$diff hours ago" -u +%Y%m%d%H`
#date=24102406
#hour=06
#wdir=2024-10-24-06
echo wrf dir $wdir $date $res

nfcst=84

#/usr/bin/perl $root/bin/wrf-table.pl -t$date -n $nfcst -r $res

# Create forecast xml file.

#/usr/bin/perl $root/bin/bc-fcst.pl -d $wdir -m wrf$res

# Initiate new db approach.

root=/home/caic/caic/rtsys/post/ptfcst-summary
python3.12 $root/bin/ptfcst.py --model wrf$res --time $dbdate
python3.12 $root/bin/ptfcst-summary.py --model wrf$res --time $dbdate

exit 0
