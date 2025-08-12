class pkt_proc_monitor extends uvm_monitor;
  `uvm_component_utils(pkt_proc_monitor)

  uvm_analysis_port #(pkt_proc_seq_item) analysis_port;
  virtual pkt_proc_interface vif;
  pkt_proc_seq_item tr;

  function new(string name = "pkt_proc_monitor", uvm_component parent = null);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pkt_proc_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for pkt_proc monitor")
  endfunction

  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    tr = pkt_proc_seq_item::type_id::create("tr");
    `uvm_info(get_type_name(), "Pkt_proc Monitor run phase started", UVM_LOW)
    
    forever begin
      // Wait for EITHER clock edge OR ANY combinational output change
      // This ensures we capture all combinational signals immediately when they change
      @(posedge vif.pck_proc_int_mem_fsm_clk or vif.packet_drop);
      
      // Determine what triggered the sampling for better debugging
      if ($rose(vif.packet_drop)) begin
        `uvm_info("COMBINATIONAL_TRIGGER", $sformatf("Time=%0t: packet_drop=1 (combinational)", $time), UVM_LOW)
      end else if ($fell(vif.packet_drop)) begin
        `uvm_info("COMBINATIONAL_TRIGGER", $sformatf("Time=%0t: packet_drop=0 (combinational)", $time), UVM_LOW)
      end else begin
        `uvm_info("CLOCK_TRIGGER", $sformatf("Time=%0t: Sampling triggered by posedge clock", $time), UVM_LOW)
      end
      
        sample_all_signals();
        analysis_port.write(tr);
    end
  endtask

  function void sample_all_signals();
    // Capture reset signals
    tr.pck_proc_int_mem_fsm_rstn = vif.pck_proc_int_mem_fsm_rstn;
    tr.pck_proc_int_mem_fsm_sw_rstn = vif.monitor_cb.pck_proc_int_mem_fsm_sw_rstn;
    
    // Capture shared signals
    tr.empty_de_assert = vif.monitor_cb.empty_de_assert;
    tr.pck_proc_almost_full_value = vif.monitor_cb.pck_proc_almost_full_value;
    tr.pck_proc_almost_empty_value = vif.monitor_cb.pck_proc_almost_empty_value;
    
    // Capture write operation signals - Sample from raw interface signals (real-time values)
    tr.enq_req = vif.enq_req;           // Raw signal, not clocking block
    tr.in_sop = vif.in_sop;             // Raw signal, not clocking block
    tr.in_eop = vif.in_eop;             // Raw signal, not clocking block
    tr.wr_data_i = vif.wr_data_i;       // Raw signal, not clocking block
    tr.pck_len_valid = vif.pck_len_valid; // Raw signal, not clocking block
    tr.pck_len_i = vif.pck_len_i;       // Raw signal, not clocking block
    
    // Capture read operation signals - Sample from raw interface signals
    tr.deq_req = vif.deq_req;           // Raw signal, not clocking block
    
    // Capture output signals - These come from RTL, so keep using monitor_cb
    tr.out_sop = vif.out_sop;
    tr.rd_data_o = vif.monitor_cb.rd_data_o;
    tr.out_eop = vif.out_eop;
    
    // Capture ALL combinational status signals from raw interface (immediate capture)
    tr.pck_proc_full = vif.pck_proc_full;           // ← COMBINATIONAL
    tr.pck_proc_empty = vif.pck_proc_empty;         // ← COMBINATIONAL  
    tr.pck_proc_almost_full = vif.pck_proc_almost_full;     // ← COMBINATIONAL
    tr.pck_proc_almost_empty = vif.pck_proc_almost_empty;   // ← COMBINATIONAL
    tr.pck_proc_overflow = vif.monitor_cb.pck_proc_overflow;
    tr.pck_proc_underflow = vif.monitor_cb.pck_proc_underflow;
    tr.packet_drop = vif.packet_drop;               // ← COMBINATIONAL
    tr.pck_proc_wr_lvl = vif.pck_proc_wr_lvl;      // ← COMBINATIONAL
    
    // Enhanced debug: Show ALL combinational outputs with detailed information
    `uvm_info("COMBINATIONAL_DEBUG", $sformatf("Time=%0t: Combinational outputs - full=%0b, empty=%0b, almost_full=%0b, almost_empty=%0b, packet_drop=%0b, wr_lvl=%0d", 
             $time, tr.pck_proc_full, tr.pck_proc_empty, tr.pck_proc_almost_full, tr.pck_proc_almost_empty, tr.packet_drop, tr.pck_proc_wr_lvl), UVM_LOW)
    
    // Additional debug: Show captured values for verification
    `uvm_info("MONITOR_DEBUG", $sformatf("Captured at %0t: pck_proc_empty=%0b, pck_proc_almost_empty=%0b, pck_proc_wr_lvl=%0d, packet_drop=%0b", 
             $time, tr.pck_proc_empty, tr.pck_proc_almost_empty, tr.pck_proc_wr_lvl, tr.packet_drop), UVM_LOW)
    
    `uvm_info(get_type_name(), $sformatf("Pkt_proc Monitor captured: %s", tr.sprint()), UVM_LOW)
  endfunction

endclass 