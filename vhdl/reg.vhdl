library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;

entity reg is
generic (
	N : integer := 8
);
port ( 
	-- system clock
	clk : in std_logic; 
	-- system reset
	clr : in std_logic := '0';
	-- enable
	en : in std_logic := '1';
	-- load
	ld : in std_logic := '1';
	-- data in
	d : in unsigned(N - 1 downto 0); 
	-- data out 
	q : out unsigned(N - 1 downto 0)
);
end reg;

architecture rtl of reg is 
begin 
	p_register: process (clk)
	begin
		if clk'event and clk = '1' then
			if (en = '1') then
				if (clr = '1') then
					q <= (others => '0');
				elsif (ld = '1') then	
					q <= d;
				end if;
			end if;
		end if;
	end process p_register;
end rtl;
