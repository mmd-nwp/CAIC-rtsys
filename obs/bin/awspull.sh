#!/bin/sh

cd /home/caic/caic/rtsys/obs
ip=34.210.251.168

aws=/var/opt/CampbellSci/LoggerNet/data
/usr/bin/rsync -arv --rsh='ssh' --delay-updates snook@$ip:$aws .

aws=/var/opt/CampbellSci/LoggerNet/images
/usr/bin/rsync -arv --rsh='ssh' --delay-updates snook@$ip:$aws .

exit 0
