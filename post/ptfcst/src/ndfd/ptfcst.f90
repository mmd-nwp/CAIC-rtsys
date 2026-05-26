program point_forecast

use proj_info

implicit none

include 'netcdf.inc'
type(projinfo) :: proj

integer, parameter :: maxsta=200  ! Maximum number of point forecast locations
real, parameter :: rmsg = -30000.

integer :: icode,ncid,nid    &
          ,nsta,nx,ny,stime,etime,ftime,diffspd,diffdir  &
          ,nhour,period,nt,ntspd,ntdir,ntgst,i,j,n,t
real :: lon0,lat1,lat2     &
       ,dx,ri,rj,ptlat(maxsta),ptlon(maxsta),pt,ptu,ptv,ptdir  &
       ,avcl,sind,cosd,atan2d
real, allocatable, dimension(:,:,:) :: grid,spd,dir,u,v,gst
real, allocatable, dimension(:,:) :: avtpa,hitpa,lotpa  &
                                    ,avspa,hispa,lospa  &
                                    ,avdia,hidia,lodia  &
                                    ,avuwa,avvwa        &
                                    ,avcla,tpcpa,tsnoa  &
                                    ,lat,lon
real*8, allocatable, dimension(:,:) :: dgrid
real*8, allocatable, dimension(:) :: dtime,dtimespd,dtimedir,dtimegst
integer, allocatable, dimension(:) :: ct

character(len=16), allocatable, dimension(:,:) :: avcld
character(len=256) :: cdfdir,projtype,pfile,odir
character(len=10)  :: stname(maxsta)
character(len=9)   :: sdate
character(len=2)   :: mapproj

read(5,'(a)') sdate
read(5,'(a)') pfile
read(5,'(a)') odir
cdfdir='/data/noaaport/grids/ndfd/netcdf'
!sdate='113211300'
!odir='./'
nhour=60
call adate_to_i4time(sdate,stime)
etime=stime+nhour*3600

! Read point forecast station file.

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

! Allocate

allocate(avtpa(5,nsta),hitpa(5,nsta),lotpa(5,nsta)  &
        ,avspa(5,nsta),hispa(5,nsta),lospa(5,nsta)  &
        ,avdia(5,nsta),hidia(5,nsta),lodia(5,nsta)  &
        ,avuwa(5,nsta),avvwa(5,nsta)                &
        ,avcla(5,nsta),avcld(5,nsta)                &
        ,tpcpa(5,nsta),tsnoa(5,nsta),ct(5))
hitpa=-99.
lotpa=-99.
avtpa=-99.

! Specify ConUS grid parameters.

mapproj='LC'
lon0=-95.
lat1=25.
lat2=25.
dx=2539.703

! Open NDFD netcdf file.

icode=nf_open(trim(cdfdir)//'/maxt-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file: ',trim(cdfdir),'/maxt-p1.cdf'
   stop
endif

! Get grid dimensions (assume they are the same for all fields).

icode=nf_inq_dimid(ncid,'x',nid)
icode=nf_inq_dimlen(ncid,nid,nx)
icode=nf_inq_dimid(ncid,'y',nid)
icode=nf_inq_dimlen(ncid,nid,ny)

! Read lat/lon and define grid projection for interpolation routines.

allocate(dgrid(nx,ny),lat(nx,ny),lon(nx,ny))

icode=nf_inq_varid(ncid,'latitude',nid)
icode=nf_get_var_double(ncid,nid,dgrid)
lat=sngl(dgrid)
icode=nf_inq_varid(ncid,'longitude',nid)
icode=nf_get_var_double(ncid,nid,dgrid)
lon=sngl(dgrid)
call map_set(mapproj,lat(1,1),lon(1,1)-360.,1.,1.,dx,lon0,lat1,lat2,nx,ny,proj)

! Parse max temp data.

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,nt)
allocate(grid(nx,ny,nt),dtime(nt))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtime)
icode=nf_inq_varid(ncid,'TMAX_2maboveground',nid)
icode=nf_get_var_real(ncid,nid,grid)

icode=nf_close(ncid)

do t=1,nt
   ftime=nint(dtime(t))
   period=(ftime-stime)/43200
   if (mod(ftime-stime,43200) /= 0) period=period+1
   if (period > 0 .and. period < 6) then
      do n=1,nsta
         call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
         call gdtost(grid(1,1,t),nx,ny,ri,rj,pt)
         hitpa(period,n)=(pt-273.15)*1.8+32.
      enddo
   endif
enddo

deallocate(grid,dtime)

! Parse min temp data.

icode=nf_open(trim(cdfdir)//'/mint-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file',trim(cdfdir),'/mint-p1.cdf'
   stop
endif

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,nt)
allocate(grid(nx,ny,nt),dtime(nt))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtime)
icode=nf_inq_varid(ncid,'TMIN_2maboveground',nid)
icode=nf_get_var_real(ncid,nid,grid)

icode=nf_close(ncid)

