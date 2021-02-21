`include "GENERAL_DEFS.svh"

function logic [ADDR_WIDTH-1:0] one_hot_to_bin(
                                                input logic [15:0] one_hot_i                  
                                              );
        logic [ADDR_WIDTH-1:0] reg_addr = '0;
        for (integer i = 0; i < 16; i++) begin
            if (one_hot_i[i])
                reg_addr = reg_addr | 4'(i);
        end 
        return reg_addr;
endfunction

function logic [15:0] priority_decode(
                                            input logic [15:0] reg_list
                                        );
        logic [15:0] decoder_signal;
        casez(reg_list)
            16'b????_????_????_???1:    decoder_signal = 16'b1;
            16'b????_????_????_??10:    decoder_signal = 16'b10;
            16'b????_????_????_?100:    decoder_signal = 16'b100;
            16'b????_????_????_1000:    decoder_signal = 16'b1000;

            16'b????_????_???1_0000:    decoder_signal = 16'b1_0000;
            16'b????_????_??10_0000:    decoder_signal = 16'b10_0000;
            16'b????_????_?100_0000:    decoder_signal = 16'b100_0000;
            16'b????_????_1000_0000:    decoder_signal = 16'b1000_0000;

            16'b????_???1_0000_0000:    decoder_signal = 16'b1_0000_0000;
            16'b????_??10_0000_0000:    decoder_signal = 16'b10_0000_0000;
            16'b????_?100_0000_0000:    decoder_signal = 16'b100_0000_0000;
            16'b????_1000_0000_0000:    decoder_signal = 16'b1000_0000_0000;

            16'b???1_0000_0000_0000:    decoder_signal = 16'b1_0000_0000_0000;
            16'b??10_0000_0000_0000:    decoder_signal = 16'b10_0000_0000_0000;
            16'b?100_0000_0000_0000:    decoder_signal = 16'b100_0000_0000_0000;
            16'b1000_0000_0000_0000:    decoder_signal = 16'b1000_0000_0000_0000;
            default: decoder_signal = 16'b0;
        endcase
        return decoder_signal;
endfunction

function logic [4:0] bit_count(
                                input logic [HALF_WORD-1:0] data_in
                                );
    logic [4:0] sum = '0;
    for (integer i = 0; i < HALF_WORD; i++) begin
        if (data_in[i])
            sum += 1; 
    end
    return sum;
endfunction

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
                        output stall_pipeline_sig       pipeline_ctrl_signal_o,
                        output logic [4:0]              accumulator_imm_o,
                        output logic [ADDR_WIDTH-1:0]   reg_file_addr_2_o,
                        output reg_file_addr_2_source   reg_file_addr_2_source_o
                        );

    localparam FULL_REG_LIST = 16'hFF_FF;

    localparam BASE_REG_NOT_IN_LIST = 1'b0;
    localparam BASE_REG_IN_LIST = 1'b1;

    logic [4:0] shift_code_internal;
    logic [3:0] data_processing_code_internal;

    // signals to deal with consecutive loads/stores
    logic [4:0] accumulator;
    logic [HALF_WORD-1:0] hold_counter;
    logic [HALF_WORD-1:0] reg_list_from_instruction;
    logic base_reg_in_list_status_sig;

    // signals to deal with pushing registers onto the stack
    logic [4:0] new_sp_offset;

    always_comb begin

        // extract signals from instruction
        shift_code_internal =           instruction_i[13:9];
        data_processing_code_internal = instruction_i[9:6];
        reg_list_from_instruction =     'x;

        // set defaults for output signals
        update_flag_o =             NO_UPDATE_FLAG; 
        mem_write_en_o =            NO_MEM_WRITE;
        mem_read_en_o  =            NO_MEM_READ;
        reg_write_en_o =            NO_REG_WRITE;
        reg_file_data_source_o =    FROM_ALU;
        alu_input_1_select_o =      FROM_REG;
        alu_input_2_select_o =      FROM_REG;
        alu_control_signal_o =      ALU_ADD;
        pipeline_ctrl_signal_o =    NO_STALL_PIPELINE;
        accumulator_imm_o =         'x;
        reg_file_addr_2_o =         'x;
        reg_file_addr_2_source_o =  ADDR_FROM_INSTRUCTION;
        new_sp_offset =             'x;

       casez(instruction_i.op)
            SHIFT_IMM: begin
                update_flag_o = UPDATE_FLAG;
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
                update_flag_o = UPDATE_FLAG;
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
            // TODO: check MOV (register) when using the SP. Need to branch in that case?
            SPECIAL: begin
                case(instruction_i[9:6])

                    default:    ;
                endcase
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
            GEN_PC_REL, 
            GEN_SP_REL: begin
                reg_write_en_o =       REG_WRITE;
                alu_input_2_select_o = FROM_IMM;
            end
            // TODO: implement misc 16 bit
            MIS_16_BIT: begin
                update_flag_o = NO_UPDATE_FLAG;
                casez(instruction_i[11:5])
                    ADD_IMM_SP:         alu_control_signal_o = ALU_ADD; 
                    SUB_IMM_SP:         alu_control_signal_o = ALU_SUB;
                    S_EXTEND_HW:        alu_control_signal_o = ALU_S_EXTEND_HW; 
                    S_EXTEND_BYTE:      alu_control_signal_o = ALU_S_EXTEND_BYTE;
                    UN_S_EXTEND_HW:     alu_control_signal_o = ALU_UN_S_EXTEND_HW;
                    UN_S_EXTEND_BYTE:   alu_control_signal_o = ALU_UN_S_EXTEND_BYTE;
                    BYTE_REV_W:         alu_control_signal_o = ALU_BYTE_REV_W;
                    BYTE_REV_P_HW:      alu_control_signal_o = ALU_BYTE_REV_P_HW;
                    BYTE_REV_S_HW:      alu_control_signal_o = ALU_BYTE_REV_S_HW;
                    PUSH_MUL_REG: begin
                        alu_control_signal_o =      ALU_SUB;
                        reg_list_from_instruction = 16'({instruction_i[8],6'b0,instruction_i[7:0]});
                        new_sp_offset =             4*bit_count(reg_list_from_instruction);
                        pipeline_ctrl_signal_o =    (bit_count(reg_list_from_instruction & hold_counter) != 5'b0);
                        accumulator_imm_o =         new_sp_offset - 4*accumulator;
                        reg_file_addr_2_source_o =  ADDR_FROM_CTRL_UNIT;
                        alu_input_2_select_o =      FROM_ACCUMULATOR;
                        mem_write_en_o =            pipeline_ctrl_signal_o;
                        if (pipeline_ctrl_signal_o) 
                            reg_file_addr_2_o =     one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter));
                        else begin
                            reg_write_en_o =        REG_WRITE;
                            reg_file_addr_2_o =     SP_REG_NUM;
                            accumulator_imm_o =     new_sp_offset;
                        end
                    end
                    // TODO: implement branching on POP registers if PC is one of the popped registers
                    POP_MULT_REG: begin
                        reg_list_from_instruction = {instruction_i[8],7'b0,instruction_i[7:0]};
                        pipeline_ctrl_signal_o =    (bit_count(reg_list_from_instruction & hold_counter) != 5'b0);
                        accumulator_imm_o =         4*accumulator;
                        reg_file_addr_2_source_o =  ADDR_FROM_CTRL_UNIT;
                        alu_input_2_select_o =      FROM_ACCUMULATOR;
                        reg_write_en_o =            REG_WRITE;
                        if (pipeline_ctrl_signal_o) 
                            reg_file_addr_2_o =     one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter));
                        else
                            reg_file_addr_2_o =     SP_REG_NUM; 
                            
                    end
                    default: ;
                endcase
            end
            STORE_MULT_REG: begin
                reg_list_from_instruction = 16'(instruction_i[7:0]);
                pipeline_ctrl_signal_o =    (bit_count(reg_list_from_instruction & hold_counter) != 5'b0);
                accumulator_imm_o =         4*accumulator;
                reg_file_addr_2_source_o =  ADDR_FROM_CTRL_UNIT;
                alu_input_2_select_o =      FROM_ACCUMULATOR;
                mem_write_en_o =            pipeline_ctrl_signal_o;
                reg_write_en_o =            ~pipeline_ctrl_signal_o;
                if (pipeline_ctrl_signal_o) 
                    reg_file_addr_2_o =     one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter));
                else
                    reg_file_addr_2_o =     4'(instruction_i[10:8]);
            end
            LOAD_MULT_REG: begin
                reg_list_from_instruction = 16'(instruction_i[7:0]);
                pipeline_ctrl_signal_o =    (bit_count(reg_list_from_instruction & hold_counter) != 5'b0);
                accumulator_imm_o =         4*accumulator;
                reg_file_addr_2_source_o =  ADDR_FROM_CTRL_UNIT;
                alu_input_2_select_o =      FROM_ACCUMULATOR;
                if (pipeline_ctrl_signal_o) begin
                    reg_file_addr_2_o =     one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter));
                    reg_write_en_o =        REG_WRITE;
                end
                else begin
                    reg_file_addr_2_o =     4'(instruction_i[10:8]);
                    reg_write_en_o =        (base_reg_in_list_status_sig == BASE_REG_NOT_IN_LIST);
                end
            end
            COND_BRANCH: ;
            UNCOND_BRANCH: ;
            default: ;
       endcase 
    end

    // logic for updating accumulator
    always_ff @(posedge clk_i)begin
        if (reset_i || ~pipeline_ctrl_signal_o) 
            accumulator <= 5'b0;
        else
            accumulator <= accumulator + 1'b1;
    end

    // logic for updating hold counter
    always_ff @(posedge clk_i) begin
        if (reset_i | ~pipeline_ctrl_signal_o)
            hold_counter <= FULL_REG_LIST;
        else 
            // AND'ing the reg list and hold counter ensures that the bit corresponding to the lowest 
            // unsaved register is cleared from the hold counter. 
            hold_counter <= hold_counter & ~priority_decode(reg_list_from_instruction & hold_counter);
    end

    // logic for updating mult_load_store_base_reg status signal
    always_ff @(posedge clk_i) begin
        if (reset_i | ~pipeline_ctrl_signal_o) 
            base_reg_in_list_status_sig <= BASE_REG_NOT_IN_LIST;
        else if (base_reg_in_list_status_sig == BASE_REG_NOT_IN_LIST) begin
            if (one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter)) == 4'(instruction_i[10:8]))
                base_reg_in_list_status_sig <= BASE_REG_IN_LIST;
        end
    end
endmodule