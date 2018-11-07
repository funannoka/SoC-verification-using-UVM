module decoder(HADDR, HSEL);
input [31:0] HADDR;
output logic [4:0] HSEL;
//output HRESP, HSEL;
//HSEL [4:0] ---->>>> combinational decode of address bus (high order address signal),default slave for remaining addr (error if non-seq or seq),default slave if receives idle or busy should give okay.
//controls read data n resp sign mux
//HMASTER controls addr & control mux.
//delayed HMASTER controls write data mux.
//hresp mux

always @(*)
begin
    if(HADDR == 32'hE01FC1B8 || (HADDR >= 32'hFFE10000 && HADDR <= 32'hFFE20000))  // LCD controller base address 0
    begin
      HSEL = 5'b00001; 
    end
    else if(HADDR == 32'hE11FC1B8 || (HADDR >= 32'hFEE10000 && HADDR <= 32'hFEE20000))  // LCD controller base address 1
    begin
      HSEL = 5'b00010;  
    end
    else if(HADDR == 32'hE21FC1B8 || (HADDR >= 32'hFDE10000 && HADDR <= 32'hFDE20000))  // LCD controller base address 2
    begin
      HSEL = 5'b00100; 
    end  
    else if(HADDR == 32'hE31FC1B8 || (HADDR >= 32'hFCE10000 && HADDR <= 32'hFCE20000))  // LCD controller base address 3
    begin
      HSEL = 5'b01000; 
    end
    else //LCD controller base address for 4 or prof's testbench 
    begin
      HSEL = 5'b10000;   
    end
end 
endmodule
