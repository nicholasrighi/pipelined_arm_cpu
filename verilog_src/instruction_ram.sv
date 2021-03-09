`include "GENERAL_DEFS.svh"

module instruction_ram(
                        input logic clk_i,
                        input logic write_en_i,
                        input logic [HALF_WORD-1:0] data_i,
                        input logic [WORD-1:0] instruction_addr_i,

                        output logic [HALF_WORD-1:0] instruction_o
                      );

    localparam NUM_INSTRUCTIONS = 512;

    logic [HALF_WORD-1:0] ram_mod [NUM_INSTRUCTIONS];

    always_ff @(posedge clk_i) begin
        if (write_en_i)
            ram_mod[instruction_addr_i/2] <= data_i;
    end

    always_ff @(posedge clk_i) begin
        instruction_o <= ram_mod[instruction_addr_i/2];
    end

endmodule