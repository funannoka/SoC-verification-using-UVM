
// This is a simple UVM Scoreboard //

class sb extends uvm_scoreboard;

	`uvm_component_utils(sb)

	uvm_analysis_port #(itm) exp;//inp;
	uvm_analysis_port #(itm) rcvd;//resp;
	uvm_nonblocking_put_imp #(itm,sb) nbimp;

	uvm_tlm_analysis_fifo #(value_f) rcvd_f_val;
	uvm_tlm_analysis_fifo #(ef) exp_f_value;

	uvm_analysis_imp #(value_n,sb) expctd_n_value;

	uvm_tlm_analysis_fifo #(itm) exp_res_fifo;//inp_fifo;
	uvm_tlm_analysis_fifo #(itm) rcvd_res_fifo;//res_fifo;

	itm ip, typ;
	value_f f,fin;
	ef exf;
	value_n n;

	//Declare the local signals here//
	
	function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function bit can_put();
		return 1;
	endfunction : can_put

	function bit try_put(itm req);
		return 1;
	endfunction : try_put

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		ip = new();
		typ = new();
		fin = new();
		f = new();
		n = new();
		exf = new();	
		exp = new("exp", this);
		exp_res_fifo = new("exp_res_fifo", this);
		rcvd = new("rcvd", this);
		rcvd_res_fifo = new("rcvd_res_fifo", this);
		nbimp = new("nbimp", this);
		rcvd_f_val = new("rcvd_f_val", this);
		exp_f_value = new("exp_f_value", this);
		expctd_n_value = new("expctd_n_value", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		exp.connect(exp_res_fifo.analysis_export);
		rcvd.connect(rcvd_res_fifo.analysis_export);

		`uvm_info("Connect", "Scoreboard Connect Phase", UVM_LOW)
	endfunction : connect_phase

	logic [31:0] a, b, c, d;
	int ex[$];
	int rc[$];
	logic [31:0] fval,exfval,exn;
	int finp;
	int i=0;
	
	function write(value_n nvalue);
		exn = nvalue.n_val;
		//$display("exn=%d\n", exn);	
	endfunction : write 
	
	task run_phase(uvm_phase phase);
		fork
			forever begin
				exp_res_fifo.get(typ);
				rcvd_res_fifo.get(ip);
				exp_res_fifo.try_put(typ);	
				//$display("exp=%6h\n",typ.data);
				//$display("rcvd=%6h\n",ip.data);
				a = typ.data;
				b = ip.data;
				//$display("a=%6h\n b=%6h\n", a,b);
				ex.push_back(a);
				rc.push_back(b);	
				
				c = ex.pop_front();
				d = rc.pop_front();

				if(a !== b) begin
					`uvm_error("Scoreboard run_phase", {"itm mismatch:\t", "expected:", $psprintf("%6h\t",a), "received:", $psprintf("%6h",b)})
				end
			end
			
			forever begin
			   	exp_f_value.get(exf);
				exfval = exf.expfval;
				rcvd_f_val.get(f);
				fval = f.f_val;
				exp_f_value.try_put(exf);
				//$display("fval=%d\n", fval);
				//$display("exfval=%d\n", exf.expfval);
				if(exfval !== fval) begin
					`uvm_error("Run_phase", {"itm mismatch:\t", "expected:", $psprintf("%d\t",exfval), "received:", $psprintf("%d",fval)})
				end
				else begin
					`uvm_info("Run_phase", {"itm matched:\t", "expected:", $psprintf("%d\t",exfval), "received:", $psprintf("%d",fval)}, UVM_LOW)
				end
				//break;
			end
			/*forever begin
			   	exp_f_value.get(exf);
				exfval = exf.expfval;
				$display("exfval=%d\n", exfval);
			end*/
		join_none
	endtask : run_phase

	
	
	function void extract_phase(uvm_phase phase);
		super.extract_phase(phase);
	endfunction : extract_phase


endclass : sb
