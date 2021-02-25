module data_mem(
                        input logic clk,
                        input logic mem_write_en,
                        input logic [6:0] opCode, // bits 15 : 9 of instruction
                        input logic [31:0] mem_addr,
                        input logic [31:0] mem_data_in,
                        output logic [31:0] mem_data_out
                        // Test outputs
			            //output logic [1:0] size,
			            //output logic [31:0] full_stored_val
								);

    // INSTRUCTION DEFS //
    // Load/Store single register
    localparam STORE_WORD               = 7'b0101000;
    localparam STORE_HALF_WORD          = 7'b0101001;
    localparam STORE_BYTE               = 7'b0101010;
    localparam LOAD_SIGNED_BYTE         = 7'b0101011;
    localparam LOAD_WORD                = 7'b0101100;
    localparam LOAD_HALF_WORD           = 7'b0101101;
    localparam LOAD_BYTE                = 7'b0101110;
    localparam LOAD_SIGNED_HALFWORD     = 7'b0101111;
    // Load/Store single immediate
    localparam STORE_WORD_IM            = 7'b01100??;
    localparam LOAD_WORD_IM             = 7'b01101??;
    localparam STORE_BYTE_IM            = 7'b01110??;
    localparam LOAD_BYTE_IM             = 7'b01111??;
    localparam STORE_HALF_WORD_IM       = 7'b10000??;
    localparam LOAD_HALF_WORD_IM        = 7'b10001??;
    localparam STORE_SP                 = 7'b10010??;
    localparam LOAD_SP                  = 7'b10011??;
    // Load register (literal)
    localparam LOAD_LIT                 = 7'b01001??;
    // Load/Store multiple registers
    localparam STORE_MULTIPLE           = 7'b11000??;
    localparam LOAD_MULTIPLE            = 7'b11001??;
    // Push/Pop
    localparam POP                      = 7'b1011110;
    localparam PUSH                     = 7'b1011010;

    logic sign_extend;
    logic mem_write_en_1;
    logic mem_write_en_2;
    logic mem_write_en_3;
    logic mem_write_en_4;
	 
	logic [1:0]   max_size;

    logic [7:0]   data_write_internal_1;
    logic [15:8]  data_write_internal_2;
    logic [23:16] data_write_internal_3;
    logic [31:24] data_write_internal_4;
    
    logic [7:0]   data_read_internal_1;
    logic [15:8]  data_read_internal_2;
    logic [23:16] data_read_internal_3;
    logic [31:24] data_read_internal_4;

	//assign size = max_size;

    assign data_write_internal_1 = mem_data_in[7:0];
    assign data_write_internal_2 = mem_data_in[15:8];
    assign data_write_internal_3 = mem_data_in[23:16];
    assign data_write_internal_4 = mem_data_in[31:24];

    // Test output for 32 stored value regardless of instruction size
    // assign full_stored_val = {data_read_internal_4, data_read_internal_3, data_read_internal_2, data_read_internal_1};

    always_comb begin

        mem_write_en_1 = 1'b0;
        mem_write_en_2 = 1'b0;
        mem_write_en_3 = 1'b0;
        mem_write_en_4 = 1'b0;
	    sign_extend = 1'b0;
			
        casez(opCode)
            // Load/Store single register//
			STORE_WORD:
			begin
				max_size = 2'd3;
            end
			STORE_HALF_WORD:
			begin
			    max_size = 2'd1;
			end
            STORE_BYTE:
			begin
				max_size = 2'd0;
			end
            LOAD_SIGNED_BYTE:   
            begin
                max_size = 2'd0;
                sign_extend = 1'b1;
            end
            LOAD_WORD:
			begin
				max_size = 2'd3;
            end
			 LOAD_HALF_WORD:
			begin
				max_size = 2'd1;
            end
			LOAD_BYTE:
			begin
				max_size = 2'd0;
            end
			LOAD_SIGNED_HALFWORD:
            begin
                max_size = 2'd1;
                sign_extend = 1'b1;
            end
            // Load/Store single immediate //
            STORE_WORD_IM:
            begin
                max_size = 2'd3;
            end
            LOAD_WORD_IM:
            begin
                max_size = 2'd3;
            end
            STORE_BYTE_IM:
            begin
                max_size = 2'd1;
            end
            LOAD_BYTE_IM:
            begin
                max_size = 2'd1;
            end
            STORE_HALF_WORD_IM:
            begin
                max_size = 2'd1;
            end
            LOAD_HALF_WORD_IM:
            begin
                max_size = 2'd1;
            end
            STORE_SP:
            begin
                max_size = 2'd3;
            end
            LOAD_SP:
            begin
                max_size = 2'd3;
            end
            // Load register (literal) //
            LOAD_LIT:
            begin
                max_size = 2'd1;
            end
            // Load/Store multiple registers //
            STORE_MULTIPLE:
            begin
                max_size = 2'd1;
            end
            LOAD_MULTIPLE:
            begin
                max_size = 2'd1;
            end
            // Push/Pop
            PUSH:
            begin
                max_size = 2'd3;
            end
            POP:
            begin
                max_size = 2'd3;
            end

            default:        
            begin
                max_size = 2'dx;
                sign_extend = 1'dx;
            end
        endcase

        // Data writing logic
        if (mem_write_en) begin
            if (max_size == 2'd0) begin
                mem_write_en_1 = 1'b1;
            end else if (max_size == 2'd1) begin
                mem_write_en_1 = 1'b1;
                mem_write_en_2 = 1'b1;
            end else if (max_size == 2'd3) begin
                mem_write_en_1 = 1'b1;
                mem_write_en_2 = 1'b1;
                mem_write_en_3 = 1'b1;
                mem_write_en_4 = 1'b1;
            end
        end

        // Data Reading logic
        mem_data_out[31:0] = 32'b0;
        if (max_size == 2'd0) begin
            mem_data_out[7:0] = data_read_internal_1;
            if (sign_extend == 1'b1)
                mem_data_out[31:8] = {24{mem_data_out[7]}};
        end else if (max_size == 2'd1) begin
            mem_data_out[7:0] = data_read_internal_1;
            mem_data_out[15:8] = data_read_internal_2;
            if (sign_extend == 1'b1)
                mem_data_out[31:16] = {16{mem_data_out[15]}};
        end else if (max_size == 2'd3) begin
            mem_data_out[7:0] = data_read_internal_1;
            mem_data_out[15:8] = data_read_internal_2;
            mem_data_out[23:16] = data_read_internal_3;
            mem_data_out[31:24] = data_read_internal_4;
        end
    end

    // Ram modules each handling 8 bits / 2 bytes
    // data_ram_1 handles the 8'h______xx bytes and data_ram_4 handles the 8'hxx______ bytes.
    ram data_ram_1 (
        .CLK(clk),
        .WEN(mem_write_en_1),
        //.CEN(),
        .A(mem_addr),
        .D(data_write_internal_1),
        .Q(data_read_internal_1)
    );
    ram data_ram_2 (
        .CLK(clk),
        .WEN(mem_write_en_2),
        //.CEN(),
        .A(mem_addr),
        .D(data_write_internal_2),
        .Q(data_read_internal_2)
    );
    ram data_ram_3 (
        .CLK(clk),
        .WEN(mem_write_en_3),
        //.CEN(),
        .A(mem_addr),
        .D(data_write_internal_3),
        .Q(data_read_internal_3)
    );
    ram data_ram_4 (
        .CLK(clk),
        .WEN(mem_write_en_4),
        //.CEN(),
        .A(mem_addr),
        .D(data_write_internal_4),
        .Q(data_read_internal_4)
    );
	 
endmodule