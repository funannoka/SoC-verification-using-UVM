//cursor
module cursor(
input logic clk,
input logic reset,
input logic [23:0] pixel,
input logic pixel_valid,
input logic vsync,
output logic [23:0] pixelout,
output logic valid,
input logic stall,
REGISTERS regif,
output logic [7:0] raddr,
input logic [31:0] rdata
);

////////internal nets
logic vsync_reg, vsyncpedge;
logic [9:0] cursorx, cursory;
logic FrameSync;

logic [5:0] size;
logic [5:0] clipx, clipy;
logic [9:0] column, row;
logic [9:0] nppl, nlpp;
logic flag0, flag1, flag;
logic lineend;

logic [5:0] imagex, imagey;
logic [7:0] rbase;
logic [1:0] CrsrNum;

logic [1:0] imagepixel;
logic crsron0, crsron;

logic [23:0] pixel0, pixel1, pixelout0;
CRSR_PAL0 pal0;
CRSR_PAL1 pal1;
logic BGR, LcdBpp;

///////positive edge of vsync
always @ (posedge clk or posedge reset)
	if(reset) vsync_reg <= 0;
	else vsync_reg <= vsync;
	
assign vsyncpedge = !vsync_reg & vsync;
//////cursor coordinates
assign FrameSync = regif.reg17.FrameSync;
always @ (posedge clk or posedge reset)
	if(reset) begin
		cursorx <= '0;
		cursory <= '0;
	end
	else if(FrameSync) begin
                if(vsyncpedge) begin
                    cursorx <= regif.reg20.CrsrX;
                    cursory <= regif.reg20.CrsrY;
                end
        end else begin
                cursorx <= regif.reg20.CrsrX;
                cursory <= regif.reg20.CrsrY;
        end
        

//////determine whether to replace original pixel
//cursor size
assign size = regif.reg17.CrsrSize ? 6'd63 : 6'd31;
assign clipx = regif.reg21.CrsrClipX;
assign clipy = regif.reg21.CrsrClipY;
//flag: 1 for overlaid, 0 for non-overlaid
assign flag0 = (column>=cursorx) && (column<=(cursorx+size-clipx));
assign flag1 = (row>=cursory) && (row<=(cursory+size-clipy));
assign flag = flag0 && flag1;

