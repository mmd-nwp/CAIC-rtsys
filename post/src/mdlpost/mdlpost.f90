program mdlpost

! Perform model post-processing.

use mdlgrid
use grib

implicit none

integer :: g,i,k,n,chr  &
          ,nmdlgrid     &  ! No. of model grids
          ,sfcst        &  ! Start forecast (hours)
          ,nfcst        &  ! Number of forecasts
          ,hour         &
          ,dbfcst
character(len=256), allocatable, dimension(:) :: lapsdir
character(len=256), parameter :: ptfcstdir='/home/caic/caic/rtsys/post/ptfcst/bin'
character(len=32), allocatable, dimension(:) :: mdlres
character(len=5) :: afcst
logical :: ex,stnread=.true.

! Get model post-processing information.

read(5,'(a)') domain
read(5,*) nmdlgrid
allocate(mdlres(nmdlgrid),lapsdir(nmdlgrid))
do g=1,nmdlgrid
   read(5,'(a)') mdlres(g)
   read(5,'(a)') lapsdir(g)
enddo
read(5,'(a)') model
read(5,'(a)') adate
read(5,*) sfcst,nfcst,fcstinc
read(5,'(a)') pffile
read(5,'(a)') thfile
read(5,'(a)') snfile
read(5,'(a)') db_script
read(5,'(a)') image_script
read(5,*) grib_inc
read(5,*) delay  ! Delay in seconds before reading wrf file.
read(5,*) dbfcst

call adate9_to_adate18(adate,dbtime)
fcstinc=fcstinc*3600

! Convert model to lower case and check for valid model type.

do i=1,len_trim(model)
   chr=ichar(model(i:i))
   if (chr > 64 .and. chr < 91) model(i:i)=char(chr+32)
enddo

if (trim(model) /= 'wrf' .and. trim(model) /= 'nam' .and.  &
    trim(model) /= 'gfs') then
   print *, 'Unrecognized model type: ',trim(model)
   print *, '   wrf, nam, and gfs are supported.'
   stop
endif

! Fill image generation host list.

res=mdlres(1)
if (image_script(1:1) /= ' ') call image_host_list

! Loop through requested number of forecasts.

fcsttime=(sfcst-1)*fcstinc
do n=sfcst,sfcst+nfcst-1
   fcsttime=fcsttime+fcstinc

! Post-process for each model grid.

   do g=1,nmdlgrid

      fcstgrid=g
      res=mdlres(g)
      lapsdataroot=lapsdir(g)

      print*,' '
      print*,'LAPS forecast model postprocessing for ',trim(model),' run: '  &
            ,'/model/'//trim(domain)//'/'//trim(res)//'/'//trim(model)//'/'//adate
!     print*,' '

! Create output file names and check if files already exist.

      write(afcst(1:3),'(i3.3)') fcsttime/3600
      write(afcst(4:5),'(i2.2)') mod(fcsttime,3600)/60
      fsfname=trim(lapsdataroot)//'/lapsprd/fsf/'//trim(model)//'/'//adate//'_'//afcst//'.fsf'
      fuaname=trim(lapsdataroot)//'/lapsprd/fua/'//trim(model)//'/'//adate//'_'//afcst//'.fua'
      xsecname=trim(lapsdataroot)//'/lapsprd/xsec/'//trim(model)//'/'//adate//'.xsec'
      inquire(file=trim(fsfname),exist=ex)
      if (ex) then
         print*,'Output file exists: ',trim(fsfname)
         cycle
      endif

! Create point forecast location files for each grid.

      if (n == 0 .and. g == 1) then
         call stn_read('master')
         if (npf+nth+nsn > 0) call stn_check(nmdlgrid,mdlres,lapsdir)
         fcstgrid=g
         res=mdlres(g)
         lapsdataroot=lapsdir(g)
      endif

! Obtain output laps isobaric grid dimensions, pressure levels, and lat/lons.

      call get_laps_static

! Allocate and fill native model grid.
!  If NCEP grid, then only fill when grid = 1.

      if (trim(model) /= 'nam' .or. g == 1) then
         call get_native_dims
         call alloc_native_grid
         call fill_native_grid
      endif
      if (verbose) call mdl_diag('native')

! Allocate and horizontally interpolate data.

      call alloc_surface_grid
      call alloc_hinterp_grid
      call mdl_hinterp
      if (verbose) call mdl_diag('horizontal')

! Set to zero any missing microphysics fields.

      if (minval(hliqmr) == rmsg) hliqmr=0.
      if (minval(hicemr) == rmsg) hicemr=0.
      if (minval(hraimr) == rmsg) hraimr=0.
      if (minval(hsnomr) == rmsg) hsnomr=0.
      if (minval(hgramr) == rmsg) hgramr=0.

