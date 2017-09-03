-- File: addr_select.vhdl
-- Module:
-- Project:	
-- Author:	Robinson Mittmann (bob@boreste.com, bob@methafora.com.br)
-- Target:
-- Comment:
-- Copyright(c) 2004-2009 BORESTE (www.boreste.com). All Rights Reserved.

library ieee;
use ieee.std_logic_1164.all; 

entity select8 is
generic ( 
	n : INTEGER := 8;
	seg : INTEGER := 0
);
port ( 
	-- data in
	ADDR : in unsigned(n-1 downto 0) := (others => '0');
	-- enable
	EN : in std_logic := '1';
	-- select out
	Y0 : out std_logic;
	Y1 : out std_logic;
	Y2 : out std_logic;
	Y3 : out std_logic;
	Y4 : out std_logic;
	Y5 : out std_logic;
	Y6 : out std_logic;
	Y7 : out std_logic
);
end select8;

architecture dataflow of addr_select is 
begin 
	Y0 <= '1' when ADDR = seg else '0';
	Y1 <= '1' when ADDR = seg + 1 else '0';
	Y2 <= '1' when ADDR = seg + 2 else '0';
	Y3 <= '1' when ADDR = seg + 3 else '0';
	Y4 <= '1' when ADDR = seg + 4 else '0';
	Y5 <= '1' when ADDR = seg + 5 else '0';
	Y6 <= '1' when ADDR = seg + 6 else '0';
	Y7 <= '1' when ADDR = seg + 7 else '0';
end dataflow;

