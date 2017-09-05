`timescale 10ns/100fs

/* ---------------------------------------------------------------------------
 * Fractional Baud Rate Generator
 * ---------------------------------------------------------------------------
 */
 
module dpll
	#(
		parameter CLK_HZ = 24000000,
		parameter OUT_HZ = 38400,
		parameter FRAC_BITS = 16
	)
	(
		input rst_i,
		input clk_i,
		input clr_i,
		input sd_i,
		output stb_o,
		output clk_o,
		output dat_o,
		output lock_o
	);

	localparam real FREQ = OUT_HZ;
	localparam real HALF = (1 << (FRAC_BITS - 1));
	localparam real ONE = HALF * 2;
	localparam real Q = FREQ / CLK_HZ;
	localparam real RDIV = Q * ONE;
	localparam integer DIV = RDIV;
	localparam integer RES = FRAC_BITS;

	localparam integer K_MIN = DIV * 0.995;
	localparam integer K_MAX = DIV * 1.005;
	localparam real RGAIN = 0.00007; 
	localparam integer GAIN = RGAIN * ONE;

	reg [RES-1:0] dpll_cnt;
	reg [RES-1:0] dpll_k;
	wire [RES-1:0] dpll_adj;
	wire [RES-1:0] dpll_up;
	reg dpll_clk;
	reg dpll_stb;
	reg dpll_lock;
	wire dpll_negedge;
	wire dpll_posedge;
	wire [RES-1:0] k_min;
	wire [RES-1:0] k_max;

	reg [RES-1:0] sum;

	assign k_min = K_MIN;
	assign k_max = K_MAX;
	assign dpll_up = dpll_cnt + dpll_k;
	assign dpll_negedge = (dpll_up[RES-1] ^ dpll_clk) & !dpll_up[RES-1];
	assign dpll_posedge = (dpll_up[RES-1] ^ dpll_clk) & dpll_up[RES-1];


	/* Control loop */
	always @(posedge clk_i or posedge rst_i)
	begin
		if (rst_i) begin
			dpll_cnt <= 0;
			dpll_clk <= 0;
			dpll_stb <= 0;
			dpll_k <= k_min;
			dpll_lock <= 0;
		end
		else if (clr_i)
		begin
			dpll_cnt <= 0;
			dpll_clk <= 0;
			dpll_stb <= 0;
			dpll_k <= k_min;
			dpll_lock <= 0;
		end
		else
		begin
			dpll_cnt <= dpll_up;
			dpll_clk <= dpll_up[RES-1];
			dpll_stb <= dpll_negedge;

			if (dpll_posedge & !(x | y))
			begin
				if (dpll_adj < K_MIN) 
					dpll_k <= k_min;
				else if (dpll_adj > K_MAX) 
					dpll_k <= k_max;
				else
					dpll_k <= dpll_adj;
			end

			if (dpll_negedge)
			begin
				dpll_lock <= 1;
			end
		end
	end

	/* DPLL outputs */
	assign clk_o = dpll_clk;
	assign stb_o = dpll_stb;
	assign lock_o = dpll_lock;

	reg [12:0] ref_sr;
	wire ref_negedge;
	wire ref_sig;
	reg ref_reg;

	/* Reference shift register */
	always @(posedge clk_i or posedge rst_i)
	begin
		if (rst_i) begin
			ref_sr <= 0;
			ref_reg <= 0;
		end
		else if (clr_i)
		begin
			ref_sr <= 0; 
			ref_reg <= 0;
		end
		else
		begin
			ref_sr[0] <= sd_i; 
			ref_sr[12:1] <= ref_sr[11:0];
			ref_reg <= ref_sig;
		end
	end
	assign ref_negedge = (ref_sr[0] ^ sd_i) & ref_sr[0];
	assign ref_sig = ref_reg ^ ref_negedge;

	/* Hogge Phase Detector (Linear PD) */
	reg b;
	reg a;
	wire y;
	wire x;
	wire [RES-1:0] z;

	always @(posedge clk_i or posedge rst_i)
	begin
		if (rst_i) 
		begin
			a <= 0;
			b <= 0;
		end
		begin
			if (dpll_posedge)
				b <= ref_sig; 
			if (dpll_negedge)
				a <= b;
		end
	end
	assign y = b ^ ref_sig;
	assign x = a ^ b;

	assign z = y * GAIN - x * GAIN;  

	always @(posedge clk_i or posedge rst_i)
	begin
		if (rst_i) 
			sum <= 0;
		else if (clr_i)
			sum <= 0;
		else if (dpll_posedge & !(x | y))
			sum <= 0; 
		else	
			sum <= sum + z;
	end

	assign dpll_adj = dpll_k + sum;

	assign dat_o = ref_sr[0];

endmodule

