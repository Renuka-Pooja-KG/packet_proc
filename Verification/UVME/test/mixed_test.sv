// Mixed Operations Test for Packet Processor
// Tests mixed read/write operations with proper reset initialization

class mixed_test extends uvm_test;
  `uvm_component_utils(mixed_test)

  pkt_proc_env env;
  
  // Mixed test sequences
  mixed_operations_sequence mixed_seq;
  overflow_test_sequence overflow_seq;
  underflow_test_sequence underflow_seq;
  
  // Reset initialization sequence
  reset_initialization_sequence reset_init_seq;

  function new(string name = "mixed_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pkt_proc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("MIXED_TEST", "Starting mixed operations test suite", UVM_LOW)
    
    // Initialize DUT with reset
    `uvm_info("MIXED_TEST", "Phase 1: Initializing DUT with reset", UVM_LOW)
    reset_init_seq = reset_initialization_sequence::type_id::create("reset_init_seq");
    reset_init_seq.reset_cycles = 5;  // 5 clock cycles of reset
    reset_init_seq.idle_cycles = 3;   // 3 idle cycles after reset
    reset_init_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between initialization and tests
    repeat(10) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 1: Mixed operations sequence
    `uvm_info("MIXED_TEST", "Phase 2: Starting mixed operations test", UVM_LOW)
    mixed_seq = mixed_operations_sequence::type_id::create("mixed_seq");
    mixed_seq.transaction_count = 100;
    mixed_seq.enable_reset = 0;  // Don't reset again, already done
    mixed_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 2: Overflow test
    `uvm_info("MIXED_TEST", "Phase 3: Starting overflow test", UVM_LOW)
    overflow_seq = overflow_test_sequence::type_id::create("overflow_seq");
    overflow_seq.write_count = 500;  // Reduced for faster simulation
    overflow_seq.enable_reset = 0;   // Don't reset again
    overflow_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 3: Underflow test
    `uvm_info("MIXED_TEST", "Phase 4: Starting underflow test", UVM_LOW)
    underflow_seq = underflow_test_sequence::type_id::create("underflow_seq");
    underflow_seq.read_count = 500;  // Reduced for faster simulation
    underflow_seq.enable_reset = 0;  // Don't reset again
    underflow_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait for any remaining operations
    repeat(50) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    `uvm_info("MIXED_TEST", "Mixed operations test suite completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass