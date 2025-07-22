//`timescale 1ns/1ps
module pck_len_fifo
              #(parameter DATA_WIDTH   = 12     , 
                          DEPTH        = 32     , 
                          ADDR_WIDTH   = 5      
               )
            (
             
            input  logic                          clk                  ,  //////  clock 

            input  logic                          hw_rst               ,  //////  reset           
            input  logic                          sw_rst               ,  //////  sotware reset

            input  logic                          wr_en                ,   //////  to write the data 
            input  logic       [DATA_WIDTH-1:0]   wr_data              ,
      
            input  logic                          rd_en                ,   //////  to read the data 
            output logic       [DATA_WIDTH-1:0]   rd_data_out          ,

            input  logic       [4:0]              almost_full_value    , 
            input  logic       [4:0]              almost_empty_value   ,
            
            output logic                          buffer_full          ,   //////  to ack wheather buffer is full or not
            output logic                          buffer_empty         ,

            output logic                          almost_full          ,   //////  to indicate almost full and almost empty
            output logic                          almost_empty         ,

            output logic       [ADDR_WIDTH:0]     wr_lvl               ,   //////  to indicate write and read level

            output logic                          overflow             ,    //////  to indicate overflow and overflow condidtion
            output logic                          underflow            ,

            input  logic                          pck_drop             
            );


//////  to know the address of buffer logic
logic [ADDR_WIDTH:0]    wr_ptr           ;
logic [ADDR_WIDTH:0]    rd_ptr           ;

////// to the use for almost empty and almost full 
logic temp_empty                        ;
logic temp_full                         ;


/////              INTERNAL BUFFER INSTANTIATION             /////
pck_len_buffer
             #(
               .DATA_WIDTH  ( DATA_WIDTH )    ,  
               .DEPTH       ( DEPTH      )    , 
               .ADDR_WIDTH  ( ADDR_WIDTH )        
              )                        
pck_len_buffer_inst           
              (
               .int_buffer_clk      ( clk           )   ,
               .int_buffer_rstn     ( hw_rst        )   ,
               .int_buffer_sw_rstn  ( sw_rst        )   ,
                                                 
               .wr_en_i             ( wr_en         )   ,
               .wr_addr             ( wr_ptr        )   ,
               .wr_data             ( wr_data       )   ,
                                                 
               .rd_en_i             ( rd_en         )   ,
               .rd_addr             ( rd_ptr        )   ,

               .buffer_full         ( buffer_full   )   ,
               .buffer_empty        ( buffer_empty  )   ,
                                                 
               .rd_data_o           ( rd_data_out   )
              );
//-------------------------------------------------------------------------------------              



////------------------------------ WRITING OPERATION ------------------------------////

////// checking for almost full condition

assign temp_full = (wr_lvl >= DEPTH - almost_full_value)        ;


////// assigning almost full 
always_comb
begin
        if(temp_full)
        begin
            almost_full = 1'b1                             ;
        end

        else
        begin
            almost_full = 1'b0                             ;
        end

end


//////   incrementing the write pointer while writing the data to the memory
always_ff@(posedge clk or negedge hw_rst )
begin

    if(!hw_rst)
    begin
         wr_ptr       <= {(ADDR_WIDTH+1){1'b0}}                  ;
    end

    else if(sw_rst)
    begin
         wr_ptr       <= {(ADDR_WIDTH+1){1'b0}}                  ;
    end
    
    else if(pck_drop)
        begin
        wr_ptr        <= wr_ptr - 1'b1                       ;
        end

    else if(wr_en && ~buffer_full)
    begin
         wr_ptr       <= wr_ptr + 1'b1                       ; 
    end

end 

////// assigning buffer full 
assign buffer_full  = (({~wr_ptr[5],wr_ptr[ADDR_WIDTH-1:0]} == rd_ptr))                   ;

////// assigning the overflow
 always_ff@(posedge clk or negedge hw_rst)
 begin

 if(!hw_rst)
     begin
     overflow  <= 1'b0                                  ;
     end
  else if(sw_rst)
     begin
     overflow  <= 1'b0                                  ;
     end
  else if(buffer_full && wr_en)
     begin
     overflow  <=  1'b1                                 ; 
     end
  else
     begin
     overflow  <= 1'b0                                  ;
     end

 end
//-------------------------------------------------------------------------------------------

////--------------------------- READING OPERATION ---------------------------------------////

////// to check almost empty condition 
assign temp_empty = (wr_lvl <= almost_empty_value)                       ;


////// assigning almost empty 
always_comb
begin

        if(!hw_rst)
        begin
            almost_empty = 1'b1                            ;     
        end

        else if(sw_rst)
        begin
             almost_empty = 1'b1                           ; 
        end

        else if(temp_empty)
        begin
            almost_empty = 1'b1                             ;
        end

        else
        begin
            almost_empty = 1'b0                             ;
        end

end

//////   reading the data from the memory
always_ff@(posedge clk or negedge hw_rst)
begin

     if(!hw_rst)
     begin        
         rd_ptr       <= {(ADDR_WIDTH+1){1'b0}}                  ;
     end

     else if(sw_rst)
     begin
         rd_ptr       <= {(ADDR_WIDTH+1){1'b0}}                  ;
     end

    else if(rd_en && !buffer_empty)
    begin        
        rd_ptr        <= rd_ptr + 1'b1                       ;
    end

end


//////  calculating buffer empty condition     

assign buffer_empty = (wr_ptr == rd_ptr)                    ;

//////  assigning the underflow 
always_ff@(posedge clk or negedge hw_rst)
 begin
 if(!hw_rst)
     begin
     underflow  <=  1'b0                                 ;
     end
 else if(sw_rst)
     begin
      underflow  <=  1'b0                                ;
     end
 else if(buffer_empty && rd_en)
     begin
     underflow  <=  1'b1                                 ; 
     end
 else
     begin
     underflow  <= 1'b0                                  ;
     end
 end

//---------------------------------------------------------------------------------------

////------------------- calculating write level -------------------------------------////

always_ff@(posedge clk or negedge hw_rst )
begin

    if(!hw_rst)
    begin
        wr_lvl  <= {(ADDR_WIDTH+1){1'b0}}                                      ;
    end

    else if(sw_rst)
    begin
        wr_lvl  <= {(ADDR_WIDTH+1){1'b0}}                                      ;
    end    

    else if( (wr_en && ~buffer_full) && (rd_en && ~buffer_empty) && (~overflow))
    begin
        wr_lvl  <= wr_lvl                                                 ;
    end

    else if(wr_en && ~buffer_full)
    begin
        wr_lvl <= wr_lvl + 1'b1                                           ;
    end

    else if(rd_en && ~buffer_empty)
    begin
        wr_lvl  <= wr_lvl - 1'b1                                          ; 
    end

end

////----------------------------------------------------------------------------------------

endmodule
