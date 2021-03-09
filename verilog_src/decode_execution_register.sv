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
                                    input flush_pipeline_sig          flush_pipeline_i,
                                    input branch_from_wb              branch_from_wb_i,
                                    input logic                       is_valid_i,
                                    input logic                       hazard_detector_invaidate_i,
                                    input instruction                 instruction_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_1_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_2_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_3_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_dest_addr_i,
                                    input logic [WORD-1:0]            immediate_i,
                                    input logic [WORD-1:0]            accumulator_imm_i,
                                    input logic [WORD-1:0]            program_counter_i,

                                    output mem_write_signal           mem_write_en_o,
                                    output mem_read_signal            mem_read_en_o,
                                    output reg_file_write_sig         reg_file_write_en_o,
                                    output reg_file_data_source       reg_file_input_ctrl_sig_o,
                                    output alu_input_source           alu_input_1_select_o,
                                    output alu_input_source           alu_input_2_select_o,
                                    output alu_control_signal         alu_control_signal_o,
                                    output update_flag_sig            update_flag_o,
                                    output reg_2_reg_3_select_sig     reg_2_reg_3_select_sig_o,
                                    output branch_from_wb             branch_from_wb_o,
                                    output logic                      is_valid_o,
                                    output instruction                instruction_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_1_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_2_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_3_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_dest_addr_o,
                                    output logic [WORD-1:0]           immediate_o,
                                    output logic [WORD-1:0]           accumulator_imm_o,
                                    output logic [WORD-1:0]           program_counter_o
                                    );

     logic mem_read_en_internal;

    always_ff @(posedge clk_i) begin
       if (reset_i) 
            is_valid_o            <= 1'b0;
       else if (flush_pipeline_i == FLUSH_PIPELINE || hazard_detector_invaidate_i)
            is_valid_o            <= 1'b0;
       else
            is_valid_o            <= is_valid_i;

      branch_from_wb_o            <= branch_from_wb_i;
      instruction_o               <= instruction_i;
      mem_write_en_o              <= mem_write_en_i;
      mem_read_en_internal        <= mem_read_en_i;
      reg_file_write_en_o         <= reg_file_write_en_i;
      reg_file_input_ctrl_sig_o   <= reg_file_input_ctrl_sig_i;
      alu_input_1_select_o        <= alu_input_1_select_i;
      alu_input_2_select_o        <= alu_input_2_select_i;
      alu_control_signal_o        <= alu_control_signal_i;
      update_flag_o               <= update_flag_i;
      accumulator_imm_o           <= accumulator_imm_i;
      immediate_o                 <= immediate_i;
      reg_1_source_addr_o         <= reg_1_source_addr_i;
      reg_2_source_addr_o         <= reg_2_source_addr_i;
      reg_3_source_addr_o         <= reg_3_source_addr_i;
      reg_dest_addr_o             <= reg_dest_addr_i;
      reg_2_reg_3_select_sig_o    <= reg_2_reg_3_select_sig_i;
      program_counter_o           <= program_counter_i;
    end

    assign mem_read_en_o = mem_read_en_internal & is_valid_o;

endmodule