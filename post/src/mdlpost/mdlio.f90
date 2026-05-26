subroutine write_cdf

use mdlgrid

implicit none

include 'netcdf.inc'

integer :: icode,nid,ncid,i4time
integer, dimension(4) :: start,cdfct

integer*2 :: short

real :: lat0,sw(2),ne(2)

real*8 :: reftime,valtime

character(len=256) :: cdlname

! xsec info

integer, parameter :: nxsec=7
integer :: p
integer, dimension(nxsec) :: ysec
data ysec/189,203,217,231,245,259,273/

lat0=90.
sw(1)=llat(1,1)
sw(2)=llon(1,1)
ne(1)=llat(lx,ly)
ne(2)=llat(lx,ly)

! Create valtime and reftime

call adate_to_i4time(adate,i4time)
reftime=float(i4time)

! Compute number of sec in forecast and add to reftime to get valtime.

valtime=reftime+fcsttime

! Write surface data to fsf file.

cdlname=trim(lapsdataroot)//'/cdl/fsf.cdl'
print *,'fsf netcdf file --> ',trim(fsfname)

! Generate output cdf file using correct cdl file.

call system('/usr/bin/ncgen -o '//trim(fsfname)//' '//trim(cdlname))

! Open this created cdf for writing.

icode=nf_open(trim(fsfname),nf_write,ncid)
if (ncid <= 0) then
   print *,'Could not open file',trim(fsfname)
   return
endif

! Write reftime and valtime.

icode=nf_inq_varid(ncid,'reftime',nid)
icode=nf_put_var_double(ncid,nid,reftime)
icode=nf_inq_varid(ncid,'valtime',nid)
icode=nf_put_var_double(ncid,nid,valtime)

! Write grid parameters.

icode=nf_inq_varid(ncid,'modelmapproj',nid)
icode=nf_put_var_int2(ncid,nid,lapproj)
icode=nf_inq_varid(ncid,'Nx',nid)
short=lx
icode=nf_put_var_int2(ncid,nid,short)
icode=nf_inq_varid(ncid,'Ny',nid)
short=ly
icode=nf_put_var_int2(ncid,nid,short)
icode=nf_inq_varid(ncid,'Lat0',nid)
icode=nf_put_var_real(ncid,nid,lat0)
icode=nf_inq_varid(ncid,'Lat1',nid)
icode=nf_put_var_real(ncid,nid,truelat1)
icode=nf_inq_varid(ncid,'Lat2',nid)
icode=nf_put_var_real(ncid,nid,truelat2)
icode=nf_inq_varid(ncid,'Lon0',nid)
icode=nf_put_var_real(ncid,nid,stdlon)
icode=nf_inq_varid(ncid,'Dx',nid)
icode=nf_put_var_real(ncid,nid,grid_spacing)
icode=nf_inq_varid(ncid,'Dy',nid)
icode=nf_put_var_real(ncid,nid,grid_spacing)
icode=nf_inq_varid(ncid,'Sw',nid)
icode=nf_put_var_real(ncid,nid,sw)
icode=nf_inq_varid(ncid,'Ne',nid)
icode=nf_put_var_real(ncid,nid,ne)

! Write surface arrays.

icode=nf_inq_varid(ncid,'msl',nid)
icode=nf_put_var_real(ncid,nid,slp)
icode=nf_inq_varid(ncid,'spr',nid)
icode=nf_put_var_real(ncid,nid,prsfc)
icode=nf_inq_varid(ncid,'stp',nid)
icode=nf_put_var_real(ncid,nid,tpsfc)
icode=nf_inq_varid(ncid,'tps',nid)
icode=nf_put_var_real(ncid,nid,tpshl)
icode=nf_inq_varid(ncid,'ltp',nid)
icode=nf_put_var_real(ncid,nid,tplow)
icode=nf_inq_varid(ncid,'sgt',nid)
icode=nf_put_var_real(ncid,nid,tpgnd)
where(tdsfc>tpshl) tdsfc=tpshl
icode=nf_inq_varid(ncid,'std',nid)
icode=nf_put_var_real(ncid,nid,tdsfc)
icode=nf_inq_varid(ncid,'srh',nid)
icode=nf_put_var_real(ncid,nid,rhsfc)
icode=nf_inq_varid(ncid,'mrs',nid)
icode=nf_put_var_real(ncid,nid,mrshl)
icode=nf_inq_varid(ncid,'lmr',nid)
icode=nf_put_var_real(ncid,nid,mrlow)
icode=nf_inq_varid(ncid,'suw',nid)
icode=nf_put_var_real(ncid,nid,uwshl)
icode=nf_inq_varid(ncid,'svw',nid)
icode=nf_put_var_real(ncid,nid,vwshl)
icode=nf_inq_varid(ncid,'luw',nid)
icode=nf_put_var_real(ncid,nid,uwlow)
icode=nf_inq_varid(ncid,'lvw',nid)
icode=nf_put_var_real(ncid,nid,vwlow)
icode=nf_inq_varid(ncid,'uws',nid)
icode=nf_put_var_real(ncid,nid,uwshl)
icode=nf_inq_varid(ncid,'vws',nid)
icode=nf_put_var_real(ncid,nid,vwshl)
icode=nf_inq_varid(ncid,'r01',nid)
icode=nf_put_var_real(ncid,nid,r01)
icode=nf_inq_varid(ncid,'rto',nid)
icode=nf_put_var_real(ncid,nid,pcp)
icode=nf_inq_varid(ncid,'rcto',nid)
icode=nf_put_var_real(ncid,nid,cpcp)
icode=nf_inq_varid(ncid,'s01',nid)
icode=nf_put_var_real(ncid,nid,s01)
icode=nf_inq_varid(ncid,'sdn',nid)
icode=nf_put_var_real(ncid,nid,sdn)
where(hsn<0.) hsn=0.
icode=nf_inq_varid(ncid,'hsn',nid)
icode=nf_put_var_real(ncid,nid,hsn)
icode=nf_inq_varid(ncid,'sto',nid)
icode=nf_put_var_real(ncid,nid,sno)
icode=nf_inq_varid(ncid,'gto',nid)
icode=nf_put_var_real(ncid,nid,gra)
icode=nf_inq_varid(ncid,'ito',nid)
icode=nf_put_var_real(ncid,nid,ice)
icode=nf_inq_varid(ncid,'acc',nid)
icode=nf_put_var_real(ncid,nid,acc)
icode=nf_inq_varid(ncid,'spt',nid)
icode=nf_put_var_real(ncid,nid,spt)
icode=nf_inq_varid(ncid,'lif',nid)
icode=nf_put_var_real(ncid,nid,lif)
icode=nf_inq_varid(ncid,'cld',nid)
icode=nf_put_var_real(ncid,nid,cldamt)
icode=nf_inq_varid(ncid,'cei',nid)
icode=nf_put_var_real(ncid,nid,ceil)
icode=nf_inq_varid(ncid,'swr',nid)
icode=nf_put_var_real(ncid,nid,swin)
icode=nf_inq_varid(ncid,'lwr',nid)
icode=nf_put_var_real(ncid,nid,lwin)
icode=nf_inq_varid(ncid,'swo',nid)
icode=nf_put_var_real(ncid,nid,swout)
icode=nf_inq_varid(ncid,'lwo',nid)
icode=nf_put_var_real(ncid,nid,lwout)
icode=nf_inq_varid(ncid,'gst',nid)
icode=nf_put_var_real(ncid,nid,gust)
icode=nf_inq_varid(ncid,'frz',nid)
if (icode == 0) icode=nf_put_var_real(ncid,nid,m0z)
icode=nf_inq_varid(ncid,'wb0',nid)
if (icode == 0) icode=nf_put_var_real(ncid,nid,wb0)

icode=nf_close(ncid)

! Write upper air data to fua file.

cdlname=trim(lapsdataroot)//'/cdl/fua.cdl'
print *,'fua netcdf file --> ',trim(fuaname)

! Generate output cdf file using correct cdl file.

call system('/usr/bin/ncgen -o '//trim(fuaname)//' '//trim(cdlname))

! Open this created cdf for writing.

icode=nf_open(trim(fuaname),nf_write,ncid)
if (ncid <= 0) then
   print *,'Could not open file',trim(fuaname)
   return
endif

! Write reftime and valtime.

icode=nf_inq_varid(ncid,'reftime',nid)
icode=nf_put_var_double(ncid,nid,reftime)
icode=nf_inq_varid(ncid,'valtime',nid)
icode=nf_put_var_double(ncid,nid,valtime)

! Write grid parameters.

icode=nf_inq_varid(ncid,'modelmapproj',nid)
icode=nf_put_var_int2(ncid,nid,lapproj)
icode=nf_inq_varid(ncid,'Nx',nid)
short=lx
icode=nf_put_var_int2(ncid,nid,short)
icode=nf_inq_varid(ncid,'Ny',nid)
short=ly
icode=nf_put_var_int2(ncid,nid,short)
icode=nf_inq_varid(ncid,'Nz',nid)
short=lz
icode=nf_put_var_int2(ncid,nid,short)
icode=nf_inq_varid(ncid,'Lat0',nid)
icode=nf_put_var_real(ncid,nid,lat0)
icode=nf_inq_varid(ncid,'Lat1',nid)
icode=nf_put_var_real(ncid,nid,truelat1)
icode=nf_inq_varid(ncid,'Lat2',nid)
icode=nf_put_var_real(ncid,nid,truelat2)
icode=nf_inq_varid(ncid,'Lon0',nid)
icode=nf_put_var_real(ncid,nid,stdlon)
icode=nf_inq_varid(ncid,'Dx',nid)
icode=nf_put_var_real(ncid,nid,grid_spacing)
icode=nf_inq_varid(ncid,'Dy',nid)
icode=nf_put_var_real(ncid,nid,grid_spacing)
icode=nf_inq_varid(ncid,'Sw',nid)
icode=nf_put_var_real(ncid,nid,sw)
icode=nf_inq_varid(ncid,'Ne',nid)
icode=nf_put_var_real(ncid,nid,ne)

! Write isobaric arrays.

icode=nf_inq_varid(ncid,'pr',nid)
icode=nf_put_var_real(ncid,nid,lprs)
icode=nf_inq_varid(ncid,'ht',nid)
icode=nf_put_var_real(ncid,nid,ht)
icode=nf_inq_varid(ncid,'tp',nid)
icode=nf_put_var_real(ncid,nid,tp)
icode=nf_inq_varid(ncid,'mr',nid)
icode=nf_put_var_real(ncid,nid,mr)
icode=nf_inq_varid(ncid,'uw',nid)
icode=nf_put_var_real(ncid,nid,uw)
icode=nf_inq_varid(ncid,'vw',nid)
icode=nf_put_var_real(ncid,nid,vw)
icode=nf_inq_varid(ncid,'ww',nid)
icode=nf_put_var_real(ncid,nid,ww)
icode=nf_inq_varid(ncid,'n2',nid)
if (icode == 0) icode=nf_put_var_real(ncid,nid,stab*1000.)

icode=nf_close(ncid)

! Write xsec file.

if (trim(res) == "2km" .and. xsec) then

   cdlname=trim(lapsdataroot)//'/cdl/xsec.cdl'
   print *,'xsec netcdf file --> ',trim(xsecname)

! Generate output cdf file using correct cdl file.

   if (reftime == valtime) call system('/usr/bin/ncgen -o '//trim(xsecname)//' '//trim(cdlname))
   icode=nf_open(trim(xsecname),nf_write,ncid)
   if (ncid <= 0) then
      print *,'Could not open file',trim(xsecname)
      return
   endif

   if (reftime == valtime) then
      icode=nf_inq_varid(ncid,'reftime',nid)
      icode=nf_put_var_double(ncid,nid,reftime)
      start(1)=1
      cdfct(1)=nx
      do p=1,nxsec
         start(2)=p
         cdfct(2)=1
         icode=nf_inq_varid(ncid,'lat',nid)
         icode=nf_put_vara_real(ncid,nid,start,cdfct,nlat(:,ysec(p)))
         icode=nf_inq_varid(ncid,'lon',nid)
         icode=nf_put_vara_real(ncid,nid,start,cdfct,nlon(:,ysec(p)))
      enddo
   endif

   start(1)=fcsttime/3600+1
   cdfct(1)=1
   icode=nf_inq_varid(ncid,'valtime',nid)
   icode=nf_put_vara_double(ncid,nid,start,cdfct,valtime)

   start(1)=1
   cdfct(1)=nx
   start(2)=1
   cdfct(2)=nz
   start(4)=fcsttime/3600+1
   cdfct(4)=1
   do p=1,nxsec
      start(3)=p
      cdfct(3)=1
      icode=nf_inq_varid(ncid,'uw',nid)
      icode=nf_put_vara_real(ncid,nid,start,cdfct,nuw(:,ysec(p),:))
      icode=nf_inq_varid(ncid,'ht',nid)
      icode=nf_put_vara_real(ncid,nid,start,cdfct,nht(:,ysec(p),:))
      icode=nf_inq_varid(ncid,'pr',nid)
      icode=nf_put_vara_real(ncid,nid,start,cdfct,npr(:,ysec(p),:))
   enddo

   icode=nf_close(ncid)

endif

return
end subroutine

!===============================================================================

subroutine write_point_forecast

use mdlgrid

implicit none

integer :: grid,rat,n
character(len=256) :: ptname
character(len=8) :: asec
character(len=3) :: agrid

grid=fcstgrid 

write(asec,'(i8.8)') fcsttime
write(agrid,'(''.g'',i1)') grid
ptname='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate  &
      //'/ptfcst/20'//adate//'_'//asec//'.'//trim(model)//agrid
print*,'point fcst file --> ',trim(ptname)

open(1,file=trim(ptname),form='formatted',status='unknown')

write(1,900)
900 format('#stn-name |msl-mb|spr-mb|stp-K|std-K|u-m/s|v-m/s|g-m/s|'   &
          ,' w-m/s|sw-W|sw%|lw-W|'                                     &
          ,'ltp-K|lum/s|lvm/s|sgt-K|slt-K|rt-mm|rc-mm| st-mm|'         &
          ,'pbl-m|viskm|ceil-m |pt|cl%|wtb-K|'                         &
          ,'m5ht-m|7tp-K|7cw-kg/kg|7u-m/s|7v-m/s|')

pfmsl=pfmsl/100.
pfspr=pfspr/100.
where(pfswr < 0.) pfswr=0.
where(pfswr > 10000.) pfswr=0.
where(pflwr < 0.) pflwr=0.
where(pflwr > 10000.) pflwr=0.
where(pfrto < 0.) pfrto=0.
where(pfrtc < 0.) pfrtc=0.
where(pfsto < 0.) pfsto=0.
pfvis=max(0.,min(999.9,pfvis))
pfcei=max(0.,min(99999.9,pfcei))
where(pf7cw > 1.) pf7cw=0.
where(pf7cw < 0.) pf7cw=0.
where(pfgst < 0.) pfgst=0.
do n=1,npf
   if (pfsmx(n) > 0) then
      rat=max(0,min(100,nint(pfswr(n)/pfsmx(n)*100.)))
   else
      rat=-1
   endif
   write(1,901) pfname(n)                            &
               ,pfmsl(n),pfspr(n),pfstp(n),pfstd(n)  &
               ,pfsuw(n),pfsvw(n),pfgst(n),pfsww(n)  &
               ,nint(pfswr(n)),rat,nint(pflwr(n))    &
               ,pfltp(n),pfluw(n),pflvw(n),pfsgt(n),pfslt(n),pfrto(n),pfrtc(n),pfsto(n)  &
               ,nint(pfpbl(n))     &
               ,pfvis(n),pfcei(n),nint(pfspt(n)),nint(pfcld(n)),pfwtb(n)  &
               ,nint(pfm5z(n)),pf7tp(n),pf7cw(n),pf7uw(n),pf7vw(n)
enddo
901 format(a10,'|',2(f6.1,'|'),2(f5.1,'|'),3(f5.1,'|'),f6.3,'|'  &
          ,i4,'|',i3,'|',i4                                      &
          ,7('|',f5.1),'|',f6.1,'|',i5,'|',f5.1,'|',f8.1,'|',i2,'|',i3,'|',f5.1,'|'  &
          ,i4,'|',f5.1,'|',f8.6,'|',2(f5.1,'|'))

close(1)

! Kick off database script.

if (db_script(1:1) /= ' ') then
   print*,'Starting grid ',trim(model)//' database population for: ',trim(ptname)
   call system('/usr/bin/perl '//db_script//' -d '//trim(domain)//' -r '//trim(res)//' '//ptname)
endif

return
end subroutine

!===============================================================================

subroutine write_time_height

use mdlgrid

implicit none

integer :: k,n,kk
real, allocatable, dimension(:) :: column
character(len=256) :: ptname
character(len=3) :: afcst

! Kludge to eliminate any levels above 100 mb.

kk=min(41,lz)
allocate(column(kk))

write(afcst,'(i3.3)') fcsttime/3600
do n=1,nth
   ptname='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate  &
         //'/timeht/'//trim(thname(n))//'_xxx.plothov.exec.part1'

   open(unit=11,file=trim(ptname),status='unknown',form='formatted')
   write(11,'(a9,i6,a4)') 'set lev ',nint(thspr(n)),' 200'
   close(11)

   ptname='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate  &
         //'/timeht/'//trim(thname(n))//'_hov_'//afcst//'.gdat'//char(0)

   do k=1,kk
      column(k)=thte(n,k)
   enddo
   call writeb3d(kk,1,1,column,trim(ptname),1)
   do k=1,kk
      column(k)=thtp(n,k)
   enddo
   call writeb3d(kk,1,1,column,trim(ptname),0)
   do k=1,kk
      column(k)=thuw(n,k)
   enddo
   call writeb3d(kk,1,1,column,trim(ptname),0)
   do k=1,kk
      column(k)=thvw(n,k)
   enddo
   call writeb3d(kk,1,1,column,trim(ptname),0)
   do k=1,kk
      column(k)=thww(n,k)
   enddo
   call writeb3d(kk,1,1,column,trim(ptname),0)
   do k=1,kk
      column(k)=thmr(n,k)
   enddo
   call writeb3d(kk,1,1,column,trim(ptname),0)

enddo

deallocate(column)

return
end subroutine

!===============================================================================

subroutine write_sndg

use mdlgrid

implicit none

integer :: n,k

character(len=256) :: ptname
character(len=3) :: afcst

write(afcst,'(i3.3)') fcsttime/3600
do n=1,nsn

   ptname='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate  &
         //'/sndg/'//trim(snname(n))//'_sndg_'//afcst//'.txt'

   open(unit=11,file=trim(ptname),status='unknown',form='formatted')
   write(11,'(6f12.2)') snpr(n,1),snht(n,1),sntp(n,1)  &
                       ,sntd(n,1),snsp(n,1),sndi(n,1)
   do k=2,nz+1
      if (snpr(n,k) < snpr(n,1))                             &
         write(11,'(6f12.2)') snpr(n,k),snht(n,k),sntp(n,k)  &
                             ,sntd(n,k),snsp(n,k),sndi(n,k)
   enddo
   close(11)

enddo

return
end subroutine

!===============================================================================

subroutine mdl_diag(post)

! Print model diagnostics.

use mdlgrid

implicit none

integer :: k
character(len=*) :: post

if (trim(post) == 'native') then
   print*,' '
   print*,'Native map projection parameters          Output map projection parameters'
   print*,'--------------------------------          --------------------------------'
   print'(a,3i5,11x,a,3i5)',' grid dimensions:',nx,ny,nz,'grid dimensions:',lx,ly,lz
   print'(a,f10.1,16x,a,f10.1)',' grid spacing   :',ngrid_spacingx,'grid spacing   :',grid_spacing
   print'(1x,2(''proj: '',a32,4x))',nprojection,projection
   print'(a,f10.3,16x,a,f10.3)',' true latitude 1:',ntruelat1,'true latitude 1:',truelat1
   print'(a,f10.3,16x,a,f10.3)',' true latitude 2:',ntruelat2,'true latitude 2:',truelat2
   print'(a,f10.3,16x,a,f10.3)',' std longitude  :',nstdlon,'std longitude  :',stdlon
   print*,' '
   print'(a,2f10.2)', ' Min/Max value of native terrain: ',minval(nhtsfc),maxval(nhtsfc)
   print*,' '
   print*,'Corner points from native grid:'
   print*,'==============================='
   print*,' '
   if (trim(model) == 'gfs') then
      print'(f8.3,1x,f8.3,10x,f8.3,1x,f8.3)'  &
           ,nlat(1,1),nlon(1,1),nlat(nx,1),nlon(nx,1)
   else
      print'(f8.3,1x,f8.3,10x,f8.3,1x,f8.3)'  &
           ,nlat(1,ny),nlon(1,ny),nlat(nx,ny),nlon(nx,ny)
   endif
   print*,'      (NW)----------------------(NE)'
   print*,'        |                        |'
   print*,'        |                        |'
   print*,'      (SW)----------------------(SE)'
   if (trim(model) == 'gfs') then
      print'(f8.3,1x,f8.3,10x,f8.3,1x,f8.3)'  &
           ,nlat(1,ny),nlon(1,ny),nlat(nx,ny),nlon(nx,ny)
   else
      print'(f8.3,1x,f8.3,10x,f8.3,1x,f8.3)'  &
           ,nlat(1,1),nlon(1,1),nlat(nx,1),nlon(nx,1)
   endif
   print*, ' '

elseif (trim(post) == 'horizontal') then
   print*,' '
   print'(a,2f10.2)', ' Min/Max value of hinterp terrain: ', minval(htsfc),maxval(htsfc)
   print*,' '
   print*,'Corner points from hinterp grid:'
   print*,'==============================='
   print*,' '
   print'(f8.3,1x,f8.3,10x,f8.3,1x,f8.3)'  &
        ,llat(1,ly),llon(1,ly),llat(lx,ly),llon(lx,ly)
   print*,'      (NW)----------------------(NE)'
   print*,'        |                        |'
   print*,'        |                        |'
   print*,'      (SW)----------------------(SE)'
   print'(f8.3,1x,f8.3,10x,f8.3,1x,f8.3)'  &
        ,llat(1,1),llon(1,1),llat(lx,1),llon(lx,1)

   print*, ' '
   print*,'Diagnostics from hinterp domain center:'
   print'(a,f7.0)',' Terrain height at center = ',htsfc(lx/2,ly/2)
   print*,'------------------------------------------------------------'
   print*,'LEVEL     PRES(Pa)  HEIGHT     T      QV         U       V'
   print*,'------------------------------------------------------------'
   do k=1,nz
      print '(i5,2x,f12.1,2x,f6.0,2x,f6.2,2x,f8.6,2f8.2)'   &
            ,k,hpr(lx/2,ly/2,k),hht(lx/2,ly/2,k)  &
            ,htp(lx/2,ly/2,k),hmr(lx/2,ly/2,k)   &
            ,huw(lx/2,ly/2,k),hvw(lx/2,ly/2,k)
   enddo

elseif (post == 'vertical') then
   print*,' '
   print*,'Diagnostics from isobaric domain center:'
   print*,'--------------------------------------------'
   print*,'LEVEL     PRES(Pa)  HEIGHT     T      QV'
   print*,'--------------------------------------------'
   do k=1,lz
      print '(i5,2x,f12.1,2x,f6.0,2x,f6.2,2x,f8.6)'   &
            ,k,lprs(k),ht(lx/2,ly/2,k)  &
            ,tp(lx/2,ly/2,k),mr(lx/2,ly/2,k)
   enddo
   print*,' '
endif

return
end subroutine

!===============================================================================

subroutine image_host_list

! Fill host list for image generation.

use mdlgrid

implicit none

logical :: there

proclist='/home/caic/caic/rtsys/post/namelist/'  &
         //trim(domain)//'-'//trim(res)//'-'//trim(model)//'-hosts.post'
inquire(file=trim(proclist),exist=there)
if (there) then
   print*,'Found hostlist: ',trim(proclist)
   open(12,file=trim(proclist),form='formatted',status='old')
1  continue
   nhost=nhost+1
   read(12,'(a)',end=10) hosts(nhost)
   goto 1
10 continue
   close(12)
   nhost=nhost-1
else
   nhost=1
   hosts(1)='localhost'
endif

return
end subroutine

!===============================================================================

subroutine image_gen(hour)

! Initiate image generation script.
!   Start images from one forecast hour earlier in an effort to address
!    timing issues with image generation.

use mdlgrid

implicit none

integer :: hour,hostid
character(len=3) :: afcst

hostid=mod(hour,nhost)+1
write(afcst,'(i3.3)') hour
print*,'Starting image script for forecast hour:',hour,' on node: ',trim(hosts(hostid))
if (trim(hosts(hostid)) == "localhost") then
   call system(trim(image_script)                                  &
             //' '//trim(domain)//' '//trim(res)//' '//trim(model) &
             //' '//afcst(1:3)//' '//afcst(1:3)//' '//adate//' &')
else
   call system('ssh '//trim(hosts(hostid))                                 &
                     //' '//trim(image_script)                             &
                     //' '//trim(domain)//' '//trim(res)//' '//trim(model) &
                     //' '//afcst(1:3)//' '//afcst(1:3)//' '//adate//' &')
endif

return
end subroutine

!===============================================================================

subroutine write_db

! Write forecast grids to database for use by interactive point forecast.

use mdlgrid
use mdlconstants
use mysql_binding

implicit none

real, allocatable, dimension(:,:) :: spd,dir

integer :: i,j,l

character(len=5000) :: query
character(len=10)   :: af,ai,aj,atp,atd,arh,aspd,adir,agst,anr,acr,asn

type(myfortran) :: myf

! Allocate and compute wind speed and direction.

allocate(spd(lx,ly),dir(lx,ly))

spd=sqrt(uwshl**2+vwshl**2)*2.23694
dir=270.-(atan2(vwshl,uwshl)*rad2deg)
where (dir>360.) dir=dir-360.

! Sanity check.

where(gust<spd) gust=spd

! Connect to mysql database.

call myfortran_init()
myf=myfortran_connect("127.0.0.1","john","Hrsb!53706","weather")

write(af,'(i10)') fcsttime/3600
query=""
do j=1,ly
   write(aj,'(i10)') j-1
   do i=1,lx
      write(ai,'(i10)') i-1
      write(atp,'(i10)') nint((tpshl(i,j)-273.15)*18.+320.)
      write(atd,'(i10)') nint((tdsfc(i,j)-273.15)*18.+320.)
      write(arh,'(i10)') nint(rhsfc(i,j)*10.)
      write(aspd,'(i10)') nint(spd(i,j)*10.)
      write(adir,'(i10)') nint(dir(i,j))
      write(agst,'(i10)') nint(gust(i,j)*22.3694)
      write(anr,'(i10)') nint(pcp(i,j)/0.0254)
      write(acr,'(i10)') nint(cpcp(i,j)/0.0254)
      write(asn,'(i10)') nint(acc(i,j)/0.254)
      l=len_trim(query)
      if (l > 0) then
         query=trim(query)               &
            //",('"//trim(dbtime)//"'"   &
            // ","//trim(adjustl(af))    &
            // ","//trim(adjustl(ai))    &
            // ","//trim(adjustl(aj))    &
            // ","//trim(adjustl(atp))   &
            // ","//trim(adjustl(atd))   &
            // ","//trim(adjustl(arh))   &
            // ","//trim(adjustl(aspd))  &
            // ","//trim(adjustl(adir))  &
            // ","//trim(adjustl(agst))  &
            // ","//trim(adjustl(anr))   &
            // ","//trim(adjustl(acr))   &
            // ","//trim(adjustl(asn))   &
            // ")"
         if (l > 4500) then
            call myfortran_query_do(myf,trim(query))
            query=""
         endif
      else
         query="replace into wrf_"//trim(res)//"_sfc_fcst (inittime,fcst,i,j,tp,td,rh,spd,dir,gst,rnto,rcto,snto) values ("  &
            // "'"//trim(dbtime)//"'"    &
            // ","//trim(adjustl(af))    &
            // ","//trim(adjustl(ai))    &
            // ","//trim(adjustl(aj))    &
            // ","//trim(adjustl(atp))   &
            // ","//trim(adjustl(atd))   &
            // ","//trim(adjustl(arh))   &
            // ","//trim(adjustl(aspd))  &
            // ","//trim(adjustl(adir))  &
            // ","//trim(adjustl(agst))  &
            // ","//trim(adjustl(anr))   &
            // ","//trim(adjustl(acr))   &
            // ","//trim(adjustl(asn))   &
            // ")"
      endif
      if (len_trim(query) > 0) call myfortran_query_do(myf,trim(query))
   enddo
enddo

! Disconnect from db.

call myfortran_disconnect(myf)
call myfortran_shutdown()

deallocate(spd,dir)

return
end subroutine
