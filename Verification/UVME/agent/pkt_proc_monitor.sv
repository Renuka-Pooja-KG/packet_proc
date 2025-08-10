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
      // Wait for clock edge to synchronize, then capture immediately
      // Keep at posedge to properly capture RTL outputs
      @(posedge vif.pck_proc_int_mem_fsm_clk);
      
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
      tr.out_sop = vif.monitor_cb.out_sop;
      tr.rd_data_o = vif.monitor_cb.rd_data_o;
      tr.out_eop = vif.monitor_cb.out_eop;
      
      // Capture status signals - these are combinational, so capture directly from interface
      tr.pck_proc_full = vif.pck_proc_full;
      tr.pck_proc_empty = vif.pck_proc_empty;
      tr.pck_proc_almost_full = vif.pck_proc_almost_full;
      tr.pck_proc_almost_empty = vif.pck_proc_almost_empty;
      tr.pck_proc_overflow = vif.monitor_cb.pck_proc_overflow;
      tr.pck_proc_underflow = vif.monitor_cb.pck_proc_underflow;
      tr.packet_drop = vif.monitor_cb.packet_drop;
      tr.pck_proc_wr_lvl = vif.monitor_cb.pck_proc_wr_lvl;
      
      // Debug: Show captured values
      `uvm_info("MONITOR_DEBUG", $sformatf("Captured at %0t: pck_proc_empty=%0b, pck_proc_almost_empty=%0b, pck_proc_wr_lvl=%0d", 
               $time, tr.pck_proc_empty, tr.pck_proc_almost_empty, tr.pck_proc_wr_lvl), UVM_LOW)
      
      // Determine operation type based on captured signals
      //determine_operation_type();
      
      `uvm_info(get_type_name(), $sformatf("Pkt_proc Monitor captured: %s", tr.sprint()), UVM_LOW)
      analysis_port.write(tr);
    end
  endtask

//   function void determine_operation_type();
//     // Determine operation type based on captured signals
//     if (tr.enq_req && !tr.deq_req) begin
//       tr.op_type = enhanced_pkt_proc_seq_item::WRITE_OP;
//     end else if (!tr.enq_req && tr.deq_req) begin
//       tr.op_type = enhanced_pkt_proc_seq_item::READ_OP;
//     end else if (tr.enq_req && tr.deq_req) begin
//       tr.op_type = enhanced_pkt_proc_seq_item::BOTH_OP;
//     end else begin
//       // No operation - could be idle or configuration
//       tr.op_type = enhanced_pkt_proc_seq_item::READ_OP; // Default
//     end
//   endfunction

endclass 