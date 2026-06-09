module ArLoUn  (
	input [10:0] Ctrl,
	input [31:0] oppA, oppB,
	output reg Z,
	output reg [31:0] ALU_Result
	);
	
	always @(*) begin
		case(Ctrl)
			11'h458, 11'h488, 11'h489:	ALU_Result = oppA + oppB;
			11'h658, 11'h688, 11'h689:	ALU_Result = oppA - oppB;
			11'h450:	ALU_Result = oppA & oppB;
			11'h550: ALU_Result = oppA | oppB;
			11'h4bc:	ALU_Result = ~(oppA & oppB); //11'h4bc is the NAND opcode
			default: ALU_Result = 0;
		endcase
		if (ALU_Result == 0) begin
			Z = 1'b1;
		end else begin
			Z = 1'b0;
		end
	end
endmodule
