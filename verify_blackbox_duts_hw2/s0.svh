 
import uvm_pkg::*;
`include "defs.svh"

class s0 extends uvm_sequence#(itm);
    `uvm_object_utils(s0);
    
function new (string name="s0");
    super.new(name);
endfunction: new

task body();
    itm tx;
    // DUT1
    
    tx=itm::type_id::create("tx");
    start_item(tx);
        tx.opcode=E_reset;
    finish_item(tx);
    
    repeat(30) begin
    tx=itm::type_id::create("tx");
    start_item(tx);
        tx.opcode= E_push;
        assert(tx.randomize());
    finish_item(tx);
    
    tx=itm::type_id::create("tx");
    start_item(tx);
        tx.opcode= E_pushcomplete;
        assert(tx.randomize());
    finish_item(tx);
    end
    
    tx=itm::type_id::create("tx");
    start_item(tx);
        tx.opcode=E_reset;
    finish_item(tx);
    
    repeat(30) begin
    tx=itm::type_id::create("tx");
    start_item(tx);
        tx.opcode= E_nop;
    finish_item(tx);
    
    tx=itm::type_id::create("tx");
    start_item(tx);
        tx.opcode= E_push;
        assert(tx.randomize());
    finish_item(tx);
    
    tx=itm::type_id::create("tx");
    start_item(tx);
        tx.opcode= E_pushcomplete;
        assert(tx.randomize());
    finish_item(tx);
    end
    
endtask: body

endclass: s0
  
//sequencer
class s0_seqr extends uvm_sequencer#(itm);
    `uvm_object_utils(s0_seqr);
    
function new (string name="s0_seqr");
    super.new(name);
endfunction: new
endclass: s0_seqr



//driver
class s0_drv extends uvm_driver#(itm);
     `uvm_component_utils(s0_drv)

     //Interface declaration
     virtual intf vif;

     function new(string name = "s0_drv", uvm_component par = null);
          super.new(name, par);
     endfunction: new

     function void build_phase(uvm_phase phase);
          super.build_phase(phase);
     void'(uvm_resource_db#(virtual intf)::read_by_name(.scope("ifs"), .name("intf"), .val(vif)));
     endfunction: build_phase

    function void connect_phase(uvm_phase phase);
    	super.connect_phase(phase);
	if (!uvm_config_db #(virtual intf)::get(null, "uvm_test_top",
        "intf", this.vif)) begin
          `uvm_error("connect", "intf interface not found")
         end 
	else
    	`uvm_info("S0_WR_DRIVER","This is Connect Phase - s0 driver", UVM_LOW)
     endfunction: connect_phase
    task run_phase(uvm_phase phase);
   	itm tx;
    	integer counter = 0;

  	vif.rst <= 0;
  	vif.complete <= 1;
  	vif.pushin <= 0;

 	// fork
  	forever
  	  begin
    	  seq_item_port.get_next_item(tx); // Gets the sequence_item
     	 if(tx.opcode == E_reset) begin
        	vif.rst <= 1;
//
       	 repeat(10) @(vif.cb);
       	 #2;
       	 vif.rst <= 0;
     	 end else if(tx.opcode == E_nop) begin
       	 vif.din <= tx.din;
       	 vif.complete <= 0;
       	 vif.pushin <= 0;
       	 repeat(3) @(vif.cb) #1;
      	end else begin
 	vif.din <= tx.din;
//
       // vif.complete <= 1;
        vif.pushin <= 1;
        @(vif.cb);
        while(counter << 6)begin
	 @(vif.cb);
        #1;
        counter = counter + 1;
	end
      end
      vif.complete <= 1;
      counter = 0;
      seq_item_port.item_done();
    end
 // join_none
endtask: run_phase
endclass: s0_drv


class s0_monitor1 extends uvm_monitor;
     `uvm_component_utils(s0_monitor1)

     uvm_analysis_port#(itm) mon1;
     itm tx;

     virtual intf viff;

     function new(string name = "s0_monitor1", uvm_component parent = null);
          super.new(name, parent);
     endfunction: new

     function void build_phase(uvm_phase phase);
	begin
          super.build_phase(phase);

          void'(uvm_resource_db#(virtual intf)::read_by_name (.scope("ifs"), .name("intf"), .val(viff)));
          mon1 = new(.name("mon1"), .parent(this));
	end
     endfunction: build_phase

function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual intf)::get(null, "uvm_test_top",
        "intf", this.viff)) begin
          `uvm_error("connect", "intf not found")
         end 
endfunction: connect_phase;
     task run_phase(uvm_phase phase);
	begin
 	 // fork 
            forever begin
 		@(posedge(viff.clk));
		if(viff.pushout && !viff.rst) begin
		  tx = new();
		  tx.dout = viff.dout;
		  mon1.write(tx);
		end
	    end
	//  join_none
	end
     endtask: run_phase
endclass: s0_monitor1


