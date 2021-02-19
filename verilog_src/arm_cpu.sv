`include "GENERAL_DEFS.svh"

module arm_cpu(
                input logic clk_i,
                input logic reset_i
                );


    //////////////////////////////////////
    //      PROGRAM COUNTER SIGNAL      //
    //////////////////////////////////////
    logic [WORD-1:0] pc_PC_TO_FETCH;

    //////////////////////////////////////
    //      INSTRUCTION MEMORY SIGNALS  //
    //////////////////////////////////////
    // verilator lint_off UNUSED
    logic [HALF_WORD-1:0] instruction_FETCH_TO_DECODE;
    // verilator lint_on UNUSED


    //////////////////////////////////////
    //      DECODE STAGE SIGNALS        //
    //////////////////////////////////////
    // verilator lint_off UNUSED
    mem_write_signal        mem_write_en_DECODE_TO_EXE;
    mem_read_signal         mem_read_en_DECODE_TO_EXE;
    reg_file_write_sig      reg_file_write_en_DECODE_TO_EXE;
    reg_file_data_source    reg_file_input_ctrl_sig_DECODE_TO_EXE;
    alu_input_source        alu_input_1_select_DECODE_TO_EXE;
    alu_input_source        alu_input_2_select_DECODE_TO_EXE;
    update_flag_sig         update_flag_DECODE_TO_EXE;
    pipeline_ctrl_sig       pipeline_ctrl_sig_DECODE_TO_EXE;
    alu_control_signal      alu_control_signal_DECODE_TO_EXE;
    logic [4:0]             accumulator_imm_DECODE_TO_EXE;
    logic [ADDR_WIDTH-1:0]  reg_1_source_addr_DECODE_TO_EXE;
    logic [ADDR_WIDTH-1:0]  reg_2_source_addr_DECODE_TO_EXE;
    logic [ADDR_WIDTH-1:0]  reg_dest_addr_DECODE_TO_EXE;
    logic [WORD-1:0]        immediate_DECODE_TO_EXE;
    logic [WORD-1:0]        reg_1_data_DECODE_TO_EXE;
    logic [WORD-1:0]        reg_2_data_DECODE_TO_EXE;
    logic [WORD-1:0]        program_counter_DECODE_TO_EXE;
    logic [WORD-1:0]        stack_pointer_DECODE_TO_EXE;
    // verilator lint_on UNUSED


    //////////////////////////////////////
    //      WB TO DECODE STAGE          //
    //////////////////////////////////////
    // verilator lint_off UNDRIVEN
    logic                   reg_file_write_en_WB_TO_DECODE;
    logic [WORD-1:0]        reg_data_WB_TO_DECODE;
    // verilator lint_on UNDRIVEN

    program_counter pc_module(
                                .clk_i(clk_i),
                                .reset_i(reset_i),

                                .program_counter_o(pc_PC_TO_FETCH)
                            );

    instruction_mem instruction_unit(
                                .clk_i(clk_i),
                                .reset_i(reset_i),
                                
                                .program_counter_i(pc_PC_TO_FETCH),
                                .instruction_o(instruction_FETCH_TO_DECODE)
                            );


    decode_block    d_block(
                        .clk_i(clk_i),
                        .reset_i(reset_i),
                        .reg_file_write_en_i(reg_file_write_en_WB_TO_DECODE),
                        .instruction_i(instruction_FETCH_TO_DECODE),
                        .reg_data_i(reg_data_WB_TO_DECODE),
                        .program_counter_i(pc_PC_TO_FETCH),

                        .mem_write_en_o(mem_write_en_DECODE_TO_EXE),
                        .mem_read_en_o(mem_read_en_DECODE_TO_EXE),
                        .reg_file_write_en_o(reg_file_write_en_DECODE_TO_EXE),
                        .reg_file_input_ctrl_sig_o(reg_file_input_ctrl_sig_DECODE_TO_EXE),
                        .alu_input_1_select_o(alu_input_1_select_DECODE_TO_EXE),
                        .alu_input_2_select_o(alu_input_2_select_DECODE_TO_EXE),
                        .alu_control_signal_o(alu_control_signal_DECODE_TO_EXE),
                        .update_flag_o(update_flag_DECODE_TO_EXE),
                        .pipeline_ctrl_sig_o(pipeline_ctrl_sig_DECODE_TO_EXE),
                        .accumulator_imm_o(accumulator_imm_DECODE_TO_EXE),
                        .reg_1_source_addr_o(reg_1_source_addr_DECODE_TO_EXE),
                        .reg_2_source_addr_o(reg_2_source_addr_DECODE_TO_EXE),
                        .reg_dest_addr_o(reg_dest_addr_DECODE_TO_EXE),
                        .immediate_o(immediate_DECODE_TO_EXE),
                        .reg_1_data_o(reg_1_data_DECODE_TO_EXE),
                        .reg_2_data_o(reg_2_data_DECODE_TO_EXE),
                        .program_counter_o(program_counter_DECODE_TO_EXE),
                        .stack_pointer_o(stack_pointer_DECODE_TO_EXE)
                        );

endmodule