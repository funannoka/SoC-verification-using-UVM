//
// This is a simple memory model for the lcd controller
//
// This memory is a 128x32 
//


module mem256x32(input logic clk, input logic write, input logic [7:0] waddr, 
    input logic [31:0] wdata, input logic [7:0] raddr, output logic [31:0] rdata,
    input logic [7:0] raddr1,output logic [31:0] rdata1);


reg [31:0] mem[0:255];

logic [31:0] m00,m01,m02,m03;
assign m00=mem[0];
assign m01=mem[1];
assign m02=mem[2];
assign m03=mem[3];

always @(*) begin
  rdata <= #4 mem[raddr];
  rdata1 <= #4 mem[raddr1];
end

always @(posedge(clk)) begin
  if(write) begin
    mem[waddr]<=#4 wdata;
  end
end

endmodule
