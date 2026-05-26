MODULE grib
  
! Module containing routines to allow output of grib data
! Requires the NCEP w3fi library routines and io routines developed
! for RUC. 
!
! REFERENCE:NCEP Office Note 388, GRIB (Edition 1)
  USE map_utils
  IMPLICIT NONE


CONTAINS
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE make_igds(proj,igds)
    
    IMPLICIT NONE
    TYPE(proj_info),INTENT(IN)           :: proj
    INTEGER, INTENT(OUT)                 :: igds(18)
    REAL, PARAMETER                      :: pi = 3.1415927
    REAL, PARAMETER                      :: deg_per_rad = 180./pi
    REAL, PARAMETER                      :: rad_per_deg = pi / 180.
    REAL                                 :: scale , latne, lonne
    igds(1) = 0                          ! number of vertical (not used)
    igds(2) = 255                        ! PV,PL or 255 (not used)
    
    ! Set Data Representation Type (GDS Octet 6, Table 6 from reference)
    SELECT CASE (proj%code)
      CASE (PROJ_PS)
         igds(3) = 5
         igds(4) = proj%nx        ! E-W Dimension
         igds(5) = proj%ny        ! N-S Dimension
         igds(6) = NINT(proj%lat1*1000.)   ! SW lat in millidegrees
         igds(7) = NINT(proj%lon1*1000.)   ! SW lon in millidegrees
         igds(8) = 8                       ! 
         igds(9) =NINT(proj%stdlon*1000.)
 
         ! Adjust grid lengths to be true at 60 deg latitude
         scale = (1.+SIN(60.*rad_per_deg)) / &
                 (1.+proj%hemi*SIN(proj%truelat1*rad_per_deg))
         igds(10) = NINT(proj%dx) * scale
         igds(11) = NINT(proj%dx) * scale
         IF (proj%hemi .EQ. -1 ) THEN   
           igds(12) = 1
         ELSE
           igds(12) = 0
         ENDIF
         igds(13) = 64
         igds(14) = 0
         igds(15) = 0
         igds(16) = 0
         igds(17) = 0
         igds(18) = 0
      CASE (PROJ_LC)
         igds(3) = 3
         igds(4) = proj%nx        ! E-W Dimension
         igds(5) = proj%ny        ! N-S Dimension
         igds(6) = NINT(proj%lat1*1000.)   ! SW lat in millidegrees
         igds(7) = NINT(proj%lon1*1000.)   ! SW lon in millidegrees
         igds(8) = 8                       ! 
         igds(9) = NINT(proj%stdlon*1000.)
         igds(10) = NINT(proj%dx) 
         igds(11) = NINT(proj%dx) 
         IF (proj%hemi .EQ. -1 ) THEN
           igds(12) = 1
         ELSE
           igds(12) = 0
         ENDIF
         igds(13) = 64
         igds(14) = 0
         igds(15) = NINT(proj%truelat1*1000.)
         igds(16) = NINT(proj%truelat2*1000.)
         igds(17) = -90000  ! Latitude of southern pole?
         igds(18) = NINT(proj%stdlon*1000.)  ! Longitude of southern pole?
      CASE (PROJ_MERC)
         igds(3) = 1
         igds(4) = proj%nx        ! E-W Dimension
         igds(5) = proj%ny        ! N-S Dimension
         igds(6) = NINT(proj%lat1*1000.)   ! SW lat in millidegrees
         igds(7) = NINT(proj%lon1*1000.)   ! SW lon in millidegrees
         igds(8) = 0                       !  
         ! Compute lat/lon at nx/ny
         CALL ij_to_latlon(proj,FLOAT(proj%nx),FLOAT(proj%ny),latne,lonne)
         igds(9) = NINT(latne*1000.)
         igds(10) = NINT(lonne*1000.)
         igds(11) = NINT(proj%dx)
         igds(12) = NINT(proj%dx)
         igds(13) = 64
         igds(14:18) = 0
      CASE DEFAULT 
         print *, 'Projection code not supported: ', proj%code
         stop
    END SELECT
    RETURN
  END SUBROUTINE make_igds
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE make_id(table_version,center_id,subcenter_id,process_id, &
                     param,leveltype,level1,level2,yyyyr,mmr,ddr,hhr,minr, &
                     timeunit, timerange, timeperiod1, timeperiod2,&
                     scalep10,id)

    ! Routine to make the ID integer array passed into W3FI72.  The ID
    ! array is used to generate the GRIB message PDS section.

    IMPLICIT NONE
    INTEGER, INTENT(IN)         :: table_version 
    INTEGER, INTENT(IN)         :: center_id
    INTEGER, INTENT(IN)         :: subcenter_id
    INTEGER, INTENT(IN)         :: process_id
    INTEGER, INTENT(IN)         :: param       ! GRIB code for variable
    INTEGER, INTENT(IN)         :: leveltype   ! GRIB code for level type
    INTEGER, INTENT(IN)         :: level1      ! Value of level1
    INTEGER, INTENT(IN)         :: level2      ! value of level2
    INTEGER, INTENT(IN)         :: yyyyr       ! Ref (initial) time year
    INTEGER, INTENT(IN)         :: mmr         ! Ref (initial) time month
    INTEGER, INTENT(IN)         :: ddr         ! Ref (initial) day of month
    INTEGER, INTENT(IN)         :: hhr         ! Ref (initial) hour (UTC)
    INTEGER, INTENT(IN)         :: minr        ! Ref (initial) minute
    INTEGER, INTENT(IN)         :: timeperiod1 ! Values used for forecast 
    INTEGER, INTENT(IN)         :: timeperiod2 !   time wrt reference time
    INTEGER, INTENT(IN)         :: timeunit    ! GRIB time unit (Table 4)
    INTEGER, INTENT(IN)         :: timerange   ! GRIB Time Range (Table 5)
    INTEGER, INTENT(IN)         :: scalep10    ! Scaling power of 10 
    INTEGER, INTENT(OUT)        :: id(27)      
    ! Some stuff from the grib setup that are for now supplied by the
    ! include file at compile time, but should be moved to a namelist 
    ! eventually
    id(1) =  28
    id(2) = table_version
    id(3) = center_id
    id(4) = process_id
    id(5) = 255    ! We use the GDS section to define grid
    id(6) = 1      ! GDS included
    id(7) = 0      ! No BMS or bitmask

    ! Stuff from arguments
    id(8) = param       ! See table 2 of reference document
    id(9) = leveltype   ! See table 3 of reference document

    ! Level stuff, dependent upon value of leveltype
    IF ( ((leveltype.GE.1).AND.(leveltype.LE.100)) .OR. &
          (leveltype.EQ.102).OR.(leveltype.EQ.103).OR.&
          (leveltype.EQ.105).OR.(leveltype.EQ.107).OR.&
          (leveltype.EQ.109).OR.(leveltype.EQ.109).OR.&
          (leveltype.EQ.111).OR.(leveltype.EQ.113).OR.&
          (leveltype.EQ.115).OR.(leveltype.EQ.117).OR.&
          (leveltype.EQ.119).OR.(leveltype.EQ.125).OR.&
          (leveltype.EQ.160).OR.(leveltype.EQ.200).OR.&
          (leveltype.EQ.201) ) THEN
      id(10) = 0
      id(11) = level1
    ELSE
      id(10) = level1
      id(11) = level2
    ENDIF

    ! Set reference time, which is the valid time for analyses and the
    ! initial time for forecasts
    id(12) = MOD(yyyyr,100)  ! Year of Century
    id(13) = mmr             ! Month
    id(14) = ddr             ! Day
    id(15) = hhr             ! Hour (UTC)
    id(16) = minr            ! Minute 
    id(17) = timeunit        ! Unit indicator from table 4
    id(18) = timeperiod1
    id(19) = timeperiod2
    id(20) = timerange 
 
    ! Flags to describe averaging (not yet used for our application)
    id(21) = 0               ! Number included in average
    id(22) = 0               ! Number missing from average

    ! Miscellaneous stuff
    id(23) =(yyyyr/100) + 1  ! Integer math to get century
    id(24) = subcenter_id   
    id(25) = scalep10        ! Scaling power of 10 for precision preservation
    id(26) = 0           
    id(27) = 0               ! Not used  
  END SUBROUTINE make_id 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE write_grib(itype,fld,id,igds,funit,startb,itot,istatus)

    ! Subroutine to generate the grib message and write it to a file which
    ! must already be opened using open_grib routine.

    IMPLICIT NONE
    INTEGER,INTENT(IN)            :: itype ! (0 for real data, 1 for int data)
    REAL,INTENT(IN)               :: fld(:)  ! Input real data array
      ! Note: If integer output desired, then pass the data in as real
      ! anyway, and this routine will convert it back to integer.

    INTEGER,INTENT(IN)            :: id(27)   ! Input ID array for PDS
    INTEGER,INTENT(IN)            :: igds(18) ! Input IGDS array for GDS
    INTEGER,INTENT(IN)            :: funit   ! Unit # for output
    INTEGER,INTENT(IN)            :: startb  ! Starting record number
    INTEGER,INTENT(OUT)           :: itot    ! Number of bytes written
    INTEGER,INTENT(OUT)           :: istatus ! Status (0=OK)

    INTEGER,PARAMETER             :: maxbuf=512000
    INTEGER,ALLOCATABLE           :: ifld(:)
    INTEGER,ALLOCATABLE           :: ibmap(:)
    CHARACTER(LEN=1)              :: kbuf(maxbuf)
    INTEGER                       :: ibitl
    INTEGER                       :: ipflag
    INTEGER                       :: igflag
    INTEGER                       :: igrid
    INTEGER                       :: icomp
    INTEGER                       :: ibflag
    INTEGER                       :: iblen
    INTEGER                       :: ibdsfl(9)
    CHARACTER(LEN=1)              :: pds(28)
    INTEGER                       :: npts,jerr
    INTEGER                       :: nxny
    INTEGER, EXTERNAL             :: c_write_g
    INTEGER                       :: iwrite
    INTEGER                       :: i,j,ibuf 
    istatus = 0

    nxny = igds(4)*igds(5)    ! nx*ny
    ! Allocate the integer data array.  If itype is 1, then 
    ! also populate it.  Otherwise, it is just used as a dummy
    ! argument
    ALLOCATE(ifld(nxny))
    IF (itype .EQ. 1) THEN 
      DO j=0,igds(5)-1
        DO i=1,igds(4)
          ifld( j*igds(4)+i ) = NINT(fld( j*igds(4)+i ))
        ENDDO
      ENDDO
    ENDIF
    ! Allocate ibmap (dummy for now)
    ALLOCATE(ibmap(nxny))
    
    kbuf(:) = char(0)
    ! For now, there are a lot of hard coded options that we can
    ! make more flexible later on (e.g., use of bit maps, etc.)

    ibitl = 0   ! Let compute pick optimum packgin length
    ipflag = 0  ! Create PDS from user supplied ID array
    igflag = 1  ! Create GDS from supplied igds array
    igrid = 255 ! Using GDS from supplied igds array
    icomp = 1   ! Grid-oriented winds (always the case in LAPS)
    ibflag = 0
    iblen = nxny
    ibdsfl(1) = 0  ! Grid point data
    ibdsfl(2) = 0  ! Simple packing
    ibdsfl(3) = itype
    ibdsfl(4) = 0  ! no additional flags at octet 14
    ibdsfl(5) = 0  ! Always set to 0 (reserved)
    ibdsfl(6) = 0  ! Single datum at each gridpoint
    ibdsfl(7) = 0  ! No secondary bit maps present
    ibdsfl(8) = 0  ! Second order values have constant widths
    ibdsfl(9) =0
 
    ! Make the grib message, which will be put into kbuf with information
    ! on its exact length provided in itot
    CALL w3fi72(itype,fld,ifld,ibitl,ipflag,id,pds,igflag,igrid,igds, &
                icomp,ibflag,ibmap,iblen,ibdsfl,npts,kbuf,itot,jerr)
    DEALLOCATE(ibmap)
    DEALLOCATE(ifld)
    ! Check error status
    IF (jerr .NE. 0) THEN
      PRINT *, 'Error creating GRIB message...jerr = ', jerr
      PRINT *, 'NPTS/ITOT = ',npts,itot
      istatus = 1
      RETURN
    ENDIF
    IF (itot .GT. maxbuf) THEN
      PRINT *, 'Message size larger than buffer allocation!'
      istatus = 1
      RETURN
    ENDIF
    ! Ready to write the message
    !print *,'Writing ',itot,'bytes starting at ', startb

    ! FORTRAN method
    !DO i = 1,itot
    !  WRITE(funit,REC=i+startb-1) kbuf(i)
    !ENDDO
    ! C method
    iwrite = c_write_g(0,itot,kbuf,funit)
    IF (iwrite .NE. 0) THEN
      print *, 'Error writing GRIB message -- ', iwrite
      istatus = 1
      RETURN
    ENDIF
    !print *,'Write completed.'
    RETURN
  END SUBROUTINE write_grib
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE open_grib_f(fname,funit)
   
    ! Opens a grib file for writing and returns the funit
    IMPLICIT NONE
    CHARACTER(LEN=*),INTENT(IN)      :: fname
    INTEGER,INTENT(OUT)                :: funit
    LOGICAL                            :: opened 
    unitloop: DO funit=7,1023
      INQUIRE(UNIT=funit,OPENED=opened) 
      IF (.NOT.opened) EXIT unitloop
    ENDDO unitloop
    OPEN(FILE=fname,UNIT=funit,ACCESS='DIRECT',FORM='UNFORMATTED',&
         RECL=1) 
    RETURN
  END SUBROUTINE open_grib_f
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE open_grib_c(fname,funit)
  
    ! Opens a grib file for writing and returns the funit
    IMPLICIT NONE
    CHARACTER(LEN=*),INTENT(IN)      :: fname
    INTEGER,INTENT(OUT)                :: funit
    INTEGER, EXTERNAL                  :: c_open_g
    INTEGER                            :: length
    LOGICAL                            :: opened
