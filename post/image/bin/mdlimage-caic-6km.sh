#!/bin/sh

domain=$1
res=$2
model=$3
mdllabel=`echo $model | tr '[:lower:]' '[:upper:]'`
if [ $model == "nam" ] || [ $model == "gfs" ]; then
  mdllabel="NCEP "$mdllabel
else
  mdllabel="CAIC "$mdllabel" "$res" Domain"
fi

root=/home/caic/caic/rtsys/post/image
export RIP_ROOT=$root/rip4.6.2
export NCARG_ROOT=/usr
mdldir=/model/$domain/$res/$model
imgdir=/web/$domain/$res/$model/forecasts
#imgdir=/net/hail/home/www/html/caic/nwp/image/$res/$model/forecasts
#haildir=/home/www/html/caic/nwp/image/$res/$model/forecasts

date=$4
grid=1
fcst=$5
mdlfcst=$fcst
imgfcst=$fcst
webdate=$6

sfcst12=$fcst;
if [ $sfcst12 -ge 12 ]; then
    sfcst12=12;
fi

pfcst24=$fcst;
if [ $pfcst24 -ge 24 ]; then
    pfcst24=24;
fi

pfcst48=$fcst;
if [ $pfcst48 -ge 48 ]; then
    pfcst48=48;
fi

imgdir=$imgdir/$webdate
#haildir=$haildir/$webdate
/bin/mkdir -p $imgdir

if [ $fcst -lt 10 ] 
then
   mdlfcst="00"$mdlfcst
   imgfcst="0"$imgfcst
elif [ $fcst -lt 100 ] 
then
   mdlfcst="0"$mdlfcst
fi
mdlfcst=$mdlfcst"00"
imgfcst=$imgfcst"00"

# Create RIP files.

workdir=$root/work/model/$domain/$res/$model/$webdate/$fcst
/bin/mkdir -p $workdir
cd $workdir
rm -f caic_* rip.cgm gmeta*

# Run rip data prep.

cat $root/namelist/ripdp.in | sed s/FCST/$fcst/g > ripdp.in

if [ $model == "wrf" ]; then
   filefcst=`expr $fcst + 1`
   filefcst="$"$filefcst
   file=`ls -mw 999999 $mdldir/$date/wrfout_d0$grid* | awk -F, {print$filefcst}`
   $RIP_ROOT/ripdp_wrfarw -n ripdp.in caic all $file
elif [ $model == "nam" ] || [ $model == "gfs" ]; then
  ripfcst=$fcst
  while [ ${#ripfcst} -lt 4 ]; do ripfcst="0$ripfcst"; done
  cp $root/namelist/$domain/$res/laps.minfo caic.minfo
  echo "            1" > caic.xtimes
  echo $ripfcst."00000" >> caic.xtimes
  cp $root/namelist/$domain/$res/laps_0000.00000_dmap caic_$ripfcst."00000_dmap"
  cp $root/namelist/$domain/$res/laps_0000.00000_xmap caic_$ripfcst."00000_xmap"
  cp $root/namelist/$domain/$res/laps_0000.00000_cor caic_$ripfcst."00000_cor"
else
   $RIP_ROOT/ripdp_$model -n ripdp.in caic `ls $mdldir/$date/fcst*.$mdlfcst.g$grid`
fi

$root/bin/mdl2rip.sh $domain $res $model $date $fcst

# Create wind barbs.

prodname=mdlbarb
prod="001"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert +transparent black - gmeta.png

g=2
cp gmeta.png $imgdir/$imgfcst-S-g$g-$prod.png

# Create temp images.

prodname=mdltemp
prod="002"

if [ $model == "wrf" ]; then
  cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
else
  cat $root/namelist/$domain/$res/$prodname.ncep | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
fi
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
cp gmeta.png $imgdir/$imgfcst-S-g$g-$prod.png

# Create wind images.

prodname=mdlwind
prod="003"
prod2="004"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
ct=0
ndomain=1
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  ct2=`expr $ct + $ndomain`
  cp gmeta-$ct2.png $imgdir/$imgfcst-S-g$g-$prod2.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create precip images.

prodname=mdlprecip
prod="005"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
cp gmeta.png $imgdir/$imgfcst-S-g$g-$prod.png

# Create 12-h snowfall accumulation images.

prodname=mdlsnow12
prod="006"

cat $root/namelist/$domain/$res/$prodname | sed s/PFCST/$sfcst12/g | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
cp gmeta.png $imgdir/$imgfcst-S-g$g-$prod.png

# Create snow images.

prodname=mdlsnow
prod="007"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
cp gmeta.png $imgdir/$imgfcst-S-g$g-$prod.png

# Create radar images.

prodname=mdlradar
prod="008"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
cp gmeta.png $imgdir/$imgfcst-S-g$g-$prod.png

# Create freezing level images.

prodname=mdlfrz
prod="009"
prod2="010"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
ct=0
ndomain=1
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  ct2=`expr $ct + $ndomain`
  cp gmeta-$ct2.png $imgdir/$imgfcst-S-g$g-$prod2.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create upper air wind barbs.

prodname=mdlbarbupa
prod="001"
prod2="002"
prod3="003"
prod4="004"
prod5="005"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert +transparent black - gmeta.png

g=2
ct=0
ndomain=1
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-U-g$g-$prod.png
  ct2=`expr $ct + $ndomain`
  cp gmeta-$ct2.png $imgdir/$imgfcst-U-g$g-$prod2.png
  ct3=`expr $ct2 + $ndomain`
  cp gmeta-$ct3.png $imgdir/$imgfcst-U-g$g-$prod3.png
  ct4=`expr $ct3 + $ndomain`
  cp gmeta-$ct4.png $imgdir/$imgfcst-U-g$g-$prod4.png
  ct5=`expr $ct4 + $ndomain`
  cp gmeta-$ct5.png $imgdir/$imgfcst-U-g$g-$prod5.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create upper air images.

prodname=mdlupa
prod="004"
prod2="005"
prod3="006"
prod4="007"
prod5="008"
prod6="009"
prod7="010"
prod8="011"
prod9="012"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x875' -window 0.0:0.125:1.0:1.0 gmeta | /usr/bin/convert - gmeta.png

g=2
ct=0
ndomain=1
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-U-g$g-$prod.png
  ct2=`expr $ct + $ndomain`
  cp gmeta-$ct2.png $imgdir/$imgfcst-U-g$g-$prod2.png
  ct3=`expr $ct2 + $ndomain`
  cp gmeta-$ct3.png $imgdir/$imgfcst-U-g$g-$prod3.png
  ct4=`expr $ct3 + $ndomain`
  cp gmeta-$ct4.png $imgdir/$imgfcst-U-g$g-$prod4.png
  ct5=`expr $ct4 + $ndomain`
  cp gmeta-$ct5.png $imgdir/$imgfcst-U-g$g-$prod5.png
  ct6=`expr $ct5 + $ndomain`
  cp gmeta-$ct6.png $imgdir/$imgfcst-U-g$g-$prod6.png
  ct7=`expr $ct6 + $ndomain`
  cp gmeta-$ct7.png $imgdir/$imgfcst-U-g$g-$prod7.png
  ct8=`expr $ct7 + $ndomain`
  cp gmeta-$ct8.png $imgdir/$imgfcst-U-g$g-$prod8.png
  ct9=`expr $ct8 + $ndomain`
  cp gmeta-$ct9.png $imgdir/$imgfcst-U-g$g-$prod9.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

rm -rf $workdir

exit 0
