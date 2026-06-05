module DataMemory (
    input  wire        CLK,
    input  wire [31:0] Address,
    input  wire [31:0] WriteData,
    input  wire        MemRead,
    input  wire        MemWrite,
    output wire [31:0] ReadData
);

    reg [31:0] mem [0:63];

    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1)
            mem[i] = 32'b0;
    end

    // byte address to word index
    wire [5:0] word_index = Address[7:2];

    always @(posedge CLK) begin
        if (MemWrite)
            mem[word_index] <= WriteData;
    end

    assign ReadData = MemRead ? mem[word_index] : 32'b0;

endmodule


`timescale 1ns/1ps

module tDataMemory;

    reg        CLK;
    reg [31:0] Address;
    reg [31:0] WriteData;
    reg        MemRead;
    reg        MemWrite;
    wire [31:0] ReadData;

    DataMemory uut (
        .CLK       (CLK),
        .Address   (Address),
        .WriteData (WriteData),
        .MemRead   (MemRead),
        .MemWrite  (MemWrite),
        .ReadData  (ReadData)
    );

    initial CLK = 0;
    always #5 CLK = ~CLK;

    integer errors;

    task write_read_check;
        input [31:0] addr;
        input [31:0] data;
        begin
            Address   = addr;
            WriteData = data;
            MemWrite  = 1;
            MemRead   = 0;
            @(posedge CLK); #1;
            MemWrite = 0;
            MemRead  = 1; #5;
            if (ReadData !== data) begin
                $display("FAIL @ addr %h: got %h, expected %h", addr, ReadData, data);
                errors = errors + 1;
            end
            MemRead = 0;
        end
    endtask

    initial begin
        errors    = 0;
        Address   = 0;
        WriteData = 0;
        MemRead   = 0;
        MemWrite  = 0;
        @(posedge CLK); #1;

        write_read_check(32'h00000000, 32'hDEADBEEF);
        write_read_check(32'h00000004, 32'hCAFEBABE);
        write_read_check(32'h00000008, 32'h12345678);

        // check word 0 wasn't overwritten
        Address = 32'h00000000; MemRead = 1; #5;
        if (ReadData !== 32'hDEADBEEF) begin
            $display("FAIL aliasing check: word 0 got %h", ReadData);
            errors = errors + 1;
        end
        MemRead = 0;

        // MemRead deasserted should return 0
        Address = 32'h0000000C; MemRead = 0; #5;
        if (ReadData !== 32'h00000000) begin
            $display("FAIL disabled read: got %h", ReadData);
            errors = errors + 1;
        end

        write_read_check(32'h00000004, 32'h0000FFFF);
        write_read_check(32'h000000FC, 32'hBEEFCAFE);

        // final integrity check on word 0
        Address = 32'h00000000; MemRead = 1; #5;
        if (ReadData !== 32'hDEADBEEF) begin
            $display("FAIL final check word 0: got %h", ReadData);
            errors = errors + 1;
        end
        MemRead = 0;

        if (errors == 0)
            $display("DataMemory: all tests passed.");
        else
            $display("DataMemory: %0d test(s) failed.", errors);

        $finish;
    end

endmodule
