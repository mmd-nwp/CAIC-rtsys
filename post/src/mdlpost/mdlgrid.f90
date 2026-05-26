module mdlgrid

use map_utils

implicit none

save

logical, parameter :: verbose=.false.
logical, parameter :: xsec=.false.     ! Generate xsec netcdf files

real, parameter :: rmsg=1.e37

integer :: nx,ny,nz,lx,ly,lz,nvar2d,nvar3d,nvar2dout,nvar3dout,nvar3dx
integer*2 :: lapproj

type(proj_info) :: proj

integer :: fcstgrid,fcsttime,fcstinc,delay

character(len=256) :: filename,lapsdataroot,fsfname,fuaname,xsecname,gribname,db_script,image_script
character(len=32)  :: domain,res,model
character(len=18)  :: dbtime
character(len=9)   :: adate

! Image generation host list parameters.

integer, parameter :: maxhost=15
integer :: nhost
character(len=256) :: proclist
character(len=10) :: hosts(maxhost)

! Grib parameters.

integer, parameter :: startb=1         &
                     ,table_version=2  &
                     ,center_id=59     &  ! FSL
                     ,subcenter_id=2   &  ! LAPB
                     ,process_id=255
integer :: grib_inc,igds(18),funit,nbytes,period_sec

! Native grid map specifications.

real :: ngrid_spacingx,ngrid_spacingy,nstdlon,ntruelat1,ntruelat2
character(len=32) :: nprojection

! Laps grid map specifications.

real :: grid_spacing,stdlon,truelat1,truelat2
character(len=32) :: projection

real, target, allocatable, dimension(:,:,:) :: ngrid   ! Native model grid
real, target, allocatable, dimension(:,:,:) :: hgrid   ! Horizontally interpolated 3d grid
real, target, allocatable, dimension(:,:,:) :: pgrid   ! Isobaric output grid
real, target, allocatable, dimension(:,:,:) :: sgrid   ! Horizontally interpolated sfc output grid

! Native grid variables.

real, allocatable, dimension(:,:) :: nlat,nlon
real, pointer, dimension(:,:) ::  &
       nhtsfc       & ! Surface height (m)
      ,nprsfc       & ! Surface pressure (Pa)
      ,ntpshl       & ! Shelter height temperature (K)
      ,nmrshl       & ! Shelter height mixing ratio (kg/kg)
      ,nuwshl       & ! Shelter height u-wind (m/s)
      ,nvwshl       & ! Shelter height v-wind (m/s)
      ,nwwsfc       & ! Surface w-wind (m/s)
      ,ntpgnd       & ! Ground temperature (K)
      ,ntpsl1       & ! Soil level 1 temperature (K)
      ,npbl         & ! PBL height (m)
      ,npcp         & ! Non-convective precipitation (mm)
      ,ncpcp        & ! Convective precipitation (mm)
      ,nsno         & ! Snow (mm)
      ,ngra         & ! Graupel (mm)
      ,nice         & ! Ice (mm)
      ,nlwout       & ! Outgoing longwave radiation (W/m**2)
      ,nswout       & ! Outgoing shortwave radiation (W/m**2)
      ,nlwin        & ! Incoming longwave radiation (W/m**2)
      ,nswin        & ! Incoming shortwave radiation (W/m**2)
      ,nfrzamt      & ! Fraction of frozen precipitation (%)
      ,nust         & ! U-star (m/s)
      ,ngust        & ! Gust (m/s)
      ,nhsn           ! Height of snow (m)
real, pointer, dimension(:,:,:) :: &
       npr          & ! 3d Pressure (Pa)
      ,nht          & ! 3d Height (m)
      ,ntp          & ! 3d Temperature (K)
      ,nmr          & ! 3d Mixing ratio (kg/kg)
      ,nuw          & ! 3d U-wind (m/s)
      ,nvw          & ! 3d V-wind (m/s)
      ,nww          & ! 3d W-wind (m/s)
      ,nliqmr       & ! 3d Cloud liquid mixing ratio (kg/kg)
      ,nraimr       & ! 3d precipitating rain mixing ratio (kg/kg)
      ,nicemr       & ! 3d precipitating ice mixing ratio (kg/kg)
      ,nsnomr       & ! 3d precipitating snow mixing ratio (kg/kg)
      ,ngramr       & ! 3d precipitating graupel mixing ratio
      ,nstab        & ! 3d stability
      ,ncloud         ! 3d existence of cloud (WRF, 0 = no, 1 = yes)

