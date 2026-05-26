program csvfcst

implicit none

include 'netcdf.inc'

integer :: icode,nid,ncid,nx,ny,nfcst,inc,f,i,j,ct,l,ll
integer, allocatable, dimension(:,:,:) :: tp,td,rh,spd,dir,gst  &
                                         ,rnto,snto,cld

real, allocatable, dimension(:,:) :: fld1,fld2
real :: pi,rad2deg

character(len=5610) :: fcst
character(len=255)  :: lapsdataroot,cdfroot,cdffile
character(len=9)    :: adate,model
character(len=5)    :: afcst

logical :: there

! Define constants.

pi=atan2(1.,1.)*4.;
rad2deg=180./pi

read(5,'(a)') model
read(5,'(a)') lapsdataroot
read(5,'(a)') adate
read(5,*) nfcst,inc

cdfroot = trim(lapsdataroot)//'/lapsprd/fsf/wrf/'//adate

! Loop through each forecast and read netcdf data.

do f=1,nfcst
   write(afcst,'(i3.3)') (f-1)*inc
   afcst=afcst(1:3)//'00'
   cdffile=trim(cdfroot)//'_'//afcst//'.fsf'
   inquire(file=trim(cdffile),exist=there)
   if (there) then
      print*,trim(cdffile)
      icode=nf_open(trim(cdffile),nf_nowrite,ncid)
      if (ncid <= 0) then
         print *,'Could not open file: ',trim(cdffile)
         stop
      endif
      if (f == 1) then
         icode=nf_inq_dimid(ncid,'x',nid)
         icode=nf_inq_dimlen(ncid,nid,nx)
         icode=nf_inq_dimid(ncid,'y',nid)
         icode=nf_inq_dimlen(ncid,nid,ny)
         allocate(fld1(nx,ny),fld2(nx,ny)                               &
                 ,tp(nx,ny,nfcst),td(nx,ny,nfcst),rh(nx,ny,nfcst)       &
                 ,spd(nx,ny,nfcst),dir(nx,ny,nfcst),gst(nx,ny,nfcst)    &
                 ,rnto(nx,ny,nfcst),snto(nx,ny,nfcst),cld(nx,ny,nfcst)  &
                 )
      endif
      icode=nf_inq_varid(ncid,'tps',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      fld1=(fld1-273.15)*1.8+32.
      tp(:,:,f)=nint(fld1*10);
      icode=nf_inq_varid(ncid,'std',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      fld1=(fld1-273.15)*1.8+32.
      td(:,:,f)=nint(fld1*10);
      icode=nf_inq_varid(ncid,'srh',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      rh(:,:,f)=nint(fld1*10);
      icode=nf_inq_varid(ncid,'uws',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      icode=nf_inq_varid(ncid,'vws',nid)
      icode=nf_get_var_real(ncid,nid,fld2)
      spd(:,:,f)=nint(sqrt(fld1**2+fld2**2)*22.3694)
      dir(:,:,f)=nint(270.-(atan2(fld2,fld1)*rad2deg))
      icode=nf_inq_varid(ncid,'gst',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      gst(:,:,f)=nint(fld1*22.3694)
      icode=nf_inq_varid(ncid,'rto',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      rnto(:,:,f)=nint(fld1/0.254)
      icode=nf_inq_varid(ncid,'acc',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      snto(:,:,f)=nint(fld1/0.254)
      icode=nf_inq_varid(ncid,'cld',nid)
      icode=nf_get_var_real(ncid,nid,fld1)
      cld(:,:,f)=nint(fld1)
   endif
enddo
where (td > tp) td=tp
where (dir >= 360) dir=dir-360

open(1,file=trim(model)//'-'//adate//'.csv',status='new',form='formatted',access='stream')
do j=1,ny
do i=1,nx
   write(fcst,'(765(i5,'',''))') &
       (tp(i,j,f),f=1,nfcst)     &
      ,(td(i,j,f),f=1,nfcst)     &
      ,(rh(i,j,f),f=1,nfcst)     &
      ,(spd(i,j,f),f=1,nfcst)    &
      ,(dir(i,j,f),f=1,nfcst)    &
      ,(gst(i,j,f),f=1,nfcst)    &
      ,(rnto(i,j,f),f=1,nfcst)   &
      ,(snto(i,j,f),f=1,nfcst)   &
      ,(cld(i,j,f),f=1,nfcst)   
   write(1,'(a)') fcst
enddo
print*,j
enddo
close(1)
deallocate(fld1,tp,td,rh,spd,dir,gst,rnto,snto,cld)

end
