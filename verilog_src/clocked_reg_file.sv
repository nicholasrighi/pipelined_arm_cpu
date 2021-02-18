`include "GENERAL_DEFS.svh"

module clocked_reg_file(
                            input logic clk_i,
                            input logic write_en_i,
                            input logic [ADDR_WIDTH-1:0] read_addr_1_i,
                            input logic [ADDR_WIDTH-1:0] read_addr_2_i,
                            input logic [ADDR_WIDTH-1:0] write_addr_i,
                            input logic [WORD-1:0] reg_data_i,
                            input logic [WORD-1:0] program_counter_i,

                            output logic [WORD-1:0] reg_data_1_o,
                            output logic [WORD-1:0] reg_data_2_o,
                            output logic [WORD-1:0] program_counter_o,
                            output logic [WORD-1:0] stack_pointer_o
                        );

    localparam NUM_REGS = 16;
    localparam SP_REG_NUM = 13;
    localparam PC_REG_NUM = 15;

    // signals used to forward data from write back stage to execution stage if 
    // reading from the register that was written to
    logic stored_write_en;
    logic [3:0] stored_write_addr;
    logic [3:0] stored_read_1_addr;
    logic [3:0] stored_read_2_addr;
    logic [WORD-1:0] stored_read_1_data;
    logic [WORD-1:0] stored_read_2_data;
    logic [WORD-1:0] stored_write_data;

    // reg file data
    logic [WORD-1:0] reg_ram [NUM_REGS-1:0];

    initial begin
        for (integer i = 0; i < 32; i++) 
            reg_ram[i] = 32'b0;
    end

    // determine if we need to output forwarded data or old data
    always_comb begin
        // TOOD: Might need to change this in order to get around asycn read. Not sure 
        // if the memory compiler supports this. But will work for simulation for now
        program_counter_o = reg_ram[PC_REG_NUM];
        stack_pointer_o = reg_ram[SP_REG_NUM];

        reg_data_1_o = stored_read_1_data;
        reg_data_2_o = stored_read_2_data;

        if (stored_write_en && stored_read_1_addr == stored_write_addr)
            reg_data_1_o = stored_write_data;
        if (stored_write_en && stored_read_2_addr == stored_write_addr)
            reg_data_2_o = stored_write_data;
    end

    always_ff @(posedge clk_i) begin
        // the progam counter shouldn't be updated
        // by anything other than the program counter
        if (write_en_i && write_addr_i != PC_REG_NUM)
            reg_ram[write_addr_i]   <= reg_data_i;

        // store forwarding data
        stored_write_en     <= write_en_i;
        stored_write_addr   <= write_addr_i;
        stored_read_1_addr  <= read_addr_1_i;
        stored_read_2_addr  <= read_addr_2_i;
        stored_read_1_data  <= reg_ram[read_addr_1_i];
        stored_read_2_data  <= reg_ram[read_addr_2_i];
        stored_write_data   <= reg_data_i; 
    end

    always_ff @(posedge clk_i) begin
        reg_ram[PC_REG_NUM] <= program_counter_i;
    end

endmodule