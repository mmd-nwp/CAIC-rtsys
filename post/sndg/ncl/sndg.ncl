;**************************************************
; skewt_2.ncl
;
; Concepts illustrated:
;   - Drawing Skew-T plots
;   - Drawing a Skew-T plot with and without wind barbs
;   - Customizing the background of a Skew-T plot
;*************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "/home/caic/caic/rtsys/post/sndg/ncl/skewt_func.ncl"
;***********************************************
 begin

; --- Read Data; no winds; set to _FillValue------------;
  diri = "./"
  fili = "sndg.txt"
  nlvl = NLINE
  ncol = 6
  TestData = asciiread (diri+fili , (/nlvl,ncol/), "float")

  p    = TestData (:,0)
  z    = TestData (:,1)
  tc   = TestData (:,2)
  tdc  = TestData (:,3)
  wspd = TestData (:,4)
  wdir = TestData (:,5)

;*************************
; create plot
;*************************
  wks_type = "png";
; wks_type@wkPaperWidthF  = 8.5  ; in inches
; wks_type@wkPaperHeightF = 8.5  ; in inches
  wks = gsn_open_wks(wks_type,"skewt")

; --- Create background skew-T; plot sounding ---------------------

  skewtOpts                  = True
  skewtOpts@DrawColAreaFill  = True    ; default is False
  skewtOpts@DrawColAreaColor = "azure"
  skewtOpts@DrawStandardAtm  = False
  title = STN+"~C~Valid: "+VAL+"   "+MDL+" Fcst Hr: "+FCST
; skewtOpts@tiMainString     = title

  dataOpts   = True
  dataOpts@colTemperature = "red"
  dataOpts@colDewPt       = "green"
  dataOpts@PlotWindH      = False
  dataOpts@PrintZ         = False
  dataOpts@Title          = title
; dataOpts@Lift           = LIFT
; dataOpts@Kind           = KIND
; dataOpts@Ttot           = TTOT

  skewt_bkgd = skewT_BackGround (wks, skewtOpts)
  skewt_data = skewT_PlotData   (wks, skewt_bkgd, p,tc,tdc,z \
                                    , wspd,wdir, dataOpts)
  draw (skewt_bkgd)
  draw (skewt_data)
  frame(wks)

 end
