#!/bin/sh

python=python3
perl=/usr/bin/perl
root=/home/caic/caic/rtsys/obs/bin

home=/home/caic/caic/rtsys/obs/provider/snotel
$python $home/wx.py
$python $home/precip.py
$python $home/snow.py
$python $home/swe.py

$perl $root/snow-qc.pl

exit 0
