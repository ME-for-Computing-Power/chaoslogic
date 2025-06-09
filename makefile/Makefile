# VCS
COMPILER = vcs -full64 -cc gcc -cpp g++ -LDFLAGS -Wl,-no-as-needed
TOP_MODULE = -top tb
TIMESCALE = -timescale=1ns/100ps
INCDIR = +incdir+config
DEBUG = -debug_access
VCD   = +vcs+dumpvars+test.vcd
# Verdi
PLI_TAB = $(VERDI_HOME)/share/PLI/VCS/LINUXAMD64/novas.tab
PLI_A = $(VERDI_HOME)/share/PLI/VCS/LINUXAMD64/pli.a
FSDB = -fsdb -P $(PLI_TAB) $(PLI_A)



run:
	$(COMPILER) -sverilog -f filelist.f  \
	$(TOP_MODULE)   					 \
	$(TIMESCALE)						 \
	$(INCDIR)						     \
	$(FSDB)							     \
	$(DEBUG)			     


# verdi:
# 	verdi +v2k -sverilog $(INCDIR) -f filelist.f -ssf wave.fsdb -sswr cfg1.rc


.PHONY:clean
clean:
	rm -rf simv.daidir csrc verdiLog novas* simv ucli.key
	rm -rf receive_pool*
	rm -rf wave.*
	rm -rf *.fsdb
	rm -rf *.log
	rm -rf receive_pool*
