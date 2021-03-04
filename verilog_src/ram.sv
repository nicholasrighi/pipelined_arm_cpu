module ram(
    input logic             CLK,
    input logic             WEN,
    // verilator lint_off UNUSED
    input logic     [31:0]  A,
    // verilator lint_on UNUSED
    input logic     [7:0]   D,
    output logic    [7:0]   Q
    );

reg [7:0] mem [8191:0];

always @(posedge CLK) begin
    if (WEN)
        mem[A] <= D;

    Q <= mem[A];
end

endmodule