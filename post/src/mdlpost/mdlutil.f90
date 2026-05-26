subroutine get_native_dims

use mdlgrid

implicit none

select case(trim(model))
   case('wrf')
      call get_wrf_dims
   case('nam')
      call get_grib2_dims
   case('gfs')
      call get_grib2_dims
end select

return
end subroutine

!===============================================================================

subroutine get_laps_static

use mdlgrid

implicit none

include 'netcdf.inc'

integer, parameter :: nprmax=150
integer :: icode,ncid,nid,nk_laps,istatus,i

real, dimension(nprmax) :: pressures
real, allocatable, dimension(:,:) :: laps

character(len=256) :: stlaps
character(len=132) :: gridtype

namelist /pressures_nl/pressures

stlaps=trim(lapsdataroot)//'/static/static.nest7grid'
icode=nf_open(trim(stlaps),nf_nowrite,ncid)
if (icode /= 0) then
   print*,'LAPS static file not found: ',trim(stlaps)
   stop
endif
icode=nf_inq_dimid(ncid,'x',nid)
icode=nf_inq_dimlen(ncid,nid,lx)
icode=nf_inq_dimid(ncid,'y',nid)
icode=nf_inq_dimlen(ncid,nid,ly)
icode=nf_inq_varid(ncid,'grid_type',nid)
icode=nf_get_var_text(ncid,nid,gridtype)
icode=nf_inq_varid(ncid,'grid_spacing',nid)
icode=nf_get_var_real(ncid,nid,grid_spacing)
icode=nf_inq_varid(ncid,'Latin1',nid)
icode=nf_get_var_real(ncid,nid,truelat1)
icode=nf_inq_varid(ncid,'Latin2',nid)
icode=nf_get_var_real(ncid,nid,truelat2)
icode=nf_inq_varid(ncid,'LoV',nid)
icode=nf_get_var_real(ncid,nid,stdlon)
if (stdlon > 180.) stdlon=stdlon-360.

! LAPS domain has a halo point surrounding the grid.
! Remove the halo for this application.

if (allocated(llat)) deallocate(llat)
if (allocated(llon)) deallocate(llon)
allocate(laps(lx,ly),llat(lx-2,ly-2),llon(lx-2,ly-2))
icode=nf_inq_varid(ncid,'lat',nid)
icode=nf_get_var_real(ncid,nid,laps)
llat=laps(2:lx-1,2:ly-1)
icode=nf_inq_varid(ncid,'lon',nid)
icode=nf_get_var_real(ncid,nid,laps)
llon=laps(2:lx-1,2:ly-1)
icode=nf_close(ncid)
deallocate(laps)
lx=lx-2
ly=ly-2

if (gridtype(1:5) == 'polar') then
   projection='POLAR STEREOGRAPHIC'
   lapproj=2
elseif (gridtype(1:14) == 'secant lambert') then
   projection='LAMBERT CONFORMAL'
   lapproj=1
elseif (gridtype(1:18) == 'tangential lambert') then
   projection='LAMBERT CONFORMAL'
   lapproj=1
else
   print*,'Unrecognized LAPS grid type: ',trim(gridtype)
   stop
endif

pressures=rmsg
stlaps=trim(lapsdataroot)//'/static/pressures.nl'
open(2,file=trim(stlaps),status='old',err=900)
read(2,pressures_nl,err=901)
close(2)

! Determine number of isobaric levels by checking pressure data.
!   (Assume there is at least one level, and that data is ordered correctly)

do lz=1,nprmax
   if (pressures(lz+1) > 200000.) exit
enddo

if (allocated(lprs)) deallocate(lprs)
if (allocated(lprsl)) deallocate(lprsl)
allocate(lprs(lz),lprsl(lz))
lprs(1:lz)=pressures(1:lz)
lprsl(1:lz)=alog(lprs(1:lz))

return

900 continue
print*,'Could not open laps namelist file: ',trim(stlaps)
stop

901 continue
print*,'Error reading laps namelist file: ',trim(stlaps)
stop

end subroutine

!===============================================================================

subroutine fill_native_grid

use mdlgrid

implicit none

integer :: i,j

! Fill native grids.

select case(trim(model))
   case('wrf')
      call fill_wrf_grid
   case('nam')
      call fill_grib2_grid
   case('gfs')
      call fill_grib2_grid
end select

! Set map utilities for use by horizontal interpolation.

select case(trim(nprojection))
   case('LAMBERT CONFORMAL')
      call map_set(proj_lc,nlat(1,1),nlon(1,1),ngrid_spacingx  &
                  ,nstdlon,ntruelat1,ntruelat2,nx,ny,proj)
   case('POLAR STEREOGRAPHIC')
      call map_set(proj_ps,nlat(1,1),nlon(1,1),ngrid_spacingx  &
                  ,nstdlon,ntruelat1,ntruelat2,nx,ny,proj)
   case('MERCATOR')
      call map_set(proj_merc,nlat(1,1),nlon(1,1),ngrid_spacingx  &
                  ,nstdlon,ntruelat1,ntruelat2,nx,ny,proj)
   case('LAT-LON')
      call map_set(proj_latlon,nlat(1,1),nlon(1,1),nstdlon  &
                  ,ngrid_spacingx,ngrid_spacingy,ntruelat2,nx,ny,proj)
   case('ROTATED LAT-LON')
