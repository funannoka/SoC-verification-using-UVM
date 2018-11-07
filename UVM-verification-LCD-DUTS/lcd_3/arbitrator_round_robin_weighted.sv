`timescale 1ns/10ps
`include "multiplexer.sv"
`include "decoder.sv"
`include "rd_mux.sv"

module arbitrator (input CLK, input RESET, AHBIF arb_lcdm0, AHBIF arb_lcdm1, AHBIF arb_lcdm2, AHBIF arb_lcdm3, AHBIF arb_lcdmtb4, AHBIF arb_lcds0, AHBIF arb_lcds1, AHBIF arb_lcds2, AHBIF arb_lcds3, AHBIF arb_lcdstb4);

logic purple_flag;       

logic [3:0] HMASTER, HMASTER_delay; // this flag shows that once arbitrator grants the request, it cannot send grant to any other master.
logic [7:0] flag;
logic [6:0] cnt;
logic [31:0] mux_wout;
logic [31:0] mux_addr_out;
logic [4:0] HSEL;
logic [31:0] rd_mux_out;
logic [1:0] resp_mux_out;
logic mux_write;
logic [1:0] mux_trans;
logic [2:0] mux_size;
logic [2:0] mux_burst;

typedef enum {bus_0_1,bus_1_1,bus_2,bus_3,bus_0_2,bus_1_2,bus_0_3,bus_4,idle}state;
state ps,ns;

multiplexer addr_ctrl_mux (.CLK(CLK), .RESET(RESET), .HADDR0(arb_lcdm0.mHADDR), .HADDR1(arb_lcdm1.mHADDR), .HADDR2(arb_lcdm2.mHADDR), .HADDR3(arb_lcdm3.mHADDR), .HADDR4(arb_lcdmtb4.mHADDR), .HWDATA0(arb_lcdm0.mHWDATA), .HWDATA1(arb_lcdm1.mHWDATA), .HWDATA2(arb_lcdm2.mHWDATA), .HWDATA3(arb_lcdm3.mHWDATA), .HWDATA4(arb_lcdmtb4.mHWDATA), .HWRITE0(arb_lcdm0.mHWRITE), .HWRITE1(arb_lcdm1.mHWRITE), .HWRITE2(arb_lcdm1.mHWRITE), .HWRITE3(arb_lcdm3.mHWRITE), .HWRITE4(arb_lcdmtb4.mHWRITE), .HTRANS0(arb_lcdm0.mHTRANS), .HTRANS1(arb_lcdm1.mHTRANS), .HTRANS2(arb_lcdm2.mHTRANS), .HTRANS3(arb_lcdm3.mHTRANS), .HTRANS4(arb_lcdmtb4.mHTRANS), .HSIZE0(arb_lcdm0.mHSIZE), .HSIZE1(arb_lcdm1.mHSIZE), .HSIZE2(arb_lcdm2.mHSIZE), .HSIZE3(arb_lcdm3.mHSIZE), .HSIZE4(arb_lcdmtb4.mHSIZE), .HBURST0(arb_lcdm0.mHBURST), .HBURST1(arb_lcdm1.mHBURST), .HBURST2(arb_lcdm2.mHBURST), .HBURST3(arb_lcdm3.mHBURST), .HBURST4(arb_lcdmtb4.mHBURST), .mux_write(mux_write), .mux_trans(mux_trans), .mux_size(mux_size), .mux_burst(mux_burst), .mux_addr_out(mux_addr_out), .mux_wout(mux_wout), .HMASTER(HMASTER));

decoder ahb_decoder (.HADDR(mux_addr_out),.HSEL(HSEL));

assign arb_lcds0.HSEL = HSEL[0];
assign arb_lcds1.HSEL = HSEL[1];
assign arb_lcds2.HSEL = HSEL[2];
assign arb_lcds3.HSEL = HSEL[3];
assign arb_lcdstb4.HSEL = HSEL[4];

assign arb_lcds0.HADDR = mux_addr_out;
assign arb_lcds1.HADDR = mux_addr_out;
assign arb_lcds2.HADDR = mux_addr_out;
assign arb_lcds3.HADDR = mux_addr_out;
assign arb_lcdstb4.HADDR = mux_addr_out;

