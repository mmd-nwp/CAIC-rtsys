#!/bin/sh

# Set options.
#  1) Process forecast (0=no, 1=yes, default=yes)
#  2) Date (Default=current)

fcst=1
now=`date -u +%Y-%m-%d`
if [ $# -ge 1 ]; then
  fcst=$1
  if [ $# -eq 2 ]; then
    now=$2
  fi
fi
year=`date -u -d "$now -7 months" "+%Y"`
webdate=`date -u -d $now +%y%j`

home=/home/caic/caic/rtsys
mail=$home/mail/bin
nohrsc=$home/snowpack/nohrsc/bin
root=$home/snowpack/runs
cd $root/wrf/bin

#  Download and process the NOHRSC HS file.

hstime=`date -u +%Y%m%d -d "$now"`
hsfile=/data/noaaport/grids/nohrsc/netcdf/$hstime.nc

if [ ! -e $hsfile ]; then
  $nohrsc/download.sh
fi

# Check that the HS file was procesed.

elapsed=0
freq_check=300
time_out=21600  # 6 hours
while [ ! -e $hsfile ]; do
  sleep $freq_check
  $nohrsc/download.sh
  if [ $elapsed -gt $time_out ]; then
    echo Missing NOHRSC HS file: $hsfile
    $mail/sp-failure.sh
    exit 1
  fi
  elapsed=`expr $elapsed + $freq_check`
done

# Generate NOHRSC JSON file for model dashboard website.

python3.12 $nohrsc/nohrsc-json.py << endin
$webdate
endin

# Check that all four WRF snowpack files are available.

sp=/home/snowpack/wrf/2km/$year

date=`date -u -d "$now 1 day ago" "+%y%j"`

files=`ls -al $sp/$date"1200"/snowpack* | wc -l`
echo WRF date: $date"1200"  Files= $files
if [ $files -lt 3 ]; then
  echo Not enough WRF SP files.
  $mail/sp-failure.sh
  exit 1
fi

files=`ls -al $sp/$date"1800"/snowpack* | wc -l`
echo WRF date: $date"1800"  Files= $files
if [ $files -lt 3 ]; then
  echo Not enough WRF SP files.
  $mail/sp-failure.sh
  exit 1
fi

date=`date -u +%y%j -d "$now"`

files=`ls -al $sp/$date"0000"/snowpack* | wc -l`
echo WRF date: $date"0000"  Files= $files
if [ $files -lt 3 ]; then
  echo Not enough WRF SP files.
  $mail/sp-failure.sh
  exit 1
fi

files=`ls -al $sp/$date"0600"/snowpack* | wc -l`
echo WRF date: $date"0600"  Files= $files
if [ $files -lt 3 ]; then
  echo Not enough WRF SP files.
  $mail/sp-failure.sh
  exit 1
fi

# Assemble WRF data for the past 24 hours.

date=`date`
echo WRF: $date
$root/wrf/bin/wrf2sp.sh $fcst $now

# Check that last time of smet file is correct.

#sptime=`sed -n '15,15p' input/zone002/101336/101336.smet | awk '{print $1}'`
sptime=`tail -n 1 output/zone003/100977/100977_res.smet | awk '{print $1}'`
chktime=`date -u -d "$now 1 days ago" "+%Y-%m-%d"`T12:00:00

if [ $sptime != $chktime ]; then
  echo SP smet data time mismatch:
  echo "  "SP  time: $sptime
  echo "  "CHK time: $chktime
  $mail/sp-failure.sh
  exit 1
fi

# Merge WRF forecasts with NOHRSC HS data and output as SP format met files.

date=`date`
echo Merge: $date
python3.12 $root/wrf/bin/wrf+hs.py -d $now

status=$?

if [ $status -ne 0 ]; then
  echo Bad status returned from WRF+HS.
  echo SP update will not run.
  $mail/sp-failure.sh
  exit 1
fi

# If successful, then update SP profiles.

date=`date`
echo Snowpack: $date
cd /ssd/snowpack
./run_snowpack.sh $now

# Upload SP nowcast files to AWS

/ssd/snowpack/bin/sp-now-sync.sh &

if [ $fcst -eq 1 ]; then

  date=`date`
  echo Snowpack forecast: $date
  cd /ssd/snowpack
  ./fcst_snowpack.sh $now

# Upload SP forecast files to AWS

  /ssd/snowpack/bin/sp-fcst-sync.sh &

fi

# Check that all SP profiles completed.

cd config
msg=`check.sh $year | wc -l`

if [ $msg -gt 0 ]; then
  echo Some SP profiles did not complete.
  check.sh $year
  $mail/sp-failure.sh
  exit 1
fi

now=`date`
echo Snowpack finished: $now
$mail/sp-success.sh

# Update stability parameters into database.

#perl $root/post/bin/fillstab.pl 

# Generate json files for website.

sptime=`date -u -d "$now" "+%y%m%d"`
perl $root/post/bin/spstab.pl -d $sptime"12"
perl $root/post/bin/spfcst.pl -d $sptime

# Generate Ron's hazard prediction json files.

cd /home/ron/forecasting_models
./src/run_predictions.sh

# Merge log files.

cd /ssd/snowpack/bin
./log-merge.sh $year

exit 0
