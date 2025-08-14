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
* File Name : int_buffer.sv

* Purpose :

* Creation Date : 05-04-2023

* Last Modified : Fri 17 Feb 2023 03:41:08 AM IST

* Created By :  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/
`timescale 1ns/1ps
module int_buffer
                 #( 
                   parameter    DATA_WIDTH = 32     ,
                                ADDR_WIDTH = 14     ,
                                DEPTH      = 16384
                  )
                  (
                   input    logic                        int_buffer_clk      ,
                   input    logic                        int_buffer_rstn     ,
                   input    logic                        int_buffer_sw_rstn  ,

                   input    logic                        wr_en_i             ,
                   input    logic   [ADDR_WIDTH:0]       wr_addr             ,
                   input    logic   [DATA_WIDTH-1:0]     wr_data             ,

                   input    logic                        rd_en_i             ,
                   input    logic   [ADDR_WIDTH:0]       rd_addr             ,

                   input    logic                        buffer_full         ,
                   input    logic                        buffer_empty        ,

                   output   logic   [DATA_WIDTH-1:0]     rd_data_o           
                  ); 

                  //////  to create a pac_buffer with data_width = 32 and depth = 16384
                  logic [DATA_WIDTH-1:0] pac_buffer [0:DEPTH-1]  ;

                  //    WRITING DATA TO THE pac_buffer
                  always_ff@(posedge int_buffer_clk)
                  begin
                  
                      if(wr_en_i && ~buffer_full)
                      begin
                           pac_buffer[wr_addr[ADDR_WIDTH-1:0]] <= wr_data               ;
                      end
                  
                  end

                 //////   READING THE DATA FROM THE pac_buffer
                 always_ff@(posedge int_buffer_clk or negedge int_buffer_rstn)
                 begin
                 
                      if(!int_buffer_rstn)
                      begin        
                          rd_data_o  <= {DATA_WIDTH{1'b0}}                  ;                            
                      end
                 
                      else if(int_buffer_sw_rstn)
                      begin
                          rd_data_o  <= {DATA_WIDTH{1'b0}}                  ;                           
                      end
                 
                      else if(rd_en_i && !buffer_empty)
                      begin        
                         rd_data_o   <= pac_buffer[rd_addr[ADDR_WIDTH-1:0]]      ;
                      end

                      else if(buffer_empty)
                      begin
                          rd_data_o  <= {DATA_WIDTH{1'b0}}                  ;                           
                      end
                 
                 end

endmodule                 
