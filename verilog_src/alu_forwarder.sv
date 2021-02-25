`include "GENERAL_DEFS.svh"

module alu_forwarder(
                        input mem_write_signal       write_en_MEM_i,
                        input mem_write_signal       write_en_WB_i,
                        input logic [ADDR_WIDTH-1:0] reg_1_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_2_addr_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_MEM_i,
                        input logic [ADDR_WIDTH-1:0] reg_dest_WB_i,

                        output forwarding_data_source alu_input_1_ctrl_sig_o,
                        output forwarding_data_source alu_input_2_ctrl_sig_o 
                    );

    always_comb begin
        if (reg_1_addr_i == reg_dest_MEM_i && (write_en_MEM_i == MEM_WRITE))
            alu_input_1_ctrl_sig_o = FROM_MEM;
        else if (reg_1_addr_i == reg_dest_WB_i && (write_en_WB_i == MEM_WRITE))
            alu_input_1_ctrl_sig_o = FROM_WB;
        else
            alu_input_1_ctrl_sig_o = FROM_DECODE;

        if (reg_2_addr_i == reg_dest_MEM_i && (write_en_MEM_i == MEM_WRITE))
            alu_input_2_ctrl_sig_o = FROM_MEM;
        else if (reg_2_addr_i == reg_dest_WB_i && (write_en_WB_i == MEM_WRITE))
            alu_input_2_ctrl_sig_o = FROM_WB;
        else
            alu_input_2_ctrl_sig_o = FROM_DECODE;
    end

endmodule