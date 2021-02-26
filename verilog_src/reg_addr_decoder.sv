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
                if (instruction_i[9:6] == NOT)
                   reg_addr_1_o =   4'(instruction_i[5:3]);
                else
                    reg_addr_1_o =  4'(instruction_i[2:0]);

                reg_addr_2_o =      4'(instruction_i[5:3]);
                reg_dest_addr_o =   4'(instruction_i[2:0]);
            end
            SPECIAL: begin
                casez(instruction_i[9:6])
                    ADD_REG_SPECIAL: begin
                        reg_addr_1_o =  4'(instruction_i[2:0]);
                        reg_addr_2_o =  4'(instruction_i[6:3]);  
                        reg_dest_addr_o = {instruction_i[7],instruction_i[2:0]};
                    end
                    MOVE_REG_SPECIAL: begin
                        reg_addr_1_o    = instruction_i[6:3];
                        reg_dest_addr_o = {instruction_i[7], instruction_i[2:0]};
                    end
                    CMP_REG_SPECIAL: begin
                       reg_addr_1_o = {instruction_i[7],instruction_i[2:0]};
                       reg_addr_2_o = instruction_i[6:3];
                    end
                    default: ;
                endcase
            end
            LOAD_LITERAL: begin
                reg_addr_1_o =      PC_REG_NUM;
                reg_dest_addr_o =   4'(instruction_i[10:8]);
            end
            GEN_PC_REL: begin
                reg_addr_1_o =      PC_REG_NUM;
                reg_dest_addr_o =   4'(instruction_i[10:8]);
            end
            GEN_SP_REL: begin
                reg_addr_1_o =      SP_REG_NUM;
                reg_dest_addr_o =   4'(instruction_i[10:8]);
            end
            MIS_16_BIT: begin
                casez(instruction_i[11:5])
                    ADD_IMM_SP, 
                    SUB_IMM_SP: begin
                        reg_addr_1_o =      SP_REG_NUM;
                        reg_dest_addr_o =   SP_REG_NUM; 
                    end
                    S_EXTEND_HW,
                    S_EXTEND_BYTE,
                    UN_S_EXTEND_HW,
                    UN_S_EXTEND_BYTE,
                    BYTE_REV_W,
                    BYTE_REV_P_HW,
                    BYTE_REV_S_HW: begin
                        reg_addr_1_o =      4'(instruction_i[5:3]);
                        reg_dest_addr_o =   4'(instruction_i[2:0]);
                    end
                    PUSH_MUL_REG,
                    POP_MUL_REG: begin
                        reg_addr_1_o =      SP_REG_NUM; 
                        reg_dest_addr_o =   SP_REG_NUM;
                    end
                    default:    ;
                endcase
            end
            LOAD_STORE_REG: begin
                reg_addr_1_o =      4'(instruction_i[5:3]);
                reg_addr_2_o =      4'(instruction_i[8:6]);
                reg_dest_addr_o =   4'(instruction_i[2:0]);
            end
            LOAD_STORE_IMM,
            LOAD_STORE_BYTE,
            LOAD_STORE_HW: begin
                reg_addr_1_o =      4'(instruction_i[5:3]);
                reg_dest_addr_o =   4'(instruction_i[2:0]);
            end 
            LOAD_STORE_SP_R: begin
                reg_addr_1_o =      SP_REG_NUM;
                reg_dest_addr_o =   4'(instruction_i[10:8]); 
            end
            STORE_MULT_REG,
            LOAD_MULT_REG: reg_addr_1_o =   4'(instruction_i[10:8]);
            default: ;
        endcase
    end
endmodule