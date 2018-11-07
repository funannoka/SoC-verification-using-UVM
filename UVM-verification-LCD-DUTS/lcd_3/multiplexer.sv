
module multiplexer (CLK,RESET,HADDR0,HADDR1,HADDR2,HADDR3,HADDR4,HWDATA0,HWDATA1,HWDATA2,HWDATA3,HWDATA4,HWRITE0, HWRITE1, HWRITE2, HWRITE3, HWRITE4, HTRANS0, HTRANS1, HTRANS2, HTRANS3, HTRANS4, HSIZE0, HSIZE1, HSIZE2, HSIZE3, HSIZE4, HBURST0, HBURST1, HBURST2, HBURST3, HBURST4, mux_addr_out, mux_wout, mux_write, mux_trans, mux_size, mux_burst, HMASTER);

//haddr hwdata

input [31:0] HADDR0, HADDR1, HADDR2, HADDR3, HADDR4;
input [31:0] HWDATA0, HWDATA1, HWDATA2, HWDATA3, HWDATA4;
input HWRITE0, HWRITE1, HWRITE2, HWRITE3, HWRITE4;
input [1:0] HTRANS0, HTRANS1, HTRANS2, HTRANS3, HTRANS4;
input [2:0] HSIZE0, HSIZE1, HSIZE2, HSIZE3, HSIZE4;
input [2:0] HBURST0, HBURST1, HBURST2, HBURST3, HBURST4;
input CLK,RESET;
output logic [31:0] mux_wout;
output logic [31:0] mux_addr_out;
output logic mux_write;
output logic [1:0] mux_trans;
output logic [2:0] mux_size;
output logic [2:0] mux_burst;
input logic [3:0] HMASTER;
logic [3:0] HMASTER_delayed;

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
  case (HMASTER)
    4'b0000 : begin mux_addr_out = HADDR0; mux_write = HWRITE0; mux_trans = HTRANS0; mux_size = HSIZE0; mux_burst = HBURST0; end 
    4'b0001 : begin mux_addr_out = HADDR1; mux_write = HWRITE1; mux_trans = HTRANS1; mux_size = HSIZE1; mux_burst = HBURST1; end
    4'b0010 : begin mux_addr_out = HADDR2; mux_write = HWRITE2; mux_trans = HTRANS2; mux_size = HSIZE2; mux_burst = HBURST2; end
    4'b0011 : begin mux_addr_out = HADDR3; mux_write = HWRITE3; mux_trans = HTRANS3; mux_size = HSIZE3; mux_burst = HBURST3; end
    4'b0100 : begin mux_addr_out = HADDR4; mux_write = HWRITE4; mux_trans = HTRANS4; mux_size = HSIZE4; mux_burst = HBURST4; end
  endcase
end 

always @ (*)
begin
// A delayed version of the HMASTER is used to control the write data multiplexor 
    case(HMASTER_delayed)
     4'b0000 : mux_wout = HWDATA0 ; 
     4'b0001 : mux_wout = HWDATA1 ;
     4'b0010 : mux_wout = HWDATA2 ;
     4'b0011 : mux_wout = HWDATA3 ;
     4'b0100 : mux_wout = HWDATA4 ;
  //   default : IDLE
    endcase
end 
endmodule 
