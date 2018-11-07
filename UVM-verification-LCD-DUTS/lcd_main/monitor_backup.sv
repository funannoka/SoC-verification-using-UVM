// This is a simple monitor //

class mon extends uvm_monitor;

	`uvm_component_utils(mon)

	uvm_analysis_port #(itm) res;
	
	//Virtual interface//
	virtual LCDOUT LCD;
	virtual AHBIF A;

	logic LCDM;
	logic LCDFP;
	logic LCDLP;
	logic LCDPWR;
	int LCDVD[$];

	itm smpl;
	int a_vl;
	
	uvm_blocking_put_imp #(value_a, mon) a_val_flag;	

	//Constructor Function//
	function new(string name = "mon" , uvm_component parent);
		super.new(name, parent);
	endfunction : new

	//Monitor Build Phase//
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		a_val_flag = new("a_val_flag", this);
		`uvm_info("Monior", "Build Phase", UVM_LOW)
		res = new("res", this);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		`uvm_info("Monitor", "Connect_phase", UVM_LOW)
		if(!uvm_config_db #(virtual LCDOUT)::get(null, "uvm_test_top",
		   "LCDOUT", this.LCD)) begin
			`uvm_error("Monior Connect", "LCDOUT Not Found")
	   	end
		if(!uvm_config_db #(virtual AHBIF)::get(null, "uvm_test_top",
		   "AHBIF", this.A)) begin
			`uvm_error("Monitor Connect", "AHBIF Not Found")
	   	end
	endfunction : connect_phase

	logic [31:0] a;
	longint count0=0;
	longint count1=0;
	logic setflag=0;
	time t1,t0,t2;
	logic start=0;
	longint final_count=0;

	task run_phase(uvm_phase phase);
		//a = a_vl;
		//$display("a=%d\n",a);	
		fork
			forever begin
				//a_vl = new();
				//if(a_vl > 0) begin
				@(posedge (LCD.LCDDCLK)) begin
					if(a_vl > 0) begin
						smpl = new();
						if(LCD.LCDENA_LCDM === 1'b1) begin
							LCDVD.push_back(LCD.LCDVD);
							smpl.data = LCD.LCDVD;
							res.write(smpl);
							a_vl = a_vl - 1;
							//$display("a_vl=%d\n",a_vl);
							//$display("Monitor data=%6h\n",smpl.data);	
						end
					end
				end
			end
			forever begin
				@(posedge (A.HCLK)) begin
					if((count1 < 2) && start === 1'b1) begin
						count0 = count0 + 1;
						//$display($time, "count0=%d\n", count0);
					end
					if(count1 === 2) begin
						final_count = count0;
						//$display($time, "final_count=%d\n", final_count);
						break;
					end
				end
			end
			forever begin
				@(posedge (LCD.LCDFP)) begin
					start = 1'b1;
					if(count1 === 2) begin
						//$display($time, "count1=%d\n", count1);
						//t1 = $time;
						//t2 = (t1 - t0)/10;
						//$display("%d - %d = %d\n",t1, t0, t2);
						setflag = 1'b1;
						break;
					end
					else begin
						//setflag = 1'b0;
						count1 = count1 + 1;
						//$display($time, "count1=%d\n", count1);
						//t0 =$time;
					end
				end
			end
			join_none
	endtask : run_phase

	task put(value_a inp);
		a_vl = inp.a_val;
		//$display("a_vl=%d\n",a_vl);
	endtask : put
	

endclass : mon
