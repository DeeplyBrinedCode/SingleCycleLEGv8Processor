module four_bit_mult (
    input [3:0] A, B,
    output [7:0] P
);
    wire [3:0] pp0, pp1, pp2, pp3;
    wire [7:0] sum1, sum2, sum3;

    assign pp0 = A & {B[0], B[0], B[0], B[0]};
    assign pp1 = A & {B[1], B[1], B[1], B[1]};
    assign pp2 = A & {B[2], B[2], B[2], B[2]};
    assign pp3 = A & {B[3], B[3], B[3], B[3]};

    assign sum1 = {4'b0000, pp0};
    assign sum2 = sum1 + {3'b000, pp1, 1'b0};
    assign sum3 = sum2 + {2'b00, pp2, 2'b00};
    assign P    = sum3 + {1'b0, pp3, 3'b000};

endmodule