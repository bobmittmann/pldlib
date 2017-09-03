#
# File:		altera.mk
# Module: 
# Project:
# Author:	Robinson Mittmann (bob@boreste.com, bobmittman@gmail.com)
# Target:
# Comment:  
# Copyright(c) 2009-2010 BORESTE (www.boreste.com). All Rights Reserved.

ifndef PLDLIBDIR
	THIS := $(lastword $(MAKEFILE_LIST))
	PLDLIBDIR := $(realpath $(dir $(THIS))..)
endif

VPATH = $(PLDLIBDIR)/vhdl

FAMILY := Cyclone
DEVICE := EP1C3T100C8
OPTIMIZE := speed
EFFORT := fast

QT_MAP = quartus_map
QT_FIT = quartus_fit 
QT_ASM = quartus_asm

###################################################################
# Executable Configuration
###################################################################

#MAP_ARGS := --optimize=$(OPTIMIZE) --effort=$(EFFORT) --parallel
#FIT_ARGS := --part=$(DEVICE) --parallel --effort=$(EFFORT) --64bit
MAP_ARGS := 
FIT_ARGS := 
ASM_ARGS :=
ASM_ARGS :=

QPF = $(PROJECT).qpf
QSF = $(PROJECT).qsf
QDF = $(PROJECT).qdf
RBF = $(PROJECT).rbf
MAP = map.done
FIT = fit.done
ASM = asm.done
STA = sta.done
MAP_LOG = map.log
FIT_LOG = fit.log
ASM_LOG = asm.log
STA_LOG = sta.log
MAP_RPT = $(PROJECT).map.rpt
FIT_RPT = $(PROJECT).fit.rpt
ASM_RPT = $(PROJECT).asm.rpt
STA_RPT = $(PROJECT).sta.rpt
FLOW_RPT = $(PROJECT).flow.rpt

ifdef O
QPF := $(abspath $(addprefix $(O)/,$(QPF)))
QSF := $(abspath $(addprefix $(O)/,$(QSF)))
QDF := $(abspath $(addprefix $(O)/,$(QDF)))
RBF := $(abspath $(addprefix $(O)/,$(RBF)))
MAP := $(abspath $(addprefix $(O)/,$(MAP)))
FIT := $(abspath $(addprefix $(O)/,$(FIT)))
ASM := $(abspath $(addprefix $(O)/,$(ASM)))
STA := $(abspath $(addprefix $(O)/,$(STA)))
MAP_LOG := $(abspath $(addprefix $(O)/,$(MAP_LOG)))
FIT_LOG := $(abspath $(addprefix $(O)/,$(FIT_LOG)))
ASM_LOG := $(abspath $(addprefix $(O)/,$(ASM_LOG)))
STA_LOG := $(abspath $(addprefix $(O)/,$(STA_LOG)))
MAP_RPT := $(abspath $(addprefix $(O)/,$(MAP_RPT)))
FIT_RPT := $(abspath $(addprefix $(O)/,$(FIT_RPT)))
ASM_RPT := $(abspath $(addprefix $(O)/,$(ASM_RPT)))
STA_RPT := $(abspath $(addprefix $(O)/,$(STA_RPT)))
FLOW_RPT := $(abspath $(addprefix $(O)/,$(FLOW_RPT)))
ifndef INSTALL_DIR
INSTALL_DIR := $(O)
endif
OUT_DIR := $(abspath $(O))
VHDL_FILES := $(abspath $(VHDL_FILES))
LOCATIONS := $(abspath $(LOCATIONS))
INSTANCES := $(abspath $(INSTANCES))
else
OUT_DIR := .
endif

ifndef V
V = 0
endif

###################################################################
# Targets
###################################################################
all: $(RBF)

build: qpf qsf map fit asm

clean:
ifeq ($(V),1)
	@rm -fv $(QPF) $(QSF) $(QDF) $(MAP) $(FIT) $(ASM) $(STA) $(RBF); \
	rm -fv $(MAP_LOG) $(FIT_LOG) $(ASM_LOG) $(STA_LOG); \
	rm -fv $(MAP_RPT) $(FIT_RPT) $(ASM_RPT) $(STA_RPT) $(FLOW_RPT); \
	cd $(OUT_DIR); \
	rm -rfv *.summary *.smsg *.eqn *.pin *.sof \
	   *.pof *.qws db incremental_db
else
	@rm -f $(QPF) $(QSF) $(QDF) $(MAP) $(FIT) $(ASM) $(STA) $(RBF); \
	rm -f $(MAP_LOG) $(FIT_LOG) $(ASM_LOG) $(STA_LOG); \
	rm -f $(MAP_RPT) $(FIT_RPT) $(ASM_RPT) $(STA_RPT) $(FLOW_RPT); \
	cd $(OUT_DIR); \
	rm -rf *.summary *.smsg *.eqn *.pin *.sof \
	   *.pof *.qws db incremental_db
endif

install:
ifeq ($(V),1)
	if [ ! -d $(INSTALL_DIR) ]; then\
		mkdir $(INSTALL_DIR);\
	fi;
	cp -f $(RBF) $(INSTALL_DIR)
else
	@if [ ! -d $(INSTALL_DIR) ]; then\
		mkdir $(INSTALL_DIR);\
	fi;
	@echo "INSTALL: $(INSTALL_DIR)"
	@cp -f $(RBF) $(INSTALL_DIR)
endif

qpf: $(QPF)

qsf: $(QSF)

qdf: $(QDF)

map: $(MAP)

fit: $(FIT)

asm: $(ASM)

sta: $(STA)

###################################################################
# Target implementations
###################################################################

$(QPF): Makefile
	@echo "PROJECT_REVISION = \"$(PROJECT)\"" > $@;\
	echo >> $@

$(QDF): Makefile $(VHDL_FILES) $(LOCATIONS) $(INSTANCES)
	@echo "set_global_assignment -name FAMILY \"$(FAMILY)\"" > $@;\
	echo "set_global_assignment -name DEVICE \"$(DEVICE)\"" >> $@;\
	echo "set_global_assignment -name TOP_LEVEL_ENTITY $(PROJECT)" >> $@;\
	echo "set_global_assignment -name OPTIMIZE_HOLD_TIMING $(OPTIMIZE_HOLD_TIMING)" >> $@;\
	echo "set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING $(OPTIMIZE_POWER_DURING_SYNTHESIS)" >> $@;\
	echo "set_global_assignment -name HDL_MESSAGE_LEVEL $(HDL_MESSAGE_LEVEL)" >> $@;\
	echo "set_global_assignment -name STATE_MACHINE_PROCESSING \"$(STATE_MACHINE_PROCESSING)\"" >> $@;\
	echo "set_global_assignment -name SYNTH_MESSAGE_LEVEL $(SYNTH_MESSAGE_LEVEL)" >> $@;\
	echo "set_global_assignment -name ENABLE_INIT_DONE_OUTPUT OFF" >> $@;\
	echo "set_global_assignment -name USE_CONFIGURATION_DEVICE OFF" >> $@;\
	echo "set_global_assignment -name RESERVE_ASDO_AFTER_CONFIGURATION \"USE AS REGULAR IO\"" >> $@;\
	echo "set_global_assignment -name CYCLONE_CONFIGURATION_SCHEME \"PASSIVE SERIAL\"" >> $@;\
	echo "set_global_assignment -name GENERATE_RBF_FILE ON" >> $@;\
	for f in $(VHDL_FILES) ; do\
		echo "set_global_assignment -name VHDL_FILE $$f" >> $@;\
	done;\
	cat $(LOCATIONS) | sed -n "/[ \t]*#/!s/ *\(\<[A-Z0-9_]\+\) \+\([][A-Za-z0-9_]\+\) */set_location_assignment \1 -to \2/p" >> $@;\
	cat $(INSTANCES) | sed -n "/[ \t]*#/!s/ *\(\<[A-Za-z0-9_ ]\+\), \+\([][A-Za-z0-9_ ]\+\) */set_instance_assignment -name \1 -to \2/p" >> $@;\
	echo >> $@
	@cp $@ $(QSF)

$(QSF): $(QDF)
	cp $(QDF) $@


ifeq ($(V),0)
$(MAP): $(QDF)
	@cd $(OUT_DIR);\
	rm -f $@;\
	$(QT_MAP) $(MAP_ARGS) $(PROJECT) >  $(MAP_LOG) && echo done > $@;\
	cat $(MAP_LOG) |\
	sed "s/File:.*Line: [0-9]\+//" |\
	sed -n "/^[A-Z][a-z]\+ ([0-9]\+):/s/\([A-Za-z]\+\) ([0-9]\+): *\(.*\) \(at\|in\) \([A-Za-z0-9._-]\+\)(\([0-9]\+\))[ :]*\(.*\)/\4:\5: \L\1\E \2 \6/p";\
	if [ ! -f $@ ]; then exit 1; fi
else
$(MAP): $(QDF)
	cd $(OUT_DIR);\
	rm -f $@;\
	$(QT_MAP) $(MAP_ARGS) $(PROJECT) >  $(MAP_LOG) && echo done > $@;\
	cat $(MAP_LOG) |\
	sed "s/File:.*Line: [0-9]\+//" |\
	sed -n "/^[A-Z][a-z]\+ ([0-9]\+):/s/\([A-Za-z]\+\) ([0-9]\+): *\(.*\) \(at\|in\) \([A-Za-z0-9._-]\+\)(\([0-9]\+\))[ :]*\(.*\)/\4:\5: \L\1\E \2 \6/p";\
	if [ ! -f $@ ]; then exit 1; fi
endif


#	sed -n "/^[ ]* [A-Z][a-z]\+:/p"|\

ifeq ($(V),0)
$(FIT): $(MAP)
	@cd $(OUT_DIR);\
	rm -f $@;\
	$(QT_FIT) $(FIT_ARGS) $(PROJECT) > $(FIT_LOG) && echo done > $@;\
	cat $(FIT_LOG) | sed "/[ ]*Info:.*/d;/^[ \t]\+/d;/[ ]*Note:/d";\
	if [ ! -f $@ ]; then exit 1; fi
else
$(FIT): $(MAP)
	cd $(OUT_DIR);\
	rm -f $@;\
	$(QT_FIT) $(FIT_ARGS) $(PROJECT) > $(FIT_LOG) && echo done > $@;\
	cat $(FIT_LOG) | sed "/[ ]*Info:.*/d;/^[ \t]\+/d;/[ ]*Note:/d";\
	if [ ! -f $@ ]; then exit 1; fi
endif
#	sed "/[ ]\+Info:.*/d"

ifeq ($(V),0)
$(ASM): $(FIT)
	@cd $(OUT_DIR);\
	($(QT_ASM) $(ASM_ARGS) $(PROJECT) && echo done > $@) | \
	sed "/[ ]\+Info:.*/d"
else
$(ASM): $(FIT)
	cd $(OUT_DIR);\
	($(QT_ASM) $(ASM_ARGS) $(PROJECT) && echo done > $@) | \
	sed "/[ ]\+Info:.*/d"
endif

ifeq ($(V),0)
$(STA): $(FIT)
	@cd $(OUT_DIR);\
	(quartus_sta $(TAN_ARGS) $(PROJECT) && echo done > $@) | \
	sed "/[ ]\+Info:.*/d"
else
$(STA): $(FIT)
	cd $(OUT_DIR);\
	(quartus_sta $(TAN_ARGS) $(PROJECT) && echo done > $@) | \
	sed "/[ ]\+Info:.*/d"
endif

$(RBF): $(ASM)

