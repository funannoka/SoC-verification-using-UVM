task run_phase(uvm_phase phase);
		while(!eof) begin
			seq_item_port.get_next_item(typ);
			if(typ.ch == "m") begin
				assoc_array_m[typ.addr] = typ.data;
				$display("m=%h data=%h\n", typ.addr,typ.data);
				seq_item_port.item_done();
			end
			if(typ.ch == "w") begin
				//seq_item_port.get_next_item(typ);
				if(A.mHBUSREQ == 1'b0) begin
					@(posedge (A.HCLK)) begin
						A.mHGRANT <= 1'b0;
						A.HADDR <= typ.addr;
						A.HWRITE <= 1'b1;
						A.HSEL <= 1'b1;
						@(posedge (A.HCLK)) begin
							A.HWDATA <= typ.data;
						end
						$display("w=%h data=%h\n", typ.addr,typ.data);
					end
				end
				seq_item_port.item_done();
			end
			if(typ.ch == "f" || typ.ch == "n" || typ.ch == "a") begin
				seq_item_port.item_done();
			end

			
			
			if(typ.ch == "d") begin
			//seq_item_port.get_next_item(typ);
				assoc_array_d[typ.addr] = typ.data;
				$display("d=%6h\n", typ.data);
				seq_item_port.item_done();
			end
			if(typ.ch == "q") begin
				eof = 1'b1;
				$display("eof=%b\n",eof);
				seq_item_port.item_done();
			end
		end
		forever begin
			@(posedge A.HCLK) begin
				//seq_item_port.get_next_item(typ);

					if(A.mHBUSREQ == 1'b1) begin
						A.mHGRANT <= 1'b1;
						A.HSEL <= 1'b0;
				        	A.mHRDATA <= assoc_array_m[A.mHADDR];	
					end
					else begin
						A.mHGRANT <= 1'b0;
						A.HADDR <= typ.addr;
						A.HWRITE <= 1'b1;
						A.HSEL <= 1'b1;
					end	
			end
		end	
	endtask : run_phase

