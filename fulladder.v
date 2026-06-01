module fulladder(
	input wire A, B, Cin,
	output reg S, Cout, S1, Cout1, S2, Cout2, S3, Cout3);
	
	always @* begin
	// Full adder
	S = A ^ B ^ Cin;
	Cout = A && B || (A ^ B) && Cin;
	// Full Subtractor
	S1 = A ^ B ^ Cin;
	Cout1 = ~A && B || ~A && Cin || B && Cin;
	// Half adder
	S2 = A ^ B;
	Cout2 = A&&B;
	// Half Subtractor
	S3 = A ^ B;
	Cout3 = ~A&&B;
	end
endmodule