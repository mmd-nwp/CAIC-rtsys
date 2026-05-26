module grib2util

use grib_mod
use mdlgrid

implicit none

save

type(gribfield) :: gfld
integer :: ifile=10  &
          ,guess=-1  &
          ,jdisc=-1  &
          ,jpdtn=-1  &
          ,jgdtn=-1  &
          ,iret,irec,orec
integer, dimension(200) :: jids=-9999  &
                          ,jpdt=-9999  &
                          ,jgdt=-9999
logical :: gunpack=.true.

end module

!===============================================================================

subroutine get_grib2_dims

use grib2util

implicit none

character(len=4) :: afcst
logical :: there

! Create and grib2 file.

write(afcst,'(i4.4)') fcsttime/3600
filename='/data/noaaport/grids/'//trim(model)//'/grib2/'//adate//afcst

! Open grib2 file, and leave open for future use.

inquire(file=trim(filename),exist=there)
if (there) then
   call sleep(delay)
   call baopenr(ifile,trim(filename),iret)
   if (iret /= 0) then
      print*,'Could not open grib2 file: ',trim(filename)
      stop
   else
      print*,'Opened ',trim(model),' file: ',trim(filename)
   endif
else
   print*,'Could not find grib2 file: ',trim(filename)
   stop
endif

! Read grib2 grid dimensions.
! nz is hardwired, otherwise the entire grib file needs to read to determine nz.

irec=0
orec=0

call getgb2(ifile,ifile,irec,guess,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt  &
    ,gunpack,orec,gfld,iret)

if (iret /= 0) then
   print*,'Error reading first grib2 record.'
   stop
endif

nx=gfld%igdtmpl(8)
ny=gfld%igdtmpl(9)
if (trim(model) == "nam") then
  nz=39
elseif (trim(model) == "gfs") then
  nz=22
endif

return
end subroutine

!===============================================================================

subroutine fill_grib2_grid

use grib2util

implicit none

integer :: mapproj,dis,cat,par,lcd,lvl,inc,i,j,k
real :: mrsat,factor=1.e6
real, external :: mixsat
real, dimension(22) :: prgfs
! Define gfs pressure levels to ingest. 50, 30, 20, 10 mb levels are available,
!  but not needed.
data prgfs/1000.,975.,950.,925.,900.,850.,800.,750.,700.,650.,600.,550.,500.  &
          , 450.,400.,350.,300.,250.,200.,150.,100., 70./ 

! Fill native map projection settings.

mapproj=gfld%igdtnum

if (mapproj /= 0 .and. mapproj /= 30) then
   print*,'Unsupported grib2 map projection:',mapproj
   stop
endif

select case (mapproj)
   case(0)
      nprojection='LAT-LON'
      ngrid_spacingx=float(gfld%igdtmpl(17))/factor
      ngrid_spacingy=-float(gfld%igdtmpl(18))/factor
      nlat(1,1)=float(gfld%igdtmpl(12))/factor
      nlon(1,1)=float(gfld%igdtmpl(13))/factor
   case(30)
      nprojection='LAMBERT CONFORMAL'
      ngrid_spacingx=float(gfld%igdtmpl(15))/factor*1000.
      ngrid_spacingy=float(gfld%igdtmpl(16))/factor*1000.
      ntruelat1=float(gfld%igdtmpl(19))/factor
      ntruelat2=float(gfld%igdtmpl(20))/factor
      nstdlon=float(gfld%igdtmpl(14))/factor
      nlat(1,1)=float(gfld%igdtmpl(10))/factor
      nlon(1,1)=float(gfld%igdtmpl(11))/factor
end select

if (nstdlon > 180.) nstdlon=nstdlon-360.
if (nlon(1,1) > 180.) nlon(1,1)=nlon(1,1)-360.

! Read model data.

if (trim(model) == 'nam') then
   do k=1,nz
      npr(:,:,k)=102500.-float(k)*2500.
   enddo
