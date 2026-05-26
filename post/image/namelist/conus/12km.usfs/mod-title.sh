#!/bin/sh

file1=$1
file2=rip.tmp

cat $file1 | \
sed 's/USFS //' \
> $file2

mv $file2 $file1

exit 0
