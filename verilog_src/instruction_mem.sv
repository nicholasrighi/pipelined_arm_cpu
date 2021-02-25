`include "GENERAL_DEFS.svh"

module instruction_mem(
                                input logic                 clk_i,
                                input logic                 reset_i,
                                input logic                 program_mem_write_en_i,
                                input logic                 is_valid_i,
                                input stall_pipeline_sig    stall_pipeline_i,
                                input logic [HALF_WORD-1:0] instruction_i,
                                input logic [WORD-1:0]      instruction_addr_i,

                                output logic                 is_valid_o,
                                output logic [HALF_WORD-1:0] instruction_o
                                );

    // store pc so we can stall the pipeline when needed
    logic [WORD-1:0] stored_pc;
    logic [WORD-1:0] next_instruction_addr;

    always_comb begin
        if (program_mem_write_en_i)
            next_instruction_addr = instruction_addr_i;
        else if (stall_pipeline_i)
            next_instruction_addr = stored_pc;
        else
            next_instruction_addr = instruction_addr_i;
    end

    instruction_ram ram(
                        .clk_i(clk_i),
                        .write_en_i(program_mem_write_en_i),
                        .instruction_addr_i(next_instruction_addr),
                        .data_i(instruction_i),

                        .instruction_o(instruction_o)
                        );

    always_ff @(posedge clk_i) begin
        if (reset_i)
            is_valid_o <= 1'b0;
        else 
            is_valid_o <= is_valid_i;

        if (stall_pipeline_i == NO_STALL_PIPELINE)
            stored_pc <= instruction_addr_i;
    end

endmodule