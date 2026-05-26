#. /opt/intel/oneapi/setvars.sh 
ifx -I /usr/include -o iptfcst-ndfd.exe nwsfcst.f90 -L /usr/lib -lnetcdf -lnetcdff
mv iptfcst-ndfd.exe ../../exe
ifx -I /usr/include -o iptfcst-wrf.exe wrffcst.f90 -L /usr/lib -lnetcdf -lnetcdff
mv iptfcst-wrf.exe ../../exe
