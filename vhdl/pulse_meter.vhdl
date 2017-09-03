library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pulse_meter is
generic ( 
	N : integer := 8 
);
port (
	-- system clock
	clk : in std_logic;
	-- enable
	input : in std_logic;
	-- clear
	clr : in std_logic := '0';
	-- out
	q : out unsigned(N - 1 downto 0);
	done : out std_logic;
	start: buffer std_logic;
	stop: buffer std_logic
);
end pulse_meter;

architecture rtl of pulse_meter is
	signal count : unsigned(N - 1 downto 0);
	signal sync_up : std_logic;
	signal sync_down : std_logic;
	signal enable : std_logic;
	signal pulse: std_logic;
--	signal start:  std_logic;
--	signal stop: std_logic;
begin 
	p_sync_up: process (input, start)
	begin
		if (start = '1') then
			sync_up <= '0';
		elsif rising_edge(input) then
			sync_up <= '1';
		end if;		
	end process p_sync_up;

	p_start: process (clk, sync_up, clr)
	begin
		if (clr = '1') then
			start <= '0';
		elsif rising_edge(clk) then
			start <= sync_up;
		end if;
	end process p_start;

	p_sync_down: process (input, stop)
	begin
		if (stop = '1') then
			sync_down <= '0';
		elsif falling_edge(input) then
			sync_down <= '1';
		end if;		
	end process p_sync_down;

	p_stop: process (clk, sync_down, clr)
	begin
		if (clr = '1') then
			stop <= '0';
		elsif rising_edge(clk) then
			stop <= sync_down;
		end if;
	end process p_stop;

	p_enable: process (clk, start, stop, clr)
	begin
		if (clr = '1') then
			pulse <= '0';
			enable <= '1';
		elsif rising_edge(clk) then
			if (stop = '1') then
				pulse <= '0';
				enable <= '0';
			elsif (start = '1') then
				pulse <= '1';
			end if;
		end if;
	end process p_enable;
    
	p_count: process (clk, enable, start, pulse, stop, clr)
		variable inc: std_logic;
	begin
		inc := start or (pulse and (not stop));
		if rising_edge(clk) then
			if (clr = '1') then
				count <= (others => '0');
			elsif (enable = '1') and (inc = '1') then
				count <= count + 1;
			end if;
		end if;
	end process p_count;

	q <= count;
	done <= not enable;
end rtl;
