
// This is a simple UVM Sequencer //

class seqr extends uvm_sequencer #(itm);

	`uvm_component_utils(seqr)

	function new(string name = "seqr", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

endclass : seqr
