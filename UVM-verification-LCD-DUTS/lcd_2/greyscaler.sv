//grey scaler
////note that initial vsync pulse will increment frame0
module greyscaler(
input logic clk,
input logic reset,
input logic [15:0] pixel,
input logic pixel_valid,
input logic vsync,
output logic [2:0] greypixel,
output logic valid,
input logic stall,
REGISTERS regif
);

logic [3:0] red, blue, green;
logic [9:0] column, row;
logic lineend;
logic vsync_reg, vsyncpedge;
logic [3:0] frame0, frame0a;
logic [19:0] lineandcol;
logic [3:0] xv1;
logic [2:0] greypixel0;
logic LcdBW, BGR;
logic [2:0] LcdBpp;
logic [9:0] nppl, nlpp;

/////extract red, blue, green from 16-bit pixel
//assign LcdBW=0; //for test only
assign LcdBW=regif.reg7.LcdBW;
//assign BGR=0; //for test only
assign BGR=regif.reg7.BGR;
//assign LcdBpp=3'b110; //for test only
assign LcdBpp=regif.reg7.LcdBpp;
//assign nppl=15; //for test only
assign nppl=((regif.reg1.PPL+1'b1)<<4)-1'b1;
//assign nlpp=15; //for test only
assign nlpp=regif.reg2.LPP;

always @(*)
begin
	case(LcdBW)
		0: begin //color STN
			if(LcdBpp<=3) begin //1,2,4,8 bpp will be from palette
				if(BGR) begin //BGR format or not
					red=pixel[14:11];
					blue=pixel[4:1];
					green=pixel[9:6];
				end
				else begin
					red=pixel[4:1];
					blue=pixel[14:11];
					green=pixel[9:6];
				end
			end
			else begin //16 bpp will be from direct 4:4:4 data
				red=pixel[3:0];
				blue=pixel[11:8];
				green=pixel[7:4];
			end
		end
		1: begin //mono STN
			red=pixel[4:1];
			blue=0;
			green=0;
		end
	endcase
end


/////row and column counter
always @ (posedge clk or posedge reset) //column
	if(reset) column <= 0;
	else if(pixel_valid & (!stall)) begin
		if(column==nppl) column <= 0; //!!!!!!!!!!!
		else column <= column + 1'b1;
	end
	
assign lineend = (column==nppl);

always @ (posedge clk or posedge reset) //row
	if(reset) row <= 0;
	else begin
		if(lineend & (!stall)) begin
			if(row==nlpp) row <= 0;  //!!!!!!!!!!!!
			else row <= row + 1'b1;
		end
	end
	
//////frame counter
//register vsync
always @ (posedge clk or posedge reset)
	if(reset) vsync_reg <= 0;
	else vsync_reg <= vsync;
	
assign vsyncpedge = !vsync_reg & vsync; //positive edge of vsync

always @ (posedge clk or posedge reset) //frame
	if(reset) frame0 <= 1;
	else if(vsyncpedge) frame0 <= (frame0<<1)^((frame0[3])?2'b11:1'b0);	

////grey scale algorithm
assign lineandcol = {row,column};
assign xv1[3] = ^{lineandcol[1],lineandcol[5],lineandcol[6],lineandcol[7],lineandcol[8],
						lineandcol[10],lineandcol[12],lineandcol[13],lineandcol[16]}; 
assign xv1[2] = ^{lineandcol[2],lineandcol[6],lineandcol[7],lineandcol[8],lineandcol[9],
						lineandcol[11],lineandcol[13],lineandcol[14],lineandcol[17]}; 
assign xv1[1] = ^{lineandcol[0],lineandcol[3],lineandcol[7],lineandcol[8],lineandcol[9],
						lineandcol[10],lineandcol[12],lineandcol[14],lineandcol[15],lineandcol[18]}; 
assign xv1[0] = ^{lineandcol[0],lineandcol[4],lineandcol[5],lineandcol[6],lineandcol[7],
						lineandcol[9],lineandcol[11],lineandcol[12],lineandcol[15],lineandcol[19]}; 

always @(*)
begin
	case(xv1)
		0:  frame0a=frame0;
		1:  frame0a={ frame0[3],frame0[1],frame0[2],frame0[0]};
		2:  frame0a={ frame0[0],frame0[1],frame0[2],frame0[3]};
		3:  frame0a={ frame0[1],frame0[0],frame0[2],frame0[3]};
		4:  frame0a={ frame0[2],frame0[0],frame0[1],frame0[3]};
		5:  frame0a={ frame0[2],frame0[0],frame0[3],frame0[1]};
		6:  frame0a={ frame0[0],frame0[3],frame0[2],frame0[1]};
		7:  frame0a={ frame0[0],frame0[3],frame0[1],frame0[2]};
		8:  frame0a={ frame0[2],frame0[1],frame0[0],frame0[3]};
		9:  frame0a={ frame0[0],frame0[2],frame0[3],frame0[1]};
		10: frame0a={ frame0[2],frame0[1],frame0[3],frame0[0]};
		11: frame0a={ frame0[1],frame0[0],frame0[3],frame0[2]};
		12: frame0a={ frame0[1],frame0[2],frame0[0],frame0[3]};
		13: frame0a={ frame0[1],frame0[2],frame0[3],frame0[0]};
		14: frame0a={ frame0[3],frame0[0],frame0[1],frame0[2]};
		15: frame0a={ frame0[3],frame0[0],frame0[2],frame0[1]};
	endcase
end

//////convert pixel to grey scale
assign greypixel0[2]=(blue>=frame0a);
assign greypixel0[1]=(green>=frame0a);
assign greypixel0[0]=(red>=frame0a);

//register output greypixel
always @ (posedge clk or posedge reset)
	if(reset) greypixel <= 0;
	else if(!stall) greypixel <= greypixel0;
	
always @ (posedge clk or posedge reset)
	if(reset) valid <= 0;
	else if(!stall) valid <= pixel_valid;
	
endmodule


		
	