end select

! If this is a grib2 file, then fill lat/lon grids.

if (trim(model) == 'nam' .or. trim(model) == 'gfs') then
   do j=1,ny
   do i=1,nx
      call ij_to_latlon(proj,float(i),float(j),nlat(i,j),nlon(i,j))
   enddo
   enddo
endif

return
end subroutine

!===============================================================================

subroutine mdl_derived

use mdlgrid
use mdlconstants

implicit none

integer, parameter :: nbl=5
integer :: gct,gct3,gct5,gct10,i,j,k,k700,k500,hour,sec,imin
real :: dz,dtdz,psnow,pice,prain,rat,tdlocal,rhlocal
real,external :: mslp,dewpt,relhum,twk
real, dimension(nx,ny) :: namrain,namsnow,mrdiff
!real, allocatable, dimension(:,:,:) :: tpb,rhb,uwb,vwb
character(len=5) :: afcstm1

k700=0
k500=0
do k=1,lz
   if (lprs(k) == 70000.) k700=k
   if (lprs(k) == 50000.) k500=k
enddo
if (k700 == 0) then
   print*,'700mb level is not defined...Quit...'
   stop
endif
if (k500 == 0) then
   print*,'500mb level is not defined...Quit...'
   stop
endif

! Extrapolate a surface temp if not available.

if (maxval(tpshl) > 1000.) then
   if (verbose) then
      print*,' '
      print*,'t-shelter not available...will extrapolate from lowest level...'
   endif
   do j=1,ly
   do i=1,lx

! Compute dz between lowest sigma layer and 2m level

      dz=hht(i,j,1)-(htsfc(i,j)+2.)

! Compute the lapse rate of temp for the two lowest sigma levels.

      dtdz=(htp(i,j,2)-htp(i,j,1))  &
          /(hht(i,j,2)-hht(i,j,1))
      tpshl(i,j)=htp(i,j,1)-dtdz*dz
   enddo
   enddo
endif

! Fill other missing surface fields from lowest model level.

if (maxval(mrshl) > 1000.) mrshl(:,:)=hmr(:,:,1)
if (maxval(uwshl) > 1000.) uwshl(:,:)=huw(:,:,1)
if (maxval(vwshl) > 1000.) vwshl(:,:)=hvw(:,:,1)
if (maxval(wwsfc) > 1000.) wwsfc(:,:)=hww(:,:,1)

! Other surface fields.

tplow(:,:)=htp(:,:,1)  ! Low-level model temp.
mrlow(:,:)=hmr(:,:,1)  ! Low-level mixing ratio
uwlow(:,:)=huw(:,:,1)  ! Low-level u-velocity.
vwlow(:,:)=hvw(:,:,1)  ! Low-level v-velocity.
tpsfc=tpshl
mrsfc=mrshl
mrdiff=0.
if (trim(model) /= "nam" .and. trim(model) /= "gfs") then
   gct=count((tplow-tpshl) > 2.)
   gct3=count((tplow-tpshl) > 3.)
   gct5=count((tplow-tpshl) > 5.)
   gct10=count((tplow-tpshl) > 10.)
   print*,"Guardrail count:",fcsttime/3600,gct,gct3,gct5,gct10
!  where ((tplow-tpshl) > 3.) mrshl=mrlow
   where ((tplow-tpshl) > 3.) mrdiff=abs(mrshl-mrlow)
!  where ((tplow-tpshl) > 3.) tpshl=tplow-3.
   print*,"MR diff max:",maxval(mrdiff)
endif
uwsfc=uwshl
vwsfc=vwshl
do j=1,ly
do i=1,lx
   slp(i,j)=mslp(htsfc(i,j),prsfc(i,j),tpshl(i,j),mrshl(i,j))
   rhsfc(i,j)=relhum(tpshl(i,j),mrshl(i,j),prsfc(i,j))
   tdsfc(i,j)=dewpt(tpshl(i,j),rhsfc(i,j))
enddo
enddo

! Compute one hour precip totals.
! For precip amounts, we combine graupel and ice into the snow category.
!    But for precip type, we still differentiate.
! Fill sfc precip density and type based on values of rain, snow,
!    and ice precip.
! Calculate frozen accumulation.

if (fcsttime == 0) then
   r01=0.
   pcp=0.
   c01=0.
   npcp=0.
   s01=0.
   sno=0.
   g01=0.
   gra=0.
   i01=0.
   ice=0.
   a01=0.
   acc=0.
   sdn=0.
   spt=0.
