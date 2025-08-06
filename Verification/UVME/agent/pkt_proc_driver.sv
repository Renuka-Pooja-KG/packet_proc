class pkt_proc_driver extends uvm_driver #(pkt_proc_seq_item);
  virtual pkt_proc_interface vif;

  `uvm_component_utils(pkt_proc_driver)

  function new(string name = "pkt_proc_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pkt_proc_interface)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for pkt_proc driver")
    
    `uvm_info("PKT_PROC_DRV", "Pkt_proc Driver build phase completed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    pkt_proc_seq_item tr;
    forever begin
      seq_item_port.get_next_item(tr);
      
      // Drive all inputs to the DUT based on operation type
      // Asynchronous reset (always driven)
      vif.pck_proc_int_mem_fsm_rstn <= tr.pck_proc_int_mem_fsm_rstn;
      
      // Synchronous reset (always driven)
      vif.driver_cb.pck_proc_int_mem_fsm_sw_rstn <= tr.pck_proc_int_mem_fsm_sw_rstn;
      
      // Shared signals (always driven)
      vif.driver_cb.empty_de_assert <= tr.empty_de_assert;
      vif.driver_cb.pck_proc_almost_full_value <= tr.pck_proc_almost_full_value;
      vif.driver_cb.pck_proc_almost_empty_value <= tr.pck_proc_almost_empty_value;
      
      // Write operation signals
      vif.driver_cb.enq_req <= tr.enq_req;
      vif.driver_cb.in_sop <= tr.in_sop;
      vif.driver_cb.in_eop <= tr.in_eop;
      vif.driver_cb.wr_data_i <= tr.wr_data_i;
      vif.driver_cb.pck_len_valid <= tr.pck_len_valid;
      vif.driver_cb.pck_len_i <= tr.pck_len_i;
      
      // Read operation signals
      vif.driver_cb.deq_req <= tr.deq_req;
      
      @(vif.driver_cb);
      
      `uvm_info("PKT_PROC_DRV", $sformatf("Drove pkt_proc transaction: %s", tr.convert2string()), UVM_LOW)
      
      seq_item_port.item_done();
    end
  endtask
endclass 