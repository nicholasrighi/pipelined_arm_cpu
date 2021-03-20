# Defines for arm cross compiler
BIN_PATH=/home/nicholasrighi/gcc-arm-none-eabi-10-2020-q4-major/bin/arm-none-eabi
LIB_PATH=/home/nicholasrighi/gcc-arm-none-eabi-10-2020-q4-major/lib/gcc/arm-none-eabi/10.2.1/thumb/v6-m/nofp

CC=$(BIN_PATH)-gcc-10.2.1
LD=$(BIN_PATH)-ld

CC_FLAGS=		-O1 -march=armv6-m -mthumb -Wall -Wno-builtin-declaration-mismatch -Ilibmc 
LD_FLAGS=		--script ld.script
LD_POSTFLAGS= 	-Llibmc -lmc -L$(LIB_PATH) -lgcc

C_FILES=test.c
S_FILES=start.s

# Defines for verilator
V_PRE_FLAGS=	--x-assign 1 --x-initial unique -Wall --trace -y verilog_src -cc 
V_POST_FLAGS=	--exe --build 
VV=verilator
CPP_SRC_DIR= testbench_code
MODULE=arm_cpu
WAVE_VIEW=reg_view

# Verilator random seeding (this could also be done in the testbench code itself)
SEED=43259258
RANDOM_FLAG=+verilator+seed+$(SEED) +verilator+rand+reset+4

goal: top

.PHONY: top gen_code clean program_counter compile

.c.o:
	$(CC) $(CC_FLAGS) -c $*.c

.s.o:
	$(CC) $(CC_FLAGS) -c $*.s -o $*.o

module:
	$(VV) $(V_PRE_FLAGS) $(MODULE).sv $(V_POST_FLAGS) $(CPP_SRC_DIR)/$(MODULE)_dut.cpp
	obj_dir/V$(MODULE) $(RANDOM_FLAG) 
	gtkwave wave_view_setups/reg_view.gtkw

compile:$(S_FILES:.s=.o) $(C_FILES:.c=.o)
	$(LD) $(LD_FLAGS) -o test $(S_FILES:.s=.o) $(C_FILES:.c=.o) $(LD_POSTFLAGS)
	./gen_sim_data.sh

top: compile module

clean:
	rm *.o test
	rm sim_data/*
	rm -r obj_dir



