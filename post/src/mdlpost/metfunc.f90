function esat(t)

! Computes saturation vapor pressure (Pa) from temperature (K).
! Note: Computed with respect to liquid.

implicit none

real :: esat,t
    
esat = 611.21 * exp ( (17.502 * (t-273.15)) / (t-32.18) )

return
end function

!===============================================================================

function potential_temp(t,p)

! Computes potential temperature from temp (K) and pressure (Pa).

use mdlconstants

implicit none

real :: t,p,potential_temp

potential_temp=t*(p0/p)**kappa

return
end function

!===============================================================================

function relhum(t,mixrat,p)

! Computes relative humidity (%)

implicit none

real :: t       ! Temperature (K)
real :: p       ! Pressure (Pa)
real :: mixrat  ! vapor mixing ratio
real :: mixsat  ! Saturation vapor mix. ratio
real :: relhum  ! RH (%)

relhum=mixrat/mixsat(t,p)*100.
relhum=max(min(100.,relhum),0.1)

return
end function

!===============================================================================

function mixsat(t,p)

! Computes saturation vapor mixing ratio as function of temp (K) and pres (Pa).

use mdlconstants

implicit none

real :: esat,mixrat,p,satvpr,t,mixsat

satvpr=esat(t)
mixsat=(e*satvpr)/(p-satvpr)

return   
end function

!===============================================================================

function eq_potential_temp(t,p,w,rh)
 
! Calculates equivalent potential temperature given temperature, 
! pressure, mixing ratio, and relative humidity via
! Bolton's equation.  (MWR 1980, P 1052, eq. 43)

implicit none
    
real :: t   ! temp (K)
real :: p   ! pressure (Pa)
real :: w   ! mixing ratio (kg/kg)
real :: rh  ! relative humidity (fraction)
real :: thtm,tlcl,eq_potential_temp

thtm=t*(100000./p)**(2./7.*(1.-(0.28*w)))
eq_potential_temp=thtm*exp((3.376/tlcl(t,rh)-0.00254)  &
                 *(w*1000.0*(1.0+0.81*w)))

return
end function

!===============================================================================

function tlcl(t,rh)

! Computes the temperature of the Lifting Condensation Level
! given surface t and RH using Bolton's equation.  (MWR 1980, p 1048, #22)

implicit none

real :: denom,rh,t,term1,term2,tlcl

term1=1.0/(t-55.0)
term2=alog(rh/1.0)/2840.
denom=term1-term2
tlcl=(1.0/denom)+55.0

return
end function

!===============================================================================

function dewpt(t,rh)
 
! Compute dew point from temperature (K) and RH (%).

use mdlconstants

implicit none

real :: dewpt,rh,t    

dewpt=t/((-rvolv*alog(max(rh,1.)/100.)*t)+1.0)
dewpt=min(t,dewpt)

return
end function

!===============================================================================

function wobf(t)

! Name: wobuf function
!
! This function calculates the difference of the wet bulb potential
! temperatures for saturated and dry air given the temperature.
!
! It was created by Herman Wobus of the Navy Weather Research
! Facility from data in the Smithsonian Meteorological Tables.
!
!
! Let wbpts = wet bulb potential temperature for saturated air
!             at temperature t in celsius
!
! Let wbptd = wet bult potential temperature for dry air at
!             the same temperature.
!
! The Wobus function wobf (in degrees celsius) is defined by:
!
!             wobf(t) = wbpts - wbptd
!
! Although wbpts and wbptd are functions of both pressure and
! temperature, their difference is a function of temperature only.
!
! The Wobus function is useful for evaluating several thermodynamic
! quantities.
!
! If t is at 1000 mb, then t is potential temperature pt and
! wbpts = pt.  Thus,
!
!             wobf(pt) = pt - wbptd
!
! If t is at the condensation level, then t is the condensation
! temperature tc and wbpts is the wet bulb potential temperature
! wbpt.  Thus,
!
!             wobf(tc) = wbpt - wbptd
!
! Manipulating the above equations we get,
!
!             wbpt = pt - wobf(pt) + wobf(tc)   and
!
!             wbpts = pt - wobf(pt) + wobf(t)
!
! If t is equivalent potential temperature ept (implying that
! the air at 1000 mb is completely dry), then
!
!             wbpts = ept and wbptd = wbpt, thus,
!
!             wobf(ept) = ept - wbpt

implicit none

real :: pol,t,wobf,x

x=t-20.

if (x <= 0.) then
   pol=1.0              +x*(-8.8416605E-03   &
      +x*( 1.4714143E-04+x*(-9.6719890E-07   &
      +x*(-3.2607217E-08+x*(-3.8598073E-10)))))
   wobf=15.130/(pol**4)
