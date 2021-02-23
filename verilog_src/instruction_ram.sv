`include "GENERAL_DEFS.svh"

module instruction_ram(
                        input logic clk_i,
                        input logic reset_i,
                        input logic write_en_i,
                        input logic [HALF_WORD-1:0] data_i,
                        input logic [WORD-1:0] instruction_addr_i,

                        output logic [HALF_WORD-1:0] instruction_o
                      );

    localparam NUM_INSTRUCTIONS = 4096;

    logic [HALF_WORD-1:0] ram_mod [NUM_INSTRUCTIONS];

    // verilator lint_off UNUSED
    logic [WORD-1:0] i_addr;
    // verilator lint_on UNUSED

    always_comb begin
        if (reset_i)
            i_addr = 2;
        else
            i_addr = instruction_addr_i;
    end

    initial begin
        $readmemh("/home/nicholasrighi/EE_477/sim_data/instruction_mem.mem", ram_mod);
    end

    always_ff @(posedge clk_i) begin
        if (write_en_i)
            ram_mod[instruction_addr_i] <= data_i;
    end

    always_ff @(posedge clk_i) begin
        instruction_o <= ram_mod[i_addr/2];
    end

endmodule