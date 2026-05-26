c                                                                     c
c*********************************************************************c
c                                                                     c
      subroutine readdat(iunit,fname,iendf1,varname,
     &   miy,mjx,mkzh,ndim,iabort,arr,istat)
c
      dimension arr(miy,mjx,1+(ndim-2)*(mkzh-1))
      character fname*256,varname*10
c
c   RIP header variables
c
      dimension ihrip(32),rhrip(32),fullsigma(128),halfsigma(128)
      character chrip(64)*64,vardesc*64,plchun*24
c
      include 'comconst'
c
      fname(iendf1+1:)=varname
      open(unit=iunit,err=30,file=fname,form='unformatted',
     &   status='old')
      read (iunit)
     &   vardesc,plchun,ihrip,rhrip,chrip,fullsigma,halfsigma
      ndimch=ihrip(6)
      if (ndim.ne.ndimch) then
         write(iup,*)'In attempting to read the file called ',fname
         write(iup,*)'you are trying to fill an array of dimension'
         write(iup,*)ndim,' with data of dimension ',ndimch
         stop
      endif
      read (iunit) arr
      close (iunit)
      istat=1
c
c   Make sure rmsg values are EXACTLY rmsg.
c   (This is necessary for the Cray, if data file was IEEE)
c
      do k=1,1+(ndim-2)*(mkzh-1)
      do j=1,mjx-1
      do i=1,miy-1
         if (abs((arr(i,j,k)-rmsg)/rmsg).lt.1e-6) arr(i,j,k)=rmsg
      enddo
      enddo
      enddo
      return
 30   istat=-1
      if (iabort.eq.1) then
         write(iup,*)'Fatal: couldn''t find file named'
         write(iup,*)'   ',fname
         stop
      endif
      return
      end
