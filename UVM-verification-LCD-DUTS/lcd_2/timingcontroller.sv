//timing control and lcd panel clock generator
//`include "lcd.register.v"

module timingcontroller(
input logic cclk, //this is the bus clock
output logic clk, //this is the pixel clock
output logic panelclk,
input logic reset,
output logic hsync,
output logic vsync,
output logic read, //read acknowledge for lcd output fifo
output logic active, //enable the lcd output
output logic startpipe, //indicate data moving in the pipeline
output logic LCDENA_LCDM,
REGISTERS regif //access the registers
//input logic lcden, //for test only
//input logic lcdpwr //for test only
);

logic lcden, lcdpwr;  //power up signals
typedef enum logic [1:0] {IDLE, READ, DONE} stater_t;
stater_t stater;
logic den;
logic [10:0] dcnt;
logic [9:0] pixelcnt, ncpl; //counter for number of lcd data each line

typedef enum logic [1:0] {LIDLE, LENABLE, LRUN} statel_t;
statel_t statel;
logic len, lclr;
logic [10:0] lcnt; //counter for line timing control
logic [8:0] nhbp, nhfp, nhsw, nl0, nl1;
logic [10:0] nppl, nl2, nl3;
logic hsync0, hsync1;

logic hsyncpedge;
typedef enum logic [1:0] {VIDLE, VENABLE, VRUN} statev_t;
statev_t statev;
logic ven, vclr;
logic [10:0] vcnt; //counter for frame timing control
logic [6:0] nvsw, nv0;
logic [7:0] nvbp, nvfp;
logic [8:0] nv1;
logic [10:0] nlpp, nv2, nv3;
logic vsync0, lineactive0, lineactive; //lineactive indicates active line period for data output

logic [10:0] clkcnt, pscaler; //counter for panelclk (clk/(pscaler+1))
logic [4:0] cclkcnt, cscaler; //counter for pixelclk (cclk/(cscaler+1))

logic panelclk0;
logic BCD;
logic active0, active1;

        
//////////////pixel clock generator
always @ (negedge cclk or posedge reset)
    if(reset) cclkcnt <= #1 0;
    else if(cclkcnt==cscaler) cclkcnt <= #1 0;
    else cclkcnt <= #1 cclkcnt + 1'b1;

always @ (negedge cclk or posedge reset)
    if(reset) clk <= #1 0;
    else if(cclkcnt==0) clk <= #1 1'b1;
    else clk <= #1 0;

//assign cscaler=2; //for test only
assign cscaler=regif.reg0.CLKDIV;
	

//power up signals
assign lcden=regif.reg7.LcdEn;
assign lcdpwr=regif.reg7.LcdPwr;

//////////////horizontal timing
//counter for line timing control
always @ (posedge clk or posedge reset)
	if(reset) lcnt <= #1 0;
	else if(lclr) lcnt <= #1 0;
	else if(len) begin
		if(lcnt == nl3) lcnt <= #1 0;
		else lcnt <= #1 lcnt + 1'b1;
	end

//FSM for horizontal timing
always @ (posedge clk or posedge reset)
	if(reset) statel <= #1 LIDLE;
	else begin
		case(statel)
			LIDLE: if(lcden) statel <= #1 LENABLE; //power-up sequence
			LENABLE: begin
				if(!lcden) statel <= #1 LENABLE;
				else if(lcdpwr) statel <= #1 LRUN;
			end
			LRUN: if(!lcdpwr) statel <= #1 LIDLE;
         default: statel <= #1 LIDLE;
		endcase
	end

