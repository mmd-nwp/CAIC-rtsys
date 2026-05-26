module wrfutil

implicit none

save

integer :: ncid

end module

!===============================================================================

subroutine get_wrf_dims

use wrfutil
use mdlgrid

implicit none

include 'netcdf.inc'

integer :: nid,icode,i4time
character(len=9) :: wrfdate9
character(len=8) :: wrfdate8
character(len=2) :: agrid
logical :: there

! Create wrf file name.

call adate_to_i4time(adate,i4time)
i4time=i4time+fcsttime
call i4time_to_adate(i4time,wrfdate9)
call adate9_to_adate8(wrfdate9,wrfdate8)
write(agrid,'(i2.2)') fcstgrid

filename='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate  &
       //'/wrfout_d'//agrid//'_20'//wrfdate8(1:2)//'-'//wrfdate8(3:4)//'-'//wrfdate8(5:6)//'_'//wrfdate8(7:8)//':00:00'

! Open wrf file, and leave open for future use.

inquire(file=trim(filename),exist=there)
if (there) then
   call sleep(delay)
   icode=nf_open(trim(filename),nf_nowrite,ncid)
   if (ncid <= 0) then
      print*,'Could not open wrf file: ',trim(filename)
      stop
   else
      print*,'Opened wrf file: ',trim(filename)
   endif
else
   print*,'Could not find wrf file: ',trim(filename)
   stop
endif

! Read wrf grid dimensions.

icode=nf_inq_dimid(ncid,'west_east',nid)
icode=nf_inq_dimlen(ncid,nid,nx)
icode=nf_inq_dimid(ncid,'south_north',nid)
icode=nf_inq_dimlen(ncid,nid,ny)
icode=nf_inq_dimid(ncid,'bottom_top',nid)
icode=nf_inq_dimlen(ncid,nid,nz)

return
end

!===============================================================================

subroutine fill_wrf_grid

use mdlgrid
use wrfutil
use mdlconstants

implicit none

include 'netcdf.inc'

integer :: nid,icode,mapproj,i,j,k
real, parameter :: t00=300.
real, allocatable, dimension(:,:,:) :: fld3d
real, allocatable, dimension(:,:)   :: fld2d
logical :: bad

! Fill native map projection settings.

icode=nf_get_att_int(ncid,NF_GLOBAL,'MAP_PROJ',mapproj)
icode=nf_get_att_real(ncid,NF_GLOBAL,'DX',ngrid_spacingx)
icode=nf_get_att_real(ncid,NF_GLOBAL,'DY',ngrid_spacingy)
icode=nf_get_att_real(ncid,NF_GLOBAL,'TRUELAT1',ntruelat1)
icode=nf_get_att_real(ncid,NF_GLOBAL,'TRUELAT2',ntruelat2)
icode=nf_get_att_real(ncid,NF_GLOBAL,'STAND_LON',nstdlon)

select case (mapproj)
   case(1)
      nprojection='LAMBERT CONFORMAL'
   case(2)
      nprojection='POLAR STEREOGRAPHIC'
   case(3)
      nprojection='MERCATOR'
end select

! Read model data.

icode=nf_inq_varid(ncid,'U',nid)
if (icode == 0) then
   allocate(fld3d(nx+1,ny,nz))
   icode=nf_get_var_real(ncid,nid,fld3d)
   do i=1,nx
      nuw(i,:,:)=(fld3d(i,:,:)+fld3d(i+1,:,:))*0.5
   enddo
   deallocate(fld3d)
endif

icode=nf_inq_varid(ncid,'V',nid)
if (icode == 0) then
   allocate(fld3d(nx,ny+1,nz))
   icode=nf_get_var_real(ncid,nid,fld3d)
   do j=1,ny
      nvw(:,j,:)=(fld3d(:,j,:)+fld3d(:,j+1,:))*0.5
   enddo
   deallocate(fld3d)
endif

icode=nf_inq_varid(ncid,'P',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,npr)
   icode=nf_inq_varid(ncid,'PB',nid)
   if (icode == 0) then
      allocate(fld3d(nx,ny,nz))
      icode=nf_get_var_real(ncid,nid,fld3d)
      npr=npr+fld3d
      deallocate(fld3d)
   else
      npr=rmsg
   endif
endif

icode=nf_inq_varid(ncid,'T',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,ntp)
   ntp=(ntp+t00)*(npr/p0)**kappa
endif

icode=nf_inq_varid(ncid,'QVAPOR',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nmr)

icode=nf_inq_varid(ncid,'QCLOUD',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nliqmr)

icode=nf_inq_varid(ncid,'QICE',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nicemr)

icode=nf_inq_varid(ncid,'QRAIN',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nraimr)

icode=nf_inq_varid(ncid,'QSNOW',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nsnomr)

icode=nf_inq_varid(ncid,'QGRAUP',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,ngramr)

allocate(fld3d(nx,ny,nz+1))
icode=nf_inq_varid(ncid,'W',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,fld3d)
   do k=1,nz
      nww(:,:,k)=(fld3d(:,:,k)+fld3d(:,:,k+1))*0.5
   enddo
