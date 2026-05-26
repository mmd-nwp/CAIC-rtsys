program mdl2rip

implicit none

include 'netcdf.inc'

integer :: ihrip(32),icode,ncid,nid,nx,ny,nz,year,julday,month,day,hour  &
          ,mapproj,ifcst,longts,nhr,i,j,k,n
integer*2 :: short

real :: rhrip(32),dx,lat0,lat1,lat2,lon0,rfcst,pint
real, external :: relhum

character(len=256) :: fname,outdir
character(len=64) :: chrip(64),vardesc,domain,res
character(len=24) :: plchun
character(len=15) :: date
character(len=10) :: afcst,model

real, allocatable, dimension(:,:,:) :: ingrid,uuu,vvv,www,tmk,ght,prs,rh
real, allocatable, dimension(:,:) :: acc,spt,srh,r01,r01h,r24,r48,rto,s12  &
                                    ,stp,std,tpw,lif,pbl,cld,suw,svw,spd   &
                                    ,gst,ter,sfp,msl,rtc,frz,wb0,hsn
real, allocatable, dimension(:) :: pr

read(5,'(a)') domain
read(5,'(a)') res
read(5,'(a)') model
read(5,*) lat0,lon0,longts
read(5,'(a)') date

read(date(1:7),'(i2,i3,i2)') year,julday,hour
call jd_to_md(julday,year,month,day)
read(date(11:13),'(i3)') ifcst

rfcst=nint(float(ifcst)*3600./float(longts))*longts/3600.
write(afcst,'(f10.5)') rfcst
do i=1,4
   if (afcst(i:i) == ' ') afcst(i:i)='0'
enddo

outdir='.'
nz=1

! If this an NCEP model, then read 3-d grids.

if (trim(model) == 'nam' .or. trim(model) == "gfs") then
   fname='/model/'//trim(domain)//'/'//trim(res)//'/laps/lapsprd/fua/'//trim(model)//'/'//date//'.fua'
   icode=nf_open(trim(fname),nf_nowrite,ncid)

   icode=nf_inq_varid(ncid,'Nx',nid)
   icode=nf_get_var_int2(ncid,nid,short)
   nx=int(short)
   icode=nf_inq_varid(ncid,'Ny',nid)
   icode=nf_get_var_int2(ncid,nid,short)
   ny=int(short)
   icode=nf_inq_varid(ncid,'Nz',nid)
   icode=nf_get_var_int(ncid,nid,short)
   nz=int(short)
!  print*,nx,ny,nz

   allocate(ingrid(nx,ny,nz),prs(ny+1,nx+1,nz)   &
           ,uuu(ny+1,nx+1,nz),vvv(ny+1,nx+1,nz)  &
           ,tmk(ny+1,nx+1,nz),ght(ny+1,nx+1,nz)  &
           ,rh(ny+1,nx+1,nz),www(ny+1,nx+1,nz),pr(nz))

   icode=nf_inq_varid(ncid,'pr',nid)
   icode=nf_get_var_real(ncid,nid,pr)
   do k=1,nz
      prs(1:ny+1,1:nx+1,k)=pr(k)
   enddo
   icode=nf_inq_varid(ncid,'uw',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,nz,ingrid,uuu)
   icode=nf_inq_varid(ncid,'vw',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,nz,ingrid,vvv)
   icode=nf_inq_varid(ncid,'ww',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,nz,ingrid,www)
   icode=nf_inq_varid(ncid,'ht',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,nz,ingrid,ght)
   icode=nf_inq_varid(ncid,'tp',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,nz,ingrid,tmk)
   icode=nf_inq_varid(ncid,'mr',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,nz,ingrid,rh)
   do k=1,nz
   do j=1,nx+1
   do i=1,ny+1
      rh(i,j,k)=relhum(tmk(i,j,k),rh(i,j,k),prs(i,j,k))
   enddo
   enddo
   enddo
   icode=nf_close(ncid)

   deallocate(ingrid)

   allocate(ingrid(nx+2,ny+2,1),ter(ny+1,nx+1))

   fname='/model/'//trim(domain)//'/'//trim(res)//'/laps/static/static.nest7grid'
   icode=nf_open(trim(fname),nf_nowrite,ncid)
   icode=nf_inq_varid(ncid,'avg',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,1,ingrid(2:nx-1,2:ny-1,1),ter)
   icode=nf_close(ncid)

   deallocate(ingrid)
endif

! Open and read model fsf (fcst) file.

