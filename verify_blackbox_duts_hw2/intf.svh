//
// This is the DUT interface
//
interface intf();
reg clk,rst;
reg [31:0] din;
reg pushin;
reg complete;
reg pushout;
reg [31:0] dout;

clocking cb @(posedge(clk));
endclocking

modport mon_mp (clocking cb);

modport dut(input clk, input rst, input pushin, input complete,
    input din, output pushout, output dout);

endinterface : intf
