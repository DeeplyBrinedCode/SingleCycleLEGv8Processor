module FullSubtractor(
	input wire A, B, Bin,
	output wire D, Bout);
	
	D = A ^ B ^ Bin;
	Bout = ~A & B || ~A & Bin || B & Bin;
endmodule