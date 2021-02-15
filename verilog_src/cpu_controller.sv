`include "GENERAL_DEFS.svh"

module cpu_controller(
                        input                           clk_i,
                        input                           reset_i,
                        input instruction               instruction_i,

                        output mem_write_signal         mem_write_en_o,
                        output mem_read_signal          mem_read_en_o,
                        output reg_file_write_sig       reg_write_en_o,
                        output reg_file_data_source     reg_file_data_source_o,
                        output alu_input_source         alu_input_1_select_o,
                        output alu_input_source         alu_input_2_select_o,
                        output pipeline_ctrl_signal     pipeline_ctrl_signal_o,
                        output reg_file_input_1_select  reg_file_input_1_select_o,
                        output logic [3:0]              reg_file_1_addr_o,
                        output logic [4:0]              accumulator_value_o
                        );
    
    localparam MAX_COUNTER_VALUE = 3'd7;
    localparam INC_COUNTER = 1'b1;
    localparam NO_INC_COUNTER = 1'b0;


    shift_code shift_code_internal;
    data_processing_code data_processing_code_internal;

    // signals to deal with consecutive loads/stores
    logic inc_load_store_counter;
    logic [2:0] load_store_counter;
    logic [7:0] reg_list;

    always_comb begin

        // extract signals from instruction
        shift_code_internal =           instruction_i[13:9];
        data_processing_code_internal = instruction_i[9:6];
        reg_list =                      instruction_i[7:0];

        // set defaults for output signals
        alu_input_1_select_o =      FROM_REG;
        alu_input_2_select_o =      FROM_REG;
        reg_file_data_source_o =    FROM_ALU;
        mem_write_en_o =            NO_MEM_WRITE;
        mem_read_en_o  =            NO_MEM_READ;
        reg_write_en_o =            NO_REG_WRITE;
        pipeline_ctrl_signal_o =    NO_STALL_PIPELINE;
        inc_load_store_counter =    NO_INC_COUNTER;

        reg_file_1_addr_o = load_store_counter;

       case(instruction_i.opcode)
		SHIFT_IMM: begin
            if (shift_code_internal != ADD_REG && shift_code_internal != SUB_REG)
                alu_input_2_select_o = FROM_IMM;
        end
		DATA_PROCESSING: begin
            if (shift_code_internal == REVERSE_SUB)
                alu_input_2_select_o = FROM_IMM;
        end
		SPECIAL:
		LOAD_LITERAL: begin
            alu_input_1_select_o = FROM_PC;
            alu_input_2_select_o = FROM_IMM;
        end
        LOAD_OFF_IMM, LOAD_SPECIAL: alu_input_2_select_o = FROM_IMM;
		GEN_PC_REL: begin
            alu_input_1_select_o = FROM_PC;
            alu_input_2_select_o = FROM_IMM;
        end
		GEN_SP_REL: begin
            alu_input_1_select_o = FROM_SP;
            alu_input_2_select_o = FROM_IMM;
        end
		MIS_16_BIT:                 
		STORE_MULT_REG: begin
            alu_input_2_select_o =      FROM_ACCUMULATOR;
            mem_write_en_o       =      reg_list[load_store_counter];
            reg_file_input_1_select_o = ADDR_FROM_CTRL_UNIT;
            // need to stall since there might be more registers to process
            if (load_store_counter != MAX_COUNTER_VALUE) begin
                pipeline_ctrl_signal_o = STALL_PIPELINE;
                inc_load_store_counter = INC_COUNTER;
            end
            
        end
		LOAD_MULT_REG: begin
            alu_input_2_select_o =      FROM_ACCUMULATOR;
            reg_file_write_en_o       = reg_list[load_store_counter];
            reg_file_input_1_select_o = ADDR_FROM_CTRL_UNIT;
            // need to stall since there might be more registers to process
            if (load_store_counter != MAX_COUNTER_VALUE) begin
                pipeline_ctrl_signal_o = STALL_PIPELINE;
                inc_load_store_counter = NO_INC_COUNTER;
            end
        end
		COND_BRANCH:
		UNCOND_BRANCH:
        // there are 3 opcodes (11101, 11110, 11111) that indicate that the current instruction
        // is the first part of a 32 bit instruction. In that case we need to insert a bubble,
        // which the default values for the control signal already do
        default: ;
       endcase 
    end


    always_ff @(posedge clk) begin
        if (reset_i || ~inc_load_store_counter)
            load_store_counter <= 3'b0;
        else
            load_store_counter <= load_store_counter + 1'1;
    end

endmodule