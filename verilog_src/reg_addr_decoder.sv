`include "GENERAL_DEFS.svh"

module reg_addr_decoder(
                        input instruction instruction_i,

                        output logic [ADDR_WIDTH-1:0] reg_addr_1_o,
                        output logic [ADDR_WIDTH-1:0] reg_addr_2_o,
                        output logic [ADDR_WIDTH-1:0] reg_dest_addr_o
                        );

    always_comb begin
        // These defaults are used by the most instructions
        reg_addr_1_o = 4'(instruction_i[5:3]);
        reg_addr_2_o = 4'(instruction_i[8:6]);
        reg_dest_addr_o = 4'(instruction_i[2:0]);
        casez (instruction_i.op)

            SHIFT_IMM: begin
               casez (instruction_i[13:9])
                    ADD_8_IMM, SUB_8_IMM, CMP_8_IMM: begin
                        reg_addr_1_o = 4'(instruction_i[10:8]);
                        reg_dest_addr_o = 4'(instruction_i[10:8]); 
                    end
                    default: ;
               endcase 
            end

            DATA_PROCESSING: begin
                casez(instruction_i[9:6]) 
                    ADD_W_CARRY, CMP_REG: reg_addr_2_o = 4'(instruction_i[2:0]);
                    default: ;
                endcase
            end

            default: begin
                reg_addr_1_o = 'x;
                reg_addr_2_o = 'x;
                reg_dest_addr_o = 'x;
            end
        endcase
        
    end



endmodule