else
   sec=fcsttime-fcstinc
   hour=sec/3600
   imin=mod(sec,3600)/60
   write(afcstm1,'(i3.3,i2.2)') hour,imin
   call read_precip(afcstm1)  ! Previous accumulated precip amounts filled into 01 arrays.
   namrain=r01
   namsnow=s01
   if (trim(model) == 'nam') then  ! NAM snowfall is since previous 12 hours, but only for 00 and 12 UTC runs
      if (adate(6:7) == "00" .or. adate(6:7) == "12") then
         if (mod(hour,24) <= 9) then
            hour=hour-mod(hour,24)
         else
            hour=hour-mod(hour,24)+12
         endif
        write(afcstm1,'(i3.3,i2.2)') hour,imin
        call read_snow(afcstm1)  
      endif
   endif

   if (trim(model) == 'nam' .or. trim(model) == 'gfs') then
      where(pcp < 0.) pcp=0.
      where(cpcp < 0.) cpcp=0.
      where(sno < 0.) sno=0.
      where(r01 > 99999.) r01=0.
      where(c01 > 99999.) c01=0.
      where(s01 > 99999.) sno=0.
      if (trim(model) == 'nam') then
         pcp=pcp+r01
         r01=pcp-namrain
         sno=sno+s01
         s01=sno-namsnow
      else
         r01=pcp-r01
         s01=sno-s01
      endif
      where(r01 < 0.) r01=0.
      where(s01 < 0.) s01=0.
      g01=0.
      i01=0.
   else
      sno=sno+gra+ice
      r01=pcp-r01
      where(r01 < 0.) r01=0.
      c01=cpcp-c01
      where(c01 < 0.) c01=0.
      s01=sno-s01
      where(s01 < 0.) s01=0.
      g01=gra-g01
      where(g01 < 0.) g01=0.
      i01=ice-i01
      where(i01 < 0.) i01=0.
   endif

   do j=1,ly
   do i=1,lx
      if (s01(i,j)+g01(i,j)+i01(i,j) > r01(i,j)) then
         rat=r01(i,j)/(s01(i,j)+g01(i,j)+i01(i,j))
         s01(i,j)=rat*s01(i,j)
         g01(i,j)=rat*g01(i,j)
         i01(i,j)=rat*i01(i,j)
      endif
      psnow=s01(i,j)
      pice=g01(i,j)+i01(i,j)
      prain=max(0.,r01(i,j)-psnow-pice)
      call sfc_precip_density(tpshl(i,j),psnow,sdn(i,j))
#     if (trim(model) == 'nam' .or. trim(model) == 'gfs') sdn(i,j)=10.
      if (trim(model) == 'gfs') sdn(i,j)=10.
      call sfc_precip_type(tpshl(i,j),prain,psnow,pice,spt(i,j))
   enddo
   enddo

   acc=a01+g01+i01+s01*sdn
endif

! Calculate boundary layer fields.

!allocate(tpb(lx,ly,nbl),rhb(lx,ly,nbl),uwb(lx,ly,nbl),vwb(lx,ly,nbl))

!call boundary_layer(lx,ly,nz,nbl,prsfc,hpr,htp,hmr,huw,hvw,tpb,rhb,uwb,vwb)

! Compute mixing height using LAPS formula.

!if (trim(model) /= "nam" .and. trim(model) /= 'gfs')  &
!   call model_pblhgt(htp,hpr,hht,htsfc,lx,ly,nz,pbl)

! Compute total precipitable water.

!call totpw(lx,ly,nz,hmr,hpr,htp,hht,htsfc,tpw)

! Compute lifted index.

!call lifted(lx,ly,tpshl,mrshl,rhsfc,prsfc,tp(1,1,k500),lif)

! Compute cloud ceiling and cloud percent.

call cloud(lx,ly,nz,ngrid_spacingx,hliqmr,hicemr,hsnomr,hcloud  &
          ,hht,htsfc,ceil,cldamt)

! Compute height of -5C and 0C isotherms.

call htmtp(lx,ly,nz,hht,htp,-5.,m5z)
call htmtp(lx,ly,nz,hht,htp,0.,m0z)
m0z=m0z*3.28084

! Compute derived wind gust.

if (trim(model) /= "nam" .and. trim(model) /= 'gfs')  &
   gust=sqrt(uwshl**2+vwshl**2)+7.71*ust

! Compute height of wet-bulb 0C.

do k=1,nz
do j=1,ly
do i=1,lx
   rhlocal=relhum(htp(i,j,k),hmr(i,j,k),hpr(i,j,k))
   tdlocal=dewpt(htp(i,j,k),rhlocal)
   hwetb(i,j,k)=twk(htp(i,j,k),tdlocal,hpr(i,j,k))
enddo
enddo
enddo
call htmtp(lx,ly,nz,hht,hwetb,0.,wb0)
wb0=wb0*3.28084

!deallocate(tpb,rhb,uwb,vwb)

return
end subroutine

!===============================================================================

subroutine model_pblhgt(tsig,psig,zsig,topo,nx,ny,nz,pblhgt)

