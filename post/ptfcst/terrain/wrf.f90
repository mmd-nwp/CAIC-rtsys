program parse_terrain

implicit none

include 'netcdf.inc'

integer :: icode,ncid,nid,nx,ny,i,j,ct
real, allocatable, dimension(:,:) :: elev

character(len=256) :: cdffile

cdffile='geo_em.d02.nc'

! Open elevation file.

icode=nf_open(trim(cdffile),nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file: ',trim(cdffile)
   stop
endif

! Get grid dimensions.

icode=nf_inq_dimid(ncid,'west_east',nid)
icode=nf_inq_dimlen(ncid,nid,nx)
icode=nf_inq_dimid(ncid,'south_north',nid)
icode=nf_inq_dimlen(ncid,nid,ny)
print*,nx,ny

! Read lat/lon and define grid projection for interpolation routines.

allocate(elev(nx,ny))

icode=nf_inq_varid(ncid,'HGT_M',nid)
icode=nf_get_var_real(ncid,nid,elev)

icode=nf_close(ncid)

print*,minval(elev),maxval(elev)
print*,elev(214,208)

open(1,file='wrf2km-terrain.csv',form='formatted')
ct=0
do j=1,ny
do i=1,nx
   write(1,'(i4,",")') nint(elev(i,j))
   ct=ct+1
   if (i == 214 .and. j == 208) print*,'count: ',ct
enddo
enddo
close(1)

end

