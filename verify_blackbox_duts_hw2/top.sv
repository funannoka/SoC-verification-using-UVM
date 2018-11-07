// A top level file for the UVM simulation
//
`timescale 1ns/10ps
`include "intf.svh"
`include "s0.svh"
//`include "defs.svh"
//`include "trand.svhp"

module top();
import uvm_pkg::*;
//import trand::*;

intf i0();

initial begin
  i0.clk=0;
  i0.rst=0;
  repeat(100000) begin
    #5 i0.clk=0;
    #5 i0.clk=1;
  end
  $display("\n\n     Oh My, we ran out of clocks\n\n");
  $finish;
end

dut d(i0.dut);

initial
  begin
    uvm_config_db #(virtual intf)::set(null, "*", "intf" , i0);
    #0;
    run_test("s0_test");
  $display("\n  din = %h,dout = %h\n\n",i0.din,i0.dout);
    // should never get here unless running old uvm
    #100;
    $finish;
  end

initial begin
//  $dumpfile("dut.vpd");
//  $dumpvars(9,top);

end


endmodule : top

