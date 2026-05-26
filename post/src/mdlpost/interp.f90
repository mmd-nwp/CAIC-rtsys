subroutine mdl_hinterp

use mdlgrid
use map_utils

implicit none

integer :: i,j,k
real, allocatable, dimension(:,:) :: ri,rj
logical :: hinterp

! Check to see if horizontal interpolation is necessary.

hinterp=.true.

if (nx == lx .and. ny == ly) then
   if (abs(nlat(1,1)-llat(1,1)) < 0.001 .and. abs(nlon(1,1)-llon(1,1)) < 0.001 .and.  &
       abs(nlat(nx,ny)-llat(nx,ny)) < 0.001 .and. abs(nlon(nx,ny)-llon(nx,ny)) < 0.001) then
      hinterp=.false.
      print*,'Native and LAPS grids are equivalent...horizontal interp is not necessary.'
   endif
endif

if (hinterp) then

! Compute i,j locations in native grid of output grid points.

   allocate(ri(lx,ly),rj(lx,ly))

   do j=1,ly
   do i=1,lx
      call latlon_to_ij(proj,llat(i,j),llon(i,j),ri(i,j),rj(i,j))
      ri(i,j)=max(1.,min(float(nx),ri(i,j)))
      rj(i,j)=max(1.,min(float(ny),rj(i,j)))
   enddo
   enddo

! Horizontally interpolate all grids.

   do k=1,nvar2d+nvar3d*nz
      if (ngrid(1,1,k) < rmsg) then
         if (k <= nvar2d) then
            do j=1,ly
            do i=1,lx
               call gdtost_mdl(ngrid(1,1,k),nx,ny,ri(i,j),rj(i,j),sgrid(i,j,k))
            enddo
            enddo
         else
            do j=1,ly
            do i=1,lx
               call gdtost_mdl(ngrid(1,1,k),nx,ny,ri(i,j),rj(i,j),hgrid(i,j,k-nvar2d))
            enddo
            enddo
         endif
      endif
   enddo

   deallocate(ri,rj)

else

   do k=1,nvar2d+nvar3d*nz
      if (k <= nvar2d) then
         sgrid(:,:,k)=ngrid(:,:,k)
      else
         hgrid(:,:,k-nvar2d)=ngrid(:,:,k)
      endif
   enddo

endif

return
end subroutine

!===============================================================================

subroutine mdl_vinterp

use mdlgrid
use mdlconstants

implicit none

real, allocatable, dimension(:,:,:) :: logp

integer :: i,j,k,kk

real :: pla,dz,plo,phi,slope

! Generate a table of log pressure for future use.

allocate(logp(lx,ly,nz))
logp=alog(hpr)

! Interpolate 3d horizontally interpolated data to isobaric surfaces.
! Assume that height and temp are always available, but check for 
!  all missing in other fields. No need to interpolate if all missing.

!$OMP PARALLEL PRIVATE(I,J,K,KK,PLA,PLO,PHI,SLOPE,DZ)
!$OMP DO SCHEDULE(DYNAMIC)

do k=1,lz
   pla=lprsl(k)

   do j=1,ly
   do i=1,lx
      if (hpr(i,j,1) <= lprs(k)) then
         if (abs(hpr(i,j,1)-lprs(k)) < .01) then
            dz=0.
         else
            dz=htp(i,j,1)/(gor/(pla-alog(hpr(i,j,1)))-lapse*0.5)
         endif
         ht(i,j,k)=hht(i,j,1)-dz
         tp(i,j,k)=htp(i,j,1)+lapse*dz
      elseif (hpr(i,j,nz) >= lprs(k)) then
         tp(i,j,k)=htp(i,j,nz)
         ht(i,j,k)=hht(i,j,nz)+rog*htp(i,j,nz)*alog(hpr(i,j,nz)/lprs(k))
      else
         do kk=1,nz-1
            if (hpr(i,j,kk) >= lprs(k) .and. hpr(i,j,kk+1) <= lprs(k)) then

               plo=logp(i,j,kk)
               phi=logp(i,j,kk+1)
               slope=(plo-pla)/(plo-phi)

               ht(i,j,k)=hht(i,j,kk)-slope*(hht(i,j,kk)-hht(i,j,kk+1))
               tp(i,j,k)=htp(i,j,kk)-slope*(htp(i,j,kk)-htp(i,j,kk+1))
               exit
            endif
         enddo
      endif
   enddo
   enddo
enddo

!$OMP END DO NOWAIT
!$OMP END PARALLEL

if (minval(hmr) < rmsg) call vinterp_field(logp,hmr,mr)
if (minval(huw) < rmsg) call vinterp_field(logp,huw,uw)
if (minval(hvw) < rmsg) call vinterp_field(logp,hvw,vw)
if (minval(hww) < rmsg) call vinterp_field(logp,hww,ww)
!if (minval(hliqmr) < rmsg) call vinterp_field(logp,hliqmr,liqmr)
!if (minval(hicemr) < rmsg) call vinterp_field(logp,hicemr,icemr)
!if (minval(hraimr) < rmsg) call vinterp_field(logp,hraimr,raimr)
!if (minval(hsnomr) < rmsg) call vinterp_field(logp,hsnomr,snomr)
!if (minval(hgramr) < rmsg) call vinterp_field(logp,hgramr,gramr)
if (minval(hstab) < rmsg) call vinterp_field(logp,hstab,stab)

