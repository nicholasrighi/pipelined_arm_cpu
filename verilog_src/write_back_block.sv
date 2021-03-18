`include "GENERAL_DEFS.svh"

module write_back_block(
                            input logic                 is_valid_i,
                            input reg_file_data_source  reg_data_ctrl_sig_i,
                            input reg_file_write_sig    reg_file_write_en_i,
                            input branch_from_wb        branch_from_wb_i,
                            input logic [ADDR_WIDTH-1:0] reg_dest_addr_i,
                            input logic [WORD-1:0]      alu_result_i,
                            input logic [WORD-1:0]      mem_data_i,

                            output reg_file_write_sig   reg_file_write_en_o,
                            output logic [WORD-1:0]     reg_data_o,
                            output branch_from_wb       branch_from_wb_o,
                            output logic [WORD-1:0]     program_counter_o,
                            output logic [ADDR_WIDTH-1:0]     reg_dest_addr_o
                       );

        always_comb begin

            program_counter_o = mem_data_i;
            branch_from_wb_o =  branch_from_wb'(branch_from_wb_i & is_valid_i);

            reg_dest_addr_o =       reg_dest_addr_i;
            // need to AND write_en with is_valid to ensure that we only write data when the signals are valid
            reg_file_write_en_o =   reg_file_write_sig'(reg_file_write_en_i & is_valid_i);
            reg_data_o =            '0;
            case(reg_data_ctrl_sig_i)
                FROM_ALU:           reg_data_o = alu_result_i;
                FROM_MEMORY:        reg_data_o = mem_data_i;
                default: ;
            endcase
        end

endmodule