! Horizontally interpolated 3d grid variables.

real, pointer, dimension(:,:,:) :: &
       hpr          & ! 3d Pressure (Pa)
      ,hht          & ! 3d Height (m)
      ,htp          & ! 3d Temperature (K)
      ,hmr          & ! 3d Mixing ratio (kg/kg)
      ,huw          & ! 3d U-wind (m/s)
      ,hvw          & ! 3d V-wind (m/s)
      ,hww          & ! 3d W-wind (m/s)
      ,hliqmr       & ! 3d Cloud liquid mixing ratio (kg/kg)
      ,hraimr       & ! 3d precipitating rain mixing ratio (kg/kg)
      ,hicemr       & ! 3d precipitating ice mixing ratio (kg/kg)
      ,hsnomr       & ! 3d precipitating snow mixing ratio (kg/kg)
      ,hgramr       & ! 3d precipitating graupel mixing ratio
      ,hstab        & ! 3d stability
      ,hcloud       & ! 3d existence of cloud

      ,hwetb          ! 3d wet-bulb temperature (K)

! Laps isobaric 3d grid variables.

real, allocatable, dimension(:) :: lprs,lprsl
real, pointer, dimension(:,:,:) ::  &
       ht           & ! 3d Height (m)
      ,tp           & ! 3d Temperature (K)
      ,mr           & ! 3d Mixing ratio (kg/kg)
      ,uw           & ! 3d U-wind (m/s)
      ,vw           & ! 3d V-wind (m/s)
      ,ww           & ! 3d W-wind (m/s)
      ,liqmr        & ! 3d Cloud liquid mixing ratio (kg/kg)
      ,raimr        & ! 3d precipitating rain mixing ratio (kg/kg)
      ,icemr        & ! 3d precipitating ice mixing ratio (kg/kg)
      ,snomr        & ! 3d precipitating snow mixing ratio (kg/kg)
      ,gramr        & ! 3d precipitating graupel mixing ratio
      ,stab           ! 3d stability

!     ,rh             ! 3d Relative humidity (%)

! Laps surface grid variables.

real, allocatable, dimension(:,:) :: llat,llon
real, pointer, dimension(:,:) ::  &
       htsfc        & ! Surface height (m)
      ,prsfc        & ! Surface pressure (Pa)
      ,tpshl        & ! Surface temperature (K)
      ,mrshl        & ! Shelter height mixing ratio (kg/kg)
      ,uwshl        & ! Shelter height u-wind (m/s)
      ,vwshl        & ! Shelter height v-wind (m/s)
      ,wwsfc        & ! Shelter height w-wind (m/s)
      ,tpgnd        & ! Ground temperature (K)
      ,tpsl1        & ! Soil level 1 temperature (K)
      ,pbl          & ! PBL height (m)
      ,pcp          & ! Non-convective precipitation (mm)
      ,cpcp         & ! Convective precipitation (mm)
      ,sno          & ! Snow (mm)
      ,gra          & ! Graupel (mm)
      ,ice          & ! Ice (mm)
      ,lwout        & ! Outgoing longwave radiation (W/m**2)
      ,swout        & ! Outgoing shortwave radiation (W/m**2)
      ,lwin         & ! Incoming longwave radiation (W/m**2)
      ,swin         & ! Incoming shortwave radiation (W/m**2)
      ,frzamt       & ! fraction of frozen precipitation (%)
      ,ust          & ! U-star (m/s)
      ,gust         & ! Wind gust (m/s)
      ,hsn          & ! Height of snow (m)

      ,tdsfc        & ! Surface dew point (K)
      ,rhsfc        & ! Surface relativie humidity (%)
      ,slp          & ! Mean sea-level pressure (Pa)
      ,tpsfc        & ! Surface temperature (K)
      ,mrsfc        & ! Surface mixing ratio (kg/kg)
      ,uwsfc        & ! Surface u-wind (m/s)
      ,vwsfc        & ! Surface v-wind (m/s)
      ,tplow        & ! Low-level temperature (K)
      ,mrlow        & ! Low-level mixing ratio (kg/kg)
      ,uwlow        & ! Low-level u-wind (m/s)
      ,vwlow        & ! Low-level v-wind (m/s)
      ,lif          & ! Lifted index (K)
      ,cldamt       & ! Cloud amount (%)
      ,ceil         & ! Cloud ceiling (m)
      ,tpw          & ! Total precipitable water (mm)
      ,r01          & ! Non-convective 1-h rain (mm)
      ,c01          & ! Convective 1-h rain (mm)
      ,s01          & ! 1-h snow (mm)
      ,g01          & ! 1-h graupel (mm)
      ,i01          & ! 1-h ice (mm)
      ,a01          & ! 1-h precip accumulation (mm)
      ,sdn          & ! Snow density (kg/m**3)
      ,spt          & ! Precip type (code)
      ,acc          & ! Total snow accumulation (mm)
      ,m5z          & ! Height of -5C isotherm (m)
      ,m0z          & ! Height of 0C isotherm (ft) [freezing level]
      ,wb0            ! Height of 0C wet-bulb (ft) 

