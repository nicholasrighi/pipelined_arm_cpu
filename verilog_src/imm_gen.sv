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
            // THIS IS WRONG
            SPECIAL: immediate_value_o = {S, ~(J_1 ^ S), ~(J_2 ^ S), current_immediate, stored_immediate, 8'b0};
            default: immediate_value_o = 32'bx;
        endcase
    end

    // always store the immediate offset as if we're currently executing a branch with
    // link instruction
    always_ff @(posedge clk_i)
        stored_instruction <= instruction_i;

endmodule