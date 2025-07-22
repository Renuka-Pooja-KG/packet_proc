class packet_proc_driver extends uvm_driver #(packet_proc_transaction);
  virtual packet_proc_if vif;

  `uvm_component_utils(packet_proc_driver)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual packet_proc_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for driver")
  endfunction

  task run_phase(uvm_phase phase);
    packet_proc_transaction tr;
    forever begin
      seq_item_port.get_next_item(tr);
      // Drive inputs
      vif.drv_cb.in_sop <= tr.in_sop;
      vif.drv_cb.in_eop <= tr.in_eop;
      vif.drv_cb.wr_data_i <= tr.wr_data_i;
      vif.drv_cb.pck_len_valid <= tr.pck_len_valid;
      vif.drv_cb.pck_len_i <= tr.pck_len_i;
      vif.drv_cb.enq_req <= tr.enq_req;
      vif.drv_cb.deq_req <= tr.deq_req;
      vif.drv_cb.empty_de_assert <= tr.empty_de_assert;
      vif.drv_cb.pck_proc_almost_full_value <= tr.pck_proc_almost_full_value;
      vif.drv_cb.pck_proc_almost_empty_value <= tr.pck_proc_almost_empty_value;
      @(vif.drv_cb);
      seq_item_port.item_done();
    end
  endtask
endclass 