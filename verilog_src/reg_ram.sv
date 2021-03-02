`include "GENERAL_DEFS.svh"

module reg_ram(
                input logic clk_i,
                input logic write_en_i,
                input logic [ADDR_WIDTH-1:0] reg_addr_1_i,
                input logic [ADDR_WIDTH-1:0] reg_addr_2_i,
                input logic [ADDR_WIDTH-1:0] reg_addr_3_i,
                input logic [ADDR_WIDTH-1:0] reg_dest_addr_i,
                input logic [WORD-1:0] reg_data_i,

                output logic [WORD-1:0] reg_data_1_o,
                output logic [WORD-1:0] reg_data_2_o,
                output logic [WORD-1:0] reg_data_3_o
            );

    localparam REG_NUM = 16; 

    logic [WORD-1:0] ram [REG_NUM-1:0];

    always_ff @(posedge clk_i) begin
        if (write_en_i)
            ram[reg_dest_addr_i] <= reg_data_i;
    end

    always_ff @(posedge clk_i) begin
       reg_data_1_o <= ram[reg_addr_1_i];
       reg_data_2_o <= ram[reg_addr_2_i]; 
       reg_data_3_o <= ram[reg_addr_3_i];
    end

endmodule