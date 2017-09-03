library ieee;
use ieee.std_logic_1164.all; 

entity sync is
port ( 
	-- system clock
	clk : in std_logic; 
	-- flag set
	d : in std_logic; 
	-- data out 
	q : out std_logic
);
end sync;

architecture rtl of sync is 
	signal s1 : std_logic;
	signal s2 : std_logic;
begin 
	ss: process (clk)
	begin
		if rising_edge(clk) then
			s_reg <= d;
		end if;
	end process p_flag;

	q <= d and not s_reg;
end rtl;
