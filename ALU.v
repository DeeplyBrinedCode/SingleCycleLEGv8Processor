
module ArLoUn  (
	input [4:0] Ctrl,
	input [31:0] oppA, oppB,
	output reg Z,
	output reg[31:0] ALU_Result
	);
	
	always @(*) begin
		case(Ctrl)
			5'b00000:	ALU_Result = oppA + oppB;
			5'b00001:	ALU_Result = oppA - oppB;
			5'b00010:	ALU_Result = oppA & oppB;
			5'b00011: 	ALU_Result = oppA | oppB;
			5'b00100:	ALU_Result = !(oppA & oppB);
			default: ALU_Result = 0;
		endcase
	if (ALU_Result == 0) 
		Z = 1'b1;
	end
endmodule
