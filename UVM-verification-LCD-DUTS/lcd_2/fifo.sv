//async fifo
//`include "lcdif.v"
module fifo(
input logic wclk, //this clock should be bus clock
input logic rclk, //this clock should be pixel clock
input logic reset,
input logic [31:0] wdata,
input logic wen,
input logic ren,
output logic [31:0] rdata,
output logic full,
output logic empty,
output logic [5:0] fifo_used,
MEMIF.F0 memif
);

logic [5:0] cnt;
logic [5:0] wptr, rptr; //one extra bit for warp around
logic ren1;
logic wen1;
logic [4:0] waddr, raddr;
//resolve memif 
assign memif.f0_waddr = waddr;
assign memif.f0_wdata = wdata;
assign memif.f0_write = wen1;
assign memif.f0_raddr = raddr;
assign rdata          = memif.f0_rdata;

//mem32x32 ram (.clk(wclk), .waddr(waddr), .wdata(wdata), .write(wen1), .raddr(raddr), .rdata(rdata));

assign ren1=ren & !empty;
assign wen1=wen & !full;
assign waddr=wptr[4:0];
assign raddr=rptr[4:0];

//write pointer logic
always @ (posedge wclk or posedge reset)
    if(reset) wptr <= #1 '0;
    else if(wen1) wptr <= #1 wptr+1'b1;

//read pointer logic
always @ (posedge rclk or posedge reset)
    if(reset) rptr<=#1 '0;
    else if(ren1) rptr<=#1 rptr+1'b1;
    
//fifo occupation counter
assign cnt=(wptr[5]>=rptr[5]) ? (wptr-rptr) : ({1'b1,wptr[4:0]}-rptr[4:0]);

always @ (posedge wclk or posedge reset)
begin
    if(reset) fifo_used<=#1 '0;
    else if(wen1) fifo_used<=#1 cnt+1'b1;
    else fifo_used<=#1 cnt;
end

//full flag logic
always @ (posedge wclk or posedge reset)
begin
    if(reset) full<=#1 '0;
    else if(({~wptr[5],wptr[4:0]}==(rptr-1'b1)) && wen1) full<=#1 1'b1;
    else if(full && ({~wptr[5],wptr[4:0]}==(rptr-1'b1))) full<=#1 '0;
end

//empty flag logic
always @ (posedge rclk or posedge reset) 
begin
    if(reset) empty<=#1 1'b1;
    else if(empty && (rptr!=wptr)) empty<=#1 '0;
    else if((rptr==(wptr-1'b1)) && ren1) empty<=#1 1'b1;
end
	
	
endmodule
