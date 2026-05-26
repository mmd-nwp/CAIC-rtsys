
.SILENT   :
.SUFFIXES :
.SUFFIXES : .F .f .c .o .a
.PRECIOUS : $(LIB)

# Define system commands.

RM      = /bin/rm -f
ECHO    = /bin/echo
ARCHIVE = ar rs

# Define compiler flags.

FC = ifx
CC = gcc
FFLAGS = -w -Dx86_64
CFLAGS = -w -DFORTRANUNDERSCORE

# Define all necessary source files.

SRC  =  fi7501.f \
        fi7502.f \
        fi7503.f \
        fi7505.f \
        fi7513.f \
        fi7516.f \
        fi7517.f \
        fi7518.f \
        w3fi01.f \
        w3fi58.F \
        w3fi59.F \
        w3fi68.f \
        w3fi71.f \
        w3fi72.F \
        w3fi73.f \
        w3fi74.f \
        w3fi75.f \
        w3fi76.f \
        w3fi82.f \
        gbyte.f \
        sbyte.f \
        sbytes.f \
        xmovex.f \
        xstore.f \
        io_utils.c

OBJ = $(LIB)($(addsuffix .o, $(basename $(SRC))))

# Define library name.

LIB = ../../lib/libgrib.a

.F.a:
	$(ECHO) "$(FC) $(FFLAGS) -c $<"
	$(FC) $(FFLAGS) -c $<
	$(ARCHIVE) $@ $(<:.F=.o)
	$(RM) $(<:.F=.o)

.f.a:
	$(ECHO) "$(FC) $(FFLAGS) -c $<"
	$(FC) $(FFLAGS) -c $<
	$(ARCHIVE) $@ $(<:.f=.o)
	$(RM) $(<:.f=.o)

.c.a:
	$(ECHO) "$(CC) $(CFLAGS) -c $<"
	$(CC) $(CFLAGS) -c $<
	$(ARCHIVE) $@ $(<:.c=.o)
	$(RM) $(<:.c=.o)

# Default target.

lib: $(LIB)

$(LIB): $(OBJ)
	$(ECHO) "$(LIB) up-to-date"

