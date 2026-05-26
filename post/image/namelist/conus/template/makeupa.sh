#!/bin/sh

# Define map backgrounds.

map="feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=med.dark.gray"

for args in \
"mdlupa # 500 mb height and absolute vorticity." 
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
| sed "s/TMCSMTH/16/" \
| sed "s/GHTCINT/6/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.5,159.5; crsb=315.5,383.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.5,16.5; crsb=331.5,252.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.5,159.5; crsb=599.5,383.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.5,16.5; crsb=573.5,264.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# State namelist

area="flmin=.005, frmax=.92, fbmin=.005, ftmax=.92,"

nl=namelist/$prod.state

cat $prod/$prod.top \
| sed "s/AREA/$area/" \
> $nl

echo $prodname >> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.5,157.5; crsb=164.5,276.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.5,179.5; crsb=194.5,288.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.5,159.5; crsb=304.5,318.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.5,16.5; crsb=375.5,385.5"

cat $prod/$prod.prod1 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
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
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

done

################################################################################
################################################################################

for args in \
"mdlupa # 500 mb height and wind." 
do
set $args

prod=$1
shift
prodname=$@
echo $prod $prodname

nl=namelist/$prod

echo $prodname >> $nl

domain=ConUS
corners="xwin=1,600; ywin=1,450; >"
box="feld=box; ptyp=hb; crsa=1.0,1.0; crsb=600.0,450.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/12/" \
| sed "s/TMCSMTH/16/" \
| sed "s/GHTCINT/6/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.0,159.0; crsb=316.0,384.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.0,16.0; crsb=332.0,253.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.0,159.0; crsb=600.0,384.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.0,16.0; crsb=574.0,265.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# State namelist

nl=namelist/$prod.state

echo $prodname >> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.0,157.0; crsb=165.0,277.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.0,179.0; crsb=195.0,289.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.0,159.0; crsb=305.0,319.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.0,16.0; crsb=376.0,386.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# Southwest namelist

nl=namelist/$prod.sw

echo $prodname >> $nl

domain=Southwest
corners="xwin=92,267; ywin=75,215; >"
box="feld=box; ptyp=hb; crsa=92.0,75.0; crsb=267.0,215.0"

cat $prod/$prod.prod2 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

done

################################################################################
################################################################################

for args in \
"mdlupa # 500 mb height, temperature, and RH." 
do
set $args

prod=$1
shift
prodname=$@
echo $prod $prodname

nl=namelist/$prod

echo $prodname >> $nl

domain=ConUS
corners="xwin=1,600; ywin=1,450; >"
box="feld=box; ptyp=hb; crsa=1.5,1.5; crsb=599.5,449.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/12/" \
| sed "s/TMCSMTH/16/" \
| sed "s/GHTCINT/6/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.5,159.5; crsb=315.5,383.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.5,16.5; crsb=331.5,252.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.5,159.5; crsb=599.5,383.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.5,16.5; crsb=573.5,264.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# State namelist

area="flmin=.005, frmax=.92, fbmin=.005, ftmax=.92,"

nl=namelist/$prod.state

echo $prodname >> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.5,157.5; crsb=164.5,276.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.5,179.5; crsb=194.5,288.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.5,159.5; crsb=304.5,318.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.5,16.5; crsb=375.5,385.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# Southwest namelist

area="flmin=.005, frmax=.92, fbmin=.12, ftmax=1.00,"

nl=namelist/$prod.sw

echo $prodname >> $nl

domain=Southwest
corners="xwin=92,267; ywin=75,215; >"
box="feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5"

cat $prod/$prod.prod3 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

done

################################################################################
################################################################################

for args in \
"mdlupa # 700 mb height and wind." 
do
set $args

prod=$1
shift
prodname=$@
echo $prod $prodname

nl=namelist/$prod

echo $prodname >> $nl

domain=ConUS
corners="xwin=1,600; ywin=1,450; >"
box="feld=box; ptyp=hb; crsa=1.0,1.0; crsb=600.0,450.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/12/" \
| sed "s/TMCSMTH/16/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.0,159.0; crsb=316.0,384.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.0,16.0; crsb=332.0,253.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.0,159.0; crsb=600.0,384.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.0,16.0; crsb=574.0,265.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# State namelist

nl=namelist/$prod.state

echo $prodname >> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.0,157.0; crsb=165.0,277.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.0,179.0; crsb=195.0,289.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.0,159.0; crsb=305.0,319.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.0,16.0; crsb=376.0,386.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# Southwest namelist

nl=namelist/$prod.sw

echo $prodname >> $nl

domain=Southwest
corners="xwin=92,267; ywin=75,215; >"
box="feld=box; ptyp=hb; crsa=92.0,75.0; crsb=267.0,215.0"

cat $prod/$prod.prod4 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

done

################################################################################
################################################################################

for args in \
"mdlupa # 700 mb height, temperature, and RH." 
do
set $args

prod=$1
shift
prodname=$@
echo $prod $prodname

nl=namelist/$prod

