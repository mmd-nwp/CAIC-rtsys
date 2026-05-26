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
light.gray           | 0.75 | 0.75  | 0.75 |  2
lmed.gray            | 0.65 | 0.65  | 0.65 |  3
med.gray             | 0.50 | 0.50  | 0.50 |  3
dark.gray            | 0.25 | 0.25  | 0.25 |  4
red                  | 1.00 | 0.00  | 0.00 |  5
orange               | 1.00 | 0.50  | 0.00 |  6
yellow               | 1.00 | 1.00  | 0.00 |  7
green                | 0.00 | 1.00  | 0.00 |  8
blue                 | 0.00 | 0.00  | 1.00 |  9
violet               | 0.50 | 0.00  | 0.50 | 10
light.red            | 1.00 | 0.50  | 0.50 | 11
light.orange         | 1.00 | 0.75  | 0.50 | 12
light.yellow         | 1.00 | 1.00  | 0.50 | 13
light.green          | 0.50 | 1.00  | 0.50 | 14
light.blue           | 0.50 | 0.50  | 1.00 | 15
light.violet         | 0.75 | 0.50  | 0.75 | 16
dark.red             | 0.50 | 0.00  | 0.00 | 17
brown                | 0.50 | 0.25  | 0.00 | 18
dark.yellow          | 0.50 | 0.50  | 0.00 | 19
dark.green           | 0.00 | 0.50  | 0.00 | 20
dark.blue            | 0.00 | 0.00  | 0.50 | 21
c23                  | 0.40 | 0.20  | 0.00 | 23
c26                  | 1.00 | 0.50  | 0.00 | 26
c27                  | 1.00 | 1.00  | 0.95 | 27
lt.blue              | 0.40 | 1.00  | 1.00 | 28
lt.gray              | 0.80 | 0.80  | 0.80 | 29
c30                  | 1.00 | 1.00  | 0.05 | 30
c31                  | 0.95 | 1.00  | 0.95 | 31
c34                  | 0.05 | 1.00  | 0.05 | 34
c35                  | 0.95 | 0.95  | 1.00 | 35
c38                  | 0.05 | 0.05  | 1.00 | 38
c43                  |0.    |0.0620 |1.0000| 43
c44                  |0.1250|0.     |1.0000| 44
c45                  |0.3120|0.     |1.0000| 45
c46                  |0.5000|0.     |1.0000| 46
c47                  |0.6880|0.     |1.0000| 47
c48                  |0.8750|0.     |1.0000| 48
c49                  |1.0000|0.     |0.9380| 49
c50                  |1.0000|0.     |0.7500| 50
c51                  |1.0000|0.     |0.5620| 51
c52                  |1.0000|0.     |0.3750| 52
c53                  |1.0000|0.     |0.1880| 53
magenta              | 1.00 | 0.50  | 1.00 | 54
very.dark.blue       | 0.00 | 0.00  | 0.30 | 55
black                | 0.00 | 0.00  | 0.00 | 56
white                | 1.00 | 1.00  | 1.00 | 57
c58                  |0.5   |0.5    |0.85  | 58
c59                  |1.00  |0.95   |0.95  | 59
c62                  |1.00  |0.05   |0.05  | 62
c63                  |1.00  |0.80   |1.00  | 63
c66                  |1.00  |0.00   |1.00  | 66
medium.red           |0.80  |0.0    |0.0   | 67
lighter.blue         | 0.75 | 0.94  | 1.00 | 68
light.brown          | 1.00 |  .60  |  .40 | 69
dark.violet          | 0.25 | 0.00  | 0.25 | 70
medium.brown         |0.68  |0.4    |0.0   | 71
lightest.red         | 1.00 | 0.85  | 0.85 | 72
med.dark.gray        | 0.40 | 0.40  | 0.40 | 73
---------------------------------------------------------------------------
===========================================================================
----------------------    Plot Specification Table    ---------------------
===========================================================================
# PBL height.
# Southwest domain.
feld=pbllaps; ptyp=hc; cmth=fill; cint=.5; nmin; hvbr=1;>
  xwin=92,267; ywin=75,215; >
  smth=1; nttl; nmsg; cbeg=0.500; cend=16;>
  cosq=0,def.background,>
         0,c38, 4,c35,>
         4,c34, 8,c31,>
         8,c30,12,c27,>
        12,c62,16,c59,>
        16,def.background
