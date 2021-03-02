`include "GENERAL_DEFS.svh"

module clocked_reg_file(
                            input logic clk_i,
                            input logic write_en_i,
                            input logic [ADDR_WIDTH-1:0] read_addr_1_i,
                            input logic [ADDR_WIDTH-1:0] read_addr_2_i,
                            input logic [ADDR_WIDTH-1:0] read_addr_3_i,
                            input logic [ADDR_WIDTH-1:0] write_addr_i,
                            input logic [WORD-1:0] reg_data_i,
                            input logic [WORD-1:0] program_counter_i,

                            output logic [WORD-1:0] reg_data_1_o,
                            output logic [WORD-1:0] reg_data_2_o,
                            output logic [WORD-1:0] reg_data_3_o,
                            output logic [WORD-1:0] program_counter_o
                        );

    // TODO: Check if you can write to the program counter. Since PC is NOT stored in the reg file,
    // need to bypass the reg file and only read out the stored pc value if that's the case. Also need
    // to add logic for "writing" to the PC  (this might not all be necessary, not sure)

    // signals used to forward data from write back stage to execution stage if 
    // reading from the register that was written to
    logic stored_write_en;
    logic [3:0] stored_write_addr;
    logic [3:0] stored_read_1_addr;
    logic [3:0] stored_read_2_addr;
    logic [3:0] stored_read_3_addr;
    logic [WORD-1:0] stored_read_1_data;
    logic [WORD-1:0] stored_read_2_data;
    logic [WORD-1:0] stored_read_3_data;
    logic [WORD-1:0] stored_write_data;

    // determine if we need to output forwarded data or old data
    always_comb begin
        reg_data_1_o = stored_read_1_data;
        reg_data_2_o = stored_read_2_data;
        reg_data_3_o = stored_read_3_data;

        if (stored_write_en && stored_read_1_addr == stored_write_addr)
            reg_data_1_o = stored_write_data;
        if (stored_write_en && stored_read_2_addr == stored_write_addr)
            reg_data_2_o = stored_write_data;
        if (stored_write_en && stored_read_3_addr == stored_write_addr)
            reg_data_3_o = stored_write_data;
    end

    reg_ram register_file_internal(
                            .clk_i(clk_i),
                            .write_en_i(write_en_i),
                            .reg_addr_1_i(read_addr_1_i),
                            .reg_addr_2_i(read_addr_2_i),
                            .reg_addr_3_i(read_addr_3_i),
                            .reg_dest_addr_i(write_addr_i),
                            .reg_data_i(reg_data_i),

                            .reg_data_1_o(stored_read_1_data),
                            .reg_data_2_o(stored_read_2_data),
                            .reg_data_3_o(stored_read_3_data)
                            );

    always_ff @(posedge clk_i) begin
        program_counter_o <= program_counter_i;
        // store forwarding data
        stored_write_en     <= write_en_i;
        stored_write_addr   <= write_addr_i;
        stored_read_1_addr  <= read_addr_1_i;
        stored_read_2_addr  <= read_addr_2_i;
        stored_read_3_addr  <= read_addr_3_i;
        stored_write_data   <= reg_data_i; 
    end

endmodule