!  Subroutine to estimate height AGL in meters of PBL from native
!  coordinate model data. Adapted from the LAPS routine for
!  terrain-following model coordinates. Uses low-level model 
!  temperature rather than "shelter" temp.

use mdlconstants

implicit none

integer :: nx,ny,nz
real, dimension(nx,ny,nz) :: tsig,psig,zsig,thsig
real, dimension(nx,ny) :: topo,pblhgt

integer :: i,j,k,ktop
real :: thresh_k,topwgt,botwgt
logical :: found_pbl_top

thsig=tsig*(p0/psig)**kappa

do j=1,ny
do i=1,nx

! Compute threshold value that theta needs to exceed
! to be above PBL. We use surface theta plus an
! additional 3K for slop.

   thresh_k = thsig(i,j,1) + 3.0

! Now begin at the bottom and work our way up until
! we find the first level with a theta exceeding the
! threshold.

   found_pbl_top = .false.
   loop_k: do k=1,nz
      if (thsig(i,j,k) >= thresh_k) then
         ktop = k
         found_pbl_top = .true.
         exit loop_k
      endif
   enddo loop_k

! If we did not find a good PBL, set PBL to first level
! and print out some diagnostics.

   if (.not. found_pbl_top) then
      print*, 'PBL height not found at i/j = ',i,j
      print*, 'Surface Theta = ', thsig(i,j,1)
      print*, 'Theta in the column:'
      print*, 'Pressure Height  Theta'
      print*, '-------- ------- --------'
      do k=nz,1,-1
         print '(f8.0,f8.0,f8.2)',psig(i,j,k),zsig(i,j,k),thsig(i,j,k)
      enddo
      ktop = nz
      pblhgt(i,j) = zsig(i,j,nz) - topo(i,j)

   else

! We found the top k-level bounding the PBL so interpolate
! to the actual level.

      if (ktop == 1) then
         pblhgt(i,j) = zsig(i,j,1) - topo(i,j)
      else
! Interpolate to get height at thresh_k.
         botwgt = ( (thsig(i,j,ktop-1)-thresh_k) / &
                    (thsig(i,j,ktop-1)-thsig(i,j,ktop)) )
         topwgt = 1.0 - botwgt
         pblhgt(i,j) = botwgt * zsig(i,j,ktop) + &
                       topwgt * zsig(i,j,ktop-1) - topo(i,j)
      endif
   endif
enddo
enddo

return
end subroutine

!===============================================================================

subroutine totpw(nx,ny,nz,vapor_mr,pr,tp,height,topo,totpcpwater)

! Computes total precip. water (mm=kg/m**2) in a column.

use mdlconstants

implicit none

integer :: nx,ny,nz,i,j,k
real, dimension(nx,ny,nz) :: vapor_mr,pr,tp,height
real, dimension(nx,ny) :: topo,totpcpwater
real :: height_top,height_bot,rho,dz

do j=1,ny
do i=1,nx
   totpcpwater(i,j) = 0.0
   do k=1,nz
      ! Compute layer thickness
      if (k == 1) then
         height_bot = topo(i,j)
         height_top = 0.5*(height(i,j,1)+height(i,j,2))
      elseif (k == nz) then
         height_bot = 0.5*(height(i,j,nz-1)+height(i,j,nz))
         height_top = 2*height(i,j,nz)-height_bot
      else
         height_bot = 0.5*(height(i,j,k-1)+height(i,j,k))
         height_top = 0.5*(height(i,j,k)+height(i,j,k+1))
      endif
      dz = height_top - height_bot
      rho=pr(i,j,k)/r/tp(i,j,k)   
      totpcpwater(i,j) = totpcpwater(i,j)+vapor_mr(i,j,k)*rho*dz
   enddo
enddo
enddo

return
end subroutine

!===============================================================================

subroutine lifted(nx,ny,stp,smr,srh,spr,t500,li)

implicit none

integer :: nx,ny,i,j
real, dimension(nx,ny) :: stp  &  !Sfc temp (K)
                         ,smr  &  !Sfc mixing ratio (kg/kg)
                         ,srh  &  !Sfc rh (%)
                         ,spr  &  !Sfc pressure (Pa)
                         ,t500 &  !500mb temp (K)
                         ,li      !Lifted index (K)
real :: thetae,epottemp,tparcel

do j=1,ny
do i=1,nx
   thetae=epottemp(stp(i,j),smr(i,j),srh(i,j),spr(i,j))
   call the2t(thetae,50000.0,tparcel)
   li(i,j)=t500(i,j)-tparcel
enddo
enddo

return
end subroutine

!===============================================================================

subroutine cloud(nx,ny,nz,grid_spacing,cldliqmr,cldicemr,snowmr,hcloud  &
                ,height,topo,ceil,cldpct)

implicit none

integer :: nx,ny,nz,i,j,k,ii,jj,ct