///////row and column counter
assign nppl=((regif.reg1.PPL+1'b1)<<4)-1'b1;
assign nlpp=regif.reg2.LPP;

always @ (posedge clk or posedge reset) //column
	if(reset) column <= 0;
	else if(pixel_valid & (!stall)) begin
		if(column == nppl) column <= 0;
		else column <= column + 1'b1;
	end
	
assign lineend = (column==nppl);

always @ (posedge clk or posedge reset) //row
	if(reset) row <= 0;
	else begin
		if(lineend & (!stall)) begin
			if(row == nlpp) row <= 0;
			else row <= row + 1'b1;
		end
	end

///////extract 2-bit pixel from the image word data
//determine the cursor image address
assign imagex = column-cursorx+clipx;
assign imagey = row-cursory+clipy;

//offset into cursor memory
always @(*) begin
    if(regif.reg17.CrsrSize) begin
        if(imagex < 6'd16) raddr = (imagey << 4);
        else if(imagex < 6'd32) raddr = (imagey << 4) + 4;
        else if(imagex < 6'd48) raddr = (imagey << 4) + 8;
        else raddr = (imagey << 4) + 12;
    end else begin
        if(imagex < 6'd16) raddr = (imagey << 3) + rbase;
        else raddr = (imagey << 3) + 4 + rbase;
    end
end
    
//base address of 32x32 cursor
assign CrsrNum = regif.reg16.CrsrNum;
always @(*) begin
    case (CrsrNum) 
        2'b00: rbase = 8'd0;
        2'b01: rbase = 8'd64;
        2'b10: rbase = 8'd128;
        2'b11: rbase = 8'd192;
    endcase
end

//////////////extract 2-bit data
assign imagepixel = crsrmap(imagex, rdata);

///////mapping to extract 2-bit data
	function logic [1:0] crsrmap(logic [5:0] imagex, logic [31:0] rdata); //offset into cursor memory
		case(imagex)
                        6'd12, 6'd28, 6'd44, 6'd60: crsrmap = rdata [31:30];
			6'd13, 6'd29, 6'd45, 6'd61: crsrmap = rdata [29:28];
			6'd14, 6'd30, 6'd46, 6'd62: crsrmap = rdata [27:26];
			6'd15, 6'd31, 6'd47, 6'd63: crsrmap = rdata [25:24];

			6'd8, 6'd24, 6'd40, 6'd56: crsrmap = rdata [23:22];
			6'd9, 6'd25, 6'd41, 6'd57: crsrmap = rdata [21:20];
			6'd10, 6'd26, 6'd42, 6'd58: crsrmap = rdata [19:18];
			6'd11, 6'd27, 6'd43, 6'd59: crsrmap = rdata [17:16];

			6'd4, 6'd20, 6'd36, 6'd52: crsrmap = rdata [15:14];
			6'd5, 6'd21, 6'd37, 6'd53: crsrmap = rdata [13:12];
			6'd6, 6'd22, 6'd38, 6'd54: crsrmap = rdata [11:10];
			6'd7, 6'd23, 6'd39, 6'd55: crsrmap = rdata [9:8];

			6'd0, 6'd16, 6'd32, 6'd48: crsrmap = rdata [7:6];
			6'd1, 6'd17, 6'd33, 6'd49: crsrmap = rdata [5:4];
			6'd2, 6'd18, 6'd34, 6'd50: crsrmap = rdata [3:2];
			6'd3, 6'd19, 6'd35, 6'd51: crsrmap = rdata [1:0];
		endcase
	endfunction



//////multiplex the output
assign crsron0 = regif.reg16.CrsrOn;
assign crsron = crsron0 & flag;

always @(*) begin
    case(crsron)
        1'b0: pixelout0 = pixel;
        1'b1: begin
            case(imagepixel)
                2'b00: pixelout0 = pixel0;
                2'b01: pixelout0 = pixel1;
                2'b10: pixelout0 = pixel;
                2'b11: pixelout0 = ~pixel;
            endcase
        end
    endcase
end

//////different data format mapping
assign pal0 = regif.reg18;
assign pal1 = regif.reg19;
assign BGR = regif.reg7.BGR;
assign LcdBpp = regif.reg7.LcdBpp;

always @(*)
begin
    case(LcdBpp)
        3'b000, 3'b001, 3'b010, 3'b011, 3'b100: begin
            if(BGR) pixel0 = {9'b0, pal0.Red[7:3], pal0.Green[15:11], pal0.Blue[23:19]};
            else pixel0 = {9'b0, pal0.Blue[23:19], pal0.Green[15:11], pal0.Red[7:3]};
        end
        3'b101: pixel0 = pal0;
        3'b110: pixel0 = {8'b0, pal0.Blue[23:19], pal0.Green[15:10], pal0.Red[7:3]};
        3'b111: begin
            if(BGR) pixel0 = {12'b0, pal0.Red[7:4], pal0.Green[15:12], pal0.Blue[23:20]};
            else pixel0 = {12'b0, pal0.Blue[23:20], pal0.Green[15:12], pal0.Red[7:4]};
        end
    endcase
end

always @(*)
begin
    case(LcdBpp)
        3'b000, 3'b001, 3'b010, 3'b011, 3'b100: begin
            if(BGR) pixel1 = {9'b0, pal1.Red[7:3], pal1.Green[15:11], pal1.Blue[23:19]};
            else pixel1 = {9'b0, pal1.Blue[23:19], pal1.Green[15:11], pal1.Red[7:3]};
        end
        3'b101: pixel1 = pal1;
        3'b110: pixel1 = {8'b0, pal1.Blue[23:19], pal1.Green[15:10], pal1.Red[7:3]};
        3'b111: begin
            if(BGR) pixel1 = {12'b0, pal1.Red[7:4], pal1.Green[15:12], pal1.Blue[23:20]};
            else pixel1 = {12'b0, pal1.Blue[23:20], pal1.Green[15:12], pal1.Red[7:4]};
        end
    endcase
end

//////register outputs
//pipeline register for pixel output
always @ (posedge clk or posedge reset)
	if(reset) pixelout <= 0;
	else if(!stall) pixelout <= pixelout0;

//pipeline register for valid output
always @ (posedge clk or posedge reset)
	if(reset) valid <= 0;
	else if(!stall) valid <= pixel_valid;
	

endmodule


