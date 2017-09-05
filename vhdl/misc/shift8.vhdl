library ieee;
use ieee.std_logic_1164.all;

entity shift8 is
port ( 
	-- system clock
	CLK : in std_logic; 
	-- enable
	EN : in std_logic;
	-- load/shift
	LD : in std_logic;
	-- Serial Input
	SDI : in std_logic;
	-- data in
	D : in std_logic_vector(7 downto 0);
	-- Serial Output
	SDO : out std_logic;
	-- data out 
	Q : out std_logic_vector(7 downto 0)
	
);
end shift8;

architecture rtl of shift8 is 
	signal s_reg : std_logic_vector(7 downto 0);
begin 
	p_shiftregister: process (CLK, EN, LD, SDI, D)
	begin
		if CLK'event and CLK = '1' then
			if EN = '1' then
				if LD = '1' then
					s_reg(7 downto 0) <= D(7 downto 0);
				else
					s_reg(7) <= SDI;
					s_reg(6 downto 0) <= s_reg(7 downto 1);
				end if;
			else
				s_reg(7 downto 0) <= s_reg(7 downto 0);
			end if;
		end if;
	end process p_shiftregister;
	
	Q(7 downto 0) <= s_reg(7 downto 0);
	SDO <= s_reg(0);
end rtl;

