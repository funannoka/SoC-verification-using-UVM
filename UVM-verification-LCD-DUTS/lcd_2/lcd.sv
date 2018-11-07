//lcd top level module
//`include "lcdif.v"
`include "ahbmaster.sv"
`include "ahbslave.sv"
`include "fifo.sv"
`include "lcdoutput.sv"
`include "registerif.sv"
`include "serializer.sv" 
`include "timingcontroller.sv"
`include "cursor.sv"
`include "greyscaler.sv"
`include "formatter.sv"

module lcd(
	AHBIF.AHBCLKS ahbclks,
	AHBIF.AHBM ahbm,
	AHBIF.AHBS ahbs,
	MEMIF.F0 mem0,
	MEMIF.F0 mem1,
	RAM128IF.R0 ram0,
	RAM256IF.R0 ram1,
	LCDOUT.O0 lcdif
);
//timing controller signals
logic vsync;
logic hsync;
logic panelclk;
logic pclk;
logic read;
logic active;
logic startpipe;
logic LCDENA_LCDM;
//lcdoutput signals
logic [23:0] lcdout;
logic full0;
//formatter signals
logic [7:0] dataout;
logic write0;
logic stall0;
//greyscaler output signals
logic pixel_valid11, pixel_valid22;
logic valid1;
logic valid2;
logic [2:0] greypixel1;
logic [2:0] greypixel2;
//serializer signals
logic stall;
logic pixel_valid1;
logic pixel_valid2;
logic [23:0] pixel1;
logic [23:0] pixel2;
//fifo signals
logic empty1;
logic empty2;
logic [31:0] rdata1;
logic [31:0] rdata2;
logic ren1;
logic ren2;
//ahbmaster signals
logic [5:0] fifo_used1;
logic [5:0] fifo_used2;
logic wen1;
logic wen2;
logic [31:0] wdata1;
logic [31:0] wdata2;
//cursor signals
logic [23:0] pixelcrsr1;
logic validcrsr1;

logic select;
logic vsync_reg, vsyncpedge;
logic [3:0] frame0;

REGISTERS R();

//resolve LCDOUT interface
assign lcdif.LCDFP=vsync;
assign lcdif.LCDLP=hsync;
assign lcdif.LCDDCLK=panelclk;
assign lcdif.LCDVD=lcdout;
assign lcdif.lcd_frame=frame0;
assign lcdif.LCDENA_LCDM=LCDENA_LCDM;

/////module instantiation
ahbmaster A0 (.ahbm(ahbm), .ahbclks(ahbclks), .LCDFP(vsync), .fifo_used1(fifo_used1), .fifo_used2(fifo_used2), 
				  .wen1(wen1), .wen2(wen2), .wdata1(wdata1), .wdata2(wdata2), .regif(R));				  

ahbslave A1 (.ahbs(ahbs), .ahbclks(ahbclks), .regif(R), .ram128if(ram0), .ram256if(ram1));

fifo F1 (.wclk(ahbclks.HCLK), .rclk(pclk), .reset(ahbclks.HRESET), .wen(wen1), .ren(ren1), .empty(empty1), .wdata(wdata1), 
			.rdata(rdata1), .fifo_used(fifo_used1), .memif(mem0), .full());
			
fifo F2 (.wclk(ahbclks.HCLK), .rclk(pclk), .reset(ahbclks.HRESET), .wen(wen2), .ren(ren2), .empty(empty2), .wdata(wdata2), 
			.rdata(rdata2), .fifo_used(fifo_used2), .memif(mem1), .full());
			
serializer S1 (.clk(pclk), .reset(ahbclks.HRESET), .fifo_data(rdata1), .empty(empty1), .read(ren1), .pixel(pixel1), .pixel_valid(pixel_valid1), 
                .stall(stall), .startpipe(startpipe), .regif(R), .ramraddr(ram0.raddr), .ramrdata(ram0.rdata));
/*					
serializer S2 (.clk(pclk), .reset(ahbclks.HRESET), .fifo_data(rdata2), .empty(empty2), .read(ren2), .pixel(pixel2), 
					.pixel_valid(pixel_valid2), .stall(stall), .regif(R), .ramraddr(ram0.raddr1), .ramrdata(ram0.rdata1));*/
					
cursor C1 (.clk(pclk), .reset(ahbclks.HRESET), .pixel(pixel1), .pixel_valid(pixel_valid1), .vsync(vsync), .pixelout(pixelcrsr1), .valid(validcrsr1), 
            .stall(stall), .regif(R), .raddr(ram1.raddr), .rdata(ram1.rdata));

					
greyscaler G1 (.clk(pclk), .reset(ahbclks.HRESET), .pixel(pixelcrsr1[15:0]), .pixel_valid(pixel_valid11), .vsync(vsync), 
					.greypixel(greypixel1), .valid(valid1), .stall(stall0), .regif(R));
/*					
greyscaler G2 (.clk(pclk), .reset(ahbclks.HRESET), .pixel(pixel2[15:0]), .pixel_valid(pixel_valid22), .vsync(vsync), 
					.greypixel(greypixel2), .valid(valid2), .stall(stall0), .regif(R));*/
					
formatter M1 (.clk(pclk), .reset(ahbclks.HRESET), .greypixel(greypixel1), .valid(valid1), .dataout(dataout), .write(write0), 
					.full(full0), .stall(stall0), .regif(R));

timingcontroller T (.cclk(ahbclks.HCLK), .clk(pclk), .panelclk(panelclk), .reset(ahbclks.HRESET), .hsync(hsync), 
                    .vsync(vsync), .read(read), .active(active), .startpipe(startpipe), .LCDENA_LCDM(LCDENA_LCDM), .regif(R));
					
lcdoutput L1 (.clk(pclk), .reset(ahbclks.HRESET), .read(read), .active(active), .pixelstn(dataout), .write(write0), 
                .full(full0), .pixeltft(pixelcrsr1), .lcdout(lcdout), .regif(R));

//pipeline control signals for serializer
assign stall = 1'b0;
//lcdoutput input data write select

//grey scaler input gating (for STN and TNT modes)
assign pixel_valid11 = validcrsr1 & (!select);
//assign pixel_valid22 = pixel_valid2 & (!select);

//determine select signal				
assign select=R.reg7.LcdTFT;

//////frame counter
//register vsync
always @ (posedge ahbclks.HCLK or posedge ahbclks.HRESET)
	if(ahbclks.HRESET) vsync_reg <= #1 0;
	else vsync_reg <= #1 vsync;
	
assign vsyncpedge = !vsync_reg & vsync; //positive edge of vsync

always @ (posedge ahbclks.HCLK or posedge ahbclks.HRESET) //frame
	if(ahbclks.HRESET) frame0 <= #1 1;
	else if(vsyncpedge) frame0 <= #1 (frame0<<1)^((frame0[3])?2'b11:1'b0);
					
endmodule

