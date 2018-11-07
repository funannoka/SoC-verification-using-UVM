//AHB slave and config registers
`include "lcd.register.sv"

module ahbslave(
	AHBIF.AHBS ahbs,
	AHBIF.AHBCLKS ahbclks,
	REGISTERS regif,
	RAM128IF.R0 ram128if,
	RAM256IF.R0 ram256if
);

/////////ports from interface
logic HCLK;
logic HRESET;
logic HREADY;
logic [1:0] HRESP;
logic [31:0] HRDATA;
logic [31:0] HWDATA;
logic [1:0] HTRANS;
logic [31:0] HADDR;
logic HWRITE;
logic [2:0] HSIZE;
logic [2:0] HBURST;
logic HSEL;         // slave select

/////////internal nets
logic [1:0] htrans0;
logic [31:0] haddr0;
logic hwrite0;
logic [31:0] wire01[0:127];
logic [31:0] wire02[0:255];

///////ram signals
logic [6:0] ramwaddr;
logic ramwrite;
logic [31:0] ramwdata;

logic [7:0] ramwaddr1;
logic ramwrite1;
logic [31:0] ramwdata1;

/////////registers declare
LCD_CFG 			reg0; //LCD Configuration and clocking control, 0xE01FC1B8
LCD_TIMH 		reg1; //Horizontal Timing Control register, 0xFFE10000
LCD_TIMV 		reg2; //Vertical Timing Control register, 0xFFE10004
LCD_POL 			reg3; //Clock and Signal Polarity Control register, 0xFFE10008
LCD_LE 			reg4; //Line End Control register, 0xFFE1000C
LCD_UPBASE 		reg5; //Upper Panel Frame Base Address register, 0xFFE10010
LCD_LPBASE 		reg6; //Lower Panel Frame Base Address register, 0xFFE10014
LCD_CTRL 		reg7; //LCD Control register, 0xFFE10018 
LCD_INTMSK 		reg8; //Interrupt Mask register, 0xFFE1001C
LCD_INTRAW 		reg9; //Raw Interrupt Status register, 0xFFE10020
LCD_INTSTAT 	reg10; //Masked Interrupt Status register, 0xFFE10024
LCD_INTCLR 		reg11; //Interrupt Clear register, 0xFFE10028
LCD_UPCURR		reg12; //Upper Panel Current Address Value register, 0xFFE1002C
LCD_LPCURR 		reg13; //Lower Panel Current Address Value register, 0xFFE10030
//LCD_PAL			reg14[0:127]; //256x16-bit Color Palette registers, 0xFFE10200 - 0xFFE103FC
//CRSR_IMG			reg15[0:255]; //Cursor Image registers, 0xFFE10800 - 0xFFE10BFC
CRSR_CRTL		reg16; //Cursor Control register, 0xFFE10C00
CRSR_CFG 		reg17; //Cursor Configuration register, 0xFFE10C04
CRSR_PAL0		reg18; //Cursor Palette register 0, 0xFFE10C08
CRSR_PAL1		reg19; //Cursor Palette register 1, 0xFFE10C0C
CRSR_XY 			reg20; //Cursor XY Position register, 0xFFE10C10
CRSR_CLIP		reg21; //Cursor Clip Position register, 0xFFE10C14
CRSR_INTMSK		reg22; //Cursor Interrupt Mask register, 0xFFE10C20
CRSR_INTCLR 	reg23; //Cursor Interrupt Clear register, 0xFFE10C24
CRSR_INTRAW 	reg24; //Cursor Raw Interrupt Status register, 0xFFE10C28
CRSR_INTSTAT 	reg25; //Cursor Masked Interrupt Status register, 0xFFE10C2C

genvar i;
  
/////////////resolve interface
assign HCLK = ahbclks.HCLK;
assign HRESET = ahbclks.HRESET;
assign ahbs.HREADY = HREADY;
assign ahbs.HRESP = HRESP;
assign ahbs.HRDATA = HRDATA;
assign HTRANS = ahbs.HTRANS;
assign HADDR = ahbs.HADDR;
assign HWRITE = ahbs.HWRITE;
assign HSIZE = ahbs.HSIZE;
assign HBURST = ahbs.HBURST; 
assign HWDATA = ahbs.HWDATA;
assign HSEL = ahbs.HSEL;

//assign registers interface
assign regif.reg0 = reg0; //LCD Configuration and clocking control, 0xE01FC1B8
assign regif.reg1 = reg1; //Horizontal Timing Control register, 0xFFE10000
assign regif.reg2 = reg2; //Vertical Timing Control register, 0xFFE10004
assign regif.reg3 = reg3; //Clock and Signal Polarity Control register, 0xFFE10008
assign regif.reg4 = reg4; //Line End Control register, 0xFFE1000C
assign regif.reg5 = reg5; //Upper Panel Frame Base Address register, 0xFFE10010
assign regif.reg6 = reg6; //Lower Panel Frame Base Address register, 0xFFE10014
assign regif.reg7 = reg7; //LCD Control register, 0xFFE10018 
assign regif.reg8 = reg8; //Interrupt Mask register, 0xFFE1001C
assign regif.reg9 = reg9; //Raw Interrupt Status register, 0xFFE10020
assign regif.reg10 = reg10; //Masked Interrupt Status register, 0xFFE10024
assign regif.reg11 = reg11; //Interrupt Clear register, 0xFFE10028
assign regif.reg12 = reg12; //Upper Panel Current Address Value register, 0xFFE1002C
assign regif.reg13 =	reg13; //Lower Panel Current Address Value register, 0xFFE10030
//assign regif.reg14 = reg14; //256x16-bit Color Palette registers, 0xFFE10200 - 0xFFE103FC
//assign regif.reg15 = reg15; //Cursor Image registers, 0xFFE10800 - 0xFFE10BFC
assign regif.reg16 = reg16; //Cursor Control register, 0xFFE10C00
assign regif.reg17 =	reg17; //Cursor Configuration register, 0xFFE10C04
assign regif.reg18 =	reg18; //Cursor Palette register 0, 0xFFE10C08
assign regif.reg19 =	reg19; //Cursor Palette register 1, 0xFFE10C0C
assign regif.reg20 =	reg20; //Cursor XY Position register, 0xFFE10C10
assign regif.reg21 =	reg21; //Cursor Clip Position register, 0xFFE10C14
assign regif.reg22 =	reg22; //Cursor Interrupt Mask register, 0xFFE10C20
assign regif.reg23 =	reg23; //Cursor Interrupt Clear register, 0xFFE10C24
assign regif.reg24 =	reg24; //Cursor Raw Interrupt Status register, 0xFFE10C28
assign regif.reg25 =	reg25; //Cursor Masked Interrupt Status register, 0xFFE10C2C

//resolve ram interface signals
assign ram128if.waddr = ramwaddr;
assign ram128if.write = ramwrite;
assign ram128if.wdata = ramwdata;

assign ram256if.waddr = ramwaddr1;
assign ram256if.write = ramwrite1;
assign ram256if.wdata = ramwdata1;
 
//ahb slave pipeline registers
always @ (posedge HCLK or posedge HRESET)
	if (HRESET) begin
		haddr0  <= #1 0;
		hwrite0 <= #1 1'b0;
		htrans0 <= #1 2'b00;
	end
	else begin
		if (HREADY) begin
			haddr0  <= #1 HADDR;
			hwrite0 <= #1 HWRITE;
			htrans0 <= #1 HTRANS;
		end
	end

//generate block for wire zeros
//generate
//	for(i=0; i<128; i=i+1) begin: f0
//		assign wire01[i] = 32'b0;
//	end
//	
//	for(i=0; i<256; i=i+1) begin: f1
//		assign wire02[i] = 32'b0;
//	end
//endgenerate
   
//write operation for registers
always @ (posedge HCLK or posedge HRESET) begin
	if (HRESET) begin
		reg0 <= #1 32'b0;
		reg1 <= #1 32'b0;
		reg2 <= #1 32'b0;
		reg3 <= #1 32'b0;
		reg4 <= #1 32'b0;
		reg5 <= #1 32'b0;
		reg6 <= #1 32'b0;
		reg7 <= #1 32'b0;
		reg8 <= #1 32'b0;
		reg9 <= #1 32'b0;
		reg10 <= #1 32'b0;
		reg11 <= #1 32'b0;
		reg12 <= #1 32'b0;
		reg13 <= #1 32'b0;
//		reg14 <= wire01;
//		reg15 <= wire02;
		reg16 <= #1 32'b0;
		reg17 <= #1 32'b0;
		reg18 <= #1 32'b0;
		reg19 <= #1 32'b0;
		reg20 <= #1 32'b0;
		reg21 <= #1 32'b0;
		reg22 <= #1 32'b0;
		reg23 <= #1 32'b0;
		reg24 <= #1 32'b0;
		reg25 <= #1 32'b0;
	end
	else if (HSEL && hwrite0 && ((htrans0==2'b10) || (htrans0==2'b11))) begin
		if(haddr0[15:0]==16'hC1B8) reg0 <= #1 HWDATA;//if(haddr0==32'hE01FC1B8) reg0 <= HWDATA;
		if(haddr0[15:0]==16'h0000) reg1 <= #1 HWDATA;//if(haddr0==32'hFFE10000) reg1 <= HWDATA;
		if(haddr0[15:0]==16'h0004) reg2 <= #1 HWDATA;//if(haddr0==32'hFFE10004) reg2 <= HWDATA;
		if(haddr0[15:0]==16'h0008) reg3 <= #1 HWDATA;//if(haddr0==32'hFFE10008) reg3 <= HWDATA;
		if(haddr0[15:0]==16'h000C) reg4 <= #1 HWDATA;//if(haddr0==32'hFFE1000C) reg4 <= HWDATA;
		if(haddr0[15:0]==16'h0010) reg5 <= #1 HWDATA;//if(haddr0==32'hFFE10010) reg5 <= HWDATA;
		if(haddr0[15:0]==16'h0014) reg6 <= #1 HWDATA;//if(haddr0==32'hFFE10014) reg6 <= HWDATA;
		if(haddr0[15:0]==16'h0018) reg7 <= #1 HWDATA;//if(haddr0==32'hFFE10018) reg7 <= HWDATA;
		if(haddr0[15:0]==16'h001C) reg8 <= #1 HWDATA;//if(haddr0==32'hFFE1001C) reg8 <= HWDATA;
		if(haddr0[15:0]==16'h0020) reg9 <= #1 HWDATA;//if(haddr0==32'hFFE10020) reg9 <= HWDATA;
		if(haddr0[15:0]==16'h0024) reg10 <= #1 HWDATA;//if(haddr0==32'hFFE10024) reg10 <= HWDATA;
		if(haddr0[15:0]==16'h0028) reg11 <= #1 HWDATA;//if(haddr0==32'hFFE10028) reg11 <= HWDATA;
		if(haddr0[15:0]==16'h002C) reg12 <= #1 HWDATA;//if(haddr0==32'hFFE1002C) reg12 <= HWDATA;
		if(haddr0[15:0]==16'h0030) reg13 <= #1 HWDATA;//if(haddr0==32'hFFE10030) reg13 <= HWDATA;
//		if((haddr0>=32'hFFE10200) && (haddr0<= #1 32'hFFE103FC)) reg14[((haddr0-32'hFFE10200)>>2)] <= HWDATA;
//		if((haddr0>=32'hFFE10800) && (haddr0<= #1 32'hFFE10BFC)) reg15[((haddr0-32'hFFE10800)>>2)] <= HWDATA;
		if(haddr0[15:0]==16'h0C00) reg16 <= #1 HWDATA;//if(haddr0==32'hFFE10C00) reg16 <= HWDATA;
		if(haddr0[15:0]==16'h0C04) reg17 <= #1 HWDATA;//if(haddr0==32'hFFE10C04) reg17 <= HWDATA;
		if(haddr0[15:0]==16'h0C08) reg18 <= #1 HWDATA;//if(haddr0==32'hFFE10C08) reg18 <= HWDATA;
		if(haddr0[15:0]==16'h0C0C) reg19 <= #1 HWDATA;//if(haddr0==32'hFFE10C0C) reg19 <= HWDATA;
		if(haddr0[15:0]==16'h0C10) reg20 <= #1 HWDATA;//if(haddr0==32'hFFE10C10) reg20 <= HWDATA;
		if(haddr0[15:0]==16'h0C14) reg21 <= #1 HWDATA;//if(haddr0==32'hFFE10C14) reg21 <= HWDATA;
		if(haddr0[15:0]==16'h0C20) reg22 <= #1 HWDATA;//if(haddr0==32'hFFE10C20) reg22 <= HWDATA;
		if(haddr0[15:0]==16'h0C24) reg23 <= #1 HWDATA;//if(haddr0==32'hFFE10C24) reg23 <= HWDATA;
		if(haddr0[15:0]==16'h0C28) reg24 <= #1 HWDATA;//if(haddr0==32'hFFE10C28) reg24 <= HWDATA;
		if(haddr0[15:0]==16'h0C2C) reg25 <= #1 HWDATA;//if(haddr0==32'hFFE10C2C) reg25 <= HWDATA;
	end
end
//write into the ram pelette
always @(*) begin
    if((haddr0[15:0]>=16'h0200) && (haddr0[15:0]<=16'h03FC) && HSEL && hwrite0 && ((htrans0==2'b10) || (htrans0==2'b11))) begin
        ramwaddr = ((haddr0[15:0]-16'h0200)>>2);
        ramwrite = 1'b1;
        ramwdata = HWDATA;
    end
    else begin
        ramwaddr = 0;
        ramwrite = 1'b0;
        ramwdata = 0;
    end
end

always @(*) begin
    if((haddr0[15:0]>=16'h0800) && (haddr0[15:0]<=16'h0BFC) && HSEL && hwrite0 && ((htrans0==2'b10) || (htrans0==2'b11))) begin
        ramwaddr1 = ((haddr0[15:0]-16'h0800)>>2);
        ramwrite1 = 1'b1;
        ramwdata1 = HWDATA;
    end
    else begin
        ramwaddr1 = 0;
        ramwrite1 = 1'b0;
        ramwdata1 = 0;
    end
end
   
//slave read operation
always @(*) begin
	HRDATA = 0;
	if (HSEL && (!hwrite0) && ((htrans0==2'b10) || (htrans0==2'b11))) begin
		if(haddr0[15:0]==16'hC1B8) HRDATA = reg0;
		if(haddr0[15:0]==16'h0000) HRDATA = reg1;
		if(haddr0[15:0]==16'h0004) HRDATA = reg2;
		if(haddr0[15:0]==16'h0008) HRDATA = reg3;
		if(haddr0[15:0]==16'h000C) HRDATA = reg4;
		if(haddr0[15:0]==16'h0010) HRDATA = reg5;
		if(haddr0[15:0]==16'h0014) HRDATA = reg6;
		if(haddr0[15:0]==16'h0018) HRDATA = reg7;
		if(haddr0[15:0]==16'h001C) HRDATA = reg8;
		if(haddr0[15:0]==16'h0020) HRDATA = reg9;
		if(haddr0[15:0]==16'h0024) HRDATA = reg10;
		if(haddr0[15:0]==16'h0028) HRDATA = reg11;
		if(haddr0[15:0]==16'h002C) HRDATA = reg12;
		if(haddr0[15:0]==16'h0030) HRDATA = reg13;
//		if((haddr0>=32'hFFE10200) && (haddr0<=32'hFFE103FC)) HRDATA = reg14[((haddr0-32'hFFE10200)>>2)];
//		if((haddr0>=32'hFFE10800) && (haddr0<=32'hFFE10BFC)) HRDATA = reg15[((haddr0-32'hFFE10800)>>2)];
		if(haddr0[15:0]==16'h0C00) HRDATA = reg16;
		if(haddr0[15:0]==16'h0C04) HRDATA = reg17;
		if(haddr0[15:0]==16'h0C08) HRDATA = reg18;
		if(haddr0[15:0]==16'h0C0C) HRDATA = reg19;
		if(haddr0[15:0]==16'h0C10) HRDATA = reg20;
		if(haddr0[15:0]==16'h0C14) HRDATA = reg21;
		if(haddr0[15:0]==16'h0C20) HRDATA = reg22;
		if(haddr0[15:0]==16'h0C24) HRDATA = reg23;
		if(haddr0[15:0]==16'h0C28) HRDATA = reg24;
		if(haddr0[15:0]==16'h0C2C) HRDATA = reg25;
	end
end

//read ram palette
//always @(*) begin
//    if((haddr0>=32'hFFE10200) && (haddr0<=32'hFFE103FC)) begin
//        ramraddr = ((haddr0-32'hFFE10200)>>2);
//        HRDATA = ramrdata;
//    end
//    else begin
//        ramraddr = 0;
//        HRDATA = 0;
//    end
//end
   
//control signals
assign HREADY = 1'b1;
assign HRESP = 0;

endmodule

