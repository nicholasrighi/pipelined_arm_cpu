`include "GENERAL_DEFS.svh"

module program_counter(
                        input logic                 clk_i,
                        input logic                 reset_i,
                        input stall_pipeline_sig    stall_pipeline_i,

                        output logic [WORD-1:0]     program_counter_o
                        );

    // the start address is 2 since on reset the instruction memory outputs the instruction
    // at address 0, and we don't want to execute the same instruction twice
    localparam START_ADDR = 32'd2;
    // Since we're in thumb mode each instruction is 2 bytes, so we increment by 2
    localparam INCREMENT_VALUE = 32'd2;

    logic [WORD-1:0] next_program_counter_value;

    always_comb begin
       if (stall_pipeline_i == STALL_PIPELINE) 
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