
// This is a top level module for the UVM Test Bench //


`timescale 1ns/10ps

//Include the interface file here//

`include "lcdif.sv"


package tb_pkg;

	`include "uvm.sv"

	import uvm_pkg::*;

	//Include all your test bench files in order//
	`include "test.sv"

endpackage : tb_pkg

module top();
	
	//Import all the packages required for the uvm simulation//
	
	import uvm_pkg::*;
	import tb_pkg::*;

	//Instantiate all the interfaces in the top module//
	
	AHBIF A();
	MEMIF T();
	MEMIF R();
	RAM128IF PAL();
	RAM256IF CRSR();
	LCDOUT LCD();

	//Generate Clock//

	initial begin
		A.HCLK = 1;
		forever #5 A.HCLK = ~A.HCLK;
	end
	
	//Apply Master Reset//
	initial begin
		A.HRESET = 1'b1;
		A.mHREADY = A.HREADY;
		##5;
		A.HRESET = 1'b0;
	end

	default clocking CB @(posedge(A.HCLK));

	endclocking : CB

	initial begin
	//	$dumpvars(9,top);
	//	$dumpfile("lcd.vcd");
		##10000000;
		$display("\n\n Ran out of clocks \n\n");
		$finish;
	end
	
	//Connect the Interface with the test bench//

	lcd L(A.AHBCLKS,A.AHBM,A.AHBS,R.F0,T.F0,PAL.R0,CRSR.R0,LCD.O0);
	
	mem128x32 PALMEM(A.HCLK,PAL.write,PAL.waddr,PAL.wdata,PAL.raddr,
		  	 PAL.rdata,PAL.raddr1,PAL.rdata1);
	
	mem256x32 CRSRMEM(A.HCLK,CRSR.write,CRSR.waddr,CRSR.wdata,
			  CRSR.raddr,CRSR.rdata,CRSR.raddr1,CRSR.rdata1);

	mem32x32 FIFOMEM0(A.HCLK,R.f0_waddr,R.f0_wdata,R.f0_write,
			  R.f0_raddr,R.f0_rdata);

	mem32x32 FIFOMEM1(A.HCLK,T.f0_waddr,T.f0_wdata,T.f0_write,
			  T.f0_raddr,T.f0_rdata);

	initial begin
		A.mHGRANT = 0;
	end		

	initial begin
		uvm_config_db #(virtual AHBIF)::set(null, "*",
				"AHBIF", A);
		
	/*	uvm_config_db #(virtual MEMIF)::set(null, "*",
				"MEMIF", T);
		
		uvm_config_db #(virtual MEMIF)::set(null, "*",
				"MEMIF", R);

		uvm_config_db #(virtual RAM128IF)::set(null, "*",
				"RAM128IF", PAL);

		uvm_config_db #(virtual RAM256IF)::set(null, "*",
				"RAM256IF", CRSR);*/
			
		uvm_config_db #(virtual LCDOUT)::set(null, "*",
				"LCDOUT", LCD);

		run_test("my_test");
		
		##100;
		$finish;
	end

endmodule : top

//Include the top level design files here//

`include "lcd.sv"
`include "mem128x32.sv"
`include "mem256x32.sv"
`include "mem32x32.sv"


