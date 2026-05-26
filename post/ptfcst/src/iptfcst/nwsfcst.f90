program nwsfcst

implicit none

include 'netcdf.inc'

integer, parameter :: refnfcst=42,refpfcst=11,nfcst=84
integer :: icode,nid,ncid1,ncid2,aid,alen,imin,jmin,imax,jmax,nx,ny,nfcst1,nfcst2,fhr,phr,f,i,j,ct
integer, allocatable, dimension(:,:,:) :: tp,td,rh,spd,dir,gst,rnto,snto,cld
real, parameter :: msg=-999.
real, allocatable, dimension(:,:,:) :: fld
real(kind=8), allocatable, dimension(:,:) :: lat,lon
real(kind=8), allocatable, dimension(:) :: time
real(kind=8) :: reftime1,reftime2
real :: dist,mindistsw,mindistne
real, parameter :: swlat=27.75023,swlon=-127.0517,nelat=49.04418,nelon=-90.7084

character(len=4590) :: fcst
character(len=255)  :: cdfroot,cdffile

cdfroot="/data/noaaport/grids/ndfd/netcdf"

! Read netcdf data for each met parameter.
! === Temperature.

cdffile=trim(cdfroot)//"/temp-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

cdffile=trim(cdfroot)//"/temp-p2.cdf"
icode=nf_open(trim(cdffile),nf_nowrite,ncid2)
icode=nf_inq_dimid(ncid2,'time',nid)
icode=nf_inq_dimlen(ncid2,nid,nfcst2)
icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_att_double(ncid2,nid,'reference_time',reftime2)

allocate(time(nfcst1),fld(nx,ny,nfcst1),tp(nx,ny,0:nfcst),lat(nx,ny),lon(nx,ny))
tp=msg

! Read lat, lon and determine subdomain (which eliminates border areas with missing data).

icode=nf_inq_varid(ncid1,'latitude',nid)
icode=nf_get_var_double(ncid1,nid,lat)
icode=nf_inq_varid(ncid1,'longitude',nid)
icode=nf_get_var_double(ncid1,nid,lon)
lon=lon-360.

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

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'TMP_2maboveground',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=0.
fld=((fld-273.15)*1.8+32.)*10.
where (fld < -700) fld = msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   tp(:,:,fhr)=nint(fld(:,:,f))
print*,'per1: ',fhr,tp(497,875,fhr)
enddo

deallocate(time,fld)
allocate(time(nfcst2),fld(nx,ny,nfcst2))

icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_var_double(ncid2,nid,time)
icode=nf_inq_varid(ncid2,'TMP_2maboveground',nid)
icode=nf_get_var_real(ncid2,nid,fld)

icode=nf_close(ncid2)

where (fld > 1000.) fld=0.
fld=((fld-273.15)*1.8+32.)*10.
where (fld < -700) fld = msg
do f=1,nfcst2
   fhr=nint(real(time(f)-reftime2)/3600.)
   if (fhr < 0) cycle
   if (fhr > nfcst) exit
   tp(:,:,fhr)=nint(fld(:,:,f))
print*,'per2: ',fhr,tp(497,875,fhr)
enddo

deallocate(time,fld)

! === Dew point.

cdffile=trim(cdfroot)//"/td-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

cdffile=trim(cdfroot)//"/td-p2.cdf"
icode=nf_open(trim(cdffile),nf_nowrite,ncid2)
icode=nf_inq_dimid(ncid2,'time',nid)
icode=nf_inq_dimlen(ncid2,nid,nfcst2)
icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_att_double(ncid2,nid,'reference_time',reftime2)

allocate(time(nfcst1),fld(nx,ny,nfcst1),td(nx,ny,0:nfcst))
td=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'DPT_2maboveground',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=0.
fld=((fld-273.15)*1.8+32.)*10.
where (fld < -700) fld = msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   td(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)
allocate(time(nfcst2),fld(nx,ny,nfcst2))

icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_var_double(ncid2,nid,time)
icode=nf_inq_varid(ncid2,'DPT_2maboveground',nid)
icode=nf_get_var_real(ncid2,nid,fld)

icode=nf_close(ncid2)

where (fld > 1000.) fld=0.
fld=((fld-273.15)*1.8+32.)*10.
where (fld < -700) fld = msg
do f=1,nfcst2
   fhr=nint(real(time(f)-reftime2)/3600.)
   if (fhr < 0) cycle
   if (fhr > nfcst) exit
   td(:,:,fhr)=nint(fld(:,:,f))
enddo
where (td > tp) td=tp

deallocate(time,fld)

! === RH.

cdffile=trim(cdfroot)//"/rh-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

cdffile=trim(cdfroot)//"/rh-p2.cdf"
icode=nf_open(trim(cdffile),nf_nowrite,ncid2)
icode=nf_inq_dimid(ncid2,'time',nid)
icode=nf_inq_dimlen(ncid2,nid,nfcst2)
icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_att_double(ncid2,nid,'reference_time',reftime2)

