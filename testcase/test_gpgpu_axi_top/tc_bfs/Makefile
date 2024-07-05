
help:
	@echo "========= help =================="
	@echo "make run-vcs-8w4t                "
	@echo "make run-vcs-4w8t                "
	@echo "make run-vcs-2w16t               "
	@echo "make run-vcs-4w32t               "
	@echo "make verdi                       "
	@echo "make clean                       "
	@echo "================================="

run-vcs-8w4t:
	vcs -full64 -LDFLAGS -Wl,--no-as-needed -R -sverilog -timescale=1ns/1ps -f ../common/run.f -debug_access+all +fsdb+functions -l simv.log +define+CASE_8W4T

run-vcs-4w8t:
	vcs -full64 -LDFLAGS -Wl,--no-as-needed -R -sverilog -timescale=1ns/1ps -f ../common/run.f -debug_access+all +fsdb+functions -l simv.log +define+CASE_4W8T

run-vcs-2w16t:
	vcs -full64 -LDFLAGS -Wl,--no-as-needed -R -sverilog -timescale=1ns/1ps -f ../common/run.f -debug_access+all +fsdb+functions -l simv.log +define+CASE_2W16T

run-vcs-4w32t:
	vcs -full64 -LDFLAGS -Wl,--no-as-needed -R -sverilog -timescale=1ns/1ps -f ../common/run.f -debug_access+all +fsdb+functions -l simv.log +define+CASE_4W32T

verdi:
	verdi -f ../common/run.f -ssf ./test.fsdb &

clean:
	rm -r ./simv* ./csrc ./verdiLog  ./ucli*  ./*.fsdb ./DVE* ./nova* ./*.h  AN.DB
