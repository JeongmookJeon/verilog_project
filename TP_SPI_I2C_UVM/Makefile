TC ?= i2c_rand_test
SEED ?= 1234

VCS_OPTS := -full64 -sverilog 
VCS_OPTS += -ntb_opts uvm-1.2 
VCS_OPTS += -timescale=1ns/1ps 
VCS_OPTS += -debug_access+all -kdb -lca
VCS_OPTS += +incdir+./tb
VCS_OPTS += -cm line+cond+fsm+tgl+branch+assert

SIM_OPTS := +UVM_VERBOSITY=UVM_MEDIUM
SIM_OPTS += +ntb_random_seed=$(SEED)
#SIM_OPTS += +UVM_TESTNAME=$(TC)
SIM_OPTS += -cm line+cond+fsm+tgl+branch+assert
SIM_OPTS += -cm_dir coverage.vdb
SIM_OPTS += -cm_name sim1

VERDI_SIM_OPTS := -dbdir simv.daidir -ssf novas.fsdb
VERDI_COV_OPTS := -cov -covdir coverage.vdb

.PHONY: compile sim clean 

compile_spi_m:
	vcs $(VCS_OPTS) -f filelist_spi_m.f -o simv

sim_spi_m: compile_spi_m
	./simv $(SIM_OPTS) +UVM_TESTNAME=spi_master_rand_test

compile_spi_s:
	vcs $(VCS_OPTS) -f filelist_spi_s.f -o simv

sim_spi_s: compile_spi_s
	./simv $(SIM_OPTS) +UVM_TESTNAME=spi_slave_rand_test

compile_i2c:
	vcs $(VCS_OPTS) -f filelist_i2c.f -o simv

sim_i2c: compile_i2c
	./simv $(SIM_OPTS) +UVM_TESTNAME=i2c_rand_test

vw: sim
	verdi $(VERDI_SIM_OPTS) &

vc: sim
	verdi $(VERDI_COV_OPTS) &

clean:
	rm	-rf simv* csrc *.key *.h 