fname='/model/'//trim(domain)//'/'//trim(res)//'/laps/lapsprd/fsf/'//trim(model)//'/'//date//'.fsf'
print *, 'mdl2rip.f90: fname=',trim(fname)

icode=nf_open(fname,nf_nowrite,ncid)

icode=nf_inq_varid(ncid,'modelmapproj',nid)
icode=nf_get_var_int2(ncid,nid,short)
mapproj=int(short)
icode=nf_inq_varid(ncid,'Nx',nid)
icode=nf_get_var_int2(ncid,nid,short)
nx=int(short)
icode=nf_inq_varid(ncid,'Ny',nid)
icode=nf_get_var_int2(ncid,nid,short)
ny=int(short)
icode=nf_inq_varid(ncid,'Dx',nid)
icode=nf_get_var_real(ncid,nid,dx)
icode=nf_inq_varid(ncid,'Lat1',nid)
icode=nf_get_var_real(ncid,nid,lat1)
icode=nf_inq_varid(ncid,'Lat2',nid)
icode=nf_get_var_real(ncid,nid,lat2)

if (lon0 > 180.) lon0=lon0-360.

! Initialize rip header variables.

do i=1,32
   ihrip(i)=999999999
   rhrip(i)=9.e9
   chrip(i)=' '
   chrip(i+32)=' '
enddo

! Fill rip header variables.

chrip(1)='map projection (1: Lam. Conf., 2: Pol. Ster., 3: Mercator)'
ihrip(1)=mapproj
chrip(2)='number of dot points in the y-direction (coarse domain)'
ihrip(2)=ny+1
chrip(3)='number of dot points in the x-direction (coarse domain)'
ihrip(3)=nx+1
chrip(4)='number of dot points in the y-direction (this domain)'
ihrip(4)=ihrip(2)
chrip(5)='number of dot points in the x-direction (this domain)'
ihrip(5)=ihrip(3)
chrip(6)='number of dimensions of this variable (2 or 3)'
ihrip(6)=2
chrip(7)='grid of this variable (1: cross point dom., 0: dot point dom.)'
ihrip(7)=1
chrip(8)='vertical coordinate (0: hydrostatic sigma, 1: nonhyd. sigma)'
ihrip(8)=1
chrip(9)='number of half sigma levels'
ihrip(9)=nz
chrip(10)='mdateb: YYMMDDHH (truncated hour) of hour-0 for this dataset'
ihrip(10)=year*1000000+month*10000+day*100+hour
chrip(11)='mdate: YYMMDDHH (truncated hour) of this time'
ihrip(11)=ihrip(10)
chrip(12)='ice physics (1: sep. arrays for ice fields, 0: no sep. arrays)'
ihrip(12)=1
chrip(13)='Program #: 1:TER. 2:DG/RG. 3:RAW. 5:INT. 6:MOD. 11:MOD.(MM5V3)'
ihrip(13)=11
chrip(14)='landuse dataset (1: old, 13-cat; 2: USGS, 24-cat; 3: SiB, 16 )'
ihrip(14)=2

chrip(32+1)='first true latitude (deg.)'
rhrip(1)=lat1
chrip(32+2)='second true latitude (deg.)'
rhrip(2)=lat2
chrip(32+3)='central latitude of coarse domain (deg.)'
rhrip(3)=lat0
chrip(32+4)='central longitude of coarse domain(deg.)'
rhrip(4)=lon0
chrip(32+5)='grid distance of coarse domain (km)'
rhrip(5)=dx/1000.
chrip(32+6)='grid distance of this domain (km)'
rhrip(6)=rhrip(5)
chrip(32+7)='coarse dom. y-position of lower left corner of this domain'
rhrip(7)=1.
chrip(32+8)='coarse dom. x-position of lower left corner of this domain'
rhrip(8)=1.
chrip(32+13)='rhourb: diff (in h) between exact time and mdate of hour-0'
rhrip(13)=0.
chrip(32+14)='rhour: diff (in h) between exact time and mdate of this data'
rhrip(14)=0.
chrip(32+15)='xtime: exact time of this data relative to exact hour-0 (in h)'
rhrip(15)=float(ifcst)

! Allocate arrays and read requested field.

nhr=min(25,ifcst+1)

print*,'nx,ny ==========',nx,ny

