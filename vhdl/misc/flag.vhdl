library ieee;
use ieee.std_logic_1164.all; 

entity flag is
port ( 
	-- system clock
	clk : in std_logic; 
	-- flag set
	s : in std_logic; 
	-- flag reset
	r : in std_logic; 
	-- data out 
	q : out std_logic
);
end flag;

architecture rtl of flag is 
	signal s_reg : std_logic;
begin 
	p_flag: process (clk)
	begin
		if rising_edge(clk) then
			s_reg <= ((not s_reg) and s) or (s_reg and (not r));
		end if;
	end process p_flag;

	q <= s_reg;
end rtl;
