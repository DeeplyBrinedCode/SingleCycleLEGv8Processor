//----------------------------------------------------------------------------------
// Register File
//----------------------------------------------------------------------------------
	
module RegisterFile (
	input wire [4:0] ReadReg1, ReadReg2, WriteReg, 
	input wire [31:0] WriteData,
	input wire WriteCmd,
	output wire [31:0] ReadData1, ReadData2
);

endmodule

//----------------------------------------------------------------------------------
// SINGLE BIT STORAGE
//----------------------------------------------------------------------------------

module bitstorage (
	input wire bitin, enout, writein,
	output wire bitout
);

	reg q = 1'b0;
	
	always @(posedge writein) begin
		q <= bitin;
	end
	
	assign bitout = (enout) ? 1'bz : q;

endmodule

//----------------------------------------------------------------------------------
// 8-bit Register
//----------------------------------------------------------------------------------

module Register8 (
	input wire [7:0] DataIn,
	input wire enout, writein,
	output wire [7:0] DataOut
);

	bitstorage m0(DataIn[0], enout, writein, DataOut[0]);
	bitstorage m1(DataIn[1], enout, writein, DataOut[1]);
	bitstorage m2(DataIn[2], enout, writein, DataOut[2]);
	bitstorage m3(DataIn[3], enout, writein, DataOut[3]);
	bitstorage m4(DataIn[4], enout, writein, DataOut[4]);
	bitstorage m5(DataIn[5], enout, writein, DataOut[5]);
	bitstorage m6(DataIn[6], enout, writein, DataOut[6]);
	bitstorage m7(DataIn[7], enout, writein, DataOut[7]);
	
endmodule

//----------------------------------------------------------------------------------
// 32-bit Register
//----------------------------------------------------------------------------------
	
module Register32 (
	input wire [31:0] DataIn,
	input wire enout32, enout16, enout8, writein32, writein16, writein8,
	output wire [31:0] DataOut
);

	wire w32, w16, w8 = 1'b0;
	wire out32, out16, out8 = 1'b1;
	
	assign w8 = writein8 | writein16 | writein32;
	assign w16 = writein16 | writein32;
	assign w32 = writein32;
	assign out8 = enout8 & enout16 & enout32;
	assign out16 = enout16 & enout32;
	assign out32 = enout32;
	
	Register8 m0(DataIn[7:0], out8, w8, DataOut[7:0]);
	Register8 m1(DataIn[15:8], out16, w16, DataOut[15:8]);
	Register8 m2(DataIn[23:16], out32, w32, DataOut[23:16]);
	Register8 m3(DataIn[31:24], out32, w32, DataOut[31:24]);
	
endmodule