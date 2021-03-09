`include "GENERAL_DEFS.svh"

module execution_block(
                        input logic                  clk_i,
                        input logic                  reset_i,
                        input update_flag_sig        update_flag_i,
                        input mem_write_signal       mem_write_en_i,
                        input reg_file_write_sig     reg_file_write_en_i,
                        input reg_file_data_source   reg_file_data_source_i,
                        input alu_input_source       alu_input_1_select_i,
                        input alu_input_source       alu_input_2_select_i,
                        input alu_control_signal     alu_control_signal_i,
                        input reg_file_write_sig     reg_write_en_MEM_i,
                        input reg_file_write_sig     reg_write_en_WB_i,
                        input reg_2_reg_3_select_sig reg_2_reg_3_select_sig_i,
                        input logic                  is_valid_i,
                        input instruction            instruction_i,
                        input branch_from_wb         branch_from_wb_i,
                        input logic [ADDR_WIDTH-1:0] reg_1_source_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_2_source_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_3_source_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_MEM_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_WB_i,
                        input logic [WORD-1:0]       accumulator_imm_i,
                        input logic [WORD-1:0]       immediate_i,
                        input logic [WORD-1:0]       reg_1_data_i,
                        input logic [WORD-1:0]       reg_2_data_i,
                        input logic [WORD-1:0]       reg_3_data_i,
                        input logic [WORD-1:0]       reg_data_MEM_i,
                        input logic [WORD-1:0]       reg_data_WB_i,
                        input logic [WORD-1:0]       program_counter_i,

                        output logic                 is_valid_o,
                        output mem_write_signal      mem_write_en_o,
                        output reg_file_write_sig    reg_file_write_en_o,
                        output reg_file_data_source  reg_file_data_source_o,
                        output take_branch_ctrl_sig  take_branch_o,
                        output flush_pipeline_sig    flush_pipeline_o,
                        output branch_from_wb        branch_from_wb_o,
                        output logic [6:0]           opA_opB_o,
                        output logic [ADDR_WIDTH-1:0] reg_dest_addr_o,
                        output logic [WORD-1:0]      alu_result_o,
                        output logic [WORD-1:0]      reg_2_data_o,       //TODO: change this name to store_reg_data from reg_2_data, since reg3 or reg2 data 
                                                                        // can be stored
                        output logic [WORD-1:0]      program_counter_o
                        );

        logic [WORD-1:0] alu_result_internal;
        logic [WORD-1:0] reg_2_data_internal;
        logic [WORD-1:0] two_instruction_ahead_pc;

        assign two_instruction_ahead_pc = program_counter_i + 32'd4;
        
        execution_datapath exe_datapath(
                            .clk_i(clk_i),
                            .reset_i(reset_i),
                            .is_valid_i(is_valid_i),
                            .update_flag_i(update_flag_i),
                            .alu_ctrl_sig_i(alu_control_signal_i),
                            .instruction_i(instruction_i),
                            .reg_2_reg_3_select_sig_i(reg_2_reg_3_select_sig_i),
                            .alu_input_1_select_i(alu_input_1_select_i),
                            .alu_input_2_select_i(alu_input_2_select_i),
                            .reg_write_en_MEM_i(reg_write_en_MEM_i),
                            .reg_write_en_WB_i(reg_write_en_WB_i),
                            .reg_addr_1_DECODE_i(reg_1_source_addr_i),
                            .reg_addr_2_DECODE_i(reg_2_source_addr_i),
                            .reg_addr_3_DECODE_i(reg_3_source_addr_i),
                            .reg_dest_MEM_i(reg_dest_MEM_i),
                            .reg_dest_WB_i(reg_dest_WB_i),
                            .reg_data_1_DECODE_i(reg_1_data_i),
                            .reg_data_2_DECODE_i(reg_2_data_i),
                            .reg_data_3_DECODE_i(reg_3_data_i),
                            .reg_data_MEM_i(reg_data_MEM_i),
                            .reg_data_WB_i(reg_data_WB_i),
                            .accumulator_i(accumulator_imm_i),
                            .immediate_i(immediate_i),
                            .program_counter_i(two_instruction_ahead_pc),
                            
                            .alu_result_o(alu_result_internal),
                            .reg_2_data_o(reg_2_data_internal),
                            .take_branch_o(take_branch_o),
                            .flush_pipeline_o(flush_pipeline_o),
                            .program_counter_o(program_counter_o)
                            );

        execution_memory_register exe_mem_reg(
                                .clk_i(clk_i),
                                .reset_i(reset_i),
                                .branch_from_wb_i(branch_from_wb_i),
                                .is_valid_i(is_valid_i),
                                .mem_write_en_i(mem_write_en_i),
                                .reg_file_write_en_i(reg_file_write_en_i),
                                .reg_file_data_source_i(reg_file_data_source_i),
                                .opA_opB_i(instruction_i[15:9]),
                                .reg_dest_addr_i(reg_dest_addr_i),
                                .alu_result_i(alu_result_internal),
                                .reg_2_data_i(reg_2_data_internal),          

                                .is_valid_o(is_valid_o),
                                .mem_write_en_o(mem_write_en_o),
                                .reg_file_write_en_o(reg_file_write_en_o),
                                .branch_from_wb_o(branch_from_wb_o),
                                .reg_file_data_source_o(reg_file_data_source_o),
                                .opA_opB_o(opA_opB_o),
                                .reg_dest_addr_o(reg_dest_addr_o),
                                .alu_result_o(alu_result_o),
                                .reg_2_data_o(reg_2_data_o)
        );

endmodule