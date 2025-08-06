class pkt_proc_agent extends uvm_agent;
  `uvm_component_utils(pkt_proc_agent)

  pkt_proc_driver m_pkt_proc_driver;
  pkt_proc_sequencer m_pkt_proc_sequencer;
  pkt_proc_monitor m_pkt_proc_monitor;

  uvm_analysis_port #(pkt_proc_seq_item) agent_analysis_port;

  function new(string name = "pkt_proc_agent", uvm_component parent = null);
    super.new(name, parent);
    agent_analysis_port = new("agent_analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(is_active == UVM_ACTIVE) begin
        m_pkt_proc_sequencer = pkt_proc_sequencer::type_id::create("pkt_proc_sequencer", this);
        m_pkt_proc_driver = pkt_proc_driver::type_id::create("pkt_proc_driver", this);
    end
    m_pkt_proc_monitor = pkt_proc_monitor::type_id::create("pkt_proc_monitor", this);
    `uvm_info(get_type_name(), "Enhanced Agent build phase completed", UVM_LOW)
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(is_active == UVM_ACTIVE) begin
        m_pkt_proc_driver.seq_item_port.connect(m_pkt_proc_sequencer.seq_item_export);
    end
    // Connect the analysis port of the monitor to the agent analysis port
    m_pkt_proc_monitor.analysis_port.connect(agent_analysis_port);
    `uvm_info(get_type_name(), "Pkt_proc Agent connect phase completed", UVM_LOW)
  endfunction

endclass 