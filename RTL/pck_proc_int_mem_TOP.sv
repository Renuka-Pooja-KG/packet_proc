//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////Copyright © 2022 PravegaSemi PVT LTD., All rights reserved//////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                              //
//All works published under Zilla_Gen_0 by PravegaSemi PVT LTD is copyrighted by the Association and ownership  // 
//of all right, title and interest in and to the works remains with PravegaSemi PVT LTD. No works or documents  //
//published under Zilla_Gen_0 by PravegaSemi PVT LTD may be reproduced,transmitted or copied without the express//
//written permission of PravegaSemi PVT LTD will be considered as a violations of Copyright Act and it may lead //
//to legal action.                                                                                         //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////
* File Name : pck_proc_int_mem_fsm.sv

* Purpose :

* Creation Date : 05-04-2023

* Last Modified : Fri 17 Feb 2023 03:58:06 AM IST

* Created By :  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
//`timescale 1ns/1ps
module pck_proc_int_mem_fsm
                  #(
                    parameter   DATA_WIDTH      = 32             ,
                                ADDR_WIDTH      = 14             ,
                                DEPTH           = 1<<ADDR_WIDTH  ,                                
                                PCK_LEN         = 12             
                                   
                   )
                   (
                    //  INPUTS
                    input   logic                       pck_proc_int_mem_fsm_clk        ,
                    input   logic                       pck_proc_int_mem_fsm_rstn       ,
                    input   logic                       pck_proc_int_mem_fsm_sw_rstn    ,

                    input   logic                       empty_de_assert                 ,
    
                    input   logic                       enq_req                         ,

                    input   logic                       in_sop                          ,
                    input   logic  [DATA_WIDTH-1:0]     wr_data_i                       ,
                    input   logic                       in_eop                          ,

                    input   logic                       pck_len_valid                   ,                    
                    input   logic  [PCK_LEN-1:0]        pck_len_i                       , 

                    input   logic                       deq_req                         ,

                    //  OUTPUTS
                    output  logic                       out_sop                         ,
                    output  logic  [DATA_WIDTH-1:0]     rd_data_o                       ,
                    output  logic                       out_eop                         ,

                    output  logic                       pck_proc_full                   ,
                    output  logic                       pck_proc_empty                  ,

                    input   logic  [4:0]                pck_proc_almost_full_value      ,
                    input   logic  [4:0]                pck_proc_almost_empty_value     ,

                    output  logic                       pck_proc_almost_full            ,
                    output  logic                       pck_proc_almost_empty           ,

                    output  logic  [ADDR_WIDTH:0]       pck_proc_wr_lvl                 ,

                    output  logic                       pck_proc_overflow               ,
                    output  logic                       pck_proc_underflow              , 

                    output  logic                       packet_drop                     
                   );

                   //       WRITE FSM STATES
                   localparam   IDLE_W        =  2'd0   ;
                   localparam   WRITE_HEADER  =  2'd1   ;
                   localparam   WRITE_DATA    =  2'd2   ;
                   localparam   ERROR         =  2'd3   ;

                   //       READ FSM STATES
                   localparam   IDLE_R        =  2'd0   ;
                   localparam   READ_HEADER   =  2'd1   ;
                   localparam   READ_DATA     =  2'd2   ;

                   //       INTERNAL DECLERATIONS FOR WRITE AND READ FSM's
                   logic    [1:0]   present_state_w             ;
                   logic    [1:0]   next_state_w                ;

                   logic    [1:0]   present_state_r             ;
                   logic    [1:0]   next_state_r                ;
                   
                   logic            in_sop_r                    ;
                   logic            in_sop_r1                   ;
                   logic            in_sop_r2                   ;

                   logic            in_eop_r                    ;
                   logic            in_eop_r1                   ;
                   logic            in_eop_r2                   ;

                   logic            enq_req_r                   ;
                   logic            enq_req_r1                  ;

                   logic    [DATA_WIDTH-1:0] wr_data_r          ;
                   logic    [DATA_WIDTH-1:0] wr_data_r1         ;                   

                   logic            next_data_ready             ;
                   logic            next_data_nt_ready          ;

                   logic                     wr_en              ;
                   logic    [DATA_WIDTH-1:0] wr_data            ;

                   logic                     rd_en              ;
                   logic    [DATA_WIDTH-1:0] rd_data_out_w      ;

                   logic    [PCK_LEN-1:0]    count_r            ;
                   logic    [PCK_LEN-1:0]    pck_len_r          ;
                   logic    [PCK_LEN-1:0]    pck_len_reg        ;

                   logic    [PCK_LEN-1:0]    count_w            ;
                   logic    [PCK_LEN-1:0]    count_w1           ;

                   logic    [PCK_LEN-1:0]    pck_len_r1         ;
                   logic    [PCK_LEN-1:0]    pck_len_r2         ;

                   logic    [PCK_LEN-1:0]    pck_len_w1         ;
                   
                   logic                     pck_len_wr_en      ;                   
                   logic    [PCK_LEN-1:0]    pck_len_wr_data    ;

                   logic                     pck_len_rd_en      ;

                   logic    [PCK_LEN-1:0]    pck_len_rd         ;

                   logic                     pck_valid          ; 
                   logic                     pck_invalid        ;

                   logic    [PCK_LEN-1:0]    packet_length      ;

                   logic                     deq_req_r          ;

                   logic                     pck_len_valid_r1   ;
                   logic                     pck_len_valid_r    ;
                                   
                   logic    [PCK_LEN-1:0]    pck_len_i_r1       ;
                   logic    [PCK_LEN-1:0]    pck_len_i_r        ;
                  
                   logic                     invalid_1 ;
                   logic                     invalid_2 ;
                   logic                     invalid_3 ;
                   logic                     invalid_4 ;
                   logic                     invalid_ ;
                   
                   logic                     valid_1   ;
                   logic                     valid_2   ;
                                      //       REGISTERING THE INPUTS
                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(!pck_proc_int_mem_fsm_rstn)
                       begin
                       in_sop_r     <=     1'b0                 ;
                       in_sop_r1    <=     1'b0                 ;
                       in_sop_r2    <=     1'b0                 ;

                       in_eop_r     <=     1'b0                 ; 
                       in_eop_r1    <=     1'b0                 ;
                       in_eop_r2    <=     1'b0                 ;

                       pck_len_valid_r1 <= 1'b0                 ;
                       pck_len_valid_r  <= 1'b0                 ;
                                       
                       pck_len_i_r1 <=     {PCK_LEN{1'b0}}      ;
                       pck_len_i_r  <=     {PCK_LEN{1'b0}}      ;

                       wr_data_r    <=     {DATA_WIDTH{1'b0}}   ;
                       wr_data_r1   <=     {DATA_WIDTH{1'b0}}   ;

                       enq_req_r    <=     1'b0                 ;
                       enq_req_r1   <=     1'b0                 ;

                       count_w1     <=     {PCK_LEN{1'b0}}      ;

                       pck_len_w1   <=     {PCK_LEN{1'b0}}      ;
                       deq_req_r    <=     1'b0                 ;

                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       in_sop_r     <=     1'b0                 ;
                       in_sop_r1    <=     1'b0                 ;
                       in_sop_r2    <=     1'b0                 ;

                       in_eop_r     <=     1'b0                 ; 
                       in_eop_r1    <=     1'b0                 ;
                       in_eop_r2    <=     1'b0                 ;

                       pck_len_valid_r1 <= 1'b0                 ;
                       pck_len_valid_r  <= 1'b0                 ;
                                       
                       pck_len_i_r1 <=     {PCK_LEN{1'b0}}      ;
                       pck_len_i_r  <=     {PCK_LEN{1'b0}}      ;

                       wr_data_r    <=     {DATA_WIDTH{1'b0}}   ;
                       wr_data_r1   <=     {DATA_WIDTH{1'b0}}   ;

                       enq_req_r    <=     1'b0                 ;
                       enq_req_r1   <=     1'b0                 ;

                       count_w1     <=     {PCK_LEN{1'b0}}      ;

                       pck_len_w1   <=     {PCK_LEN{1'b0}}      ;
                       deq_req_r    <=     1'b0                 ;

                       end    
                   else 
                       begin
                       in_sop_r1     <=    in_sop                ;
                       in_sop_r      <=    in_sop_r1             ;
                       in_sop_r2     <=    in_sop_r              ;

                       pck_len_valid_r1<= pck_len_valid          ;
                       pck_len_valid_r <= pck_len_valid_r1       ;

                       pck_len_i_r1 <=    pck_len_i              ;
                       pck_len_i_r  <=    pck_len_i_r1           ;

                       in_eop_r1    <=     in_eop                ;
                       in_eop_r     <=     in_eop_r1             ;      
                       in_eop_r2    <=     in_eop_r              ;
                         
                       wr_data_r1   <=     wr_data_i             ;
                       wr_data_r    <=     wr_data_r1            ;

                       enq_req_r    <=     enq_req               ;
                       enq_req_r1   <=     enq_req_r             ;

                       count_w1     <=     count_w               ;

                       pck_len_w1   <=     pck_len_i             ;
                       deq_req_r    <=     deq_req               ;

                       end
                       
                   end

                   assign pck_len_r2 = (pck_len_valid_r1) ? pck_len_i_r1 : ((in_sop_r1) ? wr_data_r1[11:0] : packet_length)   ; 

                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(!pck_proc_int_mem_fsm_rstn)
                       begin
                       packet_length <= {PCK_LEN{1'b0}}      ;
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       packet_length <= {PCK_LEN{1'b0}}      ;                       
                       end                   
                   else if(in_eop_r1 || packet_drop)
                       begin
                       packet_length <= {PCK_LEN{1'b0}}         ;
                       end
                   else
                       begin
                       packet_length <= pck_len_r2           ; 
                       end
                   
                   end

                   
                   //       LOGIC FOR COUNTING THE DATA WHILE WRITING TO BUFFER

                   assign valid_1 = (~in_sop      )         ;
                   assign valid_2 = (in_sop_r1 && in_sop_r   )         ;

                   //assign pck_valid 
                   assign pck_valid   = (((present_state_w==WRITE_HEADER) || (present_state_w==WRITE_DATA)) && enq_req_r && (~pck_proc_overflow ))            ;
                   assign pck_invalid = (((in_sop && in_eop) ||/* (in_sop_r && in_sop_r1)||*/ (in_sop && (~in_eop_r1) && (present_state_w==WRITE_DATA)) || ((count_w < pck_len_r2 - 12'd1) && (pck_len_r2 != {PCK_LEN{1'b0}}) && (in_eop_r1)) || ((count_w == pck_len_r2-1'b1 || (pck_len_r2 == {PCK_LEN{1'b0}})) && (~in_eop_r1) && (present_state_w==WRITE_DATA)) || (pck_proc_overflow)) && enq_req)        ;


                   assign invalid_1 =  (in_sop && in_eop)      ;
                   assign invalid_2 =  (in_sop_r && in_sop_r1) ;
                   assign invalid_3 =  (in_sop && (~in_eop_r1) && (present_state_w==WRITE_DATA)) ;
                   assign invalid_4 =  ((count_w < pck_len_r2 - 12'd1) && (pck_len_r2 != {PCK_LEN{1'b0}}) && (in_eop_r1))     ;
                   assign invalid_5 =  ((count_w == pck_len_r2-1'b1 || (pck_len_r2 == {PCK_LEN{1'b0}})) && (~in_eop_r1) && (present_state_w==WRITE_DATA))  ;
                   assign invalid_6 =  (pck_proc_overflow)    ;
        
                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(!pck_proc_int_mem_fsm_rstn)
                       begin
                       count_w   <=   {PCK_LEN{1'b0}}          ;                       
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       count_w   <=   {PCK_LEN{1'b0}}          ;                                              
                       end                   
                   else if((in_eop_r1 && (present_state_w == WRITE_DATA)) || packet_drop)
                       begin
                       count_w   <=  {PCK_LEN{1'b0}}           ;
                       end
                   else if(pck_valid)
                       begin
                       count_w   <=   count_w + 1'b1           ;
                       end
                   else
                       begin
                       count_w   <=  count_w                   ;
                       end

                   end

                   //----------------- WRITING FSM LOGIC --------------------------------------

                   assign   next_data_ready    = (in_sop && enq_req)        ;
                   assign   next_data_nt_ready = (in_eop_r1 && (!in_sop) && (!enq_req))     ;

                   //       PRESENT STATE LOGIC
                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(!pck_proc_int_mem_fsm_rstn)
                       begin
                       present_state_w  <=  IDLE_W          ; 
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       present_state_w  <=  IDLE_W          ; 
                       end    
                   else
                       begin
                       present_state_w  <=  next_state_w    ;
                       end

                   end

                   //       NEXT STATE LOGIC  
                   always_comb
                   begin

                   case(present_state_w)
                   IDLE_W       : 
                                 begin

                                 if(enq_req && (in_sop))
                                     begin
                                     next_state_w = WRITE_HEADER              ;
                                     end
                                 else
                                     begin
                                     next_state_w = IDLE_W                    ;
                                     end

                                 end
                   WRITE_HEADER :
                                 begin

                                 if(in_sop)
                                     begin
                                     next_state_w = WRITE_HEADER              ;
                                     end
                                 else if(pck_invalid)    
                                     begin
                                     next_state_w = ERROR                     ;
                                     end
                                 else 
                                     begin
                                     next_state_w = WRITE_DATA                ;                                 
                                     end
                                 end
                   WRITE_DATA   :
                                 begin
                                
                                 if(next_data_ready)
                                     begin
                                     next_state_w = WRITE_HEADER              ;
                                     end
                                 else if(next_data_nt_ready) 
                                     begin
                                     next_state_w = IDLE_W                    ;
                                     end
                                 else   
                                     begin
                                     next_state_w = WRITE_DATA                ;
                                     end

                                 end
                  

                   default      : next_state_w = IDLE_W                      ;
                   endcase

                   end

                   //       OUTPUT LOGIC
                   always_comb
                   begin
                   packet_drop     = 1'b0                                                    ;
                   pck_len_wr_en   = 1'b0                                                    ;
                   pck_len_wr_data = {PCK_LEN{1'b0}}                                         ;

                   wr_en    = 1'b0                                                           ;
                   wr_data  = {DATA_WIDTH{1'b0}}                                             ;


                   case(present_state_w)
                   IDLE_W       :
                                 begin
                                 wr_en       = 1'b0                                          ;
                                 wr_data     = {DATA_WIDTH{1'b0}}                            ;
                                 packet_drop = 1'b0                                          ;                     
                                 end

                   WRITE_HEADER :
                                 begin

                                 if(pck_invalid)
                                     begin
                                     packet_drop = 1'b1                ;
                                     end
                                 else if(enq_req_r)
                                     begin
                                     wr_en    = 1'b1                                           ;
                                     wr_data  = (in_sop_r1) ? wr_data_r1 : {DATA_WIDTH{1'b0}}   ;
                                     end
                                 else
                                     begin
                                     wr_en    = 1'b0                                          ;
                                     wr_data  = {DATA_WIDTH{1'b0}}                            ;
                                     end

                                 pck_len_wr_en    = 1'b1                  ;
                                 pck_len_wr_data  = pck_len_r2            ;

                                 end

                   WRITE_DATA   :
                                 begin

                                  if(pck_invalid)
                                     begin
                                     packet_drop = 1'b1                ;
                                     end
                                 else if(enq_req_r)
                                     begin
                                     wr_en    = 1'b1                                         ;
                                     wr_data  = wr_data_r1                                   ;                                  
                                     end
                                 else 
                                     begin
                                     wr_en    = 1'b0                                         ;
                                     wr_data  = wr_data_r1                                   ;
                                     end

                                 end

                   ERROR        :
                                 begin
                                 packet_drop  = 1'b1                                        ;
                                 end

                   default      : 
                                 begin
                                 wr_en       = 1'b0                                         ;
                                 wr_data     = {DATA_WIDTH{1'b0}}                           ;
                                 packet_drop = 1'b0                                         ; 
                                 end 
                   endcase

                   end

                   //--------------------------------------------------------------------------

                   //-------------FIFO MEMORY INSTANTIATION------------------------------------
                   int_buffer_top
                       #(
                         .DATA_WIDTH      ( DATA_WIDTH    )         ,  
                         .DEPTH           ( DEPTH         )         , 
                         .ADDR_WIDTH      ( ADDR_WIDTH    )         , 
                         .PCK_LEN         ( PCK_LEN       )                                             
                        )
                   int_buffer_top_inst
                        (   
                         .clk                   ( pck_proc_int_mem_fsm_clk     )     ,           
                                           
                         .hw_rst                ( pck_proc_int_mem_fsm_rstn    )     ,
                         .sw_rst                ( pck_proc_int_mem_fsm_sw_rstn )     ,

                         .empty_de_assert       ( empty_de_assert              )     ,
                                           
                         .wr_en                 ( wr_en                        )     , 
                         .wr_data               ( wr_data                      )     ,

                         .in_eop                ( in_eop_r2                    )     ,
                         .count                 ( count_w1                     )     ,

                         .rd_en                 ( rd_en                        )     ,
                         .rd_data_out           ( rd_data_out_w                )     ,
                                            
                         .almost_full_value     ( pck_proc_almost_full_value   )     ,
                         .almost_empty_value    ( pck_proc_almost_empty_value  )     ,
                                           
                         .buffer_full           ( pck_proc_full                )     ,
                         .buffer_empty          ( pck_proc_empty               )     ,
                                           
                         .almost_full           ( pck_proc_almost_full         )     ,
                         .almost_empty          ( pck_proc_almost_empty        )     ,
                                           
                         .wr_lvl                ( pck_proc_wr_lvl              )     ,
                                           
                         .overflow              (                              )     ,
                         .underflow             (                              )     ,

                         .pck_drop              ( packet_drop                  )     ,
                         .count_w               ( count_w                      )     
                       );  
                   //--------------------------------------------------------------------------

                   //-------------FIFO MEMORY INSTANTIATION------------------------------------
                   pck_len_fifo pck_len_fifo_inst
                        (   
                         .clk                   ( pck_proc_int_mem_fsm_clk     )     ,           
                                           
                         .hw_rst                ( pck_proc_int_mem_fsm_rstn    )     ,
                         .sw_rst                ( pck_proc_int_mem_fsm_sw_rstn )     ,
                                           
                         .wr_en                 ( pck_len_wr_en                )     , 
                         .wr_data               ( pck_len_wr_data              )     ,

                         .rd_en                 ( pck_len_rd_en                )     ,
                         .rd_data_out           ( pck_len_rd                   )     ,
                                            
                         .almost_full_value     (                              )     ,
                         .almost_empty_value    (                              )     ,
                                           
                         .buffer_full           (                              )     ,
                         .buffer_empty          (                              )     ,
                                           
                         .almost_full           (                              )     ,
                         .almost_empty          (                              )     ,
                                           
                         .wr_lvl                (                              )     ,
                                           
                         .overflow              (                              )     ,
                         .underflow             (                              )     ,

                         .pck_drop              ( packet_drop                  )     
                       );  
                   //--------------------------------------------------------------------------

                   //--------------------READING FSM LOGIC-------------------------------------

                   //                    COUNTER LOGIC TO count_r NO OF DATA
                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(!pck_proc_int_mem_fsm_rstn)
                       begin
                       count_r <= {PCK_LEN{1'b0}}                ;
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       count_r <= {PCK_LEN{1'b0}}                ;
                       end    
                   else if(out_eop)
                       begin
                       count_r <= {PCK_LEN{1'b0}}                ;
                       end                       
                   else if((deq_req_r) && ((present_state_r == READ_HEADER) || (present_state_r == READ_DATA)))
                       begin
                       count_r <= count_r + 1'b1                 ;
                       end
                   else
                       begin
                       count_r <= count_r                        ;
                       end

                   end

                   //            LOGIC TO READ PACKET LENGTH FROM THE HEADER WHILE READING

                   assign pck_len_r =  out_sop ? pck_len_rd : pck_len_reg ;

                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(!pck_proc_int_mem_fsm_rstn)
                       begin
                       pck_len_reg  <=  {PCK_LEN{1'b0}}        ;
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       pck_len_reg  <=  {PCK_LEN{1'b0}}        ;  
                       end
                   else if(pck_proc_empty)
                       begin
                       pck_len_reg  <=  {PCK_LEN{1'b0}}        ;
                       end
                   else
                       begin
                       pck_len_reg  <=  pck_len_r              ;
                       end

                   end
                   
                    //       PRESENT STATE LOGIC
                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(!pck_proc_int_mem_fsm_rstn)
                       begin
                       present_state_r  <=  IDLE_R          ; 
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       present_state_r  <=  IDLE_R          ; 
                       end    
                   else
                       begin
                       present_state_r  <=  next_state_r    ;
                       end

                   end

                   //       NEXT STATE LOGIC  
                   always_comb
                   begin

                   case(present_state_r)
                   IDLE_R       : 
                                 begin
                                 
                                 if(deq_req_r && ~pck_proc_empty)
                                     begin
                                     next_state_r = READ_HEADER         ;
                                     end
                                 else
                                     begin
                                     next_state_r = IDLE_R              ;
                                     end

                                 end
                   READ_HEADER  :
                                 begin
                                 next_state_r  = READ_DATA              ;
                                 end
                   READ_DATA    :
                                 begin

                                 if(pck_proc_empty)
                                     begin
                                     next_state_r = IDLE_R              ;
                                     end
                                 else if((count_r == (pck_len_r-1'b1)) && deq_req_r)
                                     begin
                                     next_state_r = READ_HEADER         ;
                                     end                                 
                                 else if((count_r == (pck_len_r-1'b1)) && (~deq_req_r))
                                     begin
                                     next_state_r = IDLE_R              ;
                                     end
                                 else 
                                     begin
                                     next_state_r = READ_DATA           ;
                                     end
                                 end

                   default      : next_state_r = IDLE_R                 ;
                   endcase

                   end

                   //       OUTPUT LOGIC
                   always_comb
                   begin

                   case(present_state_r)
                   IDLE_R       :
                                 begin
                                 out_sop    =  1'b0                    ;   
                                 rd_data_o  =  {DATA_WIDTH{1'b0}}      ;
                                 out_eop    =  1'b0                    ;
                                 end

                   READ_HEADER  :
                                 begin

                                 if(deq_req_r)
                                     begin
                                     out_sop    =  1'b1                    ;
                                     rd_data_o  =  rd_data_out_w           ;
                                     out_eop    =  1'b0                    ;
                                     end
                                 else 
                                     begin
                                     out_sop    =  1'b0                    ;   
                                     rd_data_o  =  {DATA_WIDTH{1'b0}}      ;
                                     out_eop    =  1'b0                    ;
                                     end

                                 end

                   READ_DATA    : 
                                 begin

                                 if(deq_req_r)
                                     begin
                                     out_sop    =  1'b0                    ;
                                     rd_data_o  =  rd_data_out_w           ;

                                     if(count_r == (pck_len_r-1'b1))             
                                        begin
                                        out_eop = 1'b1                    ;
                                        end
                                     else
                                        begin
                                        out_eop = 1'b0                    ;
                                        end
                                     end

                                 else 
                                     begin
                                     out_sop    =  1'b0                    ;   
                                     rd_data_o  =  {DATA_WIDTH{1'b0}}      ;
                                     out_eop    =  1'b0                    ;
                                     end

                                 end                   

                   default      :
                                 begin
                                 out_sop    =  1'b0                    ;
                                 rd_data_o  =  {DATA_WIDTH{1'b0}}      ;
                                 out_eop    =  1'b0                    ;
                                 end

                   endcase

                   end

                   //       LOGIC TO GENERATE READ ENABLE FOR THE INTERNAL BUFFER
                   always_comb
                   begin
                   pck_len_rd_en = 1'b0 ;

                   unique case(next_state_r)
                   IDLE_R       : begin rd_en = 1'b0 ;  end
                   READ_HEADER  : begin 
                                        if(deq_req_r)
                                            begin
                                            pck_len_rd_en = 1'b1 ;
                                            rd_en         = 1'b1 ; 
                                            end
                                        else
                                            begin
                                            pck_len_rd_en = 1'b0 ;
                                            rd_en         = 1'b0 ;
                                            end
                                  end
                   READ_DATA    : begin 
                                        if(deq_req_r)
                                            begin
                                            rd_en = 1'b1 ;
                                            end
                                        else 
                                            begin
                                            rd_en = 1'b0 ;
                                            end
                                  end          
                   default      : begin rd_en = 1'b0 ;  end
                   endcase

                   end

                   //       LOGIC FOR PACKET PROCESSOR OVERFLOW AND UNDERFLOW
                   //       OVERFLOW LOGIC
                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(~pck_proc_int_mem_fsm_rstn)
                       begin
                       pck_proc_overflow <= 1'b0    ;
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       pck_proc_overflow <= 1'b0    ;
                       end
                   else if(enq_req && pck_proc_full)  
                       begin
                       pck_proc_overflow <= 1'b1    ;
                       end
                   else 
                       begin
                       pck_proc_overflow <= 1'b0    ;
                       end

                   end

                   //       UNDERFLOW LOGIC
                   always_ff@(posedge pck_proc_int_mem_fsm_clk or negedge pck_proc_int_mem_fsm_rstn)
                   begin

                   if(~pck_proc_int_mem_fsm_rstn)
                       begin
                       pck_proc_underflow <= 1'b0    ; 
                       end
                   else if(pck_proc_int_mem_fsm_sw_rstn)
                       begin
                       pck_proc_underflow <= 1'b0    ;
                       end
                   else if(deq_req && pck_proc_empty)  
                       begin
                       pck_proc_underflow <= 1'b1    ;
                       end
                   else 
                       begin
                       pck_proc_underflow <= 1'b0    ;
                       end

                   end



endmodule                   
