subroutine stn_read(loc)

! Read point forecast and time-height information.
!   If loc is set to master, then read from master file.
!   If loc is set to model, then read from model file.

use mdlgrid

implicit none

integer :: iht,mht,istat,n
character(len=256) :: infile
character(len=*) :: loc
character(len=1) :: agrid

! Set point forecast file name.

write(agrid,'(i1)') fcstgrid
if (trim(loc) == 'master') then
   infile=trim(pffile)
elseif (trim(loc) == 'model') then
   infile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
         //'/ptfcst/ptfcst.txt.g'//agrid
else
   print*,'Station file not read.'
   npf=0
   nth=0
   nsn=0
   return
endif

! Determine number of point forecasts.

npf=0
open(2,file=trim(infile),status='old',form='formatted',iostat=istat)

if (.not. istat) then
   do
      read(2,900,iostat=istat)
      if (istat) exit
      npf=npf+1
   enddo
endif

! Allocate and read point forecast static information.

if (npf > 0) then
   if (allocated(pfname)) deallocate (pfname,pflat,pflon,pffulname  &
                                     ,pfht,pfi,pfj)
   allocate(pfname(npf),pflat(npf),pflon(npf),pffulname(npf)  &
           ,pfht(npf),pfi(npf),pfj(npf))
   rewind(2)
endif

if (loc == 'master') then
   do n=1,npf
      read(2,900,iostat=istat) pfname(n),pflat(n),pflon(n),iht,pffulname(n)
      pfht(n)=float(iht)
   enddo
else
   do n=1,npf
      read(2,901) pfname(n),pflat(n),pflon(n)  &
                 ,iht,mht,pfi(n),pfj(n)        &
                 ,pffulname(n)
      pfht(n)=float(iht)
   enddo
endif

close(2)
write(*,910) npf,trim(loc)

! Set time-height file name.

if (trim(loc) == 'master') then
   infile=trim(thfile)
elseif (trim(loc) == 'model') then
   infile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
         //'/timeht/timeht.txt.g'//agrid
endif

! Determine number of time-height forecasts.

nth=0
open(2,file=trim(infile),status='old',form='formatted',iostat=istat)

if (.not. istat) then
   do
      read(2,900,iostat=istat)
      if (istat) exit
      nth=nth+1
   enddo
endif

! Allocate and read time-height forecast static information.

if (nth > 0) then
   if (allocated(thname)) deallocate (thname,thlat,thlon,thfulname  &
                                     ,thht,thi,thj)
   allocate(thname(nth),thlat(nth),thlon(nth),thfulname(nth)  &
           ,thht(nth),thi(nth),thj(nth))
   rewind(2)
endif

if (loc == 'master') then
   do n=1,nth
      read(2,900,iostat=istat) thname(n),thlat(n),thlon(n),iht,thfulname(n)
      thht(n)=float(iht)
   enddo
else
   do n=1,nth
      read(2,901) thname(n),thlat(n),thlon(n)  &
                 ,iht,mht,thi(n),thj(n)        &
                 ,thfulname(n)
      thht(n)=float(iht)
   enddo
endif

close(2)
write(*,911) nth,trim(loc)

! Set sounding file name.

if (trim(loc) == 'master') then
   infile=trim(snfile)
elseif (trim(loc) == 'model') then
   infile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
         //'/sndg/sndg.txt.g'//agrid
endif

! Determine number of sounding forecasts.

nsn=0
open(2,file=trim(infile),status='old',form='formatted',iostat=istat)

if (.not. istat) then
   do
      read(2,900,iostat=istat)
      if (istat) exit
      nsn=nsn+1
   enddo
endif

! Allocate and read sounding forecast static information.

if (nsn > 0) then
   if (allocated(snname)) deallocate (snname,snlat,snlon,snfulname  &
                                     ,sni,snj)
   allocate(snname(nsn),snlat(nsn),snlon(nsn),snfulname(nsn)  &
           ,sni(nsn),snj(nsn))
   rewind(2)
endif

