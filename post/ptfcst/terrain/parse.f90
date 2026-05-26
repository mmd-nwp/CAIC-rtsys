program parse_terrain

implicit none

include 'netcdf.inc'

integer :: icode,ncid,nid,nx,ny,i,j
real, allocatable, dimension(:,:) :: elev

character(len=256) :: cdffile

cdffile='conus-terrain.cdf'

! Open elevation file.

icode=nf_open(trim(cdffile),nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file: ',trim(cdffile)
   stop
endif

! Get grid dimensions.

icode=nf_inq_dimid(ncid,'x',nid)
icode=nf_inq_dimlen(ncid,nid,nx)
icode=nf_inq_dimid(ncid,'y',nid)
icode=nf_inq_dimlen(ncid,nid,ny)
print*,nx,ny

! Read lat/lon and define grid projection for interpolation routines.

allocate(elev(nx,ny))

icode=nf_inq_varid(ncid,'DIST_surface',nid)
icode=nf_get_var_real(ncid,nid,elev)

icode=nf_close(ncid)

print*,minval(elev),maxval(elev)

open(1,file='conus-terrain.csv',form='formatted')
do j=378,1194
do i=1,1225
   write(1,'(i4,",")') nint(elev(i,j))
enddo
enddo
close(1)

end

