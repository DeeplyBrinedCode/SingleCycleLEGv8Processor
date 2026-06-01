module reg8(input[0:7]d, 
input clk, output reg[0:7]q);

always@(posedge clk)
	begin
		q <= d;
	end
endmodule