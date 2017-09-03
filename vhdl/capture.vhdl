-- File:	capture.vhdl
-- Module:  
-- Project:	
-- Author:	Robinson Mittmann (bob@boreste.com, bobmittmann@gmail.com)
-- Target:
-- Comment: 
-- Copyright(c) 2009 BORESTE (www.boreste.com). All Rights Reserved.

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;

entity capture is
generic ( 
	DATA_BITS : integer := 32;
	ADDR_BITS : integer := 8;
	VEC_LEN_BITS : integer := 8;
	DW_BITS : integer := 3
);
port (
	-- system clock
	clk : in std_logic;
	-- reset
	rst : in std_logic := '0';
	-- timing 
	m : in std_logic := '0';
	-- timing 
	s : in std_logic := '0';
	-- start
	start : in std_logic := '0';
	-- end of operation 
	done : out std_logic;
	-- vector length
	len : in std_logic_vector(VEC_LEN_BITS - 1 downto 0);
	-- input vector shift direction ('0'->LSB first, '1'->MSB first)
	rx_dir : in std_logic := '0';
	-- memory address to store the input vector
	rx_addr : in std_logic_vector(ADDR_BITS - 1 downto 0);
	-- serial input (TDO)
	rxd : in std_logic;

	cten : out std_logic;
	capt : out std_logic;
	cpen : out std_logic;
	zero : out std_logic;
	
	-- memory interface
	mem_addr : out std_logic_vector(ADDR_BITS - 1 downto 0);
	mem_we : out std_logic;
	mem_din : out std_logic_vector(DATA_BITS - 1 downto 0);

	idl : out std_logic;		
	st1 : out std_logic;
	st2 : out std_logic;
	st3 : out std_logic;
	
	cnt : out std_logic_vector(VEC_LEN_BITS - 1 downto 0);

	b : out unsigned(DW_BITS - 1 downto 0);
	p : out unsigned(ADDR_BITS - 1 downto 0)
);
end capture;

architecture rtl of capture is
	type state_t is (IDLE, S1, S2, S3);

--	constant DW_BITS : integer := integer(ceil(log2(real(DATA_BITS))));

	signal countdown : std_logic_vector(VEC_LEN_BITS - 1 downto 0);

	signal rx_bit_0 : unsigned(DW_BITS - 1 downto 0);
	signal rx_pos_0 : unsigned(ADDR_BITS - 1 downto 0);
	signal rx_bit : unsigned(DW_BITS - 1 downto 0);
	signal rx_pos : unsigned(ADDR_BITS - 1 downto 0);
	signal rx_buf : std_logic_vector(DATA_BITS - 1 downto 0);
	signal rx_vec : std_logic_vector(DATA_BITS - 1 downto 0);

	signal vec_len : unsigned(DATA_BITS - 1 downto 0);

	-- timing 
	signal tm0 : std_logic;
	-- timing 
	signal tm1 : std_logic;

	signal state, next_state : state_t;
	signal cnt_en : std_logic;
	-- capture the input data
	signal capture : std_logic;
	signal cap_en : std_logic;
	-- stores a word into memory
	signal store : std_logic;

	signal eot : std_logic;

	signal count_is_zero : std_logic;

	signal len_mod_data_bits: integer;
begin 

	vec_len <= unsigned(len) - 1;

	len_mod_data_bits <= to_integer(vec_len(DW_BITS downto 0));

	rx_bit_0 <= (others => '0') when (rx_dir = '0') else 
				to_unsigned(len_mod_data_bits, DW_BITS);

	rx_pos_0 <= unsigned(rx_addr) when (rx_dir = '0') else
		unsigned(rx_addr) + vec_len(VEC_LEN_BITS - 1 downto DW_BITS);
	
	tm0 <= s and m;
	tm1 <= s and not m;

