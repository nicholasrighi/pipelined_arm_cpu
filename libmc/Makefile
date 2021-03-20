#
BIN_PATH=/home/nicholasrighi/gcc-arm-none-eabi-10-2020-q4-major/bin/arm-none-eabi
LIB_PATH=/home/nicholasrighi/gcc-arm-none-eabi-10-2020-q4-major/lib/gcc/arm-none-eabi/10.2.1/thumb/v6-m/nofp

CC=$(BIN_PATH)-gcc
AS=$(BIN_PATH)-as
LD=$(BIN_PATH)-ar

SSFLAGS=-march=armv6-m
CCFLAGS=-O1 -march=armv6-m -Wno-builtin-declaration-mismatch
LDFLAGS=

FILES_S=
FILES_C=*.c

.c.o:
	$(CC) $(CCFLAGS) -c $*.c

.s.o:
	$(AS) $(SSFLAGS) -c $*.s -o $*.o

libmc.a: $(FILES_S:.s=.o) $(FILES_C:.c=.o)
	$(CC) $(CCFLAGS) -c *.c
	$(LD) $(LDFLAGS) q libmc.a *.o

clean:
	rm -f *.o libmc.a
