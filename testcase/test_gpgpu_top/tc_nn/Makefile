
help:
	@echo "========= help =================="
	@echo "make run-vcs                     "
	@echo "make verdi                       "
	@echo "make clean                       "
	@echo "================================="

run-vcs:
	vcs -full64 -cpp g++-4.8 -cc gcc-4.8 -LDFLAGS -Wl,--no-as-needed -R -timescale=1ns/1ps -fsdb -f ../testbench/run.f -debug_access+all -l simv.log
	#vcs -full64 -LDFLAGS -Wl,--no-as-needed -R -sverilog -timescale=1ns/1ps -f ../testbench/run.f -debug_access+all +fsdb+functions -l simv.log 

verdi:
	verdi -f ../testbench/run.f -ssf ./test.fsdb &

clean:
	rm -r ./simv* ./csrc ./verdiLog  ./ucli*  ./*.fsdb ./DVE* ./nova* ./*.h  AN.DB
