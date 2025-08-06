class pkt_proc_env extends uvm_env;
  `uvm_component_utils(pkt_proc_env)

  // Single enhanced agent
  pkt_proc_agent m_pkt_proc_agent;
  
  // Enhanced scoreboard
  pkt_proc_scoreboard scoreboard;
  
  // Coverage component
  pkt_proc_coverage coverage;
  
  // Virtual interface
  virtual pkt_proc_interface vif;

  function new(string name = "pkt_proc_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual pkt_proc_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for enhanced environment")
    
    // Create enhanced agent
    m_pkt_proc_agent = pkt_proc_agent::type_id::create("m_pkt_proc_agent", this);
    
    // Create enhanced scoreboard
    scoreboard = pkt_proc_scoreboard::type_id::create("scoreboard", this);
    
    // Create coverage component
    coverage = pkt_proc_coverage::type_id::create("coverage", this);
    
    `uvm_info(get_type_name(), "Pkt_proc Environment build phase completed", UVM_LOW)
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connect enhanced agent to scoreboard
    m_pkt_proc_agent.agent_analysis_port.connect(scoreboard.analysis_export);
    
    // Connect enhanced agent to coverage
    m_pkt_proc_agent.agent_analysis_port.connect(coverage.cov_export);
    
    `uvm_info(get_type_name(), "Pkt_proc Environment connect phase completed", UVM_LOW)
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    `uvm_info(get_type_name(), "Pkt_proc Environment end_of_elaboration phase completed", UVM_LOW)
  endfunction

  function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    `uvm_info(get_type_name(), "Pkt_proc Environment start_of_simulation phase completed", UVM_LOW)
  endfunction

//   task run_phase(uvm_phase phase);
//     super.run_phase(phase);
//     `uvm_info(get_type_name(), "Pkt_proc Environment run phase started", UVM_LOW)
    
//     // Wait for test completion
//     phase.raise_objection(this);
//     @(posedge vif.pck_proc_int_mem_fsm_clk);
//     phase.drop_objection(this);
//   endtask

//   function void extract_phase(uvm_phase phase);
//     super.extract_phase(phase);
//     `uvm_info(get_type_name(), "Enhanced Environment extract phase completed", UVM_LOW)
//   endfunction

//   function void check_phase(uvm_phase phase);
//     super.check_phase(phase);
//     `uvm_info(get_type_name(), "Enhanced Environment check phase completed", UVM_LOW)
//   endfunction

//   function void report_phase(uvm_phase phase);
//     super.report_phase(phase);
//     `uvm_info(get_type_name(), "Enhanced Environment report phase completed", UVM_LOW)
//   endfunction

endclass 