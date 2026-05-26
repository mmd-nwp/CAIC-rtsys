program ndfdelev 

use proj_info

implicit none

include 'netcdf.inc'
type(projinfo) :: proj

integer :: icode,nid,ncid,nsta,imin,jmin,imax,jmax,nx,ny,i,j,n
integer, parameter :: maxsta=200  ! Maximum number of point forecast locations

real, allocatable, dimension(:,:) :: elev
real(kind=8), allocatable, dimension(:,:) :: dgrid
real, allocatable, dimension(:,:) :: lat,lon
real :: dist,mindistsw,mindistne,ptlat(maxsta),ptlon(maxsta)  &
       ,lon0,lat1,lat2,dx,ri,rj,pt

real, parameter :: swlat=27.75023,swlon=-127.0517,nelat=49.04418,nelon=-90.7084

character(len=256) :: filename,pfile
character(len=10)  :: stname(maxsta)
character(len=2)   :: mapproj

! NDFD domain.

filename="ndfd-elev.cdf"
nx=2345
ny=1597

! Specify ConUS grid parameters.

mapproj='LC'
lon0=-95.
lat1=25.
lat2=25.
dx=2539.703

allocate(dgrid(nx,ny),lat(nx,ny),lon(nx,ny),elev(nx,ny))
icode=nf_open(trim(filename),nf_nowrite,ncid)

! Read lat, lon and determine subdomain.

icode=nf_inq_varid(ncid,'latitude',nid)
icode=nf_get_var_double(ncid,nid,dgrid)
lat=sngl(dgrid)
icode=nf_inq_varid(ncid,'longitude',nid)
icode=nf_get_var_double(ncid,nid,dgrid)
lon=sngl(dgrid)
lon=lon-360.
call map_set(mapproj,lat(1,1),lon(1,1),1.,1.,dx,lon0,lat1,lat2,nx,ny,proj)

mindistsw=999999.
mindistne=999999.
do j=1,ny
do i=1,nx
   dist=sqrt((lat(i,j)-swlat)**2+(lon(i,j)-swlon)**2)
   if (dist < mindistsw) then
      mindistsw=dist
      imin=i
      jmin=j
   endif
   dist=sqrt((lat(i,j)-nelat)**2+(lon(i,j)-nelon)**2)
   if (dist < mindistne) then
      mindistne=dist
      imax=i
      jmax=j
   endif
enddo
enddo

icode=nf_inq_varid(ncid,'DIST_surface',nid)
icode=nf_get_var_real(ncid,nid,elev)
icode=nf_close(ncid)

! Read point forecast station file.

pfile="/home/caic/caic/rtsys/post/ptfcst/namelist/ptfcst.txt"
open(1,file=trim(pfile),status='old',form='formatted')
nsta=1
do while(.true.)
   read(1,'(a10,1x,f7.4,1x,f8.4)',end=1) stname(nsta),ptlat(nsta),ptlon(nsta)
   nsta=nsta+1
enddo
1 continue
close(1)
nsta=nsta-1
print*,nsta,'stations read from point forecast locations file.'

do n=1,nsta
   call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
   call gdtost(elev,nx,ny,ri,rj,pt)
   pt=pt*3.28084
   print*,stname(n),' ',nint(pt)
enddo

deallocate(elev)

end
