module ram(
    input logic             CLK,
    input logic             WEN,
    // verilator lint_off UNUSED
    input logic     [31:0]  A,
    // verilator lint_on UNUSED
    input logic     [7:0]   D,
    output logic    [7:0]   Q
    );

localparam DATA_SIZE = 512;

reg [7:0] mem [DATA_SIZE-1:0];

always @(posedge CLK) begin
    if (WEN)
        mem[A] <= D;

    Q <= mem[A];
end

endmodule