real :: cldliqmr(nx,ny,nz),cldicemr(nx,ny,nz),snowmr(nx,ny,nz),hcloud(nx,ny,nz)  &
       ,height(nx,ny,nz),topo(nx,ny),lceil(nx,ny),ceil(nx,ny),cldpct(nx,ny)      &
       ,grid_spacing,icethresh,snowthresh,liqthresh

! Set thresholds for cloud determination based on grid resolution.

if (grid_spacing <= 10000.) then
   icethresh  = 0.0000005
   snowthresh = 0.0000003
   liqthresh  = 0.0000003
else
   icethresh  = 0.000005
   snowthresh = 0.000025
   liqthresh  = 0.000025
endif

if (maxval(hcloud) > 1.) then
   do j=1,ny
   do i=1,nx
      lceil(i,j)=1.e37
      find_base: do k=1,nz
         if ( (cldliqmr(i,j,k) >= liqthresh) .or. &
              (cldicemr(i,j,k) >= icethresh) .or. &
              (snowmr(i,j,k)   >= snowthresh) ) then
            lceil(i,j) = height(i,j,k) - topo(i,j)
            exit find_base
         endif
      enddo find_base
   enddo
   enddo
else
   do j=1,ny
   do i=1,nx
      lceil(i,j)=1.e37
      find_base_1: do k=1,nz
         if (hcloud(i,j,k) > 0.) then
            lceil(i,j) = height(i,j,k) - topo(i,j)
            exit find_base_1
         endif
      enddo find_base_1
   enddo
   enddo
endif

do j=1,ny
do i=1,nx
   cldpct(i,j)=0.
   ct=0
   do jj=max(1,j-2),min(ny,j+2)
   do ii=max(1,i-2),min(nx,i+2)
      ct=ct+1
      if (lceil(ii,jj) < 1.e10) cldpct(i,j)=cldpct(i,j)+1.
   enddo
   enddo
   cldpct(i,j)=cldpct(i,j)/float(ct)*100.
enddo
enddo

do j=1,ny
do i=1,nx
   ceil(i,j)=1.e37
   do jj=max(1,j-2),min(ny,j+2)
   do ii=max(1,i-2),min(nx,i+2)
      ceil(i,j)=min(ceil(i,j),lceil(ii,jj))
   enddo
   enddo
enddo
enddo

return
end subroutine

!===============================================================================

subroutine htmtp(nx,ny,nz,ht,tp,tpref,mtpz)

use mdlconstants

implicit none

integer :: nx,ny,nz,i,j,k

real, dimension(nx,ny,nz) :: ht,tp
real, dimension(nx,ny) :: mtpz
real :: tpref,tpk,dz,rat

tpk=tpref+273.15
do j=1,ny
do i=1,nx
   if (tp(i,j,1) < tpk) then
      dz=(tpk-tp(i,j,1))/lapse
      mtpz(i,j)=ht(i,j,1)-dz
   else
      mtpz(i,j)=ht(i,j,nz)
      do k=1,nz-1
         if (tp(i,j,k) >= tpk .and. tp(i,j,k+1) < tpk) then
            rat=(tp(i,j,k)-tpk)/(tp(i,j,k)-tp(i,j,k+1))
            dz=ht(i,j,k+1)-ht(i,j,k)
            mtpz(i,j)=ht(i,j,k)+dz*rat
            exit
         endif
      enddo
   endif
enddo
enddo

return
end subroutine

!===============================================================================

subroutine read_precip(afcst)

use mdlgrid

implicit none

include 'netcdf.inc'

integer :: icode,nid,ncid,i,j

character(len=256) :: outname
character(len=5)   :: afcst

logical exists

outname=trim(lapsdataroot)//'/lapsprd/fsf/'//trim(model)//'/'//adate//'_'//afcst//'.fsf'

print *,'Reading precip <-- ',trim(outname)

! Open precip cdf file.
inquire(file=trim(outname),exist=exists)
if (exists) then
   icode=nf_open(trim(outname),nf_nowrite,ncid)
else
   print *,'Could not open file',trim(outname)
   r01=0.
   c01=0.
   s01=0.
   g01=0.
   i01=0.
   a01=0.
   return
endif
!print*,'Open precip file...'

! Read precip.

icode=nf_inq_varid(ncid,'rto',nid)
icode=nf_get_var_real(ncid,nid,r01)
icode=nf_inq_varid(ncid,'rcto',nid)
icode=nf_get_var_real(ncid,nid,c01)
icode=nf_inq_varid(ncid,'sto',nid)
icode=nf_get_var_real(ncid,nid,s01)
icode=nf_inq_varid(ncid,'gto',nid)
icode=nf_get_var_real(ncid,nid,g01)
icode=nf_inq_varid(ncid,'ito',nid)
icode=nf_get_var_real(ncid,nid,i01)
icode=nf_inq_varid(ncid,'acc',nid)
icode=nf_get_var_real(ncid,nid,a01)

icode=nf_close(ncid)

return
end subroutine

!===============================================================================

subroutine read_snow(afcst)

use mdlgrid

implicit none

include 'netcdf.inc'