deallocate(logp)

return
end subroutine

!===============================================================================

subroutine vinterp_field(logp,sig,prs)

use mdlgrid

implicit none

integer :: i,j,k,kk
real :: logp(lx,ly,nz),sig(lx,ly,nz),prs(lx,ly,lz),pla,plo,phi,slope

!$OMP PARALLEL PRIVATE(I,J,K,KK,PLA,PLO,PHI,SLOPE)
!$OMP DO SCHEDULE(DYNAMIC)

do k=1,lz
   pla=lprsl(k)
   do j=1,ly
   do i=1,lx
      if (hpr(i,j,1) <= lprs(k)) then
         prs(i,j,k)=sig(i,j,1)
      elseif (hpr(i,j,nz) >= lprs(k)) then
         prs(i,j,k)=sig(i,j,nz)
      else
         do kk=1,nz-1
            if (hpr(i,j,kk) >= lprs(k) .and. hpr(i,j,kk+1) <= lprs(k)) then
               plo=logp(i,j,kk)
               phi=logp(i,j,kk+1)
               slope=(plo-pla)/(plo-phi)
               prs(i,j,k)=sig(i,j,kk)-slope*(sig(i,j,kk)-sig(i,j,kk+1))
               exit
            endif
         enddo
      endif
   enddo
   enddo

enddo

!$OMP END DO NOWAIT
!$OMP END PARALLEL

return
end subroutine

!===============================================================================

subroutine gdtost_mdl(a,ix,iy,stax,stay,staval)

! Subroutine to return stations back-interpolated values(staval)
!    from uniform grid points using overlapping-quadratics.
! Gridded values of input array a dimensioned a(ix,iy),where
!    ix=grid points in x, iy = grid points in y.
! Station location given in terms of grid relative station x (stax)
!    and station column.
! Values greater than 1.0e30 indicate missing data.

dimension a(ix,iy),r(4),scr(4)

iy1=int(stay)-1
iy2=iy1+3
ix1=int(stax)-1
ix2=ix1+3
staval=1e30
fiym2=float(iy1)-1
fixm2=float(ix1)-1
ii=0
do i=ix1,ix2
   ii=ii+1
   if (i >= 1 .and. i <= ix) then
      jj=0
      do j=iy1,iy2
         jj=jj+1
         if (j >= 1 .and. j <= iy) then
            r(jj)=a(i,j)
         else
            r(jj)=1e30
         endif
      enddo
      yy=stay-fiym2
      if (yy == 2.0) then
         scr(ii)=r(2)
      else
         call binom_mdl(1.,2.,3.,4.,r(1),r(2),r(3),r(4),yy,scr(ii))
      endif
   else
      scr(ii)=1e30
   endif
enddo
xx=stax-fixm2
if (xx == 2.0) then
   staval=scr(2)
else
   call binom_mdl(1.,2.,3.,4.,scr(1),scr(2),scr(3),scr(4),xx,staval)
endif

return
end subroutine

!===============================================================================

subroutine binom_mdl(x1,x2,x3,x4,y1,y2,y3,y4,xxx,yyy)

yyy=1e30
if (x2 > 1.e19 .or. x3 > 1.e19 .or.     &
    y2 > 1.e19 .or. y3 > 1.e19) return

wt1=(xxx-x3)/(x2-x3)
wt2=1.0-wt1

if (y4 < 1.e19 .and. x4 < 1.e19) then
   yz22=(xxx-x3)*(xxx-x4)/((x2-x3)*(x2-x4))
   yz22=wt1*(xxx-x4)/(x2-x4)
   yz23=(xxx-x2)*(xxx-x4)/((x3-x2)*(x3-x4))
   yz23=wt2*(xxx-x4)/(x3-x4)
   yz24=(xxx-x2)*(xxx-x3)/((x4-x2)*(x4-x3))
else
   yz22=wt1
   yz23=wt2
   yz24=0.0
endif

if (y1 < 1.e19 .and. x1 < 1.e19) then
   yz11=(xxx-x2)*(xxx-x3)/((x1-x2)*(x1-x3))
   yz12=(xxx-x1)*(xxx-x3)/((x2-x1)*(x2-x3))
   yz12=wt1*(xxx-x1)/(x2-x1)
   yz13=(xxx-x1)*(xxx-x2)/((x3-x1)*(x3-x2))
   yz13=wt2*(xxx-x1)/(x3-x1)
else
   yz11=0.0
   yz12=wt1
   yz13=wt2
endif

if (yz11 == 0. .and. yz24 == 0.) then
   yyy=wt1*y2+wt2*y3
else
   yyy=wt1*(yz11*y1+yz12*y2+yz13*y3)+wt2*(yz22*y2+yz23*y3+yz24*y4)
endif

return
end subroutine
