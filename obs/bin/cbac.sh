#!/bin/sh

home=/home/caic/caic/rtsys/obs/provider/cbac

cd $home/data

wget -O carbonate.txt https://datagarrison.com/users/350344984569051/300534066096200/temp/300534066096200_live.txt

cd $home

perl $home/carbonate.pl -l 24

perl /home/caic/caic/rtsys/obs/bin/obspost.pl -s 24 -o CACBH

exit 0
