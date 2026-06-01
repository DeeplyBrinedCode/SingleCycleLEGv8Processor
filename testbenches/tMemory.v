`timescale 1ns/1ps

module tb_memory;

    //------------------------------------------------------------
    // RAM SIGNALS
    //------------------------------------------------------------

    reg Reset;
    reg Clock;
    reg OE;
    reg WE;

    reg  [29:0] Address;
    reg  [31:0] DataIn;
    wire [31:0] DataOut;

    //------------------------------------------------------------
    // REGISTER BANK SIGNALS
    //------------------------------------------------------------

    reg  [4:0] ReadReg1;
    reg  [4:0] ReadReg2;
    reg  [4:0] WriteReg;

    reg  [31:0] WriteData;
    reg         WriteCmd;

    wire [31:0] ReadData1;
    wire [31:0] ReadData2;

    //------------------------------------------------------------
    // DUT INSTANTIATION
    //------------------------------------------------------------

    Memory ram0 (
        .Reset(Reset),
        .Clock(Clock),
        .OE(OE),
        .WE(WE),
        .Address(Address),
        .DataIn(DataIn),
        .DataOut(DataOut)
    );

    Registers reg0 (
        .ReadReg1(ReadReg1),
        .ReadReg2(ReadReg2),
        .WriteReg(WriteReg),
        .WriteData(WriteData),
        .WriteCmd(WriteCmd),
        .ReadData1(ReadData1),
        .ReadData2(ReadData2)
    );

    //------------------------------------------------------------
    // CLOCK TASK
    //------------------------------------------------------------

    task do_clock;
    begin
        #5 Clock = 1;
        #5 Clock = 0;
    end
    endtask

    //------------------------------------------------------------
    // MAIN TESTBENCH
    //------------------------------------------------------------

    initial begin

        //--------------------------------------------------------
        // INITIALIZATION
        //--------------------------------------------------------

        Clock     = 0;
        Reset     = 1;
        OE        = 1;
        WE        = 0;

        Address   = 0;
        DataIn    = 0;

        ReadReg1  = 0;
        ReadReg2  = 0;
        WriteReg  = 0;
        WriteData = 0;
        WriteCmd  = 0;

        #10;            
		  Reset = 0;     
		  #10;

        //========================================================
        // EXAMPLE TEST CASE
        //========================================================

        //--------------------------------------------------------
        // TEST 1 : RAM WRITE / READ
        //--------------------------------------------------------
        // Objective:
        //     Verify correct RAM write and read operations.
        //
        // Procedure:
        //     1. Enable RAM write
        //     2. Write data into memory address 0
        //     3. Disable write
        //     4. Enable output
        //     5. Read data back
        //
        // Expected Result:
        //     DataOut should equal:
        //         32'h11111111
        //--------------------------------------------------------

        $display("TEST 1 : RAM WRITE / READ");

        // WRITE OPERATION
        WE      = 1;
        OE      = 1;

        Address = 0;
        DataIn  = 32'h11111111;

        do_clock();
		  
		  #1;

        // READ OPERATION
        WE      = 0;
        OE      = 0;
		  Address = 0;

        #10;

        $display("Address 0 = %h", DataOut);



        //--------------------------------------------------------
        // TODO #2 : RAM RESET
        //--------------------------------------------------------
        // Objective:
        //     Verify reset clears all RAM locations.
        //
        // Procedure:
        //     1. Assert Reset = 1
        //     2. Wait for several nanoseconds
        //     3. Deassert Reset
        //     4. Read multiple RAM addresses
        //
        // Expected Result:
        //     All memory locations output:
        //         32'h00000000
        //--------------------------------------------------------

			$display("TEST 2 : RAM RESET");

        // RESET OPERATION
		  Reset = 1;
        WE      = 0;
        OE      = 0;

        Address = 0;
        DataIn  = 32'h11111111;

        do_clock();
		  
		  #1;

        // READ OPERATION
		  Reset = 0;
		  Address = 0;

        #10;

        $display("Address 0 = %h", DataOut);
		  
		  Address = 1;
		  
		  #10;
		  
		  $display("Address 1 = %h", DataOut);
		  
        //--------------------------------------------------------
        // TODO #3 : WRITE ENABLE DISABLED
        //--------------------------------------------------------
        // Objective:
        //     Verify RAM does not write when WE = 0.
        //
        // Procedure:
        //     1. Write known data into RAM
        //     2. Disable WE
        //     3. Attempt another write to same address
        //     4. Read address back
        //
        // Expected Result:
        //     Original value remains unchanged
        //--------------------------------------------------------

			$display("TEST 3 : WRITE ENABLE DISABLED");

        // WRITE OPERATION
        WE      = 1;
        OE      = 1;

        Address = 0;
        DataIn  = 32'h11111111;

        do_clock();
		  
		  #1;

        // DISABLE WRITE
        WE      = 0;
        OE      = 0;
		  
		  do_clock();
		  
		  #1;
		  
		  // WRITE AGAIN WITHOUT 
		  OE = 1;
		  DataIn = 32'h01000100;

        #10;

        $display("Address 0 = %h", DataOut);

        //--------------------------------------------------------
        // TODO #4 : OUTPUT ENABLE DISABLED
        //--------------------------------------------------------
        // Objective:
        //     Verify high impedance RAM output.
        //
        // Procedure:
        //     1. Disable output using OE = 1
        //     2. Observe DataOut
        //
        // Expected Result:
        //     DataOut becomes:
        //         ZZZZZZZZ...
        //--------------------------------------------------------

			$display("TEST 4 : OUTPUT ENABLE DISABLED");

        // DISABLE OUTPUT
        OE      = 1;
        do_clock();

        #10;

        $display("Address 0 = %h", DataOut);

        //--------------------------------------------------------
        // TODO #5 : INVALID ADDRESS ACCESS
        //--------------------------------------------------------
        // Objective:
        //     Verify invalid RAM addresses are ignored.
        //
        // Procedure:
        //     1. Attempt write to address > 127
        //     2. Attempt read from invalid address
        //
        // Suggested Address:
        //     30'd200
        //
        // Expected Result:
        //     Invalid accesses should not modify RAM
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #6 : CONSECUTIVE WRITES
        //--------------------------------------------------------
        // Objective:
        //     Verify sequential RAM writes.
        //
        // Procedure:
        //     1. Write different values into consecutive addresses
        //     2. Read all addresses back
        //
        // Expected Result:
        //     Each address stores the correct value
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #7 : FALLING EDGE VERIFICATION
        //--------------------------------------------------------
        // Objective:
        //     Verify RAM writes only on falling clock edge.
        //
        // Procedure:
        //     1. Change DataIn before rising edge
        //     2. Toggle clock
        //     3. Observe when RAM updates
        //
        // Expected Result:
        //     RAM updates only after falling edge
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #8 : SINGLE REGISTER WRITE
        //--------------------------------------------------------
        // Objective:
        //     Verify writing to register a0.
        //
        // Procedure:
        //     1. Set WriteReg = 5'b01010
        //     2. Enable WriteCmd
        //     3. Write known data
        //     4. Read register back
        //
        // Expected Result:
        //     ReadData outputs written value
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #9 : MULTIPLE REGISTER WRITES
        //--------------------------------------------------------
        // Objective:
        //     Verify independent register storage.
        //
        // Procedure:
        //     1. Write unique values into a0, a1, a2
        //     2. Read all registers back
        //
        // Expected Result:
        //     Each register stores correct independent value
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #10 : ZERO REGISTER PROTECTION
        //--------------------------------------------------------
        // Objective:
        //     Verify x0 always remains zero.
        //
        // Procedure:
        //     1. Attempt write into register x0
        //     2. Read x0 back
        //
        // Expected Result:
        //     x0 outputs:
        //         32'h00000000
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #11 : DUAL REGISTER READ
        //--------------------------------------------------------
        // Objective:
        //     Verify simultaneous register reads.
        //
        // Procedure:
        //     1. Set ReadReg1 and ReadReg2
        //     2. Observe ReadData1 and ReadData2
        //
        // Expected Result:
        //     Both outputs are valid simultaneously
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #12 : INVALID REGISTER READ
        //--------------------------------------------------------
        // Objective:
        //     Verify unsupported register handling.
        //
        // Procedure:
        //     1. Read unsupported register number
        //
        // Suggested Register:
        //     5'b11111
        //
        // Expected Result:
        //     Output becomes:
        //         Z
        //     or default fail value
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #13 : 8-BIT PARTIAL WRITE
        //--------------------------------------------------------
        // Objective:
        //     Verify lower byte-only update.
        //
        // Procedure:
        //     1. Perform 8-bit write
        //     2. Read full 32-bit register
        //
        // Expected Result:
        //     Only bits [7:0] change
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #14 : 16-BIT PARTIAL WRITE
        //--------------------------------------------------------
        // Objective:
        //     Verify lower 16-bit update.
        //
        // Procedure:
        //     1. Perform 16-bit write
        //     2. Read full register
        //
        // Expected Result:
        //     Only bits [15:0] change
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #15 : 32-BIT FULL WRITE
        //--------------------------------------------------------
        // Objective:
        //     Verify full register update.
        //
        // Procedure:
        //     1. Perform 32-bit write
        //     2. Read register back
        //
        // Expected Result:
        //     Entire 32-bit register changes
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #16 : REGISTER READ AFTER WRITE
        //--------------------------------------------------------
        // Objective:
        //     Verify register persistence.
        //
        // Procedure:
        //     1. Write data into register
        //     2. Immediately read register
        //
        // Expected Result:
        //     Read value matches written value
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #17 : RAM READ WITHOUT PRIOR WRITE
        //--------------------------------------------------------
        // Objective:
        //     Verify reset/default RAM state.
        //
        // Procedure:
        //     1. Read unused RAM location
        //
        // Expected Result:
        //     Output equals:
        //         32'h00000000
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #18 : SIMULTANEOUS RAM + REGISTER OPS
        //--------------------------------------------------------
        // Objective:
        //     Verify RAM and register bank operate independently.
        //
        // Procedure:
        //     1. Perform RAM write
        //     2. Simultaneously perform register write
        //     3. Read both back
        //
        // Expected Result:
        //     Both operations complete correctly
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #19 : HIGH IMPEDANCE VERIFICATION
        //--------------------------------------------------------
        // Objective:
        //     Verify tri-state bus behavior.
        //
        // Procedure:
        //     1. Disable outputs
        //     2. Observe output bus
        //
        // Expected Result:
        //     Output becomes:
        //         ZZZZZZZZ...
        //--------------------------------------------------------



        //--------------------------------------------------------
        // TODO #20 : BOUNDARY ADDRESS TEST
        //--------------------------------------------------------
        // Objective:
        //     Verify lowest and highest RAM addresses.
        //
        // Procedure:
        //     1. Write/read address 0
        //     2. Write/read address 127
        //
        // Expected Result:
        //     Both addresses function correctly
        //--------------------------------------------------------



        //--------------------------------------------------------
        // END SIMULATION
        //--------------------------------------------------------

        #100;

        $display("ALL TESTS COMPLETE");

    end

endmodule
