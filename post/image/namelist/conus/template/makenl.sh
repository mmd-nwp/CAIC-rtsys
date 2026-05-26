#!/bin/sh

# Define map backgrounds.

stmap="feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground"
ctymap="feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground\nfeld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground"

stradar="feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.background"
ctyradar="feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.background\nfeld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.background"

stcloud="feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=yellow"
ctycloud="feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=yellow\nfeld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=yellow"

slpr="\nfeld=slpgr; ptyp=hc; linw=2; cint=4; colr=def.foreground; smth=40; nmin; nmsg; nttl"
titlslp="titl=Surface_Temperature_(F),_Wind_(kt),_and_Sea-Level_Pressure_(mb); >"
titltp="titl=Surface_Temperature_(F)_and_Wind_(kt); >"
mtitlslp="titl=MOCA_Surface_Temperature_(F),_Wind_(kt),_and_Sea-Level_Pressure_(mb); >"
mtitltp="titl=MOCA_Surface_Temperature_(F)_and_Wind_(kt); >"

for args in \
"lapspbl      # PBL height." \
"lapsrh       # Relative humidity." \
"lapstd       # Surface dew point and wind." \
"lapstpw      # Total precipitable water." \
"lapstemp     # Temperature." \
"lapshaines   # Haines index (middle)." \
"lapscloud    # Cloud cover." \
"lapswind     # Wind speed." \
"mdlprecip    # Accumulated precipitation." \
"mdlsnow      # Total snowfall." \
"mdlprecip-24 # 24-hr precip accumulation." \
"mdltype      # Precip type." \
"mdlradar     # Model forecast radar reflectivity." \
"mdlpbl       # PBL height." \
"mdlrh        # Relative humidity." \
"mdltd        # Surface dew point and wind." \
"mdlhaines    # Haines index (middle)." \
"mdltpw       # Total precipitable water." \
"mdltemp      # Temperature." \
"mdlcloud     # Cloud cover." \
"mdlwind      # Wind speed." \
"mdlflux      # Latent heat flux." \
"mdlmocatemp  # Moca temperature." \
"mdlmocatd    # Moca dew point and wind." \
"mdlmocarh    # Moca relative humidity."
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
| sed "s/PCPSMTH/5/" \
| sed "s/RADSMTH/3/" \
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
| sed "s/PCPSMTH/3/" \
| sed "s/RADSMTH/2/" \
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
| sed "s/PCPSMTH/3/" \
| sed "s/RADSMTH/2/" \
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
| sed "s/PCPSMTH/3/" \
| sed "s/RADSMTH/2/" \
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
| sed "s/PCPSMTH/3/" \
| sed "s/RADSMTH/2/" \
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

# State namelist

area="flmin=.005, frmax=.92, fbmin=.005, ftmax=.92,"

nl=namelist/$prod.state

cat $prod/$prod.top \
| sed "s/AREA/$area/" \
> $nl

echo $prodname >> $nl

domain=Colorado
corners="xwin=181,251; ywin=169,239; >"
box="feld=box; ptyp=hb; crsa=181.5,169.5; crsb=250.5,238.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Wyoming
corners="xwin=168,245; ywin=221,298; >"
box="feld=box; ptyp=hb; crsa=168.5,221.5; crsb=244.5,297.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Utah
corners="xwin=118,195; ywin=179,256; >"
box="feld=box; ptyp=hb; crsa=118.5,179.5; crsb=194.5,255.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain="New Mexico"
corners="xwin=169,249; ywin=101,181; >"
box="feld=box; ptyp=hb; crsa=169.5,101.5; crsb=248.5,180.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Arizona
corners="xwin=100,186; ywin=103,189; >"
box="feld=box; ptyp=hb; crsa=100.5,103.5; crsb=185.5,188.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Southern California"
corners="xwin=35,141; ywin=133,239; >"
box="feld=box; ptyp=hb; crsa=35.5,133.5; crsb=140.5,238.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Oregon
corners="xwin=40,129; ywin=255,344; >"
box="feld=box; ptyp=hb; crsa=40.5,255.5; crsb=128.5,343.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Washington
corners="xwin=61,137; ywin=302,378; >"
box="feld=box; ptyp=hb; crsa=61.5,302.5; crsb=136.5,377.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Idaho
corners="xwin=108,216; ywin=248,356; >"
box="feld=box; ptyp=hb; crsa=108.5,248.5; crsb=215.5,355.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain="South Dakota"
corners="xwin=220,318; ywin=222,320; >"
box="feld=box; ptyp=hb; crsa=220.5,222.5; crsb=317.5,319.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Front Range"
corners="xwin=204,242; ywin=194,232; >"
box="feld=box; ptyp=hb; crsa=204.5,194.5; crsb=241.5,231.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/1/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/0/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.5,157.5; crsb=164.5,276.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2.5/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2.5/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/2/" \
| sed "s/RADSMTH/1/" \
| sed "s/CLDCINT/4/g" \
| sed "s/CLDEND/96/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.5,179.5; crsb=194.5,288.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2.5/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2.5/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/2/" \
| sed "s/RADSMTH/1/" \
| sed "s/CLDCINT/4/g" \
| sed "s/CLDEND/96/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.5,159.5; crsb=304.5,318.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2.5/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2.5/" \
| sed "s/TPSMTH/2/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/1/" \
| sed "s/CLDCINT/4/g" \
| sed "s/CLDEND/96/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Texas
corners="xwin=198,356; ywin=12,170; >"
box="feld=box; ptyp=hb; crsa=198.5,12.5; crsb=355.5,169.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.5,16.5; crsb=375.5,385.5"

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
| sed "s/PCPSMTH/3/" \
| sed "s/RADSMTH/2/" \
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

# Southwest namelist

area="flmin=.005, frmax=.92, fbmin=.12, ftmax=1.00,"

nl=namelist/$prod.sw

cat $prod/$prod.top \
| sed "s/AREA/$area/" \
> $nl

echo $prodname >> $nl

domain=Southwest
corners="xwin=92,267; ywin=75,215; >"
box="feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2.5/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2.5/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/2/" \
| sed "s/RADSMTH/1/" \
| sed "s/CLDCINT/4/g" \
| sed "s/CLDEND/96/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Montana
corners="xwin=133,248; ywin=270,362; >"
box="feld=box; ptyp=hb; crsa=133.5,270.5; crsb=247.5,361.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/3/" \
| sed "s/RHCINT/5/" \
| sed "s/RHBEG/5/" \
| sed "s/RHEND/95/" \
| sed "s/RHSMTH/1/" \
| sed "s/TDCINT/2/" \
| sed "s/TDSMTH/1/" \
| sed "s/TPCINT/2/" \
| sed "s/TPSMTH/1/" \
| sed "s/PCPSMTH/1/" \
| sed "s/RADSMTH/0/" \
| sed "s/CLDCINT/2.5/g" \
| sed "s/CLDEND/97.5/" \
| sed "s/SLPR//" \
| sed "s/MTITL/$mtitlslp/" \
| sed "s/TITL/$titltp/" \
| sed "s/MAP/$ctymap/" \
| sed "s/RADAR/$ctyradar/" \
| sed "s/CLOUD/$ctycloud/" \
| sed "s/BOX/$box/" \
>> $nl

done

exit 0
