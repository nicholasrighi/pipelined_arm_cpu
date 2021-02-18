`include "GENERAL_DEFS.svh"

module decode_execution_register   
                                   #(
                                        parameter DATA_WIDTH = WORD
                                   )
                                  (
                                    input logic                       clk_i,
                                    input logic                       reset_i,
                                    input mem_write_signal            mem_write_en_i,
                                    input mem_read_signal             mem_read_en_i,
                                    input reg_file_write_sig          reg_file_write_en_i,
                                    input reg_file_data_source        reg_file_input_ctrl_sig_i,
                                    input alu_input_source            alu_input_1_select_i,
                                    input alu_input_source            alu_input_2_select_i,
                                    input logic [4:0]                 accumulator_imm_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_1_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_2_source_addr_i,
                                    input logic [ADDR_WIDTH-1:0]      reg_dest_addr_i,
                                    input logic [DATA_WIDTH-1:0]      immediate_i,

                                    output mem_write_signal           mem_write_en_o,
                                    output mem_read_signal            mem_read_en_o,
                                    output reg_file_write_sig         reg_file_write_en_o,
                                    output reg_file_data_source       reg_file_input_ctrl_sig_o,
                                    output alu_input_source           alu_input_1_select_o,
                                    output alu_input_source           alu_input_2_select_o,
                                    output logic [4:0]                accumulator_imm_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_1_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_2_source_addr_o,
                                    output logic [ADDR_WIDTH-1:0]     reg_dest_addr_o,
                                    output logic [DATA_WIDTH-1:0]     immediate_o
                                    );

    always_ff @(posedge clk_i) begin
       if (reset_i) begin
            mem_write_en_o              <= NO_MEM_WRITE;
            mem_read_en_o               <= NO_MEM_READ;
            reg_file_write_en_o         <= NO_REG_WRITE;
            reg_file_input_ctrl_sig_o   <= FROM_ALU;
            alu_input_1_select_o        <= FROM_REG;
            alu_input_2_select_o        <= FROM_REG;
            accumulator_imm_o           <= '0;
            immediate_o                 <= '0;
            reg_1_source_addr_o         <= '0;
            reg_2_source_addr_o         <= '0;
            reg_dest_addr_o             <= '0;
       end 
       else begin
            mem_write_en_o              <= mem_write_en_i;
            mem_read_en_o               <= mem_read_en_i;
            reg_file_write_en_o         <= reg_file_write_en_i;
            reg_file_input_ctrl_sig_o   <= reg_file_input_ctrl_sig_i;
            alu_input_1_select_o        <= alu_input_1_select_i;
            alu_input_2_select_o        <= alu_input_2_select_i;
            accumulator_imm_o           <= accumulator_imm_i;
            immediate_o                 <= immediate_i;
            reg_1_source_addr_o         <= reg_1_source_addr_i;
            reg_2_source_addr_o         <= reg_2_source_addr_i;
            reg_dest_addr_o             <= reg_dest_addr_i;
       end
    end

endmodule