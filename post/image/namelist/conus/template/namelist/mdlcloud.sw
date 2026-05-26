 &userin
 title='MM5 8km Domain',
 titlecolor='def.foreground', idotitle=1,
 flmin=.005, frmax=.92, fbmin=.12, ftmax=1.00,
 ptimes=FCST,
 ptimeunits='h',timezone=-7,iusdaylightrule=1,
 tacc=600.,iinittime=0,ivalidtime=1,inearesth=1,
 ntextq=0,ntextcd=0,fcoffset=0.0,
 icgmsplit=0, itrajcalc=0, maxfld=15,imakev5d=0
 &end
 &trajcalc
 rtim=15,ctim=6,dtfile=3600.,dttraj=600.,vctraj='s',
 xjtraj=95,90,85,80,75,70,65,80.6,80.6,80.6,80.6,80.6,80.6,
 yitraj=50,55,60,65,70,75,80,77,77,77,77,77,77,
 zktraj=.9,.9,.9,.9,.9,.9,.9,.99,.9,.8,.7,.6,.5,
 ihydrometeor=0
 &end
-----------------------------------------------------------------
                           COLOR TABLE
COLOR                | RED  | GREEN | BLUE |
-----------------------------------------------------------------
def.background       | 1.00 | 1.00  | 1.00 |  1  (DEFAULT BACKGROUND)
def.foreground       | 0.00 | 0.00  | 0.00 |  2  (DEFAULT FOREGROUND)
white                | 1.00 | 1.00  | 1.00 |  3
black                | 0.00 | 0.00  | 0.00 |  4
cwhite               | 0.99 | 0.99  | 0.99 |  5
cblack               | 0.01 | 0.01  | 0.01 |  6
yellow               | 1.00 | 1.00  | 0.00 |  7
-----------------------------------------------------------------
===========================================================================
----------------------    Plot Specification Table    ---------------------
===========================================================================
# Cloud cover.
# Southwest domain.
feld=cld; ptyp=hc; cmth=fill; cbeg=4; cint=4; cend=96; nohl; nmin; hvbr=1;>
 xwin=92,267; ywin=75,215; >
 titl=Cloud_Cover_(%);>
 cosq=0,cblack,100,cwhite
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=yellow
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=yellow
feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5
===========================================================================
# Montana domain.
feld=cld; ptyp=hc; cmth=fill; cbeg=2.5; cint=2.5; cend=97.5; nohl; nmin; hvbr=1;>
 xwin=133,248; ywin=270,362; >
 titl=Cloud_Cover_(%);>
 cosq=0,cblack,100,cwhite
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=yellow
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=yellow
feld=box; ptyp=hb; crsa=133.5,270.5; crsb=247.5,361.5
===========================================================================
