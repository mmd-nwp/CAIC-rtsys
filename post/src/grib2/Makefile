
.SILENT   :
.SUFFIXES :
.SUFFIXES : .F .c .o .a
.PRECIOUS : $(LIB)

# Define system commands.

RM      = /bin/rm -f
ECHO    = /bin/echo
ARCHIVE = ar rs

# Define compiler flags.

FC = ifx
CC = gcc
FFLAGS = -DUSE_PNG -DUSE_JPEG2000 -module ../module
CFLAGS = -DUSE_PNG -DUSE_JPEG2000 -DLINUX -D__64BIT__

# Define all necessary source files.

SRC = \
drstemplates.F \
pdstemplates.F \
gridtemplates.F \
gribmod.F \
realloc.F \
addfield.F \
addgrid.F \
addlocal.F \
baciof.F \
cmplxpack.F \
compack.F \
comunpack.F \
g2grids.F \
gb_info.F \
gbytesc.F \
gdt2gds.F \
getdim.F \
getfield.F \
getg2i.F \
getg2ir.F \
getgb2.F \
getgb2l.F \
getgb2p.F \
getgb2r.F \
getgb2rp.F \
getgb2s.F \
getidx.F \
getlocal.F \
getpoly.F \
gettemplates.F \
gf_free.F \
gf_getfld.F \
gf_unpack1.F \
gf_unpack2.F \
gf_unpack3.F \
gf_unpack4.F \
gf_unpack5.F \
gf_unpack6.F \
gf_unpack7.F \
gribcreate.F \
gribend.F \
gribinfo.F \
ixgb2.F \
jpcpack.F \
jpcunpack.F \
misspack.F \
mkieee.F \
pack_gp.F \
params.F \
pngpack.F \
pngunpack.F \
putgb2.F \
rdieee.F \
reduce.F \
simpack.F \
simunpack.F \
skgb.F \
specpack.F \
specunpack.F \
bacio.v1.3.c \
dec_jpeg2000.c \
dec_png.c \
enc_jpeg2000.c \
enc_png.c \
mova2i.c

OBJ = $(LIB)($(addsuffix .o, $(basename $(SRC))))

# Define library name.

LIB = ../../lib/libgrib2.a

.F.a:
	$(ECHO) "$(FC) $(FFLAGS) -c $<"
	$(FC) $(FFLAGS) -c $<
	$(ARCHIVE) $@ $(<:.F=.o)
	$(RM) $(<:.F=.o)

.c.a:
	$(ECHO) "$(CC) $(CFLAGS) -c $<"
	$(CC) $(CFLAGS) -c $<
	$(ARCHIVE) $@ $(<:.c=.o)
	$(RM) $(<:.c=.o)

# Default target.

lib: $(LIB)

$(LIB): $(OBJ)
	$(ECHO) "$(LIB) up-to-date"

