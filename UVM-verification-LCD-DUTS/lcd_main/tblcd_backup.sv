// This is a simple test bench for LCD controller//

// Readin a .txt file //

module tb();

	string line;
	int fd;
	string a;
	int b,c;
	
	initial begin
      		fd = $fopen ("t0.txt", "r");
		while(!$feof(fd)) begin
			line = $fscanf (fd, "%s %h %h\n", a,b,c);
			if(a=="m" || a=="w") begin
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
		end
	end

endmodule : tb