allocate(time(nfcst1),fld(nx,ny,nfcst1),rh(nx,ny,0:nfcst))
rh=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'RH_2maboveground',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=-99.9
fld=fld*10.
where (fld > 1000.) fld=1000.
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   rh(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)
allocate(time(nfcst2),fld(nx,ny,nfcst2))

icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_var_double(ncid2,nid,time)
icode=nf_inq_varid(ncid2,'RH_2maboveground',nid)
icode=nf_get_var_real(ncid2,nid,fld)

icode=nf_close(ncid2)

where (fld > 1000.) fld=-99.9
fld=fld*10.
where (fld > 1000.) fld=1000.
do f=1,nfcst2
   fhr=nint(real(time(f)-reftime2)/3600.)
   if (fhr < 0) cycle
   if (fhr > nfcst) exit
   rh(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)

! === Wind speed.

cdffile=trim(cdfroot)//"/wspd-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

cdffile=trim(cdfroot)//"/wspd-p2.cdf"
icode=nf_open(trim(cdffile),nf_nowrite,ncid2)
icode=nf_inq_dimid(ncid2,'time',nid)
icode=nf_inq_dimlen(ncid2,nid,nfcst2)
icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_att_double(ncid2,nid,'reference_time',reftime2)

allocate(time(nfcst1),fld(nx,ny,nfcst1),spd(nx,ny,0:nfcst))
spd=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'WIND_10maboveground',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=-1.
fld=fld*22.3694
where (fld < 0.) fld=msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   spd(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)
allocate(time(nfcst2),fld(nx,ny,nfcst2))

icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_var_double(ncid2,nid,time)
icode=nf_inq_varid(ncid2,'WIND_10maboveground',nid)
icode=nf_get_var_real(ncid2,nid,fld)

icode=nf_close(ncid2)

where (fld > 1000.) fld=-1.
fld=fld*22.3694
where (fld < 0.) fld=msg
do f=1,nfcst2
   fhr=nint(real(time(f)-reftime2)/3600.)
   if (fhr < 0) cycle
   if (fhr > nfcst) exit
   spd(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)

! === Wind direction.

cdffile=trim(cdfroot)//"/wdir-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

cdffile=trim(cdfroot)//"/wdir-p2.cdf"
icode=nf_open(trim(cdffile),nf_nowrite,ncid2)
icode=nf_inq_dimid(ncid2,'time',nid)
icode=nf_inq_dimlen(ncid2,nid,nfcst2)
icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_att_double(ncid2,nid,'reference_time',reftime2)

allocate(time(nfcst1),fld(nx,ny,nfcst1),dir(nx,ny,0:nfcst))
dir=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'WDIR_10maboveground',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   dir(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)
allocate(time(nfcst2),fld(nx,ny,nfcst2))

icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_var_double(ncid2,nid,time)
icode=nf_inq_varid(ncid2,'WDIR_10maboveground',nid)
icode=nf_get_var_real(ncid2,nid,fld)

icode=nf_close(ncid2)

where (fld > 1000.) fld=msg
do f=1,nfcst2
   fhr=nint(real(time(f)-reftime2)/3600.)
   if (fhr < 0) cycle
   if (fhr > nfcst) exit
   dir(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)

! === Wind gust.

cdffile=trim(cdfroot)//"/wgst-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

cdffile=trim(cdfroot)//"/wgst-p2.cdf"
icode=nf_open(trim(cdffile),nf_nowrite,ncid2)
icode=nf_inq_dimid(ncid2,'time',nid)
icode=nf_inq_dimlen(ncid2,nid,nfcst2)
icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_att_double(ncid2,nid,'reference_time',reftime2)

allocate(time(nfcst1),fld(nx,ny,nfcst1),gst(nx,ny,0:nfcst))
gst=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'GUST_10maboveground',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=-1.
fld=fld*22.3694
where (fld < 0.) fld=msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   gst(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)
allocate(time(nfcst2),fld(nx,ny,nfcst2))

icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_var_double(ncid2,nid,time)
icode=nf_inq_varid(ncid2,'GUST_10maboveground',nid)
icode=nf_get_var_real(ncid2,nid,fld)

icode=nf_close(ncid2)

where (fld > 1000.) fld=-1.
fld=fld*22.3694
where (fld < 0.) fld=msg
do f=1,nfcst2
   fhr=nint(real(time(f)-reftime2)/3600.)
   if (fhr < 0) cycle
   if (fhr > nfcst) exit
   gst(:,:,fhr)=nint(fld(:,:,f))
enddo
where (gst < spd) gst=spd

deallocate(time,fld)

! === QPF.

cdffile=trim(cdfroot)//"/qpf-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

allocate(time(nfcst1),fld(nx,ny,nfcst1),rnto(nx,ny,0:nfcst))
rnto=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'APCP_surface',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=-1.
fld=fld/0.254
where (fld < 0.) fld=msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   if (f == 1) then
      where (fld(:,:,f) >= 0.) rnto(:,:,fhr)=nint(fld(:,:,f))
   else
      where (fld(:,:,f) >= 0.) rnto(:,:,fhr)=rnto(:,:,phr)+nint(fld(:,:,f))
   endif
   phr=fhr
