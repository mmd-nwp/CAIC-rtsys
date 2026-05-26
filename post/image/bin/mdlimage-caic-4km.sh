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

date=$4
grid=2
fcst=$5
mdlfcst=$fcst
imgfcst=$fcst
webdate=$6
startg=11

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
$NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert +transparent black - gmeta.png

g=$startg
ct=0
ndomain=6
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create temp images.

prodname=mdltemp
prod="002"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert - gmeta.png

g=$startg
ct=0
ndomain=6
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create wind images.

prodname=mdlwind
prod="003"
prod2="004"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert - gmeta.png

g=$startg
ct=0
ndomain=6
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  ct2=`expr $ct + $ndomain`
  cp gmeta-$ct2.png $imgdir/$imgfcst-S-g$g-$prod2.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create total precip images.

prodname=mdlprecip
prod="005"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert - gmeta.png

g=$startg
ct=0
ndomain=6
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create 12-h snowfall accumulation.

prodname=mdlsnow12
prod="006"

cat $root/namelist/$domain/$res/$prodname | sed s/PFCST/$sfcst12/g | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert - gmeta.png

g=$startg
ct=0
ndomain=6
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Create total snowfall accumulation.

prodname=mdlsnow
prod="007"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert - gmeta.png

g=$startg
ct=0
ndomain=6
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

# Radar.

if [ $model == "wrf" ]; then

  prodname=mdlradar
  prod="008"

  cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
  $RIP_ROOT/rip caic rip

  /bin/rm -f gmeta*
  mv rip.cgm gmeta
  $NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert - gmeta.png

  g=$startg
  cp gmeta.png $imgdir/$imgfcst-S-g$g-$prod.png

fi

# Freezing level.

prodname=mdlfrz
prod="009"
prod2="010"

cat $root/namelist/$domain/$res/$prodname | sed s/FCST/$fcst/g | sed s/LABEL/"$mdllabel"/ > rip.in
$RIP_ROOT/rip caic rip

/bin/rm -f gmeta*
mv rip.cgm gmeta
$NCARG_ROOT/bin/ctrans -d sun -res '1000x1000' gmeta | /usr/bin/convert - gmeta.png

g=$startg
ct=0
ndomain=1
while [ $ct -lt $ndomain ]; do
  cp gmeta-$ct.png $imgdir/$imgfcst-S-g$g-$prod.png
  ct2=`expr $ct + $ndomain`
  cp gmeta-$ct2.png $imgdir/$imgfcst-S-g$g-$prod2.png
  g=`expr $g + 1`
  ct=`expr $ct + 1`
done

rm -rf $workdir

exit 0
