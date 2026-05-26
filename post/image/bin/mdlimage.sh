#!/bin/sh

if [ $# -lt 5 ]; then
  echo "Usage:  mdlimage.sh 'domain' 'res' 'model' 'fcst' 'maxfcst' ['rundate']"
  exit 1
fi

domain=$1
res=$2
model=$3
fcst=$4
max_fcst=$5

rundate=current
#rundate=260060600
if [ $# -eq 6 ]; then
  rundate=$6
fi

if [ $model == "nam" ] || [ $model == "gfs" ]; then
  finc=3
else
  finc=1
fi

root=/home/caic/caic/rtsys/post
mdldir=/model/$domain/$res/$model/$rundate

if [ $rundate == current ]; then
  if [ $model == "nam" ] || [ $model == "gfs" ]; then
    hour=`date -u -d "2 hours ago" +%H`
    diff=`expr $hour % 6`
    diff=`expr $diff + 2`
    rundate=`date -u -d "$diff hours ago" +%y%j%H00`
  else
    rundate=`ls -al $mdldir | awk -F"> " '{print $2}'`
  fi
fi
echo $rundate

# Generate webdate from date.

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
echo webdate $webdate

#/bin/mkdir -p /web/$domain/$res/$model/forecasts/$webdate

fcst=`expr $fcst \* 1`
while [ $fcst -le $max_fcst ]; do
  $root/image/bin/mdlimage-$domain-$res.sh $domain $res $model $rundate $fcst $webdate

  if [ $model == "wrf" ] && [ $domain == "caic" ]; then
    r=`expr $fcst % 3`
    if [ $r -eq 0 ] && [ $res == "4km" ]; then
      $root/sndg/bin/sndg.sh $fcst $model $res $rundate &
    fi
    if [ $r -eq 0 ] && [ $res == "2km" ]; then
      $root/sndg/bin/sndg.sh $fcst $model $res $rundate &
    fi
  fi

  if [ $model == "nam" ]; then
    r=`expr $fcst % 3`
    if [ $r -eq 0 ] && [ $res == "12km" ] && [ $domain == "caic" ]; then
      $root/sndg/bin/sndg.sh $fcst $model $res $rundate &
    fi
  fi

  fcst=`expr $fcst + $finc`
done

exit 0
