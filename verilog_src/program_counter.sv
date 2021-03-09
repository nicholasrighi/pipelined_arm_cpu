`include "GENERAL_DEFS.svh"

module program_counter(
                        input logic                 clk_i,
                        input logic                 reset_i,
                        input branch_from_wb        branch_from_wb_i,
                        input stall_pipeline_sig    stall_pipeline_i,
                        input take_branch_ctrl_sig  take_branch_i,
                        input logic [WORD-1:0]      pop_pc_value_i,
                        input logic [WORD-1:0]      branch_pc_value_i,

                        output logic                is_valid_o,
                        output logic [WORD-1:0]     program_counter_o
                        );

    // the start address is 2 since on reset the instruction memory outputs the instruction
    // at address 0, and we don't want to execute the same instruction twice
    localparam START_ADDR = 32'd0;
    // Since we're in thumb mode each instruction is 2 bytes, so we increment by 2
    localparam INCREMENT_VALUE = 32'd2;

    logic [WORD-1:0] next_program_counter_value;

    always_comb begin

       is_valid_o = 1'b1;

       if (take_branch_i == TAKE_BRANCH)
            next_program_counter_value = branch_pc_value_i;
       else if (branch_from_wb_i == BRANCH_FROM_WB)
            next_program_counter_value = pop_pc_value_i;
       else if (stall_pipeline_i == STALL_PIPELINE) 
            next_program_counter_value = program_counter_o;
       else
            next_program_counter_value = program_counter_o + INCREMENT_VALUE;
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            program_counter_o <= START_ADDR;
        else
            program_counter_o <= next_program_counter_value;

    end

endmodule