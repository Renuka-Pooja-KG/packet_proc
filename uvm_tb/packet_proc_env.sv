class packet_proc_env extends uvm_env;

  packet_proc_agent agent;
  packet_proc_scoreboard scoreboard;
  packet_proc_coverage coverage;

  `uvm_component_utils(packet_proc_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agent = packet_proc_agent::type_id::create("agent", this);
    scoreboard = packet_proc_scoreboard::type_id::create("scoreboard", this);
    coverage = packet_proc_coverage::type_id::create("coverage", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.ap.connect(scoreboard.analysis_export);
    agent.ap.connect(coverage.analysis_export);
  endfunction
endclass 