else
   pol=1.               +x*(3.6182989E-03   &
      +x*(-1.3603273E-05+x*(4.9618922E-07   &
      +x*(-6.1059365E-09+x*(3.9401551E-11   &
      +x*(-1.2588129E-13+x*(1.6688280E-16)))))))
   wobf=(29.930/(pol**4))+(0.96*x)-14.8
endif

return
end function

!===============================================================================

subroutine the2t(thetae,p,tparcel)
 
! Calculates temperature (K) at any pressure (Pa) level along a saturation
! adiabat by iteratively solving eq 2.76 from Wallace and Hobbs (1977).

! Adpated from USAF routine, B. Shaw, NOAA/FSL

use mdlconstants

implicit none

integer           :: iter
real, external    :: mixsat
real, intent(in)  :: p
real              :: tcheck
real              :: theta
real, intent(in)  :: thetae
real              :: tovtheta
real, intent(out) :: tparcel
real              :: diff
logical           :: converged

converged=.false.
tovtheta=(p/p0)**kappa
tparcel=thetae/exp(lv*0.012/(cp*295.0))*tovtheta

diff=9999.
do iter=1,50 
   theta = thetae / exp(lv*mixsat(tparcel,p)/(cp*tparcel))
   tcheck = theta * tovtheta
!  if (abs(abs(tparcel-tcheck)-diff) < 0.1) then
   if (abs(tparcel - tcheck) .lt. 0.05) then
      converged=.true.
      exit
   endif
   diff=abs(tparcel-tcheck)
   tparcel=tparcel+(tcheck-tparcel)*0.3
enddo

if (.not. converged) then
   print*,'Warning: thetae to temp calc did not converge.'
   print*,'  thetae and p:',thetae,p
   print*,'  tparcel:',tparcel
   print*,'  theta,tovtheta:',theta,tovtheta
   print*,abs(abs(tparcel-tcheck)-diff)
endif

return
end subroutine

!===============================================================================

function wdir(u,v,xlon,orient,conefact)

! Computes wind direction from u/v components.  Converts the direction
!   to true direction if conefactor \= 0.

use mdlconstants

implicit none

real :: conefact,diff,orient,u,v,wdir,xlon

! Handle case where u is very small to prevent divide by 0.

if (abs(u) < 0.001) then
   if (v <= 0.) then
      wdir=0.
   else
      wdir=180.
   endif

! Otherwise, standard trig problem.

else
   wdir=270.-(atan2(v,u)*rad2deg)
   if (wdir > 360.) wdir=wdir-360.
endif

! Change to earth relative.

diff=(orient-xlon)*conefact
if (diff >  180.) diff=diff-360.
if (diff < -180.) diff=diff+360.

wdir=wdir-diff
if (wdir > 360.) wdir=wdir-360.
if (wdir < 0.) wdir=wdir+360.

return
end function

!===============================================================================

function wspd(u,v)

! Computes wind velocity from u/v components.

implicit none

real :: u,v,wspd

wspd=sqrt((u*u)+(v*v))

return
end function

!===============================================================================

function fahren(t)

! Converts from Celsius to fahrenheit

implicit none

real :: t,fahren

fahren=(1.8*t)+32.

return
end function

!===============================================================================

function celsius(tf)

implicit none

real, parameter :: factor=5./9.
real :: tf,celsius

celsius=factor*(tf-32.)

return
end function

!===============================================================================

function heatindex(temp_k,rh_pct)

! Computes heat index from a temperature (K) and RH (%).

use mdlconstants

implicit none

real :: celsius,fahren,heatindex,rh_pct,rh_pct_sqr,tf,tf_sqr,temp_k

rh_pct_sqr=rh_pct*rh_pct
tf=fahren(temp_k-t0)
tf_sqr=tf*tf

heatindex=-42.379+(2.04901523  *tf)                 &
                 +(10.1433312  *rh_pct)             &
                 -(0.22475541  *tf*rh_pct)          &
                 -(6.83783E-03 *tf_sqr)             &
                 -(5.481717E-02*rh_pct_sqr)         &
                 +(1.22874E-03 *tf_sqr*rh_pct)      &
                 +(8.52E-04    *rh_pct_sqr*tf)      &
                 -(1.99E-06    *tf_sqr*rh_pct_sqr)

heatindex=celsius(heatindex)+t0

return
end function

!===============================================================================

function tw(t,td,p)

! This function returns the wet-bulb temperature tw (K)
!  given the temperature t (K), dew point td (K)
!  and pressure p (Pa).  See p.13 in stipanuk (1973), referenced
!  above, for a description of the technique.

! Baker,Schlatter	17-may-1982	original version

! Determine the mixing ratio line thru td and p.

aw=w(td,p)

! Determine the dry adiabat thru t and p.

ao=o(t,p)
pi=p

! Iterate to locate pressure pi at the intersection of the two
!  curves.  pi has been set to p for the initial guess.

