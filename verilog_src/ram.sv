module ram(
    input           CLK,
    input           WEN,
    //input CEN,
    // verilator lint_off UNUSED
    input   [31:0]  A,
    // verilator lint_off UNUSED
    input   [7:0]   D,
    output  [7:0]   Q
    );

reg [7:0] mem [8191:0];

assign Q = mem[A];

//initial begin
//        $readmemh("mem_file_path", mem);
//end

always @(posedge CLK) begin
    //if (CEN) begin
        //$readmemh("mem_file_path",mem);
    //end
    if (WEN) begin
        mem[A] <= D;
    end else begin
        mem[A] <= mem[A];
    end
end

endmodule