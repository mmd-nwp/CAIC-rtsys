#!/bin/sh

date=`date -u -d "24 hours ago" +%Y-%m-%d`
date=$date" 00:00"
data=/home/caic/caic/rtsys/obs

user=mtnweath
host=az1-ss105.a2hosting.com
port=7822

/usr/bin/mysqldump -u caic --password=steepndeep --insert-ignore --skip-add-drop-table --no-create-info --where="time>='$date' and (staname='STORM' or staname='TOWC2' or staname='DRLC2')" weather obsWX > $data/work/wx.sql
/usr/bin/scp -P $port -q $data/work/wx.sql $user@$host:ops/projects/powdercats/data/wx.sql
/usr/bin/ssh -p $port $user@$host /home/$user/ops/projects/powdercats/bin/sql.sh
/usr/bin/mysqldump -u caic --password=steepndeep --insert-ignore --skip-add-drop-table --no-create-info --where="time>='$date' and (staname='STORM' or staname='TOWC2' or staname='DRLC2')" weather obsHydro > $data/work/wx.sql
/usr/bin/scp -P $port -q $data/work/wx.sql $user@$host:ops/projects/powdercats/data/wx.sql
/usr/bin/ssh -p $port $user@$host /home/$user/ops/projects/powdercats/bin/sql.sh
/usr/bin/mysqldump -u caic --password=steepndeep --insert-ignore --skip-add-drop-table --no-create-info --where="time>='$date' and (staname='STORM' or staname='TOWC2' or staname='DRLC2')" weather obsSnow > $data/work/wx.sql
/usr/bin/scp -P $port -q $data/work/wx.sql $user@$host:ops/projects/powdercats/data/wx.sql
/usr/bin/ssh -p $port $user@$host /home/$user/ops/projects/powdercats/bin/sql.sh

/usr/bin/scp -P $port -q $data/data/cmc/cmc_base/1-hour.dat $user@$host:ops/projects/cmc/data/study.dat
/usr/bin/scp -P $port -q $data/data/cmc/cmc_ridge/1-hour.dat $user@$host:ops/projects/cmc/data/ridge.dat

data=/home/caic/caic/rtsys/obs/data
/usr/bin/scp -P $port -q $data/csas/csas_putney/1-hour.dat $user@$host:ops/projects/helitrax/data/putney.dat
/usr/bin/scp -P $port -q $data/caic/kendall/1-hour.dat $user@$host:ops/projects/helitrax/data/kendall.dat
/usr/bin/scp -P $port -q $data/caic/abrams/1-hour.dat $user@$host:ops/projects/helitrax/data/abrams.dat
/usr/bin/scp -P $port -q $data/telluride_ski_area/telluride_ski_area_phq/1-hour.dat $user@$host:ops/projects/helitrax/data/tride_phq.dat
/usr/bin/scp -P $port -q $data/telluride_ski_area/telluride_ski_area_dynamo/1-hour.dat $user@$host:ops/projects/helitrax/data/dynamo.dat
/usr/bin/scp -P $port -q $data/cs_irwin/irwin_study_plot/1-hour.dat $user@$host:ops/projects/irwin/data/irwin.dat
/usr/bin/scp -P $port -q $data/cs_irwin/irwin_scarp_ridge/1-hour.dat $user@$host:ops/projects/irwin/data/scarp.dat

user=nwpconsu
host=s1103.usc1.mysecurecloudhost.com
port=22

data=/home/caic/caic/rtsys/obs/data
/usr/bin/scp -P $port -q $data/csas/csas_putney/1-hour.dat $user@$host:ops/projects/helitrax/data/putney.dat
/usr/bin/scp -P $port -q $data/caic/kendall/1-hour.dat $user@$host:ops/projects/helitrax/data/kendall.dat
/usr/bin/scp -P $port -q $data/caic/abrams/1-hour.dat $user@$host:ops/projects/helitrax/data/abrams.dat
/usr/bin/scp -P $port -q $data/telluride_ski_area/telluride_ski_area_phq/1-hour.dat $user@$host:ops/projects/helitrax/data/tride_phq.dat
/usr/bin/scp -P $port -q $data/telluride_ski_area/telluride_ski_area_dynamo/1-hour.dat $user@$host:ops/projects/helitrax/data/dynamo.dat
/usr/bin/scp -P $port -q $data/cs_irwin/irwin_study_plot/1-hour.dat $user@$host:ops/projects/irwin/data/irwin.dat
/usr/bin/scp -P $port -q $data/cs_irwin/irwin_scarp_ridge/1-hour.dat $user@$host:ops/projects/irwin/data/scarp.dat

exit 0
