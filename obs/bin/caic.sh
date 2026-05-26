#!/bin/sh

root=/home/caic/caic/rtsys/obs
perl=/usr/bin/perl

# Copy loggernet files to web directory tree for weather stn monitor page.

#/home/caic/obs/bin/mon/pushmondata.sh &

# Pull data from AWS.

$root/bin/awspull.sh

# Fill db.

$perl $root/provider/caic/caic-obs.pl -s 6 

# Obs post-processing (Fill max/min temp and accumulated precip).

$perl $root/bin/obspost.pl -s 6 

exit 0
