module SCLEGv8P (
	input wire clk, reset
	);
	
	reg [31:0] PC, Instruction, ReadData1, ReadData2, Immediate, ALUResult, MemData;
	wire [31:0] PC_wire, Instruction_wire, RD1_wire, RD2_wire;
	
	assign PC_wire = PC;
	
	//----------------------------------------------------------------------------------
	// Instruction Memory
	//----------------------------------------------------------------------------------
	
	InstructionMemory IM (PC_wire, Instruction_wire);
	
	//----------------------------------------------------------------------------------
	// Register File
	//----------------------------------------------------------------------------------
	
	reg [4:0] RF_ReadReg1, RF_ReadReg2, RF_WriteReg;
	reg [31:0] RF_WriteData;
	wire [31:0] RF_ReadData1, RF_ReadData2;
	reg RF_WriteCmd;
	
	RegisterFile RF (
		RF_ReadReg1, RF_ReadReg2, RF_WriteReg, RF_WriteData,
		RF_WriteCmd, RF_ReadData1, RF_ReadData2
	);
	
	//----------------------------------------------------------------------------------
	// ALU
	//----------------------------------------------------------------------------------
	
	
	//----------------------------------------------------------------------------------
	// Register Update
	//----------------------------------------------------------------------------------
	
	always @(posedge clk) begin
		case (reset)
			1'b1: begin
				PC          <= 32'h00000000;
				Instruction <= 32'h00000000;
				ReadData1   <= 32'h00000000;
				ReadData2   <= 32'h00000000;
				Immediate   <= 32'h00000000;
				ALUResult   <= 32'h00000000;
				MemData     <= 32'h00000000;
			end
			default: begin
				PC <= PC + 32'h00000100;
				Instruction <= Instruction_wire;
				ReadData1 <= RF_ReadData1;
				ReadData2 <= RF_ReadData2;
			end
		endcase
		// Check opcode
		case(Instruction[31:20])
			12'h458, 12'h658, : begin // R-Format Opcodes
				RF_ReadReg1 <= Instruction[9:5]; // First Source Register
				RF_ReadReg2 <= Instruction[20:16]; // Second Source Register
				RF_WriteReg <= Instruction[4:0]; // Destination Register
				RF_WriteData <= ALUResult;
				RF_WriteCmd <= 1'b1;
			end
			default: begin
				RF_ReadReg1 <= 5'bzzzzz;
				RF_ReadReg2 <= 5'bzzzzz;
				RF_WriteReg <= 5'bzzzzz;
				RF_WriteData <= 32'hzzzzzzzz;
				RF_WriteCmd <= 1'bz;
			end
		endcase
	end
endmodule