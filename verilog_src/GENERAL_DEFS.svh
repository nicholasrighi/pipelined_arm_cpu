`ifndef GENERAL_DEFS_H
`define GENERAL_DEFS_H

	// size types
	parameter WORD 		= 32;
	parameter HALF_WORD = 16;
	parameter BYTE 		= 8;

	typedef struct packed {
		opcode op;
		logic [10:0] instruction_data;
	} instruction;

	typedef enum logic [5:0] {
		SHIFT_IMM		= 6'b00xxxx;
		DATA_PROCESSING = 6'b010000;
		SPECIAL			= 6'b010001;
		LOAD_LITERAL	= 6'b01001x;
		LOAD_OFF_REG	= 6'b0101xx;
		LOAD_OFF_IMM	= 6'b011xxx;
		LOAD_SPECIAL	= 6'b100xxx;
		GEN_PC_REL		= 6'b10100x; 
		GEN_SP_REL		= 6'b10101x;
		MIS_16_BIT		= 6'b1011xx;
		STORE_MULT_REG  = 6'b11000x;
		LOAD_MULT_REG	= 6'b11001x;
		COND_BRANCH		= 6'b1101xx;
		UNCOND_BRANCH	= 6'b11100x;
	} opcode;

	typdef enum logic [4:0] {
		LEFT_SHIFT_L_IM	= 	5'b000xx;
		RIGHT_SHIFT_L_IM =	5'b001xx;
		RIGHT_SHIFT_A	=	5'b010xx;
		ADD_REG			=	5'b01100;
		SUB_REG			=	5'b01101;
		ADD_3_IMM		=	5'b01110;
		SUB_3_IMM		=	5'b01111;
		MOVE			=	5'b100xx;
		COMPARE			=	5'b101xx;
		ADD_8_IMM		=	5'b110xx;
		SUB_8_IMM		=	5'b111xx;
	} shift_code;

	typedef enum logic [3:0] {
		AND				= 4'b0000;
		XOR 			= 4'b0001;
		LEFT_SHIFT_LOG	= 4'b0010;
		RIGHT_SHIFT_LOG = 4'b0011;
		RIGHT_SHIFT_A   = 4'b0100;
		ADD_W_CARRY		= 4'b0101;
		SUB_W_CARRY		= 4'b0110;
		ROTATE_R		= 4'b0111;
		SET_AND_FLAG	= 4'b1000;
		REVERSE_SUB		= 4'b1001;
		CMP_REG			= 4'b1010;
		CMP_NEG			= 4'b1011;
		OR				= 4'b1100;
		MULT 			= 4'b1101;
		BIT_CLEAR		= 4'b1110;
		NOT				= 4'b1111;
	} data_processing_code;

	typedef enum {FROM_REG, FROM_IMM, FROM_PC, FROM_SP, FROM_ACCUMULATOR} alu_input_source;

	typedef enum {FROM_ALU,FROM_MEMORY} reg_file_data_source;

	typedef enum {} alu_controller_signal;

	typedef enum {NO_MEM_WRITE = 0, MEM_WRITE} 				mem_write_signal;
	typedef enum {NO_MEM_READ = 0, MEM_READ} 				mem_read_signal;
	typedef enum {NO_REG_WRITE = 0, REG_WRITE} 				reg_file_write_sig;
	typedef enum {NO_STALL_PIPELINE = 0, STALL_PIPELINE}	pipeline_ctrl_sig;
	typedef enum {ADDR_FROM_INST, ADDR_FROM_CRL_UNIT}		reg_file_input_1_select;

`endif
