module formatter(
input logic clk,
input logic reset,
input logic [2:0] greypixel,
input logic valid,
output logic [7:0] dataout,
output logic write,
input logic full,
output logic stall,
REGISTERS regif
);

typedef enum logic [3:0] {IDLE, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11} state_t;
state_t state;
typedef enum logic [1:0] {IDLE1, SHIFT, WRITE, WAIT} state1_t;
state1_t state1;

logic shift0, shift1;
logic stall0, stall1;
logic write0, write1;
logic [7:0] dataout0, dataout1; 
logic [2:0] shiftreg[0:3]; //blue, green, red
logic [7:0] shiftreg1;
logic [2:0] cnt, bitnum;
logic cen;
int i;
logic LcdMono8, LcdBW;

//////FSM for color 3-bit pixel formatter
always @ (posedge clk or posedge reset)
	if(reset) state <= IDLE;
   else begin
		case(state)
			IDLE: if(valid) state <= S1;
			S1: if(valid) state <= S2;
			S2: if(valid) state <= S3;
         S3: begin
				if(!valid && !full) state <= S4; //go to wait state and wait for valid signal
				if(valid && !full) state <= S5;
			end
			S4: if(valid) state <= S5;
			S5: if(valid) state <= S6;
         S6: if(valid) state <= S7;
         S7: begin
				if(!valid && !full) state <= S8; //go to wait state and wait for valid signal
				if(valid && !full) state <= S9;
			end
         S8: if(valid) state <= S9;
			S9: if(valid) state <= S10;
         S10: begin
				if(!valid && !full) state <= S11; //go to wait state and wait for valid signal
				if(valid && !full) state <= S1;
			end
			S11: if(valid) state <= S1;
         default: state <= IDLE;
		endcase
	end
//FSM output
always @(*)
begin
	shift0=0;
   write0=0;
   stall0=0;
   case(state)
		IDLE: if(valid) shift0=1;
      S1: if(valid) shift0=1;
      S2: if(valid) shift0=1;
      S3: begin
			if(full) stall0=1;
			else begin
				write0=1;
				if(valid) shift0=1;
			end
		end
		S4: if(valid) shift0=1;
		S5: if(valid) shift0=1;
		S6: if(valid) shift0=1;
		S7: begin
			if(full) stall0=1;
			else begin
				write0=1;
				if(valid) shift0=1;
			end
		end
		S8: if(valid) shift0=1;
		S9: if(valid) shift0=1;
		S10: begin
			if(full) stall0=1;
			else begin
				write0=1;
				if(valid) shift0=1;
			end
		end
		S11: if(valid) shift0=1;
		default:;
	endcase
end
    
//multiplexed dataout
always @(*)
begin
   dataout0=0;
   case(state)
		S3: dataout0={shiftreg[0][1:0], shiftreg[1], shiftreg[2]};
      S7: dataout0={shiftreg[0][0], shiftreg[1], shiftreg[2], shiftreg[3][2]};
      S10: dataout0={shiftreg[0], shiftreg[1], shiftreg[2][2:1]};
      default:;
	endcase
end
    
//shift registers
always @ (posedge clk or posedge reset)
begin
    if(reset) begin
        for(i=0; i<4; i=i+1)
            shiftreg[i] <= 0;
        end
    else if(shift0) begin
            shiftreg[0] <= greypixel;
            for(i=0; i<3; i=i+1)
                shiftreg[i+1] <= shiftreg[i];
    end
end

//////FSM for mono 1-bit pixel formatter
//for 4-bit STN panel
always @ (posedge clk or posedge reset)
   if(reset) state1 <= IDLE1;
   else begin
		case(state1)
			IDLE1: if(valid) state1 <= SHIFT;
			SHIFT: if(valid && (cnt==bitnum)) state1 <= WRITE;
			WRITE: begin
				if(valid && !full) state1 <= SHIFT;
				if(!valid && !full) state1 <= WAIT;
			end
			WAIT: if(valid) state1 <= SHIFT;
			default: state1 <= IDLE1;
		endcase
	end
//FSM output
always @(*)
begin
   shift1=0;
   write1=0;
   stall1=0;
	cen=0;
	case(state1)
		IDLE1: if(valid) shift1=1;
		SHIFT: begin
			shift1=1;
			cen=1;
		end
		WRITE: begin
			if(full) stall1=1;
			else begin
				write1=1;
				if(valid) shift1=1;
			end
		end
		WAIT: if(valid) shift1=1;
		default:;
	endcase
end
//counter for number of shifts
//assign bitnum=2'b11; //for test only
assign bitnum=LcdMono8 ? 3'b111 : 3'b011; //!!!!!!!!!!!

always @ (posedge clk or posedge reset)
	if(reset) cnt <= 1;
	else if(cen) begin
		if(cnt==bitnum) cnt <= 1; //!!!!!!!!!!!
		else cnt <= cnt + 1'b1;
	end
	
//assign LcdMono8=1; //for test only
assign LcdMono8=regif.reg7.LcdMono8;
assign dataout1=LcdMono8 ? shiftreg1[7:0] : {4'b0, shiftreg1[7:4]};

//shift registers
always @ (posedge clk or posedge reset)
begin
	if(reset) shiftreg1 <= 0;
	else if(shift1) shiftreg1 <= {greypixel[0], shiftreg1[7:1]};
end

//////////output select
//assign LcdBW=0; //for test only
assign LcdBW=regif.reg7.LcdBW;
assign dataout=LcdBW ? dataout1 : dataout0; //color or not
assign stall=LcdBW ? stall1 : stall0;
assign write=LcdBW ? write1 : write0;

endmodule