echo $prodname >> $nl

domain=ConUS
corners="xwin=1,600; ywin=1,450; >"
box="feld=box; ptyp=hb; crsa=1.5,1.5; crsb=599.5,449.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/12/" \
| sed "s/TMCSMTH/16/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.5,159.5; crsb=315.5,383.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.5,16.5; crsb=331.5,252.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.5,159.5; crsb=599.5,383.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.5,16.5; crsb=573.5,264.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# State namelist

area="flmin=.005, frmax=.92, fbmin=.005, ftmax=.92,"

nl=namelist/$prod.state

echo $prodname >> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.5,157.5; crsb=164.5,276.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.5,179.5; crsb=194.5,288.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.5,159.5; crsb=304.5,318.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.5,16.5; crsb=375.5,385.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# Southwest namelist

area="flmin=.005, frmax=.92, fbmin=.12, ftmax=1.00,"

nl=namelist/$prod.sw

echo $prodname >> $nl

domain=Southwest
corners="xwin=92,267; ywin=75,215; >"
box="feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5"

cat $prod/$prod.prod5 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

done

################################################################################
################################################################################

for args in \
"mdlupa # 300 mb height and wind." 
do
set $args

prod=$1
shift
prodname=$@
echo $prod $prodname

nl=namelist/$prod

echo $prodname >> $nl

domain=ConUS
corners="xwin=1,600; ywin=1,450; >"
box="feld=box; ptyp=hb; crsa=1.0,1.0; crsb=600.0,450.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/12/" \
| sed "s/TMCSMTH/16/" \
| sed "s/GHTCINT/6/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.0,159.0; crsb=316.0,384.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.0,16.0; crsb=332.0,253.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.0,159.0; crsb=600.0,384.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.0,16.0; crsb=574.0,265.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# State namelist

nl=namelist/$prod.state

echo $prodname >> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.0,157.0; crsb=165.0,277.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.0,179.0; crsb=195.0,289.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.0,159.0; crsb=305.0,319.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.0,16.0; crsb=376.0,386.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# Southwest namelist

nl=namelist/$prod.sw

echo $prodname >> $nl

domain=Southwest
corners="xwin=92,267; ywin=75,215; >"
box="feld=box; ptyp=hb; crsa=92.0,75.0; crsb=267.0,215.0"

cat $prod/$prod.prod6 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

done

################################################################################
################################################################################

for args in \
"mdlupa # 700 mb vertical motion and wind." 
do
set $args

prod=$1
shift
prodname=$@
echo $prod $prodname

nl=namelist/$prod

echo $prodname >> $nl

domain=ConUS
corners="xwin=1,600; ywin=1,450; >"
box="feld=box; ptyp=hb; crsa=1.5,1.5; crsb=599.5,449.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/12/" \
| sed "s/TMCSMTH/16/" \
| sed "s/GHTCINT/3/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northwest
corners="xwin=16,316; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=16.5,159.5; crsb=315.5,383.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southwest
corners="xwin=16,332; ywin=16,253; >"
box="feld=box; ptyp=hb; crsa=16.5,16.5; crsb=331.5,252.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Northeast
corners="xwin=300,600; ywin=159,384; >"
box="feld=box; ptyp=hb; crsa=300.5,159.5; crsb=599.5,383.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=Southeast
corners="xwin=242,574; ywin=16,265; >"
box="feld=box; ptyp=hb; crsa=242.5,16.5; crsb=573.5,264.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# State namelist

area="flmin=.005, frmax=.92, fbmin=.005, ftmax=.92,"

nl=namelist/$prod.state

echo $prodname >> $nl

domain="Western Great Basin"
corners="xwin=45,165; ywin=157,277; >"
box="feld=box; ptyp=hb; crsa=45.5,157.5; crsb=164.5,276.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Eastern Great Basin"
corners="xwin=85,195; ywin=179,289; >"
box="feld=box; ptyp=hb; crsa=85.5,179.5; crsb=194.5,288.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain="Rocky Mountain"
corners="xwin=145,305; ywin=159,319; >"
box="feld=box; ptyp=hb; crsa=145.5,159.5; crsb=304.5,318.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

domain=WestUS
corners="xwin=6,376; ywin=16,386; >"
box="feld=box; ptyp=hb; crsa=6.5,16.5; crsb=375.5,385.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/6/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

# Southwest namelist

area="flmin=.005, frmax=.92, fbmin=.12, ftmax=1.00,"

nl=namelist/$prod.sw

echo $prodname >> $nl

domain=Southwest
corners="xwin=92,267; ywin=75,215; >"
box="feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5"

cat $prod/$prod.prod7 \
| sed "s/DOMAIN/# $domain domain./" \
| sed "s/CORNERS/$corners/" \
| sed "s/WINDCINT/4/" \
| sed "s/TMCSMTH/8/" \
| sed "s/GHTCINT/2/" \
| sed "s/MAP/$map/" \
| sed "s/BOX/$box/" \
>> $nl

done

exit 0
