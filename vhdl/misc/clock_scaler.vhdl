library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;

entity clock_scaler is
generic ( 
	DIV : integer := 8 
);
port (
	-- input clock
	clk : in std_logic;
	-- enable
	en : in std_logic := '1';
	-- clear
	rst : in std_logic := '0';
	-- output clock
	q : out std_logic;
	-- hi/lo sync output 
	hi_sync : out std_logic;
	lo_sync : out std_logic
);
end clock_scaler;

architecture rtl of clock_scaler is
	signal count : unsigned(integer(ceil(log2(real(DIV)))) - 1 downto 0);
	signal comp : unsigned(integer(ceil(log2(real(DIV)))) - 1 downto 0);
	signal dff : std_logic;
	signal lo : std_logic;
	signal hi : std_logic;
begin 
    comp <= to_unsigned(DIV - 1, integer(ceil(log2(real(DIV)))));
    hi <= '1' when (count = (comp / 2)) else '0';
    lo <= '1' when (count = comp) else '0';

	p_count: process (clk, rst, hi, lo)
	begin
		if (rst = '1') then
			count <= (others => '0');
			dff <= '0';
		elsif rising_edge(clk) then
			if (en = '1') then
				if (lo = '1') then
					dff <= '0';						
					count <= (others => '0');
				else
					if (hi = '1') then
						dff <= '1';
					end if;
					count <= count + 1;
				end if;		
			end if;
		end if;
	end process p_count;

	q <= dff;
    hi_sync <= hi and en;
    lo_sync <= lo and en;
end rtl;

