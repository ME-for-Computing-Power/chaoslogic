# VCS
COMPILER = vcs -full64 -cc gcc -cpp g++ -LDFLAGS -Wl,-no-as-needed
TOP_MODULE = -top tb_frame_detector

COMPILER += -cm line+cond+fsm+branch+tgl
COMPILER    += -cm_name tb_frame_detector_cov
COMPILER    += -cm_dir ./covdir.vdb

TIMESCALE = -timescale=1ns/100ps
INCDIR = +incdir+config
DEBUG = -debug_access
VCD   = +vcs+dumpvars+test.vcd

# Verdi
PLI_TAB = $(VERDI_HOME)/share/PLI/VCS/LINUXAMD64/novas.tab
PLI_A = $(VERDI_HOME)/share/PLI/VCS/LINUXAMD64/pli.a
FSDB = -fsdb -P $(PLI_TAB) $(PLI_A)


# generate filelist
filelist: $(shell find ./dut -name "*.sv" -or -name "*.v")
	@echo "Generating filelist.f"
	@rm -f filelist.f
	@for file in $^; do echo $$file >> filelist.f; done
	@echo "Filelist generated: filelist.f"
run: filelist
	$(COMPILER) -sverilog -f filelist.f  \
	$(TOP_MODULE)   					 \
	$(TIMESCALE)						 \
	$(INCDIR)						     \
	$(FSDB)							     \
	$(DEBUG)

sim : run
	@echo "Simulation started..."
	./simv -l simv.log -cm line+cond+fsm+branch+tgl
	@echo "Simulation finished."
verdi:
	verdi +v2k -sverilog $(INCDIR) -f filelist.f -ssf wave.fsdb -sswr cfg1.rc

cov: sim
	dve -full64 -dir ./covdir.vdb -cov

.PHONY:clean
clean:
	rm -rf simv.daidir csrc verdiLog novas* simv ucli.key
	rm -rf receive_pool*
	rm -rf wave.*
	rm -rf *.fsdb
	rm -rf *.log
	rm -rf receive_pool*
