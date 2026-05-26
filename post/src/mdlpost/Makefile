
.SILENT   :
.SUFFIXES :
.SUFFIXES : .f90 .c .o .a
.PRECIOUS : $(LIB)

# Define system commands.

RM      = /bin/rm -f
ECHO    = /bin/echo
ARCHIVE = /usr/bin/ar rs

# Define compiler flags.

FC = ifx 
CC = icx 
FFLAGS = -w -I/usr/include -module ../module
OFLAGS =
CFLAGS = -I../include
LIBS = /usr/lib64/libmysqlclient.so -L../../lib -lgrib2 -lgrib -L/usr/lib -lnetcdff -lnetcdf -L/usr/lib64 -lpng -ljasper -ljpeg

# Define all source files.

SRC = \
writeb3d.c \
maputil.f90 \
mdlgrid.f90 \
constants.f90 \
mysql.f90 \
metfunc.f90 \
wrfutil.f90 \
grib2util.f90 \
stnutil.f90 \
mdlio.f90 \
interp.f90 \
mdlutil.f90 \
gributil.f90  

OBJ = $(LIB)($(addsuffix .o, $(basename $(SRC))))

MAIN = mdlpost.f90
LIB = ../../lib/libmdlpost.a
EXE = ../../exe/mdlpost.exe

# Compile rules.

interp.o  : OFLAGS = -qopenmp

.f90.o:
	$(ECHO) "$(FC) $(FFLAGS) -c $< $(OFLAGS)"
	$(FC) $(FFLAGS) -c $< $(OFLAGS)

.o.a:
	$(ARCHIVE) $@ $(<:.f90=.o)
	$(RM) $(<:.f90=.o)

.c.a:
	$(ECHO) "$(CC) $(CFLAGS) -c $<"
	$(CC) $(CFLAGS) -c $<
	$(ARCHIVE) $@ $(<:.c=.o)
	$(RM) $(<:.c=.o)

# Default target.

$(EXE): $(MAIN) $(LIB)
	$(ECHO) "$< $@"
	$(ECHO) $(FC) $(FFLAGS) -qopenmp $< $(LIB) $(LIBS) -o $@
	$(FC) $(FFLAGS) -qopenmp $< $(LIB) $(LIBS) -o $@

$(LIB): $(OBJ)
	$(ECHO) "$(LIB) up-to-date"

exe: $(EXE)

lib: $(LIB)

clean:
	$(ECHO) $(RM) $(LIB) $(EXE)
	$(RM) $(LIB) $(EXE)

# Dependencies.

$(LIB)(mdlgrid.o): $(LIB)(maputil.o)
$(LIB)(stnutil.o): $(LIB)(mdlgrid.o)
$(LIB)(wrfutil.o): $(LIB)(mdlgrid.o) $(LIB)(constants.o)
$(LIB)(mdlutil.o): $(LIB)(mdlgrid.o) $(LIB)(constants.o)
$(LIB)(metfunc.o): $(LIB)(constants.o)
$(LIB)(mdlio.o): $(LIB)(mdlgrid.o) $(LIB)(constants.o) $(LIB)(mysql.o)
$(LIB)(interp.o): $(LIB)(mdlgrid.o) $(LIB)(constants.o) $(LIB)(maputil.o)
$(LIB)(grib2util.o): $(LIB)(mdlgrid.o)
$(LIB)(gributil.o): $(LIB)(mdlgrid.o)
