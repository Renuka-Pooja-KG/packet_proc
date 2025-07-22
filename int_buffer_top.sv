//`timescale 1ns/1ps
module int_buffer_top
              #(parameter DATA_WIDTH        = 32     , 
                          DEPTH             = 16384  , 
                          ADDR_WIDTH        = 14     ,
                          PCK_LEN           = 12     
               )
            (
             
            input  logic                          clk                  ,  //////  clock 

            input  logic                          hw_rst               ,  //////  reset           
            input  logic                          sw_rst               ,  //////  sotware reset

            input  logic                          empty_de_assert      ,

            input  logic                          wr_en                ,   //////  to write the data 
            input  logic       [DATA_WIDTH-1:0]   wr_data              ,

            input  logic                          in_eop               ,
            input  logic       [PCK_LEN-1:0]      count                ,

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

            input  logic                          pck_drop             ,
            input  logic       [PCK_LEN-1:0]      count_w       

            );


//////  to know the address of buffer logic
logic [ADDR_WIDTH:0]    wr_ptr           ;
logic [ADDR_WIDTH:0]    rd_ptr           ;

////// to the use for almost empty and almost full 
logic temp_empty                        ;
logic temp_full                         ;

logic buffer_empty_r                    ;


/////              INTERNAL BUFFER INSTANTIATION             /////
int_buffer 
             #( 
               .DATA_WIDTH  ( DATA_WIDTH  ) ,
               .DEPTH       ( DEPTH       ) ,
               .ADDR_WIDTH  ( ADDR_WIDTH  )
              )
int_buffer_inst
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
    
    else if(pck_drop && overflow)
        begin
        wr_ptr        <= wr_ptr - count_w + 1'b1                 ;
        end

    else if(pck_drop)
        begin
        wr_ptr        <= wr_ptr - count_w                        ;
        end

    else if(wr_en && ~buffer_full)
    begin
       //  buffer[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data             ;
         wr_ptr       <= wr_ptr + 1'b1                           ; 
    end  

end 

////// assigning buffer full 
assign buffer_full  = (({~wr_ptr[14],wr_ptr[ADDR_WIDTH-1:0]} == rd_ptr))                   ;

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

        if(temp_empty)
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

assign buffer_empty =  ((empty_de_assert ==0) && (wr_ptr != rd_ptr)) ? 1'b0 :((in_eop && (wr_ptr != rd_ptr) && (empty_de_assert == 1))) ? 1'b0 : ((wr_ptr == rd_ptr) ? 1'b1 : buffer_empty_r)  ; 

always_ff@(posedge clk or negedge hw_rst)
begin

if(!hw_rst)
    begin
        buffer_empty_r <= 1'b1  ;
    end
else if(sw_rst)
    begin
        buffer_empty_r <= 1'b1  ;
    end
else 
    begin
        buffer_empty_r <= buffer_empty  ;
    end
end

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

    else if(pck_drop)
    begin
        wr_lvl <= wr_lvl - count_w                                             ;
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
