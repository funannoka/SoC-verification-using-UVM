//
// This is a simple memory model for the lcd controller
//
// This memory is a 32x32 that will be used for a single FIFO
//


module mem32x32(input logic clk,input logic [4:0] waddr, 
    input logic [31:0] wdata, input logic write,
    input logic [4:0] raddr, output logic [31:0] rdata);


reg [31:0] mem[0:31];

logic [31:0] m00,m01,m02,m03;
assign m00=mem[0];
assign m01=mem[1];
assign m02=mem[2];
assign m03=mem[3];

always @(*) begin
  rdata <= #4 mem[raddr];
end

always @(posedge(clk)) begin
  if(write) begin
    mem[waddr]<=#4 wdata;
  end
end

endmodule
