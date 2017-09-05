
LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY lpm;
USE lpm.lpm_components.all;

ENTITY reg8 IS
	PORT
	(
		clk : IN STD_LOGIC ;
		en : IN STD_LOGIC ;
		d : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		q : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END reg8;

ARCHITECTURE SYN OF reg8 IS
	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (7 DOWNTO 0);

	COMPONENT lpm_ff
	GENERIC (
		lpm_width		: NATURAL;
		lpm_type		: STRING;
		lpm_fftype		: STRING
	);
	PORT (
			enable : IN STD_LOGIC ;
			clock : IN STD_LOGIC ;
			q : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
			data : IN STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	q <= sub_wire0(7 DOWNTO 0);

	lpm_ff_component : lpm_ff
	GENERIC MAP (
		lpm_width => 8,
		lpm_type => "LPM_FF",
		lpm_fftype => "DFF"
	)
	PORT MAP (
		enable => en,
		clock => clk,
		data => d,
		q => sub_wire0
	);

END SYN;