allocate(ingrid(nx,ny,1))
allocate(acc(ny+1,nx+1),spt(ny+1,nx+1),srh(ny+1,nx+1),std(ny+1,nx+1)                  &
        ,tpw(ny+1,nx+1),sfp(ny+1,nx+1),r01(ny+1,nx+1),r01h(ny+1,nx+1),r24(ny+1,nx+1)  &
        ,r48(ny+1,nx+1),rto(ny+1,nx+1),s12(ny+1,nx+1),lif(ny+1,nx+1),stp(ny+1,nx+1)   &
        ,pbl(ny+1,nx+1),cld(ny+1,nx+1),suw(ny+1,nx+1),svw(ny+1,nx+1),spd(ny+1,nx+1)   &
        ,gst(ny+1,nx+1),msl(ny+1,nx+1),rtc(ny+1,nx+1),frz(ny+1,nx+1),wb0(ny+1,nx+1)   &
        ,hsn(ny+1,nx+1))

rtc=0.
icode=nf_inq_varid(ncid,'spr',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,sfp)
icode=nf_inq_varid(ncid,'msl',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,msl)
icode=nf_inq_varid(ncid,'acc',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,acc)
icode=nf_inq_varid(ncid,'spt',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,spt)
icode=nf_inq_varid(ncid,'srh',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,srh)
icode=nf_inq_varid(ncid,'r01',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,r01)
icode=nf_inq_varid(ncid,'rto',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,rto)
icode=nf_inq_varid(ncid,'tps',nid) 
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,stp)
icode=nf_inq_varid(ncid,'std',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,std)
icode=nf_inq_varid(ncid,'tpw',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,tpw)
icode=nf_inq_varid(ncid,'lif',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,lif)
icode=nf_inq_varid(ncid,'cld',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,cld)
icode=nf_inq_varid(ncid,'pbl',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,pbl)
icode=nf_inq_varid(ncid,'suw',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,suw)
icode=nf_inq_varid(ncid,'svw',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,svw)
icode=nf_inq_varid(ncid,'gst',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,gst)
icode=nf_inq_varid(ncid,'frz',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,frz)
frz=frz/1000.
icode=nf_inq_varid(ncid,'wb0',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,wb0)
wb0=wb0/1000.
icode=nf_inq_varid(ncid,'hsn',nid)
icode=nf_get_var_real(ncid,nid,ingrid)
call rearrange(nx,ny,1,ingrid,hsn)

icode=nf_close(ncid)

! Generate 24 hour precipitation accumulation.

if (ifcst <= 24) then
   do j=1,nx+1
   do i=1,ny+1
      r24(i,j)=rto(i,j)
   enddo
   enddo
else
   write(date(11:13),'(i3.3)') ifcst-24
   fname='/model/'//trim(domain)//'/'//trim(res)//'/laps/lapsprd/fsf/'//trim(model)//'/'//date//'.fsf'
   print *, 'mdl2rip.f90: fname=',trim(fname)
   icode=nf_open(fname,nf_nowrite,ncid)
   icode=nf_inq_varid(ncid,'rto',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,1,ingrid,r24)
   icode=nf_close(ncid)
   do j=1,nx+1
   do i=1,ny+1
      r24(i,j)=max(0.,rto(i,j)-r24(i,j))
   enddo
   enddo
endif

! Generate 48 hour precipitation accumulation.

if (ifcst <= 48) then
   do j=1,nx+1
   do i=1,ny+1
      r48(i,j)=rto(i,j)
   enddo
   enddo
else
   write(date(11:13),'(i3.3)') ifcst-48
   fname='/model/'//trim(domain)//'/'//trim(res)//'/laps/lapsprd/fsf/'//trim(model)//'/'//date//'.fsf'
   print *, 'mdl2rip.f90: fname=',trim(fname)
   icode=nf_open(fname,nf_nowrite,ncid)
   icode=nf_inq_varid(ncid,'rto',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,1,ingrid,r48)
   icode=nf_close(ncid)
   do j=1,nx+1
   do i=1,ny+1
      r48(i,j)=max(0.,rto(i,j)-r48(i,j))
   enddo
   enddo
endif

! Generate 12 hour snowfall accumulation.

if (ifcst <= 12) then
   do j=1,nx+1
   do i=1,ny+1
      s12(i,j)=acc(i,j)
   enddo
   enddo
