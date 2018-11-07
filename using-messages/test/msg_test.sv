`timescale 1ns/10ps


class msg;
string message;
reg [0:7] val;
endclass : msg


class src_scoreboard extends uvm_scoreboard;
 `uvm_component_utils(src_scoreboard)
   integer v;
     uvm_analysis_port#(msg) porta;
    msg m;
  function new(string name="src_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new
    
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
      porta = new("porta",this);
      m = new ();
  endfunction

  task run_phase (uvm_phase phase);
    phase.raise_objection(this,"src_scoreboard");
    for (v = 1; v <= 20; v += 1)begin
    m.message = "Ifunanya Nnoka, Message #";
    m.val = v;
    porta.write(m);
    #2;  
    end
    phase.drop_objection(this,"End");
  endtask : run_phase
endclass : src_scoreboard


class dst_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(dst_scoreboard)
  uvm_analysis_imp#(msg,dst_scoreboard) portb;
  msg rx;
  function new(string name="dst_scoreboard", uvm_component parent=null);
    super.new(name, parent);
    rx = new();
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    portb = new("portb",this); 
  endfunction

task run_phase (uvm_phase phase);
   super.run_phase(phase);
   #100;
   phase.raise_objection(this,"starting");
   forever begin
   portb.get(rx);
   write(rx);
  phase.drop_objection(this,"End");
    end
 endtask : run_phase

function void write (msg trx);
   `uvm_info("write",$sformatf("%s%d",trx.message,trx.val), UVM_LOW)
 endfunction : write
endclass : dst_scoreboard

class msg_env extends uvm_env;
  `uvm_component_utils(msg_env)
  dst_scoreboard sb_dest;
  src_scoreboard sb_src;
  function new(string name="msg_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sb_src = src_scoreboard::type_id::create("sb_src",this);
    sb_dest = dst_scoreboard::type_id::create("sb_dest",this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    sb_src.porta.connect(sb_dest.portb);
  endfunction
endclass : msg_env

class msg_test extends uvm_test;
   `uvm_component_utils(msg_test)  
   msg_env env;
  function new(string name="msg_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction
  
  function void  build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = msg_env::type_id::create("env",this);
  endfunction
endclass : msg_test


