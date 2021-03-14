`include "GENERAL_DEFS.svh"

module instruction_mem(
                                input logic                 clk_i,
                                input logic                 reset_i,
                                input logic                 program_mem_write_en_i,
                                input logic                 is_valid_i,
                                input flush_pipeline_sig    flush_pipeline_i,
                                input stall_pipeline_sig    stall_pipeline_i,
                                input logic [HALF_WORD-1:0] instruction_i,
                                input logic [WORD-1:0]      instruction_addr_i,

                                output logic                 is_valid_o,
                                output logic [HALF_WORD-1:0] instruction_o,
                                output logic [WORD-1:0]      program_counter_o
                                );

    // store pc so we can stall the pipeline when needed
    logic [WORD-1:0] next_instruction_addr;

    always_comb begin
        // determines what the next value of the pc should be 
        if (program_mem_write_en_i)
            next_instruction_addr = instruction_addr_i;
        else if (stall_pipeline_i)
            next_instruction_addr = program_counter_o;
        else
            next_instruction_addr = instruction_addr_i;
    end

    `ifdef DC
       RAM_16B_512_AR1_LP ram(
                                .CLK(clk_i),
                                .WEN(~program_mem_write_en_i),
                                .CEN(1'b0),
                                .A(next_instruction_addr[8:0]),
                                .D(instruction_i),
                                .Q(instruction_o),
                                .EMA(3'b010),
                                .EMAW(2'b00),
                                .EMAS(1'b0),
                                .RET1N(1'b1)
                            ); 
    `else 
        instruction_ram ram(
                            .clk_i(clk_i),
                            .write_en_i(program_mem_write_en_i),
                            .instruction_addr_i(next_instruction_addr),
                            .data_i(instruction_i),

                            .instruction_o(instruction_o)
                            );
    `endif

    always_ff @(posedge clk_i) begin
        if (reset_i)
            is_valid_o  <= 1'b0;
        else if (flush_pipeline_i == FLUSH_PIPELINE)
            is_valid_o  <= 1'b0;
        else
            is_valid_o  <= is_valid_i;

        if (reset_i)
            program_counter_o  <= 32'b0;
        else
            program_counter_o  <= next_instruction_addr;
    end

endmodule