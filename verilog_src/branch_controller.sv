`include "GENERAL_DEFS.svh"

module branch_controller(
                            input logic                 is_valid_i,
                            input status_register       status_reg_i,
                            input logic [7:0]           op_cond_i,
                            input logic [WORD-1:0]      program_counter_i,
                            // verilator lint_off UNUSED
                            input logic [WORD-1:0]      reg_data_i,
                            // verilator lint_on UNUSED
                            input logic [WORD-1:0]      immediate_i,

                            output take_branch_ctrl_sig take_branch_o,
                            output flush_pipeline_sig   flush_pipeline_o,
                            output [WORD-1:0]           program_counter_o
                        );

    logic take_branch_internal;
    opcode op;
    logic [3:0] condition;

    // NOTE: ALL REFERENCES TO THE PC MUST USE PROGRAM_COUNTER_INTERNAL, NOT PROGRAM_COUNTER_I
    logic [WORD-1:0] program_counter_internal;

    always_comb begin

        op = op_cond_i[7:2];
        condition = op_cond_i[3:0];

        // This is to account for the offset that arm requires the PC and the current instruction
        // to have
        program_counter_internal = program_counter_i + 32'd4;

        take_branch_internal = NO_TAKE_BRANCH;
        flush_pipeline_o = take_branch_internal;
        program_counter_o = 'x;

        casez(op)
            COND_BRANCH: begin
                program_counter_o = program_counter_internal + immediate_i;
                casez(condition)
                    EQ: take_branch_internal = (status_reg_i.zero_flag == 1'b1);
                    NE: take_branch_internal = (status_reg_i.zero_flag == 1'b0);
                    CS: take_branch_internal = (status_reg_i.carry_flag == 1'b1);
                    CC: take_branch_internal = (status_reg_i.carry_flag == 1'b0);
                    MI: take_branch_internal = (status_reg_i.negative_flag == 1'b1);
                    PL: take_branch_internal = (status_reg_i.negative_flag == 1'b0);
                    VS: take_branch_internal = (status_reg_i.overflow_flag == 1'b1);
                    VC: take_branch_internal = (status_reg_i.overflow_flag == 1'b0);
                    HI: take_branch_internal = (status_reg_i.carry_flag == 1'b1 & status_reg_i.zero_flag == 1'b0);
                    LS: take_branch_internal = (status_reg_i.carry_flag == 1'b0 & status_reg_i.zero_flag == 1'b1);
                    GE: take_branch_internal = (status_reg_i.negative_flag == status_reg_i.overflow_flag);
                    LT: take_branch_internal = (status_reg_i.negative_flag != status_reg_i.overflow_flag);
                    GT: take_branch_internal = (status_reg_i.zero_flag & (status_reg_i.negative_flag == status_reg_i.overflow_flag));
                    LE: take_branch_internal = (status_reg_i.zero_flag == 1 || (status_reg_i.negative_flag != status_reg_i.overflow_flag));
                    AL: take_branch_internal = TAKE_BRANCH;
                default: ;
                endcase
            end
            UNCOND_BRANCH: begin
                take_branch_internal = TAKE_BRANCH;
                program_counter_o =    program_counter_internal + immediate_i;
            end
        default;
        endcase 

        take_branch_o = is_valid_i & take_branch_internal;
        flush_pipeline_o = is_valid_i & take_branch_internal;
    end

endmodule