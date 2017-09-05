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

entity dpll is
generic ( 
	-- number of bits for the divisor 
	CLK_HZ: integer := 4000000;
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
	-- reference signal
	sdat_i : in std_logic := '1';
	-- Clock output
	clk_o : out std_logic;
	-- Strobe output
	stb_o : out std_logic
);
end dpll;

architecture rtl of dpll is
	constant FIN: real := real(CLK_HZ);
	constant FOUT: real := real(OUT_HZ);
	constant ONE: real:= real(2 ** (RES_BITS - 1)) * 2.0;
	constant CKGEN_K : natural := natural((FOUT * ONE) / FIN);
	constant DIV_M : natural := 8;

	signal s_cnt: signed(RES_BITS + 5 downto 0);
	signal s_k: signed(RES_BITS + 5 downto 0);
	signal k_min: signed(RES_BITS + 5 downto 0);
	signal k_max: signed(RES_BITS + 5 downto 0);
	signal s_clk: std_logic;
	signal s_edge: std_logic;
	signal s_stb: std_logic;	

	signal s_det: std_logic;
	signal s_ref: std_logic;
	signal s_div: unsigned(DIV_M downto 0);

	signal s_posedge: std_logic;
	signal s_negedge: std_logic;

	-- Hogge Phase Detector (Linear PD)
	signal s_b: std_logic;
	signal s_a: std_logic;
	signal s_y: std_logic;
	signal s_x: std_logic;
	signal s_z: signed(RES_BITS + 5 downto 0);
	signal s_err: signed(RES_BITS + 5 downto 0);
	signal s_adj: signed(RES_BITS + 5 downto 0);
	signal s_zero: signed(RES_BITS + 5 downto 0);
begin 

	k_min <= to_signed(CKGEN_K - 4, k_min'length);
	k_max <= to_signed(CKGEN_K + 4, k_max'length);
	s_zero <= to_signed(0, k_max'length);

	p_cnt: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			s_cnt <= (others => '0');
			s_clk <= '0';
			s_stb <= '0';
			s_edge <= '0';
			s_k <= k_min;
		elsif rising_edge(clk_i) then
			if (en_i = '1') then
--				-- update counter
				s_cnt <= s_cnt + s_k;
				s_clk <= s_cnt(RES_BITS-1);
				s_stb <= s_cnt(RES_BITS-1) and (s_cnt(RES_BITS-1) 
												xor s_clk);

				s_edge <= s_cnt(RES_BITS-1);
				if (s_posedge = '1') and not ((s_x or s_y) = '1') then
					if (s_adj < k_min) then
						s_k <= k_min;
					elsif (s_adj > k_max) then
						s_k <= k_max;
					else
						s_k <= s_adj;
					end if;
				end if;
			end if;
		end if;
	end process p_cnt;

	clk_o <= s_clk;
	stb_o <= s_stb;

	s_negedge <= (s_cnt(RES_BITS-1) xor s_edge) and 
			not s_cnt(RES_BITS-1);
	s_posedge <= (s_cnt(RES_BITS-1) xor s_edge) and 
			s_cnt(RES_BITS-1);

	p_div: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			s_det <= '0';
			s_div <= (others => '0');
		elsif rising_edge(clk_i) then
			s_det <= sdat_i;
			if ((sdat_i xor s_det) = '1' and s_det = '1') then
				s_div <= s_div + 1;
			end if;
		end if;
	end process p_div;

	s_ref <= s_div(DIV_M);

	p_pd: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			s_a <= '0';
			s_b <= '0';
		elsif rising_edge(clk_i) then
			if (s_posedge = '1') then
				s_b <= s_ref;
			end if;
			if (s_negedge = '1') then
				s_a <= s_b;
			end if;
		end if;
	end process p_pd;

	s_y <= s_b xor s_ref;
	s_x <= s_a xor s_b;
	s_z <= to_signed(1, s_z'length) when s_y = '1' else 
		to_signed(-1, s_z'length)  when s_x = '1' else (others => '0');
--	s_adj <= s_k + s_err;
	s_adj <= to_signed(1, s_adj'length) when (s_err > 0) else 
		to_signed(-1, s_adj'length)  when (s_err < 0) else 
		(others => '0');
--	s_adj <= s_k + s_err;

	p_err: process (clk_i, rst_i)
	begin
		if (rst_i = '1') then
			s_err <= (others => '0');
		elsif rising_edge(clk_i) then
			if (s_posedge = '1') and not ((s_x or s_y) = '1') then
				s_err <= (others => '0');
			else
				s_err <= s_err + s_z;
			end if;
		end if;
	end process p_err;


end rtl;

