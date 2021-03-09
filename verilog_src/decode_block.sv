`include "GENERAL_DEFS.svh"

module decode_block(
                        input logic                   clk_i,
                        input logic                   reset_i,
                        input logic                   is_valid_i,          
                        input logic                   reg_file_write_en_i,
                        input mem_read_signal         mem_read_EXE_i,
                        input logic [ADDR_WIDTH-1:0]  mem_reg_dest_addr_i,
                        input logic [ADDR_WIDTH-1:0]  reg_dest_addr_i,
                        input instruction             instruction_i,
                        input flush_pipeline_sig      flush_pipeline_i,
                        input logic [WORD-1:0]        reg_data_i,
                        input logic [WORD-1:0]        program_counter_i,

                        output update_flag_sig        update_flag_o,
                        output mem_write_signal       mem_write_en_o,
                        output mem_read_signal        mem_read_en_o,
                        output reg_file_write_sig     reg_file_write_en_o,
                        output reg_file_data_source   reg_file_input_ctrl_sig_o,
                        output alu_input_source       alu_input_1_select_o,
                        output alu_input_source       alu_input_2_select_o,
                        output stall_pipeline_sig     pipeline_ctrl_sig_o,
                        output alu_control_signal     alu_control_signal_o,
                        output reg_2_reg_3_select_sig reg_2_reg_3_select_sig_o,
                        output logic                  is_valid_o,
                        output instruction            instruction_o,
                        output branch_from_wb         branch_from_wb_o,
                        output logic [ADDR_WIDTH-1:0] reg_1_source_addr_o,
                        output logic [ADDR_WIDTH-1:0] reg_2_source_addr_o,
                        output logic [ADDR_WIDTH-1:0] reg_3_source_addr_o,
                        output logic [ADDR_WIDTH-1:0] reg_dest_addr_o,
                        output logic [WORD-1:0]       accumulator_imm_o,
                        output logic [WORD-1:0]       immediate_o,
                        output logic [WORD-1:0]       reg_1_data_o,
                        output logic [WORD-1:0]       reg_2_data_o,
                        output logic [WORD-1:0]       reg_3_data_o,
                        output logic [WORD-1:0]       program_counter_o
                     );

            //////////////////////////////////////
            //    SIGNALS FROM CONTROL LOGIC    //
            //////////////////////////////////////
            mem_write_signal        mem_write_en_internal;
            mem_read_signal         mem_read_en_internal;
            // verilator lint_off UNUSED
            is_valid_sig            is_valid_from_controller_internal;
            // verilator lint_on UNUSED
            reg_file_write_sig      reg_file_write_en_internal;
            reg_file_data_source    reg_file_data_source_internal;   
            alu_input_source        alu_input_1_select_internal;
            alu_input_source        alu_input_2_select_internal;
            alu_control_signal      alu_control_signal_internal;
            update_flag_sig         update_flag_internal;
            stall_pipeline_sig      stall_pipeline_controller_internal;
            branch_from_wb          branch_from_wb_internal;
            reg_addr_data_source    reg_file_addr_2_source_internal;
            reg_addr_data_source    reg_dest_addr_source_internal;
            reg_2_reg_3_select_sig  select_reg_2_reg_3_sig_internal;
            logic [ADDR_WIDTH-1:0]  reg_file_addr_o;
            logic [WORD-1:0]        accumulator_imm_internal;

            //////////////////////////////////////
            //    SIGNALS FROM ADDR DECODER     //
            //////////////////////////////////////
            logic [ADDR_WIDTH-1:0]  reg_addr_1_from_addr_decoder; 
            logic [ADDR_WIDTH-1:0]  reg_addr_2_from_addr_decoder;
            logic [ADDR_WIDTH-1:0]  reg_addr_3_from_addr_decoder;
            logic [ADDR_WIDTH-1:0]  reg_dest_addr_from_addr_decoder;

            //////////////////////////////////////
            //    SIGNALS FROM IMMEDIATE GEN    //
            //////////////////////////////////////
            logic [WORD-1:0]  immediate_internal;

            //////////////////////////////////////
            //    SIGNALS FOR REG ADDRESSES     //
            //////////////////////////////////////
            logic [ADDR_WIDTH-1:0]  final_reg_2_addr_internal;
            logic [ADDR_WIDTH-1:0]  final_reg_dest_addr_internal;

            //////////////////////////////////////
            //    SIGNALS FROM HAZARD DETECTOR  //
            //////////////////////////////////////
            stall_pipeline_sig stall_pipeline_hazard_internal;
            logic              hazard_detector_invaidate_internal;

            //////////////////////////////////////
            //    INTERNAL ONLY LOGIC SIGNALS   //
            //////////////////////////////////////
            branch_from_wb    branch_from_wb_to_reg;
            // verilator lint_off UNUSED
            //is_valid_sig   final_is_valid_internal;
            // verilator lint_on UNUSED

            always_comb begin

               // if the current values being evaluated aren't valid, then the controller and hazard detectors 
               // stall_pipeline signals aren't relevant. We always need to AND the is_valid_i signal with any control logic that 
               // is used 
               // TODO: This flag is for detecting invalid instructions. Not sure if we need to do this, but could be useful later
               //final_is_valid_internal = is_valid_i & is_valid_from_controller_internal & stall_pipeline_hazard_internal;

               // If we decide that we're branching during the WB stage, then we need to flush the instructions currently in the 
               // fetch stage
               branch_from_wb_to_reg =  is_valid_i & branch_from_wb_internal;
               pipeline_ctrl_sig_o = (is_valid_i & (stall_pipeline_hazard_internal | stall_pipeline_controller_internal));

               if (reg_file_addr_2_source_internal == ADDR_FROM_INSTRUCTION)
                  final_reg_2_addr_internal = reg_addr_2_from_addr_decoder;
               else
                  final_reg_2_addr_internal = reg_file_addr_o;
               
               if (reg_dest_addr_source_internal == ADDR_FROM_INSTRUCTION)
                  final_reg_dest_addr_internal = reg_dest_addr_from_addr_decoder;
               else
                  final_reg_dest_addr_internal = reg_file_addr_o;
            end

            hazard_detector haz_detect(
                                       .mem_read_EXE_i(mem_read_EXE_i),
                                       .dest_addr_reg_EXE_i(mem_reg_dest_addr_i),
                                       .source_reg_1_DECODE_i(reg_addr_1_from_addr_decoder),
                                       .source_reg_2_DECODE_i(final_reg_2_addr_internal),
                                       
                                       .stall_pipeline_o(stall_pipeline_hazard_internal),
                                       .hazard_detector_invaidate_o(hazard_detector_invaidate_internal)
                                       );

            cpu_controller control_module(
                                        .clk_i(clk_i),
                                        .reset_i(reset_i),
                                        .is_valid_i(is_valid_i),
                                        .instruction_i(instruction_i),

                                        .mem_write_en_o(mem_write_en_internal),
                                        .mem_read_en_o(mem_read_en_internal),
                                        .is_valid_o(is_valid_from_controller_internal),
                                        .reg_write_en_o(reg_file_write_en_internal),
                                        .reg_file_data_source_o(reg_file_data_source_internal),
                                        .alu_input_1_select_o(alu_input_1_select_internal),
                                        .alu_input_2_select_o(alu_input_2_select_internal),
                                        .alu_control_signal_o(alu_control_signal_internal),
                                        .update_flag_o(update_flag_internal),
                                        .pipeline_ctrl_signal_o(stall_pipeline_controller_internal),
                                        .branch_from_wb_o(branch_from_wb_internal),
                                        .accumulator_imm_o(accumulator_imm_internal),
                                        .reg_file_addr_o(reg_file_addr_o),
                                        .reg_file_addr_2_source_o(reg_file_addr_2_source_internal),
                                        .reg_dest_addr_source_o(reg_dest_addr_source_internal),
                                        .reg_2_reg_3_select_sig_o(select_reg_2_reg_3_sig_internal)
                                       );

            reg_addr_decoder addr_decoder(
                                       .instruction_i(instruction_i),

                                       .reg_addr_1_o(reg_addr_1_from_addr_decoder),
                                       .reg_addr_2_o(reg_addr_2_from_addr_decoder),
                                       .reg_addr_3_o(reg_addr_3_from_addr_decoder),
                                       .reg_dest_addr_o(reg_dest_addr_from_addr_decoder)
                                        );   

            imm_gen  immediate_generator(
                                       .clk_i(clk_i),
                                       .instruction_i(instruction_i),

                                       .immediate_value_o(immediate_internal)
                                       );

            clocked_reg_file reg_file (
                                       .clk_i(clk_i),
                                       .write_en_i(reg_file_write_en_i),
                                       .read_addr_1_i(reg_addr_1_from_addr_decoder),
                                       .read_addr_2_i(final_reg_2_addr_internal),
                                       .read_addr_3_i(reg_addr_3_from_addr_decoder),
                                       .write_addr_i(reg_dest_addr_i),
                                       .reg_data_i(reg_data_i),
                                       .program_counter_i(program_counter_i),

                                       .reg_data_1_o(reg_1_data_o),
                                       .reg_data_2_o(reg_2_data_o),
                                       .reg_data_3_o(reg_3_data_o),
                                       .program_counter_o(program_counter_o)
            );

            decode_execution_register decode_exe_reg(
                                        .clk_i(clk_i),
                                        .reset_i(reset_i),
                                        .mem_write_en_i(mem_write_en_internal),
                                        .mem_read_en_i(mem_read_en_internal),
                                        .reg_file_write_en_i(reg_file_write_en_internal),
                                        .reg_file_input_ctrl_sig_i(reg_file_data_source_internal),
                                        .alu_input_1_select_i(alu_input_1_select_internal),
                                        .alu_input_2_select_i(alu_input_2_select_internal),
                                        .alu_control_signal_i(alu_control_signal_internal),
                                        .update_flag_i(update_flag_internal),
                                        .hazard_detector_invaidate_i(hazard_detector_invaidate_internal),
                                        .is_valid_i(is_valid_i),
                                        .branch_from_wb_i(branch_from_wb_to_reg),
                                        .flush_pipeline_i(flush_pipeline_i),
                                        .instruction_i(instruction_i),
                                        .accumulator_imm_i(accumulator_imm_internal),
                                        .immediate_i(immediate_internal),
                                        .reg_1_source_addr_i(reg_addr_1_from_addr_decoder),
                                        .reg_2_source_addr_i(final_reg_2_addr_internal),
                                        .reg_3_source_addr_i(reg_addr_3_from_addr_decoder),
                                        .reg_dest_addr_i(final_reg_dest_addr_internal),
                                        .reg_2_reg_3_select_sig_i(select_reg_2_reg_3_sig_internal),
                                        .program_counter_i(program_counter_i),

                                        .mem_write_en_o(mem_write_en_o),
                                        .mem_read_en_o(mem_read_en_o),
                                        .reg_file_write_en_o(reg_file_write_en_o),
                                        .reg_file_input_ctrl_sig_o(reg_file_input_ctrl_sig_o),
                                        .alu_input_1_select_o(alu_input_1_select_o),
                                        .alu_input_2_select_o(alu_input_2_select_o),
                                        .alu_control_signal_o(alu_control_signal_o),
                                        .update_flag_o(update_flag_o),
                                        .instruction_o(instruction_o),
                                        .is_valid_o(is_valid_o),
                                        .branch_from_wb_o(branch_from_wb_o),
                                        .accumulator_imm_o(accumulator_imm_o),
                                        .immediate_o(immediate_o),
                                        .reg_1_source_addr_o(reg_1_source_addr_o),
                                        .reg_2_source_addr_o(reg_2_source_addr_o),
                                        .reg_3_source_addr_o(reg_3_source_addr_o),
                                        .reg_dest_addr_o(reg_dest_addr_o),
                                        .reg_2_reg_3_select_sig_o(reg_2_reg_3_select_sig_o),
                                        .program_counter_o(program_counter_o)
                                          );
endmodule