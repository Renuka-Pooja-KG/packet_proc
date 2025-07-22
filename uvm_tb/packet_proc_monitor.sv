class packet_proc_monitor extends uvm_monitor;
  virtual packet_proc_if vif;
  uvm_analysis_port #(packet_proc_transaction) ap;

  `uvm_component_utils(packet_proc_monitor)

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual packet_proc_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface not set for monitor")
  endfunction

  task run_phase(uvm_phase phase);
    packet_proc_transaction tr;
    forever begin
      @(vif.mon_cb);
      tr = packet_proc_transaction::type_id::create("tr", this);

      // Sample all inputs from mon_cb clocking block
      tr.empty_de_assert                = vif.mon_cb.empty_de_assert;
      tr.enq_req                        = vif.mon_cb.enq_req;
      tr.in_sop                         = vif.mon_cb.in_sop;
      tr.wr_data_i                      = vif.mon_cb.wr_data_i;
      tr.in_eop                         = vif.mon_cb.in_eop;
      tr.pck_len_valid                  = vif.mon_cb.pck_len_valid;
      tr.pck_len_i                      = vif.mon_cb.pck_len_i;
      tr.deq_req                        = vif.mon_cb.deq_req;
      tr.pck_proc_almost_full_value     = vif.mon_cb.pck_proc_almost_full_value;
      tr.pck_proc_almost_empty_value    = vif.mon_cb.pck_proc_almost_empty_value;

      // Sample all outputs from mon_cb clocking block
      tr.out_sop                        = vif.mon_cb.out_sop;
      tr.rd_data_o                      = vif.mon_cb.rd_data_o;
      tr.out_eop                        = vif.mon_cb.out_eop;
      tr.pck_proc_full                  = vif.mon_cb.pck_proc_full;
      tr.pck_proc_empty                 = vif.mon_cb.pck_proc_empty;
      tr.pck_proc_almost_full           = vif.mon_cb.pck_proc_almost_full;
      tr.pck_proc_almost_empty          = vif.mon_cb.pck_proc_almost_empty;
      tr.pck_proc_wr_lvl                = vif.mon_cb.pck_proc_wr_lvl;
      tr.pck_proc_overflow              = vif.mon_cb.pck_proc_overflow;
      tr.pck_proc_underflow             = vif.mon_cb.pck_proc_underflow;
      tr.packet_drop                    = vif.mon_cb.packet_drop;

      ap.write(tr);
    end
  endtask
endclass 