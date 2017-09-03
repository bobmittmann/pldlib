-- File: cmp_eq.vhdl
-- Module:
-- Project:	
-- Author:	Robinson Mittmann (bob@boreste.com, bob@methafora.com.br)
-- Target:
-- Comment: equality comparator
-- Copyright(c) 2004-2009 BORESTE (www.boreste.com). All Rights Reserved.

library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity cmp_eq is
generic ( 
	n : INTEGER := 8
);
port ( 
	-- data in
	A : in unsigned(n-1 downto 0) := (others => '0');
	B : in unsigned(n-1 downto 0) := (others => '0');
	-- compare out
	EQ : out std_logic
);
end cmp_eq;

architecture dataflow of cmp_eq is 
begin 
	EQ <= '1' when A = B else '0';
end dataflow;
