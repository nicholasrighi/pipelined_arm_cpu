`include "GENERAL_DEFS.svh"

module arm_cpu(
                input logic                 clk_i,
                input logic                 reset_i,
                input logic                 program_mem_write_en_i, 
                input logic [HALF_WORD-1:0] instruction_i,
                input logic [WORD-1:0]      instruction_addr_i,

                output logic [WORD-1:0]     data_o
                );

    //////////////////////////////////////
    //      PROGRAM COUNTER SIGNAL      //
    //////////////////////////////////////
    logic is_valid_PC_TO_FETCH;
    logic [WORD-1:0] pc_PC_TO_FETCH;

    //////////////////////////////////////
    //      INSTRUCTION MEMORY SIGNALS  //
    //////////////////////////////////////
    logic is_valid_FETCH_TO_DECODE;
    logic [HALF_WORD-1:0] instruction_FETCH_TO_DECODE;
    logic [WORD-1:0] instruction_fetch_addr_internal;
    logic [WORD-1:0] program_counter_FETCH_TO_DECODE;

    //////////////////////////////////////
    //      DECODE STAGE SIGNALS        //
    //////////////////////////////////////
    stall_pipeline_sig      pipeline_stall_FROM_DECODE;
    mem_write_signal        mem_write_en_DECODE_TO_EXE;
    mem_read_signal         mem_read_en_DECODE_TO_EXE;
    reg_file_write_sig      reg_file_write_en_DECODE_TO_EXE;
    reg_file_data_source    reg_file_input_ctrl_sig_DECODE_TO_EXE;
    alu_input_source        alu_input_1_select_DECODE_TO_EXE;
    alu_input_source        alu_input_2_select_DECODE_TO_EXE;
    update_flag_sig         update_flag_DECODE_TO_EXE;
    alu_control_signal      alu_control_signal_DECODE_TO_EXE;
    reg_2_reg_3_select_sig  reg_2_reg_3_select_DECODE_TO_EXE;
    instruction             instruction_DECODE_TO_EXE;
    branch_from_wb          branch_from_wb_DECODE_TO_EXE;
    logic                   is_valid_DECODE_TO_EXE;
    logic [ADDR_WIDTH-1:0]  reg_1_source_addr_DECODE_TO_EXE;
    logic [ADDR_WIDTH-1:0]  reg_2_source_addr_DECODE_TO_EXE;
    logic [ADDR_WIDTH-1:0]  reg_3_source_addr_DECODE_TO_EXE;
    logic [ADDR_WIDTH-1:0]  reg_dest_addr_DECODE_TO_EXE;
    logic [WORD-1:0]        accumulator_imm_DECODE_TO_EXE;
    logic [WORD-1:0]        immediate_DECODE_TO_EXE;
    logic [WORD-1:0]        reg_1_data_DECODE_TO_EXE;
    logic [WORD-1:0]        reg_2_data_DECODE_TO_EXE;
    logic [WORD-1:0]        reg_3_data_DECODE_TO_EXE;
    logic [WORD-1:0]        program_counter_DECODE_TO_EXE;

    //////////////////////////////////////
    //    EXECUTION STAGE SIGNALS       //
    //////////////////////////////////////
    logic                   is_valid_EXE_TO_MEM;
    mem_write_signal        mem_write_en_EXE_TO_MEM;
    reg_file_write_sig      reg_file_write_en_EXE_TO_MEM;
    reg_file_data_source    reg_file_data_source_EXE_TO_MEM;
    branch_from_wb          branch_from_wb_EXE_TO_MEM;
    logic [6:0]             opA_opB_EXE_TO_MEM;
    logic [ADDR_WIDTH-1:0]  reg_dest_addr_EXE_TO_MEM;
    logic [WORD-1:0]        alu_result_EXE_TO_MEM;
    logic [WORD-1:0]        reg_2_data_EXE_TO_MEM;
    
    // these are the branch control signals from the exe stage
    take_branch_ctrl_sig    take_branch_EXE_TO_PC;
    flush_pipeline_sig      flush_pipeline_FROM_EXE;
    logic [WORD-1:0]        program_counter_EXE_TO_PC;

    //////////////////////////////////////
    //     MEMORY STAGE SIGNALS         //
    //////////////////////////////////////
    logic                  is_valid_MEM_TO_WB;
    reg_file_data_source   reg_data_ctrl_sig_MEM_TO_WB;
    reg_file_write_sig     reg_file_write_en_MEM_TO_WB;
    branch_from_wb         branch_from_wb_MEM_TO_WB;
    logic [ADDR_WIDTH-1:0] reg_dest_addr_MEM_TO_WB;
    logic [WORD-1:0]       mem_data_MEM_TO_WB;
    logic [WORD-1:0]       alu_data_MEM_TO_WB;

    //////////////////////////////////////
    //      WB STAGE SIGNALS            //
    //////////////////////////////////////
    logic                  reg_file_write_en_WB_TO_DECODE;
    branch_from_wb         branch_from_wb_WB_TO_PC;
    logic [WORD-1:0]       program_counter_WB_TO_PC;
    logic [ADDR_WIDTH-1:0] reg_dest_addr_WB_TO_DECODE;
    logic [WORD-1:0]       reg_data_WB_TO_DECODE;

    //////////////////////////////////////
    //      MISC CONTROL SIGNALS        //
    //////////////////////////////////////
    flush_pipeline_sig final_flush_signal;

    always_comb begin

        final_flush_signal = flush_pipeline_sig'(flush_pipeline_FROM_EXE | branch_from_wb_WB_TO_PC);

        // this logic determines if we're writing to instruction mem (done during startup) 
        // reading instructions during program execution (done after startup)
        if (program_mem_write_en_i)
            instruction_fetch_addr_internal = instruction_addr_i;
        else
            instruction_fetch_addr_internal = pc_PC_TO_FETCH;
    end

    // if writing to register 0 put that data onto the data out line from the cpu so we can 
    // see the data in the waveform viewer
    always_ff @(posedge clk_i) begin
        if (reset_i)
            data_o <= '0;
        else if (reg_file_write_en_WB_TO_DECODE == REG_WRITE && reg_dest_addr_WB_TO_DECODE == 4'b0)
            data_o <= reg_data_WB_TO_DECODE;
    end

    program_counter pc_module(
                                .clk_i(clk_i),
                                .reset_i(reset_i),
                                .branch_from_wb_i(branch_from_wb_WB_TO_PC),
                                .pop_pc_value_i(program_counter_WB_TO_PC),
                                .take_branch_i(take_branch_EXE_TO_PC),
                                .stall_pipeline_i(pipeline_stall_FROM_DECODE),
                                .branch_pc_value_i(program_counter_EXE_TO_PC),

                                .is_valid_o(is_valid_PC_TO_FETCH),
                                .program_counter_o(pc_PC_TO_FETCH)
                            );

    instruction_mem instruction_unit(
                                .clk_i(clk_i),
                                .reset_i(reset_i),
                                .flush_pipeline_i(final_flush_signal),
                                .program_mem_write_en_i(program_mem_write_en_i),
                                .is_valid_i(is_valid_PC_TO_FETCH),
                                .stall_pipeline_i(pipeline_stall_FROM_DECODE),
                                .instruction_i(instruction_i),
                                .instruction_addr_i(instruction_fetch_addr_internal),

                                .is_valid_o(is_valid_FETCH_TO_DECODE), 
                                .instruction_o(instruction_FETCH_TO_DECODE),
                                .program_counter_o(program_counter_FETCH_TO_DECODE)
                            );

    decode_block    d_block(
                        .clk_i(clk_i),
                        .reset_i(reset_i),
                        .is_valid_i(is_valid_FETCH_TO_DECODE),
                        .flush_pipeline_i(final_flush_signal),
                        // the mem_read signal that leaves the decode block is the 
                        // signal that we want to read to determine if the instruction
                        // in the EXE stage is a load. So we simply AND the mem_read signal from decode
                        // with the is_valid signal from decode to determine if the EXE stage is reading
                        .mem_read_EXE_i(mem_read_signal'(mem_read_en_DECODE_TO_EXE & is_valid_DECODE_TO_EXE)),
                        .mem_reg_dest_addr_i(reg_dest_addr_DECODE_TO_EXE),
                        .reg_file_write_en_i(reg_file_write_en_WB_TO_DECODE),
                        .reg_data_i(reg_data_WB_TO_DECODE),
                        .reg_dest_addr_i(reg_dest_addr_WB_TO_DECODE),
                        .instruction_i(instruction_FETCH_TO_DECODE),
                        .program_counter_i(program_counter_FETCH_TO_DECODE),

                        .mem_write_en_o(mem_write_en_DECODE_TO_EXE),
                        .mem_read_en_o(mem_read_en_DECODE_TO_EXE),
                        .reg_file_write_en_o(reg_file_write_en_DECODE_TO_EXE),
                        .reg_file_input_ctrl_sig_o(reg_file_input_ctrl_sig_DECODE_TO_EXE),
                        .alu_input_1_select_o(alu_input_1_select_DECODE_TO_EXE),
                        .alu_input_2_select_o(alu_input_2_select_DECODE_TO_EXE),
                        .alu_control_signal_o(alu_control_signal_DECODE_TO_EXE),
                        .update_flag_o(update_flag_DECODE_TO_EXE),
                        .pipeline_ctrl_sig_o(pipeline_stall_FROM_DECODE),
                        .reg_2_reg_3_select_sig_o(reg_2_reg_3_select_DECODE_TO_EXE),
                        .is_valid_o(is_valid_DECODE_TO_EXE),
                        .branch_from_wb_o(branch_from_wb_DECODE_TO_EXE),
                        .instruction_o(instruction_DECODE_TO_EXE),
                        .accumulator_imm_o(accumulator_imm_DECODE_TO_EXE),
                        .reg_1_source_addr_o(reg_1_source_addr_DECODE_TO_EXE),
                        .reg_2_source_addr_o(reg_2_source_addr_DECODE_TO_EXE),
                        .reg_3_source_addr_o(reg_3_source_addr_DECODE_TO_EXE),
                        .reg_dest_addr_o(reg_dest_addr_DECODE_TO_EXE),
                        .immediate_o(immediate_DECODE_TO_EXE),
                        .reg_1_data_o(reg_1_data_DECODE_TO_EXE),
                        .reg_2_data_o(reg_2_data_DECODE_TO_EXE),
                        .reg_3_data_o(reg_3_data_DECODE_TO_EXE),
                        .program_counter_o(program_counter_DECODE_TO_EXE)
                        );

    execution_block exe_block(
                         .clk_i(clk_i),
                         .reset_i(reset_i),
                         .update_flag_i(update_flag_DECODE_TO_EXE),
                         .mem_write_en_i(mem_write_en_DECODE_TO_EXE),
                         .reg_file_write_en_i(reg_file_write_en_DECODE_TO_EXE),
                         .reg_file_data_source_i(reg_file_input_ctrl_sig_DECODE_TO_EXE),
                         .alu_input_1_select_i(alu_input_1_select_DECODE_TO_EXE),
                         .alu_input_2_select_i(alu_input_2_select_DECODE_TO_EXE),
                         .alu_control_signal_i(alu_control_signal_DECODE_TO_EXE),
                         .reg_write_en_MEM_i(reg_file_write_sig'(reg_file_write_en_EXE_TO_MEM & is_valid_EXE_TO_MEM)),
                         .reg_write_en_WB_i(reg_file_write_sig'(reg_file_write_en_MEM_TO_WB & is_valid_MEM_TO_WB)), 
                         .reg_2_reg_3_select_sig_i(reg_2_reg_3_select_DECODE_TO_EXE),
                         .branch_from_wb_i(branch_from_wb_DECODE_TO_EXE),
                         .is_valid_i(is_valid_DECODE_TO_EXE),
                         .instruction_i(instruction_DECODE_TO_EXE),
                         .reg_1_source_addr_i(reg_1_source_addr_DECODE_TO_EXE),
                         .reg_2_source_addr_i(reg_2_source_addr_DECODE_TO_EXE),
                         .reg_3_source_addr_i(reg_3_source_addr_DECODE_TO_EXE),
                         .reg_dest_addr_i(reg_dest_addr_DECODE_TO_EXE),
                         .reg_dest_MEM_i(reg_dest_addr_EXE_TO_MEM),  
                         .reg_dest_WB_i(reg_dest_addr_WB_TO_DECODE),
                         .accumulator_imm_i(accumulator_imm_DECODE_TO_EXE),
                         .immediate_i(immediate_DECODE_TO_EXE),
                         .reg_1_data_i(reg_1_data_DECODE_TO_EXE),
                         .reg_2_data_i(reg_2_data_DECODE_TO_EXE),
                         .reg_3_data_i(reg_3_data_DECODE_TO_EXE),
                         .reg_data_MEM_i(alu_result_EXE_TO_MEM), 
                         .reg_data_WB_i(reg_data_WB_TO_DECODE),
                         .program_counter_i(program_counter_DECODE_TO_EXE),
                         
                         .is_valid_o(is_valid_EXE_TO_MEM),
                         .branch_from_wb_o(branch_from_wb_EXE_TO_MEM),
                         .flush_pipeline_o(flush_pipeline_FROM_EXE),
                         .mem_write_en_o(mem_write_en_EXE_TO_MEM),
                         .opA_opB_o(opA_opB_EXE_TO_MEM),
                         .reg_file_write_en_o(reg_file_write_en_EXE_TO_MEM),
                         .reg_file_data_source_o(reg_file_data_source_EXE_TO_MEM),
                         .reg_dest_addr_o(reg_dest_addr_EXE_TO_MEM),
                         .alu_result_o(alu_result_EXE_TO_MEM),
                         .reg_2_data_o(reg_2_data_EXE_TO_MEM),
                         .take_branch_o(take_branch_EXE_TO_PC),
                         .program_counter_o(program_counter_EXE_TO_PC)
                        );
        
    memory_block mem_block(
                        .clk_i(clk_i),
                        .reset_i(reset_i),
                        .is_valid_i(is_valid_EXE_TO_MEM),
                        .mem_write_en_i(mem_write_en_EXE_TO_MEM),
                        .branch_from_wb_i(branch_from_wb_EXE_TO_MEM),
                        .reg_data_ctrl_sig_i(reg_file_data_source_EXE_TO_MEM),
                        .reg_file_write_en_i(reg_file_write_en_EXE_TO_MEM),
                        .opA_opB_i(opA_opB_EXE_TO_MEM[6:0]), 
                        .reg_dest_addr_i(reg_dest_addr_EXE_TO_MEM),
                        .stored_mem_data_i(reg_2_data_EXE_TO_MEM),
                        .alu_data_i(alu_result_EXE_TO_MEM),
                        
                        .is_valid_o(is_valid_MEM_TO_WB),
                        .branch_from_wb_o(branch_from_wb_MEM_TO_WB),
                        .reg_data_ctrl_sig_o(reg_data_ctrl_sig_MEM_TO_WB),
                        .reg_dest_addr_o(reg_dest_addr_MEM_TO_WB),
                        .reg_file_write_en_o(reg_file_write_en_MEM_TO_WB),
                        .mem_data_o(mem_data_MEM_TO_WB),
                        .alu_data_o(alu_data_MEM_TO_WB)
                        );

    write_back_block wb_block(
                        .is_valid_i(is_valid_MEM_TO_WB),
                        .branch_from_wb_i(branch_from_wb_MEM_TO_WB),
                        .reg_data_ctrl_sig_i(reg_data_ctrl_sig_MEM_TO_WB),
                        .reg_file_write_en_i(reg_file_write_en_MEM_TO_WB),
                        .reg_dest_addr_i(reg_dest_addr_MEM_TO_WB),
                        .alu_result_i(alu_data_MEM_TO_WB),
                        .mem_data_i(mem_data_MEM_TO_WB),

                        .reg_dest_addr_o(reg_dest_addr_WB_TO_DECODE),
                        .branch_from_wb_o(branch_from_wb_WB_TO_PC),
                        .program_counter_o(program_counter_WB_TO_PC),
                        .reg_file_write_en_o(reg_file_write_en_WB_TO_DECODE),
                        .reg_data_o(reg_data_WB_TO_DECODE)
                        );

endmodule