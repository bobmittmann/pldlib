
library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;

--  A testbench has no ports.
entity frac_ckgen_tb is
end frac_ckgen_tb;

architecture behav of frac_ckgen_tb is
   --  Declaration of the component that will be instantiated.

	component  frac_ckgen 
		generic ( 
			-- number of bits for the divisor 
			CLK_HZ: integer;
			OUT_HZ : integer;
			RES_BITS : integer
		);
		port (
			clk_i : in std_logic;
			rst_i : in std_logic := '0';	
			en_i : in std_logic := '1';
			clk_o : out std_logic;
			stb_o : out std_logic
		);
   end component;

	--  Specifies which entity is bound with the component.
	for dut0: frac_ckgen use entity work.frac_ckgen;

	signal clk_out, stb_out: std_logic;
	signal  en : std_ulogic := '1';
	signal  rst : std_ulogic := '0';
	signal  clk : std_ulogic := '1';
begin
	--  Component instantiation.
	dut0: frac_ckgen 
		generic map ( 
			CLK_HZ => 10000000,
			OUT_HZ => 2000000,
			RES_BITS => 8) 
		port map (clk_i => clk, rst_i => rst, en_i => en,
				  clk_o => clk_out, stb_o => stb_out);

	-- architecture statement part
	clk <= not clk after 50 ns;

	-- Stimulus process
	stim_proc: process
	begin         
		wait for 100 ns;
		rst <='1';
		wait for 100 ns;
		rst <='0';
		wait for 10000 ns;
		assert false
			report "simulation ended"
			severity failure;
	end process;

end behav;

