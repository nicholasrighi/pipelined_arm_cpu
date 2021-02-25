`include "GENERAL_DEFS.svh"

module execution_block(
                        input logic                  clk_i,
                        input logic                  reset_i,
                        input update_flag_sig        update_flag_i,
                        input mem_write_signal       mem_write_en_i,
                        input mem_read_signal        mem_read_en_i,
                        input reg_file_write_sig     reg_file_write_en_i,
                        input reg_file_data_source   reg_file_data_source_i,
                        input alu_input_source       alu_input_1_select_i,
                        input alu_input_source       alu_input_2_select_i,
                        input alu_control_signal     alu_control_signal_i,
                        input mem_write_signal       mem_write_en_MEM_i,
                        input mem_write_signal       mem_write_en_WB_i,
                        input logic                  is_valid_i,
                        input logic [ADDR_WIDTH-1:0] reg_1_source_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_2_source_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_MEM_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_WB_i,
                        input logic [WORD-1:0]       accumulator_imm_i,
                        input logic [WORD-1:0]       immediate_i,
                        input logic [WORD-1:0]       reg_1_data_i,
                        input logic [WORD-1:0]       reg_2_data_i,
                        input logic [WORD-1:0]       reg_data_MEM_i,
                        input logic [WORD-1:0]       reg_data_WB_i,

                        output logic                 is_valid_o,
                        output mem_read_signal       mem_read_en_o,
                        output mem_write_signal      mem_write_en_o,
                        output reg_file_write_sig    reg_file_write_en_o,
                        output reg_file_data_source  reg_file_data_source_o,
                        output logic [ADDR_WIDTH-1:0] reg_dest_addr_o,
                        output logic [WORD-1:0]      alu_result_o,
                        output logic [WORD-1:0]      reg_2_data_o
                        );

        logic [WORD-1:0] alu_result_internal;
        
        assign mem_read_en_o = mem_read_en_i;

        execution_datapath exe_datapath(
                            .clk_i(clk_i),
                            .update_flag_i(update_flag_i),
                            .alu_ctrl_sig_i(alu_control_signal_i),
                            .alu_input_1_select_i(alu_input_1_select_i),
                            .alu_input_2_select_i(alu_input_2_select_i),
                            .mem_write_en_MEM_i(mem_write_en_MEM_i),
                            .mem_write_en_WB_i(mem_write_en_WB_i),
                            .reg_addr_1_DECODE_i(reg_1_source_addr_i),
                            .reg_addr_2_DECODE_i(reg_2_source_addr_i),
                            .reg_dest_MEM_i(reg_dest_MEM_i),
                            .reg_dest_WB_i(reg_dest_WB_i),
                            .reg_data_1_DECODE_i(reg_1_data_i),
                            .reg_data_2_DECODE_i(reg_2_data_i),
                            .reg_data_MEM_i(reg_data_MEM_i),
                            .reg_data_WB_i(reg_data_WB_i),
                            .accumulator_i(accumulator_imm_i),
                            .immediate_i(immediate_i),
                            
                            .alu_result_o(alu_result_internal)
                            ); 

        execution_memory_register exe_mem_reg(
                                .clk_i(clk_i),
                                .reset_i(reset_i),
                                .is_valid_i(is_valid_i),
                                .mem_write_en_i(mem_write_en_i),
                                .reg_file_write_en_i(reg_file_write_en_i),
                                .reg_file_data_source_i(reg_file_data_source_i),
                                .reg_dest_addr_i(reg_dest_addr_i),
                                .alu_result_i(alu_result_internal),
                                .reg_2_data_i(32'b0),            // TODO. NEED TO IMPLEMENT THIS IN THE 
                                                                // EXECUTION DATAPATH
                                .is_valid_o(is_valid_o),
                                .mem_write_en_o(mem_write_en_o),
                                .reg_file_write_en_o(reg_file_write_en_o),
                                .reg_file_data_source_o(reg_file_data_source_o),
                                .reg_dest_addr_o(reg_dest_addr_o),
                                .alu_result_o(alu_result_o),
                                .reg_2_data_o(reg_2_data_o)
        );

endmodule