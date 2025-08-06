// Comprehensive Test for Packet Processor
// Tests all major functionality with proper reset initialization

class comprehensive_test extends uvm_test;
  `uvm_component_utils(comprehensive_test)

  pkt_proc_env env;
  
  // All test sequences
  write_only_sequence write_seq;
  read_only_sequence read_seq;
  packet_write_sequence packet_write_seq;
  continuous_read_sequence continuous_read_seq;
  concurrent_rw_sequence concurrent_seq;
  mixed_operations_sequence mixed_seq;
  overflow_test_sequence overflow_seq;
  underflow_test_sequence underflow_seq;
  
  // Reset sequences
  async_reset_test_sequence async_reset_seq;
  sync_reset_test_sequence sync_reset_seq;
  
  // Reset initialization sequence
  reset_initialization_sequence reset_init_seq;

  function new(string name = "comprehensive_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pkt_proc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("COMPREHENSIVE_TEST", "Starting comprehensive test suite", UVM_LOW)
    
    // Initialize DUT with reset
    `uvm_info("COMPREHENSIVE_TEST", "Phase 1: Initializing DUT with reset", UVM_LOW)
    reset_init_seq = reset_initialization_sequence::type_id::create("reset_init_seq");
    reset_init_seq.reset_cycles = 5;  // 5 clock cycles of reset
    reset_init_seq.idle_cycles = 3;   // 3 idle cycles after reset
    reset_init_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between initialization and tests
    repeat(10) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 1: Basic write operations
    `uvm_info("COMPREHENSIVE_TEST", "Phase 2: Basic write operations", UVM_LOW)
    write_seq = write_only_sequence::type_id::create("write_seq");
    write_seq.write_count = 30;
    write_seq.enable_reset = 0;
    write_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 2: Basic read operations
    `uvm_info("COMPREHENSIVE_TEST", "Phase 3: Basic read operations", UVM_LOW)
    read_seq = read_only_sequence::type_id::create("read_seq");
    read_seq.read_count = 30;
    read_seq.enable_reset = 0;
    read_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 3: Packet write operations
    `uvm_info("COMPREHENSIVE_TEST", "Phase 4: Packet write operations", UVM_LOW)
    packet_write_seq = packet_write_sequence::type_id::create("packet_write_seq");
    packet_write_seq.packet_count = 8;
    packet_write_seq.min_packet_length = 4;
    packet_write_seq.max_packet_length = 12;
    packet_write_seq.enable_reset = 0;
    packet_write_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 4: Concurrent operations
    `uvm_info("COMPREHENSIVE_TEST", "Phase 5: Concurrent operations", UVM_LOW)
    concurrent_seq = concurrent_rw_sequence::type_id::create("concurrent_seq");
    concurrent_seq.write_count = 25;
    concurrent_seq.read_count = 35;
    concurrent_seq.enable_reset = 0;
    concurrent_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 5: Mixed operations
    `uvm_info("COMPREHENSIVE_TEST", "Phase 6: Mixed operations", UVM_LOW)
    mixed_seq = mixed_operations_sequence::type_id::create("mixed_seq");
    mixed_seq.transaction_count = 80;
    mixed_seq.enable_reset = 0;
    mixed_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 6: Async reset test
    `uvm_info("COMPREHENSIVE_TEST", "Phase 7: Async reset test", UVM_LOW)
    async_reset_seq = async_reset_test_sequence::type_id::create("async_reset_seq");
    async_reset_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 7: Sync reset test
    `uvm_info("COMPREHENSIVE_TEST", "Phase 8: Sync reset test", UVM_LOW)
    sync_reset_seq = sync_reset_test_sequence::type_id::create("sync_reset_seq");
    sync_reset_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 8: Overflow test
    `uvm_info("COMPREHENSIVE_TEST", "Phase 9: Overflow test", UVM_LOW)
    overflow_seq = overflow_test_sequence::type_id::create("overflow_seq");
    overflow_seq.write_count = 300;  // Reduced for faster simulation
    overflow_seq.enable_reset = 0;
    overflow_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    repeat(15) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 9: Underflow test
    `uvm_info("COMPREHENSIVE_TEST", "Phase 10: Underflow test", UVM_LOW)
    underflow_seq = underflow_test_sequence::type_id::create("underflow_seq");
    underflow_seq.read_count = 300;  // Reduced for faster simulation
    underflow_seq.enable_reset = 0;
    underflow_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait for any remaining operations
    repeat(50) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    `uvm_info("COMPREHENSIVE_TEST", "Comprehensive test suite completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass