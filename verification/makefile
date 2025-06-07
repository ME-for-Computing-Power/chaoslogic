######################################
# VCS Makefile Template
# For Verilog/SystemVerilog Simulation
######################################

# Project Settings
TOP_MODULE     ?= tb_frame_detector# 顶层测试模块
TIMESCALE      ?= timescale=1ns/1ps# 时间精度 (e.g., "1ns/1ps")
DUMP_WAVEFORM  ?= 0          # 是否生成波形文件 (0/1)

# Tool Paths
VCS            = vcs
SIMV           = ./simv
DVE            = dve
VERDI          = verdi

# Source Files
RTL_SOURCES   += ./rtl/*.sv
TB_SOURCES    += ./tb.sv
INC_DIRS      += ./tb

# Compilation Options
VCS_OPTS      += -R -full64 +v2k# 64-bit compilation
VCS_OPTS      += -sverilog# SystemVerilog support
# VCS_OPTS      += +incdir+$(INC_DIRS)
# VCS_OPTS      += -debug_acc   # Debugging access
# VCS_OPTS      += +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR
# VCS_OPTS      += +vpi 
VCS_OPTS      += -cpp g++ -cc gcc -LDFLAGS -Wl,--no-as-needed 
# VCS_OPTS      += +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv
# VCS_OPTS      += $(UVM_HOME)/src/dpi/uvm_dpi.cc -CFLAGS -DVCS

# Simulation Options
SIM_OPTS      += -l vcs.log
SIM_OPTS      += +ntb_random_seed_automatic
# SIM_OPTS      += +UVM_TEST_NAME=$(UVM_CASE)

# Waveform Options
ifeq ($(DUMP_WAVEFORM), 1)
  VCS_OPTS    += +vcs+vcdpluson
  SIM_OPTS    += +vcs+vcdplusmemon
  WAVE_OPT    ?= +vcs+flush+all
endif

# Coverage Options
VCS_OPTS    += -cm line+cond+fsm+branch+tgl
VCS_OPTS    += -cm_name $(TOP_MODULE)_cov
VCS_OPTS    += -cm_dir ./covdir.vdb
SIM_OPTS    += -cm line+cond+fsm+branch+tgl


# Default Target
all: compile run

# Compilation Target
compile:
	$(VCS) $(VCS_OPTS) \
		-top $(TOP_MODULE) \
		-$(TIMESCALE) \
		$(RTL_SOURCES) $(TB_SOURCES)

# Simulation Target
run:
	$(SIMV) $(SIM_OPTS) $(WAVE_OPT)

# Debug Targets
wave:
	$(DVE) -vpd vcdplus.vpd &

verdi:
	$(VERDI) -ssf novas.fsdb &

cov:
	$(DVE) -full64 -covdir *.vdb &
# Cleanup
clean:
	rm -rf csrc simv* *.vpd *.key *.log *.vdb *.fsdb urgReport DVEfiles *.bak

# Help Information
help:
	@echo "----------------------- Help ------------------------"
	@echo "make compile      - Compile design"
	@echo "make run          - Run simulation"
	@echo "make wave         - Open waveform in DVE"
	@echo "make verdi        - Open waveform in Verdi"
	@echo "make cov          - Open coverage in DVE"
	@echo "make clean        - Remove generated files"
	@echo "make all          - Compile and run (default)"
	@echo "------------------------------------------------------"

.PHONY: all compile run wave verdi clean help