! Allocate and vertically interpolate data to isobaric grid.

      call alloc_isobaric_grid
      call mdl_vinterp
      if (verbose) call mdl_diag('vertical')

! Generate derived fields.

      if (verbose) print*,'Begin generation of derived fields.'
      call mdl_derived

! Generate grib files.

!     if (grib_inc > 0 .and. mod(n,grib_inc) == 0) then
!        call make_igds(proj,igds)
!        gribname='/ftp/fxnet/'//adate//'_'//afcst//'.grib'
!        if (verbose) print*,'Grib sfc file --> ',trim(gribname)
!        call open_grib_c(trim(gribname),funit)
!        call grib_sfc_vars_mdl
!        call close_grib_c(funit)
!        call system('/usr/bin/ssh ldm@master4 /home/ldm/bin/pqinsert '//trim(gribname))
!        gribname='/ftp/fxnet/'//adate//'_'//afcst//'.3dgrib'
!        if (verbose) print*,'Grib upa file --> ',trim(gribname)
!        call open_grib_c(trim(gribname),funit)
!        call grib_upa_vars_mdl
!        call close_grib_c(funit)
!        call system('/usr/bin/ssh ldm@master4 /home/ldm/bin/pqinsert '//trim(gribname))
!     endif

! Generate point forecasts.

      if (verbose) print*,'Begin generation of point forecasts.'

! Update ptfcst text files to include model heights.

      if (n == 0) then
         call stn_read('master')
         if (npf+nth+nsn > 0) call stn_height
      endif

      call stn_read('model')

! Generate and output point forecasts.

      if (npf > 0) then
         call alloc_point_forecast
         call point_forecast
         call write_point_forecast
      endif

! Generate and output time-height data.

      if (nth > 0) then
         call alloc_time_height
         call time_height
         call write_time_height
      endif

! Generate and output sounding forecasts.

      if (nsn > 0) then
         call alloc_sndg
         call sndg
         call write_sndg
      endif

      call dealloc_points

! Write netcdf (.fsf and .fua) files.

      call write_cdf

! Write forecast to database.

      if (dbfcst > 0) then
         if (verbose) print*,'Write db forecast.'
         call write_db
      endif

! Initiate image script.
! Process the previous hour to ensure all data is available.

      if (image_script(1:1) /= ' ') then
         if (trim(model) == 'nam' .or. trim(model) == "gfs") then
            hour=fcsttime/3600
            call image_gen(hour)
         else
            hour=fcsttime/3600 - 1
            if (hour >= 0) call image_gen(hour)
            if (n == sfcst+nfcst-1) then
               call sleep(30)
               hour=hour+1
               call image_gen(hour)
            endif
         endif
      endif

! Deallocate grids.

      if (trim(model) /= 'nam' .or. g == nmdlgrid) call dealloc_grid('native')
      call dealloc_grid('horiz')
      call dealloc_grid('isobaric')
      call dealloc_grid('surface')

! Initiate point forecast table script.

      if ((n == 60 .or. n == 72) .and. g == 2 .and. adate(6:7) == "00"  &
          .and. trim(model) == "wrf" .and. trim(domain) == "caic") then          
         call system(trim(ptfcstdir)//'/ptfcst.sh wrf'//trim(res)//' &')
      endif
      if ((n == 54 .or. n == 66 .or. n == 78) .and. g == 2 .and. adate(6:7) == "06"  &
          .and. trim(model) == "wrf" .and. trim(domain) == "caic") then          
         call system(trim(ptfcstdir)//'/ptfcst.sh wrf'//trim(res)//' &')
      endif
      if ((n == 60 .or. n == 72) .and. g == 2 .and. adate(6:7) == "12"  &
          .and. trim(model) == "wrf" .and. trim(domain) == "caic") then          
         call system(trim(ptfcstdir)//'/ptfcst.sh wrf'//trim(res)//' &')
      endif
      if ((n == 54 .or. n == 66 .or. n == 78) .and. g == 2 .and. adate(6:7) == "18"  &
          .and. trim(model) == "wrf" .and. trim(domain) == "caic") then          
         call system(trim(ptfcstdir)//'/ptfcst.sh wrf'//trim(res)//' &')
      endif
      if (n == 84 .and. g == 2  &
          .and. trim(model) == "wrf" .and. trim(domain) == "caic") then          
         call system(trim(ptfcstdir)//'/ptfcst.sh wrf'//trim(res)//' &')
      endif

   enddo

enddo

deallocate(mdlres,lapsdir)

end
