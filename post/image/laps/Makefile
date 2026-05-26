
EXE = mdl2rip.exe 

F90 = ifx
FFLAGS = -convert big_endian -I/usr/include 

LIB = -L/usr/lib64 -lnetcdff -lnetcdf

all: $(EXE)

$(EXE): 
	$(F90) $(FFLAGS) $(@:.exe=.f90) -o $@ $(LIB)
	cp $@ ../exe

mdl2rip.exe: mdl2rip.f90
