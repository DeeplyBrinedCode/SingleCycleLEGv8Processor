//----------------------------------------------------------------------------------
// Register File
//----------------------------------------------------------------------------------
	
module RegisterFile (
	input wire [4:0] ReadReg1, ReadReg2, WriteReg, 
	input wire [31:0] WriteData,
	input wire WriteCmd,
	output reg [31:0] ReadData1, ReadData2
);
	// XZR Register
	reg enable = 1'b0;
	reg XZRWrite = 1'b1;
	reg [31:0] XZRReg = 32'h00000000;
	wire [31:0] XZROut;
	// Write enables
	wire x0_write, x1_write, x2_write, x3_write,
		  x4_write, x5_write, x6_write, x7_write;
	// Register Outputs
	wire [31:0] x0_out, x1_out, x2_out, x3_out,
				  x4_out, x5_out, x6_out, x7_out;
	reg [31:0] Fail_read = 32'hzzzzzzzz;
	
	assign x0_write = (WriteCmd && WriteReg==5'b00000);
	assign x1_write = (WriteCmd && WriteReg==5'b00001);
	assign x2_write = (WriteCmd && WriteReg==5'b00010);
	assign x3_write = (WriteCmd && WriteReg==5'b00011);
	assign x4_write = (WriteCmd && WriteReg==5'b00100);
	assign x5_write = (WriteCmd && WriteReg==5'b00101);
	assign x6_write = (WriteCmd && WriteReg==5'b00110);
	assign x7_write = (WriteCmd && WriteReg==5'b00111);
	
	Register32 XZR(XZRReg, enable, enable, enable, XZRWrite, XZRWrite, XZRWrite, XZROut);
	Register32 X0(WriteData, enable, enable, enable, x0_write, x0_write, x0_write, x0_out);
	Register32 X1(WriteData, enable, enable, enable, x1_write, x1_write, x1_write, x1_out);
	Register32 X2(WriteData, enable, enable, enable, x2_write, x2_write, x2_write, x2_out);
	Register32 X3(WriteData, enable, enable, enable, x3_write, x3_write, x3_write, x3_out);
	Register32 X4(WriteData, enable, enable, enable, x4_write, x4_write, x4_write, x4_out);
	Register32 X5(WriteData, enable, enable, enable, x5_write, x5_write, x5_write, x5_out);
	Register32 X6(WriteData, enable, enable, enable, x6_write, x6_write, x6_write, x6_out);
	Register32 X7(WriteData, enable, enable, enable, x7_write, x7_write, x7_write, x7_out);
	
	always @(*) begin
		case (ReadReg1)
			5'b00000 : ReadData1 = x0_out;
			5'b00001 : ReadData1 = x1_out;
			5'b00010 : ReadData1 = x2_out;
			5'b00011 : ReadData1 = x3_out;
			5'b00100 : ReadData1 = x4_out;
			5'b00101 : ReadData1 = x5_out;
			5'b00110 : ReadData1 = x6_out;
			5'b00111 : ReadData1 = x7_out;
			5'b11111 : ReadData1 = XZROut;
			default : ReadData1 = Fail_read;
		endcase
		
		case (ReadReg2)
			5'b00000 : ReadData2 = x0_out;
			5'b00001 : ReadData2 = x1_out;
			5'b00010 : ReadData2 = x2_out;
			5'b00011 : ReadData2 = x3_out;
			5'b00100 : ReadData2 = x4_out;
			5'b00101 : ReadData2 = x5_out;
			5'b00110 : ReadData2 = x6_out;
			5'b00111 : ReadData2 = x7_out;
			5'b11111 : ReadData2 = XZROut;
			default : ReadData2 = Fail_read;
		endcase
	end
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

	wire w32;
	wire w16;
	wire w8;
	wire out32;
	wire out16;
	wire out8;
	
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