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
-------------------------------------------------------------------------------
                                 COLOR TABLE
COLOR                | RED  | GREEN | BLUE | NUMBER
-------------------------------------------------------------------------------
def.background       | 1.00 | 1.00  | 1.00 |  0       (DEFAULT BACKGROUND)
def.foreground       | 0.00 | 0.00  | 0.00 |  1       (DEFAULT FOREGROUND)
lt.gray              | 0.75 | 0.75  | 0.75 |  2
lmed.gray            | 0.65 | 0.65  | 0.65 |  3
med.gray             | 0.50 | 0.50  | 0.50 |  4
dk.gray              | 0.25 | 0.25  | 0.25 |  5
lt.green             | 0.60 | 1.00  | 0.60 |  6
green                | 0.00 | 1.00  | 0.00 |  7
dk.green             | 0.00 | 0.50  | 0.00 |  8 
lt.blue              | 0.50 | 0.50  | 1.00 |  9
blue                 | 0.00 | 0.00  | 1.00 | 10
dk.blue              | 0.00 | 0.00  | 0.50 | 11
lt.red               | 1.00 | 0.70  | 0.70 | 12
red                  | 1.00 | 0.00  | 0.00 | 13
dk.red               | 0.50 | 0.00  | 0.00 | 14
lt.orange            | 1.00 | 0.75  | 0.00 | 15
orange               | 1.00 | 0.50  | 0.00 | 16
dk.orange            | 1.00 | 0.25  | 0.00 | 17
lt.violet            | 1.00 | 0.50  | 1.00 | 18
violet               | 1.00 | 0.00  | 1.00 | 19
dk.violet            | 0.50 | 0.00  | 0.50 | 20
black                | 0.00 | 0.00  | 0.00 | 21
white                | 1.00 | 1.00  | 1.00 | 22
-------------------------------------------------------------------------------
===========================================================================
----------------------    Plot Specification Table    ---------------------
===========================================================================
# Precip type.
# Southwest domain.
feld=spt; ptyp=hc; ptcb; nmin; hvbr=1;>
   xwin=92,267; ywin=75,215; >
   cbeg=2; cend=15; cint=1.;>
   cmth=fill; titl=Precipitation_type; >
   cosq=0.5,lt.green,  1.5,lt.green,>
        1.5,green,     2.5,green,>
        2.5,dk.green,  3.5,dk.green,>
        3.5,lt.orange, 4.5,lt.orange,>
        4.5,orange,    5.5,orange,>
        5.5,dk.orange, 6.5,dk.orange,>
        6.5,lt.blue,   7.5,lt.blue,>
        7.5,blue,      8.5,blue,>
        8.5,dk.blue,   9.5,dk.blue,>
        9.5,lt.violet,10.5,lt.violet,>
       10.5,violet,   11.5,violet,>
       11.5,dk.violet,12.5,dk.violet,>
       12.5,lt.red,   15.5,red,>
       15.6,transparent
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground
feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5
===========================================================================
# Montana domain.
feld=spt; ptyp=hc; ptcb; nmin; hvbr=1;>
   xwin=133,248; ywin=270,362; >
   cbeg=2; cend=15; cint=1.;>
   cmth=fill; titl=Precipitation_type; >
   cosq=0.5,lt.green,  1.5,lt.green,>
        1.5,green,     2.5,green,>
        2.5,dk.green,  3.5,dk.green,>
        3.5,lt.orange, 4.5,lt.orange,>
        4.5,orange,    5.5,orange,>
        5.5,dk.orange, 6.5,dk.orange,>
        6.5,lt.blue,   7.5,lt.blue,>
        7.5,blue,      8.5,blue,>
        8.5,dk.blue,   9.5,dk.blue,>
        9.5,lt.violet,10.5,lt.violet,>
       10.5,violet,   11.5,violet,>
       11.5,dk.violet,12.5,dk.violet,>
       12.5,lt.red,   15.5,red,>
       15.6,transparent
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground
feld=box; ptyp=hb; crsa=133.5,270.5; crsb=247.5,361.5
===========================================================================
