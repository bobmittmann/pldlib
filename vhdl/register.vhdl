library ieee;
use ieee.std_logic_1164.all; 

entity reg is

generic (
	dataw : INTEGER := 8;
	addrw : INTEGER := 16;
	addr: INTEGER := 0
);

port (
	-- data in
	D : in unsigned(n-1 downto 0) := (others => '0');
	-- system clock
	CLK : in std_logic := '0';
	
	-- system reset
	CLR : in std_logic;
	-- enable
	EN : in std_logic;
	-- data in
	
	-- data out 
	Q : out std_logic_vector(n-1 downto 0)
);

end reg;

architecture rtl of reg is 
begin 
	p_register: process (CLK)
	begin
		if CLK'event and CLK = '1' then
			if (EN = '1') then
				Q <= D;
			end if;
			if (CLR = '1') then
				Q(n-1 downto 0) <=  (others => '0');
			end if;
		end if;
	end process p_register;
	
end rtl;

