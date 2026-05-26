#!/bin/sh

year=25
month=12
day=1
res=bsu

while [ $day -lt 22 ]; do
  while [ ${#day} -lt 2 ]; do day="0$day"; done
  date=$year$month$day
  echo $date
  perl nohrsc2db.pl -d $date -r $res
  day=`expr $day + 1`
done
exit 0

month=12
day=1

while [ $day -lt 32 ]; do
  while [ ${#day} -lt 2 ]; do day="0$day"; done
  date=$year$month$day
  echo $date
  perl nohrsc2db.pl -d $date -r $res
  day=`expr $day + 1`
done

year=25
month=01
day=1

while [ $day -lt 32 ]; do
  while [ ${#day} -lt 2 ]; do day="0$day"; done
  date=$year$month$day
  echo $date
  perl nohrsc2db.pl -d $date -r $res
  day=`expr $day + 1`
done

month=02
day=1

while [ $day -lt 30 ]; do
  while [ ${#day} -lt 2 ]; do day="0$day"; done
  date=$year$month$day
  echo $date
  perl nohrsc2db.pl -d $date -r $res
  day=`expr $day + 1`
done

month=03
day=1

while [ $day -lt 32 ]; do
  while [ ${#day} -lt 2 ]; do day="0$day"; done
  date=$year$month$day
  echo $date
  perl nohrsc2db.pl -d $date -r $res
  day=`expr $day + 1`
done

month=04
day=1

while [ $day -lt 31 ]; do
  while [ ${#day} -lt 2 ]; do day="0$day"; done
  date=$year$month$day
  echo $date
  perl nohrsc2db.pl -d $date -r $res
  day=`expr $day + 1`
done

exit 0

month=05
day=1

while [ $day -lt 32 ]; do
  while [ ${#day} -lt 2 ]; do day="0$day"; done
  date=$year$month$day
  echo $date
  perl nohrsc2db.pl -d $date
  day=`expr $day + 1`
done

exit 0
