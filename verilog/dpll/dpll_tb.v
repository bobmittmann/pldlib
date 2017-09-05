`timescale 10ns/100fs

module dpll_tb;

	reg  clk = 0;
	reg  rst = 0;
	reg  clr = 0;
	reg  tdm = 0;
	reg  tdm_din;
	reg  tdm_syn;
	reg  ref_clk = 0;
	wire dpll_clk;
	wire dpll_lock;
	wire dpll_stb;

	localparam integer CLK_HZ = 79027200;
	localparam real CLK = CLK_HZ;
	localparam real CLK_DT = (1.0e9 / CLK) / 20.0;

	localparam real REF_CLK_HZ = 3969200;
	localparam real REF_CLK_DT = (1.0e9 / REF_CLK_HZ) / 10.0;

	initial 
	begin
		$display("-----------------------------------------");
		$dumpfile("dpll_tb.vcd");
		$dumpvars(0, dpll_tb);
	end

	integer r, fd, samp, val;
	real t, t0;
	real dt;

	/* Make a reset that pulses once. */
	initial 
	begin
		# 0 rst = 0;
		# 2 rst = 1;
		# 18 rst = 0;
		# 100000 $stop;
	end

	/* Make a regular pulsing clock. */
	always # CLK_DT clk = !clk;
	always # REF_CLK_DT ref_clk = !ref_clk;

	/* Read from file. */
	initial
	begin
		fd = $fopen( "tdm_anc.csv", "r");
		r = $fscanf(fd, "%d, %d\n", samp, val);
		t = samp * 2 / 10;
		t0 = -8;
		while (r == 2)
		begin
			dt = t - t0;
			# dt tdm = val; 
			r = $fscanf(fd, "%d, %d\n", samp, val);
			t0 = t;
			t = samp * 2 / 10;
		end
		$fclose(fd);
	end

	always @(posedge clk, rst)
	begin
		tdm_din <= tdm;
		tdm_syn <= tdm_din;
	end


	dpll #(.CLK_HZ(79027200),
//			  .OUT_HZ(3969000),
			  .OUT_HZ(3960000),
			  .FRAC_BITS(14))
		u1 (.clk_i(clk), 
			.rst_i(rst),
			.clr_i(clr),
			.sd_i(tdm_syn),
//			.sd_i(ref_clk),
			.stb_o(dpll_stb),
			.clk_o(dpll_clk),
			.lock_o(dpll_lock));

	reg q;

	always @(posedge clk, rst)
	begin
		if (rst)
			q <= 0;
		else if (dpll_stb)
		begin
			q <= !q;
		end
	end

endmodule 