do i=1,10
   x=0.02*(tmr(aw,pi)-tda(ao,pi))
   if (abs(x) < 0.01) goto 5
   pi=pi*(2.**(x))
enddo
5 continue

! Find the temperature on the dry adiabat ao at pressure pi.

ti=tda(ao,pi)

! The intersection has been located...now, find a saturation
!  adiabat thru this point.  Function os returns the equivalent 
!  potential temperature (K) of a parcel saturated at temperature
!  ti and pressure pi.

aos=os(ti,pi)

! Function tsa returns the wet-bulb temperature (K) of a parcel at
!  pressure p whose equivalent potential temperature is aos.

tw=tsa(aos,p)

return
end function

!===============================================================================

function w(t,p)
 
! This function returns the mixing ratio (kg/kg) given the temperature t (K) 
!  and pressure (Pa).  The formula is quoted in most meteorological texts.

! Baker,Schlatter	17-may-1982	original version

implicit none

real :: t,p,x,esat,w

x=esat(t)
w=0.622*x/(p-x)

return
end function

!===============================================================================

function o(t,p)

! G.S. Stipanuk     1973      	  original version.
! Reference stipanuk paper entitled:
!  "algorithms for generating a skew-t, log p
!     diagram and computing selected meteorological quantities."
!     atmospheric sciences laboratory
!     u.s. army electronics command
!     white sands missile range, new mexico 88002
!     33 pages
! Baker, Schlatter  17-may-1982	 

! This function returns potential temperature (K) given
!  temperature t (K) and pressure p (Pa) by solving the poisson
!  equation.

implicit none

real :: t,p,o

o=t*((100000./p)**.286)

return
end function

!===============================================================================

function tmr(w,p)

!	g.s. stipanuk     1973      	  original version.
!	reference stipanuk paper entitled:
!            "algorithms for generating a skew-t, log p
!	     diagram and computing selected meteorological
!	     quantities."
!	     atmospheric sciences laboratory
!	     u.s. army electronics command
!	     white sands missile range, new mexico 88002
!	     33 pages
!	Baker, Schlatter  17-may-1982	 

!   This function returns the temperature (K) on a mixing
!   ratio line w (kg/kg) at pressure p (Pa). The formula is given in 
!   table 1 on page 7 of stipanuk (1973).

!   initialize constants

data c1/.0498646455/,c2/2.4082965/,c3/7.07475/
data c4/38.9114/,c5/.0915/,c6/1.2035/

x=alog10(w*p*0.01/(0.622+w))
tmr=10.**(c1*x+c2)-c3+c4*((10.**(c5*x)-c6)**2.)

return
end function

!===============================================================================

function tda(th,p)

!	g.s. stipanuk     1973      	  original version.
!	reference stipanuk paper entitled:
!            "algorithms for generating a skew-t, log p
!	     diagram and computing selected meteorological
!	     quantities."
!	     atmospheric sciences laboratory
!	     u.s. army electronics command
!	     white sands missile range, new mexico 88002
!	     33 pages
!	Baker, Schlatter  17-may-1982	 

! This function returns the temperature tda (K) on a dry adiabat
!  at pressure p (Pa).  The dry adiabat is given by
!  potential temperature th (K).  The computation is based on
!  poisson's equation.

implicit none

real :: th,p,tda

tda=th*((p*0.00001)**.286)

return
end function

!===============================================================================

function os(t,p)

!	G.S. Stipanuk     1973      	  original version.
!	reference stipanuk paper entitled:
!            "algorithms for generating a skew-t, log p
!	     diagram and computing selected meteorological
!	     quantities."
!	     atmospheric sciences laboratory
!	     u.s. army electronics command
!	     white sands missile range, new mexico 88002
!	     33 pages
!	Baker, Schlatter  17-may-1982	 

! This function returns the equivalent potential temperature os
!  (K) for a parcel of air saturated at temperature t (K)
!  and pressure p (Pa).

implicit none

real :: t,p,b,w,os

data b/2651.8986/

! b is an empirical constant approximately equal to the latent heat
!  of vaporization for water divided by the specific heat at constant
!  pressure for dry air.

os=t*((100000./p)**.286)*(exp(b*w(t,p)/t))

return
end function

!===============================================================================

function tsa(os,p)

!	g.s. stipanuk     1973      	  original version.
!	reference stipanuk paper entitled:
!            "algorithms for generating a skew-t, log p
!	     diagram and computing selected meteorological
!	     quantities."
!	     atmospheric sciences laboratory
!	     u.s. army electronics command
!	     white sands missile range, new mexico 88002
!	     33 pages
!	baker, schlatter  17-may-1982	 

! This function returns the temperature tsa (K) on a saturation
!  adiabat at pressure p (Pa). os is the equivalent potential
!  temperature of the parcel (K). sign(a,b) replaces the
!  algebraic sign of a with that of b.
!  b is an empirical constant approximately equal to 0.001 of the latent 
!  heat of vaporization for water divided by the specific heat at constant
!  pressure for dry air.

