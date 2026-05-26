!===============================================================================
!  map_utils.f90
!
!  This routine is converted from Perl code obtained from NOAA/FSL/LAPS.
!
!  This is a Perl module for converting (i,j) to (lat,lon) and vice versa
!  for any of 4 map projections:  Cylindrical Equadistant (lat-lon), 
!  Mercator, lambert conformal (secant and tangent), and polar 
!  stereographic.  
!
!  Usage
!
!    1.  First, you need to know the basic parameters of your map
!        projection and grid:
!          a.  TYPE:Projection type ("LC", "PS", "LL", or "ME" for
!              Lambert Conformal, Polar-Stereographic, Lat/lon cylindrical
!              equidistant, or mercator, respectively.
!          b.  KNOWN_LAT/KNOWN_LON:  You need to know the lat/lon (deg N/E)   
!              of one point on your grid.  Typically, this will be the center
!              or SW corner point, but the module allows the use of any
!              known point on the grid.
!          c.  KNOWN_RI/KNOWN_RJ:  You have to know the real (i,j) coordinate
!              of your known lat/lon.  The value ranges from (1:nx,1:ny), 
!              where nx and ny are the number of grid points in the E-W and
!              N-S direction, respectively.  For example, if KNOWN_LAT/
!              KNOWN_LON represent the SW corner, then KNOWN_RI/KNOWN_RJ
!              should be set to (1.0,1.0).  If you are providing the
!              center point, you should use ( 0.5*(nx+1), 0.5*(ny+1) ).
!              should be the SW corner of the grid
!          d.  DX:The grid spacing in meters at the true latitude (not used
!              for lat/lon grids)
!          e.  TRUELAT1: The latitude at which the grid spacing is true
!              (polar-stereo,
!              lambert conformal, and mercator grids only).  For lat/lon grids,
!              the first truelat value is set to the latitudinal grid spacing
!              in degrees
!          f.  TRUELAT2:The second true latitude if a lambert conformal
!          g.  STDLON:The standard longitude (LC and PS grids only)...
!              for lat/lon 
!              grids the standard longitude is set to the longitudinal
!              grid increment in degrees
!          h.  NX:The number of east-west points
!          i.  NY:The number of north south points
!            

!
!    2.  Once you know all of the above, you call the map_set subroutine,
!        passing in all of the above arguments (even if not used for your
!        particular projection type.  This routine returns a hash:
!
!       my %proj = &map_utils::map_set($TYPE,$KNOWNLAT,$KNOWNLON, 
!                   KNOWN_RI, KNOWN_RJ,$DX,$STDLON,
!                   $TRUELAT1,$TRUELAT2,$NX,$NY);
!   
!    3.  The %proj hash is then used as an input argument to the 
!        coordinate conversion routines.  To convert an (i,j) to
!        a lat/lon, you would call:
!
!        my ($lat,$lon) = &map_utils::ij_to_latlon($i,$j,%proj);
!
!        Or, to convert a lat/lon to an i/j:
!   
!        my ($i,$j) = &map_utils::latlon_to_ij($lat,$lon,%proj);
!
!  History:
!
!   3 Sep 2002:  Initial version checked into LAPS repository..B. Shaw
!
!
!===============================================================================

subroutine map_set(type,knownlat,knownlon,kri,krj,dx,stdlon  &
                  ,truelat1,truelat2,nx,ny,proj)

use proj_info

implicit none

type(projinfo) :: proj
integer :: nx,ny
real :: knownlat,knownlon,kri,krj,dx,stdlon,truelat1,truelat2  &
       ,rswi,rswj,latsw,lonsw
character(len=2) :: type

call map_set_sub(type,knownlat,knownlon,dx,stdlon,truelat1,truelat2,nx,ny,proj)

if (kri .ne. 1. .or. krj .ne. 1.) then
    rswi = 2.0 - kri
    rswj = 2.0 - krj 
    call ij_to_latlon(rswi,rswj,proj,latsw,lonsw)
    
    ! Call map_set again...
    call map_set_sub(type,latsw,lonsw,dx,stdlon,truelat1,truelat2,nx,ny,proj)
endif

return
end

!===============================================================================

subroutine proj_hash(proj)

! Sub for returning a hash to be populated.

use proj_info

implicit none

type(projinfo) :: proj

proj%proj="XX"
proj%latsw=-999.9
proj%lonsw=-999.9
proj%latne=-999.9
proj%lonne=-999.9
proj%latnw=-999.9
proj%lonnw=-999.9
proj%latse=-999.9
proj%lonse=-999.9
proj%latcen=-999.9
proj%loncen=-999.9
proj%dx=-999.9
proj%stdlon=-999.9 
proj%truelat1=-999.9
proj%truelat2=-999.9
proj%hemi=0
proj%cone=-999.9
proj%polei=-999.9
proj%polej=-999.9
proj%rsw=-999.9
proj%rebydx=-999.9
proj%nx=-99
proj%ny=-99
proj%dellon=-999.9

return
end

!===============================================================================

subroutine map_set_sub(type,latsw,lonsw,dx,stdlon,truelat1,truelat2,nx,ny,proj) 

! Sub for setting up hash table defining map structure

use proj_info

implicit none

type(projinfo) :: proj
real, parameter :: earth_radius_m = 6371229.
integer :: nx,ny
real :: latsw,lonsw,dx,stdlon,truelat1,truelat2,reflon,scale_top,alo1  &
       ,deltalon,costl1,param1,clain
real :: sind,cosd,tand
character(len=2) :: type

! Fill missing values into project information hash.

  call proj_hash(proj)
 
! Start populating the hash, doing some validity checks based 
! on projection type.

if (type .ne. 'LL' .and. type .ne. 'PS' .and.  &
    type .ne. 'LC' .and. type .ne. 'ME') then
   print*,'Invalid projection type specified: ',type
   stop
endif

proj%proj = type;

! Ensure latitude of southwest corner is between -90 and 90 degrees.

if (abs(latsw) .gt. 90.) then
   print*,'Invalid lat: ',latsw
   stop
endif

proj%latsw = latsw

! Ensure longitude of southwest corner is between -180 and 180 degrees.

if (abs(lonsw) > 180.) then
   print*,'Invalid SW corner lon: ',lonsw
   stop
endif

proj%lonsw = lonsw

! If not a latlon grid, ensure dx is positive.  Dx is not used
! in the case of a latlon grid.

if ((type .ne. 'LL') .and. (dx .le. 0)) then
   print*,'Invalid dx: ',dx
   print*,' For projections other than lat/lon, dx must be set to'
   print*,' a postive value in meters.'
   stop
endif

proj%dx = dx

! Check stdlon, which should be set for all projection types
! except mercator.  In the case of a latlon grid, this is set
! to an increment.

if (type .ne. 'ME') then
   if (abs(stdlon) .gt. 180.) then
      print*,'Invalid standard longitude: ',stdlon
      print*,' For PS and LC : -180 <= stdlon <= 180'
      print*,' For LL, this should be the delta-lon value.'
      stop
   endif
   if (type .eq. 'LL' .and. stdlon .eq. 0.) then
       print*,'Invalid delta-longitude for LL grid.'
       stop
   endif
   proj%stdlon = stdlon
else
   proj%stdlon = 0.
endif 
 
! All projections use truelat1.  In the case of a Latlon grid, however,
! this is really the delta-lat parameter.

if (abs(truelat1) .gt. 90.) then
   print*,'Invalid true latitude 1: ',truelat1
   stop
endif

if (type .eq. 'LL' .and. truelat1 .eq. 0.) then
   print*,'Delta-lat for LL grid must be non-zero.'
   stop
endif

proj%truelat1 = truelat1

! LC projection requires truelat2.

if (type .eq. 'LC') then
   if (abs(truelat2) .gt. 90.) then 
      print*,'Invalid true latitude 2: ',truelat2
      stop
   endif
   proj%truelat2 = truelat2
endif

! Check nx/ny.

if (nx .le. 1) then
   print*,'Invalid nx: ',nx
   stop
endif

proj%nx = nx

if (ny .le. 1) then
   print*,'Invalid ny: ',ny
   stop
endif

proj%ny = ny

! Fill in the rest of the proj hash.
  
! Hemisphere parameter.

if (type .ne. 'LL') then
   if (truelat1 .lt. 0.) then
      proj%hemi = -1.0
   else
      proj%hemi = 1.0
   endif
   proj%rebydx = earth_radius_m / dx
endif

! Case-dependent calls for final setup.

if (type .eq. 'PS') then
   proj%cone = 1.0
   reflon = proj%stdlon + 90.
   scale_top = 1. + proj%hemi * sind(proj%truelat1)
   proj%rsw = proj%rebydx*cosd(proj%latsw)*scale_top/  &
              (1.+proj%hemi*sind(proj%latsw)) 

   ! Find the pole point
   alo1 = proj%lonsw - reflon
   proj%polei = 1. - proj%rsw * cosd(alo1)
   proj%polej = 1. - proj%hemi * proj%rsw * sind(alo1)
    
elseif (type .eq. 'LC') then
    
   ! Make sure truelat1 <= truelat2
   if (truelat1 .gt. truelat2) then
      proj%truelat1 = truelat2
      proj%truelat2 = truelat1
   endif

   ! Set cone factor.
   call lc_cone(proj%truelat1,proj%truelat2,proj%cone)

   ! Compute longitude differences to avoid the "cut" zone.
   deltalon = proj%lonsw - proj%stdlon
   if (deltalon .gt.  180.) deltalon = deltalon - 360.
   if (deltalon .lt. -180.) deltalon = deltalon + 360. 

   costl1 = cosd(truelat1)

   ! Radius to SW corner.
   proj%rsw = proj%rebydx * costl1/proj%cone *              &
              (tand((90.*proj%hemi-proj%latsw   )/2.) /     &
               tand((90.*proj%hemi-proj%truelat1)/2.) ) **  &
              proj%cone
   
   ! Find the pole point.
   param1 = proj%cone*deltalon
   proj%polei = 1. - proj%hemi * proj%rsw * sind(param1)
   proj%polej = 1. + proj%rsw * cosd(param1)
   
elseif (type .eq. 'ME') then
    clain = cosd(proj%truelat1)
    proj%dellon = proj%dx / (earth_radius_m * clain)
    proj%rsw = 0.
    if (proj%latsw .ne. 0.) then
       proj%rsw = (log(tand(0.5*(proj%latsw+90.))))/proj%dellon
    endif

elseif (type .eq. 'LL') then
    if (proj%lonsw .lt. 0.) proj%lonsw = proj%lonsw + 360.

else
    print*,'Unknown projection: ',type
    stop
endif

! Call ij_to_latlon to fill in corners/center.

call ij_to_latlon(1.,float(ny),proj,proj%latnw,proj%lonnw)
call ij_to_latlon(float(nx),float(ny),proj,proj%latne,proj%lonne)
call ij_to_latlon(float(nx),1.,proj,proj%latse,proj%lonse)
call ij_to_latlon(float(nx+1)*.5,float(ny+1)*.5,proj,proj%latcen,proj%loncen)

return
end

!===============================================================================

subroutine latlon_to_ij(lat,lon,proj,ri,rj) 

! Wrapper subroutine to compute the i/j point (1->nx,1->ny) from
! a provided latitude and longitude for a given projection.  
!
! Arguments:
!
!    lat = input latitude (float value in degrees N)
!    lon = input longitude (float value in degrees E)
!    proj = input map information hash as set up by map_set subroutine
!
!    Returns:  (ri,rj), real i/j values
!

use proj_info

implicit none

type(projinfo) :: proj

real :: lat,lon,ri,rj
  
if (proj%proj .eq. 'PS') then
   call llij_ps(lat,lon,proj,ri,rj)
elseif (proj%proj .eq. 'LC') then
   call llij_lc(lat,lon,proj,ri,rj)
elseif (proj%proj .eq. 'LL') then
   call llij_ll(lat,lon,proj,ri,rj)
elseif (proj%proj .eq. 'ME') then
   call llij_me(lat,lon,proj,ri,rj)
else
   print*,'Unsupported projection type in latlon_to_ij: ',proj%proj
   stop
endif

return
end

!===============================================================================

subroutine ij_to_latlon(ri,rj,proj,lat,lon) 

! Wrapper subroutine to compute the latitude and longitude for 
! a given map/grid projection and a given (i,j) coordinate.
!
! We define the coordinate to be (1,1) at the origin (SW corner) 
!
! Arguments:
!
!    ri = input float i coordinate (E-W direction)
!    rj = input float j coordinate (N-S direction)
!    proj = input map information hash as set up by map_set subroutine
!
!    Returns:  (lat,lon), real lat/lon values in degrees N/E

use proj_info

implicit none

type(projinfo) :: proj

real :: lat,lon,ri,rj

if (proj%proj .eq. 'PS') then
    call ijll_ps(ri,rj,proj,lat,lon)
elseif (proj%proj .eq. 'LC') then
    call ijll_lc(ri,rj,proj,lat,lon)
elseif (proj%proj .eq. 'LL') then
    call ijll_ll(ri,rj,proj,lat,lon)
elseif (proj%proj .eq. 'ME') then
    call ijll_me(ri,rj,proj,lat,lon);
else
   print*,'Unsupported projection type in latlon_to_ij: ',proj%proj
   stop
endif

return
end

!===============================================================================

subroutine llij_ps(lat,lon,proj,ri,rj) 

! Subroutine to compute i/j from lat/lon for a polar-stereographic
! grid projection.  Arguments are the same as for latlon_to_ij...in fact
! ij_to_latlon calls this routine as necessary so the calling routine
! has one interface to all required conversion routines.

use proj_info

implicit none

type(projinfo) :: proj

real :: lat,lon,ri,rj,reflon,scale_top,rm,alo
real :: sind,cosd,tand

reflon = proj%stdlon + 90.
  
! Compute numerator term of map scale factor.

scale_top = 1. + proj%hemi * sind(proj%truelat1)

! Find radius to desired point.

rm = proj%rebydx*cosd(lat)*scale_top/(1.+proj%hemi*sind(lat))
alo = lon-reflon
ri = proj%polei + rm * cosd(alo)
rj = proj%polej + proj%hemi * rm * sind(alo)
  
return
end

!===============================================================================

subroutine ijll_ps(ri,rj,proj,lat,lon) 

! Subroutine to compute lat/lon from i/j for a polar-stereographic
! grid projection.  Arguments are the same as for ij_to_latlon...in fact
! ij_to_latlon calls this routine as necessary so the calling routine
! has one interface to all required conversion routines.

use proj_info

implicit none

type(projinfo) :: proj

real :: lat,lon,ri,rj,reflon,scale_top,xx,yy,r2,gi2,arccos
real :: sind,cosd,tand,asind,acosd

! Compute the reference longitude by rotating 90 degrees to the east
! to find the longitude line parallel to the positive x-axis.

reflon = proj%stdlon + 90.

! Compute numerator term of map scale factor.

scale_top = 1. + proj%hemi * sind(proj%truelat1)

! Compute radius to point of interest.

xx = ri - proj%polei
yy = (rj - proj%polej) * proj%hemi
r2 = xx**2 + yy**2

! Now, the magic code.

if (r2 .eq. 0.) then
   lat = proj%hemi * 90.
   lon = reflon
else
   gi2 = (proj%rebydx * scale_top)**2.
   lat = proj%hemi*asind((gi2-r2)/(gi2+r2)) 
   arccos = acosd(xx/sqrt(r2))
   if (yy .gt. 0) then
      lon = reflon + arccos
   else
      lon = reflon - arccos
   endif
endif
 
! Convert to a -180 -> 180 East convention.

if (lon .gt.  180.) lon = lon - 360. 
if (lon .lt. -180.) lon = lon + 360. 

return
end

!===============================================================================

subroutine llij_lc(lat,lon,proj,ri,rj) 

! Computes i/j from lat/lon for a Lambert Conformal Grid.

use proj_info

implicit none

type(projinfo) :: proj

real :: lat,lon,ri,rj,deltalon,costl1,rm,param1
real :: sind,cosd,tand

! Compute deltalon

deltalon = lon - proj%stdlon
if (deltalon .gt.  180.) deltalon = deltalon - 360. 
if (deltalon .lt. -180.) deltalon = deltalon + 360.

! Get cosine of truelat1 for future use.

costl1 = cosd(proj%truelat1)

! Compute the radius to the desired point

rm = proj%rebydx * costl1/proj%cone *                           &
                  (tand((90.*proj%hemi-lat)/2.) /               &
                   tand((90.*proj%hemi-proj%truelat1)/2.) ) **  &
                  proj%cone

param1 = proj%cone * deltalon
ri = proj%polei + proj%hemi * rm * sind(param1)
rj = proj%polej - rm * cosd(param1)

! If in the southern hemisphere, we need to flip the i/j values such
! that (1,1) is still the SW corner.

if (proj%hemi .eq. -1.) then
   ri = 2. - ri
   rj = 2. - rj
endif

return
end

!===============================================================================

subroutine ijll_lc(ri,rj,proj,lat,lon) 

! Subroutine to compute lat/lon from i/j for Lambert conformal maps.

use proj_info

implicit none

type(projinfo) :: proj

real :: ri,rj,lat,lon,chi1,chi2,xx,yy,r2,r,chi
real :: sind,cosd,tand,atand,atan2d

chi1 = 90. - proj%hemi*proj%truelat1
chi2 = 90. - proj%hemi*proj%truelat2

! Flip indices if we are in southern hemisphere.

if (proj%hemi .lt. 0.) then
   ri = 2. - ri
   rj = 2. - rj
endif 

! Compute square of radius to i/j.

xx = ri - proj%polei
yy = proj%polej - rj
r2 = xx**2. + yy**2.
r = sqrt(r2)/proj%rebydx

! Convert to lat/lon.

if (r2 .eq. 0.) then
   lat = proj%hemi * 90.
   lon = proj%stdlon
else
   lon = proj%stdlon + atan2d(proj%hemi*xx,yy)/proj%cone 
   lon = mod((lon+360),360.)
   if (chi1 .eq. chi2) then
      chi = 2.0 * atand((r/tand(chi1))**(1./proj%cone) * tand(chi1*0.5))
   else
      chi = 2.0 * atand((r*proj%cone/sind(chi1))**(1./proj%cone) *  &
            tand(chi1*0.5)) 
   endif 
   lat = (90.0 - chi) * proj%hemi
endif
if (lon .gt.  180.) lon = lon - 360.
if (lon .lt. -180.) lon = lon + 360. 

return
end

!===============================================================================

subroutine llij_me(lat,lon,proj,ri,rj)

! Subroutine that computes i/j from lat/lon for mercator maps.

use proj_info

implicit none

type(projinfo) :: proj

real, parameter :: rad2deg = 180./3.14159265
real :: lat,lon,ri,rj,deltalon
real :: tand

deltalon = lon - proj%lonsw
if (deltalon .lt. -180.) deltalon = deltalon + 360.
if (deltalon .gt.  180.) deltalon = deltalon - 360. 
ri = 1. + deltalon/(rad2deg*proj%dellon)
rj = 1. + (log(tand(0.5*(lat+90.))))/proj%dellon - proj%rsw

return
end

!===============================================================================

subroutine ijll_me(ri,rj,proj,lat,lon)

! Subroutine that computes lat/lon from i/j for mercator maps.

use proj_info

implicit none

type(projinfo) :: proj

real, parameter :: rad2deg = 180./3.14159265
real :: ri,rj,lat,lon
real :: atand
  
lat = 2.0*atand(exp(proj%dellon*(proj%rsw+rj-1.))) -90.
lon = (ri-1.)*rad2deg*proj%dellon + proj%lonsw
if (lon .gt.  180.) lon = lon - 360.
if (lon .lt. -180.) lon = lon + 360.

return
end

!===============================================================================

subroutine llij_ll(lat,lon,proj,ri,rj)

! Subroutine that computes i/j from lat/lon for lat/lon grids.

use proj_info

implicit none

type(projinfo) :: proj

real :: lat,lon,ri,rj,latinc,loninc,deltalat,lon360,deltalon

latinc = proj%truelat1
loninc = proj%stdlon

! Compute deltalat/deltalon.

deltalat = lat - proj%latsw

! Account for possible issues around dateline

if (lon .lt. 0.) then
   lon360 = lon + 360.
else
   lon360 = lon
endif
  
deltalon = lon360 - proj%lonsw
if (deltalon .lt. 0) deltalon = deltalon + 360.

! Compute i/j.

ri = deltalon/loninc + 1.
rj = deltalat/latinc + 1.

return
end

!===============================================================================

subroutine ijll_ll(ri,rj,proj,lat,lon)

! Subroutine to convert i/j to lat/lon for lat/lon grids.

use proj_info

implicit none

type(projinfo) :: proj

real :: ri,rj,lat,lon,latinc,loninc,deltalat,deltalon


latinc = proj%truelat1
loninc = proj%stdlon

deltalat = (rj-1.)*latinc
deltalon = (ri-1.)*loninc
lat = proj%latsw + deltalat
lon = proj%lonsw + deltalon

if (abs(lat) .gt. 90. .or. abs(deltalon) .gt. 360.) then
   ! Off the earth!
   print*,'Warning:',ri,rj,' is off this grid.'
   lat = -999.
   lon = -999.
else
   lon = lon + 360.
   lon = mod(lon,360.)
   if (lon .gt. 180.) lon = lon - 360
endif

return
end 

!===============================================================================

subroutine lc_cone(truelat1,truelat2,cone) 

! Computes the cone factor for a lambert conformal map.

implicit none

real :: truelat1,truelat2,cone
real :: sind,cosd,tand

if (truelat2 - truelat1 .gt. 0.01) then
   cone = (log(cosd(truelat1)) -                 &
           log(cosd(truelat2))) /                &
          (log(tand((90.-abs(truelat1))*0.5)) -  &
           log(tand((90.-abs(truelat2))*0.5)) )

else
   cone = sind(abs(truelat1))
endif

return
end
