
library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;
-- needed for the write and read calls
use std.textio.all;

--  A testbench has no ports.
entity dpll_tb is
end dpll_tb;

architecture behav of dpll_tb is
   --  Declaration of the component that will be instantiated.

	component  dpll 
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
			sdat_i : in std_logic := '1';
			clk_o : out std_logic;
			stb_o : out std_logic
		);
   end component;

	--  Specifies which entity is bound with the component.
	for dut0: dpll use entity work.dpll;

	signal clk_out, stb_out: std_logic;
	signal  en : std_ulogic := '1';
	signal  rst : std_ulogic := '1';
	signal  clk : std_ulogic := '1';
	signal  sig: std_ulogic := '1';
	signal  syn: std_ulogic := '1';
begin
	p_syn: process (clk)
	begin
		if rising_edge(clk) then
			syn <= sig;
		end if;
	end process;

	--  Component instantiation.
	dut0: dpll 
		generic map ( 
			CLK_HZ => 79027200,
			OUT_HZ => 3960000,
			RES_BITS => 14) 
		port map (clk_i => clk, rst_i => rst, en_i => en,
				  sdat_i => syn, clk_o => clk_out, stb_o => stb_out);

	-- architecture statement part
	clk <= not clk after 6.3269 ns;

	-- Stimulus process
	stim_proc: process
	begin         
		rst <='1';
		wait for 10 ns;
		rst <='1';
		wait for 10 ns;
		rst <='0';
		wait for 10000 us;
		assert false
			report "simulation ended"
			severity failure;
	end process;

	file_read: process
		file csv : text open read_mode is "test.csv";
		variable row : line;
		variable i : integer := 0;
		variable n : integer := 0;
		variable v : integer := 0;
		variable t : time;
		variable dt : time;
		variable t0 : time := 0 ns;
	begin         
		-- read from input file in "row" variable
		while (not endfile(csv)) loop
			i := i + 1;
			readline(csv,row);
			-- read integer number from "row" variable in integer array
			read(row, n);
			read(row, v);
			t := n * 2 ns;
			dt := t - t0;
			wait for dt;
			sig <= not sig;
			t0 := t;
		end loop;
		assert false
			report "end of file"
			severity failure;
	end process;

end behav;

