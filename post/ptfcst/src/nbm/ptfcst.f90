program point_forecast

use proj_info

implicit none

include 'netcdf.inc'
type(projinfo) :: proj

integer, parameter :: maxsta=200  ! Maximum number of point forecast locations

integer :: icode,ncid,nid                   &
          ,ct,nsta,nx,ny,stime,ftime        &
          ,hour,nhour,period,i,j,f,n
real :: lon0,lat1,lat2                        &
       ,dx,ri,rj,ptlat(maxsta),ptlon(maxsta)  &
       ,sind,cosd,atan2d
real, allocatable, dimension(:,:) :: avtpa,hitpa,lotpa  &
                                    ,avspa,hispa,lospa  &
                                    ,avdia,hidia,lodia  &
                                    ,avuwa,avvwa        &
                                    ,avcla,tpcpa,tsnoa  &
                                    ,lat,lon            &
                                    ,tpgrid             &
                                    ,wsgrid,wdgrid      &
                                    ,gsgrid             &
                                    ,wugrid,wvgrid      &
                                    ,cldgrid            &
                                    ,pcpgrid,snogrid
real, allocatable, dimension(:) :: tp,ws,wd,uw,vw,gs,cld,pcp,sno
real*8, allocatable, dimension(:,:) :: dgrid

character(len=16), allocatable, dimension(:,:) :: avcld
character(len=256) :: cdfdir,projtype,pfile,odir
character(len=10)  :: stname(maxsta)
character(len=9)   :: sdate
character(len=4)   :: afcst
character(len=2)   :: ahour,mapproj

logical :: first

read(5,'(a)') sdate
read(5,'(a)') pfile
read(5,'(a)') odir

cdfdir='/data/noaaport/grids/blend/netcdf'
ahour=sdate(6:7)
read(ahour,'(i2)') hour
nhour=81
call adate_to_i4time(sdate,stime)

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

! Allocate output parameters. 

allocate(avtpa(7,nsta),hitpa(7,nsta),lotpa(7,nsta)  &
        ,avspa(7,nsta),hispa(7,nsta),lospa(7,nsta)  &
        ,avdia(7,nsta),hidia(7,nsta),lodia(7,nsta)  &
        ,avuwa(7,nsta),avvwa(7,nsta)                &
        ,avcla(7,nsta),avcld(7,nsta)                &
        ,tpcpa(7,nsta),tsnoa(7,nsta)                &
        ,tp(nsta),ws(nsta),wd(nsta)                 &
        ,uw(nsta),vw(nsta),gs(nsta)                 &
        ,cld(nsta),pcp(nsta),sno(nsta))
hitpa=-999.
lotpa= 999.
avtpa=0.
!hispa=-999.
lospa= 999.
avspa=0.
hispa=0.
avuwa=0.
avvwa=0.
hidia=-999.
lodia= 999.
avdia=0.
avcla=0.
tpcpa=0.
tsnoa=0.

! Specify ConUS grid parameters.

mapproj='LC'
lon0=-95.
lat1=25.
lat2=25.
dx=2539.703

! Read NBM data from netcdf files.

