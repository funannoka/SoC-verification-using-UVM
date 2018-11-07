module dma_fifo_ctrl_logic(output dma_req,input clk,rst,push,pull,
                           input  [31:0] data_in,input LCD_CTRL lcd_ctrl,
                           output [31:0] data_out,output fifofull,
                           MEMIF.F0 mem_if0,MEMIF.F0 mem_if1,input fp_pulse);
wire [5:0] depth_left_top,depth_left_bottom;
wire [6:0] comb_depth;
wire [3:0] water_mark_level;
wire check_up_fifo,check_bottom_fifo,check_combined,select_check;
wire [31:0] data_out_top,data_out_bottom;
wire push_top,push_bottom,fifo_top_full,fifo_bottom_full,fifo_top_empty,fifo_bottom_empty;
reg [5:0] r_ptr,w_ptr,net_depth;

dma_fifo fifo_top(.clk(clk),
                  .rst(rst),
                  .push(push_top),
                  .pull(pull_top),
                  .data_in(data_in),
                  .data_out(data_out_top),
                  .depth_left(depth_left_top),
                  .mem_if(mem_if0),
		  .full(fifo_top_full),
		  .empty(fifo_top_empty),
                  .fp_pulse(fp_pulse));

dma_fifo fifo_bottom(.clk(clk),
                     .rst(rst),
                     .push(push_bottom),
                     .pull(pull_bottom),
                     .data_in(data_in),
                     .data_out(data_out_bottom),
                     .depth_left(depth_left_bottom),
                     .mem_if(mem_if1),
		     .full(fifo_bottom_full),
		     .empty(fifo_bottom_empty),
                     .fp_pulse(fp_pulse));

// dma req generation 
assign water_mark_level  = lcd_ctrl.WATERMARK ? (1<<3):(1<<2);
assign check_up_fifo     = (depth_left_top >= water_mark_level);
assign check_bottom_fifo = (depth_left_bottom >= water_mark_level);
assign check_combined    = ((depth_left_top + depth_left_bottom) >= water_mark_level);
assign select_check      =  !lcd_ctrl.LCDTFT ? check_combined : (check_bottom_fifo|check_up_fifo);
assign dma_req           = rst ? 0 : select_check;

assign comb_depth        = depth_left_top + depth_left_bottom;
assign comb_full         = (comb_depth == 0) ;
assign comb_empty        = (comb_depth == 64)  ;

//assign data_out          = pull_top ? data_out_top : data_out_bottom;
assign data_out          = !r_ptr[5] ? data_out_top : data_out_bottom;

// wrap counter for TFT case
//fifo fill in TFT mode 
always @(posedge clk or posedge rst) begin 
           if(rst | fp_pulse) begin 
              r_ptr <= #0 0;
              w_ptr <= #0 0;
              net_depth <= #0 0;
           end else begin 

                      if(pull && !comb_empty) begin 
                        r_ptr <= #1 r_ptr+1;
                      end
 
                      if(push && !comb_full) begin 
                        w_ptr <= #1 w_ptr+1;
                      end                  
 
                      if(pull && !push) begin 
                        net_depth <= #1 net_depth - 1;
                      end

                      if(!pull && push) begin 
                        net_depth <= #1 net_depth + 1;
                      end

                    end
end 

// fifo filling 
reg mod2_pull,mod2_push;
assign push_top    = !lcd_ctrl.LCDTFT    ? (push & !mod2_push):(push & !w_ptr[5] & !fifo_top_full );
assign push_bottom = !lcd_ctrl.LCDTFT    ? (push & mod2_push) :(push &  w_ptr[5] & !fifo_bottom_full );
assign pull_top    = !lcd_ctrl.LCDTFT    ? (pull & !mod2_pull):(pull & !r_ptr[5] & !fifo_top_empty);
assign pull_bottom = !lcd_ctrl.LCDTFT    ? (pull & !mod2_pull):(pull &  r_ptr[5] & !fifo_bottom_empty  );


always @(posedge clk or posedge rst) begin 
   if(rst|fp_pulse)begin 
          mod2_pull <= #0 0;
          mod2_push <= #0 0;
   end else begin  
              mod2_pull <= #1 pull ? ~mod2_pull:mod2_pull;
              mod2_push <= #1 push ? ~mod2_push:mod2_push;
            end 
end

assign fifofull = lcd_ctrl.LCDTFT ? (comb_full):((depth_left_top==31) & (depth_left_bottom==31));

assert property ( @(posedge clk) disable iff (rst) !(push_top & push_bottom));
assert property ( @(posedge clk) disable iff (rst) !(pull_top & pull_bottom));

endmodule 
