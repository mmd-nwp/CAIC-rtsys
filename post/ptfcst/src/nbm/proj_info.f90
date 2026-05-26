module proj_info

type projinfo
   integer :: nx,ny
   real :: latsw,lonsw,latne,lonne,latnw,lonnw,latse,lonse,latcen,loncen  &
          ,dx,stdlon,truelat1,truelat2,hemi,cone,polei,polej,rsw,rebydx,dellon
   character(len=2) :: proj
end type 

end module
