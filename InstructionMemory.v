module InstructionMemory (
	input wire [31:0] Address,
	output wire [31:0] Instruction
);
	
	reg [31:0] ROM [0:31];

    initial begin
        ROM[0] = 32'h91001401;
        ROM[1] = 32'h91002802;
        ROM[2] = 32'h8B020023;
        ROM[3] = 32'hCB010064;
        ROM[4] = 32'h8A020065;
        ROM[5] = 32'hAA020026;
        ROM[6] = 32'hF8000003;
        ROM[7] = 32'hF8400007;
        ROM[8] = 32'h14000002;
        ROM[9] = 32'h91018C01;
        // Fill remaining spaces with NOP
        ROM[10] = 32'hD503201F; ROM[11] = 32'hD503201F; ROM[12] = 32'hD503201F;
        ROM[13] = 32'hD503201F; ROM[14] = 32'hD503201F; ROM[15] = 32'hD503201F;
        ROM[16] = 32'hD503201F; ROM[17] = 32'hD503201F; ROM[18] = 32'hD503201F;
        ROM[19] = 32'hD503201F; ROM[20] = 32'hD503201F; ROM[21] = 32'hD503201F;
        ROM[22] = 32'hD503201F; ROM[23] = 32'hD503201F; ROM[24] = 32'hD503201F;
        ROM[25] = 32'hD503201F; ROM[26] = 32'hD503201F; ROM[27] = 32'hD503201F;
        ROM[28] = 32'hD503201F; ROM[29] = 32'hD503201F; ROM[30] = 32'hD503201F;
        ROM[31] = 32'hD503201F;
    end
	
	assign Instruction = ROM[Address[6:2]]; // Shifted 2 left since we used byte addressing, instruction every 4 bytes
									
endmodule