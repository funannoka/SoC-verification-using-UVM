
// This is simple driver to send the output values to the scoreboard//

class output_drv extends uvm_driver #(itm);

	`uvm_component_utils(output_drv)

	itm typ, snt;
	bit fl;

	uvm_blocking_put_imp #(seq_item,output_drv) rec_flag;
	uvm_analysis_imp #(value_n,output_drv) exp_n_val;

	function new(string name = "output_drv", uvm_component parent = null);
		super.new(name, parent);	
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		rec_flag=new("rec_flag",this);
		exp_n_val = new("exp_n_val", this);
		output_data=new("output_data",this);
		`uvm_info("Ouput Driver", "Driver Build Phase started", UVM_LOW)
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		`uvm_info("Output Driver", "Driver Connect Phase started", UVM_LOW)
	endfunction : connect_phase

	int data;
	logic eof=0;
	logic [31:0] nv_val;
	int i=0;

	uvm_analysis_port #(itm) output_data;

	function write(value_n nv);
		nv_val = nv.n_val;
		//$display("Output Driver nv_val=%d\n", nv_val);	
	endfunction : write
	
	task run_phase(uvm_phase phase);
		fl=0;
	//	while(!eof) begin
			wait (fl==1);
		fork
			forever begin
				snt = new();
				seq_item_port.get_next_item(typ);
				if(typ.ch == "d") begin
					snt.data = typ.data;
					output_data.write(snt);
					//$display("Output Drv Data=%6h\n",typ.data);
				end
				seq_item_port.item_done();
			end
		join_none
	endtask : run_phase

	task put(seq_item a);
		fl=a.flag;
	endtask: put
	
endclass : output_drv
