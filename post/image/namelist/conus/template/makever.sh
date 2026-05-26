#!/bin/sh

# Define map backgrounds.

stmap="feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground"
ctymap="feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground\nfeld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground"

for args in \
"vertemp      # Surface temp bias." \
"vertd        # Surface dew point bias." \
"verrh        # Surface relative humidity bias." \
"verspd       # Surface wind speed bias." \
"vermocatemp  # Surface moca temp bias." \
"vermocatd    # Surface moca dew point bias."  \
"vermocarh    # Surface moca relative humidity bias." \
"vermocaspd   # Surface moca wind speed bias."
do
set $args

prod=$1
shift
prodname=$@
echo $prod $prodname

nl=namelist/$prod

area="flmin=.005, frmax=.92, fbmin=.20, ftmax=.95,"
cat $prod/$prod.top \
| sed "s/AREA/$area/" \
> $nl

echo $prodname >> $nl

domain=ConUS
corners="xwin=1,600; ywin=1,450; >"
box="feld=box; ptyp=hb; crsa=1.5,1.5; crsb=599.5,449.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/12/" \
| sed "s/RHCINT/10/" \
| sed "s/RHBEG/10/" \
| sed "s/RHEND/90/" \
| sed "s/RHSMTH/10/" \
| sed "s/TDCINT/10/" \
| sed "s/TDSMTH/10/" \
| sed "s/TPCINT/5/" \
| sed "s/TPSMTH/10/" \
| sed "s/CLDCINT/5/g" \
| sed "s/CLDEND/95/" \
| sed "s/SLPR/$slpr/" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titlslp/" \
| sed "s/MAP/$stmap/" \
| sed "s/RADAR/$stradar/" \
| sed "s/CLOUD/$stcloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.5,159.5; crsb=315.5,383.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/RHCINT/10/" \
| sed "s/RHBEG/10/" \
| sed "s/RHEND/90/" \
| sed "s/RHSMTH/10/" \
| sed "s/TDCINT/10/" \
| sed "s/TDSMTH/10/" \
| sed "s/TPCINT/5/" \
| sed "s/TPSMTH/10/" \
| sed "s/CLDCINT/5/g" \
| sed "s/CLDEND/95/" \
| sed "s/SLPR/$slpr/" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titlslp/" \
| sed "s/MAP/$stmap/" \
| sed "s/RADAR/$stradar/" \
| sed "s/CLOUD/$stcloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.5,16.5; crsb=331.5,252.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/RHCINT/10/" \
| sed "s/RHBEG/10/" \
| sed "s/RHEND/90/" \
| sed "s/RHSMTH/10/" \
| sed "s/TDCINT/10/" \
| sed "s/TDSMTH/10/" \
| sed "s/TPCINT/5/" \
| sed "s/TPSMTH/10/" \
| sed "s/CLDCINT/5/g" \
| sed "s/CLDEND/95/" \
| sed "s/SLPR/$slpr/" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titlslp/" \
| sed "s/MAP/$stmap/" \
| sed "s/RADAR/$stradar/" \
| sed "s/CLOUD/$stcloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.5,159.5; crsb=599.5,383.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/RHCINT/10/" \
| sed "s/RHBEG/10/" \
| sed "s/RHEND/90/" \
| sed "s/RHSMTH/10/" \
| sed "s/TDCINT/10/" \
| sed "s/TDSMTH/10/" \
| sed "s/TPCINT/5/" \
| sed "s/TPSMTH/10/" \
| sed "s/CLDCINT/5/g" \
| sed "s/CLDEND/95/" \
| sed "s/SLPR/$slpr/" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titlslp/" \
| sed "s/MAP/$stmap/" \
| sed "s/RADAR/$stradar/" \
| sed "s/CLOUD/$stcloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.5,16.5; crsb=573.5,264.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/RHCINT/10/" \
| sed "s/RHBEG/10/" \
| sed "s/RHEND/90/" \
| sed "s/RHSMTH/10/" \
| sed "s/TDCINT/10/" \
| sed "s/TDSMTH/10/" \
| sed "s/TPCINT/5/" \
| sed "s/TPSMTH/10/" \
| sed "s/CLDCINT/5/g" \
| sed "s/CLDEND/95/" \
| sed "s/SLPR/$slpr/" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titlslp/" \
| sed "s/MAP/$stmap/" \
| sed "s/RADAR/$stradar/" \
| sed "s/CLOUD/$stcloud/" \
| sed "s/BOX/$box/" \
>> $nl

done

exit 0