elseif (trim(model) == 'gfs') then
   do k=1,nz
      npr(:,:,k)=prgfs(k)*100.
   enddo
endif

irec=0
iret=0
do

   if (irec /= 0)  &
      call getgb2(ifile,0,irec,guess,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt  &
                 ,gunpack,orec,gfld,iret)

   if (iret /= 0) exit

   dis=gfld%discipline
   cat=gfld%ipdtmpl(1)
   par=gfld%ipdtmpl(2)
   lcd=gfld%ipdtmpl(10)
   lvl=gfld%ipdtmpl(12)
   inc=gfld%ipdtmpl(27)

   if (lcd == 100) then
      if (trim(model) == 'nam') then
         k=41-(lvl/2500)
      elseif (trim(model) == 'gfs') then
         if (lvl < int(npr(1,1,nz))) then
            call gf_free(gfld)
            irec=irec+1
            cycle
         endif
         do k=1,nz
            if (int(npr(1,1,k)) == lvl) exit
         enddo
      endif
   endif

!  print*,"====",irec,cat,par,lcd,lvl,"========================"

   if (dis == 0 .and. cat == 3 .and. par == 0 .and. lcd == 1 .and. lvl == 0) then        ! Sfc pressure
      call g2fill(nx,ny,gfld%fld,nprsfc)
   elseif (dis == 0 .and. cat == 3 .and. par == 5 .and. lcd == 1 .and. lvl == 0) then    ! Surface height
      call g2fill(nx,ny,gfld%fld,nhtsfc)
   elseif (dis == 0 .and. cat == 0 .and. par == 0 .and. lcd == 103 .and. lvl == 2) then  ! Shelter temp
      call g2fill(nx,ny,gfld%fld,ntpshl)
   elseif (dis == 0 .and. cat == 1 .and. par == 1 .and. lcd == 103 .and. lvl == 2) then  ! Shelter RH
      call g2fill(nx,ny,gfld%fld,nmrshl)
   elseif (dis == 0 .and. cat == 2 .and. par == 2 .and. lcd == 103 .and. lvl == 10) then ! Shelter u-wind
      call g2fill(nx,ny,gfld%fld,nuwshl)
   elseif (dis == 0 .and. cat == 2 .and. par == 3 .and. lcd == 103 .and. lvl == 10) then ! Shelter v-wind
      call g2fill(nx,ny,gfld%fld,nvwshl)
   elseif (dis == 0 .and. cat == 2 .and. par == 22 .and. lcd == 1 .and. lvl == 0) then   ! Gust
      call g2fill(nx,ny,gfld%fld,ngust)
   elseif (dis == 0 .and. cat == 0 .and. par == 0 .and. lcd == 1 .and. lvl == 0) then    ! Surface temp
      call g2fill(nx,ny,gfld%fld,ntpgnd)
   elseif (dis == 2 .and. cat == 0 .and. par == 2 .and. lcd == 106 .and. lvl == 0) then  ! Soil temp
      call g2fill(nx,ny,gfld%fld,ntpsl1)
   elseif (dis == 0 .and. cat == 1 .and. par == 8 .and. lcd == 1 .and. lvl == 0) then    ! 3-h non-conv precip
      if (inc == 3) then
         call g2fill(nx,ny,gfld%fld,npcp)
      endif
      if (trim(model) == 'gfs' .and. fcsttime/3600 == inc) then
         call g2fill(nx,ny,gfld%fld,npcp)
      endif
   elseif (dis == 0 .and. cat == 1 .and. par == 10 .and. lcd == 1 .and. lvl == 0) then   ! 3-h conv precip
      if (inc == 3) then
         call g2fill(nx,ny,gfld%fld,ncpcp)
      endif
      if (trim(model) == 'gfs' .and. fcsttime/3600 == inc) then
         call g2fill(nx,ny,gfld%fld,ncpcp)
      endif
   elseif (dis == 0 .and. cat == 1 .and. par == 13 .and. lcd == 1 .and. lvl == 0) then   ! Delta snow water equiv
