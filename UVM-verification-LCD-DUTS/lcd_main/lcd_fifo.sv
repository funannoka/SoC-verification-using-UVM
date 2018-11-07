//
// This is the lcd fifo
//
module lcd_fifo(AHBIF.AHBCLKS C,input logic push,output logic full,input logic [31:0] wdata,
    input logic pull, output logic fifoempty, output logic [31:0] rdata,output logic [5:0] cnt, 
    input flush,
    MEMIF.F0 F);

logic [4:0] rpt,rpt_d,wpt,wpt_d;
logic [5:0] wcnt,wcnt_d;
logic fullflag,fullflag_d;
assign F.f0_raddr = rpt;
assign F.f0_waddr = wpt;
assign F.f0_wdata = wdata;
assign rdata = F.f0_rdata;
logic emptyflag;
assign fifoempty=emptyflag;
assign cnt = wcnt;

always @(*) begin
  fullflag_d = fullflag;
  wcnt_d = wcnt;
  emptyflag = rpt==wpt && fullflag==0;
  wpt_d=wpt;
  rpt_d=rpt;
  F.f0_write=0;
  if(flush) begin
    rpt_d=0;
    wpt_d=0;
    wcnt_d=0;
    fullflag_d=0;
  end else begin
    if((emptyflag==0) && pull==1) begin
      rpt_d=rpt+1;
      wcnt_d = wcnt-1;
      fullflag_d=0;
    end
    if(!fullflag && push) begin
      F.f0_write=1;
      wpt_d=wpt+1;
      if(wpt_d == rpt) fullflag_d=1;
      wcnt_d = wcnt_d+1;
    end
  end
end



always@(posedge(C.HCLK) or posedge(C.HRESET)) begin
  if(C.HRESET) begin
    fullflag <= 0;
    rpt  <= 0;
    wpt  <= 0;
    wcnt <= 0;
  end else begin
    fullflag <= #1 fullflag_d;
    wpt <= #1 wpt_d;
    rpt <= #1 rpt_d;
    wcnt <= #1 wcnt_d;
  end
end


endmodule: lcd_fifo
