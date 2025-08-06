// Reset Test for Packet Processor
// Tests various reset scenarios with write/read operations

class reset_test extends uvm_test;
  `uvm_component_utils(reset_test)

  pkt_proc_env env;
  
  // Reset test sequences
  async_reset_test_sequence async_reset_seq;
  sync_reset_test_sequence sync_reset_seq;
  dual_reset_test_sequence dual_reset_seq;
  reset_during_packet_sequence reset_packet_seq;
  reset_during_read_sequence reset_read_seq;
  
  // Reset initialization sequence
  reset_initialization_sequence reset_init_seq;

  function new(string name = "reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pkt_proc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("RESET_TEST", "Starting reset test suite", UVM_LOW)
    
    // Initialize DUT with reset before starting reset tests
    `uvm_info("RESET_TEST", "Phase 0: Initializing DUT with reset", UVM_LOW)
    reset_init_seq = reset_initialization_sequence::type_id::create("reset_init_seq");
    reset_init_seq.reset_cycles = 5;  // 5 clock cycles of reset
    reset_init_seq.idle_cycles = 3;   // 3 idle cycles after reset
    reset_init_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between initialization and tests
    repeat(10) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 1: Async reset test
    `uvm_info("RESET_TEST", "Phase 1: Async reset test", UVM_LOW)
    async_reset_seq = async_reset_test_sequence::type_id::create("async_reset_seq");
    async_reset_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 2: Sync reset test
    `uvm_info("RESET_TEST", "Phase 2: Sync reset test", UVM_LOW)
    sync_reset_seq = sync_reset_test_sequence::type_id::create("sync_reset_seq");
    sync_reset_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 3: Dual reset test
    `uvm_info("RESET_TEST", "Phase 3: Dual reset test", UVM_LOW)
    dual_reset_seq = dual_reset_test_sequence::type_id::create("dual_reset_seq");
    dual_reset_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 4: Reset during packet transmission
    `uvm_info("RESET_TEST", "Phase 4: Reset during packet transmission", UVM_LOW)
    reset_packet_seq = reset_during_packet_sequence::type_id::create("reset_packet_seq");
    reset_packet_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 5: Reset during read operations
    `uvm_info("RESET_TEST", "Phase 5: Reset during read operations", UVM_LOW)
    reset_read_seq = reset_during_read_sequence::type_id::create("reset_read_seq");
    reset_read_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait for final operations to complete
    repeat(50) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    `uvm_info("RESET_TEST", "Reset test suite completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass