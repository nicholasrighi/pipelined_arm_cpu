`include "GENERAL_DEFS.svh"

module imm_gen(
                    input logic clk_i,
                    input logic [HALF_WORD-1:0] instruction_i,

                    output logic [WORD-1:0] immediate_value_o 
              );

    logic opcode;
    logic J_1;
    logic J_2;
    logic S;
    logic [10:0] stored_immediate;
    logic [9:0] current_immediate;

    // this is used for 32 bit instructions, since in that case we need to forward data from
    logic [HALF_WORD-1:0] stored_instruction;

    always_comb begin

        // extract fields from current instruction
        opcode = instruction_i[15:10];
        current_immediate = instruction_i[9:0];
        S   = instruction_i[10];

        // extract fields from stored instruction
        stored_immediate = stored_instruction[10:0];
        J_1 = stored_instruction[13];
        J_2 = stored_instruction[11];

        case(opcode)
            BL: immediate_value_o = {S, ~(J_1 ^ S), ~(J_2 ^ S), current_immediate, stored_immediate, 0};
            default: immediate_value_o = 32'bx;
        endcase
    end

    // always store the immediate offset as if we're currently executing a branch with
    // link instruction
    always_ff @(posedge clk)
        stored_instruction <= instruction_i;

endmodule