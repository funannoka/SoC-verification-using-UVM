// This is a UVM Test Class//

`include "seq_item.sv"
`include "seq.sv"
`include "seqr.sv"
`include "drv.sv"
`include "output_drv.sv"
`include "monitor.sv"
`include "scoreboard.sv"


class my_test extends uvm_test;

	`uvm_component_utils(my_test)

	seq test_seq;
	drv test_driver;
	seqr test_seqr;
	mon test_mon;
	sb test_sb;
	output_drv test_output_drv;

	function new(string name = "my_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		test_seq = seq::type_id::create("test_seq", this);
		test_driver = drv::type_id::create("test_driver", this);
		test_seqr = seqr::type_id::create("test_seqr", this);
		test_mon = mon::type_id::create("test_mon", this);
		test_sb = sb::type_id::create("test_sb", this);
		test_output_drv = output_drv::type_id::create("test_output_drv", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		test_driver.seq_item_port.connect(test_seqr.seq_item_export);
		test_mon.res.connect(test_sb.rcvd);
		//test_mon.rcvd_f.connect(test_sb.rcvd_f_val);
		test_mon.rcvd_f.connect(test_sb.rcvd_f_val.analysis_export);
		test_driver.exp_n_val.connect(test_sb.expctd_n_value);
		test_driver.put_flag.connect(test_output_drv.rec_flag);
		test_driver.put_a_value.connect(test_mon.a_val_flag);
		test_driver.exp_n_val.connect(test_mon.n_val_flag);
		test_driver.exp_f_val.connect(test_sb.exp_f_value.analysis_export);
		test_output_drv.seq_item_port.connect(test_seqr.seq_item_export);
		test_driver.exp_n_val.connect(test_output_drv.exp_n_val);
		test_output_drv.output_data.connect(test_sb.exp);
		if(!uvm_config_db #(virtual AHBIF)::get(this,"","AHBIF",
		  test_driver.A)) begin
			`uvm_error("connect", "AHBIF not found")
	   	end
	endfunction: connect_phase

	task run_phase(uvm_phase phase);
		test_seq = seq::type_id::create("test_seq");
		phase.raise_objection(this, "starting test_seq");
		test_seq.start(test_seqr);
		#10000000;
		phase.drop_objection(this, "finished test_seq");
	endtask : run_phase

endclass : my_test
