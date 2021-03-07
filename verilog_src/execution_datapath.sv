`include "GENERAL_DEFS.svh"

module execution_datapath(
                            input logic                     clk_i,
                            input logic                     reset_i,
                            input logic                     is_valid_i,
                            input logic                     update_flag_i,
                            input reg_2_reg_3_select_sig    reg_2_reg_3_select_sig_i,
                            input alu_control_signal        alu_ctrl_sig_i,
                            input alu_input_source          alu_input_1_select_i,
                            input alu_input_source          alu_input_2_select_i,
                            input reg_file_write_sig        reg_write_en_MEM_i,
                            input reg_file_write_sig        reg_write_en_WB_i,
                            input instruction               instruction_i,
                            input logic [ADDR_WIDTH-1:0]    reg_addr_1_DECODE_i,
                            input logic [ADDR_WIDTH-1:0]    reg_addr_2_DECODE_i,
                            input logic [ADDR_WIDTH-1:0]    reg_addr_3_DECODE_i,
                            input logic [ADDR_WIDTH-1:0]    reg_dest_MEM_i,
                            input logic [ADDR_WIDTH-1:0]    reg_dest_WB_i,
                            input logic [WORD-1:0]          reg_data_1_DECODE_i,
                            input logic [WORD-1:0]          reg_data_2_DECODE_i,
                            input logic [WORD-1:0]          reg_data_3_DECODE_i,
                            input logic [WORD-1:0]          reg_data_MEM_i,
                            input logic [WORD-1:0]          reg_data_WB_i,
                            input logic [WORD-1:0]          accumulator_i,
                            input logic [WORD-1:0]          immediate_i,
                            // this is addr instruction + 4, so offset is included in this input
                            input logic [WORD-1:0]          program_counter_i,  

                            output take_branch_ctrl_sig     take_branch_o,
                            output flush_pipeline_sig       flush_pipeline_o,
                            output logic [WORD-1:0]         alu_result_o,
                            output logic [WORD-1:0]         reg_2_data_o,
                            output logic [WORD-1:0]         program_counter_o
                        );

        //////////////////////////////////////
        //  ALU FOWARDING CTRL SIGNALS      //
        //////////////////////////////////////
        forwarding_data_source  reg_1_ctrl_sig_internal;
        forwarding_data_source  reg_2_ctrl_sig_internal;
        forwarding_data_source  reg_3_ctrl_sig_internal;

        //////////////////////////////////////
        //  BRANCH CONTROLLER SIGNALS       //
        //////////////////////////////////////
        status_register status_reg_internal;

        // these are the values that will be given to the alu as register inputs
        // if forwarding is required, these signals will have the forwarded values
        logic [WORD-1:0] final_alu_reg_input_1_data_internal;
        logic [WORD-1:0] final_alu_reg_input_2_data_internal;
        logic [WORD-1:0] final_alu_reg_input_3_data_internal;

        always_comb begin
            final_alu_reg_input_1_data_internal = 'x;
            final_alu_reg_input_2_data_internal = 'x;
            final_alu_reg_input_3_data_internal = 'x;

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

            case(reg_3_ctrl_sig_internal)
                FORWARD_FROM_DECODE:    final_alu_reg_input_3_data_internal = reg_data_3_DECODE_i;
                FORWARD_FROM_MEM:       final_alu_reg_input_3_data_internal = reg_data_MEM_i;
                FORWARD_FROM_WB:        final_alu_reg_input_3_data_internal = reg_data_WB_i;
                default: ;
            endcase

            if (reg_2_reg_3_select_sig_i == SELECT_REG_2)
                reg_2_data_o = final_alu_reg_input_2_data_internal;
            else
                reg_2_data_o = final_alu_reg_input_3_data_internal;
        end

        alu_forwarder alu_forwarding_unit(
                                            .reg_write_en_MEM_i(reg_write_en_MEM_i),
                                            .reg_write_en_WB_i(reg_write_en_WB_i),
                                            .reg_1_addr_i(reg_addr_1_DECODE_i),
                                            .reg_2_addr_i(reg_addr_2_DECODE_i),
                                            .reg_3_addr_i(reg_addr_3_DECODE_i),
                                            .reg_dest_MEM_i(reg_dest_MEM_i),
                                            .reg_dest_WB_i(reg_dest_WB_i),

                                            .alu_input_1_ctrl_sig_o(reg_1_ctrl_sig_internal),
                                            .alu_input_2_ctrl_sig_o(reg_2_ctrl_sig_internal),
                                            .alu_input_3_ctrl_sig_o(reg_3_ctrl_sig_internal)
                                         );

        alu_wrapper wrapped_alu (
                                    .clk_i(clk_i),
                                    .reset_i(reset_i),
                                    .update_flag_i(update_flag_i & is_valid_i),
                                    .alu_ctrl_sig_i(alu_ctrl_sig_i),
                                    .alu_input_1_select_i(alu_input_1_select_i),
                                    .alu_input_2_select_i(alu_input_2_select_i),
                                    .reg_data_1_i(final_alu_reg_input_1_data_internal),
                                    .reg_data_2_i(final_alu_reg_input_2_data_internal),
                                    .accumulator_i(accumulator_i),
                                    .immediate_i(immediate_i),
                                    .program_counter_i(program_counter_i),

                                    .alu_result_o(alu_result_o),
                                    .status_reg_o(status_reg_internal)
        );

        branch_controller b_controller(
                                    .clk_i(clk_i),
                                    .reset_i(reset_i),
                                    .is_valid_i(is_valid_i),
                                    .status_reg_i(status_reg_internal),
                                    .instruction_i(instruction_i),
                                    .program_counter_i(program_counter_i),
                                    .immediate_i(immediate_i),
                                    .reg_data_1_i(final_alu_reg_input_1_data_internal),
                                    .reg_data_2_i(final_alu_reg_input_2_data_internal),

                                    .take_branch_o(take_branch_o),
                                    .flush_pipeline_o(flush_pipeline_o),
                                    .program_counter_o(program_counter_o)
                                    );
endmodule