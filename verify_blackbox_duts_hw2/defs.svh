//
// Definitions for the test bench
//
typedef enum {E_reset,E_push,E_nop,E_pushcomplete} icmd;


//
// The item sent by the sequence
//
class itm extends uvm_sequence_item;
`uvm_object_utils(itm)
icmd opcode;
rand reg [31:0] din;
 reg [31:0] dout;
function new(string name="itm");
    super.new(name);
endfunction : new

endclass : itm

//
// The message sent by the input monitor
// Only sends a message when there is a push
class idata extends uvm_sequence_item;
`uvm_object_utils(idata)
reg [31:0] value;
bit complete;

function new(string name="idata");
    super.new(name);
endfunction : new

endclass : idata

class exp extends uvm_sequence_item;
`uvm_object_utils(exp)
reg [31:0] value;
function new(string name="exp");
    super.new(name);
endfunction : new
endclass : exp

class resq extends uvm_sequence_item;
`uvm_object_utils(resq)
reg [31:0] value;
function new(string name="resq");
    super.new(name);
endfunction : new
endclass : resq
