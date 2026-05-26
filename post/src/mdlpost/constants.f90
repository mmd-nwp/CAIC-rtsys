module mdlconstants

   integer, parameter :: imiss=-99999
   integer, parameter :: ismth=0
   integer, parameter :: jsmth=0

   real, parameter :: cm2inch=1.0/2.54
   real, parameter :: cp=1004.
   real, parameter :: g=9.8
   real, parameter :: gi=1./g
   real, parameter :: lapse=6.5E-03
   real, parameter :: lapseh=lapse/2.
   real, parameter :: lv=2.5E+06
   real, parameter :: m2feet=3.281
   real, parameter :: mps2knts=1.944
   real, parameter :: mps2mph=2.237
   real, parameter :: p0=100000.0
   real, parameter :: r=287.    
   real, parameter :: rv=461.5
   real, parameter :: t0=273.15
   real, parameter :: xmiss=-99999.9
   real, parameter :: cpog=cp/g
   real, parameter :: gocp=g/cp
   real, parameter :: cpor=cp/r
   real, parameter :: e=r/rv
   real, parameter :: gor=g/r
   real, parameter :: kappa=r/cp
   real, parameter :: rog=r/g
   real, parameter :: rvolv=rv/lv
   real, parameter :: zero_thresh=1.e-10
   real, parameter :: s0=1376.

   real, parameter :: pi=atan2(1.,1.)*4.
   real, parameter :: rad2deg=180./pi
   real, parameter :: deg2rad=pi/180.
   real, parameter :: pi2d=2.*pi/365.

end module mdlconstants
