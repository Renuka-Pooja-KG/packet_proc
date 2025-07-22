# Makefile for Packet Processor UVM Verification (xrun + simvision only)

RTL_DIR = ..
UVM_DIR = .

DESIGN_FILES = $(RTL_DIR)/int_buffer_top.sv \
               $(RTL_DIR)/int_buffer.sv \
               $(RTL_DIR)/pck_len_buffer.sv \
               $(RTL_DIR)/pck_len_fifo.sv \
               $(RTL_DIR)/pck_proc_int_mem_TOP.sv

TB_FILES = $(UVM_DIR)/packet_proc_agent.sv \
           $(UVM_DIR)/packet_proc_coverage.sv \
           $(UVM_DIR)/packet_proc_driver.sv \
           $(UVM_DIR)/packet_proc_env.sv \
           $(UVM_DIR)/packet_proc_if.sv \
           $(UVM_DIR)/packet_proc_monitor.sv \
           $(UVM_DIR)/packet_proc_scoreboard.sv \
           $(UVM_DIR)/packet_proc_seq_lib.sv \
           $(UVM_DIR)/packet_proc_sequence_base.sv \
           $(UVM_DIR)/packet_proc_sequencer.sv \
           $(UVM_DIR)/packet_proc_test_base.sv \
           $(UVM_DIR)/packet_proc_test_lib.sv \
           $(UVM_DIR)/packet_proc_transaction.sv \
           $(UVM_DIR)/tb_top.sv

UVMHOME ?= CDNS-1.1d
TEST ?= packet_proc_test_base

help:
	@echo "//------------------- Packet Processor UVM Verification Makefile -------------------//"
	@echo "make run TEST=<test_name>     : Run the specified UVM test (default: packet_proc_test_base)"
	@echo "make all                     : Run all major UVM tests (add your test names)"
	@echo "make waveform                : Open SimVision waveform viewer (waves.shm)"
	@echo "make clean                   : Remove all generated files and logs"
	@echo "make help                    : Show this help message"
	@echo "//-----------------------------------------------------------------------------------//"

INCDIRS = +incdir+$(UVM_DIR) \
          +incdir+$(RTL_DIR)

run:
	@echo "[makefile] Running test: $(TEST)"
	xrun -access +rwc $(INCDIRS) $(DESIGN_FILES) $(TB_FILES) -uvmhome $(UVMHOME) +UVM_TESTNAME=$(TEST)

all:
	$(MAKE) run TEST=packet_proc_test_base
	$(MAKE) run TEST=packet_proc_test_lib

waveform:
	@echo "[makefile] Launching SimVision for waveform viewing"
	simvision waves.shm &

clean:
	@echo "[makefile] Cleaning all generated files and logs"
	rm -rf work xcelium.d xcelium.h xrun.history xrun.log xrun.key INCA_libs *.vcd *.log *.wlf waves.shm

.PHONY: run all waveform clean help 