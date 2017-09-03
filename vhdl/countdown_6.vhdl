library ieee;
use ieee.std_logic_1164.all; 
use ieee.std_logic_arith.all;

entity countdown_6 is
port ( 
	-- data in
	D : in unsigned(5 downto 0);
	-- system clock
	CLK : in std_logic;
	-- enable
	EN : in std_logic;
	-- load
	LD : in std_logic;
	-- zero
	Z : out std_logic;
	-- data out 
	Q : out unsigned(5 downto 0)
);
end countdown_6;

architecture rtl of countdown_6 is 
	signal s_count : unsigned(5 downto 0);
	signal s_zero : std_logic;
begin 
	p_zero: process (s_count)
	begin
		if (s_count(5 downto 0) = 0) then
			s_zero <= '1';
		else
			s_zero <= '0';
		end if;
	end process p_zero;

	p_count: process (CLK, EN) 
		variable carry : std_logic;
	begin
		if (CLK'event and CLK = '1') then
			if (EN = '1') then
				if (LD = '1') then
					s_count <= D;
				else
					carry := '1';
					s_count(0) <= s_count(0) xor carry;
					carry := (not s_count(0)) and carry;
					for i in 1 to 5 loop
						s_count(i) <= s_count(i) xor carry;
						carry := (not s_count(i)) and carry;
					end loop;
				end if;
			end if;
		end if;
	end process p_count;

	Q(5 downto 0) <= s_count(5 downto 0);
	Z <= s_zero;
end rtl;
