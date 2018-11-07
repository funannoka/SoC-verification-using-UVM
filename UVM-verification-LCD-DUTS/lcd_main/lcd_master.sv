//
// this is to handle the bus master requirements of the
// lcd controller. It is a very simple bus master. It will
// handle bursting to the correct address point.
//



module lcd_master(AHBIF.AHBCLKS C, AHBIF.AHBM M,
        input logic fetch, output logic done,
        input logic [31:0] faddr, input logic [4:0] fwords,
        output logic dstrobe, output logic [31:0] fdata
            );
typedef enum logic [1:0] { Sidle,Sreq,S0,S1 } Mstate;
Mstate csm,nsm;
logic [31:0] addr,addr_d;
logic [4:0] bcnt,bcnt_d;
logic [1:0] pdone,pdone_d; // 0=nothing, 1=data, 2=last data
logic pread,pread_d;
assign done=pdone==2;
assign dstrobe=M.mHREADY && pdone != 0;
assign fdata = M.mHRDATA;


always @(*) begin
  nsm = csm;
  M.mHBUSREQ= ((csm==Sidle && fetch) || csm!=Sidle);
  M.mHWRITE=0;
  addr_d = addr;
//  M.HTRANS = 0;     // set it to idle
  bcnt_d = bcnt;
//  M.HSIZE=2;
//  M.HBURST=0;
//  M.HADDR = addr;
  pdone_d=0;
  case(csm)
    Sidle:
      begin
        bcnt_d=1;
        M.mHTRANS=0;
        if(fetch) begin
          addr_d = faddr;
        end
        if(fetch && M.mHGRANT) begin
          nsm = S0;
        end else if(fetch) begin
          nsm = Sreq;
        end
      end
    Sreq:
      begin
        M.mHTRANS=2;
        M.mHADDR=addr;
        if(M.mHGRANT) begin
          nsm=S1;
          addr_d=addr+4;
          bcnt_d=2;
          pdone_d=1;
        end
      end
    S0:
      begin
        M.mHADDR=addr;
        M.mHTRANS=2;
        bcnt_d=2;
        if(fwords > 1) begin
          M.mHBURST=1;
        end
        if(M.mHREADY) begin
          pdone_d=1;
          if(fwords > 1) begin
            M.mHBURST=1;
            pdone_d=1;
            nsm=S1;
          end else begin
            nsm=Sidle;
            pdone_d=2;
          end
          addr_d = addr+4;
        end
      end
    S1:
      begin
        M.mHTRANS=3;
        M.mHADDR=addr;
        if(fwords > 1) begin
          M.mHBURST=1;
        end
        if(M.mHREADY) begin
          if(bcnt < fwords) begin
            bcnt_d = bcnt+1;
            addr_d = addr+4;
            pdone_d=1;
            if(addr_d[10] != addr[10]) nsm=S1;
          end else begin
            pdone_d=2;
            nsm=Sidle;
          end
        end
      end
  endcase
end


always @(posedge(C.HCLK) or posedge(C.HRESET) ) begin
  if(C.HRESET) begin
    csm <= Sidle;
    addr <= 0;
    bcnt <= 0;
    pdone <= 0;
  end else begin
    csm <= #1 nsm;
    addr <= #1 addr_d;
    bcnt <= #1 bcnt_d;
    pdone <= #1 pdone_d;
  end
end




endmodule : lcd_master
