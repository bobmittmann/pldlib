`timescale 10ns/1ns

//`define MASTER_DELAY
`define INT_DELAY

module fracbrg_tb;

	reg  clk = 0;
	reg  rst = 0;
	reg  clr = 0;
	wire brg_clk;

	initial 
	begin
		$display("-----------------------------------------");
		$dumpfile("fracbrg_tb.vcd");
		$dumpvars(0, fracbrg_tb);
	end

	/* Make a reset that pulses once. */
	initial 
	begin
		# 0 rst = 0;
		# 2 rst = 1;
		# 20 rst = 0;
		# 8520 $stop;
	end

	/* Make a regular pulsing clock. */
	always #4 clk = !clk;

	fracbrg #(.CLK_HZ(79027200),
			  .BAUDRATE(1000000),
			  .OVERSAMPLE(1),
			  .RESOLUTION(32))
		u1 (.clk_i(clk), 
			.rst_i(rst),
			.clr_i(clr),
			.brg_clk_o(brg_clk));

endmodule 

