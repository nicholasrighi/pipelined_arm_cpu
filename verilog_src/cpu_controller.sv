`include "GENERAL_DEFS.svh"

function automatic [HALF_WORD-1:0] bit_reverse(
                                            input logic [HALF_WORD-1:0] data_i
                                          );
        logic [HALF_WORD-1:0] reversed_half_word;
        for (integer i = 0; i < HALF_WORD; i++) begin
           if (i < 8)
            reversed_half_word[i] = data_i[7-i];
           else
            reversed_half_word[i] = 1'b0;
        end
        return reversed_half_word;
endfunction

function automatic [ADDR_WIDTH-1:0] one_hot_to_bin(
                                                input logic [HALF_WORD-1:0] one_hot_i                  
                                              );
        logic [ADDR_WIDTH-1:0] reg_addr = '0;
        for (integer i = 0; i < HALF_WORD; i++) begin
            if (one_hot_i[i])
                reg_addr = reg_addr | 4'(i);
        end 
        return reg_addr;
endfunction

function automatic [HALF_WORD-1:0] reverse_priority_decode(
                                                        input logic [BYTE-1:0] data_i

                                                  );
    logic [HALF_WORD-1:0] decoder_signal;
    casez(data_i)
        8'b1???_????:   decoder_signal = 16'b1000_0000;
        8'b01??_????:   decoder_signal = 16'b0100_0000;
        8'b001?_????:   decoder_signal = 16'b0010_0000;
        8'b0001_????:   decoder_signal = 16'b0001_0000;

        8'b0000_1???:   decoder_signal = 16'b0000_1000;
        8'b0000_01??:   decoder_signal = 16'b0000_0100;
        8'b0000_001?:   decoder_signal = 16'b0000_0010;
        8'b0000_0001:   decoder_signal = 16'b0000_0001;
        default: decoder_signal = 16'b0;   
    endcase
    return decoder_signal;

endfunction

function automatic [15:0] priority_decode(
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

function automatic [4:0] bit_count(
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
                        output is_valid_sig             is_valid_o,
                        output mem_write_signal         mem_write_en_o,
                        output mem_read_signal          mem_read_en_o,
                        output reg_file_write_sig       reg_write_en_o,
                        output reg_file_data_source     reg_file_data_source_o,
                        output alu_input_source         alu_input_1_select_o,
                        output alu_input_source         alu_input_2_select_o,
                        output alu_control_signal       alu_control_signal_o,
                        output stall_pipeline_sig       pipeline_ctrl_signal_o,
                        output reg_addr_data_source     reg_file_addr_2_source_o,
                        output reg_addr_data_source     reg_dest_addr_source_o,
                        output reg_2_reg_3_select_sig   reg_2_reg_3_select_sig_o,
                        output logic [WORD-1:0]         accumulator_imm_o,
                        output logic [ADDR_WIDTH-1:0]   reg_file_addr_o
                        );

    localparam FULL_REG_LIST = 16'hFF_FF;
    localparam NO_REV_LOAD_COUNTER = 1'b0;
    localparam REV_LOAD_COUNTER = 1'b1;

    localparam BASE_REG_NOT_IN_LIST = 1'b0;
    localparam BASE_REG_IN_LIST = 1'b1;

    // signals to deal with branch and link
    branch_link_status stored_branch_link;
    branch_link_status next_branch_link;

    logic [4:0] shift_code_internal;
    logic [3:0] data_processing_code_internal;

    // signals to deal with consecutive loads/stores
    logic reverse_order_hold_counter;
    logic [4:0] accumulator;
    logic [HALF_WORD-1:0] hold_counter;
    logic [HALF_WORD-1:0] reg_list_from_instruction;
    logic base_reg_in_list_status_sig;

    // signals to deal with pushing registers onto the stack
    logic [4:0] new_sp_offset;
    // TODO. Check if we overwrite all flags, or just some of them
    // TODO. Check all instructions that only set flags (there's test, cmp, etc, i forget them all at this moment)
    always_comb begin

        // extract signals from instruction
        shift_code_internal =           instruction_i[13:9];
        data_processing_code_internal = instruction_i[9:6];
        reg_list_from_instruction =     'x;

        // set defaults for output signals
        next_branch_link =          NO_STORE_BRANCH;
        is_valid_o =                IS_VALID;
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
        reg_file_addr_o =           'x;
        reg_file_addr_2_source_o =  ADDR_FROM_INSTRUCTION;
        reg_dest_addr_source_o  =   ADDR_FROM_INSTRUCTION;
        new_sp_offset =             'x;
        reg_2_reg_3_select_sig_o =  SELECT_REG_2;
        reverse_order_hold_counter = NO_REV_LOAD_COUNTER;

       casez(instruction_i.op)
            SHIFT_IMM: begin
                // almost all of these instructions update the flags and write to registers,
                // so putting these here makes code easier to understand
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
                    default: ;
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
                    ADD_W_CARRY:    alu_control_signal_o = ALU_ADD_W_CARRY;
                    SUB_W_CARRY:    alu_control_signal_o = ALU_SUB_W_CARRY;
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
            SPECIAL: begin
                casez(instruction_i[9:6])
                    ADD_REG_SPECIAL: begin
                        alu_control_signal_o = ALU_ADD;
                        // If dest reg is the PC then writing has no effect, since we never read the PC value from the register file, we 
                        // always pass it through the decode stage and read the raw PC value (so the data in R15 is never used)
                        reg_write_en_o       = REG_WRITE;
                    end
                    MOVE_REG_SPECIAL: begin
                        alu_control_signal_o = ALU_ADD;
                        // once again if the dest reg is PC then we can write to the reg file since we never read the value of the PC from the reg file
                        // we only read the value of the PC from the decode pass through
                        reg_write_en_o       = REG_WRITE;
                        alu_input_2_select_o = FROM_ZERO;
                    end
                    CMP_REG_SPECIAL: begin
                        alu_control_signal_o  = ALU_SUB;
                        update_flag_o         = UPDATE_FLAG;
                    end
                    BRANCH_LINK_EXCH: begin
                       alu_control_signal_o =  ALU_SUB; 
                       alu_input_1_select_o =  FROM_PC;
                       alu_input_2_select_o =  FROM_TWO;
                       reg_write_en_o =        REG_WRITE;
                    end
                    BRANCH_EXCH: ;
                    default:    ;
                endcase
            end
            LOAD_LITERAL: begin
                mem_read_en_o =        MEM_READ;
                reg_write_en_o =       REG_WRITE;
                alu_input_1_select_o = FROM_PC_ALIGNED;
                alu_input_2_select_o = FROM_IMM;
            end
            LOAD_STORE_REG: begin
                reg_file_data_source_o = FROM_MEMORY;
                if (instruction_i[11] || (instruction_i[10:9] == 2'b11)) begin 
                    mem_read_en_o =          MEM_READ;
                    reg_write_en_o =         REG_WRITE;
                end
                else begin
                    mem_write_en_o =            MEM_WRITE;
                    reg_2_reg_3_select_sig_o =  SELECT_REG_3;
                end
            end
            LOAD_STORE_IMM, 
            LOAD_STORE_BYTE,
            LOAD_STORE_HW,
            LOAD_STORE_SP_R: begin
                alu_input_2_select_o =   FROM_IMM;
                reg_file_data_source_o = FROM_MEMORY;
                if (instruction_i[11]) begin
                    reg_write_en_o =     REG_WRITE; 
                    mem_read_en_o =      MEM_READ;
                end
                else 
                    mem_write_en_o =     MEM_WRITE;
            end
            GEN_PC_REL: begin
                reg_write_en_o =       REG_WRITE;
                alu_input_1_select_o = FROM_PC_ALIGNED;
                alu_input_2_select_o = FROM_IMM;
            end
            GEN_SP_REL: begin
                reg_write_en_o =       REG_WRITE;
                alu_input_2_select_o = FROM_IMM;
            end
            MIS_16_BIT: begin
                update_flag_o = NO_UPDATE_FLAG;
                reg_write_en_o = REG_WRITE;
                casez(instruction_i[11:5])
                    ADD_IMM_SP: begin        
                        alu_control_signal_o = ALU_ADD; 
                        alu_input_2_select_o = FROM_IMM;
                    end
                    SUB_IMM_SP: begin
                        alu_control_signal_o = ALU_SUB;
                        alu_input_2_select_o = FROM_IMM;
                    end
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
                        accumulator_imm_o =         32'(new_sp_offset)- 4*accumulator;
                        reg_file_addr_2_source_o =  ADDR_FROM_CTRL_UNIT;
                        alu_input_2_select_o =      FROM_ACCUMULATOR;
                        mem_write_en_o =            pipeline_ctrl_signal_o;
                        if (pipeline_ctrl_signal_o) begin
                            reg_write_en_o =        NO_REG_WRITE;
                            reg_file_addr_o =       one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter));
                        end
                        else begin
                            reg_write_en_o =        REG_WRITE;
                            reg_file_addr_o =       SP_REG_NUM;
                            accumulator_imm_o =     32'(new_sp_offset);
                        end
                    end
                    // TODO: implement branching on POP registers if PC is one of the popped registers
                    // See the note on LOAD_MULTIPLE_REG for an explination of why read_mem isn't asserted 
                    // for this instruction
                    POP_MUL_REG: begin
                        reg_list_from_instruction = {instruction_i[8],7'b0,instruction_i[7:0]};
                        // once the pipeline_ctrl signal goes low, we know that we've 
                        pipeline_ctrl_signal_o =    (bit_count(reg_list_from_instruction & hold_counter) != 5'b0);
                        accumulator_imm_o =         4*accumulator;
                        reg_dest_addr_source_o =    ADDR_FROM_CTRL_UNIT;
                        alu_input_2_select_o =      FROM_ACCUMULATOR;
                        if (pipeline_ctrl_signal_o) begin
                            reg_write_en_o =         REG_WRITE;
                            reg_file_data_source_o = FROM_MEMORY;
                            reg_file_addr_o =        one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter));
                        end
                        else begin
                            reg_file_data_source_o = FROM_ALU;
                            reg_file_addr_o =        SP_REG_NUM; 
                        end
                    end
                    default: ;
                endcase
            end
            STORE_MULT_REG: begin
                reg_list_from_instruction = 16'(instruction_i[7:0]);
                pipeline_ctrl_signal_o =    (bit_count(reg_list_from_instruction & hold_counter) != 5'b0);
                accumulator_imm_o =         4*accumulator;
                alu_input_2_select_o =      FROM_ACCUMULATOR;
                mem_write_en_o =            pipeline_ctrl_signal_o;
                reg_write_en_o =            ~pipeline_ctrl_signal_o;
                if (pipeline_ctrl_signal_o) begin 
                    reg_file_addr_o =       one_hot_to_bin(priority_decode(reg_list_from_instruction & hold_counter));
                    reg_file_addr_2_source_o =  ADDR_FROM_CTRL_UNIT;
                end
                else begin
                    reg_file_addr_o =       4'(instruction_i[10:8]);
                    reg_dest_addr_source_o = ADDR_FROM_CTRL_UNIT;
                end
            end
            // LDM always has a final step after the reigster list has been loaded where it checks if the base
            // register needs to be updated. Since this step occurs there's no need to assert mem read, since
            // the last register to be loaded will be in the write back stage when the next instruction is in the 
            // execution stage (since the check for updating the base register will be in the memory stage, and fills
            // the purpose of the delay slot for loading + using data from that load). This also applies to the POP
            // instruction for the same reason
            LOAD_MULT_REG: begin
                reg_file_data_source_o =    FROM_MEMORY;
                reverse_order_hold_counter = REV_LOAD_COUNTER;
                reg_list_from_instruction = 16'(instruction_i[7:0]);
                new_sp_offset =             4*(bit_count(16'(instruction_i[7:0])) - 1'b1);
                pipeline_ctrl_signal_o =    (bit_count(reg_list_from_instruction & hold_counter) != 5'b0);
                accumulator_imm_o =         32'(new_sp_offset)-4*accumulator;
                reg_dest_addr_source_o =    ADDR_FROM_CTRL_UNIT;
                alu_input_2_select_o =      FROM_ACCUMULATOR;
                if (pipeline_ctrl_signal_o) begin
                    reg_file_addr_o =       one_hot_to_bin(reverse_priority_decode(reg_list_from_instruction[7:0] & hold_counter[7:0]));
                    reg_write_en_o =        REG_WRITE;
                end
                else begin
                    reg_file_addr_o =       4'(instruction_i[10:8]);
                    reg_write_en_o =        (base_reg_in_list_status_sig == BASE_REG_NOT_IN_LIST);
                    accumulator_imm_o =     4*bit_count(16'(instruction_i[7:0]));
                    reg_file_data_source_o = FROM_ALU;
                end
            end
            COND_BRANCH: ;
            UNCOND_BRANCH: ;
            TWO_WORD_INST_1,
            TWO_WORD_INST_2,
            TWO_WORD_INST_3: begin
               if (stored_branch_link == NO_STORE_BRANCH)
                    next_branch_link = STORE_BRANCH;
               if (stored_branch_link == STORE_BRANCH) begin
                    reg_write_en_o =       REG_WRITE;
                    alu_control_signal_o = ALU_SUB; 
                    alu_input_1_select_o = FROM_PC;
                    // since the PC points to the middle of the 32 bit instruction, the pc the execution
                    // block uses is actually 2 bytes ahead of the pc we want. So we need to subtract 
                    // 2 from the pc in order to create the correct value
                    alu_input_2_select_o = FROM_TWO;
               end
            end
            default: is_valid_o = NO_IS_VALID;
       endcase 
    end

    always_ff @(posedge clk_i) begin
       if (reset_i)
            stored_branch_link <= NO_STORE_BRANCH;
       else
            stored_branch_link <= next_branch_link;
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
        else if (reverse_order_hold_counter == NO_REV_LOAD_COUNTER)
            // AND'ing the reg list and hold counter ensures that the bit corresponding to the lowest 
            // unsaved register is cleared from the hold counter. 
            hold_counter <= hold_counter & ~priority_decode(reg_list_from_instruction & hold_counter);
        else
            hold_counter <= hold_counter & ~reverse_priority_decode(reg_list_from_instruction[7:0] & hold_counter[7:0]);
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