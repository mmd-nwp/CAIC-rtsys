#!/bin/sh

if [ ! -t 0 ]; then
  source /opt/intel/oneapi/setvars.sh
fi

root=/home/caic/caic/rtsys
pdir=$root/post/ptfcst
pfile=$pdir/namelist/ptfcst.txt
date=`date -u -d "1 hour ago" +%y%j%H00`
data=`date -u -d "1 hour ago" +%Y-%m-%d-%H`
hour=`date -u -d "1 hour ago" +%H`
diff=`expr $hour % 6`
#date=250381500
#data=2025-02-07-15

# Download NBM grids.

perl $root/download/bin/model_download.pl -m nbm -p 1

# Convert NBM grib2 files to netcdf.
 
nbm=/data/noaaport/grids/blend
cd $nbm/netcdf

fcst=1
while [ $fcst -le 36 ]; do
  prevfcst=`expr $fcst - 1`
  prevfcst=$prevfcst-$fcst
  while [ ${#fcst} -lt 4 ]; do fcst="0$fcst"; done
  file=$date$fcst
  wgrib2 ../grib2/$file -match_fs TMP:2 -not_fs APTMP -not_fs ens -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs WIND:10 -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs WDIR:10 -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs GUST:10 -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs TCDC:surface -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs APCP -not_fs prob -not_fs level -not_fs $prevfcst -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs ASNOW -not_fs prob -not_fs level -not_fs $prevfcst -append -nc3 -netcdf $file.nc
  fcst=`expr $fcst + 1`
done

fcst=39
while [ $fcst -le 84 ]; do
  prevfcst=`expr $fcst - 1`
  prevfcst=$prevfcst-$fcst
  while [ ${#fcst} -lt 4 ]; do fcst="0$fcst"; done
  file=$date$fcst
  wgrib2 ../grib2/$file -match_fs TMP:2 -not_fs APTMP -not_fs ens -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs WIND:10 -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs WDIR:10 -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs GUST:10 -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs TCDC:surface -not_fs ens -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs APCP -not_fs prob -not_fs level -not_fs $prevfcst -append -nc3 -netcdf $file.nc
  wgrib2 ../grib2/$file -match_fs ASNOW -not_fs prob -not_fs level -append -nc3 -netcdf $file.nc
  fcst=`expr $fcst + 3`
done

# Parse gridded data into point forecast table.

mkdir -p $pdir/table/$data
$pdir/exe/ptfcst-nbm.exe << endin
$date
$pfile
$pdir/table/$data
endin

# Create forecast xml file.

#/usr/bin/perl $pdir/bin/xml-forecast.pl -d $data -m nbm
#/usr/bin/perl $pdir/bin/xml-forecast.pl -d $data -m nbm -z new
/usr/bin/perl $pdir/bin/bc-fcst.pl -d $data -m nbm

# Generate nbm forecast json files for model dashboard.

echo Generate web file $date

if [ $diff -eq 0 ]; then
  /home/caic/caic/rtsys/snowpack/runs/zones/post/bin/nbmfcst-json.sh $date
fi

# Initiate new db approach.

root=/home/caic/caic/rtsys/post/ptfcst-summary
date=`date -u -d "1 hour ago" +%Y%m%d%H`
python3.12 $root/bin/ptfcst.py --model nbm --time $date
python3.12 $root/bin/ptfcst-summary.py --model nbm --time $date

exit 0
