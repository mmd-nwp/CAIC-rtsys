#!/bin/sh

root=/home/caic/caic/rtsys/obs/provider/snocountry

wget -O $root/data/snowreport.json "http://feeds.snocountry.net/getSnowReport.php?apiKey=caic672.ava154&states=co"

/usr/bin/perl $root/snowreport.pl

exit 0
