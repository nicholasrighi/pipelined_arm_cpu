`include "GENERAL_DEFS.svh"

module alu_wrapper(
                            input logic                 clk_i,
                            input logic                 reset_i,
                            input logic                 update_flag_i,
                            input alu_control_signal    alu_ctrl_sig_i,
                            input alu_input_source      alu_input_1_select_i,
                            input alu_input_source      alu_input_2_select_i,
                            input logic [WORD-1:0]      reg_data_1_i,
                            input logic [WORD-1:0]      reg_data_2_i,
                            input logic [WORD-1:0]      accumulator_i,
                            input logic [WORD-1:0]      immediate_i,
                            input logic [WORD-1:0]      program_counter_i,

                            output logic [WORD-1:0]     alu_result_o,
                            output status_register      status_reg_o
                        );

        status_register next_status_reg;

        logic [WORD-1:0] alu_data_in_1_internal;
        logic [WORD-1:0] alu_data_in_2_internal;

        always_comb begin
                alu_data_in_1_internal = 'x;
                alu_data_in_2_internal = 'x;
                case (alu_input_1_select_i)
                        FROM_REG:               alu_data_in_1_internal = reg_data_1_i;
                        FROM_IMM:               alu_data_in_1_internal = immediate_i;
                        FROM_ZERO:              alu_data_in_1_internal = 32'b0;
                        FROM_ACCUMULATOR:       alu_data_in_1_internal = accumulator_i;
                        FROM_PC:                alu_data_in_1_internal = program_counter_i;
                        FROM_PC_ALIGNED:        alu_data_in_1_internal = {program_counter_i[31:2],2'b00};
                        FROM_TWO:               alu_data_in_1_internal = 32'd2;
                        default: ;
                endcase

                case(alu_input_2_select_i)
                        FROM_REG:               alu_data_in_2_internal = reg_data_2_i;
                        FROM_IMM:               alu_data_in_2_internal = immediate_i;
                        FROM_ZERO:              alu_data_in_2_internal = 32'b0;
                        FROM_ACCUMULATOR:       alu_data_in_2_internal = accumulator_i;
                        FROM_PC:                alu_data_in_2_internal = program_counter_i;
                        FROM_PC_ALIGNED:        alu_data_in_2_internal = {program_counter_i[31:2],2'b00};
                        FROM_TWO:               alu_data_in_2_internal = 32'd2;
                        default: ;
                endcase
        end

        alu full_alu(
                        .carry_flag_i(status_reg_o.carry_flag),
                        .alu_ctrl_sig_i(alu_ctrl_sig_i),
                        .data_in_1_i(alu_data_in_1_internal),
                        .data_in_2_i(alu_data_in_2_internal),

                        .status_reg_o(next_status_reg),
                        .alu_result_o(alu_result_o)
        );

        always_ff @(posedge clk_i) begin 
                if (reset_i)
                        status_reg_o <= 4'b0;
                else if (update_flag_i)
                        status_reg_o <= next_status_reg;
        end

endmodule