else
   write(date(11:13),'(i3.3)') ifcst-12
   fname='/model/'//trim(domain)//'/'//trim(res)//'/laps/lapsprd/fsf/'//trim(model)//'/'//date//'.fsf'
   print *, 'mdl2rip.f90: fname=',trim(fname)
   icode=nf_open(fname,nf_nowrite,ncid)
   icode=nf_inq_varid(ncid,'acc',nid)
   icode=nf_get_var_real(ncid,nid,ingrid)
   call rearrange(nx,ny,1,ingrid,s12)
   icode=nf_close(ncid)
   do j=1,nx+1
   do i=1,ny+1
      s12(i,j)=max(0.,acc(i,j)-s12(i,j))
   enddo
   enddo
endif

! Generate spt, haines indexes and final parameter units conversions.

do j=1,nx+1
do i=1,ny+1
   s12(i,j)=s12(i,j)/25.4
   sfp(i,j)=sfp(i,j)*0.01
   msl(i,j)=msl(i,j)*0.01
   acc(i,j)=acc(i,j)/25.4
   hsn(i,j)=hsn(i,j)*39.3701
   if (spt(i,j) > 0.) then
      if (r01(i,j) > 2.54) then
         pint=2.
      elseif (r01(i,j) > 1.27) then
         pint=1.
      else
         pint=0.
      endif
      if (spt(i,j) == 1.) then
         spt(i,j)=1.+pint
      elseif (spt(i,j) == 2. .or. spt(i,j) == 8 .or.  &
              spt(i,j) == 12.) then
         spt(i,j)=7.+pint
      elseif (spt(i,j) == 4. .or. spt(i,j) == 5 .or.  &
              spt(i,j) == 6. .or. spt(i,j) == 7) then
         spt(i,j)=4.+pint
      elseif (spt(i,j) == 3. .or. spt(i,j) == 9 .or.  &
              spt(i,j) == 14.) then
         spt(i,j)=10.+pint
      elseif (spt(i,j) == 10. .or. spt(i,j) == 11 .or.  &
              spt(i,j) == 13.) then
         spt(i,j)=13.+pint
      endif
   else
      spt(i,j)=9.0e+9
   endif
   r01(i,j)=r01(i,j)/25.4
   r01h(i,j)=r01(i,j)*100.
   r24(i,j)=r24(i,j)/0.254
   r48(i,j)=r48(i,j)/0.254
   stp(i,j)=(stp(i,j)-273.15)*1.8+32.
   std(i,j)=(std(i,j)-273.15)*1.8+32.
!  spd(i,j)=((suw(i,j)**2+svw(i,j)**2)**0.5)*1.9438   ! m/s to kts
   spd(i,j)=((suw(i,j)**2+svw(i,j)**2)**0.5)*2.23694  ! m/s to mph
   gst(i,j)=gst(i,j)*2.23694    ! m/s to mph
   tpw(i,j)=tpw(i,j)*0.0393696
   pbl(i,j)=pbl(i,j)*0.0032808  ! Convert from m to kft
enddo
enddo
print*,"HS: ",maxval(hsn),minval(hsn)

! Write data to rip file.

fname=trim(outdir)//'/caic_'//afcst//'_s12'
open(1,file=fname,form='unformatted',status='unknown')
plchun='in'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) s12
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_acc'
open(1,file=fname,form='unformatted',status='unknown')
plchun='in'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) acc
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_hsn'
open(1,file=fname,form='unformatted',status='unknown')
plchun='in'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) hsn
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_r01'
open(1,file=fname,form='unformatted',status='unknown')
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) r01
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_r01h'
open(1,file=fname,form='unformatted',status='unknown')
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) r01h
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_r24'
open(1,file=fname,form='unformatted',status='unknown')
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) r24
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_r48'
open(1,file=fname,form='unformatted',status='unknown')
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) r48
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_spt'
open(1,file=fname,form='unformatted',status='unknown')
plchun=' '
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) spt
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_suw'
open(1,file=fname,form='unformatted',status='unknown')
plchun='mph'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) suw
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_svw'
open(1,file=fname,form='unformatted',status='unknown')
plchun='mph'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) svw
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_lspd'
open(1,file=fname,form='unformatted',status='unknown')
plchun='mph'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) spd
close(1)
print*,minval(spd),maxval(spd)
fname=trim(outdir)//'/caic_'//afcst//'_gst'
open(1,file=fname,form='unformatted',status='unknown')
plchun='mph'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) gst
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_RH2'
open(1,file=fname,form='unformatted',status='unknown')
plchun='%'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) srh
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_stp'
open(1,file=fname,form='unformatted',status='unknown')
plchun='F'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) stp
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_TD2'
open(1,file=fname,form='unformatted',status='unknown')
plchun='F'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) std
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_tpw'
open(1,file=fname,form='unformatted',status='unknown')
plchun='in'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) tpw
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_lif'
open(1,file=fname,form='unformatted',status='unknown')
plchun='K'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) lif
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_cld'
open(1,file=fname,form='unformatted',status='unknown')
plchun='%'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) cld
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_frz'
open(1,file=fname,form='unformatted',status='unknown')
plchun='kft'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) frz
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_wb0'
open(1,file=fname,form='unformatted',status='unknown')
plchun='kft'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) wb0
close(1)
fname=trim(outdir)//'/caic_'//afcst//'_pbllaps'
open(1,file=fname,form='unformatted',status='unknown')
plchun='kft'
write(1) vardesc,plchun,ihrip,rhrip,chrip
write(1) pbl
close(1)

