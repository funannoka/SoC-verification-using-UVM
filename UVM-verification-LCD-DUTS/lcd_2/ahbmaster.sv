//ahb master

module ahbmaster(
	AHBIF.AHBM ahbm,
	AHBIF.AHBCLKS ahbclks,
   input logic LCDFP,
   input logic [5:0] fifo_used1,
	input logic [5:0] fifo_used2,
   output logic wen1,
	output logic wen2,
   output logic [31:0] wdata1,
	output logic [31:0] wdata2,
	REGISTERS regif
);

////////////ports from interface
logic HCLK;
logic HRESET;
logic mHBUSREQ;

logic mHGRANT;
logic mHREADY;
logic [1:0] mHRESP;
logic [31:0] mHRDATA;
logic [1:0] mHTRANS;
logic [31:0] mHADDR;
logic mHWRITE;
logic [2:0] mHSIZE;
logic [2:0] mHBURST;
////////////internal nets and regs
logic up; //1: up panel, 0: lower panel
logic dual; //dual panel or not
logic [31:0] address1, address2;
logic [31:0] total_cnt1, total_cnt2, total_words; //total_cnt1 for up panel, total_cnt2 for lower panel
logic [5:0] burst_cnt, burst_len1, burst_len2;
logic start;
logic increment_address1, increment_address2, cen;
logic load, load1, load2;
logic [3:0] wmark; //watermark 4 or 8
logic [5:0] len1, len2;
logic [31:0] len_addr1, len_addr2;
logic [11:0] len_addr1s, len_addr2s;
logic [2:0] shift;
logic [10:0] ppl, lpp;
logic [2:0] lcdbpp;
logic reassert1, reassert2;
logic [28:0] upbase, lpbase;
logic LCDFP0;

typedef enum logic [1:0] {IDLE=2'b00, BUSY=2'b01, NONSEQ=2'b10, SEQ=2'b11} htran_t;
typedef enum logic [2:0] {SINGLE=3'b000, INCR=3'b001, INCR4=3'b011, INCR8=3'b101} hburst_t;
typedef enum logic [3:0] {SIDLE, INIT, INIT1, INIT2, BUSREQ1, SNONSEQ1, SSEQ1, DONE1, BUSREQ2, SNONSEQ2, SSEQ2, DONE2, FRAMEDONE} state_t;

state_t     state, state_r;
hburst_t    hburst, hburst1, hburst2;
htran_t     htrans;


///////////////resolve interface
assign HCLK = ahbclks.HCLK;
assign HRESET = ahbclks.HRESET;
// assign ahbm.mHBUSREQ = mHBUSREQ; //causing error in compilation.. multiple driver
assign mHGRANT = ahbm.mHGRANT;
assign mHREADY = ahbm.mHREADY;
assign mHRESP = ahbm.mHRESP;
assign mHRDATA = ahbm.mHRDATA;
assign ahbm.mHTRANS = mHTRANS;
assign ahbm.mHADDR = mHADDR;
assign ahbm.mHWRITE = mHWRITE;
assign ahbm.mHSIZE = mHSIZE;
assign ahbm.mHBURST = mHBURST;

/////////////
//assign dual = 1'b0; //for test only
assign dual = regif.reg7.LcdDual;

//////////Address register
//assign upbase = '0; //for test only
//assign lpbase = 256; //for test only
assign upbase = regif.reg5.LCDUPBASE;
assign lpbase = regif.reg6.LCDLPBASE;

assign mHADDR = up ? address1 : address2;
//upper panel address
always @ (posedge HCLK or posedge HRESET)
	if(HRESET) LCDFP0 <= #1 0;
	else LCDFP0 <= #1 LCDFP;
	
assign start = !LCDFP0 & LCDFP; //positive edge of vsync