integer :: icode,nid,ncid,i,j

character(len=256) :: outname
character(len=5)   :: afcst

logical exists

outname=trim(lapsdataroot)//'/lapsprd/fsf/'//trim(model)//'/'//adate//'_'//afcst//'.fsf'

print *,'Reading snow <-- ',trim(outname)

! Open precip cdf file.
inquire(file=trim(outname),exist=exists)
if (exists) then
   icode=nf_open(trim(outname),nf_nowrite,ncid)
else
   print *,'Could not open file',trim(outname)
   s01=0.
   return
endif
!print*,'Open snow file...'

! Read snow.

icode=nf_inq_varid(ncid,'sto',nid)
icode=nf_get_var_real(ncid,nid,s01)

icode=nf_close(ncid)

return
end subroutine

!===============================================================================

subroutine boundary_layer(nx,ny,nz,nbl,spr,pr,tp,mr,uw,vw,tpb,rhb,uwb,vwb)

implicit none

integer :: nx,ny,nz,nbl,i,j,k,kk,l
integer, dimension(50,40) :: ind
integer, dimension(40) ::  nl

real :: dp,rh,relhum
real, dimension(nx,ny,nz) :: pr,tp,mr,uw,vw
real, dimension(nx,ny,nbl) :: tpb,rhb,uwb,vwb
real, dimension(nx,ny) :: spr
real, dimension(50,40) :: fac

do j=1,ny
do i=1,nx
   dp=spr(i,j)-(pr(i,j,1)+pr(i,j,2))*0.5
   nl(1)=1
   fac(1,1)=min(3000.,dp)
   ind(1,1)=1
   l=1
   k=1
   do while (spr(i,j)-(pr(i,j,k)+pr(i,j,k-1))*0.5 <= 15000.) 
      if (spr(i,j)-(pr(i,j,k-1)+pr(i,j,k-2))*0.5 > float(l)*3000.) then
         nl(l)=nl(l)+1
         fac(nl(l),l)=float(l)*3000.-(spr(i,j)-(pr(i,j,k)+pr(i,j,k-1))*0.5)
         ind(nl(l),l)=k-1
         l=l+1
         nl(l)=1
         fac(nl(l),l)=spr(i,j)-(pr(i,j,k-1)+pr(i,j,k-2))*0.5-float(l-1)*3000.
         ind(nl(l),l)=k-1
      else
         nl(l)=nl(l)+1
         fac(nl(l),l)=(pr(i,j,k)-pr(i,j,k-2))*0.5
         ind(nl(l),l)=k-1
      endif
      k=k+1
   enddo
   do k=1,nbl
      tpb(i,j,k)=fac(1,k)*tp(i,j,ind(1,k))
      rh=relhum(tp(i,j,ind(1,k)),mr(i,j,ind(1,k)),pr(i,j,ind(1,k)))
      rhb(i,j,k)=fac(1,k)*rh
      uwb(i,j,k)=fac(1,k)*uw(i,j,ind(1,k))
      vwb(i,j,k)=fac(1,k)*vw(i,j,ind(1,k))
      do kk=2,nl(k)
         tpb(i,j,k)=tpb(i,j,k)+fac(kk,k)*tp(i,j,ind(kk,k))
         rh=relhum(tp(i,j,ind(kk,k)),mr(i,j,ind(kk,k)),pr(i,j,ind(kk,k)))
         rhb(i,j,k)=rhb(i,j,k)+fac(kk,k)*rh
         uwb(i,j,k)=uwb(i,j,k)+fac(kk,k)*uw(i,j,ind(kk,k))
         vwb(i,j,k)=vwb(i,j,k)+fac(kk,k)*vw(i,j,ind(kk,k))
      enddo
      tpb(i,j,k)=tpb(i,j,k)/3000.
      rhb(i,j,k)=rhb(i,j,k)/3000.
      uwb(i,j,k)=uwb(i,j,k)/3000.
      vwb(i,j,k)=vwb(i,j,k)/3000.
   enddo
enddo
enddo

return
end subroutine

!===============================================================================

subroutine sfc_precip_density(stp,snow,density)

implicit none

real :: stp,snow,tpf,density

tpf=(stp-273.15)*1.8+32.
if (snow > 0. .and. tpf < 36.) then
   if (tpf <= 20.) then
      density=15.
   elseif (tpf <= 32.) then
      density=15.+(20.-tpf)*0.5
   else
      density=9.+(32.-tpf)*2.
   endif
else
  density=1.
endif

return
end subroutine

!===============================================================================

subroutine sfc_precip_type(stp,rain,snow,ice,code)

implicit none

real :: stp,rain,snow,ice,ptot,low  &
       ,code                        &
       ,nonecode=0.                 &
       ,raincode=1                  &
       ,snowcode=2.                 &
       ,icecode=3.                  &
       ,rainsnowcode=4.             &
       ,snowraincode=5.             &
       ,rainicecode=6.              &
       ,iceraincode=7.              &
       ,snowicecode=8.              &
       ,icesnowcode=9.              &
       ,zraincode=10.               &
       ,zrainsnowcode=11.           &
       ,snowzraincode=12.           &
       ,zrainicecode=13.            &
       ,icezraincode=14.

