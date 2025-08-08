interface pkt_proc_interface (input logic pck_proc_int_mem_fsm_clk);

  logic pck_proc_int_mem_fsm_rstn; //Asynchronous reset
  logic pck_proc_int_mem_fsm_sw_rstn; //Synchronous reset
  logic empty_de_assert; //Empty de-assert

  logic enq_req; //Enqueue request
  logic in_sop; //Start of packet
  logic [31:0] wr_data_i; //Write data
  logic in_eop; //End of packet

  logic pck_len_valid; //Packet length valid
  logic [11:0] pck_len_i; //Packet length

  logic deq_req; //Dequeue request
  logic out_sop; //Start of packet
  logic [31:0] rd_data_o; //Read data
  logic out_eop; //End of packet

  logic pck_proc_full; //Packet full
  logic pck_proc_empty; //Packet empty

  logic [4:0] pck_proc_almost_full_value; //Packet almost full value
  logic [4:0] pck_proc_almost_empty_value; //Packet almost empty value

  logic pck_proc_almost_full; //Packet almost full
  logic pck_proc_almost_empty; //Packet almost empty

  logic pck_proc_overflow; //Packet overflow
  logic pck_proc_underflow; //Packet underflow

  logic packet_drop; //Packet drop

  logic [13:0] pck_proc_wr_lvl; //Packet write level
  
  //Clocking block to the driver
  //Driving inputs to the DUT at negative edge of the clock as the RTL is written in posedge
  clocking driver_cb @(negedge pck_proc_int_mem_fsm_clk);
    //Driving the inputs to the DUT
    //default input #1 output #1;
    output pck_proc_int_mem_fsm_sw_rstn;
    output empty_de_assert;
    output enq_req;
    output in_sop;
    output wr_data_i;
    output in_eop;
    output pck_len_valid;
    output pck_len_i;
    output deq_req;
    output pck_proc_almost_full_value;
    output pck_proc_almost_empty_value;

    input out_sop;
    input rd_data_o;
    input out_eop;
    input pck_proc_full;
    input pck_proc_empty;
    input pck_proc_almost_full;
    input pck_proc_almost_empty;
    input pck_proc_overflow;
    input pck_proc_underflow;
    input packet_drop;
    input pck_proc_wr_lvl;
  endclocking

  //Clocking block to the monitor
  //Monitoring the outputs from the DUT at positive edge of the clock as the RTL is written in posedge
  clocking monitor_cb @(posedge pck_proc_int_mem_fsm_clk);
    //Monitoring the outputs from the DUT
    default input #0 output #0;
    input out_sop;
    input rd_data_o;
    input out_eop;
    input pck_proc_overflow;
    input pck_proc_underflow;
    input packet_drop;
    input pck_proc_wr_lvl;

    //Monitoring the inputs to the DUT 
    input pck_proc_int_mem_fsm_sw_rstn;
    input empty_de_assert;
    input enq_req;
    input in_sop;
    input wr_data_i;
    input in_eop;
    input pck_len_valid;
    input pck_len_i;
    input deq_req;
    input pck_proc_almost_full_value;
    input pck_proc_almost_empty_value;
    
  endclocking

  //Modport to the driver
  modport driver_mp (clocking driver_cb, output pck_proc_int_mem_fsm_rstn);

  //Modport to the monitor
  modport monitor_mp (clocking monitor_cb, input pck_proc_int_mem_fsm_rstn, 
                     input pck_proc_full, input pck_proc_empty, 
                     input pck_proc_almost_full, input pck_proc_almost_empty);

endinterface