!     ,odv            ! Ozone deposition velocity (mm/s)

! Point forecast, time height, and sounding variables.

integer :: npf,nth,nsn    ! Number of pt forecasts, time-heights, and sndgs.
real, allocatable, dimension(:) :: pflat,pflon,pfht   &  ! lat, lon, ht
                                  ,pfi,pfj            &  ! model grid i,j
                                  ,pfspr,pfstp,pfstd  &
                                  ,pfsuw,pfsvw,pfsww  &
                                  ,pfswr,pflwr,pfsmx  &
                                  ,pfltp,pfluw,pflvw  &
                                  ,pfsgt,pfslt,pfsht  &
                                  ,pfpbl,pfrto,pfrtc  &
                                  ,pfsto,pfmsl,pfsrh  &
                                  ,pfvis,pfcei,pfspt  &
                                  ,pfcld,pfwtb,pfm5z  &
                                  ,pf7tp,pf7cw,pf7uw  &
                                  ,pf7vw,pfgst
real, allocatable, dimension(:) :: thlat,thlon,thht   &  ! lat, lon, ht
                                  ,thi,thj            &  ! model grid i,j
                                  ,thspr
real, allocatable, dimension(:,:) :: thtp,thte,thmr   &
                                    ,thuw,thvw,thww
real, allocatable, dimension(:) :: snlat,snlon        &  ! lat, lon
                                  ,sni,snj               ! model grid i,j
real, allocatable, dimension(:,:) :: snht,snpr,sntp   &  ! Pres (mb), temp (C)
                                    ,sntd,snsp,sndi      ! Speed (knots)
character(len=256) :: pffile,thfile,snfile
character(len=30), allocatable, dimension(:) :: pffulname,thfulname,snfulname
character(len=10), allocatable, dimension(:) :: pfname,thname,snname

contains

!===============================================================================

subroutine alloc_native_grid

implicit none

integer :: ct

nvar2d=23
nvar3d=14

if (allocated(nlat)) deallocate(nlat)
if (allocated(nlon)) deallocate(nlon)
allocate(nlat(nx,ny),nlon(nx,ny))

if (allocated(ngrid)) deallocate(ngrid)
allocate(ngrid(nx,ny,nvar2d+nvar3d*nz))

ngrid=rmsg

ct=1

nhtsfc  =>ngrid(1:nx,1:ny,ct); ct=ct+1
nprsfc  =>ngrid(1:nx,1:ny,ct); ct=ct+1
ntpshl  =>ngrid(1:nx,1:ny,ct); ct=ct+1
nmrshl  =>ngrid(1:nx,1:ny,ct); ct=ct+1
nuwshl  =>ngrid(1:nx,1:ny,ct); ct=ct+1
nvwshl  =>ngrid(1:nx,1:ny,ct); ct=ct+1
nwwsfc  =>ngrid(1:nx,1:ny,ct); ct=ct+1
ntpgnd  =>ngrid(1:nx,1:ny,ct); ct=ct+1
ntpsl1  =>ngrid(1:nx,1:ny,ct); ct=ct+1
npbl    =>ngrid(1:nx,1:ny,ct); ct=ct+1
npcp    =>ngrid(1:nx,1:ny,ct); ct=ct+1
ncpcp   =>ngrid(1:nx,1:ny,ct); ct=ct+1
nsno    =>ngrid(1:nx,1:ny,ct); ct=ct+1
ngra    =>ngrid(1:nx,1:ny,ct); ct=ct+1
nice    =>ngrid(1:nx,1:ny,ct); ct=ct+1
nlwout  =>ngrid(1:nx,1:ny,ct); ct=ct+1
nswout  =>ngrid(1:nx,1:ny,ct); ct=ct+1
nlwin   =>ngrid(1:nx,1:ny,ct); ct=ct+1
nswin   =>ngrid(1:nx,1:ny,ct); ct=ct+1
nfrzamt =>ngrid(1:nx,1:ny,ct); ct=ct+1
nust    =>ngrid(1:nx,1:ny,ct); ct=ct+1
ngust   =>ngrid(1:nx,1:ny,ct); ct=ct+1
nhsn    =>ngrid(1:nx,1:ny,ct); ct=ct+1

