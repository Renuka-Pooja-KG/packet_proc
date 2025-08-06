# Packet Processor UVM Verification Makefile
# Show available test cases and options

# Default target that shows info
run: info

info:
	@echo "/------------------------list of alias name available in make file ----------------------//"
	@echo " along with make pass any of the one parameter to run corresponding test or to open waveform"
	@echo "  all        			 	----> to run all the below test cases use make all command"
	@echo "  base_test  				----> to run the basic_test.sv (basic write/read operations)"
	@echo "  packet_write_test  		----> to run the packet_write_test.sv (packet writing operations)"
	@echo "  packet_read_test  			----> to run the packet_read_test.sv (packet reading operations)"
	@echo "  reset_test  				----> to run the reset_test.sv (reset scenarios)"
	@echo "  concurrent_test  			----> to run the concurrent_test.sv (concurrent read/write)"
	@echo "  mixed_test  				----> to run the mixed_test.sv (mixed operations)"
	@echo "  comprehensive_test  		----> to run the comprehensive_test.sv (all functionality)"
	@echo "  waveform   				----> to open the simvision"
	@echo "  regression 				----> to run the regression & source the cmd and open the imc"
	@echo "  clean      				----> to delete the previous xrun files and cov files"
	@echo "/----------------------------------------------------------------------------------------//"

# Default target that runs all tests
all: base_test packet_write_test packet_read_test reset_test concurrent_test mixed_test comprehensive_test waveform

# Base test case - Basic write/read operations
base_test:
	@echo "[makefile]  base test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=basic_test -uvmhome CDNS-1.1d
	@echo "[makefile]  base test case run is completed successfully"

# Packet write test case
packet_write_test:
	@echo "[makefile]  packet write test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=packet_write_test -uvmhome CDNS-1.1d
	@echo "[makefile]  packet write test case run is completed successfully"

# Packet read test case
packet_read_test:
	@echo "[makefile]  packet read test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=packet_read_test -uvmhome CDNS-1.1d
	@echo "[makefile]  packet read test case run is completed successfully"

# Reset test case
reset_test:
	@echo "[makefile]  reset test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=reset_test -uvmhome CDNS-1.1d
	@echo "[makefile]  reset test case run is completed successfully"

# Concurrent test case
concurrent_test:
	@echo "[makefile]  concurrent test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=concurrent_test -uvmhome CDNS-1.1d
	@echo "[makefile]  concurrent test case run is completed successfully"

# Mixed operations test case
mixed_test:
	@echo "[makefile]  mixed operations test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=mixed_test -uvmhome CDNS-1.1d
	@echo "[makefile]  mixed operations test case run is completed successfully"

# Comprehensive test case
comprehensive_test:
	@echo "[makefile]  comprehensive test case is running"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=comprehensive_test -uvmhome CDNS-1.1d
	@echo "[makefile]  comprehensive test case run is completed successfully"

# Regression test
regression:
	@echo "[makefile]  regression running"
	@echo "[makefile]  Running all test cases in sequence..."
	$(MAKE) base_test
	$(MAKE) packet_write_test
	$(MAKE) packet_read_test
	$(MAKE) reset_test
	$(MAKE) concurrent_test
	$(MAKE) mixed_test
	$(MAKE) comprehensive_test
	@echo "[makefile]  All regression tests completed successfully"
	@echo "[makefile]  Opening coverage viewer..."
	imc &
	@echo "[makefile]  regression was successfully completed"

# Clean previous run files
clean:
	rm -rf *.log *.key xrun.history xcelium.d wave.shm cov_report.txt cov_report_html
	rm -rf simv* csrc* *.vcd *.wlf *.so *.o
	rm -rf INCA_libs* *.shm* *.db* *.vstf* *.ucdb*
	@echo "[makefile]  clean was successfully completed"

# Waveform viewing
waveform:
	simvision wave.shm &

# Compile only (without running)
compile:
	@echo "[makefile]  Compiling design and testbench..."
	xrun -access +rwc -f compile_list.f -uvmhome CDNS-1.1d -compile
	@echo "[makefile]  Compilation completed successfully"

# Run with custom test name
custom_test:
	@echo "[makefile]  Running custom test: $(TEST_NAME)"
	xrun -access +rwc -f compile_list.f +UVM_TESTNAME=$(TEST_NAME) -uvmhome CDNS-1.1d
	@echo "[makefile]  Custom test run is completed successfully"

# Help target
help: info