data b/2651.8986/

! tq is the first guess for tsa.

tsa=253.15

! d is an initial value used in the iteration below.

d=120.

! Iterate to obtain sufficient accuracy....see table 1, p.8
!  of stipanuk (1973) for equation used in iteration.

do i=1,12
   d=d/2.
   x=os*exp(-b*w(tsa,p)/tsa)-tsa*((100000./p)**.286)
   if (abs(x) < 1.e-7) goto 2
   tsa=tsa+sign(d,x)
enddo
2 continue

return
end function

!===============================================================================

function mslp(ter,pr,tp,mr)

use mdlconstants

implicit none

real :: mslp,ter,pr,tp,mr,tv

tv=tp*(1.0+0.61*mr)
mslp=pr*exp(gor*ter/(tv+ter*lapseh))

return
end function

!===============================================================================

function epottemp(t,q,rh,prs)

! Subroutine to calculate thetae (algorithm from Bolton)

! Input/Output:
!    T: temperature (K)
!    Q: water vapor mixing ratio (kg/kg)
!   RH: relative humidity (%)
!  PRS: pressure (Pa)
!  epottemp: equivalent potential temperature (K)

use mdlconstants

implicit none

real :: t,q,rh,prs,theta,fact,epottemp

theta=t*(p0/prs)**0.286
fact=1./(1./(t-55.)-alog(rh*0.01)/2840.)+55.
epottemp=theta*exp(2675.*q/fact)

return
end function

!===============================================================================

subroutine therm(t,q,prspa,ix,kx,thetae)

! Subroutine to calculate thetae (algorithm from Bolton)
! Convert mr to rh
! Convert temp from K to C

! Input/Output:
!    T: temperature (in as K, out as C)
!    Q: in as water vapor mixing ratio (kg/kg) and out as RH (%)
!  PRS: pressure (Pa)
!  thetae: equivalent potential temperature (K)

real :: t(ix,kx),q(ix,kx),thetae(ix,kx),prspa(kx),prs(kx)

prs=prspa/100.
do k=1,kx
do i=1,ix

   if (t(i,k) > 273.16) then
      es=6.11*exp(19.84659-5418.12/t(i,k))
   else
      es=6.11*exp(22.514-6.15e3/t(i,k))
   endif

   qs=.622*es/(prs(k)-es)
   q(i,k)=amax1(1.e-10,q(i,k))
   rh=q(i,k)/qs
   rh=amin1(1.,rh)

   if (rh <= 0.) then
      print*,'rh=',rh,t(i,k),prs(k)
      print*,i,k
      stop
   endif

   theta=t(i,k)*(1000./prs(k))**0.286
   fact=1./(1./(t(i,k)-55.)-alog(rh)/2840.)+55.
   thetae(i,k)=theta*exp(2675.*q(i,k)/fact)
   t(i,k)=t(i,k)-273.15
   q(i,k)=rh*100.

enddo
enddo

return
end subroutine

!===============================================================================

function twk(tpk,tdk,prpa)

! Function to compute wet bulb temperature using iterative approach.
! Inputs - Temp (K), Dewpoint (K), Pressure (Pa).

implicit none

integer :: ipsign,icsign

real :: tpk,tdk,prpa,twk  &
       ,tpc,tdc,prmb,twc  &
       ,e,diff,rinc,ew,eg

tpc=tpk-273.15
tdc=tdk-273.15
prmb=prpa/100.

!e=6.112*exp(17.67*tdc/(tdc+243.5))
if (tpc > 0.) then
   e=6.1121*exp((18.678-tdc/234.5)*tdc/(tdc+257.14))
else
   e=6.1115*exp((23.036-tdc/333.7)*tdc/(tdc+279.82))
endif

twc=tdc

if (tpc-tdc > 0.001) then

!  twc=0.
   ipsign=1
   diff=1.
   rinc=10.
   do while (abs(diff) > 0.005)

!     ew=6.112*exp(17.67*twc/(twc+243.5))
      if (tpc > 0.) then
         ew=6.1121*exp((18.678-twc/234.5)*twc/(twc+257.14))
      else
         ew=6.1115*exp((23.036-twc/333.7)*twc/(twc+279.82))
      endif
      eg=ew-prmb*(tpc-twc)*0.00066*(1.+(0.00115*twc))

      diff=e-eg
      if (diff == 0.) exit

      if (diff < 0.) then
         icsign = -1
      else
         icsign = 1
      endif
      if (icsign /= ipsign) then
         ipsign = icsign
         rinc = rinc/10.
      endif

      twc=twc+rinc*float(ipsign);

   enddo
endif

twk=twc+273.15

return
end function
