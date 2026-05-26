#!/bin/sh

if [ $# -lt 3 ]; then
  echo "Usage:  sndg.sh 'fcst' 'model' 'res' ['rundate']"
  exit 1
fi

fcst=$1
model=$2
wres=$3

# Check if date (yyyjjjhhmm) is passed in.
# rundate=170641800

rundate=current
if [ $# -eq 4 ]; then
  rundate=$4
fi

export NCARG_ROOT=/usr
export setenv NCARG_LIB=$NCARG_ROOT/lib

sndg=/home/caic/caic/rtsys/post/sndg

mdir=/model/caic/$res/$model
if [ $model == "nam" ] || [ $model == "gfs" ]; then
  hour=`date -u -d "2 hours ago" +%H`
  diff=`expr $hour % 6`
  diff=`expr $diff + 2`
  rundate=`date -u -d "$diff hours ago" +%y%j%H00`
  res=12km
  mdir=/model/caic/$res/$model
else
  res=$wres
  mdir=/model/caic/$res/$model
  if [ $rundate == "current" ]; then
    rundate=`/bin/ls -al $mdir/current | awk -F"> " '{print $2}'`
  fi
fi
mdir=$mdir/$rundate

days1=31
days2=28
days3=31
days4=30
days5=31
days6=30
days7=31
days8=31
days9=30
days10=31
days11=30
days12=31

year=`expr $rundate / 10000000`
year=`expr $year + 2000`
day=`expr $rundate % 10000000`
day=`expr $day / 10000`
if [ `expr $year % 4` -eq 0 ]; then
   days2=29
fi
month=1
days=$(eval echo "\$days$month")
while [ $day -gt $days ]; do
   day=`expr $day - $days`
   month=`expr $month + 1`
   days=$(eval echo "\$days$month")
done
hour=`expr $rundate % 10000`
hour=`expr $hour / 100`
while [ ${#month} -lt 2 ]; do month="0$month"; done
while [ ${#day} -lt 2 ]; do day="0$day"; done
while [ ${#hour} -lt 2 ]; do hour="0$hour"; done
webdate=$year-$month-$day-$hour"00"
timdate=$year-$month-$day" $hour:00"
echo webdate $webdate

itime=`date -u -d "$timdate" +%s`

sdir=$mdir/sndg
wdir=/web/caic/$res/$model/sndg/$webdate

ptfile=$mdir/ptfcst/ptfcst.txt

stns=`/bin/ls $sdir/*_sndg_000.txt | awk -F_sndg '{ print $1 }' | awk -Fsndg\/ '{ print $2 }'`

mkdir -p $sndg/work/$res/$model/$fcst
cd $sndg/work/$res/$model/$fcst

echo "Working directory ===" `pwd`
echo "Date ===" `date`

umodel=`echo $model | awk '{ print toupper($1) }'`
for stn in $stns; do
  ptname=`grep " $stn " $ptfile | awk '{ print substr($0,34) }' | sed -e 's/[[:space:]]*$//'`
  echo $stn $ptname

  f=`expr $fcst \* 1`
  sec=`expr $f \* 3600`
  vtime=`expr $itime + $sec`
  valtime=`date -d @$vtime "+%H00 %Z, %a, %b %d, %Y"`
  while [ ${#fcst} -lt 3 ]; do fcst="0$fcst"; done
  file=$stn"_sndg_"$fcst
  /bin/rm -f sndg.txt
  /bin/ln -fs $sdir/$file.txt sndg.txt
  nline=`wc -l < sndg.txt`
  $NCARG_ROOT/bin/ncl STN=\""$ptname"\" FCST=\""$f"\" VAL=\""$valtime"\" MDL=\""$umodel"\" NLINE="$nline" $sndg/ncl/sndg.ncl > /dev/null 2>&1
  /usr/bin/convert skewt.png -resize 800x800 skewt.png
  /bin/mv skewt.png $wdir/$file.png
done
/bin/rm -f sndg.txt

echo "Working directory ===" `pwd`
echo "Finished ===" `date`

exit 0
