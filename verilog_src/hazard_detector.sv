`include "GENERAL_DEFS.svh"

module hazard_detector(
                        input logic mem_read_EXE_i,
                        input logic [ADDR_WIDTH-1:0] dest_addr_reg_EXE_i,
                        input logic [ADDR_WIDTH-1:0] source_reg_1_DECODE_i,
                        input logic [ADDR_WIDTH-1:0] source_reg_2_DECODE_i,
    
                        output stall_pipeline_sig stall_pipeline_o
                        );

    always_comb begin
        if (mem_read_EXE_i && 
            ((dest_addr_reg_EXE_i == source_reg_1_DECODE_i) || (dest_addr_reg_EXE_i == source_reg_2_DECODE_i)))
            stall_pipeline_o = STALL_PIPELINE;
        else
            stall_pipeline_o = NO_STALL_PIPELINE;
    end

endmodule