do t=1,nt
   ftime=nint(dtime(t))
   period=(ftime-stime)/43200
   if (mod(ftime-stime,43200) /= 0) period=period+1
   if (period > 0 .and. period < 6) then
      do n=1,nsta
         call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
         call gdtost(grid(1,1,t),nx,ny,ri,rj,pt)
         lotpa(period,n)=(pt-273.15)*1.8+32.
      enddo
   endif
enddo

deallocate(grid,dtime)

! Parse wind data.
!   Since this is NDFD data, we cannot assume that the times in the 
!      speed and direction files match. 
!   [Not checking gust at this time]

icode=nf_open(trim(cdfdir)//'/wspd-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file',trim(cdfdir),'/wspd-p1.cdf'
   stop
endif

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,ntspd)
allocate(spd(nx,ny,ntspd),dtimespd(ntspd))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtimespd)
icode=nf_inq_varid(ncid,'WIND_10maboveground',nid)
icode=nf_get_var_real(ncid,nid,spd)

icode=nf_close(ncid)

icode=nf_open(trim(cdfdir)//'/wdir-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file',trim(cdfdir),'/wdir.cdf'
   stop
endif

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,ntdir)
allocate(dir(nx,ny,ntdir),dtimedir(ntdir))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtimedir)
icode=nf_inq_varid(ncid,'WDIR_10maboveground',nid)
icode=nf_get_var_real(ncid,nid,dir)

icode=nf_close(ncid)

icode=nf_open(trim(cdfdir)//'/wgst-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file',trim(cdfdir),'/wgst-p1.cdf'
   stop
endif

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,ntgst)
allocate(gst(nx,ny,ntgst),dtimegst(ntgst))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtimegst)
icode=nf_inq_varid(ncid,'GUST_10maboveground',nid)
icode=nf_get_var_real(ncid,nid,gst)

icode=nf_close(ncid)

! Rectify any time differences.

diffspd=0
diffdir=0
if (ntspd > ntdir) then
   do t=1,ntspd
      if (dtimespd(t) == dtimedir(1)) exit
   enddo
   if (t >= ntspd) then
      print*,'Wind time mismatch.'
      stop
   endif
   diffspd=t-1
endif

if (ntdir > ntspd) then
   do t=1,ntdir
      if (dtimedir(t) == dtimespd(1)) exit
   enddo
   if (t >= ntdir) then
      print*,'Wind time mismatch.'
      stop
   endif
   diffdir=t-1
endif

nt=min(ntspd-diffspd,ntdir-diffdir)
allocate(dtime(nt))
do t=1,nt
   if (dtimespd(t+diffspd) /= dtimedir(t+diffdir)) then
      print*,'Wind time mismatch:',dtimespd(t+diffspd),dtimedir(t+diffdir)
      stop
   endif
   dtime(t)=dtimespd(t+diffspd)
enddo

deallocate(dtimespd,dtimedir)

! Generate u, v from spd, dir.

allocate(u(nx,ny,nt),v(nx,ny,nt))
do t=1,nt
do j=1,ny
do i=1,nx
   u(i,j,t)=-spd(i,j,t+diffspd)*sind(dir(i,j,t+diffdir))
   v(i,j,t)=-spd(i,j,t+diffspd)*cosd(dir(i,j,t+diffdir))
enddo
enddo
enddo

lospa=999.
hispa=-99.
avspa=0.
hispa=0.
lodia=999.
hidia=-99.
avuwa=0.
avvwa=0.
ct=0

period=1   
do t=1,nt
   ftime=nint(dtime(t))
   if (period > 0 .and. period < 6) then
      ct(period)=ct(period)+1
      do n=1,nsta
         call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
         call gdtost(spd(1,1,t+diffspd),nx,ny,ri,rj,pt)
         pt=pt*2.23693629  ! Convert m/s to mph
         lospa(period,n)=min(lospa(period,n),pt)
         avspa(period,n)=avspa(period,n)+pt
         call gdtost(gst(1,1,t+diffspd),nx,ny,ri,rj,pt)  ! Put gust into max wind spd
         pt=pt*2.23693629  ! Convert m/s to mph
!        hispa(period,n)=max(hispa(period,n),pt)
         hispa(period,n)=hispa(period,n)+pt  ! Per group discussion, max wind speed will be ave gust

         call gdtost(u(1,1,t),nx,ny,ri,rj,ptu)
         avuwa(period,n)=avuwa(period,n)+ptu
         call gdtost(v(1,1,t),nx,ny,ri,rj,ptv)
         avvwa(period,n)=avvwa(period,n)+ptv
         ptdir=atan2d(-ptu,-ptv)
         if (ptdir < 0.) ptdir=ptdir+360.
         lodia(period,n)=min(lodia(period,n),ptdir)
         hidia(period,n)=max(hidia(period,n),ptdir)
      enddo
   endif
   if (mod(ftime,43200) == 0) period=period+1
enddo

do t=1,5
   if (ct(t) > 0) then
      do n=1,nsta
         avspa(t,n)=avspa(t,n)/float(ct(t))
         hispa(t,n)=hispa(t,n)/float(ct(t))
         avuwa(t,n)=avuwa(t,n)/float(ct(t))
         avvwa(t,n)=avvwa(t,n)/float(ct(t))
         avdia(t,n)=atan2d(-avuwa(t,n),-avvwa(t,n))
         if (avdia(t,n) < 0.) avdia(t,n)=avdia(t,n)+360.
      enddo
   endif
