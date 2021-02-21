`include "GENERAL_DEFS.svh"

module reg_addr_decoder(
                        input instruction instruction_i,

                        output logic [ADDR_WIDTH-1:0] reg_addr_1_o,
                        output logic [ADDR_WIDTH-1:0] reg_addr_2_o,
                        output logic [ADDR_WIDTH-1:0] reg_dest_addr_o
                        );

    always_comb begin
        reg_addr_1_o =      'x;
        reg_addr_2_o =      'x;
        reg_dest_addr_o =   'x;
        casez (instruction_i.op)
            SHIFT_IMM: begin
               casez (instruction_i[13:9])
                    LEFT_SHIFT_L_IM, 
                    RIGHT_SHIFT_L_IM,
                    RIGHT_SHIFT_A_IM: begin
                        reg_addr_1_o =      ADDR_WIDTH'(instruction_i[5:3]);  
                        reg_dest_addr_o =   ADDR_WIDTH'(instruction_i[2:0]);
                    end
                    ADD_REG, SUB_REG: begin
                        reg_addr_1_o =      ADDR_WIDTH'(instruction_i[5:3]);
                        reg_addr_2_o =      ADDR_WIDTH'(instruction_i[8:6]);
                        reg_dest_addr_o =   ADDR_WIDTH'(instruction_i[2:0]);
                    end
                    ADD_3_IMM, SUB_3_IMM: begin
                        reg_addr_1_o =      ADDR_WIDTH'(instruction_i[5:3]);
                        reg_dest_addr_o =   ADDR_WIDTH'(instruction_i[2:0]);
                    end
                    MOV_8_IMM: reg_dest_addr_o =    ADDR_WIDTH'(instruction_i[10:8]);
                    CMP_8_IMM: reg_addr_1_o =       ADDR_WIDTH'(instruction_i[10:8]);
                    ADD_8_IMM, 
                    SUB_8_IMM: begin
                        reg_addr_1_o =      ADDR_WIDTH'(instruction_i[10:8]);
                        reg_dest_addr_o =   ADDR_WIDTH'(instruction_i[10:8]);
                    end 
                    default: ;
               endcase 
            end
            DATA_PROCESSING: begin
                reg_addr_1_o =      4'(instruction_i[2:0]);
                reg_addr_2_o =      4'(instruction_i[5:3]);
                reg_dest_addr_o =   4'(instruction_i[2:0]);
            end
            LOAD_LITERAL: begin
                reg_addr_1_o =      PC_REG_NUM;
                reg_dest_addr_o =   4'(instruction_i[10:8]);
            end
            default: ;
        endcase
    end



endmodule