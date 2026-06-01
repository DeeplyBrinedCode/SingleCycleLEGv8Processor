module D_Flipflop(
	input wire D, clk,
	output reg Q, q);
	
		always @(posedge clk) begin
		Q = D;
		q <= ~D;
		end
endmodule