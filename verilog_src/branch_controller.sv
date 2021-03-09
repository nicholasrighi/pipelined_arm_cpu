`include "GENERAL_DEFS.svh"

module branch_controller(
                            input logic                 clk_i,
                            input logic                 reset_i,
                            input logic                 is_valid_i,
                            input status_register       status_reg_i,
                            // verilator lint_off UNUSED
                            input instruction           instruction_i,
                            // verilator lint_on UNUSED
                            input logic [WORD-1:0]      program_counter_i,
                            input logic [WORD-1:0]      reg_data_1_i,
                            // verilator lint_off UNUSED
                            // TODO: remove reg_data_1 from branch controller, not needed
                            input logic [WORD-1:0]      reg_data_2_i,
                            // verilator lint_on UNUSED
                            input logic [WORD-1:0]      immediate_i,

                            output take_branch_ctrl_sig take_branch_o,
                            output flush_pipeline_sig   flush_pipeline_o,
                            output logic [WORD-1:0]     program_counter_o
                        );

    branch_link_status next_branch_link;
    branch_link_status stored_branch_link;
    logic take_branch_internal;
    logic [3:0] branch_condition;

    always_comb begin

        branch_condition =  instruction_i[11:8];
        next_branch_link =  NO_STORE_BRANCH;

        take_branch_internal =  NO_TAKE_BRANCH;
        program_counter_o =     'x;

        casez(instruction_i.op)
            COND_BRANCH: begin
                program_counter_o = program_counter_i + immediate_i;
                casez(branch_condition)
                    EQ: take_branch_internal = (status_reg_i.zero_flag == 1'b1);
                    NE: take_branch_internal = (status_reg_i.zero_flag == 1'b0);
                    CS: take_branch_internal = (status_reg_i.carry_flag == 1'b1);
                    CC: take_branch_internal = (status_reg_i.carry_flag == 1'b0);
                    MI: take_branch_internal = (status_reg_i.negative_flag == 1'b1);
                    PL: take_branch_internal = (status_reg_i.negative_flag == 1'b0);
                    VS: take_branch_internal = (status_reg_i.overflow_flag == 1'b1);
                    VC: take_branch_internal = (status_reg_i.overflow_flag == 1'b0);
                    HI: take_branch_internal = (status_reg_i.carry_flag == 1'b1 & status_reg_i.zero_flag == 1'b0);
                    LS: take_branch_internal = (status_reg_i.carry_flag == 1'b0 | status_reg_i.zero_flag == 1'b1);
                    GE: take_branch_internal = (status_reg_i.negative_flag == status_reg_i.overflow_flag);
                    LT: take_branch_internal = (status_reg_i.negative_flag != status_reg_i.overflow_flag);
                    GT: take_branch_internal = (status_reg_i.zero_flag == 1'b0 & (status_reg_i.negative_flag == status_reg_i.overflow_flag));
                    LE: take_branch_internal = (status_reg_i.zero_flag == 1'b1 || (status_reg_i.negative_flag != status_reg_i.overflow_flag));
                    AL: take_branch_internal = TAKE_BRANCH;
                default: ;
                endcase
            end
            UNCOND_BRANCH: begin
                take_branch_internal = TAKE_BRANCH;
                program_counter_o =    program_counter_i + immediate_i;
            end
            SPECIAL: begin
               casez(instruction_i[9:6])
                    ADD_REG_SPECIAL: begin
                       // we only take this branch if the PC is the destination register
                       if ({instruction_i[7],instruction_i[2:0]} == PC_REG_NUM) begin
                          take_branch_internal =    TAKE_BRANCH;
                          program_counter_o =       program_counter_i + reg_data_1_i; 
                       end
                    end
                    MOVE_REG_SPECIAL: begin
                       // we only take this branch if the PC is the destination register
                       if ({instruction_i[7],instruction_i[2:0]} == PC_REG_NUM) begin
                          take_branch_internal =     TAKE_BRANCH;
                          program_counter_o =        reg_data_1_i; 
                       end
                    end
                    BRANCH_LINK_EXCH,
                    BRANCH_EXCH: begin
                        take_branch_internal =      TAKE_BRANCH; 
                        program_counter_o =         reg_data_1_i;
                    end
                default: ;
               endcase 
            end
            TWO_WORD_INST_1,
            TWO_WORD_INST_2,
            TWO_WORD_INST_3: begin
               if (stored_branch_link == TAKE_BRANCH) begin
                   take_branch_internal = TAKE_BRANCH;
                   program_counter_o =    program_counter_i + immediate_i;
                   next_branch_link =     NO_STORE_BRANCH;
               end
               else begin
                   next_branch_link = STORE_BRANCH;
               end
            end
        default:;
        endcase 

        // need to AND is_valid signal with take branch and pipeline signal to prevent an invalid instruction from branching
        take_branch_o = take_branch_ctrl_sig'(is_valid_i & take_branch_internal);
        flush_pipeline_o = flush_pipeline_sig'(is_valid_i & take_branch_internal);
    end

    always_ff @(posedge clk_i) begin
        if (reset_i)
            stored_branch_link <= NO_STORE_BRANCH;
        else 
            stored_branch_link <= next_branch_link;
    end

endmodule