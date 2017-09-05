-- File: addr_select.vhdl
-- Module:
-- Project:	
-- Author:	Robinson Mittmann (bob@boreste.com, bob@methafora.com.br)
-- Target:
-- Comment:
-- Copyright(c) 2004-2009 BORESTE (www.boreste.com). All Rights Reserved.

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity select8 is
generic ( 
	N : integer := 4;
	ADDR : integer := 0
);
port ( 
	-- data in
	sel : in unsigned(N - 1 downto 0) := (others => '0');
	-- enable
	en : in std_logic := '1';
	-- select out
	y0 : out std_logic;
	y1 : out std_logic;
	y2 : out std_logic;
	y3 : out std_logic;
	y4 : out std_logic;
	y5 : out std_logic;
	y6 : out std_logic;
	y7 : out std_logic
);
end select8;

architecture dataflow of select8 is
	signal base_addr : unsigned(N - 1 downto 0);	
begin 
    base_addr <= to_unsigned(ADDR, N);
	y0 <= en when (sel = base_addr) else '0';
	y1 <= en when (sel = base_addr + 1) else '0';
	y2 <= en when (sel = base_addr + 2) else '0';
	y3 <= en when (sel = base_addr + 3) else '0';
	y4 <= en when (sel = base_addr + 4) else '0';
	y5 <= en when (sel = base_addr + 5) else '0';
	y6 <= en when (sel = base_addr + 6) else '0';
	y7 <= en when (sel = base_addr + 7) else '0';
end dataflow;

