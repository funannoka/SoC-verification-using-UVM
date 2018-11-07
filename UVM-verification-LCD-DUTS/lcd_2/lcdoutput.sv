//lcd output fifo and select

module lcdoutput(
input logic clk, //this is the pixel clock
input logic reset, 
input logic read, //from timing controller read STN fifo
input logic active, //from timing controller enable output register
input logic [7:0] pixelstn, //STN pixel
input logic write, //STN write
output logic full, //STN full flag
input logic [23:0] pixeltft, //TFT pixel
output logic [23:0] lcdout,
REGISTERS regif
);

//fifo signals for the STN display
logic [7:0] mems[0:3];
logic [2:0] cnt0;
logic [1:0] wptr0, rptr0;
logic read0, empty0;
//fifo signals for the STN display
logic [23:0] memt[0:1];
//outputs
logic [7:0] lcdout0;
logic [23:0] lcdout1, lcdout_m;
logic select;
logic [2:0] lcdbpp;

/////////select panels
assign select=regif.reg7.LcdTFT;
assign lcdbpp=regif.reg7.LcdBpp;

////////////fifo for the STN display
assign read0=read & (!select);

always @ (posedge clk)
    if(write && !full) mems[wptr0] <= #1 pixelstn;
    
always @(*)
    if(active) lcdout0=mems[rptr0];
    else lcdout0='0;
    
always @ (posedge clk or posedge reset)
    if(reset) wptr0<=#1 '0;
    else if(write && !full) wptr0<=#1 wptr0+1'b1;

always @ (posedge clk or posedge reset)
    if(reset) rptr0<= #1 '0;
    else if(read0 && !empty0) rptr0<= #1 rptr0+1'b1;
    
always @ (posedge clk or posedge reset)
begin
    if(reset) cnt0<= #1 '0;
    else if(!full && write && !(read0 && !empty0)) cnt0<= #1 cnt0+1'b1;
    else if(!empty0 && read0 && !(write && !full)) cnt0<= #1 cnt0-1'b1;
end

always @ (posedge clk or posedge reset)
begin
    if(reset) full<= #1 '0;
    else if(cnt0==3 && write && !read0) full<= #1 1'b1;
    else if(cnt0==4 && read0) full<= #1 0;
end

always @ (posedge clk or posedge reset)
begin
    if(reset) empty0<= #1 1;
    else if(cnt0==0 && write) empty0<= #1 0;
    else if(cnt0==1 && read0 && !write) empty0<= #1 1'b1;
end

/////////fifo for TFT display
assign lcdout1 = pixeltft;

///////////lcd output select
always @(*) begin
    case(select)
        0: lcdout_m = {16'b0, lcdout0};
        1: begin
            case(lcdbpp)
                3'b101: lcdout_m = lcdout1;
                3'b110: lcdout_m = {lcdout1[15:11], 3'b0, lcdout1[10:5], 2'b0, lcdout1[4:0], 3'b0};
                3'b111: lcdout_m = {lcdout1[11:8], 4'b0, lcdout1[7:4], 4'b0, lcdout1[3:0], 4'b0};
                default: lcdout_m = {lcdout1[14:10], lcdout1[15], 2'b0, lcdout1[9:5], lcdout1[15], 2'b0, lcdout1[4:0], lcdout1[15], 2'b0};
            endcase
        end
        default:;
    endcase
end

//pipeline register for pixel output
always @ (posedge clk or posedge reset)
	if(reset) lcdout <=  #1 0;
	else if(active) lcdout <=  #1 lcdout_m;
	else lcdout <=  #1 0;


endmodule
		
