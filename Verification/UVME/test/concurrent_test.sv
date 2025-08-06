// Concurrent Test for Packet Processor
// Tests concurrent read/write operations with proper reset initialization

class concurrent_test extends uvm_test;
  `uvm_component_utils(concurrent_test)

  pkt_proc_env env;
  
  // Concurrent test sequences
  concurrent_rw_sequence concurrent_seq;
  packet_write_sequence packet_write_seq;
  continuous_read_sequence continuous_read_seq;
  
  // Reset initialization sequence
  reset_initialization_sequence reset_init_seq;

  function new(string name = "concurrent_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pkt_proc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("CONCURRENT_TEST", "Starting concurrent operations test suite", UVM_LOW)
    
    // Initialize DUT with reset
    `uvm_info("CONCURRENT_TEST", "Phase 1: Initializing DUT with reset", UVM_LOW)
    reset_init_seq = reset_initialization_sequence::type_id::create("reset_init_seq");
    reset_init_seq.reset_cycles = 5;  // 5 clock cycles of reset
    reset_init_seq.idle_cycles = 3;   // 3 idle cycles after reset
    reset_init_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between initialization and tests
    repeat(10) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 1: Built-in concurrent sequence
    `uvm_info("CONCURRENT_TEST", "Phase 2: Starting built-in concurrent sequence", UVM_LOW)
    concurrent_seq = concurrent_rw_sequence::type_id::create("concurrent_seq");
    concurrent_seq.write_count = 20;
    concurrent_seq.read_count = 30;
    concurrent_seq.enable_reset = 0;  // Don't reset again, already done
    concurrent_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 2: Separate sequences with fork/join
    `uvm_info("CONCURRENT_TEST", "Phase 3: Starting separate concurrent sequences", UVM_LOW)
    packet_write_seq = packet_write_sequence::type_id::create("packet_write_seq");
    continuous_read_seq = continuous_read_sequence::type_id::create("continuous_read_seq");
    
    // Configure sequences
    packet_write_seq.packet_count = 10;
    packet_write_seq.min_packet_length = 4;
    packet_write_seq.max_packet_length = 12;
    packet_write_seq.enable_reset = 0;  // Don't reset again
    
    continuous_read_seq.read_count = 80;
    continuous_read_seq.enable_reset = 0;  // Don't reset again
    
    // Run both sequences concurrently using fork/join
    fork
      packet_write_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
      continuous_read_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    join
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 3: High-load concurrent test
    `uvm_info("CONCURRENT_TEST", "Phase 4: Starting high-load concurrent test", UVM_LOW)
    concurrent_seq = concurrent_rw_sequence::type_id::create("concurrent_seq_high_load");
    concurrent_seq.write_count = 50;
    concurrent_seq.read_count = 60;
    concurrent_seq.enable_reset = 0;  // Don't reset again
    concurrent_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait for any remaining operations
    repeat(50) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    `uvm_info("CONCURRENT_TEST", "Concurrent operations test suite completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass