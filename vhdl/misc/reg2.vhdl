library ieee;
use ieee.std_logic_1164.all; 

entity reg2 is
port ( 
	-- system clock
	CLK : in std_logic; 
	-- system reset
	CLR : in std_logic;
	-- enable
	EN : in std_logic;
	-- data in
	D : in std_logic_vector(1 downto 0); 
	-- data out 
	Q : out std_logic_vector(1 downto 0)
);
end reg2;

architecture rtl of reg2 is 
begin 
	p_register: process (CLK)
	begin
		if CLK'event and CLK = '1' then
			if (EN = '1') then
				Q <= D;
			end if;
			if (CLR = '1') then
				Q(1 downto 0) <=  "00";
			end if;
		end if;
	end process p_register;
	
end rtl;

