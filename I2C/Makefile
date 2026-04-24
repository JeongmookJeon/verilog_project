TC ?= i2c_test
SEED ?= 1234

VCS_OPTS = -full64 -sverilog -ntb_opts uvm-1.2 -timescale=1ns/1ps -debug_access+a -kdb -lca -cm line+cond+fsm+tgl+branch+assert +incdir+tb

SIM_OPTS := +UVM_TESTNAME=$(TC)
SIM_OPTS += +UVM_VERBOSITY=UVM_MEDIUM
SIM_OPTS += +ntb_random_seed=$(SEED)
#SIM_OPTS += -cm lines+cond+fsm+tgl+branch+assert
#SIM_OPTS += -cm_dir coverage.vdb
3SIM_OPTS += -cm_name sim1

VERDI_OPTS := -dbdir simv.daidir -ssf novas.fsdb -covdir coverage.vdb

.PHONY: compile sim clean

compile:
	vcs $(VCS_OPTS) -f filelist.f -o simv 
	@echo "Executing vcs Compilation..."
	@echo "target [$@] completed"

sim: compile
	./simv $(SIM_OPTS) # +UVM_TESTNAME="reset_seq_test" <- Test Class name
	@echo "Executing Simulation..."
	@echo "depend target [$<] completed"
	@echo "target [$@] completed"

verdi:
	verdi $(VERDI_OPTS) &

vw: sim
	verdi -dbdir simv.daidir -ssf novas.fsdb &

vc: sim
	verdi -cov -covdir coverage.vdb &

clean:
	rm -rf simv* csrc *.key *.h *.log *.fsdb novas* *.conf *Log
	@echo "Cleaning..."

A := hello
B := $(A) world
A := goodbye

test:
	@echo $(B)
