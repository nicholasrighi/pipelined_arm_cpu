`include "GENERAL_DEFS.svh"

module alu(
            input alu_control_signal        alu_ctrl_sig_i,
            input logic signed [WORD-1:0]   data_in_1_i,
            input logic signed [WORD-1:0]   data_in_2_i,

            output status_register          status_reg_o,
            output logic [WORD-1:0]         alu_result_o
          );

    // this is for holding 33 bit result of adds/substracts so we can determine
    // what condition flags to update 
    logic [WORD:0] extended_sum;

    always_comb begin

    alu_result_o = 'x;
    extended_sum = 'x;

    case (alu_ctrl_sig_i)
        // all shift instructions only allow the bottom byte of data_in_2 to be used for the shift value
        ALU_LEFT_SHIFT_L:       alu_result_o = data_in_1_i << data_in_2_i[BYTE-1:0];
        ALU_RIGHT_SHIFT_L:      alu_result_o = data_in_1_i >> data_in_2_i[BYTE-1:0];
        ALU_RIGHT_SHIFT_A:      alu_result_o = data_in_1_i >>> data_in_2_i[BYTE-1:0];
        ALU_ADD: begin                
                extended_sum = {1'b0,data_in_1_i} + {1'b0, data_in_2_i};
                alu_result_o = extended_sum[31:0];
        end
        ALU_SUB: begin                
                extended_sum = {1'b0,data_in_1_i} - {1'b0,data_in_2_i};
                alu_result_o = extended_sum[31:0]; 
        end
        ALU_AND:                alu_result_o = data_in_1_i & data_in_2_i;
        ALU_OR:                 alu_result_o = data_in_1_i | data_in_2_i;
        ALU_XOR:                alu_result_o = data_in_1_i ^ data_in_2_i;
        ALU_ROTATE_R:           alu_result_o = (data_in_1_i << (32-data_in_2_i[BYTE-1:0])) | (data_in_1_i >> data_in_2_i[BYTE-1:0]);
        ALU_MULT:               alu_result_o = WORD'(data_in_1_i * data_in_2_i); 
        ALU_NOT:                alu_result_o = ~data_in_1_i;
        ALU_BIT_CLEAR:          alu_result_o = data_in_1_i & (~data_in_2_i);
        ALU_S_EXTEND_HW:        alu_result_o = {{16{data_in_1_i[HALF_WORD-1]}},data_in_1_i[HALF_WORD-1:0]};
        ALU_S_EXTEND_BYTE:      alu_result_o = {{24{data_in_1_i[BYTE-1]}}, data_in_1_i[BYTE-1:0]};
        ALU_UN_S_EXTEND_HW:     alu_result_o = {{16{1'b0}},data_in_1_i[HALF_WORD-1:0]};
        ALU_UN_S_EXTEND_BYTE:   alu_result_o = {{24{1'b0}}, data_in_1_i[BYTE-1:0]};
        ALU_BYTE_REV_W:         alu_result_o = {data_in_1_i[BYTE-1:0], data_in_1_i[2*BYTE-1 -: BYTE], data_in_1_i[3*BYTE-1 -: BYTE], 
                                                data_in_1_i[4*BYTE-1 -: BYTE]};
        ALU_BYTE_REV_P_HW:      alu_result_o = {data_in_1_i[3*BYTE-1 -: BYTE], data_in_1_i[4*BYTE-1 -: BYTE], 
                                                data_in_1_i[BYTE-1 -: BYTE], data_in_1_i[2*BYTE-1 -: BYTE]};
        ALU_BYTE_REV_S_HW:      alu_result_o = {{16{data_in_1_i[BYTE-1]}}, data_in_1_i[BYTE-1 -: BYTE], data_in_1_i[2*BYTE-1 -: BYTE]}; 
    default: ;
    endcase

    status_reg_o.negative_flag = alu_result_o[WORD-1];
    status_reg_o.zero_flag =     (alu_result_o == 32'b0);
    
    // the overflow flag is simply the carry out of the extended sum
    status_reg_o.carry_flag =    extended_sum[WORD];      
    
    // overflow can only occur if the sign bits of input data are the same (the left XNOR checks for this)
    // if the sign bits are the same, then overflow occured if the result has a different sign than
    // the result. We can check for the sign of input/result being the same by XOR'ing the result sign
    // with the input sign. If the signs of the result/input are different and the inputs have the same sign
    // then overflow occured
    status_reg_o.overflow_flag = ~(data_in_1_i[WORD-1] ^ data_in_2_i[WORD-1]) & (extended_sum[WORD-1] ^ data_in_1_i[WORD-1]);

end

endmodule