!   CALL s_len(fname,length)
    funit = -1
    funit = c_open_g(trim(fname)//char(0),'w'//char(0))
    RETURN
  END SUBROUTINE open_grib_c
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE close_grib_f(funit)

    IMPLICIT NONE
    INTEGER, INTENT(IN)       :: funit

    close(funit) 
 
    RETURN
  END SUBROUTINE close_grib_f    
   
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  SUBROUTINE close_grib_c(funit)

    IMPLICIT NONE
    INTEGER, INTENT(IN)       :: funit
    INTEGER, EXTERNAL         :: c_close_g
    INTEGER                   :: iretc

    iretc = -1
    iretc = c_close_g(funit)
    print *, 'Grib file closed with iretc = ', iretc
    RETURN
  END SUBROUTINE close_grib_c
  
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END MODULE grib

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE grib_sfc_vars_mdl

    USE grib
    use mdlgrid
    IMPLICIT NONE

    INTEGER                     :: laps_reftime
    INTEGER                     :: laps_valtime

    INTEGER                     :: i,j
    INTEGER                     :: itype
    INTEGER                     :: istatus
    INTEGER                     :: id(27)
    INTEGER                     :: param
    INTEGER                     :: leveltype
    INTEGER                     :: level1
    INTEGER                     :: level2
    INTEGER                     :: yyyyr
    INTEGER                     :: mmr
    INTEGER                     :: ddr
    INTEGER                     :: hhr
    INTEGER                     :: minr
    INTEGER                     :: timeunit
    INTEGER                     :: timerange
    INTEGER                     :: timeperiod1
    INTEGER                     :: timeperiod2
    INTEGER                     :: scalep10
    CHARACTER(LEN=24)           :: atime 
    REAL                        :: fld(lx*ly)
    CHARACTER(LEN=3)            :: amonth
    CHARACTER(LEN=3)            :: amonths(12)
    INTEGER                     :: fcsttime_now
    INTEGER                     :: fcsttime_prev
    INTEGER                     :: itot 
    INTEGER                     :: startbyte
    DATA amonths /'JAN','FEB','MAR','APR','MAY','JUN', &
                  'JUL','AUG','SEP','OCT','NOV','DEC'/

    ! Compute year, month, day of month, hour, and minute from laps_reftime

    call adate_to_i4time(adate,laps_reftime)
    laps_valtime=laps_reftime+fcsttime
    period_sec=max(0,laps_valtime-grib_inc*3600)
    CALL cv_i4tim_asc_lp(laps_reftime,atime,istatus) 
    READ(atime,'(I2.2,x,A3,x,I4.4,x,I2.2,x,I2.2)') ddr,amonth,yyyyr, &
       hhr,minr
    DO i = 1, 12
      IF (amonth .eq. amonths(i)) THEN
         mmr = i
         EXIT
      ENDIF
    ENDDO

    ! Determine appropriate timeunit

    IF ( MOD(period_sec,3600) .EQ. 0) THEN
      ! Time unit shoud be hours
      timeunit = 1
      fcsttime_now = (laps_valtime-laps_reftime)/3600
      IF (fcsttime_now .GT. 0) THEN
        fcsttime_prev = fcsttime_now - (period_sec/3600)
      ELSE
        fcsttime_prev = 0
      ENDIF
    ELSE
      ! Time unit in minutes
      timeunit = 0
      fcsttime_now = (laps_valtime-laps_reftime)/60
      IF (fcsttime_now .GT. 0) THEN
        fcsttime_prev = fcsttime_now - (period_sec/60)
      ELSE
        fcsttime_prev = 0
      ENDIF
    ENDIF
    
    ! Grib up each variable...
    nbytes = startb - 1
    startbyte = nbytes+startb
    
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
    ! Surface Temperature
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = tpshl(i,j+1)
      ENDDO
    ENDDO
    print *,'Gribbing Tsfc Min/Max = ',minval(fld),maxval(fld)
    itype = 0
    param = 11
    leveltype = 105
    level1 = 2
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = 1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
               scalep10,id) 
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte = nbytes + 1 

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Surface dewpoint
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = tdsfc(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing TdSfc Min/Max = ',minval(fld),maxval(fld)
    itype = 0
    param = 17
    leveltype = 105
    level1 = 2
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = 1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte=nbytes+1

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Surface RH
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = rhsfc(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing Sfc RH Min/Max = ',minval(fld),maxval(fld)
    itype = 0
    param = 52
    leveltype = 105
    level1 = 2
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = 1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &   
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)     
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)    
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte=nbytes+1

    !!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Surface U wind  
    !!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = uwshl(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing Sfc U Min/Max = ', minval(fld),maxval(fld)
    itype = 0
    param = 33
    leveltype = 105
    level1 = 10
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = 1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)    
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte=nbytes+1
   
    !!!!!!!!!!!!!!!!!!!!!!!!
    ! Surface V wind  
    !!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = vwshl(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing Sfc V Min/Max = ', minval(fld),maxval(fld)
    itype = 0
    param = 34
    leveltype = 105
    level1 = 10
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = 1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)    
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte = nbytes+1
   
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Sea Level Pressure
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = slp(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing MSLP Min/Max = ',minval(fld),maxval(fld)
    itype = 0
    param = 2 
    leveltype = 1
    level1 = 0 
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = -1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)    
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte=nbytes+1

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Surface Pressure
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = prsfc(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing Sfc P Min/Max = ', minval(fld),maxval(fld)
    itype = 0
    param =  1
    leveltype = 1
    level1 = 0
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = -1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte=nbytes+1

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Some fields only present in true forecast fields
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    IF (fcsttime_now > 0) THEN
    
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      ! Total Accum Precip
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      DO j = 0,ly-1
        DO i = 1,lx
          fld(j*lx + i) = pcp(i,j+1)
        ENDDO
      ENDDO
      print *,'Gribbing TotPCP Min/Max = ',minval(fld),maxval(fld)
      itype = 0
      param =  61
      leveltype = 1
      level1 = 0
      level2 = 0
      timerange = 4
      timeperiod1 = 0
      timeperiod2 = fcsttime_now
      scalep10 =  1
      CALL make_id(table_version,center_id,subcenter_id,process_id, &
                   param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)
      CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
      print*,'Status =',istatus
      nbytes = nbytes + itot
      startbyte=nbytes+1

      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      ! Total Accum Snow
      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      DO j = 0,ly-1
        DO i = 1,lx
          fld(j*lx + i) = sno(i,j+1)
        ENDDO
      ENDDO
      print *, 'Gribbing Snow Tot Min/Max =',minval(fld),maxval(fld)
      itype = 0
      param =  161
      leveltype = 1
      level1 = 0
      level2 = 0
      timerange = 4
      timeperiod1 = 0
      timeperiod2 = fcsttime_now
      scalep10 =  1
      CALL make_id(table_version,center_id,subcenter_id,process_id, &
                   param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)
      CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
      print*,'Status =',istatus
      nbytes = nbytes + itot
      startbyte=nbytes+1

    ENDIF

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Lifted index
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = lif(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing LI Min/Max = ',minval(fld),maxval(fld)
    itype = 0
    param =  131
    leveltype = 1
    level1 = 0
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = 1
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte=nbytes+1

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !  PBL Height
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
       DO i = 1,lx
          fld(j*lx + i) = pbl(i,j+1)
       ENDDO
    ENDDO
    print *, 'Gribbing PBLHGT Min/Max =',minval(fld),maxval(fld)
    itype = 0
    param =  221
    leveltype = 1
    level1 = 0
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 =  0
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                scalep10,id)
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    print*,'Status =',istatus
    nbytes = nbytes + itot
    startbyte=nbytes+1

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    ! Total preciptable water
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    DO j = 0,ly-1
      DO i = 1,lx
        fld(j*lx + i) = tpw(i,j+1)
      ENDDO
    ENDDO
    print *, 'Gribbing Total PW Min/Max = ',minval(fld),maxval(fld)
    itype = 0
    param =  54
    leveltype = 200
    level1 = 0
    level2 = 0
    timerange = 0
    timeperiod1 = fcsttime_now
    timeperiod2 = 0
    scalep10 = 0
    CALL make_id(table_version,center_id,subcenter_id,process_id, &
                 param,leveltype,level1,level2,yyyyr,mmr,ddr, &
                 hhr,minr,timeunit,timerange,timeperiod1,timeperiod2, &
                 scalep10,id)
    CALL write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
    nbytes = nbytes + itot
    startbyte=nbytes+1

    RETURN
  END SUBROUTINE grib_sfc_vars_mdl

!===============================================================================

subroutine grib_upa_vars_mdl

use grib
use mdlgrid

implicit none

integer           :: laps_reftime
integer           :: laps_valtime

integer           :: i,j,k,lvl
integer           :: itype
integer           :: istatus
integer           :: id(27)
integer           :: param
integer           :: leveltype
integer           :: level1
integer           :: level2
integer           :: yyyyr
integer           :: mmr
integer           :: ddr
integer           :: hhr
integer           :: minr
integer           :: timeunit
integer           :: timerange
integer           :: timeperiod1
integer           :: timeperiod2
integer           :: scalep10
character(len=24) :: atime 
real              :: fld(lx*ly)
character(len=3)  :: amonth
character(len=3)  :: amonths(12)
integer           :: fcsttime_now
integer           :: fcsttime_prev
integer           :: itot 
integer           :: startbyte

real, external :: relhum

data amonths /'JAN','FEB','MAR','APR','MAY','JUN'   &
             ,'JUL','AUG','SEP','OCT','NOV','DEC'/

! Compute year, month, day of month, hour, and minute from laps_reftime.

call adate_to_i4time(adate,laps_reftime)
laps_valtime=laps_reftime+fcsttime
period_sec=max(0,laps_valtime-grib_inc*3600)
call cv_i4tim_asc_lp(laps_reftime,atime,istatus) 
read(atime,'(I2.2,x,A3,x,I4.4,x,I2.2,x,I2.2)') ddr,amonth,yyyyr  &
    ,hhr,minr
do i=1,12
   if (amonth == amonths(i)) then
      mmr=i
      exit
   endif
enddo

! Determine appropriate timeunit.

if (mod(period_sec,3600) == 0) then
! Time unit shoud be hours.
   timeunit=1
   fcsttime_now=(laps_valtime-laps_reftime)/3600
   if (fcsttime_now > 0) then
     fcsttime_prev=fcsttime_now-(period_sec/3600)
   else
     fcsttime_prev=0
   endif
else
! Time unit in minutes.
   timeunit=0
   fcsttime_now=(laps_valtime-laps_reftime)/60
   if (fcsttime_now > 0) then
     fcsttime_prev=fcsttime_now-(period_sec/60)
   else
     fcsttime_prev=0
   endif
endif

! Grib up each variable at each level.

nbytes=startb-1
startbyte=startb+nbytes
levelloop: do k=1,lz
   lvl=nint(lprs(k))/100
   if (lvl <= 1000 .and. mod(lvl,50) == 0) then

! Geopotential height.

      do j=0,ly-1
      do i=1,lx
         fld(j*lx+i)=ht(i,j+1,k)
      enddo
      enddO
      itype=0
      param=7
      leveltype=100
      level1=lvl
      level2=0
      timerange=0
      timeperiod1=fcsttime_now
      timeperiod2=0
      scalep10=0
      call make_id(table_version,center_id,subcenter_id,process_id      &
                  ,param,leveltype,level1,level2,yyyyr,mmr,ddr          &
                  ,hhr,minr,timeunit,timerange,timeperiod1,timeperiod2  &
                  ,scalep10,id)
      call write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
      nbytes=nbytes+itot
      startbyte=nbytes+1

! Temperature.

      do j=0,ly-1
      do i=1,lx
         fld(j*lx+i)=tp(i,j+1,k)
      enddo
      enddO
      itype=0
      param=11
      leveltype=100
      level1=lvl
      level2=0
      timerange=0
      timeperiod1=fcsttime_now
      timeperiod2=0
      scalep10=2
      call make_id(table_version,center_id,subcenter_id,process_id      &
                  ,param,leveltype,level1,level2,yyyyr,mmr,ddr          &
                  ,hhr,minr,timeunit,timerange,timeperiod1,timeperiod2  &
                  ,scalep10,id)
      call write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
      nbytes=nbytes+itot
      startbyte=nbytes+1

! Relative humidity.

      do j=0,ly-1
      do i=1,lx
         fld(j*lx+i)=relhum(tp(i,j+1,k),mr(i,j+1,k),lprs(k))
      enddo
      enddO
      itype=0
      param=52
      leveltype=100
      level1=lvl
      level2=0
      timerange=0
      timeperiod1=fcsttime_now
      timeperiod2=0
      scalep10=1
      call make_id(table_version,center_id,subcenter_id,process_id      &
                  ,param,leveltype,level1,level2,yyyyr,mmr,ddr          &
                  ,hhr,minr,timeunit,timerange,timeperiod1,timeperiod2  &
                  ,scalep10,id)
      call write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
      nbytes=nbytes+itot
      startbyte=nbytes+1

! U-wind.

      do j=0,ly-1
      do i=1,lx
         fld(j*lx+i)=uw(i,j+1,k)
      enddo
      enddO
      itype=0
      param=33
      leveltype=100
      level1=lvl
      level2=0
      timerange=0
      timeperiod1=fcsttime_now
      timeperiod2=0
      scalep10=1
      call make_id(table_version,center_id,subcenter_id,process_id      &
                  ,param,leveltype,level1,level2,yyyyr,mmr,ddr          &
                  ,hhr,minr,timeunit,timerange,timeperiod1,timeperiod2  &
                  ,scalep10,id)
      call write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
      nbytes=nbytes+itot
      startbyte=nbytes+1

! V-wind.

      do j=0,ly-1
      do i=1,lx
         fld(j*lx+i)=vw(i,j+1,k)
      enddo
      enddO
      itype=0
      param=34
      leveltype=100
      level1=lvl
      level2=0
      timerange=0
      timeperiod1=fcsttime_now
      timeperiod2=0
      scalep10=0
      call make_id(table_version,center_id,subcenter_id,process_id      &
                  ,param,leveltype,level1,level2,yyyyr,mmr,ddr          &
                  ,hhr,minr,timeunit,timerange,timeperiod1,timeperiod2  &
                  ,scalep10,id)
      call write_grib(itype,fld,id,igds,funit,startbyte,itot,istatus)
      nbytes=nbytes+itot
      startbyte=nbytes+1

   endif

enddo levelloop

return
end subroutine grib_upa_vars_mdl
