module rd_mux(HSEL, HRDATA0, HRDATA1, HRDATA2, HRDATA3, HRDATA4, HRESP0, HRESP1, HRESP2, HRESP3, HRESP4, HREADY0, HREADY1, HREADY2, HREADY3, HREADY4, rd_mux_out, resp_mux_out, CLK, RESET, HMASTER, mHRDATA0, mHRDATA1, mHRDATA2, mHRDATA3, mHRDATA4, mHRESP0, mHRESP1, mHRESP2, mHRESP3, mHRESP4);
input [4:0] HSEL;
input CLK, RESET;
input [3:0] HMASTER;
input [31:0]HRDATA0,HRDATA1,HRDATA2,HRDATA3,HRDATA4;
output logic [31:0] mHRDATA0,mHRDATA1,mHRDATA2,mHRDATA3,mHRDATA4;
input [1:0]HRESP0,HRESP1,HRESP2,HRESP3,HRESP4;
output logic [1:0] mHRESP0,mHRESP1,mHRESP2,mHRESP3,mHRESP4;
input HREADY0,HREADY1,HREADY2,HREADY3,HREADY4;
logic mHREADY0,mHREADY1,mHREADY2,mHREADY3,mHREADY4,ready_mux_out;
output logic [31:0] rd_mux_out;
output logic [1:0] resp_mux_out;
logic [3:0] HMASTER_delayed;

always @(*)
begin
  case (HSEL)
    5'b00001:begin rd_mux_out = HRDATA0; resp_mux_out = HRESP0; ready_mux_out = HREADY0; end
    5'b00010:begin rd_mux_out = HRDATA1; resp_mux_out = HRESP1; ready_mux_out = HREADY1; end
    5'b00100:begin rd_mux_out = HRDATA2; resp_mux_out = HRESP2; ready_mux_out = HREADY2; end
    5'b01000:begin rd_mux_out = HRDATA3; resp_mux_out = HRESP3; ready_mux_out = HREADY3; end
    5'b10000:begin rd_mux_out = HRDATA4; resp_mux_out = HRESP4; ready_mux_out = HREADY4; end
  endcase
end


always @(posedge CLK or posedge RESET)
begin
  if(RESET)
  begin
    HMASTER_delayed <= 'bX;
  end
  else
  begin
    HMASTER_delayed <= HMASTER;
  end
end


always @ (*)
begin
// A delayed version of the HMASTER is used to control the write data multiplexor 
#0    case(HMASTER_delayed)
     4'b0000 : mHRDATA0 = rd_mux_out ; 
     4'b0001 : mHRDATA1 = rd_mux_out ;
     4'b0010 : mHRDATA2 = rd_mux_out ;
     4'b0011 : mHRDATA3 = rd_mux_out ;
     4'b0100 : mHRDATA4 = rd_mux_out ;
  //   default : IDLE
    endcase
end 


always @ (*)
begin
// A delayed version of the HMASTER is used to control the write data multiplexor 
#0    case(HMASTER_delayed)
     4'b0000 : mHRESP0 = resp_mux_out ; 
     4'b0001 : mHRESP1 = resp_mux_out ;
     4'b0010 : mHRESP2 = resp_mux_out ;
     4'b0011 : mHRESP3 = resp_mux_out ;
     4'b0100 : mHRESP4 = resp_mux_out ;
  //   default : IDLE
    endcase
end 

always @ (*)
begin
// A delayed version of the HMASTER is used to control the write data multiplexor 
#0    case(HMASTER)
     4'b0000 : mHREADY0 = ready_mux_out ; 
     4'b0001 : mHREADY1 = ready_mux_out ;
     4'b0010 : mHREADY2 = ready_mux_out ;
     4'b0011 : mHREADY3 = ready_mux_out ;
     4'b0100 : mHREADY4 = ready_mux_out ;
  //   default : IDLE
    endcase
end 



endmodule
