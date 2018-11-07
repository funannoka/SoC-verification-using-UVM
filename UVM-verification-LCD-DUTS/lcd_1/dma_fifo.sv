module dma_fifo(input clk,rst,push,pull,input [31:0] data_in,output [31:0] data_out,output reg [5:0] depth_left,MEMIF.F0 mem_if,output full,empty,input fp_pulse);

reg [4:0]  w_ptr,r_ptr;
reg [31:0] w_data,r_data;
wire write;

//mem32x32 mem(.clk(clk),.waddr(w_ptr),.wdata(w_data),.write(write),.raddr(r_ptr),.rdata(r_data));
assign mem_if.f0_waddr = w_ptr;
assign mem_if.f0_wdata = w_data;
assign mem_if.f0_write = write;
assign mem_if.f0_raddr = r_ptr;
assign r_data          =mem_if.f0_rdata;


//assign read  = rst ? 0 : pull;
assign write = rst ? 0 : push;
assign w_data = data_in;    
assign data_out = rst ? 0:r_data; 
//assign full  = ((w_ptr + 4'h1) == r_ptr);
//assign empty = (r_ptr==w_ptr);
assign full  = (depth_left == 0);
assign empty = (depth_left == 32);

always @(posedge clk or negedge rst) begin 
  if(rst|fp_pulse) begin
 	w_ptr <= #0 0;
        r_ptr <= #0 0; 
        depth_left <= #0 32;
  end else begin
  
	        if(pull && !push && !empty) begin
                 r_ptr <= #1 r_ptr + 1;
                 depth_left <= #1 depth_left +1; 
                end 
                
                if(!pull && push && !full) begin
                 w_ptr <= #1 w_ptr + 1; 
                 depth_left <= #1 depth_left -1; 
                end  
                
                if(push && pull && !empty && !full) begin 
                 r_ptr <= #1 r_ptr + 1;
                 w_ptr <= #1 w_ptr + 1;
                end 
           
           end 

end 

assert property  ( @(posedge clk) disable iff (rst) (!(full && push)) ) ; 
assert property  ( @(posedge clk) disable iff (rst) (!(empty && pull))) ;
endmodule 
