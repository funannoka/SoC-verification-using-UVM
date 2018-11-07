// Sequences //
`timescale 1ns/10ps

class seq extends uvm_sequence #(itm);

	`uvm_object_utils(seq)
	itm typ;

	function new(string name = "seq");
		super.new(name);
	endfunction : new
	
	string line;
	logic [31:0] fd;
	string ch;
	int b,c;
	string testname;
	
	int f1=0,n1=0,a1=0,d1=0;
/*	
	int assoc_array_m[*];
	int assoc_array_w[*];
	int assoc_array_d[*];
*/
	virtual task body;
		begin
			typ = itm::type_id::create("typ");
			//start_item(typ);
			if($test$plusargs("FileTest=")) begin	
      				$value$plusargs("FileTest=%s", testname);
				`uvm_info("Sequence", {"Running Test:\t", $psprintf("%s\t",testname)}, UVM_LOW)
				fd = $fopen (testname, "r");
				if(!fd) begin
					`uvm_fatal("FATAL:", "File open failed");
				end
			end
			/*while(!$feof(fd)) begin
				line = $fscanf (fd, "%s %h %h\n", a,b,c);
				if(a=="m") begin
					$display("%s %h %h\n", a,b,c);
				end
				if(a=="w") begin
					$display("%s %h %h\n", a,b,c);
				end
				if(a=="f") begin
					$display("%s %1d\n", a,b);
				end
				if(a=="n") begin
					$display("%s %1d\n", a,b);
				end
				if(a=="a") begin
					$display("%s %d\n", a,b);
				end
				if(a=="d") begin
					$display("%s %6h\n", a,b);
				end
			end
			if(a=="q") begin
				$fclose(fd);
			end*/
			while(!$feof(fd)) begin
				line = $fscanf (fd, "%s\n", ch);
				if(ch === "m") begin
					line = $fscanf(fd, "%h %h\n", b,c);
					start_item(typ);
					typ.ch = ch;
					typ.addr = b;
					typ.data = c;
					finish_item(typ);
					//assoc_array_m[b] = c;
					//$display("%s %h %h\n", ch,b,c);
				end
				if(ch === "w") begin
					line = $fscanf(fd, "%h %h\n", b,c);
					start_item(typ);
					typ.ch = ch;
					typ.addr = b;
					typ.data = c;
					finish_item(typ);
					//assoc_array_w[b] = c;
					//$display("%s %h %h\n", ch,b,c);
				end
				if(ch === "f") begin
					line = $fscanf(fd, "%d\n", b);
					start_item(typ);
					typ.ch = ch;
					typ.data = b;
					finish_item(typ);
					//$display("%s %d\n", ch,b);
				end
				if(ch === "n") begin
					line = $fscanf(fd, "%d\n", b);
					start_item(typ);
					typ.ch = ch;
					typ.data = b;
					finish_item(typ);
					//$display("%s %1d\n", ch,b);
				end
				if(ch === "a") begin
					line = $fscanf(fd, "%d\n", b);
					start_item(typ);
					typ.ch = ch;
					typ.data = b;
					finish_item(typ);
					//$display("%s %1d\n", ch,b);
				end
				if(ch === "d") begin
					line = $fscanf(fd, "%6h", b);
					start_item(typ);
					typ.ch = ch;
					typ.data = b;
					finish_item(typ);
					//assoc_array_d[d1] = b;
					//$display("%s %6h\n", ch,b);
					//d1++;
				end
				if(ch === "q") begin
					start_item(typ);
					typ.ch = ch;
					finish_item(typ);
					//$fclose(fd);
				end
			end
			if(ch === "q") begin
				$fclose(fd);
			end

			//finish_item(typ);	
		end
	endtask : body

endclass : seq