assign arb_lcds0.HWDATA = mux_wout;
assign arb_lcds1.HWDATA = mux_wout;
assign arb_lcds2.HWDATA = mux_wout;
assign arb_lcds3.HWDATA = mux_wout;
assign arb_lcdstb4.HWDATA = mux_wout;

assign arb_lcds0.HWRITE = mux_write;
assign arb_lcds1.HWRITE = mux_write;
assign arb_lcds2.HWRITE = mux_write;
assign arb_lcds3.HWRITE = mux_write;
assign arb_lcdstb4.HWRITE = mux_write;


assign arb_lcds0.HTRANS = mux_trans;
assign arb_lcds1.HTRANS = mux_trans;
assign arb_lcds2.HTRANS = mux_trans;
assign arb_lcds3.HTRANS = mux_trans;
assign arb_lcdstb4.HTRANS = mux_trans;


assign arb_lcds0.HSIZE = mux_size;
assign arb_lcds1.HSIZE = mux_size;
assign arb_lcds2.HSIZE = mux_size;
assign arb_lcds3.HSIZE = mux_size;
assign arb_lcdstb4.HSIZE = mux_size;


assign arb_lcds0.HBURST = mux_burst;
assign arb_lcds1.HBURST = mux_burst;
assign arb_lcds2.HBURST = mux_burst;
assign arb_lcds3.HBURST = mux_burst;
assign arb_lcdstb4.HBURST = mux_burst;


rd_mux read_data_mux (.HSEL(HSEL), .HRDATA0(arb_lcds0.HRDATA), .HRDATA1(arb_lcds1.HRDATA), .HRDATA2(arb_lcds2.HRDATA), .HRDATA3(arb_lcds3.HRDATA), .HRDATA4(arb_lcdstb4.HRDATA), .HRESP0(arb_lcds0.HRESP), .HRESP1(arb_lcds1.HRESP), .HRESP2(arb_lcds2.HRESP), .HRESP3(arb_lcds3.HRESP), .HRESP4(arb_lcdstb4.HRESP), .HREADY0(arb_lcds0.HREADY), .HREADY1(arb_lcds1.HREADY), .HREADY2(arb_lcds2.HREADY), .HREADY3(arb_lcds3.HREADY), .HREADY4(arb_lcdstb4.HREADY), .rd_mux_out(rd_mux_out), .resp_mux_out(resp_mux_out), .CLK(CLK), .RESET(RESET), .HMASTER(HMASTER), .mHRDATA0(arb_lcdm0.mHRDATA), .mHRDATA1(arb_lcdm1.mHRDATA), .mHRDATA2(arb_lcdm2.mHRDATA), .mHRDATA3(arb_lcdm3.mHRDATA), .mHRDATA4(arb_lcdmtb4.mHRDATA), .mHRESP0(arb_lcdm0.mHRESP), .mHRESP1(arb_lcdm1.mHRESP), .mHRESP2(arb_lcdm2.mHRESP), .mHRESP3(arb_lcdm3.mHRESP), .mHRESP4(arb_lcdmtb4.mHRESP));

assign arb_lcdm0.mHREADY = 1'b1;
assign arb_lcdm1.mHREADY = 1'b1;
assign arb_lcdm2.mHREADY = 1'b1;
assign arb_lcdm3.mHREADY = 1'b1;
assign arb_lcdmtb4.mHREADY = 1'b1;

