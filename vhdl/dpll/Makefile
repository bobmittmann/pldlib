MODULE=dpll

MODULE_TB = $(MODULE)_tb
WORK_LIB = work-obj93.cf
VHDL_FILES = $(MODULE).vhdl $(MODULE_TB).vhdl
MODULE_VCD = $(MODULE_TB).vcd

all: vcd

clean:
	rm -f $(WORK_LIB)
	rm -f $(MODULE_VCD)
	rm -f *~

run:

tb: $(WORK_LIB) 
	ghdl -r $@ 

vcd: $(MODULE_VCD) 

.PHONY: all clean run tb vcd

$(WORK_LIB): $(VHDL_FILES)
	ghdl -a $^

$(MODULE_VCD): $(WORK_LIB)
	ghdl -r $(MODULE_TB) --vcd=$@ 