--       _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ 
-- CLK _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
--     __   . ___     ___     ___      __     ___     ___     ___   . ___     _
-- TM0   \___/  .\___/   \___/   \__...  \___/   \___/   \___/   \___/   \___/
--        ___   . ___     ___     __      ___     ___     ___     ___     ___ 
-- TM1 __/  .\___/   \___/   \___/  ...__/   \___/   \___/   \___/  .\___/   \_
--          . ___ _______ _______ __   __ _______ _______ _______ _______
-- CNT ______/_35/___34__/___33__/__...__/___03__/___02__/___01__/___00__\_____
--          . _______ ___________ __   ______ _______ _______ _______
-- CNT ______/___34__/___33__/___32_...__03__/___02__/___01__/___00__\_____
--          . ______________________   _______________________________
-- CNT_EN ___/                      ...                             . \_____
--        ___   .                                                   .       
-- START /  .\______________________...________________________________________
--      _____   .                                                   .     _____ 
-- IDLE     .\______________________...__________________________________/
--          . _______                                               .     
-- S1 _______/  .    \______________...________________________________________
--          .   .     ______________   ______________________________
-- S2 _______________/              ...                             .\_________
--          .   .                                                   . ___   
-- S3 ______________________________...______________________________/   \_____
--          .   . _______ _______ __   __ _______ _______ _______ _______
-- RXD __________/___00__/___01__/__...__/___31__/___32__/___33__/___34__\_____
--          .   .     ______________   __________________________________
-- CAP_EN ___________/              ...                             .    \_____
--          .   .     ___     ___      __     ___     ___     ___   . ___    
-- CAPTURE __________/   \___/   \__...  \___/   \___/   \___/   \___/   \_____
--          .   .                             ___               .     ___  
-- STORE ___________________________...______/   \___________________/   \_____
--          .   .                                                   . ___   
-- DONE ____________________________...______________________________/   \_____
--

	p_ctrl: process (state, start, tm0, tm1, count_is_zero)
	begin
		case state is
			when IDLE =>
				cap_en <= '0';
				cnt_en <= '0';
				idl <= '1';
				st1 <= '0';
				st2 <= '0';
				st3 <= '0';
				eot <= '0';
				if (start = '1') then
					next_state <= S1;
				else	
					next_state <= IDLE;				
				end if;

			when S1 =>
				cnt_en <= '1';
				cap_en <= '0';
				idl <= '0';
				st1 <= '1';
				st2 <= '0';
				st3 <= '0';
				eot <= '0';
				
				if (tm1 = '1') then
					if (count_is_zero = '1') then
						next_state <= S3;
					else
						next_state <= S2;				
					end if;
				else	
					next_state <= S1;				
				end if;

			when S2 =>
				cap_en <= '1';
				cnt_en <= '1';
				idl <= '0';
				st1 <= '0';
				st2 <= '1';
				st3 <= '0';
				eot <= '0';				
				if (count_is_zero = '1') and (tm1 = '1') then
					next_state <= S3;
				else
					next_state <= S2;				
				end if;
				
			when S3 =>
				cnt_en <= '0';
				cap_en <= '1';
				idl <= '0';
				st1 <= '0';
				st2 <= '0';
				st3 <= '1';
				eot <=  m;
				if (tm0 = '1') then
					next_state <= IDLE;
				else
					next_state <= S3;				
				end if;
		end case;
	end process p_ctrl;

	p_fsm: process (clk, rst)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				state <= IDLE;
			else	
				state <= next_state;
			end if;	
		end if;		
	end process p_fsm;

	cten <= cnt_en;
	capt <= capture;
	cpen <= cap_en;
	zero <= count_is_zero;
	b <= rx_bit;
	p <= rx_pos;
	done <= eot and tm0;

	---------------------------------------------------------------------------
	-- vector length bit count
	p_count: process (clk, rst, start, countdown, cnt_en, tm1)
		variable cy : std_logic;
	begin
		cy := cnt_en and tm1;
		for i in 0 to VEC_LEN_BITS - 1 loop
			if rising_edge(clk) then
				if (rst = '1') then
					countdown(i) <= '0';
				elsif (start = '1') then
					countdown(i) <= vec_len(i);
--				elsif (tm0 = '1') then
				else
					countdown(i) <= countdown(i) xor cy;
				end if;
			end if;
			cy := (not countdown(i)) and cy;
		end loop;
		count_is_zero <= cy;
	end process p_count;

	---------------------------------------------------------------------------
	-- compute the rx address
	p_rx_pos: process (clk, rst, start, cap_en, tm0, rx_dir, rx_bit, rx_pos, eot, m)
		variable cy : std_logic;
	begin
		cy := cap_en and m;
--		 and tm0;
		for i in 0 to DW_BITS - 1 loop
			if rising_edge(clk) then
				if (rst = '1') then
					rx_bit(i) <= '0';
				elsif (start = '1') then
					rx_bit(i) <= rx_bit_0(i);
				elsif (tm0 = '1') then
					rx_bit(i) <= rx_bit(i) xor cy;
				end if;
			end if;
			cy := (rx_dir xor rx_bit(i)) and cy;
		end loop;
		store <= cy or eot;
		for i in 0 to ADDR_BITS - 1 loop
			if rising_edge(clk) then
				if (rst = '1') then
					rx_pos(i) <= '0';
				elsif (start = '1') then
					rx_pos(i) <= rx_pos_0(i);
				elsif (tm0 = '1') then				
					rx_pos(i) <= rx_pos(i) xor cy;
				end if;
			end if;
			cy := (rx_dir xor rx_pos(i)) and cy;
		end loop;
	end process p_rx_pos;

	capture <= cap_en and tm0;

	---------------------------------------------------------------------------
	-- rxd capture
--	p_capture: process (clk, rst, start, rx_bit, capture, rx_buf, rxd)
--	begin
--		for i in 0 to DATA_BITS - 1 loop
--			if (i = to_integer(rx_bit)) then
--				if rising_edge(clk) then
--					if (capture = '1') then
--						rx_buf(i) <= rxd;
--					end if;
--			end if;
--				rx_vec(i) <= rxd;
--			else
--				rx_vec(i) <= rx_buf(i);
--			end if;
--		end loop;
--	end process p_capture;

	p_capture: process (clk, rst, start, rx_bit, capture, rx_buf, rxd)
	begin
		for i in 0 to DATA_BITS - 1 loop
			if (i = to_integer(rx_bit)) then
				if rising_edge(clk) then
					if (capture = '1') then
						rx_buf(i) <= rxd;
					end if;
				end if;
				rx_vec(i) <= rxd;
			else
				rx_vec(i) <= rx_buf(i);
			end if;
		end loop;
	end process p_capture;



	---------------------------------------------------------------------------
	-- vector address mux
	mem_addr <= std_logic_vector(rx_pos) when store = '1' else (others => '1');
	mem_we <= store and s;
	mem_din <= rx_vec;

	cnt <= countdown;
end rtl;


