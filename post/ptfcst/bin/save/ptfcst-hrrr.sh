#!/bin/sh

root=/home/caic/caic/rtsys/post/ptfcst-summary
date=`date -u -d "1 hour ago" +%Y%m%d%H`
python3.12 $root/bin/ptfcst.py --model hrrr --time $date
python3.12 $root/bin/ptfcst-summary.py --model hrrr --time $date

exit 0
