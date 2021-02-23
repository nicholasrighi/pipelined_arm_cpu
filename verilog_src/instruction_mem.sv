`include "GENERAL_DEFS.svh"

module instruction_mem(
                                input logic                 clk_i,
                                input logic                 reset_i,
                                input stall_pipeline_sig    stall_pipeline_i,
                                input logic [WORD-1:0]      program_counter_i,

                                output logic [HALF_WORD-1:0] instruction_o
                                );

    // store pc so we can stall the pipeline when needed
    logic [WORD-1:0] stored_pc;
    logic [WORD-1:0] next_instruction_addr;


    always_comb begin
       if (stall_pipeline_i)
            next_instruction_addr = stored_pc;
        else
            next_instruction_addr = program_counter_i;
    end

    instruction_ram ram(
                        .clk_i(clk_i),
                        .reset_i(reset_i),
                        .write_en_i(1'b0),
                        .instruction_addr_i(next_instruction_addr),
                        .data_i('x),

                        .instruction_o(instruction_o)
                        );

    always_ff @(posedge clk_i) begin
            stored_pc <= program_counter_i;
    end

endmodule