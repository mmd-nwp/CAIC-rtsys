#!/bin/sh

res=4km
mail_dis="john@nwpconsultants.com"
if [ $# -eq 1 ]; then
  res=$1
  mail_dis="john@nwpconsultants.com,AlanH@a-basin.net,LouisS@a-basin.net,TimF@a-basin.net"
fi

root=/home/caic/caic/rtsys/post
mail=$root/ptfcst/bin/mail
pdir=/web/caic/$res/wrf/points/current

file=$pdir/FWAB.txt

echo "Subject: A-Basin $res forecast" | cat - $mail/mailheader.txt $file $mail/mailfooter.txt | /usr/sbin/sendmail -f john@nwpconsultants.com $mail_dis

exit 0