feld=pbllaps; ptyp=hc; linw=1; cint=2; colr=med.gray;>
   smth=1; mjsk=0; nohl; nmsg; titl=Mixing_Height_(ft*1000)
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground
feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5
===========================================================================
# Montana domain.
feld=pbllaps; ptyp=hc; cmth=fill; cint=.5; nmin; hvbr=1;>
  xwin=133,248; ywin=270,362; >
  smth=1; nttl; nmsg; cbeg=0.500; cend=16;>
  cosq=0,def.background,>
         0,c38, 4,c35,>
         4,c34, 8,c31,>
         8,c30,12,c27,>
        12,c62,16,c59,>
        16,def.background
feld=pbllaps; ptyp=hc; linw=1; cint=2; colr=med.gray;>
   smth=1; mjsk=0; nohl; nmsg; titl=Mixing_Height_(ft*1000)
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground
feld=box; ptyp=hb; crsa=133.5,270.5; crsb=247.5,361.5
===========================================================================
# Ventilation index and mean PBL wind.
# Southwest domain.
feld=ven; ptyp=hc; cmth=fill; cint=5; nmin; hvbr=1;>
  xwin=92,267; ywin=75,215; >
  smth=10; nttl; nmsg; cbeg=5; cend=120;>
  cosq=  0,c62, 20,c59,>
        20,c66, 40,c63,>
        40,c30, 60,c27,>
        60,c34, 80,c31,>
        80,c38,120,c35,>
       120,def.background
feld=ven; ptyp=hc; linw=1; cint=10; colr=med.gray;>
   cbeg=10; cend=30;>
   smth=10; mjsk=0; nohl; titl=Ventilation_Index_(kt-ft*1000)_and_Mean_Mixing_Depth_Wind_(kt); nmsg
feld=ven; ptyp=hc; linw=1; cint=20; colr=med.gray;>
   cbeg=40; cend=80;>
   smth=10; mjsk=0; nohl; nttl; nmsg
feld=ven; ptyp=hc; linw=1; cint=40; colr=med.gray;>
   cbeg=120; cend=120;>
   smth=10; mjsk=0; nohl; nttl; nmsg
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground
feld=puw,pvw; ptyp=hv; vcmx=-15; fulb=10kts; nttl;>
   linw=1; smth=0; intv=4; colr=dark.gray; nmsg
feld=box; ptyp=hb; crsa=92.5,75.5; crsb=266.5,214.5
===========================================================================
# Montana domain.
feld=ven; ptyp=hc; cmth=fill; cint=5; nmin; hvbr=1;>
  xwin=133,248; ywin=270,362; >
  smth=10; nttl; nmsg; cbeg=5; cend=120;>
  cosq=  0,c62, 20,c59,>
        20,c66, 40,c63,>
        40,c30, 60,c27,>
        60,c34, 80,c31,>
        80,c38,120,c35,>
       120,def.background
feld=ven; ptyp=hc; linw=1; cint=10; colr=med.gray;>
   cbeg=10; cend=30;>
   smth=10; mjsk=0; nohl; titl=Ventilation_Index_(kt-ft*1000)_and_Mean_Mixing_Depth_Wind_(kt); nmsg
feld=ven; ptyp=hc; linw=1; cint=20; colr=med.gray;>
   cbeg=40; cend=80;>
   smth=10; mjsk=0; nohl; nttl; nmsg
feld=ven; ptyp=hc; linw=1; cint=40; colr=med.gray;>
   cbeg=120; cend=120;>
   smth=10; mjsk=0; nohl; nttl; nmsg
feld=map; ptyp=hb; outy=Earth..2L5; ouds=solid; oulw=1; cint=360; colr=def.foreground
feld=map; ptyp=hb; outy=Earth..2L4; ouds=solid; oulw=2; cint=360; colr=def.foreground
feld=puw,pvw; ptyp=hv; vcmx=-15; fulb=10kts; nttl;>
   linw=1; smth=0; intv=4; colr=dark.gray; nmsg
feld=box; ptyp=hb; crsa=133.5,270.5; crsb=247.5,361.5
===========================================================================
