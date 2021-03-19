`include "GENERAL_DEFS.svh"

module hazard_detector(
                        input logic mem_read_EXE_i,
                        input logic [ADDR_WIDTH-1:0] dest_addr_reg_EXE_i,
                        input logic [ADDR_WIDTH-1:0] source_reg_1_DECODE_i,
                        input logic [ADDR_WIDTH-1:0] source_reg_2_DECODE_i,
                        input logic [ADDR_WIDTH-1:0] source_reg_3_DECODE_i,
    
                        output stall_pipeline_sig stall_pipeline_o,
                        output logic              hazard_detector_invaidate_o
                        );

    always_comb begin
        // a very important implication of this hazard detector is that it assumes mem_read and reg_write 
        // always occur together. This is important because if mem_read is asserted but reg_write isn't asserted, 
        // then the hazard detector can stall when there's no need to. This doesn't effect the functionality of the 
        // cpu, but it will negatively impact performance.
        if (mem_read_EXE_i && ( (dest_addr_reg_EXE_i == source_reg_1_DECODE_i) || (dest_addr_reg_EXE_i == source_reg_2_DECODE_i) 
            || (dest_addr_reg_EXE_i == source_reg_3_DECODE_i) ))

            stall_pipeline_o = STALL_PIPELINE;
        else
            stall_pipeline_o = NO_STALL_PIPELINE;
        
        hazard_detector_invaidate_o = stall_pipeline_o;
    end

endmodule