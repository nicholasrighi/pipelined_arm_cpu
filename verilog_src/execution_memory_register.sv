`include "GENERAL_DEFS.svh"

module execution_memory_register(
                                input logic                 clk_i,
                                input logic                 reset_i,
                                input logic                 is_valid_i,
                                input mem_write_signal      mem_write_en_i,
                                input reg_file_write_sig    reg_file_write_en_i,
                                input branch_from_wb        branch_from_wb_i,
                                input logic [6:0]           opA_opB_i,
                                input reg_file_data_source  reg_file_data_source_i,
                                input logic [ADDR_WIDTH-1:0] reg_dest_addr_i, 
                                input logic [WORD-1:0]      alu_result_i,
                                input logic [WORD-1:0]      reg_2_data_i,

                                output logic                 is_valid_o,
                                output mem_write_signal      mem_write_en_o,
                                output reg_file_write_sig    reg_file_write_en_o,
                                output branch_from_wb        branch_from_wb_o,
                                output logic [6:0]           opA_opB_o,
                                output reg_file_data_source  reg_file_data_source_o,
                                output logic [ADDR_WIDTH-1:0] reg_dest_addr_o,
                                output logic [WORD-1:0]      alu_result_o,
                                output logic [WORD-1:0]      reg_2_data_o
                            );

    always_ff @(posedge clk_i) begin
          if (reset_i) 
               is_valid_o          <= 1'b0;
          else
               is_valid_o          <= is_valid_i;

          branch_from_wb_o         <= branch_from_wb_i;
          opA_opB_o                <= opA_opB_i;
          mem_write_en_o           <= mem_write_en_i;
          reg_file_write_en_o      <= reg_file_write_en_i;
          reg_file_data_source_o   <= reg_file_data_source_i;
          alu_result_o             <= alu_result_i;
          reg_2_data_o             <= reg_2_data_i;
          reg_dest_addr_o          <= reg_dest_addr_i;
    end

endmodule