module ImmediateGenerator (
    input  wire [31:0] Instruction,
    output reg  [31:0] ImmOut
);

    wire [9:0]  op10 = Instruction[31:22];
    wire [10:0] op11 = Instruction[31:21];
    wire [7:0]  op8  = Instruction[31:24];
    wire [5:0]  op6  = Instruction[31:26];

    // ADDI is matched on [31:22] because bit 21 overlaps with imm12[11]
    localparam ADDI = 10'b1001000100;
    localparam LDUR = 11'b11111000010;
    localparam STUR = 11'b11111000000;
    localparam CBZ  = 8'b10110100;
    localparam B    = 6'b000101;

    always @(*) begin
        if (op10 == ADDI)
            ImmOut = {{20{Instruction[21]}}, Instruction[21:10]};
        else if (op11 == LDUR || op11 == STUR)
            ImmOut = {{23{Instruction[20]}}, Instruction[20:12]};
        else if (op8 == CBZ)
            ImmOut = {{13{Instruction[23]}}, Instruction[23:5]};
        else if (op6 == B)
            ImmOut = {{6{Instruction[25]}}, Instruction[25:0]};
        else
            ImmOut = 32'b0;
    end

endmodule


`timescale 1ns/1ps

module tImmediateGenerator;

    reg  [31:0] Instruction;
    wire [31:0] ImmOut;

    ImmediateGenerator uut (
        .Instruction (Instruction),
        .ImmOut      (ImmOut)
    );

    integer errors;

    initial begin
        errors = 0;

        // LDUR X4, [X1, #8] -- offset = +8, expected 0x00000008
        Instruction = {11'b11111000010, 9'b000001000, 2'b00, 5'b00001, 5'b00100};
        #20;
        if (ImmOut !== 32'h00000008) begin
            $display("FAIL LDUR +8: got %h", ImmOut);
            errors = errors + 1;
        end

        // LDUR negative offset -4, expected 0xFFFFFFFC
        Instruction = {11'b11111000010, 9'b111111100, 2'b00, 5'b00001, 5'b00100};
        #20;
        if (ImmOut !== 32'hFFFFFFFC) begin
            $display("FAIL LDUR -4: got %h", ImmOut);
            errors = errors + 1;
        end

        // STUR X3, [X1, #16] -- offset = +16, expected 0x00000010
        Instruction = {11'b11111000000, 9'b000010000, 2'b00, 5'b00001, 5'b00011};
        #20;
        if (ImmOut !== 32'h00000010) begin
            $display("FAIL STUR +16: got %h", ImmOut);
            errors = errors + 1;
        end

        // ADDI X2, X1, #100 -- expected 0x00000064
        // I-type concat: {op[31:22], imm12, Rn, Rd} = 10+12+5+5 = 32 bits
        Instruction = {10'b1001000100, 12'd100, 5'b00001, 5'b00010};
        #20;
        if (ImmOut !== 32'h00000064) begin
            $display("FAIL ADDI +100: got %h", ImmOut);
            errors = errors + 1;
        end

        // ADDI negative immediate -1, expected 0xFFFFFFFF
        Instruction = {10'b1001000100, 12'hFFF, 5'b00001, 5'b00010};
        #20;
        if (ImmOut !== 32'hFFFFFFFF) begin
            $display("FAIL ADDI -1: got %h", ImmOut);
            errors = errors + 1;
        end

        // CBZ X0, #4 -- expected 0x00000004
        Instruction = {8'b10110100, 19'd4, 5'b00000};
        #20;
        if (ImmOut !== 32'h00000004) begin
            $display("FAIL CBZ +4: got %h", ImmOut);
            errors = errors + 1;
        end

        // CBZ negative offset -8, expected 0xFFFFFFF8
        Instruction = {8'b10110100, 19'b1111111111111111000, 5'b00000};
        #20;
        if (ImmOut !== 32'hFFFFFFF8) begin
            $display("FAIL CBZ -8: got %h", ImmOut);
            errors = errors + 1;
        end

        // B #12 -- expected 0x0000000C
        Instruction = {6'b000101, 26'd12};
        #20;
        if (ImmOut !== 32'h0000000C) begin
            $display("FAIL B +12: got %h", ImmOut);
            errors = errors + 1;
        end

        // B negative offset -4, expected 0xFFFFFFFC
        Instruction = {6'b000101, 26'b11111111111111111111111100};
        #20;
        if (ImmOut !== 32'hFFFFFFFC) begin
            $display("FAIL B -4: got %h", ImmOut);
            errors = errors + 1;
        end

        // R-type ADD -- no immediate, expected 0x00000000
        Instruction = {11'b10001011000, 5'b00010, 6'b000000, 5'b00001, 5'b00011};
        #20;
        if (ImmOut !== 32'h00000000) begin
            $display("FAIL R-type: got %h", ImmOut);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ImmediateGenerator: all tests passed.");
        else
            $display("ImmediateGenerator: %0d test(s) failed.", errors);

        $finish;
    end

endmodule
