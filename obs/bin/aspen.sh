#!/bin/sh

home=/home/caic/caic/rtsys/obs/provider/aspen

cd $home/data

wget --no-dns-cache -d -O highlands.txt https://weather.aspensnowmass.com/HIGHLANDS-SUMMARY.HTM
wget --no-dns-cache -d -O snowmass.txt https://weather.aspensnowmass.com/SNOWMASS-SUMMARY.HTM
wget --no-dns-cache -d -O aspen.txt https://weather.aspensnowmass.com/ASPEN-SUMMARY.HTM

perl $home/highlands.pl
perl $home/snowmass.pl
perl $home/ajax.pl

exit 0
