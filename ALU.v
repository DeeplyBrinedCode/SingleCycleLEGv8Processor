
module ArLoUn  (
	input [4:0] Ctrl,
	input [7:0] oppA, oppB,
	output reg Z
	);
	
	
	reg[7:0] result;
	
	always @(*) begin
		case(Ctrl)
			5'b00000:	result = oppA + oppB;
			5'b00001:	result = oppA - oppB;
			5'b00010:	result = oppA & oppB;
			5'b00011: 	result = oppA | oppB;
			default: result = 0;
		endcase
	if (result == 0) 
		Z = 1'b1;
	end
endmodule