always @(posedge CLK or posedge RESET)
begin
  if(RESET)
  begin
    ps <= idle;
    cnt <= 'bx;
  end
  else 
  begin
    if(ps == idle || ns== bus_4 || purple_flag == 1'b1) //idle or reset or priority condition, change state immediately
    begin
      ps <= ns;
      cnt <= 1;
    end
    else
    begin
      cnt <= cnt +1;
      if (cnt >= 30) //every state gets 100 time unit for 30% 20% 10% 10% range of time for every state.(round robin)
      begin
        ps <= ns;
        #0 cnt <= 1; 
      end
    end
  end
end

always @(*)
begin
  case(ps)
    bus_0_1:
    begin
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
      if(arb_lcdmtb4.mHBUSREQ != 1'b1)
      begin
        if (arb_lcdm0.mHBUSREQ == 1'b1)
        begin
          arb_lcdm0.mHGRANT = 1'b1;
          HMASTER=4'b0000;
          ns=bus_2; 
          purple_flag = 1'b0; 
          flag= 8'b00000000; 
        end
        else 
        begin
          arb_lcdm0.mHGRANT = 1'b0;
          HMASTER=4'bx;
          ns=bus_2;
          purple_flag = 1'b1; 
          flag= 8'b00000000; 
        end
      end
      else
      begin 
        ns = bus_4;
        arb_lcdm0.mHGRANT = 1'b0;
        flag =  8'b0000001; 
        purple_flag = 1'b0;      
        HMASTER = 4'bx;
      end
    end

    bus_1_1:
    begin 
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
      if(arb_lcdmtb4.mHBUSREQ != 1'b1)
      begin
        if (arb_lcdm1.mHBUSREQ == 1'b1)
        begin
          arb_lcdm1.mHGRANT = 1'b1;
          HMASTER=4'b0001;
          ns=bus_0_1;
          purple_flag = 1'b0; 
          flag= 8'b00000000; 
        end
        else 
        begin
          arb_lcdm1.mHGRANT = 1'b0;
          HMASTER=4'bx;            
          ns=bus_0_1;
          purple_flag = 1'b1; 
          flag= 8'b00000000; 
        end
      end
      else 
        begin
          ns= bus_4;
          arb_lcdm1.mHGRANT = 1'b0;
          flag = 8'b0000010;
          purple_flag = 1'b0;
          HMASTER=4'bx;            
        end
    end

    bus_2:
    begin 
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
      if(arb_lcdmtb4.mHBUSREQ != 1'b1)
      begin
        if (arb_lcdm2.mHBUSREQ == 1'b1)
        begin
          arb_lcdm2.mHGRANT = 1'b1;
          HMASTER=4'b0010;
          ns=bus_0_2;
          purple_flag = 1'b0; 
          flag= 8'b00000000; 
       end
        else 
        begin
          arb_lcdm2.mHGRANT = 1'b0;
          HMASTER=4'bx;            
          ns=bus_0_2;
          purple_flag = 1'b1; 
          flag= 8'b00000000; 
        end
      end
    else 
      begin
        ns = bus_4;
        arb_lcdm2.mHGRANT = 1'b0;
        flag = 8'b0000100;
        purple_flag = 1'b0;
        HMASTER = 4'bx;
      end
    end
  
    bus_3:
    begin 
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
      if(arb_lcdmtb4.mHBUSREQ != 1'b1)
      begin
        if (arb_lcdm3.mHBUSREQ == 1'b1)
        begin
          arb_lcdm3.mHGRANT = 1'b1;
          HMASTER=4'b0011;
          ns=bus_1_1;
          purple_flag = 1'b0; 
          flag= 8'b00000000; 
        end
        else 
        begin 
          arb_lcdm3.mHGRANT = 1'b0;
          HMASTER=4'bx;
          ns=bus_1_1;
          purple_flag = 1'b1; 
          flag= 8'b00000000; 
        end
      end
      else 
        begin 
          ns = bus_4;
          arb_lcdm3.mHGRANT = 1'b0;
          flag = 8'b0001000;
          purple_flag = 1'b0;
          HMASTER=4'bx;
          ns=bus_0_2;
       end
    end

  bus_0_2:
  begin 
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
    if(arb_lcdmtb4.mHBUSREQ != 1'b1)
    begin  
      if (arb_lcdm0.mHBUSREQ == 1'b1)
      begin
        arb_lcdm0.mHGRANT = 1'b1;
        HMASTER=4'b0000;
        ns=bus_1_2;
        purple_flag = 1'b0; 
        flag= 8'b00000000; 
      end
      else 
      begin
        arb_lcdm0.mHGRANT = 1'b0;
        HMASTER=4'bx;
        ns=bus_1_2;
        purple_flag = 1'b1; 
        flag= 8'b00000000; 
      end
    end
    else 
      begin
        ns = bus_4;
        arb_lcdm0.mHGRANT = 1'b0;
        flag = 8'b0010000;
        purple_flag = 1'b0;
        HMASTER=4'bx;
     end
  end

  bus_1_2:
  begin 
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
    if(arb_lcdmtb4.mHBUSREQ != 1'b1)
    begin  
      if (arb_lcdm1.mHBUSREQ == 1'b1)
      begin
        arb_lcdm1.mHGRANT = 1'b1;
        HMASTER=4'b0001;
        ns=bus_0_3;
        purple_flag = 1'b0; 
        flag= 8'b00000000; 
      end
      else 
      begin 
        arb_lcdm1.mHGRANT = 1'b0;
        HMASTER=4'bx;
        ns=bus_0_3;
        purple_flag = 1'b1; 
        flag= 8'b00000000; 
      end
    end
    else 
      begin
        ns = bus_4;
        arb_lcdm1.mHGRANT = 1'b0;
        flag = 8'b0100000;
        purple_flag = 1'b0;
        HMASTER=4'bx;
     end
  end

  bus_0_3:
  begin 
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
    if(arb_lcdmtb4.mHBUSREQ != 1'b1)
    begin  
      if (arb_lcdm0.mHBUSREQ == 1'b1)
      begin
        arb_lcdm0.mHGRANT = 1'b1;
        HMASTER=4'b0000;
        ns=bus_3;
        purple_flag = 1'b0; 
        flag= 8'b00000000; 
      end
      else 
      begin 
        arb_lcdm0.mHGRANT = 1'b0;
        HMASTER=4'bx;
        ns=bus_3;
        purple_flag = 1'b1; 
        flag= 8'b00000000; 
      end
    end
    else 
      begin
        ns = bus_4;
        arb_lcdm0.mHGRANT = 1'b0;
        flag = 8'b10000000;
        purple_flag = 1'b0;
        HMASTER=4'bx;
      end
  end

  bus_4: // priority for bus_4 from professor's testbench
  begin
          arb_lcdm0.mHGRANT = 1'b0;
          arb_lcdm1.mHGRANT = 1'b0;
          arb_lcdm2.mHGRANT = 1'b0;
          arb_lcdm3.mHGRANT = 1'b0;
          arb_lcdmtb4.mHGRANT = 1'b0;
    if (arb_lcdmtb4.mHBUSREQ == 1'b1)
    begin //
      arb_lcdmtb4.mHGRANT = 1'b1;
      HMASTER=4'b0100;
      ns = bus_4;
      purple_flag = 1'b0;
      flag = 8'b10000000;
      case(flag)
        8'b00000001 : begin flag= 8'b00000000; ns = bus_0_1; end
        8'b00000010 : begin flag= 8'b00000000; ns = bus_1_1; end
        8'b00000100 : begin flag= 8'b00000000; ns = bus_2;   end
        8'b00001000 : begin flag= 8'b00000000; ns = bus_3;   end
        8'b00010000 : begin flag= 8'b00000000; ns = bus_0_2; end
        8'b00100000 : begin flag= 8'b00000000; ns = bus_1_2; end
        8'b01000000 : begin flag= 8'b00000000; ns = bus_0_3; end
        8'b10000000 : begin flag= 8'b00000000; ns = bus_4; end
      endcase
    end //
    else 
    begin 
      arb_lcdmtb4.mHGRANT = 1'b0;
      HMASTER=4'bx;
      ns=bus_0_1;
      purple_flag = 1'b1; 
      flag= 8'b00000000; 
    end
  end

 idle:
 begin
   if(RESET || (~arb_lcdm0.mHBUSREQ && ~arb_lcdm1.mHBUSREQ && ~arb_lcdm2.mHBUSREQ && ~arb_lcdm3.mHBUSREQ && ~arb_lcdmtb4.mHBUSREQ)) 
     begin
     ns =  idle;
     purple_flag = 1'b0;
     HMASTER = 1'bx; 
     flag= 8'bx; 
     arb_lcdm0.mHGRANT = 1'b0; arb_lcdm1.mHGRANT = 1'b0; arb_lcdm2.mHGRANT = 1'b0; arb_lcdm3.mHGRANT =1'b0; arb_lcdmtb4.mHGRANT = 1'b0;  
     end
     else 
     begin 
       ns = bus_3;
       purple_flag = 1'b1; 
       flag= 8'b00000000;
     end 
 end 

endcase   
end

always @(posedge CLK or posedge RESET)
begin
  if(RESET)
  begin
    HMASTER_delay <= 'bX;
  end
  else
  begin
    HMASTER_delay <= HMASTER;
  end
end
endmodule