if (loc == 'master') then
   do n=1,nsn
      read(2,900,iostat=istat) snname(n),snlat(n),snlon(n),iht,snfulname(n)
   enddo
else
   do n=1,nsn
      read(2,901) snname(n),snlat(n),snlon(n)  &
                 ,iht,mht,sni(n),snj(n)        &
                 ,snfulname(n)
   enddo
endif

close(2)
write(*,912) nsn,trim(loc)

900 format(a10,1x,f8.4,1x,f9.4,1x,i4,1x,a30)
901 format(a10,1x,f8.4,1x,f9.4,1x,i4,1x,i4,1x,f6.2,1x,f6.2,1x,a30)
910 format(i7,' stations read from ',a,' point forecast file.')
911 format(i7,' stations read from ',a,' time-height file.')
912 format(i7,' stations read from ',a,' sounding file.')

return
end subroutine

!===============================================================================

subroutine stn_check(nmdlgrid,mdlres,lapsdir)

! Eliminate stations outside of model domains.
! Write reduced station list to model directory.

use mdlgrid

implicit none

integer :: nmdlgrid,g,n
integer, dimension(nmdlgrid) :: ct
real :: mht,ri,rj
type(proj_info) :: lproj
character(len=256) :: stnfile
character(len=256), dimension(nmdlgrid) :: lapsdir
character(len=32), dimension(nmdlgrid) :: mdlres
character(len=3) :: agrid
character(len=2) :: agrd
logical :: is_open

! Point forecast.

stnfile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
      //'/ptfcst/ptfcst.txt'

