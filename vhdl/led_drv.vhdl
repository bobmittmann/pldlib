library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity led_drv is
generic ( 
	PULSE : integer := 4;
	INV : boolean := false;
	LEVEL : boolean := false
);
port (
	-- system clock
	clk : in std_logic;
	-- delay trigger
	trip : in std_logic;
	-- output
	q : out std_logic
);
end led_drv;

architecture rtl of led_drv is
	signal s_count : unsigned(PULSE-1 downto 0);
	signal s_state: std_logic;
	signal s_edge_sync: std_logic;
	signal s_edge_sync0: std_logic;
	signal s_level_sync: std_logic;
	signal cout: std_logic;
begin 
	process (trip, s_edge_sync)
	begin
		if (s_edge_sync = '1') then
			s_edge_sync0 <= '0';
		elsif rising_edge(trip) then
			s_edge_sync0 <= '1';
		end if;
	end process;

	process (clk, s_edge_sync)
	begin
		if rising_edge(clk) then
			s_edge_sync <= s_edge_sync0;
		end if;
	end process;

	process (trip, clk)
	begin
		if rising_edge(clk) then
			s_level_sync <= trip;
		end if;
	end process;

	process (clk, s_edge_sync, trip, s_state)
		variable carry : std_logic;
	begin
		if rising_edge(clk) then
			if (s_edge_sync = '1') then
				s_state <= '1';
				s_count <= (others => '0');
			else
				if (LEVEL) then
					carry := not s_level_sync;
				else
					carry := '1';
				end if;	
				if (s_state = '1') then
					for i in 0 to (PULSE - 1) loop
						s_count(i) <= s_count(i) xor carry;
						carry := s_count(i) and carry;
					end loop;
				end if;
				s_state <= not carry;			
			end if;
		end if;
	end process;

	q <= not s_state when (INV) else s_state;
end rtl;

