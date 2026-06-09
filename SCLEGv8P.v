module SCLEGv8P (
	input wire clk, reset
	);
	
	reg [31:0] PC, ReadData1, ReadData2, ALUResult;
	wire [31:0] PC_wire, Instruction, RD1_wire, RD2_wire;
	
	assign PC_wire = PC;
	
	wire [31:0] RAM_DataIn, RAM_DataOut; // Declarations for RAM
	
	//----------------------------------------------------------------------------------
	// Instruction Memory
	//----------------------------------------------------------------------------------
	
	InstructionMemory IM (PC_wire, Instruction);
	
	//----------------------------------------------------------------------------------
	// Register File
	//----------------------------------------------------------------------------------
	
	wire [4:0] RF_ReadReg1, RF_ReadReg2, RF_WriteReg;
	wire [31:0] RF_WriteData;
	wire [31:0] ReadData1W, ReadData2W;
	wire RegisterWrite; // Whether or not the current instruction should write
	wire WriteCmd, CBZ;
	
	assign RF_ReadReg1 = Instruction[9:5]; // First Source Register
	assign RF_ReadReg2 = (Instruction[31:21] == 11'h7c0 || Instruction[31:24] == 8'hB4) ? Instruction[4:0] : Instruction[20:16]; // Second Source Register
	assign RF_WriteReg = Instruction[4:0]; // Destination Register
	assign RF_WriteData = (Instruction[31:21] == 11'h7C2) ? RAM_DataOut : ALUResult;
	assign RegisterWrite = (Instruction[31:21] == 11'h458 ||
									Instruction[31:21] == 11'h658 ||
									Instruction[31:21] == 11'h450 ||
									Instruction[31:21] == 11'h550 ||
									Instruction[31:21] == 11'h488 ||
									Instruction[31:21] == 11'h489 ||
									Instruction[31:21] == 11'h688 ||
									Instruction[31:21] == 11'h689 ||
									Instruction[31:21] == 11'h450 ||
									Instruction[31:21] == 11'h550 ||
									Instruction[31:21] == 11'h4bc ||
									Instruction[31:21] == 11'h7c2);
	assign WriteCmd = ~clk & RegisterWrite; // If IW reg is high, will write on negative edge of clock
	assign CBZ = ~(ReadData2W == 32'h00000000);
	
	RegisterFile RF (
		RF_ReadReg1, RF_ReadReg2, RF_WriteReg, RF_WriteData,
		WriteCmd, ReadData1W, ReadData2W
	);
	
	//----------------------------------------------------------------------------------
	// RAM
	//----------------------------------------------------------------------------------
	
	wire RAM_OE, RAM_WE;
	wire [29:0] RAM_Address;
	wire RAM_Write, RAM_Read;
	
	assign RAM_Write = (Instruction[31:21] == 11'h7c0); // Whether or not the RAM should be written to
	assign RAM_WE = ~clk & RAM_Write;
	assign RAM_OE = ~(Instruction[31:21] == 11'h7c2); // Whether or not the RAM should be read from
	assign RAM_Address = ReadData1W[28:0] + Instruction[20:12];
	assign RAM_DataIn = ReadData2W;
	
	Memory RAM (reset, clk, RAM_OE, RAM_WE, RAM_Address, RAM_DataIn, RAM_DataOut);
	
	//----------------------------------------------------------------------------------
	// ALU
	//----------------------------------------------------------------------------------
	
	wire [31:0] ALUOp1, ALUOp2, Immediate;
	wire ZeroFlag;
	wire [31:0] ALUResultWire;
	wire IorR;
	
	assign Immediate = {32{Instruction[21]}} ^ {{20{1'b0}}, Instruction[20:10]} + Instruction[21];
	assign ALUOp1 = ReadData1;
	assign ALUOp2 = (IorR) ? Immediate : ReadData2;
	assign IorR = (Instruction[31:21] == 11'h488 || Instruction[31:21] == 11'h489 || Instruction[31:21] == 11'h688 || Instruction[31:21] == 11'h689);
	
	ArLoUn ALU (Instruction[31:21], ALUOp1, ALUOp2, ZeroFlag, ALUResultWire);
	
	//----------------------------------------------------------------------------------
	// Register Update
	//----------------------------------------------------------------------------------
	
	always @(*) begin
		ReadData1 <= ReadData1W;
		ReadData2 <= ReadData2W;
		ALUResult <= ALUResultWire;
	end
	
	always @(posedge clk) begin // Read on positive edge
		case (reset)
			1'b1: begin
				PC <= 32'h00000000;
			end
			default: begin
				casex (Instruction[31:24])
					8'b000101xx: PC <= PC + ({25{Instruction[25]}} ^ Instruction[24:0]) + Instruction[25]; // If opcode == B
					8'hb4: begin // If opcode == CBZ
						case(CBZ)
							1'b0: PC <= PC <= PC + ({18{Instruction[23]}} ^ Instruction[22:5]) + Instruction[23];
							default: PC <= PC + 32'h00000004;
						endcase
					end
					default: PC <= PC + 32'h00000004; // Increment program counter
				endcase
			end
		endcase
	end
	
endmodule