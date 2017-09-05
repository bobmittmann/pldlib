`timescale 10ns/1ns

/* ---------------------------------------------------------------------------
 * Fractional Baud Rate Generator
 * ---------------------------------------------------------------------------
 */
 
module fracbrg
	#(
		parameter CLK_HZ = 24000000,
		parameter BAUDRATE = 38400,
		parameter OVERSAMPLE = 16,
		parameter RESOLUTION = 16
	)
	(
		input rst_i,
		input clk_i,
		input clr_i,
		output brg_stb_o,
		output brg_clk_o
	);

	localparam real FREQ = BAUDRATE * OVERSAMPLE;
	localparam real RES2 = (1 << (RESOLUTION - 1));
	localparam real RES1 = RES2 * 2;
	localparam real RDIV = ((FREQ * RES1) / CLK_HZ);
	localparam integer DIV = RDIV;

	reg [RESOLUTION-1:0] brg_cnt;
	reg brg_clk;
	reg brg_stb;

	always @(posedge clk_i or posedge rst_i)
	begin
		if (rst_i) begin
			brg_cnt <= 0;
			brg_clk <= 0;
			brg_stb <= 0;
		end
		else if (clr_i)
		begin
			brg_cnt <= 0;
			brg_clk <= 0;
			brg_stb <= 0;
		end
		else
		begin
			begin
				brg_cnt <= brg_cnt + DIV;
				brg_clk <= brg_cnt[RESOLUTION-1];
				brg_stb <= brg_cnt[RESOLUTION-1] & 
					(brg_cnt[RESOLUTION-1] ^ brg_clk);
			end
		end
	end

	/* Assign outputs */
	assign brg_clk_o = brg_clk;
	assign brg_stb_o = brg_stb;

endmodule

