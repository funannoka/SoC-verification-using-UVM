/******************** HTRANS parameter *********************/
                           
  parameter IDLE_m     = 2'b00;
  parameter BUSY_m     = 2'b01;
  parameter NONSEQ_m_m   = 2'b10;
  parameter SEQ_m      = 2'b11;
                          
                       
/******************** HBURST parameter **********************/
                            
 parameter SINGLE   = 3'b000;
 parameter INCR     = 3'b001;
 parameter WRAP4    = 3'b010;
 parameter INCR4    = 3'b011;
 parameter WRAP8    = 3'b100;
 parameter INCR8    = 3'b101;
 parameter WRAP16   = 3'b110;
 parameter INCR16   = 3'b111;
  
 
/*********************** HWRITE parameter *********************/
  
 parameter WRITE_m = 1'b1;
 parameter READ_m = 1'b0;
 
 /**************************************************************/

 parameter BASE_ADDR = 32'h00010200;
 
/*******************   States of FSM  ************************/

 parameter IDLE_m_1      = 3'b000;
 parameter ACCESSBUS   = 3'b001;
 parameter READ_SINGLE = 3'b010;
 parameter READ_BURST  = 3'b011;
 parameter LAST_READ   = 3'b100;
 parameter READ_KILLED = 3'b101;

/**************************************************************/ 

module LCD_master(
  input              HCLK,
  input              HRESET,
  input 	     dma_req_in, 
  input              HGRANT,
  input              HREADY,
  input [31:0]       HRDATA,
  input [1:0]        HRESP,
  input              lcd_en_i,
  output reg [31:0]  HADDR,
  output reg         HBUSREQ,
  output reg         HWRITE,
  output reg [1:0]   HTRANS,
  output reg [2:0]   HBURST,
  output reg [2:0]   HSIZE,
  input LCD_UPBASE   lcd_upbase,
  input              FIFO_full,
  output reg         fifo_push,
  input              valid,
  output reg [31:0]  FIFO_data,
  input fp_pulse
);


reg [2:0]  state_q, state_ns;
reg [10:0] count;
reg [10:0] count_w;
reg [31:0] DMA_addr_reg,DMA_addr_d;
reg [31:0] DMA_addr_w;
reg FIFO_push_d,FIFO_push;

assign FIFO_data = HRDATA;
assign HADDR     = DMA_addr_reg;
assign fifo_push = FIFO_push_d;

 always @(posedge HCLK or posedge HRESET) begin
   if(HRESET == 1'b1) begin
       state_q             <= #1 IDLE_m_1; 
       DMA_addr_reg        <= #1 32'b0;
       DMA_addr_d          <= #1 32'b0;  
       count 		   <= #1 count_w; 
       FIFO_push_d         <= #1 0;
   end else begin
       state_q             <= #1 state_ns;
       DMA_addr_reg        <= #1 DMA_addr_w;
       DMA_addr_d          <= #1 DMA_addr_reg;
       count 		   <= #1 count_w; 
       FIFO_push_d         <= #1 FIFO_push;
   end
 end
 
 always @(*) begin
    HSIZE   = 3'b010;
    HWRITE  = READ_m;
    HBURST  = INCR;
    
    case(state_q)
      IDLE_m_1: begin

                  HBUSREQ       = 1'b0;
                  HTRANS        = IDLE_m;
                  FIFO_push     = 1'b0;
                  count_w       = 11'b0;
                  DMA_addr_w    = {lcd_upbase.LCDUPBASE,3'b000};
                  
                  if(lcd_en_i) begin
                    state_ns = ACCESSBUS;
                  end else begin 
                    state_ns = IDLE_m_1;
                  end

                end


      ACCESSBUS: begin
                    HBUSREQ       = 1'b1;  
                    HTRANS        = IDLE_m;
                    FIFO_push     = 1'b0;
                    DMA_addr_w    = DMA_addr_reg;
                             
                   if(fp_pulse == 0) begin 
                    if(HGRANT == 1'b1 && dma_req_in) begin 
                      //DMA_addr_w    = DMA_addr_reg + 3'b001;
                      state_ns      = READ_SINGLE ;
                    end else begin
                      state_ns = ACCESSBUS;
                    end
		   end else begin
                             state_ns = IDLE_m_1; // refresh frame buffer after fp
			    end
                  end
      
      
      READ_SINGLE : begin
                     HBUSREQ    = 1'b1;
                     HTRANS     = NONSEQ_m_m;
                     FIFO_push  = 1'b0;
                     DMA_addr_w =  DMA_addr_reg;
                     
                     if (HGRANT == 1'b1) begin
                        state_ns   = dma_req_in ? READ_BURST:ACCESSBUS;
                        FIFO_push  = 1'b1;
                        DMA_addr_w = DMA_addr_reg + 3'b100;
                     end else begin
                        state_ns = ACCESSBUS;
                     end

                    end
      
      READ_BURST  : begin
                     HBUSREQ = 1'b1;
                     HTRANS  = SEQ_m;
                     count_w = count + 4;       
                     FIFO_push = 1'b0;
                        
                     if(HREADY == 1'b1 & HGRANT == 1'b1 & FIFO_full == 1'b0 & count[10] == 1'b0) begin

                         FIFO_push     = 1'b1;
                         DMA_addr_w    = DMA_addr_reg + 3'b100;
                         state_ns      = dma_req_in ? READ_BURST : ACCESSBUS;

                     end else if (HREADY == 1'b0 & HGRANT == 1'b1 & FIFO_full == 1'b0 & count[10] == 1'b0) begin

                         DMA_addr_w    = DMA_addr_reg;
                         state_ns      = READ_BURST;

                     end else if (HREADY == 1'b0 & HGRANT == 1'b1 & FIFO_full == 1'b1 & count[10] == 1'b1) begin

                         DMA_addr_w    = DMA_addr_reg;
                         state_ns      = LAST_READ;
                     end else begin
                         
                         HTRANS        = IDLE_m;
                         DMA_addr_w    = DMA_addr_reg;
                         state_ns      = ACCESSBUS;
                     end

                   end
      
      LAST_READ   : begin
                      HBUSREQ = 1'b0;
                      HTRANS  = IDLE_m;
                      DMA_addr_w = DMA_addr_reg;
                      
                      if(HREADY == 1'b1) begin 
                          FIFO_push = 1'b1;
                          DMA_addr_w = DMA_addr_reg + 3'b001;
                          state_ns = ACCESSBUS;
                      end else begin
                          FIFO_push = 1'b0;
                          state_ns = LAST_READ;
                      end
                      end

      READ_KILLED : begin
                     HBUSREQ   = 1'b0;
                     HTRANS    = IDLE_m;
                     FIFO_push = 1'b0;
                     state_ns  = ACCESSBUS; 

      end
    endcase
 end
 
endmodule