! If total precip is less than .005 inch then set to none.

ptot=rain+snow+ice
if (ptot < 0.1270) then
   code=nonecode
   return
endif

! If any one type is less than 10% of total then zero it out.

if (rain/ptot < 0.1) rain=0.
if (snow/ptot < 0.1) snow=0.
if (ice /ptot < 0.1) ice =0.

! If any type is less than .001 inch then zero it out.

if (rain < 0.0254) rain=0.
if (snow < 0.0254) snow=0.
if (ice  < 0.0254) ice =0.

! If all 3 types exist, zero out smallest.

if (rain > 0. .and. snow > 0. .and. ice > 0.) then
   low=min(rain,snow,ice)
   if (ice == low) then
      ice=0.
   elseif (snow == low) then
      snow=0.
   else
      rain=0.
   endif
endif

! Assign precip type.

if (rain > 0.) then
   if (snow > 0.) then
      if (snow > rain) then
         if (stp > 273.15) then
            code=snowraincode
         else
            code=snowzraincode
         endif
      else
         if (stp > 272.) then
            code=rainsnowcode
         else
            code=zrainsnowcode
         endif
      endif
   elseif (ice > 0.) then
      if (ice > rain) then
         if (stp > 272.) then
            code=iceraincode
         else
            code=icezraincode
         endif
      else
         if (stp > 272.) then
            code=rainicecode
         else
            code=zrainicecode
         endif
      endif
   else
      if (stp > 272.) then
         code=raincode
      else
         code=zraincode
      endif
   endif
else
   if (snow > 0.) then
      if (ice > 0.) then
         if (snow > ice) then
            code=snowicecode
         else
            code=icesnowcode
         endif
      else
         code=snowcode
      endif
   else
      if (ice > 0.) then
         code=icecode
      else
         code=nonecode
      endif
   endif
endif

return
end subroutine

!===============================================================================

subroutine solmax(adate,nsta,lat,lon,solmx)

! Calculate maximum downward solar irradiance.
! (based on Pielke, p.211)

use mdlconstants

implicit none

integer :: jday,ihr,imin,n,nsta

real :: lat(nsta),lon(nsta),rat,sundec,gt,lt,hr  &
       ,solz,cosz,d0,solmx(nsta)

character*9 adate

read(adate(3:9),'(i3,2i2)') jday,ihr,imin

! Calculate sun declination angle assuming 
!    max= 23.5 degrees on June 21 (jday 172) and
!    min=-23.5 degrees on Dec. 22 (jday 356).

if (jday .ge. 172 .and. jday .le. 356) then
   rat=float(jday-172)/184.
else
   if (jday .gt. 356) then
      rat=float(537-jday)/181.
   else 
      rat=float(172-jday)/181.
   endif
endif
sundec=23.5-rat*47.

! Account for time varying earth-sun distance.

d0=pi2d*float(jday-1)
rat=1.00011+0.034221*cos(   d0)+0.001280*sin(   d0)  &
           +0.000719*cos(2.*d0)+0.000077*sin(2.*d0)

gt=float(ihr)+float(imin)/60.
do n=1,nsta

! Calculate hour angle based on 0 degrees for noon.

   lt=gt+lon(n)/15.
   if (lt .lt.  0.) lt=lt+24.
   if (lt .gt. 24.) lt=lt-24.
   hr=-180.+lt*15.

! Calculate cos of zenith angle.

   cosz=cosd(lat(n))*cosd(sundec)*cosd(hr)+sind(sundec)*sind(lat(n))

   solmx(n)=max(s0*rat*cosz,0.)

enddo

return
end subroutine

!===============================================================================

subroutine adate_to_i4time(adate,i4time)

implicit none

integer :: iyear,iday,ihour,imin,lp,i4time

character :: adate*9

read(adate(1:2),'(i2)') iyear
read(adate(3:5),'(i3)') iday
read(adate(6:7),'(i2)') ihour
read(adate(8:9),'(i2)') imin

! Valid for years 1960-2060.

if (iyear .lt. 60) iyear = iyear + 100

lp = (iyear + 3 - 60) / 4

i4time = (iyear-60)  * 31536000  &
       + (iday-1+lp) * 86400     &
       + ihour       * 3600      &
       + imin        * 60

return
end subroutine

!===============================================================================

subroutine i4time_to_adate(i4time,adate)

implicit none

integer :: i4time,ltime,iyear,iday,ihour,imin,leap

character(len=9) :: adate

ltime=i4time
iyear=60
leap=86400
do while (ltime >= 31536000+leap)
   iyear=iyear+1
   ltime=ltime-31536000-leap
   if (mod(iyear,4) == 0) then
      leap=86400
   else
      leap=0
   endif
enddo

