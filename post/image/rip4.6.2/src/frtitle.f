c                                                                     c
c*********************************************************************c
c                                                                     c
      subroutine frtitle(title,casename,iendc,rootname,
     &   mdateb,rhourb,xtime,timezone,iusdaylightrule,inearesth,
     &   idotitle,iinittime,ifcsttime,ivalidtime,toptextclg)
c
      character title*80,str(4)*80,casename*256,rootname*256,
     &   blank*80
      character*22 dtgi,dtgfz,dtgfl
      integer ilast(4)
c
      blank=' '
      chwd=.012
      chht=1.155*chwd
      chgap=.6*chht
c
c   If idealized, treat as though printing of init time AND valid time
c   have been disabled, even if they haven't, because these times
c   are meaningless for idealized runs.
c
      if (mdateb.eq.40010100) then ! indicates idealized model run
c                                  ! (starts on "00 UTC 1 Jan 1940")
         iit=0
         ivt=0
      else
         iit=iinittime
         ivt=ivalidtime
      endif
c
c     If title is specified as 'none', this effectively means idotitle
c     should be treated as zero.
c
      idt=idotitle
      if (title(1:10).eq.'none      ') idt=0
c
      ift=ifcsttime  ! for brevity
c
c   Make set call
c
      call set(0.,1.,0.,1.,0.,1.,0.,1.,1)
c
c   Create human-readable dates/times from time info
c
      call createdtg(mdateb,rhourb,xtime,timezone,
     &   iusdaylightrule,inearesth,dtgi,dtgfz,dtgfl)
c
c     Here's how this works.  Four things may or may not be written in
c     the title lines: the title (model/rip.in info); the model initial
c     date/time; the model forecast hour; and the model valid date/time.
c     They are written at the top of the frame in that order.  The first
c     item is 1st line/left, the second is 1st line/right, the third is
c     2nd line/left, and the fourth is 2nd line/right.  If there are
c     less than four of these items requested, just follow the same
c     rules, with the exception that if there are exactly three items,
c     the third item is moved to 2nd line/right.  Thus, there may
c     possibly be 0, 1, or 2 frame title lines. I've thought a lot
c     (probably too much) about this, and this is the best way to do it,
c     so don't argue.
c
      icount=0
c
      if (idt.eq.1) then
         icount=icount+1
         if (title(1:10).eq.'auto      ') then
            ibegc=1
            ibegcr=1
            do i=256,2,-1
               if (ibegc.eq.1.and.casename(i-1:i-1).eq.'/') ibegc=i
               if (ibegcr.eq.1.and.rootname(i-1:i-1).eq.'/') ibegcr=i
            enddo
            ilenc=min(iendc-ibegc+1,15)
            ilencr=31-ilenc
            str(icount)='Dataset: '//casename(ibegc:ibegc+ilenc-1)//
     &                  '  RIP: '//rootname(ibegcr:ibegcr+ilencr-1)
         else
            str(icount)=title
         endif
         ilast(icount)=47
      endif
c
      if (iit.eq.1) then
         icount=icount+1
         str(icount)=' '
         write(str(icount),'(a6,a22)') 'Init: ',dtgi
         ilast(icount)=28
         if (inearesth.eq.1) ilast(icount)=ilast(icount)-2
      endif
c
c     if (ift.eq.1) then
c        icount=icount+1
c        write(str(icount),'(a6)') 'Fcst: '
c        if (inearesth.eq.0) then
c           write(str(icount)(7:),'(f7.2,a2)') xtime,' h'
c        else
c           ixtime=nint(xtime)
c           write(str(icount)(7:),'(i4,a2)') ixtime,' h'
c        endif
c        ilast(icount)=15
c     endif
c
c     if (ivt.eq.1) then
c        icount=icount+1
c        if (inearesth.eq.0) then
c           write(str(icount),'(a7,a22,a2,a22,a1)')
c    &         'Valid: ',dtgfz,' (',dtgfl,')'
c           ilast(icount)=54
c        else
c           write(str(icount),'(a7,a20,a2,a20,a1)')
c    &         'Valid: ',dtgfz(1:20),' (',dtgfl(1:20),')'
c           ilast(icount)=50
c        endif
c     endif
c
      ntotal=icount
      print*,'ntotal: ',ntotal
c
c   Now write the strings that were created
c
      ntotal=3
      do i=1,ntotal
c
      if (i.eq.1) then
         xpos=.995
         ypos=toptextclg-.5*chht
         align=1.
c     elseif (i.eq.2) then
c        xpos=.01
c        ypos=0.955
c        align=-1.
      elseif (i.eq.2) then
         str(i)=' '
         if (ivt.eq.1) then
            write(str(i),'(a15)') 'Forecast hour: '
         else
            write(str(i),'(a15)') 'LAPS Analysis  '
         endif
         iendst=15
         if (ivt.eq.1) then
            if (inearesth.eq.0) then
               if (xtime.ge.0.) then
                  write(str(i)(iendst+1:),'(f7.2)') xtime
               else
                  str(i)(3:3)='-'
                  write(str(i)(iendst+1:),'(f7.2,a2)') -xtime,' h'
               endif
            else
               ixtime=nint(xtime)
               if (ixtime.ge.0) then
                 write(str(i)(iendst+1:iendst+4),'(i3)') ixtime
               else
                 str(i)(3:3)='-'
                 write(str(i)(iendst+1:iendst+4),'(i4,a2)') -ixtime,' h'
               endif
            endif
         endif
         xpos=0.01
         ypos=0.935
         align=-1.
      elseif (i.eq.3) then
         xpos=.915
         align=1.
         write(str(i),'(a7,a2,a3,a3,a2,a3,a2,a4,a2,a4,a2)')
     &      'Valid: ',dtgfl(1:2),'00 ',dtgfl(4:6),', ',dtgfl(8:10)
     &     ,', ',dtgfl(15:18),dtgfl(12:13),', 20',dtgfl(19:20)
      endif
c
      call plchhq(xpos,ypos,trim(str(i)),chwd,0.,align)
c
      enddo
c
c   Adjust toptextclg
c
      if (ntotal.eq.1.or.ntotal.eq.2) then
         toptextclg=toptextclg-(chht+chgap)
      elseif (ntotal.eq.3.or.ntotal.eq.4) then
         toptextclg=toptextclg-2.*(chht+chgap)
      endif
c
      return
      end
