#!/bin/sh

file1=$1
file2=rip.tmp

cat $file1 | \
sed 's/12km Conus/Conus 12km/' \
> $file2

mv rip.tmp $1

exit 0
