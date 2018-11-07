
typedef enum {INIT,DELAY,OUT} LDE_STATE;
typedef enum bit [3:0] {VRST,VSW,VBP,LPP,VFP} vpixel_state;
typedef enum bit [3:0] {HRST,HSW,HBP,PPL,HFP} hpixel_state;

module timing_control(input pixel_clk,rst,cclk,
                      input LCD_TIMH lcd_timh,input LCD_TIMV lcd_timv,input lcd_en,// lcd_en reg input
                      input lcd_pwr,// power reg input
                      output LCDPWR,output LCDDCLK,
                      output LCDFP, output LCDLE, output LCDLP,/*output LCDVD,*/
                      output [9:0] x_count,y_count,output pixel_disp_on,LCDENA_LCDM,Lcdena_lcdm,input LCD_LE lcd_le,output fp_pulse);

//LCD_TIMH      lcd_timh;
//LCD_TIMV      lcd_timv;
//LCD_LE        lcd_le;

reg lcdena_lcdm; 
reg [11:0] h_pixel;
reg [11:0] v_pixel;    
reg [11:0] line_length;
reg [11:0] frame_length;    
reg [2:0]  le_count;
reg        le_start;
reg [6:0]  lcdle_delay_count;
reg [2:0]  lcdle_hold_count;

reg line_clk;
reg [9:0] x_cor;
reg [9:0] y_cor;    

////////////////////////////////////////////////////////////

reg [11:0] counter_clicks,counter_clicks_nxt;
reg [11:0] hcounter_clicks,hcounter_clicks_nxt;
reg fp,lp,lineclk,lineclk_nxt;

vpixel_state vstate,vnxtstate;
hpixel_state hstate,hnxtstate,linestate,nxtlinestate;

assign  LCDFP = fp;
assign  fp_pulse = fp;
assign  LCDLP = lp;
assign  LCDDCLK = pixel_clk;
assign  LCDENA_LCDM = lcdena_lcdm;
assign  Lcdena_lcdm = lcdena_lcdm;

always @(posedge lineclk or posedge rst) begin 
   if(rst) begin
     vstate <= #0 VRST;
     counter_clicks <= #0 12'hfff; 
   end else begin 
               vstate <= #1 vnxtstate;
               counter_clicks <= #1 counter_clicks_nxt;
            end
end 

/*always @(posedge pixel_clk or posedge rst) begin 
   if(rst) begin
     hstate <= #0 HRST;
     //hcounter_clicks <= #0 12'hfff; 
     hcounter_clicks <= #0 0; 
   end else begin 
               hstate <= #1 hnxtstate;
               hcounter_clicks <= #1 hcounter_clicks_nxt;
            end
end*/

reg [11:0] line_count,line_count_nxt;
 
always @(posedge pixel_clk or posedge rst) begin 
   if(rst) begin
     line_count <= #0 12'hfff;
     linestate <= #0 HRST;
   end else begin 
               line_count <= #1 line_count_nxt;
               linestate  <= #1 nxtlinestate;
            end
end

/// vertical case states
always @(*) begin
     fp = 0; 
     vnxtstate = VRST;
     counter_clicks_nxt = counter_clicks + 1;
    case(vstate) 
      VRST : begin 
               if(lcd_en) begin
		vnxtstate = VFP; 
                counter_clicks_nxt = 0;
               end else begin 
		vnxtstate = VRST; 
                counter_clicks_nxt = 0;
			end
            end
      VSW : begin 
               if(lcd_en ) begin
                 fp = 1;
                 if(counter_clicks == lcd_timv.VSW) begin
                   vnxtstate = VBP;
                   counter_clicks_nxt = 0;
                 end else begin
                            vnxtstate = VSW;
                          end
		end  
            end
      VBP : begin 
               if(lcd_en ) begin
                 if(counter_clicks == lcd_timv.VBP) begin
                   vnxtstate = LPP;
                   counter_clicks_nxt = 0;
                 end else begin
                            vnxtstate = VBP;
                          end
		end 
            end
      LPP : begin 
               if(lcd_en ) begin
                 if(counter_clicks == lcd_timv.LPP) begin
                   vnxtstate = VFP;
                   counter_clicks_nxt = 0;
                 end else begin
                            vnxtstate = LPP;
                          end
		end 
            end
      VFP : begin 
               if(lcd_en ) begin
                 if(counter_clicks == lcd_timv.VFP) begin
                   vnxtstate = VSW;
                   counter_clicks_nxt = 0;
                 end else begin
                            vnxtstate = VFP;
                          end
		end 
            end
    endcase
end

/// horizontal case states
/*always @(*) begin 
  lp = 0;
  hnxtstate = HRST;
  hcounter_clicks_nxt = (vstate == LPP) ? (hcounter_clicks + 1):0;
//  if(vstate == LPP) begin 
    case(hstate) 
      HRST : begin 
               if(lcd_en && vstate == LPP) begin
		hnxtstate = HSW; 
                hcounter_clicks_nxt = 0;
               end else begin 
		hnxtstate = HRST; 
                hcounter_clicks_nxt = 0;
			end
            end
      HSW : begin 
               lp = 1;
               if(lcd_en ) begin
                 if(hcounter_clicks == lcd_timh.HSW) begin
                   hnxtstate = HBP;
                   hcounter_clicks_nxt = 0;
                 end else begin
                            hnxtstate = HSW;
                          end
		end  
            end
      HBP : begin 
               if(lcd_en ) begin
                 if(hcounter_clicks == lcd_timh.HBP) begin
                   hnxtstate = PPL;
                   hcounter_clicks_nxt = 0;
                 end else begin
                            hnxtstate = HBP;
                          end
		end 
            end
      PPL : begin 
               if(lcd_en ) begin
                 if(hcounter_clicks == ((16*(lcd_timh.PPL+1))-1)) begin
                   hnxtstate = HFP;
                   hcounter_clicks_nxt = 0;
                 end else begin
                            hnxtstate = PPL;
                          end
		end 
            end
      HFP : begin 
               if(lcd_en ) begin
                 if(hcounter_clicks == lcd_timh.HFP) begin
                     hnxtstate = HRST;
                     hcounter_clicks_nxt = hcounter_clicks;
                 end else begin
                            hnxtstate = HFP;
                          end
		end 
            end
    endcase
//  end 
end 
*/

