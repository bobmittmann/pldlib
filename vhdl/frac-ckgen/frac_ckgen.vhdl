-- File:	frac_ckgen.vhdl
-- Author:	Robinson Mittmann (bobmittmann@gmail.com)
-- Target:
-- Comment:
-- Copyright(C) 2011 Bob Mittmann. All Rights Reserved.
-- 
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
-- 

-- 
-- Fractional Clock Generator
-- 

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;
use ieee.math_real.all;

entity frac_ckgen is
generic ( 
	-- number of bits for the divisor 
	CLK_HZ: integer := 24000000;
	OUT_HZ : integer := 1000000;
	RES_BITS : integer := 16
);
port (
	-- clock
	clk_i : in std_logic;
	-- assynchronous reset
	rst_i : in std_logic := '0';	
	-- enable
	en_i : in std_logic := '1';
	-- Clock output
	clk_o : out std_logic;
	-- Strobe output
	stb_o : out std_logic
);
end frac_ckgen;

architecture rtl of frac_ckgen is
	constant FREQ: natural := OUT_HZ;
	constant ONE: natural := (2 ** (RES_BITS - 1)) * 2;
	constant CKGEN_Q: natural := ((FREQ * ONE) / CLK_HZ);
	constant CKGEN_K: natural := CKGEN_Q;
	signal s_cnt: unsigned(RES_BITS - 1 downto 0);
	signal s_clk: std_logic;
	signal s_stb: std_logic;	
begin 

	p_cnt: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			s_cnt <= (others => '0');
			s_clk <= '0';
			s_stb <= '0';
		elsif rising_edge(clk_i) then
			if (en_i = '1') then
				-- increment counter
				s_cnt <= s_cnt + CKGEN_K;
				s_clk <= s_cnt(RES_BITS-1);
				s_stb <= s_cnt(RES_BITS-1) and (s_cnt(RES_BITS-1) xor s_clk);
			end if;
		end if;
	end process p_cnt;

	clk_o <= s_clk;
	stb_o <= s_stb;

end rtl;

