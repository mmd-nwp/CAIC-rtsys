
EXE = ndfd-elev.exe

SRCS = proj_info.f90 ndfd-elev.f90 map_utils.f90 gridinterp.f90 

OBJS = proj_info.o ndfd-elev.o map_utils.o gridinterp.o 

FC = ifx
FFLAGS = -I /usr/include

LIBS = -L/usr/lib64 -lnetcdf -lnetcdff

all: $(EXE)

$(EXE): $(OBJS)
	$(FC) $(FFLAGS) -o $@ $(OBJS) $(LIBS)

clean:
	rm -f $(EXE) $(OBJS)

.SUFFIXES: $(SUFFIXES) .f90

.f90.o:
	$(FC) $(FFLAGS) -c $<
