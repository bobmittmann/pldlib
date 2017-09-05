-- File:	jtag_shifter.vhdl
-- Module:  
-- Project:	
-- Author:	Robinson Mittmann (bob@boreste.com, bobmittmann@gmail.com)
-- Target:
-- Comment: JTAG TDO/TDI Shifter
--  shits in and out a vector of arbitrary length form memory
--  shits right or left depending upon the rx_dir and tx_dir signals
--  
-- Copyright(c) 2009 BORESTE (www.boreste.com). All Rights Reserved.

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;

entity jtag_shifter is
generic ( 
	DATA_BITS : integer := 32;
	ADDR_BITS : integer := 8;
	VEC_LEN_BITS : integer := 8
);
port (
	-- system clock
	clk : in std_logic;
	-- reset
	rst : in std_logic := '0';
	-- timing synchronization
	sync: in std_logic := '0';
	-- timing phase
	phase: in std_logic := '0';
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
	-- output vector shift direction ('0'->LSB first, '1'->MSB first)
	tx_dir : in std_logic := '0';
	-- memory address for the output vector
	tx_addr : in std_logic_vector(ADDR_BITS - 1 downto 0);
	-- serial input (TDO)
	rxd : in std_logic;
	-- serial output (TDI)
	txd : out std_logic;
	-- memory interface
	mem_din : out std_logic_vector(DATA_BITS - 1 downto 0);
	mem_addr : out std_logic_vector(ADDR_BITS - 1 downto 0);
	mem_we : out std_logic;
	mem_dout : in std_logic_vector(DATA_BITS - 1 downto 0);
	-- debug signals
	idl : out std_logic;		
	st1 : out std_logic;
	st2 : out std_logic;
	st3 : out std_logic
);
end jtag_shifter;

architecture rtl of jtag_shifter is
    -- number of bits needed to store the width of the data
	constant DW_BITS : integer := integer(ceil(log2(real(DATA_BITS))));
	-- control finite state machine states
	type state_t is (S0, S1, S2, S3);
	-- count the number of bits remaining
	signal countdown : std_logic_vector(VEC_LEN_BITS - 1 downto 0);
	-- initial bit position in the receive buffer
	signal rx_bit_0 : unsigned(DW_BITS - 1 downto 0);
	-- initial word position in the vector memory
	signal rx_pos_0 : unsigned(ADDR_BITS - 1 downto 0);
	-- current bit position in the receive buffer
	signal rx_bit : unsigned(DW_BITS - 1 downto 0);
	-- current word position (address) in the vector memory
	signal rx_pos : unsigned(ADDR_BITS - 1 downto 0);
	-- receive buffer
	signal rx_buf : std_logic_vector(DATA_BITS - 1 downto 0);
	-- auxiliary signal
	signal rx_vec : std_logic_vector(DATA_BITS - 1 downto 0);
	-- initial bit position in the transmit buffer
	signal tx_bit_0 : unsigned(DW_BITS - 1 downto 0);
	-- initial word position in the vector memory for transmission
	signal tx_pos_0 : unsigned(ADDR_BITS - 1 downto 0);
	-- current bit position in the transmit buffer
	signal tx_bit : unsigned(DW_BITS - 1 downto 0);
	-- current word position in the vector memory for transmission
	signal tx_pos : unsigned(ADDR_BITS - 1 downto 0);
	-- transmit buffer
	signal tx_buf : std_logic_vector(DATA_BITS - 1 downto 0);
	-- timing 
	signal tm0 : std_logic;
	-- timing 
	signal tm1 : std_logic;
	-- finite state machine states
	signal state, next_state : state_t;
	-- counter is enabled
	signal idle: std_logic;
	-- counter is enabled
	signal cnt_en : std_logic;
	-- capture the input data
	signal cap_en : std_logic;
	signal capture: std_logic;
	-- stores a word into memory
	signal store : std_logic;
	-- load a word from memory
--	signal load_en : std_logic;
	signal load : std_logic;
	-- indicate the end of operation
	signal stop: std_logic;
	-- countdown is zero
	signal count_is_zero : std_logic;
	-- auxiliary signal
	signal vec_len : unsigned(VEC_LEN_BITS - 1 downto 0);
begin 
	-- the vector length is decremented by one to simplify the
	-- remaining operations and control structures
	-- NOTICE: a vector length of size 0 will result in a maximum length
	-- vector being transmitted/received
	vec_len <= unsigned(len) - 1;
	-- compute the initial rx bit position
	rx_bit_0 <= (others => '0') when (rx_dir = '0')
				else vec_len(DW_BITS - 1 downto 0);
	-- compute the initial rx word position
	rx_pos_0 <= unsigned(rx_addr) when (rx_dir = '0') else
		unsigned(rx_addr) + vec_len(VEC_LEN_BITS - 1 downto DW_BITS);
	-- compute the initial tx bit position
	tx_bit_0 <= (others => '0') when (tx_dir = '0') 
				else vec_len(DW_BITS - 1 downto 0);
	-- compute the initial tx word position
	tx_pos_0 <= unsigned(tx_addr) when (tx_dir = '0') else 
		unsigned(tx_addr) + vec_len(VEC_LEN_BITS - 1 downto DW_BITS);

--       _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ 
-- CLK _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
--                _______         _______         _______         _______   
-- PHASE \_______/       \_______/       \_______/       \_______/       \_____ 
--      _     ___     ___     ___     ___     ___     ___     ___     ___     _
-- SYNC  \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/   \___/ 
--     __             ___             ___             ___             ___      
-- TM0   \___________/   \___________/   \___________/   \___________/   \_____
--     __     ___             ___             ___             ___             _
-- TM1   \___/   \___________/   \___________/   \___________/   \___________/
-- 
	tm0 <= sync and phase;
	tm1 <= sync and not phase;
