#!/bin/sh

root=/home/caic/caic/rtsys

# Purge wrf model runs.

#perl $root/bin/mdlpurge.pl -p-15 -d/model/caic/4km/wrf
#perl $root/bin/mdlpurge.pl -p-15 -d/model/caic/2km/wrf
perl $root/bin/mdlpurge.pl -p-7 -d/model/caic/4km/nam

# Purge NCEP model directories.

perl $root/bin/nceppurge.pl -p3 -m hrrr
perl $root/bin/nceppurge.pl -p3 -m nam
perl $root/bin/nceppurge.pl -p3 -m gfs
perl $root/bin/nceppurge.pl -p2 -m blend
perl $root/bin/nceppurge.pl -p2 -m blend -f netcdf

# Purge web interactive point forecast grids.

rm -f `find /home/www/html/iptfcst/grids/* -mtime +4`
rm -rf `find /data/iptfcst -maxdepth 1 -type d -mtime +1`

# CAIC WRF web products.

perl $root/bin/webpurge.pl -p-7 -d/web/caic/12km/wrf/forecasts
perl $root/bin/webpurge.pl -p-7 -d/web/caic/4km/wrf/forecasts
perl $root/bin/webpurge.pl -p-7 -d/web/caic/4km/wrf/points
perl $root/bin/webpurge.pl -p-7 -d/web/caic/4km/wrf/xsec
perl $root/bin/webpurge.pl -p-7 -d/web/caic/4km/wrf/sndg

perl $root/bin/webpurge.pl -p-7 -d/web/caic/6km/wrf/forecasts
perl $root/bin/webpurge.pl -p-7 -d/web/caic/2km/wrf/forecasts
perl $root/bin/webpurge.pl -p-7 -d/web/caic/2km/wrf/points
perl $root/bin/webpurge.pl -p-7 -d/web/caic/2km/wrf/xsec
perl $root/bin/webpurge.pl -p-7 -d/web/caic/2km/wrf/sndg

# CAIC 12km and 4km NAM and GFS web products.

perl $root/bin/webpurge.pl -p-7 -d/web/caic/12km/nam/forecasts
perl $root/bin/webpurge.pl -p-7 -d/web/caic/4km/nam/forecasts
perl $root/bin/webpurge.pl -p-7 -d/web/caic/12km/nam/points
perl $root/bin/webpurge.pl -p-7 -d/web/caic/12km/nam/xsec
perl $root/bin/webpurge.pl -p-7 -d/web/caic/12km/nam/sndg
perl $root/bin/webpurge.pl -p-7 -d/web/caic/12km/gfs/forecasts

# LAPS directory purge.

perl $root/bin/lapspurge.pl -t 1 /model/caic/4km/laps/lapsprd
perl $root/bin/lapspurge.pl -t 1 /model/caic/12km/laps/lapsprd
perl $root/bin/lapspurge.pl -t 1 /model/caic/2km/laps/lapsprd
perl $root/bin/lapspurge.pl -t 1 /model/caic/6km/laps/lapsprd
perl $root/bin/lapspurge.pl -t 1 /model/conus/12km/laps/lapsprd

exit 0
