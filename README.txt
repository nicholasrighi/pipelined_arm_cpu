Directory structure is as follow

	// minimal standard library installiation. If any of the files in this directory are changed, need to 
	// cd into limbc and then run make clean followed by make. The Makefile inside this directory 
	// needs to have the same BIN_PATH and LIB_PATH as the Makefile in the top level directory
	limbc:
		Makefile
		collection of .c and .o files

	// contains files related to generating instruction stream for processor to run
	sim_data:
		data_mem.mem	// contains words sized chunks of data that should be stored in memory 
				// upon initilization. Assumes that memory is 8192 bytes in size, not
				// used for this project
		disassembled_code: // dissassembled code produced by objdump -d test. Used to examine
				   // assembly output of C code
		hex_code:	// the output of running hexdump -v on raw_code. This is what create_mem_files.py
				// uses to create instruction_mem.mem
		instruction_mem.mem	//the instruction stream to be loaded into the processor with $readmemh. 
					//Assumes each instruction is 16 bytes (can be changed in create_mem_files.py)
		raw_code:	// the .text (ie. code) section of the executable "test", used as the input to 
				// hexdump -v

	
	// contains all verilog source code
	verilog_src:

	// python script for taking raw_code file and generating instruction stream from that file
	create_mem_files.py

	// linker script for LD linker. Currently data section isn't used by this processor, but create_mem_files.py
	// will generate code for the data section if gen_sim_data.sh is modified to extract the .data section from the
	// test executable.
	ld.script 

	// Generates instruction stream from list of .s and .c files. All .s files should be listed in S_FILES and all
	// C files should be listed in C_FILES. The BIN_PATH and LIB_PATH variables at the top of the Makefile need to 
	// be configured for your specific arm tool chain location. BIN_PATH should be /path/to/arm-none-eabi, and 
	// LIB_PATH should be /path/to/arm-none-eabi/10.2.1/thumb/v6-m/nofp. Also contains recipies for verilator,
	// but those aren't used on the EE servers
	Makefile

	// assembly file that sets up stack and calls main()
	start.s

	// C code to run, contains main
	test.c

	/////////////////////////////////////////////
	//		HOW TO USE		   //
	/////////////////////////////////////////////
	When in this directory edit the .c and .s files as desired. Type make and check the sim_data/disassembled_code to verify 
	that the processor is generating assemmbly you want to test. Copy/Soft link sim_data/instruction_mem.mem to the directory containing your
	test bench. Inside the testbench include $readmemh("/path/to/instruction_mem.mem", <your instrution memory>). Now you have loaded the 
	assembly code into your testbench and can do whatever you want with it