class s0_monitor2 extends uvm_monitor;
     `uvm_component_utils(s0_monitor2)

     uvm_analysis_port#(itm) mon2;

     virtual intf viff;

     itm tx;

     function new(string name = "s0_monitor2", uvm_component parent = null);
          super.new(name, parent);
     endfunction: new

     function void build_phase(uvm_phase phase);
	begin
          super.build_phase(phase);

          void'(uvm_resource_db#(virtual intf)::read_by_name(.scope("ifs"), .name("intf"), .val(viff)));
          mon2= new(.name("mon2"), .parent(this));
	end
     endfunction: build_phase

     function void connect_phase(uvm_phase phase);
      if (!uvm_config_db #(virtual intf)::get(null, "uvm_test_top",
        "intf", this.viff)) begin
          `uvm_error("connect", "intf not found")
         end 
     endfunction: connect_phase;

     task run_phase(uvm_phase phase);
	begin
 	//  fork 
            forever begin
 		@(posedge(viff.clk));
		if(viff.pushin && !viff.rst) begin
		  tx = new();
		  tx.dout = viff.dout;
		  mon2.write(tx);
		end
	    end
	//  join_none
	end
     endtask: run_phase
endclass: s0_monitor2

//scoreboard
class s0_scoreboard extends uvm_scoreboard;
     `uvm_component_utils(s0_scoreboard)

     uvm_analysis_export #(itm) sb_export_before;
     uvm_analysis_export #(itm) sb_export_after;

     uvm_tlm_analysis_fifo #(itm) input_fifo;
     uvm_tlm_analysis_fifo #(itm) res_fifo;

     itm tx;
     itm rx;

     function new(string name = "s0_scoreboard", uvm_component parent = null);
	begin
          super.new(name, parent);
          tx    = new("tx");
          rx    = new("rx");
	end
     endfunction: new

     function void build_phase(uvm_phase phase);
	begin
          super.build_phase(phase);
          sb_export_before    = new("sb_export_before", this);
          sb_export_after        = new("sb_export_after", this);

          input_fifo        = new("input_fifo", this);
          res_fifo        = new("res_fifo", this);
	end
     endfunction: build_phase

     function void connect_phase(uvm_phase phase);
          sb_export_before.connect(input_fifo.analysis_export);
          sb_export_after.connect(res_fifo.analysis_export);
     endfunction: connect_phase

     task run();
          forever begin
               input_fifo.get(tx);
               res_fifo.get(rx);
               compare();
          end
     endtask: run

     virtual function void compare();
          if(tx.din == rx.din) begin
               `uvm_info("compare", {"Test: Successful!"}, UVM_LOW);
          end else begin
               `uvm_info("compare", {"Test: Failed!"}, UVM_LOW);
          end
     endfunction: compare
endclass: s0_scoreboard


class agent1 extends uvm_agent;
  
  s0_drv driver1;
  s0 test_seq;
  s0_seqr seqr;
  s0_monitor1 monitor;
  s0_monitor2 resmon;
  s0_scoreboard scoreboard;


  `uvm_component_utils_begin(agent1)
    `uvm_field_object(driver1,UVM_ALL_ON)
    `uvm_field_object(test_seq,UVM_ALL_ON)
    `uvm_field_object(seqr,UVM_ALL_ON)
    `uvm_field_object(monitor,UVM_ALL_ON)
    `uvm_field_object(resmon,UVM_ALL_ON)
  `uvm_component_utils_end

  function void build_phase(uvm_phase phase);
   begin
    super.build_phase(phase);
    test_seq = s0::type_id::create("test_seq",this);
    seqr = s0_seqr::type_id::create("seqr",this);
    driver1 = s0_drv::type_id::create("driver1",this);
    monitor = s0_monitor1::type_id::create("s0_monitor1",this);
    resmon = s0_monitor2::type_id::create("s0_monitor2",this);
    scoreboard = s0_scoreboard::type_id::create("s0_scoreboard",this);
   end
   endfunction: build_phase;


  function void connect_phase(uvm_phase phase);
    driver1.seq_item_port.connect(seqr.seq_item_export);
    monitor.mon1.connect(scoreboard.input_fifo.analysis_export);
    resmon.mon2.connect(scoreboard.res_fifo.analysis_export);
  endfunction: connect_phase;
  task run_phase(uvm_phase phase);
    phase.raise_objection(this, "start of test");
    test_seq.start(seqr);
    fork
      test_seq.start(seqr);
    join
    phase.drop_objection(this, "end of test");
  endtask: run_phase;

  function new(string name = "agent1", uvm_component parent = null);
    super.new(name,parent);
  endfunction

  
endclass: agent1

//
// The environment
//

class env1 extends uvm_env;
  agent1 agnt;
  `uvm_component_utils_begin(env1)
    `uvm_field_object(agnt,UVM_ALL_ON)  
  `uvm_component_utils_end
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agnt = agent1::type_id::create("agnt",this); 
  endfunction: build_phase;
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase;
  
  function new(string name="env1", uvm_component parent=null);
    super.new(name,parent);
  endfunction: new;
endclass : env1
 

class s0_test extends uvm_test;


env1 environ;
`uvm_component_utils_begin(s0_test)
  `uvm_field_object(environ,UVM_ALL_ON)
`uvm_component_utils_end
function new(string name = "s0_test", uvm_component parent = null);
  super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
          super.build_phase(phase);
  environ = env1::type_id::create("env1",this);
endfunction: build_phase
 task run_phase(uvm_phase phase);
          s0 s0_seq;
 
          phase.raise_objection(.obj(this));
               s0_seq = s0::type_id::create("s0",this);
               assert(s0_seq.randomize());
               s0_seq.start(environ.agnt.seqr);
          phase.drop_objection(.obj(this));
     endtask: run_phase

endclass: s0_test



