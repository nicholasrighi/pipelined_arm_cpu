`include "GENERAL_DEFS.svh"

module execution_datapath(
                            input logic                     clk_i,
                            input logic                     update_flag_i,
                            input alu_control_signal        alu_ctrl_sig_i,
                            input alu_input_source          alu_input_1_select_i,
                            input alu_input_source          alu_input_2_select_i,
                            input reg_file_write_sig        reg_write_en_MEM_i,
                            input reg_file_write_sig        reg_write_en_WB_i,
                            input logic [ADDR_WIDTH-1:0]    reg_addr_1_DECODE_i,
                            input logic [ADDR_WIDTH-1:0]    reg_addr_2_DECODE_i,
                            input logic [ADDR_WIDTH-1:0]    reg_dest_MEM_i,
                            input logic [ADDR_WIDTH-1:0]    reg_dest_WB_i,
                            input logic [WORD-1:0]          reg_data_2_DECODE_i,
                            input logic [WORD-1:0]          reg_data_1_DECODE_i,
                            input logic [WORD-1:0]          reg_data_MEM_i,
                            input logic [WORD-1:0]          reg_data_WB_i,
                            input logic [WORD-1:0]          accumulator_i,
                            input logic [WORD-1:0]          immediate_i,

                            output logic [WORD-1:0]         alu_result_o,
                            output logic [WORD-1:0]         reg_2_data_o
                        );

        //////////////////////////////////////
        //  ALU FOWARDING CTRL SIGNALS      //
        //////////////////////////////////////
        forwarding_data_source  reg_1_ctrl_sig_internal;
        forwarding_data_source  reg_2_ctrl_sig_internal;


        // these are the values that will be given to the alu as register inputs
        // if forwarding is required, these signals will have the forwarded values
        logic [WORD-1:0] final_alu_reg_input_1_data_internal;
        logic [WORD-1:0] final_alu_reg_input_2_data_internal;

        // verilator lint_off UNUSED
        status_register status_reg_internal;    //TODO. Need to use status register for cond. branching
        // verilator lint_on UNUSED

        // TODO. Need to implement outputting data from reg 2 as an output of the execution datapath, since we need it
        //      for storing data

        always_comb begin
            final_alu_reg_input_1_data_internal = 'x;
            final_alu_reg_input_2_data_internal = 'x;

            case(reg_1_ctrl_sig_internal)
                FORWARD_FROM_DECODE:    final_alu_reg_input_1_data_internal = reg_data_1_DECODE_i;
                FORWARD_FROM_MEM:       final_alu_reg_input_1_data_internal = reg_data_MEM_i;
                FORWARD_FROM_WB:        final_alu_reg_input_1_data_internal = reg_data_WB_i;
                default: ;
            endcase

            case(reg_2_ctrl_sig_internal)
                FORWARD_FROM_DECODE:    final_alu_reg_input_2_data_internal = reg_data_2_DECODE_i;
                FORWARD_FROM_MEM:       final_alu_reg_input_2_data_internal = reg_data_MEM_i;
                FORWARD_FROM_WB:        final_alu_reg_input_2_data_internal = reg_data_WB_i;
                default: ;
            endcase

            reg_2_data_o = final_alu_reg_input_2_data_internal;
        end

        alu_forwarder alu_forwarding_unit(
                                            .reg_write_en_MEM_i(reg_write_en_MEM_i),
                                            .reg_write_en_WB_i(reg_write_en_WB_i),
                                            .reg_1_addr_i(reg_addr_1_DECODE_i),
                                            .reg_2_addr_i(reg_addr_2_DECODE_i),
                                            .reg_dest_MEM_i(reg_dest_MEM_i),
                                            .reg_dest_WB_i(reg_dest_WB_i),

                                            .alu_input_1_ctrl_sig_o(reg_1_ctrl_sig_internal),
                                            .alu_input_2_ctrl_sig_o(reg_2_ctrl_sig_internal)
                                         );

        alu_wrapper wrapped_alu (
                                    .clk_i(clk_i),
                                    .update_flag_i(update_flag_i),
                                    .alu_ctrl_sig_i(alu_ctrl_sig_i),
                                    .alu_input_1_select_i(alu_input_1_select_i),
                                    .alu_input_2_select_i(alu_input_2_select_i),
                                    .reg_data_1_i(final_alu_reg_input_1_data_internal),
                                    .reg_data_2_i(final_alu_reg_input_2_data_internal),
                                    .accumulator_i(accumulator_i),
                                    .immediate_i(immediate_i),

                                    .alu_result_o(alu_result_o),
                                    .status_reg_o(status_reg_internal)
        );

endmodule