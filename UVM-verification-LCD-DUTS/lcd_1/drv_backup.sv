// Thi is a UVM Driver Class//

class drv extends uvm_driver #(itm);

	`uvm_component_utils(drv)
	
	itm typ;
	seq_item fl;
	value_a a_vl;

	uvm_blocking_put_port #(seq_item) put_flag;
	uvm_blocking_put_port #(value_a) put_a_value;

	virtual AHBIF A;

	function new(string name = "drv", uvm_component parent = null);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		put_flag = new("put_flag",this);
		put_a_value = new("put_a_value", this);
		`uvm_info("Driver","Driver Build Phase started", UVM_LOW);
	endfunction : build_phase

	function void connect_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual AHBIF)::get(null, "uvm_test.top",
		  "AHBIF", this.A)) begin
			`uvm_error("Connect", "AHBIF Not Found")
	  	end
			
	endfunction : connect_phase

	//Arbitrator Variables//
	logic tb_req, tb_gnt, eof=0;
	logic [31:0] assoc_array_m[*];
	logic [31:0] wa[$];
	logic [31:0] wd[$];
	logic [31:0] assoc_array_d[*];
	int f,a,n;
	int size_wa,size_chk;
	logic [31:0] HWDATA_P1;
	int size_chk_P1;
	logic [1:0] HTRANS_P1;
	
	task run_phase(uvm_phase phase);
		fl = new();
		a_vl = new();
		fork
		while(!eof) begin
			seq_item_port.get_next_item(typ);
		//	`uvm_info("recv",$sformatf("%s",typ.ch),UVM_LOW)
			if(typ.ch === "m") begin
				assoc_array_m[typ.addr] = typ.data;
			//	$display("m=%h %h\n", typ.addr, typ.data);	
			end
			if(typ.ch === "w") begin
				wa.push_back(typ.addr);
				wd.push_back(typ.data);	
			//	$display("w=%h %h size=%d\n", typ.addr, typ.data, wa.size());	
				size_wa = wa.size();
				//$display("size_wa=%d\n", size_wa);
				size_chk = size_wa;
				size_chk_P1 = size_wa;
			end
			if(typ.ch === "f") begin
				f = typ.data;	
				//$display("f=%5h\n", typ.data);	
			end
			if(typ.ch === "n") begin
				n = typ.data;
				//$display("n=%d\n", typ.data);	
			end
			if(typ.ch === "a") begin
				a = typ.data;
				//$display("a=%d\n", typ.data);	
				fl.flag = 1;
				a_vl.a_val = typ.data;
				put_a_value.put(a_vl);
				`uvm_info("sent","a_vl",UVM_LOW)
				put_flag.put(fl);
				`uvm_info("sent","fl",UVM_LOW)
				eof = 1;
			end
			if(typ.ch === "d") begin
				assoc_array_d[typ.addr] = typ.data;
				//$display("d=%6h\n", typ.data);	
			end
			if(typ.ch === "q") begin
				eof = 1'b1;
			end
			seq_item_port.item_done();
			end
			
			A.HADDR <= 32'd0;
				forever begin
					@(posedge A.HCLK) begin
						if(A.HRESET === 1'b1) begin
							A.HADDR <= 32'd0;
						end 
						else begin
							if(A.mHBUSREQ === 1'b1) begin
								A.mHGRANT <= #1 1'b1;
								A.mHREADY <= #1 1'b1;
							end	
							if(A.mHBUSREQ === 1'b0) begin
								A.mHGRANT <= #1 1'b0;
								HTRANS_P1 <= 2'b00;
								A.HTRANS <= #1 HTRANS_P1;
							end
							if(/*(A.mHBUSREQ === 1'b0) &&*/ (size_chk !== 0)/* && (A.mHTRANS === 2'b00)*/) begin
								A.HSEL <= #1 1'b1;
								A.HBURST <= #1 3'b000;
								A.HWRITE <= #1 1'b1;
								A.HTRANS <= #1 2'b10;
								if(size_chk_P1 !== 0) begin
									A.HADDR <= #1 wa.pop_front();
								end
								HWDATA_P1 <= wd.pop_front();
								A.HWDATA <= #1 HWDATA_P1;
								size_chk_P1 <= size_chk_P1 - 1; 
								size_chk <= size_chk_P1;
								//$display($time, "size_chk=%d size_chk_P1=%d\n", size_chk, size_chk_P1);
							end
							if(size_chk_P1 === 0) begin
								A.HSEL <= #1 1'b0;
								A.HTRANS <= #1 2'b00;
								//A.mHREADY <= #1 1'b0;
							end
							if(A.mHGRANT === 1'b1) begin
								A.mHRDATA <= #1 assoc_array_m[A.mHADDR];
							end
						end
					end
				end
		join_none	

	endtask : run_phase
		
endclass : drv
