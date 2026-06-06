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
	
	wire [4:0] RF_ReadReg1, RF_ReadReg2, RF_WriteReg;
	wire [31:0] RF_WriteData;
	wire [31:0] RF_ReadData1, RF_ReadData2;
	reg RF_WriteCmd; // To be pulsed by a combinational block for the ALU
	
	assign RF_ReadReg1 = Instruction[9:5]; // First Source Register
	assign RF_ReadReg2 = Instruction[20:16]; // Second Source Register
	assign RF_WriteReg = Instruction[4:0]; // Destination Register
	assign RF_WriteData = ALUResult;
	
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
	
	always @(posedge clk) begin // Read on positive edge
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
			12'h458, 12'h658: begin // R-Format Opcode
				ReadData1 <= RF_ReadData1;
				ReadData2 <= RF_ReadData2;
			end
			12'h488, 12'h489, 12'h688, 12'h689: begin // I-Format Opcodes
				ReadData1 <= RF_ReadData1;
				ReadData2 <= {{20{1'b0}}, Instruction[21:10]};
			end
			default: begin
				ReadData1 <= 32'hzzzzzzzz;
				ReadData2 <= 32'hzzzzzzzz;
			end
		endcase
	end
	
endmodule