iday=1
do while (ltime >= 86400)
   iday=iday+1
   ltime=ltime-86400
enddo

ihour=0
do while (ltime >= 3600)
  ihour=ihour+1
  ltime=ltime-3600
enddo

imin=0
do while (ltime >= 60)
   imin=imin+1
   ltime=ltime-60
enddo

iyear=mod(iyear,100)
write(adate,'(i2.2,i3.3,2i2.2)') iyear,iday,ihour,imin

return
end subroutine

!===============================================================================

subroutine adate9_to_adate8(adate9,adate8)

implicit none

integer :: iyr,imm,jjj,idy,ihh,imin,i,kk
integer, dimension(12) :: imon_a,imon
character(len=9) :: adate9
character(len=8) :: adate8
data imon_a/0,31,59,90,120,151,181,212,243,273,304,334/

! Read adate9 and get julian days.

read(adate9,'(i2,i3,2i2)') iyr, jjj, ihh, imin

! Check for leap year.

do i=1,12
   imon(i) = imon_a(i)
enddo 
if (mod(iyr,4) == 0) then
   do i=3,12
      imon(i) = imon(i) + 1
   enddo
endif

! Convert julian day to month, day.

do i=12,1,-1
   kk = jjj - imon(i)
   if (kk > 0) then
      imm = i
      idy = kk
      goto 200
   elseif (kk == 0) then
      imm = i - 1
      idy = jjj - imon(imm)
      goto 200
   endif
enddo
imm = 1
idy = jjj

200  continue

! Write out the time.

write(adate8,'(4i2.2)') iyr, imm, idy, ihh

return
end subroutine

!===============================================================================

subroutine cv_i4tim_asc_lp(i4time,atime,istatus)

! Takes in an i4time and returns the time as an ASCII string
!  (e.g. 27-MAR-1990 12:30:00.00 ). The i4time is assumed to
!  be a 1960-relative time, although the starting year is easily
!  changed in the code.

implicit none

integer :: i4time,istatus,rmndr,nsec,monthsec(12),year,month,day,hour,min,sec

character(len=24) :: atime
character(len=4) :: ayear
character(len=3) :: amonth(12)
character(len=2) :: aday,ahour,amin,asec

data  monthsec/2678400,2419200,2678400,2592000  &
              ,2678400,2592000,2678400,2678400  &
              ,2592000,2678400,2592000,2678400/

data  amonth/'JAN','FEB','MAR','APR','MAY','JUN'  &
            ,'JUL','AUG','SEP','OCT','NOV','DEC'/

if (i4time < 0) then
   istatus=0
   write (6,*) 'Error in input to cv_i4tim_asc_lp: negative time'
   return
endif

rmndr=i4time
do year=1960,2100
   if (mod(year,4) == 0) then
      nsec=31622400
   else
      nsec=31536000
   endif
   if (rmndr < nsec) exit
   rmndr=rmndr-nsec
enddo

do month=1,12
   nsec=monthsec(month)
   if (mod(year,4) == 0 .and. month == 2) nsec=nsec+86400
   if (rmndr < nsec) exit
   rmndr=rmndr-nsec
enddo

do day=1,31
   if (rmndr < 86400) exit
   rmndr=rmndr-86400
enddo

do hour=0,23
   if (rmndr < 3600) exit
   rmndr=rmndr-3600
enddo

do min=0,59
   if (rmndr < 60) exit
   rmndr=rmndr-60
enddo

sec=rmndr

write(ayear,'(i4)') year
write(aday,'(i2)') day
write(ahour,'(i2.2)') hour
write(amin,'(i2.2)') min
write(asec,'(i2.2)') sec

atime=aday//'-'//amonth(month)//'-'//ayear//' '//ahour//':'//amin//':'//asec//'.00 '

istatus=1

return
end subroutine

!===============================================================================

subroutine adate9_to_adate18(adate9,adate18)

implicit none

integer :: iyr,imm,jjj,idy,ihh,imin,i,kk
integer, dimension(12) :: imon_a,imon
character(len=18) :: adate18
character(len=9) :: adate9
data imon_a/0,31,59,90,120,151,181,212,243,273,304,334/

! Read adate9 and get julian days.

read(adate9,'(i2,i3,2i2)') iyr, jjj, ihh, imin

! Check for leap year.

do i=1,12
   imon(i) = imon_a(i)
enddo
if (mod(iyr,4) == 0) then
   do i=3,12
      imon(i) = imon(i) + 1
   enddo
endif

! Convert julian day to month, day.

do i=12,1,-1
   kk = jjj - imon(i)
   if (kk > 0) then
      imm = i
      idy = kk
      goto 200
   elseif (kk == 0) then
      imm = i - 1
      idy = jjj - imon(imm)
      goto 200
   endif
enddo
imm = 1
idy = jjj

200  continue

! Write out the time.

write(adate18,'(i4,2(''-'',i2.2),'' '',i2.2,'':00'')') iyr+2000, imm, idy, ihh

return
end subroutine
