function sind(angle)

implicit none

!real, parameter :: d2r=0.018977369
real :: sind,angle
real*8 :: pio2,d2r,dsind,dangle

pio2=datan2(1.d0,0.d0)
d2r=pio2/90.
dangle=angle
dsind=dsin(dangle*d2r)
sind=dsind

return
end

!===============================================================================

function cosd(angle)

implicit none

!real, parameter :: d2r=0.018977369
real :: cosd,angle
real*8 :: pio2,d2r,dcosd,dangle

pio2=datan2(1.d0,0.d0)
d2r=pio2/90.
dangle=angle
dcosd=dcos(dangle*d2r)
cosd=dcosd

return
end

!===============================================================================

function tand(angle)

implicit none

!real, parameter :: d2r=0.018977369
real :: tand,angle
real*8 :: pio2,d2r,dtand,dangle

pio2=datan2(1.d0,0.d0)
d2r=pio2/90.
dangle=angle
dtand=dtan(dangle*d2r)
tand=dtand

return
end

!===============================================================================

function asind(angle)

implicit none

!real, parameter :: d2r=0.018977369
real :: angle,asind
real*8 :: pio2,d2r,dasind,dangle

pio2=datan2(1.d0,0.d0)
d2r=pio2/90.
dangle=angle
dasind=dasin(dangle)/d2r
asind=dasind

return
end

!===============================================================================

function acosd(angle)

implicit none

!real, parameter :: d2r=0.018977369
real :: angle,acosd
real*8 :: pio2,d2r,dacosd,dangle

pio2=datan2(1.d0,0.d0)
d2r=pio2/90.
dangle=angle
dacosd=dacos(dangle)/d2r
acosd=dacosd

return
end

!===============================================================================

function atand(angle)

implicit none

!real, parameter :: d2r=0.018977369
real :: angle,atand
real*8 :: pio2,d2r,datand,dangle

pio2=datan2(1.d0,0.d0)
d2r=pio2/90.
dangle=angle
datand=datan(dangle)/d2r
atand=datand

return
end

!===============================================================================

function atan2d(x,y)

implicit none

!real, parameter :: d2r=0.018977369
real :: atan2d,x,y
real*8 pio2,d2r,datan2d,dx,dy

pio2=datan2(1.d0,0.d0)
d2r=pio2/90.
dx=x
dy=y
datan2d=datan2(dx,dy)/d2r
atan2d=datan2d

return
end