endif

icode=nf_inq_varid(ncid,'PH',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,fld3d)
   do k=1,nz
      nht(:,:,k)=(fld3d(:,:,k)+fld3d(:,:,k+1))*0.5
   enddo
   icode=nf_inq_varid(ncid,'PHB',nid)
   if (icode == 0) then
      icode=nf_get_var_real(ncid,nid,fld3d)
      do k=1,nz
         nht(:,:,k)=(nht(:,:,k)+(fld3d(:,:,k)+fld3d(:,:,k+1))*0.5)/g
      enddo
   else
      nht=rmsg
   endif
endif
deallocate(fld3d)

icode=nf_inq_varid(ncid,'TSK',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,ntpgnd)

icode=nf_inq_varid(ncid,'PSFC',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nprsfc)

icode=nf_inq_varid(ncid,'T2',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,ntpshl)

icode=nf_inq_varid(ncid,'Q2',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nmrshl)

icode=nf_inq_varid(ncid,'U10',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nuwshl)

icode=nf_inq_varid(ncid,'V10',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nvwshl)

icode=nf_inq_varid(ncid,'RAINC',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,ncpcp)
else
   ncpcp=0.
endif

! Sanity check.

bad=.false.
if (minval(npr) <=     0. .or. maxval(npr) > 200000.) bad=.true.
if (minval(nht) <= -9999. .or. maxval(nht) >  99999.) bad=.true.
if (minval(ntp) <=     0. .or. maxval(ntp) >    500.) bad=.true.
if (bad) then
   print*,'Appears to be missing data in WRF output file.'
   stop
endif

icode=nf_inq_varid(ncid,'RAINNC',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,npcp)
else
   npcp=0.
endif

! WRF combines snow and ice into the snow field.

icode=nf_inq_varid(ncid,'SNOWNC',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,nsno)
else
   nsno=0.
endif
nice=0.

icode=nf_inq_varid(ncid,'GRAUPELNC',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,ngra)
else
   ngra=0.
endif

icode=nf_inq_varid(ncid,'HGT',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nhtsfc)

icode=nf_inq_varid(ncid,'XLAT',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nlat)

icode=nf_inq_varid(ncid,'XLONG',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nlon)

icode=nf_inq_varid(ncid,'SWDOWN',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nswin)

icode=nf_inq_varid(ncid,'ALBEDO',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nswout)

icode=nf_inq_varid(ncid,'GLW',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nlwin)

icode=nf_inq_varid(ncid,'OLR',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nlwout)

icode=nf_inq_varid(ncid,'CLDFRA',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,ncloud)

icode=nf_inq_varid(ncid,'SR',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nfrzamt)

icode=nf_inq_varid(ncid,'UST',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nust)

icode=nf_inq_varid(ncid,'SNOWH',nid)
if (icode == 0) icode=nf_get_var_real(ncid,nid,nhsn)

!icode=nf_inq_varid(ncid,'LH',nid)
!if (icode == 0) icode=nf_get_var_real(ncid,nid,nlhflux)

!icode=nf_inq_varid(ncid,'HFX',nid)
!if (icode == 0) icode=nf_get_var_real(ncid,nid,nshflux)

icode=nf_inq_varid(ncid,'PBLH',nid)
if (icode == 0) then
   icode=nf_get_var_real(ncid,nid,npbl)
   if (maxval(npbl) <= 1.) npbl=rmsg
endif

icode=nf_inq_varid(ncid,'TSLB',nid)
if (icode == 0) then
   allocate(fld3d(nx,ny,4))
   icode=nf_get_var_real(ncid,nid,fld3d)
   ntpsl1=fld3d(:,:,1)
   deallocate(fld3d)
endif

icode=nf_close(ncid)

! Fill total precip (non-convective + convective).

where(ncpcp < 0.) ncpcp=0.
where(npcp < 0.) npcp=0.
where(nsno < 0.) nsno=0.
!npcp=npcp+conpcp
!if (maxval(ntpshl) < 350.) where(ntpshl <= 273.15) nsno=nsno+conpcp

! Convert albedo to outgoing shortwave radiation.

nswout=nswout*nswin

if (fcsttime == 0) then
   nlwin=rmsg
   nswin=rmsg
!  nshflux=rmsg
!  nlhflux=rmsg
endif

! Compute stability,

allocate(fld2d(nx,ny))
do k=1,nz
   if (k == 1) then
      fld2d(:,:)=(ntp(:,:,k+1)-ntpshl(:,:))/(nht(:,:,k+1)-nhtsfc(:,:))
   elseif (k == nz) then
      fld2d(:,:)=(ntp(:,:,k)-ntp(:,:,k-1))/(nht(:,:,k)-nht(:,:,k-1))
   else
      fld2d(:,:)=(ntp(:,:,k+1)-ntp(:,:,k-1))/(nht(:,:,k+1)-nht(:,:,k-1))
   endif
   nstab(:,:,k)=g/ntp(:,:,k)*(fld2d(:,:)+gocp)
enddo
deallocate(fld2d)

return
end
