#!/bin/sh

wget=/usr/bin/wget
wgrib2=/usr/bin/wgrib2

grbdir=/data/noaaport/grids/ndfd/grib2
ptfcst=/home/caic/caic/rtsys/post/ptfcst
domain=conus

cd $grbdir/period1

$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.maxt.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.mint.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.temp.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.td.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.rhm.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.wdir.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.wspd.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.wgust.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.qpf.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.snow.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.001-003/ds.sky.bin

cd $grbdir/period2

$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.maxt.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.mint.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.temp.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.td.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.rhm.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.wdir.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.wspd.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.wgust.bin
$wget -nv -nd -m ftp://tgftp.nws.noaa.gov/SL.us008001/ST.opnl/DF.gr2/DC.ndfd/AR.$domain/VP.004-007/ds.sky.bin

cd $grbdir
cat period1/* period2/* > ndfd.grb2

# Generate point forecasts.

$ptfcst/bin/ptfcst.sh ndfd
$ptfcst/bin/iptfcst-ndfd.sh

exit 0