/// line clk states
always @(*) begin
  lcdena_lcdm = 0;
  lp = 0;
  lineclk = (linestate==HSW);
  line_count_nxt = line_count + 1;
    case(linestate) 
      HRST : begin 
               if(lcd_en) begin
		nxtlinestate = HSW; 
               end else begin 
		nxtlinestate = HRST; 
                line_count_nxt   = 0;
			end
            end
      HSW : begin 
               if(lcd_en ) begin
                 lp = 1;
                 if(line_count == lcd_timh.HSW) begin
                   nxtlinestate = HBP;
                   line_count_nxt = 0;
                 end else begin
                            nxtlinestate = HSW;
                          end
		end  
            end
      HBP : begin 
               if(lcd_en ) begin
                 if(line_count == lcd_timh.HBP) begin
                   nxtlinestate = PPL;
                   line_count_nxt = 0;
                 end else begin
                            nxtlinestate = HBP;
                          end
		end 
            end
      PPL : begin 
               if(lcd_en ) begin
                 lcdena_lcdm = (vstate==LPP)?1:0;
                 if(line_count == ((16*(lcd_timh.PPL+1))-1)) begin
                   nxtlinestate = HFP;
                   line_count_nxt = 0;
                 end else begin
                            nxtlinestate = PPL;
                          end
		end 
            end
      HFP : begin 
               if(lcd_en ) begin
                 if(line_count == lcd_timh.HFP) begin
                   nxtlinestate = HSW;
                   line_count_nxt = 0;
                 end else begin
                            nxtlinestate = HFP;
                          end
		end 
            end
    endcase
end 

///////////////////////////////////////////////////////////


LDE_STATE lcdle_cur_state,lcdle_nxt_state;

//LCD power display register
assign LCDPWR = rst ? 0:lcd_pwr;

//LCDLE generation 
always @(posedge cclk or posedge rst) begin 
  if(rst) begin
   lcdle_cur_state <= #0 INIT; 
  end else begin 
           lcdle_cur_state <= #1 lcdle_nxt_state;    
  end
end 


//lcdle delay counter
always @(posedge cclk or posedge rst) begin
   if(rst) begin
     lcdle_delay_count <= #0 lcd_le.LED;
     lcdle_hold_count <= #0 3;
   end else begin
             if(lcd_en) begin  
             lcdle_delay_count <= #1 ((lcdle_cur_state == DELAY)?  (lcdle_delay_count - 1) : lcd_le.LED);
             lcdle_hold_count <= #1 ((lcdle_cur_state == OUT)?  (lcdle_hold_count - 1) : 3);
             end
            end
end 

// state selection logic 
always @(*) begin
  
  lcdle_nxt_state = INIT;
 
 if(lcd_en) begin  

   case(lcdle_cur_state)
    INIT: begin
           if(linestate == HFP && nxtlinestate == HSW) begin
               lcdle_nxt_state = (lcd_le.LEE==0) ? OUT:DELAY;
           end else begin 
		     lcdle_nxt_state =  lcdle_cur_state;
                    end  
          end
    DELAY:begin
            if(lcdle_delay_count==0) begin
               lcdle_nxt_state = OUT; 
            end else begin 
               lcdle_nxt_state = lcdle_cur_state;
            end
	  end
    OUT  :begin
            if(lcdle_hold_count==0) begin
               lcdle_nxt_state = INIT;// 4 cycle pouch over 
            end else begin 
               lcdle_nxt_state = lcdle_cur_state;
                     end
          end
   endcase

 end 
end

assign LCDLE = (rst | !lcd_en)  ? 0:((lcdle_hold_count >0 )&& (lcdle_hold_count<3));
wire x_cur_clk;
assign x_cur_clk = (linestate == HSW);

// x_cur logic
always @(posedge x_cur_clk or posedge rst) begin 
 if(rst) begin
   x_cor <= #0 0; 
 end else begin
            x_cor <= #1 (vstate==LPP) ? (x_cor + 1):0; 
          end
end 
// y_cur logic
always @(posedge pixel_clk or posedge rst) begin 
 if(rst) begin 
   y_cor <= #0 0;
 end else begin
            if(lcd_en) begin  
            case(1)
             (vstate==LPP && linestate==PPL):   y_cor <= #1 y_cor + 1; // incr y count
             (linestate==VFP && vstate==LPP):   y_cor <= #1 0; // reset y count at end of line
				         
            endcase
            end
          end
end 
// pixel_disp_on
//wire pixel_disp_on;
assign pixel_disp_on =  lcd_en? (vstate==LPP && linestate==PPL):0;

assign x_count = x_cor;
assign y_count = y_cor;

endmodule 