enddo

deallocate(spd,dir,u,v,gst,dtime)

! Parse cloud data.

icode=nf_open(trim(cdfdir)//'/sky-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file',trim(cdfdir),'/sky-p1.cdf'
   stop
endif

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,nt)
allocate(grid(nx,ny,nt),dtime(nt))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtime)
icode=nf_inq_varid(ncid,'TCDC_surface',nid)
icode=nf_get_var_real(ncid,nid,grid)

icode=nf_close(ncid)

avcla=0.
ct=0

period=1
do t=1,nt
   ftime=nint(dtime(t))
   if (period > 0 .and. period < 6) then
      ct(period)=ct(period)+1
      do n=1,nsta
         call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
         call gdtost(grid(1,1,t),nx,ny,ri,rj,pt)
         avcla(period,n)=avcla(period,n)+pt
      enddo
   endif
   if (mod(ftime,43200) == 0) period=period+1
enddo

avcld="MSG"
do t=1,5
   if (ct(t) > 0) then
      do n=1,nsta
         avcl=avcla(t,n)/float(ct(t))
         if (avcl < 10) then
            avcld(t,n)="CLEAR"
         elseif (avcl < 25) then
            avcld(t,n)="FEW"
         elseif (avcl < 50) then
            avcld(t,n)="SCATTERED"
         elseif (avcl < 90) then
            avcld(t,n)="BROKEN"
         else
            avcld(t,n)="OVERCAST"
         endif
      enddo
   endif
enddo

deallocate(grid,dtime)

! Parse QPF data.

icode=nf_open(trim(cdfdir)//'/qpf-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file',trim(cdfdir),'/qpf-p1.cdf'
   stop
endif

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,nt)
allocate(grid(nx,ny,nt),dtime(nt))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtime)
icode=nf_inq_varid(ncid,'APCP_surface',nid)
icode=nf_get_var_real(ncid,nid,grid)

icode=nf_close(ncid)

tpcpa=0.
period=1
do t=1,nt
   ftime=nint(dtime(t))
   if (period > 0 .and. period < 6) then
      do n=1,nsta
         call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
         call gdtost(grid(1,1,t),nx,ny,ri,rj,pt)
         pt=max(0.,pt*0.0393700787)  ! Convert mm to in
         tpcpa(period,n)=tpcpa(period,n)+pt
      enddo
   endif
   if (mod(ftime,43200) == 0) period=period+1
enddo

deallocate(grid,dtime)

! Parse snow data.

icode=nf_open(trim(cdfdir)//'/snow-p1.cdf',nf_nowrite,ncid)
if (icode /= 0) then
   print *,'Could not open file',trim(cdfdir),'/snow-p1.cdf'
   stop
endif

icode=nf_inq_dimid(ncid,'time',nid)
icode=nf_inq_dimlen(ncid,nid,nt)
allocate(grid(nx,ny,nt),dtime(nt))

icode=nf_inq_varid(ncid,'time',nid)
icode=nf_get_var_double(ncid,nid,dtime)
icode=nf_inq_varid(ncid,'ASNOW_surface',nid)
icode=nf_get_var_real(ncid,nid,grid)

icode=nf_close(ncid)

tsnoa=0.
period=1
do t=1,nt
   ftime=nint(dtime(t))
   if (period > 0 .and. period < 6) then
      do n=1,nsta
         call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
         call gdtost(grid(1,1,t),nx,ny,ri,rj,pt)
         pt=max(0.,pt*39.3700787)  ! Convert m to in
         tsnoa(period,n)=tsnoa(period,n)+pt
      enddo
   endif
   if (mod(ftime,43200) == 0) period=period+1
enddo

deallocate(grid,dtime)

open(1,file=trim(odir)//'/ndfd.txt',form='formatted',status='unknown')
do n=1,nsta
   write(1,'(a10,''  NWS|'',5(i3,2i4''|''))')   stname(n),(nint(avtpa(t,n)),nint(lotpa(t,n)),nint(hitpa(t,n)),t=1,5)
   write(1,'(''Avg,Min,Max NWS|'',5(i3,2i4''|''))')       (nint(avspa(t,n)),nint(lospa(t,n)),nint(hispa(t,n)),t=1,5)
   write(1,'(''Avg,Min,Max NWS|'',5(i3,2i4''|''))')       (nint(avdia(t,n)),nint(lodia(t,n)),nint(hidia(t,n)),t=1,5)
   write(1,'(''Avg         NWS|'',5(a10,1x''|''))')       (trim(avcld(t,n)),t=1,5)
   write(1,'(''Total (in)  NWS|'',5(f5.1,i5,1x''|''))') (tpcpa(t,n),nint(tsnoa(t,n)),t=1,5)
enddo
close(1)

deallocate(avtpa,hitpa,lotpa,avspa,hispa,lospa,avdia,hidia,lodia,avuwa,avvwa,avcla,avcld,tpcpa,tsnoa,ct)

end
