`include "GENERAL_DEFS.svh"

module clocked_reg_file(
                            input logic clk_i,
                            input logic reset_i,
                            input logic write_en_i,
                            input logic [3:0] read_addr_1_i,
                            input logic [3:0] read_addr_2_i,
                            input logic [3:0] write_addr_i,
                            input logic [WORD-1:0] reg_data_i,
                            input logic [WORD-1:0] pc_value_i,

                            output logic [WORD-1:0] reg_data_1_o,
                            output logic [WORD-1:0] reg_data_2_o
                        );

    // signals used to forward data from write back stage to execution stage if 
    // reading from the register that was written to
    logic stored_write_en;
    logic [3:0] stored_write_addr;
    logic [3:0] stored_read_1_addr;
    logic [3:0] stored_read_2_addr;
    logic [31:0] stored_read_1_data;
    logic [31:0] stored_read_2_data;
    logic [31:0] stored_write_data;

    logic [WORD-1:0] reg_ram [15:0];

    always_comb begin
        if (stored_write_en && stored_read_1_addr == stored_write_addr)
            reg_data_1_o = stored_write_data;
        else
            reg_data_1_o = stored_read_1_data;

        if (stored_write_en && stored_read_2_addr == stored_write_addr)
            reg_data_2_o = stored_write_data;
        else
            reg_data_2_o = stored_read_2_data;
    end

    always_ff @(posedge clk_i) begin
        // Write to ram
        if (write_en_i)
            reg_ram[write_addr_i]   <= reg_data_i;

        // Store forwarding control data
        stored_write_en     <= write_en_i;
        stored_write_addr   <= write_addr_i;
        stored_read_1_addr  <= read_addr_1_i;
        stored_read_2_addr  <= read_addr_2_i;

        // Store data to be forwarded
        stored_read_1_data  <= reg_ram[read_addr_1_i];
        stored_read_2_data  <= reg_ram[read_addr_2_i];
        stored_write_data   <= reg_data_i; 
    end

endmodule