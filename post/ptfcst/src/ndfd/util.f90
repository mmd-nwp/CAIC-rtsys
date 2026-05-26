subroutine adate_to_i4time(adate,i4time)

implicit none

integer :: i4time,iyear,iday,ihour,imin,lp

character(len=9) :: adate

read(adate(1:2),'(i2)') iyear
read(adate(3:5),'(i3)') iday
read(adate(6:7),'(i2)') ihour
read(adate(8:9),'(i2)') imin

! Valid for years 1970-2070.

if (iyear < 70) iyear = iyear + 100

lp = (iyear + 1 - 70) / 4

i4time = (iyear-70)  * 31536000  &
       + (iday-1+lp) * 86400     &
       + ihour       * 3600      &
       + imin        * 60

return
end

!===============================================================================

subroutine i4time_to_adate(i4time,adate)

implicit none

integer :: i4time,ltime,iyear,iday,ihour,imin,leap

character(len=9) :: adate

ltime=i4time
iyear=70
leap=0
do while (ltime >= 31536000+leap)
   iyear=iyear+1
   ltime=ltime-31536000-leap
   if (mod(iyear,4) == 0) then
      leap=86400
   else
      leap=0
   endif
enddo

iday=1
do while (ltime >= 86400)
   iday=iday+1
   ltime=ltime-86400
enddo

ihour=0
do while (ltime >= 3600)
   ihour=ihour+1
   ltime=ltime-3600
enddo

imin=0
do while (ltime >= 60)
   imin=imin+1
   ltime=ltime-60
enddo

iyear=mod(iyear,100)
write(adate,'(i2.2,i3.3,2i2.2)') iyear,iday,ihour,imin

return
end
