
// UVM Sequence Item //

class itm extends uvm_sequence_item;

	`uvm_object_utils(itm)
	string ch;
       	logic [31:0] addr, data;	
	function new(string name = "itm");
		super.new(name);
	endfunction : new

endclass : itm

class seq_item extends uvm_sequence_item;
	
	`uvm_object_utils(seq_item)
	bit flag;
	function new(string name ="seq_item");
		super.new(name);
	endfunction : new

endclass : seq_item

class value_a extends uvm_sequence_item;
	
	`uvm_object_utils(value_a)
	logic [31:0] a_val;
	bit a_flag;
	function new(string name = "value_a");
		super.new(name);
	endfunction : new

endclass : value_a

class value_f extends uvm_sequence_item;

	`uvm_object_utils(value_f)
	logic [31:0] f_val;
	bit f_flag;

	function new(string name = "value_f");
		super.new(name);
	endfunction : new

endclass : value_f

class ef extends uvm_sequence_item;

	`uvm_object_utils(ef)
	logic [31:0] expfval;

	function new(string name = "ef");
		super.new(name);
	endfunction : new

endclass

class value_n extends uvm_sequence_item;
	
	`uvm_object_utils(value_n)
	logic [31:0] n_val;
	bit n_flag;

	function new(string name = "value_n");
		super.new(name);
	endfunction : new

endclass : value_n