!     if (fcsttime/3600 == inc) call g2fill(nx,ny,gfld%fld,nsno)
      if (fcsttime == 0) then
         nsno=0.
      elseif (mod(inc,3) == 0 .or. trim(model) == 'gfs') then
         call g2fill(nx,ny,gfld%fld,nsno)
      endif
   elseif (dis == 0 .and. cat == 3 .and. par == 196 .and. lcd == 1 .and. lvl == 0) then  ! PBL height
      call g2fill(nx,ny,gfld%fld,npbl)
   elseif (dis == 0 .and. cat == 4 .and. par == 192 .and. lcd == 1 .and. lvl == 0) then  ! Incoming SW rad
      call g2fill(nx,ny,gfld%fld,nswin)
   elseif (dis == 0 .and. cat == 5 .and. par == 192 .and. lcd == 1 .and. lvl == 0) then  ! Incoming LW rad
      call g2fill(nx,ny,gfld%fld,nlwin)
   elseif (dis == 0 .and. cat == 4 .and. par == 193 .and. lcd == 1 .and. lvl == 0) then  ! Outgoing SW rad
      call g2fill(nx,ny,gfld%fld,nswout)
   elseif (dis == 0 .and. cat == 5 .and. par == 193 .and. lcd == 1 .and. lvl == 0) then  ! Outgoing LW rad
      call g2fill(nx,ny,gfld%fld,nlwout)
   elseif (dis == 0 .and. cat == 3 .and. par == 5 .and. lcd == 100) then                 ! 3d height
      call g2fill(nx,ny,gfld%fld,nht(:,:,k))
   elseif (dis == 0 .and. cat == 0 .and. par == 0 .and. lcd == 100) then                 ! 3d temp
      call g2fill(nx,ny,gfld%fld,ntp(:,:,k))
   elseif (dis == 0 .and. cat == 1 .and. par == 1 .and. lcd == 100) then                 ! 3d RH
      call g2fill(nx,ny,gfld%fld,nmr(:,:,k))
   elseif (dis == 0 .and. cat == 2 .and. par == 2 .and. lcd == 100) then                 ! 3d u-wind
      call g2fill(nx,ny,gfld%fld,nuw(:,:,k))
   elseif (dis == 0 .and. cat == 2 .and. par == 3 .and. lcd == 100) then                 ! 3d v-wind
      call g2fill(nx,ny,gfld%fld,nvw(:,:,k))
   elseif (dis == 0 .and. cat == 2 .and. par == 9 .and. lcd == 100) then                 ! 3d w-wind
      call g2fill(nx,ny,gfld%fld,nww(:,:,k))
   endif

   call gf_free(gfld)
   irec=irec+1

enddo

call baclose(ifile,iret)

where(npcp < 0.) npcp=0.
where(ncpcp < 0.) ncpcp=0.
where(nsno < 0.) nsno=0.
npcp=npcp-ncpcp
where(npcp < 0.) npcp=0.

! Convert RH to mixing ratio

do k=1,nz
do j=1,ny
do i=1,nx
   mrsat=mixsat(ntp(i,j,k),npr(i,j,k))
   nmr(i,j,k)=nmr(i,j,k)*mrsat/100.
enddo
enddo
enddo

do j=1,ny
do i=1,nx
   mrsat=mixsat(ntpshl(i,j),nprsfc(i,j))
   nmrshl(i,j)=nmrshl(i,j)*mrsat/100.
enddo
enddo

ngra=0.
nice=0.

return
end subroutine

!===============================================================================

subroutine g2fill(nx,ny,fldin,fldout)

implicit none

integer :: nx,ny
real, dimension(nx,ny) :: fldin,fldout

fldout=fldin

return
end subroutine