enddo

deallocate(time,fld)

! === Accumulated snow.

cdffile=trim(cdfroot)//"/snow-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

allocate(time(nfcst1),fld(nx,ny,nfcst1),snto(nx,ny,0:nfcst))
snto=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'ASNOW_surface',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld > 1000.) fld=-1.
fld=fld*3937.
where (fld < 0.) fld=msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   if (f == 1) then
      where (fld(:,:,f) >= 0.) snto(:,:,fhr)=nint(fld(:,:,f))
   else
      where (fld(:,:,f) >= 0.) snto(:,:,fhr)=snto(:,:,phr)+nint(fld(:,:,f))
   endif
   phr=fhr
enddo
!do f=0,nfcst
!if (tp(nx/2,ny/2,f) > -999) &
!   print*,f,tp(nx/2,ny/2,f),td(nx/2,ny/2,f),rh(nx/2,ny/2,f),spd(nx/2,ny/2,f) &
!           ,dir(nx/2,ny/2,f),gst(nx/2,ny/2,f),rnto(nx/2,ny/2,f),snto(nx/2,ny/2,f)
!print*,f,tp(nx/2,ny/2,f),td(nx/2,ny/2,f),rh(nx/2,ny/2,f),spd(nx/2,ny/2,f),dir(nx/2,ny/2,f),gst(nx/2,ny/2,f)
!enddo

deallocate(time,fld)

! === Sky cover.

cdffile=trim(cdfroot)//"/sky-p1.cdf"
print*,trim(cdffile)
icode=nf_open(trim(cdffile),nf_nowrite,ncid1)

icode=nf_inq_dimid(ncid1,'x',nid)
icode=nf_inq_dimlen(ncid1,nid,nx)
icode=nf_inq_dimid(ncid1,'y',nid)
icode=nf_inq_dimlen(ncid1,nid,ny)
icode=nf_inq_dimid(ncid1,'time',nid)
icode=nf_inq_dimlen(ncid1,nid,nfcst1)
icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_att_double(ncid1,nid,'reference_time',reftime1)

cdffile=trim(cdfroot)//"/sky-p2.cdf"
icode=nf_open(trim(cdffile),nf_nowrite,ncid2)
icode=nf_inq_dimid(ncid2,'time',nid)
icode=nf_inq_dimlen(ncid2,nid,nfcst2)
icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_att_double(ncid2,nid,'reference_time',reftime2)

allocate(time(nfcst1),fld(nx,ny,nfcst1),cld(nx,ny,0:nfcst))
cld=msg

icode=nf_inq_varid(ncid1,'time',nid)
icode=nf_get_var_double(ncid1,nid,time)
icode=nf_inq_varid(ncid1,'TCDC_surface',nid)
icode=nf_get_var_real(ncid1,nid,fld)

icode=nf_close(ncid1)

where (fld < 0. .or. fld > 100.) fld=msg
do f=1,nfcst1
   fhr=nint(real(time(f)-reftime1)/3600.)
   if (fhr < 0) cycle
   cld(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)
allocate(time(nfcst2),fld(nx,ny,nfcst2))

icode=nf_inq_varid(ncid2,'time',nid)
icode=nf_get_var_double(ncid2,nid,time)
icode=nf_inq_varid(ncid2,'TCDC_surface',nid)
icode=nf_get_var_real(ncid2,nid,fld)

icode=nf_close(ncid2)

where (fld < 0. .or. fld > 100.) fld=msg
do f=1,nfcst2
   fhr=nint(real(time(f)-reftime2)/3600.)
   if (fhr < 0) cycle
   if (fhr > nfcst) exit
   cld(:,:,fhr)=nint(fld(:,:,f))
enddo

deallocate(time,fld)

open(1,file='nws.csv',status='unknown',form='formatted',access='stream')
print*,'SW:',imin,jmin
print*,'NE:',imax,jmax
do f=0,nfcst
!print*,'io: ',f,tp(497,875,f)
enddo
ct=1
do j=jmin,jmax
do i=imin,imax
!if (ct == 539393) write(6,'(85(i5,'',''))') (spd(i,j,f),f=0,nfcst)
   write(fcst,'(765(i5,'',''))') &
       (tp(i,j,f),f=0,nfcst)     &
      ,(td(i,j,f),f=0,nfcst)     &
      ,(rh(i,j,f),f=0,nfcst)     &
      ,(spd(i,j,f),f=0,nfcst)    &
      ,(dir(i,j,f),f=0,nfcst)    &
      ,(gst(i,j,f),f=0,nfcst)    &
      ,(rnto(i,j,f),f=0,nfcst)   &
      ,(snto(i,j,f),f=0,nfcst)   &
      ,(cld(i,j,f),f=0,nfcst)   
   write(1,'(a)') trim(fcst)
ct=ct+1
enddo
if (mod(j,100) == 1) print*,j
enddo
close(1)
deallocate(tp,td,rh,spd,dir,gst,rnto,snto,cld,lat,lon)

end
