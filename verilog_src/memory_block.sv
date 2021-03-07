`include "GENERAL_DEFS.svh"

module memory_block(
                    input logic                     clk_i,
                    input logic                     reset_i,
                    input logic                     is_valid_i,
                    input logic                     mem_write_en_i,
                    input reg_file_data_source      reg_data_ctrl_sig_i,
                    input reg_file_write_sig        reg_file_write_en_i,
                    input logic [6:0]               opA_opB_i,
                    input logic [ADDR_WIDTH-1:0]    reg_dest_addr_i,
                    input logic [WORD-1:0]          stored_mem_data_i,
                    input logic [WORD-1:0]          alu_data_i,

                    output logic                    is_valid_o,
                    output reg_file_data_source     reg_data_ctrl_sig_o,
                    output reg_file_write_sig       reg_file_write_en_o,
                    output logic [ADDR_WIDTH-1:0]   reg_dest_addr_o,
                    output logic [WORD-1:0]         mem_data_o,
                    output logic [WORD-1:0]         alu_data_o
                    );

    data_mem data_ram (
                    .clk(clk_i),
                    // need to AND is_valid with mem_write to ensure that invalidated instructions dont have 
                    // a visible effect on the system
                    .mem_write_en(is_valid_i & mem_write_en_i),
                    .opCode(opA_opB_i),
                    .mem_addr(alu_data_i),
                    .mem_data_in(stored_mem_data_i),
                    .mem_data_out(mem_data_o)
                    );

    always_ff @(posedge clk_i) begin
        if (reset_i)
            is_valid_o <= 1'b0;
        else   
            is_valid_o <= is_valid_i;

        reg_data_ctrl_sig_o <= reg_data_ctrl_sig_i;
        reg_dest_addr_o     <= reg_dest_addr_i;
        alu_data_o          <= alu_data_i;
        reg_file_write_en_o <= reg_file_write_en_i;
    end

endmodule   