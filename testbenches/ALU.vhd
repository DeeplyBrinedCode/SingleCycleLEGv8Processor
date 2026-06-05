module ALU (
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [3:0]  ALUControl,
    output reg  [31:0] ALUResult,
    output wire        Zero
);

    // ALUControl encoding
    // 0000 = AND, 0001 = ORR, 0010 = ADD, 0110 = SUB, 1111 = PASS B
    always @(*) begin
        case (ALUControl)
            4'b0000: ALUResult = A & B;
            4'b0001: ALUResult = A | B;
            4'b0010: ALUResult = A + B;
            4'b0110: ALUResult = A - B;
            4'b1111: ALUResult = B;
            default: ALUResult = 32'b0;
        endcase
    end

    assign Zero = (ALUResult == 32'b0) ? 1'b1 : 1'b0;

endmodule


`timescale 1ns/1ps

module tALU;

    reg  [31:0] A, B;
    reg  [3:0]  ALUControl;
    wire [31:0] ALUResult;
    wire        Zero;

    ALU uut (
        .A          (A),
        .B          (B),
        .ALUControl (ALUControl),
        .ALUResult  (ALUResult),
        .Zero       (Zero)
    );

    integer errors;

    initial begin
        errors = 0;

        // ADD tests
        A = 32'd5;        B = 32'd3;        ALUControl = 4'b0010; #10;
        if (ALUResult !== 32'd8 || Zero !== 1'b0)         begin $display("FAIL ADD 5+3");          errors = errors + 1; end

        A = 32'd0;        B = 32'd0;        ALUControl = 4'b0010; #10;
        if (ALUResult !== 32'd0 || Zero !== 1'b1)         begin $display("FAIL ADD 0+0 zero flag"); errors = errors + 1; end

        A = 32'h7FFFFFFF; B = 32'd1;        ALUControl = 4'b0010; #10;
        if (ALUResult !== 32'h80000000)                   begin $display("FAIL ADD overflow");      errors = errors + 1; end

        // SUB tests
        A = 32'd10;       B = 32'd3;        ALUControl = 4'b0110; #10;
        if (ALUResult !== 32'd7 || Zero !== 1'b0)         begin $display("FAIL SUB 10-3");          errors = errors + 1; end

        A = 32'd5;        B = 32'd5;        ALUControl = 4'b0110; #10;
        if (ALUResult !== 32'd0 || Zero !== 1'b1)         begin $display("FAIL SUB 5-5 zero flag"); errors = errors + 1; end

        A = 32'd3;        B = 32'd10;       ALUControl = 4'b0110; #10;
        if (ALUResult !== 32'hFFFFFFF9 || Zero !== 1'b0)  begin $display("FAIL SUB 3-10");          errors = errors + 1; end

        // AND tests
        A = 32'hFF00FF00; B = 32'hF0F0F0F0; ALUControl = 4'b0000; #10;
        if (ALUResult !== 32'hF000F000)                   begin $display("FAIL AND basic");         errors = errors + 1; end

        A = 32'hDEADBEEF; B = 32'h00000000; ALUControl = 4'b0000; #10;
        if (ALUResult !== 32'h00000000 || Zero !== 1'b1)  begin $display("FAIL AND with zero");     errors = errors + 1; end

        // ORR tests
        A = 32'h0F0F0F0F; B = 32'hF0F0F0F0; ALUControl = 4'b0001; #10;
        if (ALUResult !== 32'hFFFFFFFF || Zero !== 1'b0)  begin $display("FAIL ORR basic");         errors = errors + 1; end

        A = 32'h00000000; B = 32'h00000000; ALUControl = 4'b0001; #10;
        if (ALUResult !== 32'h00000000 || Zero !== 1'b1)  begin $display("FAIL ORR zero");          errors = errors + 1; end

        // PASS B
        A = 32'hDEADBEEF; B = 32'h0000000C; ALUControl = 4'b1111; #10;
        if (ALUResult !== 32'h0000000C)                   begin $display("FAIL PASS B");            errors = errors + 1; end

        // Zero flag edge case
        A = 32'hFFFFFFFF; B = 32'd1;        ALUControl = 4'b0010; #10;
        if (ALUResult !== 32'h00000000 || Zero !== 1'b1)  begin $display("FAIL zero flag -1+1");    errors = errors + 1; end

        if (errors == 0)
            $display("ALU: all tests passed.");
        else
            $display("ALU: %0d test(s) failed.", errors);

        $finish;
    end

endmodule
