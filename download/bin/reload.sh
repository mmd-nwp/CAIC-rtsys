#!/bin/sh

# Remove and re-download NAM run.

if [ $# -lt 2 ]; then
  echo Usage: reload.sh date [yyyy-mm-dd hh]
  exit 1
fi

now=$1
hour=$2
now="$now $hour"

home=/home/caic/caic/rtsys/download
mdir=/data/noaaport/grids/nam/grib2

dldate=`date -u -d "$now" +%Y%m%d%H`
mdldate=`date -u -d "$now" +%y%j%H00`

# Check for download lock file.

lockfile=$home/lock/nam_download.lock
elapsed=0
freq_check=1
time_out=300
while [ -e $lockfile ]; do
  if [ $elapsed -gt $time_out ]; then
    echo Timeout waiting on lock file: $lockfile
    exit 1
  fi
  sleep $freq_check
  elapsed=`expr $elapsed + $freq_check`
done

rm -rf $mdir/$mdldate*
/usr/bin/perl $home/bin/model_download.pl -m nam -d $dldate

exit 0
