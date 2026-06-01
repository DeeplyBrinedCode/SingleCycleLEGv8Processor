module comparator (
    input wire [3:0] A, B,
    output wire AgeB
);
    assign AgeB = (A >= B);
endmodule

module subtractor (
    input wire [3:0] A, B,
    output wire [3:0] result
);
    assign result = A - B;
endmodule

module divisor (
    input  wire [3:0] A, B,
    output reg  [3:0] Q, R
);
    reg [4:0] i;  // 5-bit loop counter

    always @(posedge clk) begin
        if (B == 4'b0) begin
            Q = 4'hF;  // undefined: signal error with sentinel
            R = A;
        end else begin
            Q = 4'b0;
            R = A;
            for (i = 0; i < 16; i = i + 1) begin
                if (R >= B) begin
                    R = R - B;
                    Q = Q + 1;
                end
            end
        end
    end
endmodule