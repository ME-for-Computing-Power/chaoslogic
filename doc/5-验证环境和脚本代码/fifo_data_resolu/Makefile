# VCS
COMPILER = vcs -full64 -cc gcc -cpp g++ -LDFLAGS -Wl,-no-as-needed
TOP_MODULE = -top tb

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
filelist: 
    @echo "Generating filelist.f"
    @rm -f filelist.f
    @echo "./verification/tb.sv" >> filelist.f
    @echo "./design/dut.v" >> filelist.f
    @echo "./ref_model/ref_model.sv" >> filelist.f
    @echo "Filelist generated: filelist.f"
run: filelist
    $(COMPILER) -sverilog -f filelist.f  \
    $(TOP_MODULE)                        \
    $(TIMESCALE)                         \
    $(INCDIR)                             \
    $(FSDB)                                 \
    $(DEBUG)

sim : run
    @echo "Simulation started..."
    ./simv -l simv.log -cm line+cond+fsm+branch+tgl
    @echo "Simulation finished."
    
verdi:
    verdi +v2k -sverilog $(INCDIR) -f filelist.f -ssf wave.fsdb -sswr cfg1.rc

cov: 
    dve -full64 -dir ./covdir.vdb -cov

urg:
    urg -dir ./covdir.vdb -report urg_report

.PHONY:clean
clean:
    rm -rf simv.daidir csrc verdiLog novas* simv ucli.key
    rm -rf receive_pool*
    rm -rf wave.*
    rm -rf *.fsdb
    rm -rf *.log
    rm -rf receive_pool*