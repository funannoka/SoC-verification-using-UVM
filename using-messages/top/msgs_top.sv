
`timescale 1ns/10ps

module msgs_top ();
import uvm_pkg::*;
`include "msg_test.sv"
`include "uvm_macros.svh"
//`include "./../package/msgs_pkg.sv"

  initial 
     begin
    run_test("msg_test"); 
    #100
 $finish; 
  end 

endmodule : msgs_top
