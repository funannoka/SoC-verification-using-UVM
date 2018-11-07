//serializer and ram palette

module serializer(
input logic clk, //pixel clock
input logic reset,
input logic [31:0] fifo_data,
input logic empty,
output logic read,
output logic [23:0] pixel, //for next stage
output logic pixel_valid, //for next stage
input logic stall,
input logic startpipe,
REGISTERS regif,
input logic [15:0] ramrdata,
output logic [7:0] ramraddr
);

logic [7:0] raddr1; //for serializer
logic [15:0] rdata1; //for serializer
typedef enum logic {IDLE, RUN} state_t;
state_t state;
logic [4:0] cnt;
logic cnt_en;
logic [4:0] cnt_part;
logic [5:0] cycles; //shift cycles for one word data
logic load, valid_next, shift;
logic pixel_valid0;
logic [31:0] shiftreg;
logic [23:0] pixel_out, pixel0; //bypass palette pixel
logic select; //1: bypass the palette, 0: not bypass
logic [2:0] lcdbpp;

//resolve ram interface
assign ramraddr=raddr1;
assign rdata1=ramrdata;

//assign lcdbpp=3'b110; //for test only
assign lcdbpp=regif.reg7.LcdBpp;

////determin select and cycles signal
always @(*) begin
	case(lcdbpp)
		3'b000: cycles=32;
		3'b001: cycles=16;
		3'b010: cycles=8;
		3'b011: cycles=4;
		3'b101: cycles=1;
		default: cycles=2;
	endcase
end	
assign select=(lcdbpp>3); //bypass palette signal
		
//////serializer
//counter
always @ (posedge clk or posedge reset)
	if(reset) cnt <= #1 5'b0;
	else if(cnt_en) cnt <= #1 cnt + 1'b1;
	else cnt <= #1 5'b0;

//for different modes, cnt has different ranges	
always @(*)
begin
	case(cycles)
		32: cnt_part=cnt;
		16: cnt_part={1'b0,cnt[3:0]};
		8: cnt_part={2'b0,cnt[2:0]};
		4: cnt_part={3'b0,cnt[1:0]};
		2: cnt_part={4'b0,cnt[0]};
		1: cnt_part=0;
		default: cnt_part=cnt;
	endcase
end
	

assign read = startpipe & (!stall) & (cnt_part == 0) & (!empty);
assign load = startpipe & (!stall) & (cnt_part == 0);
assign valid_next = startpipe & (!empty);
assign shift = startpipe & (!stall);
assign cnt_en = startpipe & (!stall);


//pixel valid output bit when bypass palette
always @ (posedge clk or posedge reset)
	if(reset) pixel_valid0 <= #1 0;
	else if(!stall) pixel_valid0 <= #1 valid_next;
	
//pixel shift register(serialization)
always @ (posedge clk or posedge reset)
begin
	if(reset) shiftreg <= #1 0;
	else begin
		if(load) shiftreg <= #1 fifo_data; //priority with load
		else if(shift) begin
			case(cycles)
				32: shiftreg <= #1 {1'b0, shiftreg[31:1]};
				16: shiftreg <= #1 {2'b0, shiftreg[31:2]};
				8: shiftreg <= #1 {4'b0, shiftreg[31:4]};
				4: shiftreg <= #1 {8'b0, shiftreg[31:8]};
				2: shiftreg <= #1 {16'b0, shiftreg[31:16]};
				default:;
			endcase
		end
	end
end

//serializer output before palette
always @(*)
begin
	case(cycles)
		32: pixel_out={23'b0, shiftreg[0]};
		16: pixel_out={22'b0, shiftreg[1:0]};
		8: pixel_out={20'b0, shiftreg[3:0]};
		4: pixel_out={16'b0, shiftreg[7:0]};
		2: pixel_out={8'b0, shiftreg[15:0]};
		1: pixel_out=shiftreg[23:0];
		default: pixel_out=0;
	endcase
end


//reading palette
assign raddr1=pixel_out[7:0];

//output select
assign pixel0=(select) ? pixel_out : {8'b0, rdata1};

//pipeline register for pixel output
always @ (posedge clk or posedge reset)
	if(reset) pixel <= #1 0;
	else if(!stall) pixel <= #1 pixel0;

//pipeline register for valid output
always @ (posedge clk or posedge reset)
	if(reset) pixel_valid <= #1 0;
	else if(!stall) pixel_valid <= #1 pixel_valid0;
	
endmodule
	
