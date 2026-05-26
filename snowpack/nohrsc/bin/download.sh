#!/bin/sh

month=`date -u +%h`
mm=`date -u +%m`
year=`date -u +%Y`
day=`date -u +%d`
webdate=`date -u +%y%j`
#month=Nov
#mm=11
#year=2025
#day=02
#webdate=25306

. /home/intel/oneapi/setvars.sh

data=/home/caic/caic/rtsys/snowpack/nohrsc/data
cdfdir=/data/noaaport/grids/nohrsc/netcdf

while [ ${#day} -lt 2 ]; do day="0$day"; done
cd $data/tar
#wget ftp://sidads.colorado.edu/DATASETS/NOAA/G02158/masked/$year/$mm"_$month/SNODAS_$year$mm$day.tar"
#tar xvf SNODAS_$year$mm$day.tar
#file=us_ssmv11036tS__T0001TTNATS$year$mm$day"05HP001"
file=SNODAS_unmasked_$year$mm$day.tar
wget -O $file ftp://sidads.colorado.edu/DATASETS/NOAA/G02158/unmasked/$year/$mm"_$month/$file"
tar xvf $file
file=zz_ssmv11036tS__T0001TTNATS$year$mm$day"05HP001"
gunzip $file.dat
mv $file.dat ../work
#rm us*
rm zz*

cd ../work
#ln -fs master.hdr $file.hdr
#/usr/local/bin/gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs' -a_nodata -9999 -a_ullr -124.73333333333333 52.87500000000000 -66.94166666666667 24.95000000000000 $file.dat $cdfdir/$year$mm$day.nc
ln -fs master-unmasked.hdr $file.hdr
/usr/local/bin/gdal_translate -of NetCDF -a_srs '+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs' -a_nodata -9999 -a_ullr -130.516666666661 58.2333333333310 -62.2499999999975 24.0999999999990 $file.dat $cdfdir/$year$mm$day.nc
rm $file.*

perl /home/caic/caic/rtsys/snowpack/nohrsc/bin/nohrsc2db.pl 

# Generate json file for model dashboard web site. [Now generated in the master snowpack script]

#python3.12 /home/caic/caic/rtsys/snowpack/nohrsc/bin/nohrsc-json.py << endin
#$webdate
#endin

exit 0
