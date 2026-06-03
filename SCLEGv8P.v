module SCLEGv8P (
	input wire clk, reset
	);
	
	reg [31:0] PC, Instruction, ReadData1, ReadData2, Immediate, ALUResult, MemData;
	wire [31:0] PC_wire, Instruction_wire;
	
	assign PC_wire = PC;
	
	//----------------------------------------------------------------------------------
	// Instruction Memory
	//----------------------------------------------------------------------------------
	
	InstructionMemory IM (PC_wire, Instruction_wire);
	
	//----------------------------------------------------------------------------------
	// Register File
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
			end
		endcase
	end
endmodule