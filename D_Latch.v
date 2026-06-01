module D_Latch(
	input wire D, E,
	output reg Q, q);
	
		always @* begin
		Q = ~((~D & E) | q);
		q = ~((D & E)| Q);
		end
endmodule