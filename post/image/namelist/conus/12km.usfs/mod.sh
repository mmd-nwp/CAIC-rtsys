#!/bin/sh

file1=$1
file2=rip.tmp

cat $file1 | \
sed 's/8km/Conus 12km/' | \
sed 's/xwin=1,488; ywin=1,488/xwin=1,400; ywin=1,300/' | \
sed 's/crsa=1.5,1.5; crsb=335.5,335.5/crsa=1.5,1.5; crsb=399.5,299.5/'  \
> $file2

mv rip.tmp $1

exit 0
