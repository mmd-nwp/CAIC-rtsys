#!/bin/sh

root=/home/caic/caic/rtsys/obs/bin
perl=/usr/bin/perl

$perl $root/daily-obs.pl
$perl $root/snow-qc.pl

exit 0