ct=0
do n=1,npf

   do g=nmdlgrid,1,-1

      fcstgrid=g
      res=mdlres(g)
      lapsdataroot=lapsdir(g)
      call get_laps_static

      select case(trim(projection))
         case('LAMBERT CONFORMAL')
            call map_set(proj_lc,llat(1,1),llon(1,1),grid_spacing  &
                        ,stdlon,truelat1,truelat2,lx,ly,lproj)
         case('POLAR STEREOGRAPHIC')
            call map_set(proj_ps,llat(1,1),llon(1,1),grid_spacing  &
                        ,stdlon,truelat1,truelat2,lx,ly,lproj)
      end select

      write(agrd,'(i2.2)') g
      write(agrid,'(''.g'',i1)') g
      funit=11+g

      call latlon_to_ij(lproj,pflat(n),pflon(n),ri,rj)
      if (ri >= 1. .and. ri <= lx .and.  &
          rj >= 1. .and. rj <= ly) then
         ct(g)=ct(g)+1
         mht=-999.  ! This will be filled later.

         inquire(file=trim(stnfile),opened=is_open)
         if (.not. is_open) open(11,file=trim(stnfile),status='replace',form='formatted')
         inquire(file=trim(stnfile)//agrid,opened=is_open)
         if (.not. is_open) open(funit,file=trim(stnfile)//agrid,status='replace',form='formatted')
         write(11,900) agrd,pfname(n),pflat(n),pflon(n),pffulname(n)
         write(funit,901) pfname(n),pflat(n),pflon(n)    &
                         ,nint(pfht(n)),nint(mht),ri,rj  &
                         ,pffulname(n)
         exit
      endif

   enddo
enddo

inquire(file=trim(stnfile),opened=is_open)
if (is_open) close(11)
do g=1,nmdlgrid
   write(agrid,'(''.g'',i1)') g
   funit=11+g
   inquire(file=trim(stnfile)//agrid,opened=is_open)
   if (is_open) close(funit)
   write(*,902) ct(g),g
enddo

! Time-height.

stnfile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
      //'/timeht/timeht.txt'

ct=0
do n=1,nth

   do g=nmdlgrid,1,-1

      fcstgrid=g
      res=mdlres(g)
      lapsdataroot=lapsdir(g)
      call get_laps_static

      select case(trim(projection))
         case('LAMBERT CONFORMAL')
            call map_set(proj_lc,llat(1,1),llon(1,1),grid_spacing  &
                        ,stdlon,truelat1,truelat2,lx,ly,lproj)
         case('POLAR STEREOGRAPHIC')
            call map_set(proj_ps,llat(1,1),llon(1,1),grid_spacing  &
                        ,stdlon,truelat1,truelat2,lx,ly,lproj)
      end select

      write(agrd,'(i2.2)') g
      write(agrid,'(''.g'',i1)') g
      funit=11+g

      call latlon_to_ij(lproj,thlat(n),thlon(n),ri,rj)
      if (ri >= 1. .and. ri <= lx .and.  &
          rj >= 1. .and. rj <= ly) then
         ct(g)=ct(g)+1
         mht=-999.
         inquire(file=trim(stnfile),opened=is_open)
         if (.not. is_open) open(11,file=trim(stnfile),status='replace',form='formatted')
         inquire(file=trim(stnfile)//agrid,opened=is_open)
         if (.not. is_open) open(funit,file=trim(stnfile)//agrid,status='replace',form='formatted')
         write(11,900) agrd,thname(n),thlat(n),thlon(n),thfulname(n)
         write(funit,901) thname(n),thlat(n),thlon(n)    &
                         ,nint(thht(n)),nint(mht),ri,rj  &
                         ,thfulname(n)
         exit
      endif

   enddo
enddo

inquire(file=trim(stnfile),opened=is_open)
if (is_open) close(11)
do g=1,nmdlgrid
   write(agrid,'(''.g'',i1)') g
   funit=11+g
   inquire(file=trim(stnfile)//agrid,opened=is_open)
   if (is_open) close(funit)
   write(*,902) ct(g),g
enddo

! Sounding.

stnfile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
      //'/sndg/sndg.txt'

ct=0
do n=1,nsn

   do g=nmdlgrid,1,-1

      fcstgrid=g
      res=mdlres(g)
      lapsdataroot=lapsdir(g)
      call get_laps_static

      select case(trim(projection))
         case('LAMBERT CONFORMAL')
            call map_set(proj_lc,llat(1,1),llon(1,1),grid_spacing  &
                        ,stdlon,truelat1,truelat2,lx,ly,lproj)
         case('POLAR STEREOGRAPHIC')
            call map_set(proj_ps,llat(1,1),llon(1,1),grid_spacing  &
                        ,stdlon,truelat1,truelat2,lx,ly,lproj)
      end select

      write(agrd,'(i2.2)') g
      write(agrid,'(''.g'',i1)') g
      funit=11+g

      call latlon_to_ij(lproj,snlat(n),snlon(n),ri,rj)
      if (ri >= 1. .and. ri <= lx .and.  &
          rj >= 1. .and. rj <= ly) then
         ct(g)=ct(g)+1
         mht=-999.
         inquire(file=trim(stnfile),opened=is_open)
         if (.not. is_open) open(11,file=trim(stnfile),status='replace',form='formatted')
         inquire(file=trim(stnfile)//agrid,opened=is_open)
         if (.not. is_open) open(funit,file=trim(stnfile)//agrid,status='replace',form='formatted')
         write(11,900) agrd,snname(n),snlat(n),snlon(n),snfulname(n)
         write(funit,901) snname(n),snlat(n),snlon(n)   &
                         ,nint(mht),nint(mht),ri,rj  &
                         ,snfulname(n)
         exit
      endif

   enddo
enddo

inquire(file=trim(stnfile),opened=is_open)
if (is_open) close(11)
do g=1,nmdlgrid
   write(agrid,'(''.g'',i1)') g
   funit=11+g
   inquire(file=trim(stnfile)//agrid,opened=is_open)
   if (is_open) close(funit)
   write(*,902) ct(g),g
enddo

900 format(a2,1x,a10,1x,f8.4,1x,f9.4,1x,a30)
901 format(a10,1x,f8.4,1x,f9.4,1x,i4,1x,i4,1x,f6.2,1x,f6.2,1x,a30)
902 format(i7,' stations written to model point forecast file for model grid ',i1,'.')
903 format(i7,' stations written to model time-height file for model grid ',i1,'.')
904 format(i7,' stations written to model sounding file for model grid ',i1,'.')

return
end subroutine

!===============================================================================

subroutine stn_height

use mdlgrid

implicit none

type(proj_info) :: lproj
real :: mht,ri,rj
integer :: grid,n
character(len=256) :: stnfile
character(len=3) :: agrid
logical :: is_open

select case(trim(projection))
   case('LAMBERT CONFORMAL')
      call map_set(proj_lc,llat(1,1),llon(1,1),grid_spacing  &
                  ,stdlon,truelat1,truelat2,lx,ly,lproj)
   case('POLAR STEREOGRAPHIC')
      call map_set(proj_ps,llat(1,1),llon(1,1),grid_spacing  &
                  ,stdlon,truelat1,truelat2,lx,ly,lproj)
end select

write(agrid,'(''.g'',i1)') fcstgrid

! Point forecast.

stnfile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
      //'/ptfcst/ptfcst.txt'
print*,"Updating stn ht: ",trim(stnfile)//agrid

if (npf > 0) then
   open(11,file=trim(stnfile),status='old',form='formatted')
   do n=1,npf
      read(11,900) grid
      if (grid == fcstgrid) then
         inquire(file=trim(stnfile)//agrid,opened=is_open)
         if (.not. is_open) open(12,file=trim(stnfile)//agrid,status='replace',form='formatted')
         call latlon_to_ij(lproj,pflat(n),pflon(n),ri,rj)
         call gdtost_mdl(htsfc,lx,ly,ri,rj,mht)
         write(12,901) pfname(n),pflat(n),pflon(n)    &
                      ,nint(pfht(n)),nint(mht),ri,rj  &
                      ,pffulname(n)
      endif
   enddo
   close(11)
   inquire(file=trim(stnfile)//agrid,opened=is_open)
   if (is_open) close(12)
endif

! Time height.

stnfile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
      //'/timeht/timeht.txt'
print*,"Updating stn ht: ",trim(stnfile)//agrid

if (nth > 0) then
   open(11,file=trim(stnfile),status='old',form='formatted')
   do n=1,nth
      read(11,900) grid
      if (grid == fcstgrid) then
         inquire(file=trim(stnfile)//agrid,opened=is_open)
         if (.not. is_open) open(12,file=trim(stnfile)//agrid,status='replace',form='formatted')
         call latlon_to_ij(lproj,thlat(n),thlon(n),ri,rj)
         call gdtost_mdl(htsfc,lx,ly,ri,rj,mht)
         write(12,901) thname(n),thlat(n),thlon(n)    &
                      ,nint(thht(n)),nint(mht),ri,rj  &
                      ,thfulname(n)
      endif
   enddo
   close(11)
   inquire(file=trim(stnfile)//agrid,opened=is_open)
   if (is_open) close(12)
endif

! Sounding.

stnfile='/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate &
      //'/sndg/sndg.txt'
print*,"Updating stn ht: ",trim(stnfile)//agrid

if (nsn > 0) then
   open(11,file=trim(stnfile),status='old',form='formatted')
   do n=1,nsn
      read(11,900) grid
      if (grid == fcstgrid) then
         inquire(file=trim(stnfile)//agrid,opened=is_open)
         if (.not. is_open) open(12,file=trim(stnfile)//agrid,status='replace',form='formatted')
         call latlon_to_ij(lproj,snlat(n),snlon(n),ri,rj)
         call gdtost_mdl(htsfc,lx,ly,ri,rj,mht)
         write(12,901) snname(n),snlat(n),snlon(n)    &
                      ,nint(mht),nint(mht),ri,rj  &
                      ,snfulname(n)
      endif
   enddo
   close(11)
   inquire(file=trim(stnfile)//agrid,opened=is_open)
   if (is_open) close(12)
endif

900 format(i2)
901 format(a10,1x,f8.4,1x,f9.4,1x,i4,1x,i4,1x,f6.2,1x,f6.2,1x,a30)

return
end subroutine

!===============================================================================

subroutine point_forecast

use mdlgrid

implicit none

integer :: i4time,k700,k,n
real :: tpv,tdv
real, external :: twk
character(len=9) :: vdate

k700=0
do k=1,lz
   if (lprs(k) == 70000.) k700=k
enddo
if (k700 == 0) then
   print*,'700mb level is not defined...Quit...'
   stop
endif

do n=1,npf
   call gdtost_mdl(slp  ,lx,ly,pfi(n),pfj(n),pfmsl(n))
   call gdtost_mdl(prsfc,lx,ly,pfi(n),pfj(n),pfspr(n))
   call gdtost_mdl(tplow,lx,ly,pfi(n),pfj(n),pfltp(n))
   call gdtost_mdl(tdsfc,lx,ly,pfi(n),pfj(n),pfstd(n))
   call gdtost_mdl(uwlow,lx,ly,pfi(n),pfj(n),pfluw(n))
   call gdtost_mdl(vwlow,lx,ly,pfi(n),pfj(n),pflvw(n))
   call gdtost_mdl(wwsfc,lx,ly,pfi(n),pfj(n),pfsww(n))
   call gdtost_mdl(swin ,lx,ly,pfi(n),pfj(n),pfswr(n))
   call gdtost_mdl(lwin ,lx,ly,pfi(n),pfj(n),pflwr(n))
   call gdtost_mdl(tpshl,lx,ly,pfi(n),pfj(n),pfstp(n))
   call gdtost_mdl(uwshl,lx,ly,pfi(n),pfj(n),pfsuw(n))
   call gdtost_mdl(vwshl,lx,ly,pfi(n),pfj(n),pfsvw(n))
   call gdtost_mdl(tpgnd,lx,ly,pfi(n),pfj(n),pfsgt(n))
   call gdtost_mdl(tpsl1,lx,ly,pfi(n),pfj(n),pfslt(n))
   call gdtost_mdl(r01  ,lx,ly,pfi(n),pfj(n),pfrto(n))
   call gdtost_mdl(c01  ,lx,ly,pfi(n),pfj(n),pfrtc(n))
   call gdtost_mdl(acc  ,lx,ly,pfi(n),pfj(n),pfsto(n))
   call gdtost_mdl(pbl  ,lx,ly,pfi(n),pfj(n),pfpbl(n))
   call gdtost_mdl(rhsfc,lx,ly,pfi(n),pfj(n),pfsrh(n))
   call gdtost_mdl(m5z  ,lx,ly,pfi(n),pfj(n),pfm5z(n))
   call gdtost_mdl(tp(1,1,k700),lx,ly,pfi(n),pfj(n),pf7tp(n))
   call gdtost_mdl(gust ,lx,ly,pfi(n),pfj(n),pfgst(n))
   if (pfspr(n) > 70500.) then
      call gdtost_mdl(liqmr(1,1,k700),lx,ly,pfi(n),pfj(n),pf7cw(n))
      call gdtost_mdl(   uw(1,1,k700),lx,ly,pfi(n),pfj(n),pf7uw(n))
      call gdtost_mdl(   vw(1,1,k700),lx,ly,pfi(n),pfj(n),pf7vw(n))
   else
      call gdtost_mdl(hliqmr,lx,ly,pfi(n),pfj(n),pf7cw(n))
      pf7uw(n)=pfsuw(n)
      pf7vw(n)=pfsvw(n)
   endif
   pfcei(n)=ceil(nint(pfi(n)),nint(pfj(n)))
   pfspt(n)=spt(nint(pfi(n)),nint(pfj(n)))
   pfcld(n)=cldamt(nint(pfi(n)),nint(pfj(n)))
   pfstd(n)=min(pfstp(n),pfstd(n))
   pfwtb(n)=twk(pfstp(n),pfstd(n),pfspr(n))
   if (pfwtb(n) > pfstp(n) .or. pfwtb(n) < pfstd(n)) pfwtb(n)=(pfstp(n)+pfstd(n))*0.5
enddo

! Compute surface visibility (km) from relative humidity and temp/dewpoint

do n=1,npf
   if (pfsgt(n) > pfltp(n)) then
      tpv=pfstp(n)
   else
      tpv=pfltp(n)
   endif
   tdv=min(tpv,pfstd(n))
   pfvis(n)=6000.0*(tpv-tdv)/(pfsrh(n)**1.75)
enddo

! Calculate max possible solar at each station.

call adate_to_i4time(adate,i4time)
i4time=i4time+fcsttime
call i4time_to_adate(i4time,vdate)
call solmax(vdate,npf,pflat,pflon,pfsmx)

return
end subroutine

!===============================================================================

subroutine time_height

use mdlgrid

implicit none

integer :: k,n

do n=1,nth
   call gdtost_mdl(prsfc,lx,ly,thi(n),thj(n),thspr(n))
   do k=1,lz
      call gdtost_mdl(tp(1,1,k),lx,ly,thi(n),thj(n),thtp(n,k))
      call gdtost_mdl(mr(1,1,k),lx,ly,thi(n),thj(n),thmr(n,k))
      call gdtost_mdl(uw(1,1,k),lx,ly,thi(n),thj(n),thuw(n,k))
      call gdtost_mdl(vw(1,1,k),lx,ly,thi(n),thj(n),thvw(n,k))
      call gdtost_mdl(ww(1,1,k),lx,ly,thi(n),thj(n),thww(n,k))
   enddo
enddo

! Compute theta-e, convert mr to rh, convert temp from K to C,
!   and convert sfc pres to mb.

call therm(thtp,thmr,lprs,nth,lz,thte)
thspr=thspr/100.

return
end subroutine

!===============================================================================

subroutine sndg

use mdlgrid
use mdlconstants

implicit none

integer :: k,n

real :: mrl,rhl,uwl,vwl,dewpt,relhum

do n=1,nsn
   call gdtost_mdl(htsfc,lx,ly,sni(n),snj(n),snht(n,1))
   call gdtost_mdl(prsfc,lx,ly,sni(n),snj(n),snpr(n,1))
   call gdtost_mdl(tpshl,lx,ly,sni(n),snj(n),sntp(n,1))
   call gdtost_mdl(tdsfc,lx,ly,sni(n),snj(n),sntd(n,1))
   call gdtost_mdl(uwshl,lx,ly,sni(n),snj(n),uwl)
   call gdtost_mdl(vwshl,lx,ly,sni(n),snj(n),vwl)
   snsp(n,1)=sqrt(uwl**2+vwl**2)
   sndi(n,1)=270.-(atan2(vwl,uwl)*rad2deg)
   do k=1,nz
      call gdtost_mdl(hht(1,1,k),lx,ly,sni(n),snj(n),snht(n,k+1))
      call gdtost_mdl(hpr(1,1,k),lx,ly,sni(n),snj(n),snpr(n,k+1))
      call gdtost_mdl(htp(1,1,k),lx,ly,sni(n),snj(n),sntp(n,k+1))
      call gdtost_mdl(hmr(1,1,k),lx,ly,sni(n),snj(n),mrl)
      rhl=relhum(sntp(n,k+1),mrl,snpr(n,k+1))
      sntd(n,k+1)=dewpt(sntp(n,k+1),rhl)
      call gdtost_mdl(huw(1,1,k),lx,ly,sni(n),snj(n),uwl)
      call gdtost_mdl(hvw(1,1,k),lx,ly,sni(n),snj(n),vwl)
      snsp(n,k+1)=sqrt(uwl**2+vwl**2)
      sndi(n,k+1)=270.-(atan2(vwl,uwl)*rad2deg)
   enddo
enddo

! Convert pres to mb, temp/dewpt to C, and speed to knots.

snpr=snpr/100.
sntp=sntp-273.15
sntd=sntd-273.15
snsp=snsp*1.94384
where (sndi >= 360.) sndi=sndi-360.

return
end subroutine
