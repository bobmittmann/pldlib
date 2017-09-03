library ieee;
use ieee.std_logic_1164.all; 

entity reg1 is
port ( 
	-- system clock
	clk : in std_logic; 
	-- system reset
	clr : in std_logic := '0';
	-- enable
	en : in std_logic := '1';
	-- data in
	d : in std_logic; 
	-- data out 
	q : out std_logic
);
end reg1;

architecture rtl of reg1 is 
begin 
	p_register: process (clk, en, clr)
	begin
		if clk'event and clk = '1' then
			if (en = '1') then
				q <= d;
			end if;
			if (clr = '1') then
				q <= '0';
			end if;
		end if;
	end process p_register;
end rtl;