if (trim(model) == "nam" .or. trim(model) == "gfs") then
   fname=trim(outdir)//'/caic_'//afcst//'_ter'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='m'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) ter
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_rte'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='mm'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) rto
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_rtc'
   open(1,file=fname,form='unformatted',status='unknown')
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) rtc
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_sfp'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='hPa'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) sfp
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_msl'
   open(1,file=fname,form='unformatted',status='unknown')
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) msl
   close(1)
   ihrip(6)=3
   fname=trim(outdir)//'/caic_'//afcst//'_uuu'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='m/s'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) uuu
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_vvv'
   open(1,file=fname,form='unformatted',status='unknown')
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) vvv
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_www'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun=' '
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) www
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_tmk'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='K'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) tmk
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_ght'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='m'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) ght
   close(1)
   prs=prs/100.
   fname=trim(outdir)//'/caic_'//afcst//'_prs'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='hPa'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) prs
   close(1)
   fname=trim(outdir)//'/caic_'//afcst//'_rhu'
   open(1,file=fname,form='unformatted',status='unknown')
   plchun='%'
   write(1) vardesc,plchun,ihrip,rhrip,chrip
   write(1) rh
   close(1)
endif

deallocate(ingrid,acc,spt,srh,std,tpw,sfp,r01,r01h,r24,r48,rto,s12,lif,stp  &
          ,pbl,cld,suw,svw,spd,msl,rtc)
if (trim(model) == 'nam' .or. trim(model) == "gfs")  &
   deallocate(prs,uuu,vvv,tmk,ght,rh,www,pr)

end

!===============================================================================

subroutine rearrange(nx,ny,nz,in,out)

implicit none

integer :: nx,ny,nz,i,j,k

real :: in(nx,ny,nz),out(ny+1,nx+1,nz)

do k=1,nz
   do j=1,ny
   do i=1,nx
      out(j,i,k)=in(i,j,k)
   enddo
   enddo
   do i=1,ny
      out(i,nx+1,k)=out(i,nx,k)
   enddo
   do j=1,nx+1
      out(ny+1,j,k)=out(ny,j,k)
   enddo
enddo

return
end

!===============================================================================

subroutine jd_to_md(julday,year,month,day)

implicit none

integer :: julday,year,month,day,ndays(12),jd

data ndays/31,28,31,30,31,30,31,31,30,31,30,31/

if (mod(year,4) == 0) ndays(2)=29

jd=julday
month=1
do while (jd > ndays(month) .and. month <= 12)
   jd=jd-ndays(month)
   month=month+1
enddo
day=jd

return
end

!===============================================================================

function relhum(t,mixrat,p)

! Computes relative humidity (%)

implicit none

real :: t       ! Temperature (K)
real :: p       ! Pressure (Pa)
real :: mixrat  ! vapor mixing ratio
real :: mixsat  ! Saturation vapor mix. ratio
real :: relhum  ! RH (%)

relhum=mixrat/mixsat(t,p)*100.
relhum=max(min(100.,relhum),0.1)

return
end function

!===============================================================================

function mixsat(t,p)

! Computes saturation vapor mixing ratio as function of temp (K) and pres (Pa).

implicit none

real :: esat,mixrat,p,satvpr,t,mixsat
real, parameter :: r=287.
real, parameter :: rv=461.5
real, parameter :: e=r/rv

satvpr=esat(t)
mixsat=(e*satvpr)/(p-satvpr)

return
end function

!===============================================================================

function esat(t)

! Computes saturation vapor pressure (Pa) from temperature (K).
! Note: Computed with respect to liquid.

implicit none

real :: esat,t

esat = 611.21 * exp ( (17.502 * (t-273.15)) / (t-32.18) )

return
end function
