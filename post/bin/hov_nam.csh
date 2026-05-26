#!/bin/csh


#===============================================================================
#                            Version 1.0 (2007-01-04)
#                            ------------------------
# hov_nam - script to create Hovmoller diagrams 
# 
#===============================================================================

set script = hov_nam
setenv GADDIR /usr/local/lib/grads  # Font file directory.

# Make sure all required parameters are passed in.
if ( $# != 10 ) then 
   	echo ""
 	echo "Usage: $script YYYY MM DD HH hh WebGifs Model Domain Res"
 	echo "       Where YYYY    is 4 digits year -model start"
 	echo "             MM         2 digits month-model start"  
 	echo "             DD         2 digits day  -model start"
 	echo "             HH         2 digits hour -model start"
 	echo "             hh         2 model forecast hour"
 	echo "             thDate     th date"
 	echo "             WebGifs    Output directory"
 	echo "             Model      Model -mm5 or mff"
 	echo "             Domain     Domain westus or conus"
 	echo "             Res        Grid spacing -8km or 12km"
 	echo ""
 	exit
endif
  
# Consistence check (argument by argument) Not yet implemented!  

set postdir = /home/caic/caic/rtsys/post

set echo

# ======= set Model hours ===============================================
set combohr = ( 000 003 006 009 012 \
                015 018 021 024 027 \
                030 033 036 039 042 \
                045 048 051 054 057 \
                060 063 066 069 072 \
                075 078 081 084 )
# ========================================================================

set yr = $1
set mn = $2
set dy = $3
set hr = $4
set wrfhr = $5
set date = $6
set webdir = $7
set WEBGIFS = $webdir
set model = $8
set domain = $9
set res = $10

set mXXdir = /model/$domain/$res/$model/$date/timeht
set stationlist = $mXXdir/timeht.txt

# ------- define months ---------- #
if ( $mn == 01 ) set mnlet = jan
if ( $mn == 02 ) set mnlet = feb
if ( $mn == 03 ) set mnlet = mar
if ( $mn == 04 ) set mnlet = apr
if ( $mn == 05 ) set mnlet = may
if ( $mn == 06 ) set mnlet = jun
if ( $mn == 07 ) set mnlet = jul
if ( $mn == 08 ) set mnlet = aug
if ( $mn == 09 ) set mnlet = sep
if ( $mn == 10 ) set mnlet = oct
if ( $mn == 11 ) set mnlet = nov
if ( $mn == 12 ) set mnlet = dec
# ------------------------------- #

set stations = ` cat $stationlist | awk '{ print $2 }' `

if ( $stations[1] == "" ) then
 echo ERROR IN STATION FILE, EXIT
 exit
endif

foreach f ( $stations )

# ========== do Hovmoller diagrams ================ #

    # ====== create data file ========= #

rm -f ${f}_hov.gdat

@ xnum = $wrfhr / 3 + 1
set xcount = 0
LOOP:
@ xcount = $xcount + 1
if ( $xcount <= $xnum ) then
 cat $mXXdir/${f}_hov_$combohr[$xcount].gdat >> ${f}_hov.gdat
 goto LOOP
else
 goto GETOUT
endif 

GETOUT:

# ======== if less than 12-h, exit ========
if ( $wrfhr < 12 ) then

 goto SKIP

endif
 # ======== create control file =========== 
@ grhr = ${wrfhr} / 3 + 1

cat <<EOF > ${f}_hov.ctl
dset ./${f}_hov.gdat
options little_endian
undef -999999
*pdef  1  1 lcc  30.20716 -124.4856  1.  1.  45.  45. -114. 12500. 12500.
xdef  1 linear -126.31445 0.14846323
ydef  1 linear   30.19919 0.1101682
zdef  41 levels 1100 1075 1050 1025 1000 975 950 925 900 875 850 825 800 775 750 725 700 675 650 625 600 575 550 525 500 475 450 425 400 375 350 325 300 275 250 225 200 175 150 125 100
tdef $grhr linear ${hr}z${dy}${mnlet}${yr} 3hr
vars 6
thetae       41 99  equivalent potential temperature (K)
tempc        41 99  temperature (deg C)
u            41 99  zonal wind (m/s)
v            41 99  meridional wind (m/s)
omega        41 99  dP/dt (Pa/s)
rh           41 99  relative humidity (%)
endvars
EOF
 # ======= create GrADS script for PT ==============
if ( $wrfhr > 41 ) then
 @ barbpltu = 1
 @ barbpltv = 1
else if ( $wrfhr > 32 ) then
 @ barbpltu = 1
 @ barbpltv = 1
else if ( $wrfhr > 20 ) then
 @ barbpltu = 1
 @ barbpltv = 1
else if ( $wrfhr > 11 ) then
 @ barbpltu = 1
 @ barbpltv = 1
else if ( $wrfhr <= 11 ) then
 @ barbpltu = 1
 @ barbpltv = 1
endif

cat $mXXdir/${f}_xxx.plothov.exec.part1 $postdir/grads/plot_hov_pt.exec > plot_hov_pt_${f}.exec
set pngname = NAMHOVPT_${f}.png
cat <<EOF > comm.scr
'open ${f}_hov.ctl'
'set t 1 $grhr'
'exec plot_hov_pt_${f}.exec $barbpltu $barbpltv'
'set strsiz 0.15'
'draw title ${f}: 20${yr}-${mn}-${dy} ${hr}00 + ${wrfhr}h (NAM)'
'gxprint $pngname white'
'quit'
EOF
                                                                                                          
/usr/local/bin/grads -lbc 'comm.scr'

rm -f plot_hov_pt_${f}.exec
mv ${pngname} $WEBGIFS
chmod gu+w ${WEBGIFS}/${pngname}

 # ======= create GrADS script for PT ==============
cat $mXXdir/${f}_xxx.plothov.exec.part1 $postdir/grads/plot_hov_thetae.exec > plot_hov_thetae_${f}.exec
set pngname = NAMHOVEPT_${f}.png
cat <<EOF > comm.scr
'open ${f}_hov.ctl'
'set t 1 $grhr'
'exec plot_hov_thetae_${f}.exec'
'set strsiz 0.15'
'draw title ${f}: 20${yr}-${mn}-${dy} ${hr}00 + ${wrfhr}h (NAM)'
'gxprint $pngname white'
'quit'
EOF
                                                                                                              
/usr/local/bin/grads -lbc 'comm.scr'
                                                                                                              
rm -f plot_hov_thetae_${f}.exec
mv ${pngname} $WEBGIFS
chmod gu+w ${WEBGIFS}/${pngname}

SKIP:

rm -f *.gdat *.ctl *.scr

end