--       _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ 
-- CLK _/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \
--     __   . ___     ___     ___      __     ___     ___     ___   . ___     _
-- TM0   \___/  .\___/   \___/   \__...  \___/   \___/   \___/   \___/   \___/
--        ___   . ___     ___     __      ___     ___     ___     ___     ___ 
-- TM1 __/  .\___/   \___/   \___/  ...__/   \___/   \___/   \___/  .\___/   \_
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
--        ___   .                         ___                       .      
-- LOAD _/   \______________________...__/   \_________________________________
--          . _______ _______ ______   ______ _______ _______ _______
-- TXD ______/___00__/___01__/___02_...__31__/___32__/___33__/___34__\_________
--          .   .                                                   . ___   
-- STOP ____________________________...______________________________/   \_____
--        __________________________   ______________________________      
-- LD_EN /                          ...                             .\_________
--

	p_ctrl: process (state, start, phase, tm0, tm1, count_is_zero)
	begin
		case state is
			when S0 =>
				cap_en <= '0';
				cnt_en <= '0';
				idle <= '1';
				idl <= '1';
				st1 <= '0';
				st2 <= '0';
				st3 <= '0';
				stop <= '0';
				if (start = '1') then
					next_state <= S1;
				else	
					next_state <= S0;				
				end if;
			-- state 1 enables the counter
			when S1 =>
				cnt_en <= '1';
				cap_en <= '0';
				idle <= '0';
				idl <= '0';
				st1 <= '1';
				st2 <= '0';
				st3 <= '0';
				stop <= '0';
				if (tm1 = '1') then
					-- the counter will be zero here if the
					-- vector size is one, in this case
					-- we jump to the termination  state (S3)
					if (count_is_zero = '1') then
						next_state <= S3;
					else
						next_state <= S2;				
					end if;
				else	
					next_state <= S1;				
				end if;
			-- state 2 enable capturing the rxd input
			when S2 =>
				cap_en <= '1';
				cnt_en <= '1';
				idle <= '0';
				idl <= '0';
				st1 <= '0';
				st2 <= '1';
				st3 <= '0';
				stop <= '0';				
				if (count_is_zero = '1') and (tm1 = '1') then
					next_state <= S3;
				else
					next_state <= S2;				
				end if;
			-- the final state is used to store the last received word 
			-- and to signal the end of the cycle	
			when S3 =>
				cnt_en <= '0';
				cap_en <= '1';
				idle <= '0';
				idl <= '0';
				st1 <= '0';
				st2 <= '0';
				st3 <= '1';
				stop <=  phase;
				if (tm0 = '1') then
					next_state <= S0;
				else
					next_state <= S3;				
				end if;
		end case;
	end process p_ctrl;
	-- bottom layer of the controller fsm
	p_fsm: process (clk, rst)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				state <= S0;
			else	
				state <= next_state;
			end if;	
		end if;		
	end process p_fsm;
--	load_en <= start or cnt_en;
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
	p_rx_pos: process (clk, rst, start, cap_en, rx_dir, rx_bit, rx_pos, 
					   stop, phase, tm0)
		variable cy : std_logic;
	begin
		cy := cap_en and phase;
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
		store <= cy or stop;
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

	-- rxd capture signal
	capture <= cap_en and tm0;

	---------------------------------------------------------------------------
	-- rxd capture
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
	-- compute the tx address
	p_tx_pos: process (clk, rst, start, cnt_en, tx_dir, tx_bit, tx_pos, 
					   phase, tm1)
		variable cy : std_logic;
	begin
--		cy := cnt_en and not phase;
		cy := cnt_en;
		for i in 0 to DW_BITS - 1 loop
			if rising_edge(clk) then
				if (rst = '1') then
					tx_bit(i) <= '0';
				elsif (start = '1') then
					tx_bit(i) <= tx_bit_0(i);
				elsif (tm1 = '1') then
					tx_bit(i) <= tx_bit(i) xor cy;
				end if;
			end if;
			cy := (tx_dir xor tx_bit(i)) and cy;
		end loop;
		load <= cy and tm1;
		for i in 0 to ADDR_BITS - 1 loop
			if rising_edge(clk) then
				if (rst = '1') then
					tx_pos(i) <= '0';
				elsif (start = '1') then
					tx_pos(i) <= tx_pos_0(i);
				elsif (tm0 = '1') then				
					tx_pos(i) <= tx_pos(i) xor cy;
				end if;
			end if;
			cy := (tx_dir xor tx_pos(i)) and cy;
		end loop;
	end process p_tx_pos;
	-- loads a word from memory into the transmit buffer
	p_load: process (clk, rst, start, load, tm1)
	begin
		if rising_edge(clk) then
			if (rst = '1') then
				tx_buf <= (others => '0');
			elsif (start = '1') or (load = '1') then
				tx_buf <= mem_dout;
			end if;
		end if;
	end process p_load;
	-- select the bit to be transmitted from tx_buf
	txd <= tx_buf(to_integer(tx_bit));

	-- signal the end of cycle
	done <= stop and sync;
	---------------------------------------------------------------------------
	-- vector address mux
	mem_addr <= std_logic_vector(rx_pos) when store = '1' else 
		std_logic_vector(tx_pos_0) when idle = '1' else 
		std_logic_vector(tx_pos);
	mem_we <= store and sync;
	mem_din <= rx_vec;
end rtl;

