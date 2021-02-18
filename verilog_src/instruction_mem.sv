`include "GENERAL_DEFS.svh"

module instruction_mem(
                                input logic clk_i,
                                input logic reset_i,
                                // verilator lint_off UNUSED
                                input logic [WORD-1:0] program_counter_i,
                                // verilator lint_on UNUSED

                                output logic [HALF_WORD-1:0] instruction_o
                                );

    localparam NUM_INSTRUCTIONS = 8192;

    // Since we're in thumb mode, each instruction is 2 bytes, so we only store halfwords 
    logic [HALF_WORD-1:0] instruction_ram [NUM_INSTRUCTIONS-1:0];

    initial begin
        $readmemh("/home/nicholasrighi/EE_477/sim_data/instruction_mem.mem", instruction_ram);
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            instruction_o <= instruction_ram[32'b0];
        else 
            // Since we're in thumb mode we only divide by 2 to determine the relevant instruction
            // to execute
            instruction_o <= instruction_ram[program_counter_i/2];
    end

endmodule