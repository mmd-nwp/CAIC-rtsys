#!/bin/sh

export NCARG_ROOT=/usr/local
export setenv NCARG_LIB=$NCARG_ROOT/lib

mdir=/model/caic/4km/wrf
rundate=current
#rundate=163050600

if [ $rundate == "current" ]; then
  rundate=`ls -al $mdir/current | awk -F"> " '{print $2}'`
fi
mdir=$mdir/$rundate

date=`ls $mdir/wrfout_d01_* | awk -Fd01_20 '{ print $2 }'`
set -- $date
date=$1
ymd=`echo $date | awk -F_ '{ print $1 }'`
year=20`echo $ymd | awk -F- '{ print $1 }'`
month=`echo $ymd | awk -F- '{ print $2 }'`
day=`echo $ymd | awk -F- '{ print $3 }'`
ymd=`echo $date | awk -F: '{ print $1 }'`
hour=`echo $ymd | awk -F_ '{ print $2 }'`
webdate=$year-$month-$day-$hour"00"
timdate=$year-$month-$day" $hour:00"
echo $timdate

itime=`date -d "$timdate" +%s`

sdir=$mdir/sndg
wdir=/web/caic/4km/wrf/sndg/$webdate

ptfile=$mdir/ptfcst/ptfcst.txt

stns=`ls $sdir/*_sndg_000.txt | awk -F_sndg '{ print $1 }' | awk -Fsndg\/ '{ print $2 }'`

for stn in $stns; do
  ptname=`grep $stn $ptfile | awk '{ print substr($0,34) }' | sed -e 's/[[:space:]]*$//'`
  echo $stn $ptname

  fcst=0
  while [ $fcst -lt 85 ]; do
    f=$fcst
    sec=`expr $f \* 3600`
    vtime=`expr $itime + $sec`
    valtime=`date -d @$vtime "+%H00 %Z, %a, %b %d, %Y"`
    while [ ${#fcst} -lt 3 ]; do fcst="0$fcst"; done
    file=$stn"_sndg_"$fcst
    rm -f sndg.txt
    /bin/ln -fs $sdir/$file.txt sndg.txt
    $NCARG_ROOT/bin/ncl STN=\""$ptname"\" FCST=\""$f"\" VAL=\""$valtime"\" sndg.ncl
    convert skewt.png -resize 800x800 skewt.png
    mv skewt.png $wdir/$file.png
    fcst=`expr $fcst + 1`
  done
done

exit 0
