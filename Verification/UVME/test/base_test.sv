// Basic test for Packet Processor
// Tests basic write and read operations with proper reset initialization

class basic_test extends uvm_test;
  `uvm_component_utils(basic_test)

  pkt_proc_env env;
  
  // Basic test sequences
  write_only_sequence write_seq;
  read_only_sequence read_seq;
  
  // Reset initialization sequence
  reset_initialization_sequence reset_init_seq;

  function new(string name = "basic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = pkt_proc_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    `uvm_info("BASIC_TEST", "Starting basic operations test suite", UVM_LOW)
    
    // Initialize DUT with reset
    `uvm_info("BASIC_TEST", "Phase 1: Initializing DUT with reset", UVM_LOW)
    reset_init_seq = reset_initialization_sequence::type_id::create("reset_init_seq");
    reset_init_seq.reset_cycles = 5;  // 5 clock cycles of reset
    reset_init_seq.idle_cycles = 3;   // 3 idle cycles after reset
    reset_init_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between initialization and tests
    repeat(10) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 1: Write-only sequence
    `uvm_info("BASIC_TEST", "Phase 2: Starting write-only test", UVM_LOW)
    write_seq = write_only_sequence::type_id::create("write_seq");
    write_seq.write_count = 20;
    write_seq.enable_reset = 0;  // Don't reset again, already done
    write_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait between tests
    repeat(20) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    // Test 2: Read-only sequence
    `uvm_info("BASIC_TEST", "Phase 3: Starting read-only test", UVM_LOW)
    read_seq = read_only_sequence::type_id::create("read_seq");
    read_seq.read_count = 20;
    read_seq.enable_reset = 0;  // Don't reset again, already done
    read_seq.start(env.pkt_proc_agent.pkt_proc_sequencer);
    
    // Wait for any remaining operations
    repeat(30) @(posedge env.vif.pck_proc_int_mem_fsm_clk);
    
    `uvm_info("BASIC_TEST", "Basic operations test suite completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask

endclass