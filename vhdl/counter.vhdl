library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity counter is
generic (
	WIDTH : integer := 32;
	BITS : integer := 8
);
port (
	-- data in
	d : in std_logic_vector(WIDTH - 1 downto 0) := (others => '0');
	-- system clock
	clk : in std_logic;
	-- assynchronous reset 
	rst : in std_logic := '1';
	-- enable
	en : in std_logic := '1';
	-- carry in
	cin : in std_logic := '1';
	-- load
	ld : in std_logic := '0';
	-- synchronous clear
	clr : in std_logic := '0';
	-- up/down count
	up : in std_logic := '1';
	-- data out 
	q : out std_logic_vector(WIDTH - 1 downto 0);
	-- carrty out
	cout : out std_logic
);
end counter;

architecture rtl of counter is 
	signal count : std_logic_vector(BITS - 1 downto 0);
--	signal count : unsigned(BITS - 1 downto 0);

	function vector_fill(x : std_logic_vector(BITS - 1 downto 0)) 
		return std_logic_vector is
		variable y: std_logic_vector(WIDTH - 1 downto 0);
	begin
		y(BITS - 1 downto 0) := x;

		if (WIDTH > BITS) then
			for i in BITS to (WIDTH - 1) loop
				y(i) := '0';
			end loop; 
		end if;
		return y;
	end vector_fill;
begin
	p_count: process (clk, rst, en, clr, ld, cin, count, up)
		variable cy : std_logic;
	begin
		cy := cin;
		for i in 0 to BITS - 1 loop
			if (rst = '1') then
				count(i) <= '0';
			elsif rising_edge(clk) then
				if (en = '1') then
					if (clr = '1') then
						count(i) <= '0';
					elsif (ld = '1') then
						count(i) <= d(i);
					else
						count(i) <= count(i) xor cy;
					end if;
				end if;
			end if;
			cy := (count(i) xor not up) and cy;
		end loop;
		cout <= cy;

--		if rising_edge(clk) then
--			if (en = '1') then
--				if (clr = '1') then
--					count <= (others => '0');
--				elsif (ld = '1') then
--					count <= d;
--				elsif (cin = '1') then
--					if (up = '1') then
--						count <= count + 1;
--					else	
--						count <= count - 1;
--					end if;	
--				end if;
--			end if;
--		end if;
	end process p_count;

--	p_carry: process (cin, count, up)
--	begin
--		if (up = '1') then
--			if (count = (others => '0')) then
--				cout <= cin;
--			else
--				cout <= '0';
--			end if;
--		else	
--			if (count = (others => '1')) then
--				cout <= cin;
--			else
--				cout <= '0';
--			end if;
--		end if;	
--	end process p_carry;

	-- output
--	q <= vector_fill(std_logic_vector(count));
	q <= vector_fill(count);
end rtl;

