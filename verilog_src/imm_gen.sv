`include "GENERAL_DEFS.svh"

module imm_gen(
                    input logic         clk_i,
                    input instruction   instruction_i,

                    output logic [WORD-1:0] immediate_value_o 
              );

    opcode op;
    logic J_1;
    logic J_2;
    logic S;
    logic [10:0] stored_immediate;
    logic [9:0]  current_immediate;

    // this is used for 32 bit instructions, since those require saving the 
    // first 16 bits of the instruction to determine the full behavior
    // verilator lint_off UNUSED
    logic [HALF_WORD-1:0] stored_instruction;
    // verilator lint_on UNUSED

    always_comb begin

        // extract fields from current instruction
        op =                instruction_i[15:10];
        current_immediate = instruction_i[9:0];
        S  =                instruction_i[10];

        // extract fields from stored instruction
        stored_immediate =  stored_instruction[10:0];
        J_1 =               stored_instruction[13];
        J_2 =               stored_instruction[11];

        casez(op)
            SHIFT_IMM: begin
                casez(instruction_i[13:9])
                    LEFT_SHIFT_L_IM, 
                    RIGHT_SHIFT_L_IM,    
                    RIGHT_SHIFT_A_IM:     immediate_value_o = 32'(instruction_i[10:6]);
                    ADD_3_IMM, SUB_3_IMM: immediate_value_o = 32'(instruction_i[8:6]);
                    ADD_8_IMM, SUB_8_IMM, 
                    MOV_8_IMM, CMP_8_IMM: immediate_value_o = 32'(instruction_i[7:0]);
                    default: immediate_value_o = 'x;
                endcase    
            end
            DATA_PROCESSING: begin
                casez(instruction_i[9:6])
                    REVERSE_SUB: immediate_value_o = 32'b0;
                    default: immediate_value_o = 'x;
                endcase
            end
            LOAD_LITERAL:       immediate_value_o = 32'({instruction_i[7:0], 2'b0});
            LOAD_STORE_IMM:     immediate_value_o = 32'({instruction_i[10:6],2'b0});
            LOAD_STORE_BYTE:    immediate_value_o = 32'(instruction_i[10:6]);
            LOAD_STORE_HW:      immediate_value_o = 32'({instruction_i[10:6],1'b0});
            LOAD_STORE_SP_R:    immediate_value_o = 32'({instruction_i[7:0],2'b0});
            GEN_PC_REL, 
            GEN_SP_REL:         immediate_value_o = 32'({instruction_i[7:0], 2'b0});
            MIS_16_BIT: begin
                casez(instruction_i[11:5])
                    ADD_IMM_SP, SUB_IMM_SP: immediate_value_o = 32'({instruction_i[6:0], 2'b0});
                    default:    immediate_value_o = 'x;
                endcase
            end
            // TODO: Fix this SPECIAL case, it's wrong, should be some branch instruction
            SPECIAL: immediate_value_o = {S, ~(J_1 ^ S), ~(J_2 ^ S), current_immediate, stored_immediate, 8'b0};
            default: immediate_value_o = 32'bx;
        endcase
    end

    // always store the immediate offset as if we're currently executing a branch with
    // link instruction
    always_ff @(posedge clk_i)
        stored_instruction <= instruction_i;

endmodule