always @ (posedge HCLK or posedge HRESET)
begin
	if (HRESET == 1'b1) address1 <= #1 32'b0;
	else begin
		if(start == 1'b1) address1 <= #1 {upbase,3'b0}; //hierarchical names
		else if(increment_address1 == 1'b1)
			address1 <= #1 address1 + 3'b100;
	end
end
//lower panel address
always @ (posedge HCLK or posedge HRESET)
begin
	if (HRESET == 1'b1) address2 <= #1 32'b0;
	else begin
		if(start == 1'b1) address2 <= #1 {lpbase,3'b0}; //!!!!!!!!!!!!!!
		else if(increment_address2 == 1'b1)
			address2 <= #1 address2 + 3'b100;
	end
end

////////////Burst counter
assign cen=increment_address1 || increment_address2;
always @ (posedge HCLK or posedge HRESET)
begin
	if (HRESET == 1'b1) burst_cnt <= #1 6'b0;
	else begin
		if(load1 == 1'b1) burst_cnt <= #1 burst_len1;
		else if(load2 == 1'b1) burst_cnt <= #1 burst_len2;
		else if(cen == 1'b1) burst_cnt <= #1 burst_cnt - 1'b1;
	end
end

//Total pixels counter (in one frame)
//upper panel
always @ (posedge HCLK or posedge HRESET)
begin
	if (HRESET == 1'b1) total_cnt1 <= #1 32'b0;
	else begin
		if(load == 1'b1) total_cnt1 <= #1 total_words; //load is 1 cycle pulse
		else if(increment_address1 == 1'b1) total_cnt1 <= #1 total_cnt1 - 1'b1;
	end
end
//lower panel
always @ (posedge HCLK or posedge HRESET)
begin
	if (HRESET == 1'b1) total_cnt2 <= #1 32'b0;
	else begin
		if(!dual) total_cnt2 <= #1 '0;
		else if(load == 1'b1) total_cnt2 <= #1 total_words; //load is 1 cycle pulse
		else if(increment_address2 == 1'b1) total_cnt2 <= #1 total_cnt2 - 1'b1;
	end
end
       
//Burst Length each transaction and total words in one frame
//assign wmark = 4'b1000; //for test only
assign wmark = regif.reg7.WATERMARK ? 4'b1000 : 4'b0100; 

//upper panel
assign len1 = (wmark > total_cnt1) ? total_cnt1 : wmark;
assign len_addr1 = address1 + ((len1-1'b1)<<2);
assign len_addr1s = (address1[10]) ? (1'b1<<11) : (1'b1<<10);
assign burst_len1 = (address1[10] ^ len_addr1[10]) ? ((len_addr1s - address1[10:0])>>2) : len1; //1k bound adjust
//lower panel
assign len2 = (wmark > total_cnt2) ? total_cnt2 : wmark;
assign len_addr2 = address2 + ((len2-1'b1)<<2);
assign len_addr2s = (address2[10]) ? (1'b1<<11) : (1'b1<<10);
assign burst_len2 = (address2[10] ^ len_addr2[10]) ? ((len_addr2s - address2[10:0])>>2) : len2; //1k bound adjust

//Total pixels
//assign lcdbpp = 3'b110; //for test only
assign lcdbpp = regif.reg7.LcdBpp;

always_comb
begin
	shift=1'b0;
	case(1'b1)
	{lcdbpp<=5}: shift=3'b101-lcdbpp;
	{lcdbpp==6}: shift=1'b1;
	{lcdbpp==7}: shift=1'b1;
	default: shift=1'b0;
	endcase
end

//assign ppl=16; //for test only
//assign lpp=16; //for test only
assign ppl=(regif.reg1.PPL+1'b1)<<4;
assign lpp=regif.reg2.LPP+1'b1;
assign total_words=(ppl * lpp)>>shift;

////////////////Master state machine
always @ (posedge HCLK or posedge HRESET)
begin
	if(HRESET == 1'b1)
		state <= #1 SIDLE;
	else begin
		case(state)
			SIDLE: if(start == 1'b1) state <= #1 INIT;
			INIT: state <= #1 INIT1; //load total counter
			INIT1: state <= #1 BUSREQ1; //load burst counter for upper panel
			BUSREQ1: if(mHGRANT) state <= #1 SNONSEQ1;
			SNONSEQ1: begin
				if(mHGRANT) begin
					if(mHREADY) begin
						if(burst_cnt==1'b1) state <= #1 DONE1;
						else state <= #1 SSEQ1;
					end
				end
				else state <= #1 BUSREQ1;
			end
			SSEQ1: begin
				if(mHGRANT) begin
					if(mHREADY && (burst_cnt==1'b1)) state <= #1 DONE1;
				end
				else state <= #1 BUSREQ1;
			end
			DONE1: begin
				if(mHREADY) begin
					if((total_cnt1=='0) && (total_cnt2=='0)) state <= #1 FRAMEDONE;
					else if(total_cnt2!='0) begin
						if(reassert2) state <= #1 INIT2;
					end
					else if(reassert1) state <= #1 INIT1;
				end
			end
			INIT2: state <= #1 BUSREQ2; //load burst counter for lower panel
			BUSREQ2: if(mHGRANT) state <= #1 SNONSEQ2;
			SNONSEQ2: begin
				if(mHGRANT) begin
					if(mHREADY) begin
						if(burst_cnt==1'b1) state <= #1 DONE2;
						else state <= #1 SSEQ2;
					end
				end
				else state <= #1 BUSREQ2;
			end
			SSEQ2: begin
				if(mHGRANT) begin
					if(mHREADY && (burst_cnt==1'b1)) state <= #1 DONE2;
				end
				else state <= #1 BUSREQ2;
			end
			DONE2: begin
				if(mHREADY) begin
					if((total_cnt1=='0) && (total_cnt2=='0)) state <= #1 FRAMEDONE;
					else if(total_cnt1!='0) begin
						if(reassert1) state <= #1 INIT1;
					end
					else if(reassert2) state <= #1 INIT2;
				end
			end
			FRAMEDONE: state <= #1 SIDLE; //whole frame is done
			default: state <= #1 SIDLE;
		endcase
	end 
end

//state machine output
always @(*)
begin
	load='0;
	load1='0;
	load2='0;
	mHBUSREQ='0;  //mHBUSREQ signal logic
	htrans=IDLE; //htrans signal logic
	up=1'b1; //at the beginning, do upper panel transcations
	case(state)
		INIT: load=1'b1;
		INIT1: load1=1'b1;
		INIT2: load2=1'b1;
		BUSREQ1:begin ahbm.mHBUSREQ=1'b1; mHBUSREQ=1'b1; end
		BUSREQ2:begin ahbm.mHBUSREQ=1'b1; mHBUSREQ=1'b1; end
		SNONSEQ1: htrans=NONSEQ;
		SSEQ1: htrans=SEQ;
		SNONSEQ2: begin 
			htrans=NONSEQ;
			up='0;
		end
		SSEQ2: begin
			htrans=SEQ;
			up='0;
		end
		default:;
	endcase
end

///////////////HBURST logic
always @(*) //upper panel
begin
	case(burst_len1)
		1: hburst1=SINGLE;
		4: hburst1=INCR4;
		8: hburst1=INCR8;
		default: hburst1=INCR;
	endcase
end

always @(*) //lower panel
begin
	case(burst_len2)
		1: hburst2=SINGLE;
		4: hburst2=INCR4;
		8: hburst2=INCR8;
		default: hburst2=INCR;
	endcase
end

always @ (posedge HCLK or posedge HRESET)
begin
	if (HRESET == 1'b1) hburst <= #1 SINGLE;
	else if(load1 == 1'b1) hburst <= #1 hburst1;
	else if(load2 == 1'b1) hburst <= #1 hburst2;
end

//////////control signals
assign mHWRITE = 1'b0;
assign mHTRANS = htrans;
assign mHBURST = hburst;
assign reassert1 = (fifo_used1 <= (6'b100000-wmark));
assign reassert2 = (fifo_used2 <= (6'b100000-wmark));
assign increment_address1 = mHREADY && ((state == SSEQ1) || (state == SNONSEQ1));
assign increment_address2 = mHREADY && ((state == SSEQ2) || (state == SNONSEQ2));
assign mHSIZE=3'b10;

///////////////fifo logic
//register the state because of AHB bus pipeline
always @ (posedge HCLK or posedge HRESET)
begin
	if(HRESET) state_r <= #1 SIDLE;
	else if(mHREADY) state_r <= #1 state;
end
assign wdata1 = mHRDATA;
assign wdata2 = mHRDATA;
assign wen1 = mHREADY && ((state == SSEQ1) || (state == SNONSEQ1));
assign wen2 = mHREADY && ((state == SSEQ2) || (state == SNONSEQ2));

endmodule