npr     =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nht     =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
ntp     =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nmr     =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nuw     =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nvw     =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nww     =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nliqmr  =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nicemr  =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nraimr  =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nsnomr  =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
ngramr  =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
nstab   =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz
ncloud  =>ngrid(1:nx,1:ny,ct:ct+nz-1); ct=ct+nz

return
end subroutine

!===============================================================================

subroutine alloc_hinterp_grid

implicit none

integer :: ct

nvar3dx=1

if (allocated(hgrid)) deallocate(hgrid)
allocate(hgrid(lx,ly,(nvar3d+nvar3dx)*nz))  

hgrid=rmsg

ct=1

hpr    =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hht    =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
htp    =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hmr    =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
huw    =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hvw    =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hww    =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hliqmr =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hicemr =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hraimr =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hsnomr =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hgramr =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hstab  =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz
hcloud =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz

hwetb  =>hgrid(1:lx,1:ly,ct:ct+nz-1); ct=ct+nz

return
end subroutine

!===============================================================================

subroutine alloc_isobaric_grid

implicit none

integer :: ct

nvar3dout=12

if (allocated(pgrid)) deallocate(pgrid)
allocate(pgrid(lx,ly,nvar3dout*lz))

pgrid=rmsg

ct=1

ht    =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
tp    =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
mr    =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
uw    =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
vw    =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
ww    =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
liqmr =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
icemr =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
raimr =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
snomr =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
gramr =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz
stab  =>pgrid(1:lx,1:ly,ct:ct+lz-1); ct=ct+lz

return
end subroutine

!===============================================================================

subroutine alloc_surface_grid

implicit none

integer :: ct

nvar2dout=50

if (allocated(sgrid)) deallocate(sgrid)
allocate(sgrid(lx,ly,nvar2dout))

sgrid=rmsg

ct=1

! The order of the first set of variables needs to match the order of 
!   the surface variables in the native grid.

htsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
prsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
tpshl  =>sgrid(1:lx,1:ly,ct); ct=ct+1
mrshl  =>sgrid(1:lx,1:ly,ct); ct=ct+1
uwshl  =>sgrid(1:lx,1:ly,ct); ct=ct+1
vwshl  =>sgrid(1:lx,1:ly,ct); ct=ct+1
wwsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
tpgnd  =>sgrid(1:lx,1:ly,ct); ct=ct+1
tpsl1  =>sgrid(1:lx,1:ly,ct); ct=ct+1
pbl    =>sgrid(1:lx,1:ly,ct); ct=ct+1
pcp    =>sgrid(1:lx,1:ly,ct); ct=ct+1
cpcp   =>sgrid(1:lx,1:ly,ct); ct=ct+1
sno    =>sgrid(1:lx,1:ly,ct); ct=ct+1
gra    =>sgrid(1:lx,1:ly,ct); ct=ct+1
ice    =>sgrid(1:lx,1:ly,ct); ct=ct+1
lwout  =>sgrid(1:lx,1:ly,ct); ct=ct+1
swout  =>sgrid(1:lx,1:ly,ct); ct=ct+1
lwin   =>sgrid(1:lx,1:ly,ct); ct=ct+1
swin   =>sgrid(1:lx,1:ly,ct); ct=ct+1
frzamt =>sgrid(1:lx,1:ly,ct); ct=ct+1
ust    =>sgrid(1:lx,1:ly,ct); ct=ct+1
gust   =>sgrid(1:lx,1:ly,ct); ct=ct+1
hsn    =>sgrid(1:lx,1:ly,ct); ct=ct+1

tdsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
rhsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
slp    =>sgrid(1:lx,1:ly,ct); ct=ct+1
tpsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
mrsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
uwsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
vwsfc  =>sgrid(1:lx,1:ly,ct); ct=ct+1
tplow  =>sgrid(1:lx,1:ly,ct); ct=ct+1
mrlow  =>sgrid(1:lx,1:ly,ct); ct=ct+1
uwlow  =>sgrid(1:lx,1:ly,ct); ct=ct+1
vwlow  =>sgrid(1:lx,1:ly,ct); ct=ct+1
lif    =>sgrid(1:lx,1:ly,ct); ct=ct+1
cldamt =>sgrid(1:lx,1:ly,ct); ct=ct+1
ceil   =>sgrid(1:lx,1:ly,ct); ct=ct+1
tpw    =>sgrid(1:lx,1:ly,ct); ct=ct+1
r01    =>sgrid(1:lx,1:ly,ct); ct=ct+1
c01    =>sgrid(1:lx,1:ly,ct); ct=ct+1
s01    =>sgrid(1:lx,1:ly,ct); ct=ct+1
g01    =>sgrid(1:lx,1:ly,ct); ct=ct+1
i01    =>sgrid(1:lx,1:ly,ct); ct=ct+1
a01    =>sgrid(1:lx,1:ly,ct); ct=ct+1
sdn    =>sgrid(1:lx,1:ly,ct); ct=ct+1
spt    =>sgrid(1:lx,1:ly,ct); ct=ct+1
acc    =>sgrid(1:lx,1:ly,ct); ct=ct+1
m5z    =>sgrid(1:lx,1:ly,ct); ct=ct+1
m0z    =>sgrid(1:lx,1:ly,ct); ct=ct+1
wb0    =>sgrid(1:lx,1:ly,ct); ct=ct+1

return
end subroutine

!===============================================================================

subroutine alloc_point_forecast

implicit none

allocate(pfspr(npf),pfstp(npf),pfstd(npf)  &
        ,pfsuw(npf),pfsvw(npf),pfsww(npf)  &
        ,pfswr(npf),pflwr(npf),pfsmx(npf)  &
        ,pfltp(npf),pfluw(npf),pflvw(npf)  &
        ,pfsgt(npf),pfslt(npf),pfsht(npf)  &
        ,pfpbl(npf),pfrto(npf),pfrtc(npf)  &
        ,pfsto(npf),pfmsl(npf),pfsrh(npf)  &
        ,pfvis(npf),pfcei(npf),pfspt(npf)  &
        ,pfcld(npf),pfwtb(npf),pfm5z(npf)  &
        ,pf7tp(npf),pf7cw(npf),pf7uw(npf)  &
        ,pf7vw(npf),pfgst(npf))

return
end subroutine

!===============================================================================

subroutine alloc_time_height

implicit none

allocate(thspr(nth)                               &
        ,thtp(nth,lz),thte(nth,lz),thmr(nth,lz)   &
        ,thuw(nth,lz),thvw(nth,lz),thww(nth,lz))

return
end subroutine

!===============================================================================

subroutine alloc_sndg

implicit none

allocate(snht(nsn,nz+1),snpr(nsn,nz+1),sntp(nsn,nz+1)   &
        ,sntd(nsn,nz+1),snsp(nsn,nz+1),sndi(nsn,nz+1))

return
end subroutine

!===============================================================================

subroutine dealloc_grid(gtype)

implicit none

character(len=*) :: gtype

select case(trim(gtype))
   case('native')
      deallocate(ngrid,nlat,nlon)
   case('horiz')
      deallocate(hgrid)
   case('isobaric')
      deallocate(pgrid)
   case('surface')
      deallocate(sgrid)
end select

return
end subroutine

!===============================================================================

subroutine dealloc_points

implicit none

if (allocated(pfspr))            &
   deallocate(pfspr,pfstp,pfstd  &
             ,pfsuw,pfsvw,pfsww  &
             ,pfswr,pflwr,pfsmx  &
             ,pfltp,pfluw,pflvw  &
             ,pfsgt,pfslt,pfsht  &
             ,pfpbl,pfrto,pfrtc  &
             ,pfsto,pfmsl,pfsrh  &
             ,pfvis,pfcei,pfspt  &
             ,pfcld,pfwtb,pfm5z  &
             ,pf7tp,pf7cw,pf7uw  &
             ,pf7vw,pfgst)

if (allocated(thspr))            &
   deallocate(thspr,thtp,thte,thmr,thuw,thvw,thww)

if (allocated(snht))             &
   deallocate(snht,snpr,sntp,sntd,snsp,sndi)

return
end subroutine

end module
