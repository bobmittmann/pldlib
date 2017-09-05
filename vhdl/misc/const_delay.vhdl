library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;

entity const_delay is
generic ( 
	DELAY : integer := 5
);
port (
	-- system clock
	clk : in std_logic;
	-- clock enable
	en : in std_logic := '1';
	-- delay trigger
	trip : in std_logic;
	-- assynchronous reset
	rst : in std_logic := '0';
	-- carrty out
	q : out std_logic;
	p : out std_logic;
	y : out std_logic;
	x : out unsigned(integer(ceil(log2(real(DELAY)))) - 1 downto 0)
);
end const_delay;

architecture rtl of const_delay is
	signal comp : unsigned(integer(ceil(log2(real(DELAY)))) - 1 downto 0);	
	signal count : unsigned(integer(ceil(log2(real(DELAY)))) - 1 downto 0);
	signal dff : std_logic;
	signal counting : std_logic;
	signal sync : std_logic;
begin 
    comp <= to_unsigned(DELAY - 1, integer(ceil(log2(real(DELAY)))));
    
    p_trigger: process (clk, rst, en, trip)
	begin
		if (rst = '1') then
			dff <= '0';
		elsif rising_edge(clk) then
			if (en = '1') then
				dff <= trip;
			end if;
		end if;
	end process p_trigger;
	
	-- pulse start detection (sync edge detect)
	sync <= trip and not dff;

	p_sync: process (clk, rst, en, sync, count, comp)
	begin
		if (rst = '1') then
			counting <= '0';
		elsif rising_edge(clk) then
			if (en = '1') then
				if (sync = '1') then
					counting <= '1';
				elsif (count = comp) then
					counting <= '0';
				end if;
			end if;
		end if;
	end process p_sync;

	p_count: process (clk, rst, en, sync, counting)
	begin
		if (rst = '1') then
			count <= (others => '0');
		elsif rising_edge(clk) then
			if (en = '1') then
				if (sync = '1') then
					count <= (others => '0');			
				elsif (counting = '1') then
					count <= count + 1;
				else	
					count <= (others => '0');
				end if;
			end if;
		end if;
	end process p_count;

	q <= '1' when (count = comp) else '0';
	p <= counting;
	x <= count;
	y <= sync;
end rtl;
