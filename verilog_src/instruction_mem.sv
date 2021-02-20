`include "GENERAL_DEFS.svh"

module instruction_mem(
                                input logic                 clk_i,
                                input logic                 reset_i,
                                input stall_pipeline_sig    stall_pipeline_i,
                                input logic [WORD-1:0]      program_counter_i,

                                output logic [HALF_WORD-1:0] instruction_o
                                );

    localparam NUM_INSTRUCTIONS = 8192;

    // Since we're in thumb mode, each instruction is 2 bytes, so we only store halfwords 
    logic [HALF_WORD-1:0] instruction_ram [NUM_INSTRUCTIONS-1:0];

    // store pc so we can stall the pipeline when needed
    logic [WORD-1:0] stored_pc;
    logic [WORD-1:0] next_instruction_addr;

    initial $readmemh("/home/nicholasrighi/EE_477/sim_data/instruction_mem.mem", instruction_ram);

    always_comb begin
       if (stall_pipeline_i)
            next_instruction_addr = stored_pc;
        else
            next_instruction_addr = program_counter_i;
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            instruction_o <= instruction_ram[32'b0];
        else if (stall_pipeline_i == NO_STALL_PIPELINE)
            // Since we're in thumb mode we only divide by 2 to determine the relevant instruction
            // to execute
            instruction_o <= instruction_ram[next_instruction_addr/2];
    end

    always_ff @(posedge clk_i) begin
            stored_pc <= program_counter_i;
    end

endmodule