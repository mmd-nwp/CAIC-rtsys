#!/bin/sh

root=/home/caic/caic/rtsys/post/sndg/bin

fcst=3
while [ $fcst -le 84 ]; do
  $root/sndg.sh $fcst nam 12km &
  fcst=`expr $fcst + 3`
done

exit 0