first=.true.
period=1
ct=0
do f=1,nhour
   if (f == 0) cycle
   if (f > 36 .and. mod(f,3) /= 0) cycle
   ct=ct+1

   write(afcst,'(i4.4)') f

   print*,trim(cdfdir)//'/'//sdate//afcst//'.nc'
   icode=nf_open(trim(cdfdir)//'/'//sdate//afcst//'.nc',nf_nowrite,ncid)
   if (icode /= 0) then
      print *,'Could not open file: ',trim(cdfdir)//'/'//sdate//afcst//'.nc'
      stop
   endif

   if (first) then

! Get grid dimensions (assume they are the same for all fields).

      icode=nf_inq_dimid(ncid,'x',nid)
      icode=nf_inq_dimlen(ncid,nid,nx)
      icode=nf_inq_dimid(ncid,'y',nid)
      icode=nf_inq_dimlen(ncid,nid,ny)

! Read lat/lon and define grid projection for interpolation routines.

      allocate(dgrid(nx,ny),lat(nx,ny),lon(nx,ny)             &
              ,tpgrid(nx,ny),wsgrid(nx,ny),wdgrid(nx,ny)      &
              ,wugrid(nx,ny),wvgrid(nx,ny),gsgrid(nx,ny)      &
              ,cldgrid(nx,ny),pcpgrid(nx,ny),snogrid(nx,ny))

      icode=nf_inq_varid(ncid,'latitude',nid)
      icode=nf_get_var_double(ncid,nid,dgrid)
      lat=sngl(dgrid)
      icode=nf_inq_varid(ncid,'longitude',nid)
      icode=nf_get_var_double(ncid,nid,dgrid)
      lon=sngl(dgrid)
      call map_set(mapproj,lat(1,1),lon(1,1)-360.,1.,1.,dx,lon0,lat1,lat2,nx,ny,proj)

      first=.false.
   endif

! Read forecast parameters.

   icode=nf_inq_varid(ncid,'TMP_2maboveground',nid)
   icode=nf_get_var_real(ncid,nid,tpgrid)
   icode=nf_inq_varid(ncid,'WIND_10maboveground',nid)
   icode=nf_get_var_real(ncid,nid,wsgrid)
   icode=nf_inq_varid(ncid,'WDIR_10maboveground',nid)
   icode=nf_get_var_real(ncid,nid,wdgrid)
   wugrid=-wsgrid*sind(wdgrid)
   wvgrid=-wsgrid*cosd(wdgrid)
   icode=nf_inq_varid(ncid,'GUST_10maboveground',nid)
   icode=nf_get_var_real(ncid,nid,gsgrid)
   icode=nf_inq_varid(ncid,'TCDC_surface',nid)
   icode=nf_get_var_real(ncid,nid,cldgrid)
   if (mod(f+hour,6) == 0) then
      icode=nf_inq_varid(ncid,'APCP_surface',nid)
      if (icode == 0) then 
         icode=nf_get_var_real(ncid,nid,pcpgrid)
      else
         pcpgrid=0.
      endif
      icode=nf_inq_varid(ncid,'ASNOW_surface',nid)
      if (icode == 0) then 
         icode=nf_get_var_real(ncid,nid,snogrid)
      else
         snogrid=0.
      endif
!     print*,'Snow read: fcst=',f,' per=',period
   endif

! Interpolate data to each station location.

   do n=1,nsta
!     if (n == 2) print*,stname(n)
      call latlon_to_ij(ptlat(n),ptlon(n),proj,ri,rj)
      call gdtost(tpgrid,nx,ny,ri,rj,tp(n))
      tp(n)=(tp(n)-273.15)*1.8+32.  ! Convert to K
      hitpa(period,n)=max(tp(n),hitpa(period,n))
      lotpa(period,n)=min(tp(n),lotpa(period,n))
      avtpa(period,n)=avtpa(period,n)+tp(n)

      call gdtost(wsgrid,nx,ny,ri,rj,ws(n))
      call gdtost(wugrid,nx,ny,ri,rj,uw(n))
      call gdtost(wvgrid,nx,ny,ri,rj,vw(n))
      call gdtost(gsgrid,nx,ny,ri,rj,gs(n))
      ws(n)=max(0.,ws(n)*2.23693629)  ! Convert m/s to mph
      gs(n)=max(0.,gs(n)*2.23693629)  ! Convert m/s to mph
      wd(n)=atan2d(-uw(n),-vw(n))
      if (wd(n) < 0.) wd(n)=wd(n)+360.
!     hispa(period,n)=max(gs(n),hispa(period,n))
      lospa(period,n)=min(ws(n),lospa(period,n))
      avspa(period,n)=avspa(period,n)+ws(n)  
      hispa(period,n)=hispa(period,n)+gs(n)   ! Per group discussion, max wind speed will be ave gust.
      avuwa(period,n)=avuwa(period,n)+uw(n)
      avvwa(period,n)=avvwa(period,n)+vw(n)
      hidia(period,n)=max(wd(n),hidia(period,n))
      lodia(period,n)=min(wd(n),lodia(period,n))

      call gdtost(cldgrid,nx,ny,ri,rj,cld(n))
      cld(n)=max(0.,min(100.,cld(n)))
      avcla(period,n)=avcla(period,n)+cld(n)

      if (mod(f+hour,6) == 0) then
         call gdtost(pcpgrid,nx,ny,ri,rj,pcp(n))
         pcp(n)=max(0.,pcp(n)/25.4)  ! Convert mm to in
         tpcpa(period,n)=tpcpa(period,n)+pcp(n)
         call gdtost(snogrid,nx,ny,ri,rj,sno(n))
         sno(n)=max(0.,sno(n)*39.3700787)  ! Convert m to in
         tsnoa(period,n)=tsnoa(period,n)+sno(n)
!        if (n == 2) print*,'Snow sum: fcst=',f,' per=',period,'snow =',sno(n),'tot: ',tsnoa(period,n)
      endif

   enddo

! Housekeeping for next forecast period.

   if (mod(f+hour,12) == 0) then
      do n=1,nsta
         avtpa(period,n)=avtpa(period,n)/ct
         avspa(period,n)=avspa(period,n)/ct
         hispa(period,n)=hispa(period,n)/ct
         avuwa(period,n)=avuwa(period,n)/ct
         avvwa(period,n)=avvwa(period,n)/ct
         avdia(period,n)=atan2d(-avuwa(period,n),-avvwa(period,n))
         if (avdia(period,n) < 0.) avdia(period,n)=avdia(period,n)+360.
         avcla(period,n)=avcla(period,n)/ct
         if (avcla(period,n) < 10.) then
            avcld(period,n)="CLEAR"
         elseif (avcla(period,n) < 25.) then
            avcld(period,n)="FEW"
         elseif (avcla(period,n) < 50.) then
            avcld(period,n)="SCATTERED"
         elseif (avcla(period,n) < 90.) then
            avcld(period,n)="BROKEN"
         else
            avcld(period,n)="OVERCAST"
         endif
         if (period+1 < 7) then
            hitpa(period+1,n)=tp(n)
            lotpa(period+1,n)=tp(n)
            avtpa(period+1,n)=tp(n)
!           hispa(period+1,n)=ws(n)
            lospa(period+1,n)=ws(n)
            avspa(period+1,n)=ws(n)
            hispa(period+1,n)=gs(n)
            avuwa(period+1,n)=uw(n)
            avvwa(period+1,n)=vw(n)
            avcla(period+1,n)=cld(n)
         endif
      enddo
      period=period+1
      ct=1
   endif

   icode=nf_close(ncid)
enddo

open(1,file=trim(odir)//'/nbm.txt',form='formatted',status='unknown')
do n=1,nsta
   write(1,'(a10,''  NWS|'',6(i3,2i4''|''))')   stname(n),(nint(avtpa(f,n)),nint(lotpa(f,n)),nint(hitpa(f,n)),f=1,6)
   write(1,'(''Avg,Min,Max NWS|'',6(i3,2i4''|''))')       (nint(avspa(f,n)),nint(lospa(f,n)),nint(hispa(f,n)),f=1,6)
   write(1,'(''Avg,Min,Max NWS|'',6(i3,2i4''|''))')       (nint(avdia(f,n)),nint(lodia(f,n)),nint(hidia(f,n)),f=1,6)
   write(1,'(''Avg         NWS|'',6(a10,1x''|''))')       (trim(avcld(f,n)),f=1,6)
   write(1,'(''Total (in)  NWS|'',6(f5.1,i5,1x''|''))') (tpcpa(f,n),nint(tsnoa(f,n)),f=1,6)
enddo
close(1)

deallocate(avtpa,hitpa,lotpa,avspa,hispa,lospa,avdia,hidia,lodia,avuwa,avvwa,avcla,avcld    &
          ,tpcpa,tsnoa,tp,ws,wd,uw,vw,gs,cld,pcp,sno                                        &
          ,dgrid,lat,lon,tpgrid,wsgrid,wdgrid,wugrid,wvgrid,gsgrid,cldgrid,pcpgrid,snogrid)

end
