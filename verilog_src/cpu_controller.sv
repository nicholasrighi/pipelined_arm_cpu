`include "GENERAL_DEFS.svh"

module cpu_controller(
                        input                           clk_i,
                        input                           reset_i,
                        input instruction               instruction_i,

                        output update_flag_sig          update_flag_o,
                        output mem_write_signal         mem_write_en_o,
                        output mem_read_signal          mem_read_en_o,
                        output reg_file_write_sig       reg_write_en_o,
                        output reg_file_data_source     reg_file_data_source_o,
                        output alu_input_source         alu_input_1_select_o,
                        output alu_input_source         alu_input_2_select_o,
                        output alu_control_signal       alu_control_signal_o,
                        output pipeline_ctrl_sig        pipeline_ctrl_signal_o,
                        output reg_file_addr_1_source   reg_file_addr_1_source_o,
                        output logic [ADDR_WIDTH-1:0]   mult_access_reg_file_1_addr_o,
                        output logic [ADDR_WIDTH-1:0]   mult_access_dest_reg_addr,
                        output logic [4:0]              accumulator_imm_o
                        );


    localparam MAX_COUNTER_VALUE = 3'd7;
    localparam INC_COUNTER = 1'b1;
    localparam NO_INC_COUNTER = 1'b0;

    logic [4:0] shift_code_internal;
    logic [3:0] data_processing_code_internal;

    // signals to deal with consecutive loads/stores
    logic inc_load_store_counter;
    logic [2:0] load_store_counter;
    logic [4:0] accumulator;
    logic [7:0] reg_list;

    always_comb begin

        // extract signals from instruction
        shift_code_internal =           instruction_i[13:9];
        data_processing_code_internal = instruction_i[9:6];
        reg_list =                      instruction_i[7:0];

        // set defaults for output signals
        update_flag_o =             UPDATE_FLAG;
        alu_input_1_select_o =      FROM_REG;
        alu_input_2_select_o =      FROM_REG;
        reg_file_data_source_o =    FROM_ALU;
        mem_write_en_o =            NO_MEM_WRITE;
        mem_read_en_o  =            NO_MEM_READ;
        reg_write_en_o =            NO_REG_WRITE;
        pipeline_ctrl_signal_o =    NO_STALL_PIPELINE;
        inc_load_store_counter =    NO_INC_COUNTER;
        reg_file_addr_1_source_o =  ADDR_FROM_INSTRUCTION;
        alu_control_signal_o =      ALU_ADD;

        // signals for multi cycle load/stores
        // TODO: check if this 0 bit concationation is correct
        mult_access_reg_file_1_addr_o = 4'(load_store_counter);
        mult_access_dest_reg_addr     = 4'(instruction_i[10:8]);

        // accumulator always stores the number of register that have been written to 
        // memory. Since each register is 4 bytes, the offset from the base register is 
        // 4x the accumulator value, so left shift by 2 gives us the correct offset
        accumulator_imm_o = accumulator << 2;

       casez(instruction_i.op)
            SHIFT_IMM: begin
                reg_write_en_o = REG_WRITE;
                casez(shift_code_internal)
                    LEFT_SHIFT_L_IM: begin
                                alu_control_signal_o = ALU_LEFT_SHIFT_L;
                                alu_input_2_select_o = FROM_IMM;
                    end                      
                    RIGHT_SHIFT_L_IM:   begin 
                                alu_control_signal_o = ALU_RIGHT_SHIFT_L;
                                alu_input_2_select_o = FROM_IMM;
                    end
                    RIGHT_SHIFT_A_IM:   begin
                                alu_control_signal_o = ALU_RIGHT_SHIFT_A;
                                alu_input_2_select_o = FROM_IMM;
                    end
                    ADD_REG:    alu_control_signal_o = ALU_ADD;
                    SUB_REG:    alu_control_signal_o = ALU_SUB;
                    ADD_3_IMM, ADD_8_IMM: begin
                                alu_input_2_select_o = FROM_IMM;
                    end
                    SUB_3_IMM, SUB_8_IMM: begin
                                alu_control_signal_o = ALU_SUB;
                                alu_input_2_select_o = FROM_IMM;
                    end                    
                    MOV_8_IMM: begin
                                alu_control_signal_o = ALU_ADD;
                                alu_input_1_select_o = FROM_ZERO;
                                alu_input_2_select_o = FROM_IMM;
                    end
                    CMP_8_IMM: begin
                                alu_input_2_select_o = FROM_IMM;
                                alu_control_signal_o = ALU_SUB;
                                reg_write_en_o = NO_REG_WRITE;
                    end       
                    default: ;  // this is just here to ensure that there are no latches
                endcase
            end
            DATA_PROCESSING: begin
                reg_write_en_o = REG_WRITE;
                casez(data_processing_code_internal)
                    AND:            alu_control_signal_o = ALU_AND;
                    XOR:            alu_control_signal_o = ALU_XOR;
                    LEFT_SHIFT_L:   alu_control_signal_o = ALU_LEFT_SHIFT_L;
                    RIGHT_SHIFT_L:  alu_control_signal_o = ALU_RIGHT_SHIFT_L;
                    RIGHT_SHIFT_A:  alu_control_signal_o = ALU_RIGHT_SHIFT_A;
                    ADD_W_CARRY:    alu_control_signal_o = ALU_ADD;
                    SUB_W_CARRY:    alu_control_signal_o = ALU_SUB;
                    ROTATE_R:       alu_control_signal_o = ALU_ROTATE_R;
                    SET_AND_FLAG:   begin
                                    alu_control_signal_o = ALU_AND;
                                    reg_write_en_o =       NO_REG_WRITE;
                    end
                    REVERSE_SUB: begin
                                    alu_control_signal_o = ALU_SUB; 
                                    alu_input_1_select_o = FROM_ZERO;
                    end
                    CMP_REG: begin
                                    alu_control_signal_o = ALU_SUB;
                                    reg_write_en_o =       NO_REG_WRITE;
                    end
                    CMP_NEG: begin
                                    alu_control_signal_o = ALU_ADD; 
                                    reg_write_en_o =       NO_REG_WRITE;
                    end
                    OR:             alu_control_signal_o = ALU_OR;
                    MULT:           alu_control_signal_o = ALU_MULT;
                    BIT_CLEAR:      alu_control_signal_o = ALU_BIT_CLEAR;
                    NOT:            alu_control_signal_o = ALU_NOT;
                    default: ;
                endcase
            end
            // TODO: implement special instructions
            SPECIAL: begin
            end
            LOAD_LITERAL: begin
                reg_write_en_o =       REG_WRITE;
                alu_input_2_select_o = FROM_IMM;
            end
            LOAD_STORE_REG: begin
                if (instruction_i[11] || instruction_i[10:9] == 2'b11)
                    reg_write_en_o =   REG_WRITE;
            end
            LOAD_STORE_IMM, 
            LOAD_STORE_BYTE,
            LOAD_STORE_HW,
            LOAD_STORE_SP_R: begin
                alu_input_2_select_o = FROM_IMM;
                if (instruction_i[11])
                    reg_write_en_o =   REG_WRITE; 
            end
            GEN_PC_REL: begin
                alu_input_2_select_o = FROM_IMM;
            end
            GEN_SP_REL: begin
                alu_input_2_select_o = FROM_IMM;
            end
            MIS_16_BIT: ;
            STORE_MULT_REG: begin
                alu_input_2_select_o =      FROM_ACCUMULATOR;
                mem_write_en_o       =      reg_list[load_store_counter];
                reg_file_addr_1_source_o =  ADDR_FROM_CTRL_UNIT;
                // need to stall since there might be more registers to process
                if (load_store_counter != MAX_COUNTER_VALUE) begin
                    pipeline_ctrl_signal_o = STALL_PIPELINE;
                    inc_load_store_counter = INC_COUNTER;
                end
            end
            LOAD_MULT_REG: begin
                alu_input_2_select_o    = FROM_ACCUMULATOR;
                reg_write_en_o          = reg_list[load_store_counter];
                reg_file_addr_1_source_o= ADDR_FROM_CTRL_UNIT;
                // need to stall since there might be more registers to process
                if (load_store_counter != MAX_COUNTER_VALUE) begin
                    pipeline_ctrl_signal_o = STALL_PIPELINE;
                    inc_load_store_counter = NO_INC_COUNTER;
                end
            end
            COND_BRANCH: ;
            UNCOND_BRANCH: ;
            // there are 3 opcodes (11101, 11110, 11111) that indicate that the current instruction
            // is the first part of a 32 bit instruction. In that case we need to insert a bubble,
            // which the default values for the control signal already do
            default: ;
       endcase 
    end

    always_ff @(posedge clk_i) begin
        if (reset_i || ~inc_load_store_counter)
            load_store_counter <= 3'b0;
        else
            load_store_counter <= load_store_counter + 1'b1;
    end

    always_ff @(posedge clk_i)begin
        if (reset_i || ~inc_load_store_counter)
            accumulator <= 5'b0;
        else if (reg_list[load_store_counter])
            accumulator <= accumulator + 1'b1;
    end

endmodule