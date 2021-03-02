`include "GENERAL_DEFS.svh"

module decode_execution_register   
                                  (
                                    input logic                       clk_i,
                                    input logic                       reset_i,
                                    input mem_write_signal            mem_write_en_i,
                                    input mem_read_signal             mem_read_en_i,
                                    input reg_file_write_sig          reg_file_write_en_i,
                                    input reg_file_data_source        reg_file_input_ctrl_sig_i,
                                    input alu_input_source            alu_input_1_select_i,
                                    input alu_input_source            alu_input_2_select_i,
                                    input alu_control_signal          alu_control_signal_i,
                                    input update_flag_sig             update_flag_i,
                                    input reg_2_reg_3_select_sig      reg_2_reg_3_select_sig_i,
                                    input logic                       is_valid_i,
                                    input logic [6:0]                 opA_opB_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_1_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_2_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_3_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_dest_addr_i,
                                    input logic [WORD-1:0]            immediate_i,
                                    input logic [WORD-1:0]            accumulator_imm_i,

                                    output mem_write_signal           mem_write_en_o,
                                    output mem_read_signal            mem_read_en_o,
                                    output reg_file_write_sig         reg_file_write_en_o,
                                    output reg_file_data_source       reg_file_input_ctrl_sig_o,
                                    output alu_input_source           alu_input_1_select_o,
                                    output alu_input_source           alu_input_2_select_o,
                                    output alu_control_signal         alu_control_signal_o,
                                    output update_flag_sig            update_flag_o,
                                    output reg_2_reg_3_select_sig     reg_2_reg_3_select_sig_o,
                                    output logic                      is_valid_o,
                                    output logic [6:0]                opA_opB_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_1_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_2_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_3_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_dest_addr_o,
                                    output logic [WORD-1:0]           immediate_o,
                                    output logic [WORD-1:0]           accumulator_imm_o
                                    );

    always_ff @(posedge clk_i) begin
       if (reset_i) 
            is_valid_o            <= 1'b0;
       else
            is_valid_o            <= is_valid_i;

      opA_opB_o                   <= opA_opB_i;
      mem_write_en_o              <= mem_write_en_i;
      mem_read_en_o               <= mem_read_en_i;
      reg_file_write_en_o         <= reg_file_write_en_i;
      reg_file_input_ctrl_sig_o   <= reg_file_input_ctrl_sig_i;
      alu_input_1_select_o        <= alu_input_1_select_i;
      alu_input_2_select_o        <= alu_input_2_select_i;
      alu_control_signal_o        <= alu_control_signal_i;
      update_flag_o               <= update_flag_i;
      is_valid_o                  <= is_valid_i;
      accumulator_imm_o           <= accumulator_imm_i;
      immediate_o                 <= immediate_i;
      reg_1_source_addr_o         <= reg_1_source_addr_i;
      reg_2_source_addr_o         <= reg_2_source_addr_i;
      reg_3_source_addr_o         <= reg_3_source_addr_i;
      reg_dest_addr_o             <= reg_dest_addr_i;
      reg_2_reg_3_select_sig_o    <= reg_2_reg_3_select_sig_i;
    end

endmodule