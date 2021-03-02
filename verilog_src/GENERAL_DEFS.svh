`ifndef GENERAL_DEFS_H
`define GENERAL_DEFS_H
//verilator lint_off UNUSED
	// size types
	parameter WORD 			= 32;
	parameter HALF_WORD 	= 16;
	parameter BYTE			= 8;
	parameter ADDR_WIDTH 	= 4;
	parameter SP_REG_NUM	= 13;
	// verilator lint_off UNUSED
	parameter LR_REG_NUM	= 14;
	// verilator lint_on UNUSED
	parameter PC_REG_NUM	= 15;

	typedef enum logic [5:0] {
		SHIFT_IMM		= 6'b00????,
		DATA_PROCESSING = 6'b010000,
		SPECIAL			= 6'b010001,
		LOAD_LITERAL	= 6'b01001?,
		LOAD_STORE_REG	= 6'b0101??,
		LOAD_STORE_IMM	= 6'b0110??,
		LOAD_STORE_BYTE = 6'b0111??,
		LOAD_STORE_HW	= 6'b1000??,
		LOAD_STORE_SP_R = 6'b1001??,
		GEN_PC_REL		= 6'b10100?,
		GEN_SP_REL		= 6'b10101?,
		MIS_16_BIT		= 6'b1011??,
		STORE_MULT_REG  = 6'b11000?,
		LOAD_MULT_REG	= 6'b11001?,
		COND_BRANCH		= 6'b1101??,
		UNCOND_BRANCH	= 6'b11100?
	} opcode;

	typedef struct packed {
		opcode op;
		logic [9:0] instruction_data;
	} instruction;

	// codes for shift instructions
	parameter LEFT_SHIFT_L_IM	= 	5'b000??;
	parameter RIGHT_SHIFT_L_IM 	=	5'b001??;
	parameter RIGHT_SHIFT_A_IM	=	5'b010??;
	parameter ADD_REG			=	5'b01100;
	parameter SUB_REG			=	5'b01101;
	parameter ADD_3_IMM			=	5'b01110;
	parameter SUB_3_IMM			=	5'b01111;
	parameter MOV_8_IMM			=	5'b100??;
	parameter CMP_8_IMM			=	5'b101??;
	parameter ADD_8_IMM			=	5'b110??;
	parameter SUB_8_IMM			=	5'b111??;

	// codes for data processing instuctions
	parameter AND				= 4'b0000;
	parameter XOR 				= 4'b0001;
	parameter LEFT_SHIFT_L		= 4'b0010;
	parameter RIGHT_SHIFT_L 	= 4'b0011;
	parameter RIGHT_SHIFT_A   	= 4'b0100;
	parameter ADD_W_CARRY		= 4'b0101;
	parameter SUB_W_CARRY		= 4'b0110;
	parameter ROTATE_R			= 4'b0111;
	parameter SET_AND_FLAG		= 4'b1000;
	parameter REVERSE_SUB		= 4'b1001;
	parameter CMP_REG			= 4'b1010;
	parameter CMP_NEG			= 4'b1011;
	parameter OR				= 4'b1100;
	parameter MULT 				= 4'b1101;
	parameter BIT_CLEAR			= 4'b1110;
	parameter NOT				= 4'b1111;

	// codes for special data instructions
	parameter ADD_REG_SPECIAL	= 4'b00??;
	parameter MOVE_REG_SPECIAL  = 4'b10??;
	parameter CMP_REG_SPECIAL	= 4'b011?;	//TODO: check if this is the only encoding of cmp register for special insturction

	// codes for misc 16 bit instructions
	parameter ADD_IMM_SP		= 7'b00000??;
	parameter SUB_IMM_SP		= 7'b00001??;
	parameter S_EXTEND_HW		= 7'b001000?;
	parameter S_EXTEND_BYTE 	= 7'b001001?;
	parameter UN_S_EXTEND_HW	= 7'b001010?;
	parameter UN_S_EXTEND_BYTE 	= 7'b001011?;
	parameter PUSH_MUL_REG		= 7'b010????;
	parameter BYTE_REV_W		= 7'b101000?;
	parameter BYTE_REV_P_HW		= 7'b101001?;
	parameter BYTE_REV_S_HW 	= 7'b101011?;
	parameter POP_MUL_REG		= 7'b110????;

	// codes for loads/stores
	parameter STORE_REG_IMM_OFFSET = 3'b0??;
	parameter LOAD_REG_IMM_OFFSET =  3'b1??;

	typedef enum logic [1:0] {FROM_REG, FROM_IMM,  
					FROM_ACCUMULATOR, FROM_ZERO} 						alu_input_source;
					
	typedef enum logic {FROM_ALU,FROM_MEMORY}							reg_file_data_source;
	typedef enum logic {NO_REG_WRITE = 0, REG_WRITE}					reg_file_write_sig;
	typedef enum logic {ADDR_FROM_INSTRUCTION, ADDR_FROM_CTRL_UNIT}		reg_addr_data_source;

	typedef enum logic {NO_IS_VALID = 0, IS_VALID = 1}					is_valid_sig;
	typedef enum logic {NO_MEM_WRITE = 0, MEM_WRITE}					mem_write_signal;
	typedef enum logic {NO_MEM_READ = 0, MEM_READ} 						mem_read_signal;
	typedef enum logic {NO_STALL_PIPELINE = 0, STALL_PIPELINE}			stall_pipeline_sig;
	typedef enum logic {NO_UPDATE_FLAG = 0, UPDATE_FLAG} 				update_flag_sig;
	typedef enum logic {SELECT_REG_2 = 0, SELECT_REG_3}					reg_2_reg_3_select_sig;
	typedef enum logic [1:0] {FORWARD_FROM_DECODE, 
							FORWARD_FROM_MEM, FORWARD_FROM_WB}			forwarding_data_source;

	typedef enum logic [4:0]{ALU_LEFT_SHIFT_L, ALU_RIGHT_SHIFT_L, 
		ALU_RIGHT_SHIFT_A, ALU_ADD, ALU_SUB, ALU_AND, ALU_OR, ALU_XOR,
		ALU_ROTATE_R, ALU_MULT, ALU_NOT, ALU_BIT_CLEAR, ALU_S_EXTEND_HW,
		ALU_S_EXTEND_BYTE, ALU_UN_S_EXTEND_HW, ALU_UN_S_EXTEND_BYTE, ALU_BYTE_REV_W,
		ALU_BYTE_REV_P_HW, ALU_BYTE_REV_S_HW}							alu_control_signal;

	typedef struct packed {
		logic negative_flag;
		logic zero_flag;
		logic carry_flag;
		logic overflow_flag;
	} status_register;
//verilator lint_on UNUSED
`endif
