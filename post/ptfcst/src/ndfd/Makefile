
EXE = ptfcst-ndfd.exe

SRCS = proj_info.f90 ptfcst.f90 math.f90 map_utils.f90 gridinterp.f90 util.f90

OBJS = proj_info.o ptfcst.o math.o map_utils.o gridinterp.o util.o

FC = ifx
FFLAGS = -I /usr/include

LIBS = -L/usr/lib64 -lnetcdf -lnetcdff

all: $(EXE)

$(EXE): $(OBJS)
	$(FC) $(FFLAGS) -o $@ $(OBJS) $(LIBS)
	mv $(EXE) ../../exe

clean:
	rm -f $(EXE) $(OBJS)

.SUFFIXES: $(SUFFIXES) .f90

.f90.o:
	$(FC) $(FFLAGS) -c $<