assign nhsw=regif.reg1.HSW;
//assign nhsw=2; //for test only
assign nhbp=regif.reg1.HBP+1'b1;
//assign nhbp=5; //for test only
assign nhfp=regif.reg1.HFP+1'b1;
//assign nhfp=5; //for test only
assign nppl=((regif.reg1.PPL+1'b1)<<4);
//assign nppl=16; //for test only

assign nl0 = nhsw; //end of HSW period
assign nl1 = nl0 + nhbp; //end of HBP period
assign nl2 = nl1 + nppl; //end of PPL period
assign nl3 = nl2 + nhfp; //end of HFP period

//counter clear and enable logic
assign lclr = (statel == LENABLE);
assign len = (statel == LRUN);

//horizontal sync pulse logic
always @(*) begin
	hsync0 = 1'b0;
	case(statel)
//		LIDLE: if(lcden) hsync0 = 1'b1;
		LENABLE: if(lcdpwr) hsync0 = 1'b1;
		LRUN: begin
			if(lcnt == nl3) hsync0 = 1'b1;
			else if(lcnt == nl0) hsync0 = 0;
			else hsync0 = hsync1;
		end
		default: hsync0 = hsync1;
	endcase
end

//hsync1 register the hsync0
always @ (posedge clk or posedge reset)
    if(reset) hsync1 <= #1 0;
    else hsync1 <= #1 hsync0;

//actual hsync pulse (hsync0 may be suppressed by vsync pulse)
always @ (posedge clk or posedge reset)
    if(reset) hsync <= #1 0;
    else hsync <= #1 hsync0 & (!vsync0);

/////////////panel clock logic for STN and TFT panels
//STN
always @ (posedge clk or posedge reset)
    if(reset) clkcnt <= #1 0;
    else if(clkcnt == pscaler) clkcnt <= #1 0;
    else clkcnt <= #1 clkcnt + 1'b1;
	 
//panel clock may be suppressed by hsync pulse
always @ (posedge clk or posedge reset)
    if(reset) panelclk0 <= #1 0;
    else if(hsync1 == 0) panelclk0 <= #1 (clkcnt==0);
    else panelclk0 <= #1 0;
    
//TFT just bypass the clock divider
assign BCD = regif.reg3.BCD;
assign panelclk = BCD ? clk : panelclk0;

///////////////read and active signals logic (for controlling the lcd data outputs)
//FSM for read and active signals for STN panel
always @ (posedge clk or posedge reset)
    if(reset) stater <= #1 IDLE;
    else begin
        case(stater)
            IDLE: if(lineactive && (statel == LRUN) && (lcnt == nl1)) stater <= #1 READ;
            READ: if((pixelcnt == ncpl) && (dcnt == pscaler)) stater <= #1 DONE;
            DONE: stater <= #1 IDLE;
            default: stater <= #1 IDLE;
        endcase
    end
//assert one clk cycle read pulse every (pscaler+1) number of clk cycles
assign read = (stater == READ) && (dcnt == pscaler);
//assert active to enable the lcd data output (otherwise data will be gated zero by active)
assign active0 = (stater == READ);
//enable a counter to count (pscaler+1) clk cycles
assign den = (stater == READ);
//the counter
always @ (posedge clk or posedge reset) //count pixel cycles to assert one cycle read pulse
    if(reset) dcnt <= #1 0;
    else if(den) begin
        if(dcnt == pscaler) dcnt <= #1 0;
        else dcnt <= #1 dcnt + 1'b1;
    end else dcnt <= #1 0; 

//counter to count number of lcd data outputs during each line
always @ (posedge clk or posedge reset)
    if(reset) pixelcnt <= #1 0;
    else if(read) pixelcnt <= #1 pixelcnt + 1'b1;
    else if(stater == DONE) pixelcnt <= #1 0;

//assign ncpl=5; //for test only
assign ncpl=regif.reg3.CPL; 
//assign pscaler=2; //for test only
assign pscaler={1'b0, regif.reg3.PCD_HI, regif.reg3.PCD_LO} + 1'b1;

//for TFT
assign active1 = lineactive & (statel == LRUN) & (lcnt >= nl1) & (lcnt <=  (nl2 - 1'b1));
//pipeline needs to be enabled 4-clocks before PPL region
assign startpipe = lineactive & (statel == LRUN) & (lcnt >= (nl1 - 2'b11)) & (lcnt <= (nl2 - 3'b100));
assign active = regif.reg7.LcdTFT ? active1 : active0;
//LCDENA_LCDM
assign LCDENA_LCDM = lineactive & (statel == LRUN) & (lcnt > nl1) & (lcnt <= nl2);



//////////////vertical timing
//positive edge of hsync1
assign hsyncpedge=hsync0 & !hsync1;

//counter to count hsync pulse for vertical timing control
always @ (posedge clk or posedge reset)
begin
    if(reset) vcnt <= #1 0;
    else if(vclr) vcnt <= #1 0;
	 else if(ven && hsyncpedge) begin
        if(vcnt == nv3) vcnt <= #1 0;
        else vcnt <= #1 vcnt + 1'b1;
    end
end

//assign nvsw=1; //for test only
assign nvsw=regif.reg2.VSW;
//assign nvbp=1; //for test only
assign nvbp=regif.reg2.VBP+1'b1;
//assign nvfp=1; //for test only
assign nvfp=regif.reg2.VFP+1'b1;
//assign nlpp=16; //for test only
assign nlpp=regif.reg2.LPP+1'b1;

assign nv0 = nvsw; //end of VSW period
assign nv1 = nv0 + nvbp; //end of VBP period
assign nv2 = nv1 + nlpp; //end of LPP period
assign nv3 = nv2 + nvfp; //end of VFP period

//FSM for vsync pulse
always @ (posedge clk or posedge reset)
begin
    if(reset) statev <= #1 VIDLE;
    else begin
        case(statev)
            VIDLE: if(lcden) statev <= #1 VENABLE;
            VENABLE: begin 
					if(!lcden) statev <= #1 VIDLE;
					else if(lcdpwr) statev <= #1 VRUN;
				end
            VRUN: if(!lcdpwr) statev <= #1 VENABLE;
            default: statev <= #1 VIDLE;
        endcase
    end
end

//vertical counter clear and enable
assign vclr = (statev == VENABLE);
assign ven = (statev == VRUN);

//vsync logic
always @(*) begin
	vsync0 = 1'b0;
	case(statev)
//		VIDLE: if(lcden) vsync0 = 1'b1;
		VENABLE: if(lcdpwr) vsync0 = 1'b1;
		VRUN: begin
			if(hsyncpedge) begin
				if(vcnt == nv3) vsync0 = 1'b1;
				else if(vcnt == nv0) vsync0 = 0;
				else vsync0 = vsync;
			end
			else vsync0 = vsync;
		end
		default: vsync0 = vsync;
	endcase
end

//register vsync0
always @ (posedge clk or posedge reset)
    if(reset) vsync <= #1 0;
    else vsync <= #1 vsync0;

//lineactive signal logic (indicating active lines during LPP period)
always @(*) begin
	lineactive0 = 0;
	case(statev)
		VRUN: begin
			if(hsyncpedge) begin
				if(vcnt == nv1) lineactive0 = 1'b1;
				else if(vcnt == nv2) lineactive0 = 0;
				else lineactive0 = lineactive;
			end
			else lineactive0 = lineactive;
		end
		default: lineactive0 = lineactive;
	endcase
end

always @ (posedge clk or posedge reset)
    if(reset) lineactive <= #1 0;
    else      lineactive <= #1 lineactive0;	

endmodule
