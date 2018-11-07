
module timing_ctrl(t_clk_if,LCDDCLK_full,line_clk_in,panel_data,lcdout_if,stopin_timing_ctrl,one_time_sync);
 input LCDDCLK_full,line_clk_in;
 input [23:0] panel_data;
AHBIF t_clk_if;
LCDOUT lcdout_if;
logic lcddclk,lcdena_lcdm,lcdfp,lcdlp;
logic [23:0] lcdvd;
logic clk_out, line_clk;
wire pixel_clk;
logic tmp_cnt;
output logic stopin_timing_ctrl,one_time_sync;
int reg_vsw_change_f, reg_vsw_change;

logic [2:0] ps,ns;
parameter IDLE         = 3'b000;
parameter V_VSW        = 3'b001;
parameter V_VBP        = 3'b010;
parameter H_HSW        = 3'b011;
parameter H_HBP        = 3'b100;
parameter H_PANEL_DATA = 3'b101;
parameter H_HFP        = 3'b110;
parameter V_VFP        = 3'b111;

int vsw_cnt,vbp_cnt,hsw_cnt, hbp_cnt,h_panel_data_cnt, hfp_cnt,vfp_cnt,lpp_cnt,c_ounter;

initial
begin
  vsw_cnt = 0;
  vbp_cnt = 0;
  hsw_cnt = 0;
  hbp_cnt = 0;
  h_panel_data_cnt = 0;
  hfp_cnt = 0;
  vfp_cnt = 0;
  lpp_cnt = 0;
  c_ounter = 0;
  stopin_timing_ctrl = 1;
  lcdfp = 0;
  lcdlp = 0;
  lcdvd = 0;
  lcdena_lcdm = 0;
  lcddclk = 0;
end

assign pixel_clk = t_clk_if.HCLK;

always @(posedge clk_out or posedge t_clk_if.HRESET)
begin
  if (t_clk_if.HRESET)
  begin
    ps <= IDLE;
    tmp_cnt <= 0;
    vsw_cnt <= 0;
    vbp_cnt <= 0;
    hsw_cnt <= 0;
    hbp_cnt <= 0;
    h_panel_data_cnt <= 0;
    hfp_cnt <= 0;
    vfp_cnt <= 0;
    lpp_cnt <= 0;
    c_ounter <= 0;
    stopin_timing_ctrl <= 1;
    reg_vsw_change_f <= 0;
  end
  else
  begin
    ps <= ns;
    tmp_cnt <= tmp_cnt+1;
    reg_vsw_change_f <= reg_vsw_change;
  end
end

assign line_clk = line_clk_in;
assign reg_vsw_change = lcd.reg_mem_map.CRSR_IMG[255];
//assign reg_vsw_change = lcd.reg_mem_map.LCD_TIMV;

assign lcdout_if.LCDVD = lcdvd;
assign lcdout_if.LCDLP = lcdlp;
assign lcdout_if.LCDFP = lcdfp;
assign lcdout_if.LCDDCLK = lcddclk;
assign lcdout_if.LCDENA_LCDM = lcdena_lcdm;

always@(*)
begin
  case(ps)
    IDLE:  begin clk_out = pixel_clk; end
    V_VSW: begin clk_out = line_clk; lcddclk = LCDDCLK_full; end
    V_VBP: begin clk_out = line_clk; lcddclk = LCDDCLK_full; end
    H_HSW: begin clk_out = pixel_clk; lcddclk = 0; end
    H_HBP: begin clk_out = pixel_clk; lcddclk = LCDDCLK_full; end
    H_PANEL_DATA: begin clk_out = pixel_clk; lcddclk = LCDDCLK_full; end
    H_HFP: begin clk_out = pixel_clk; lcddclk = LCDDCLK_full; end
    V_VFP: begin clk_out = line_clk; lcddclk = LCDDCLK_full; end
  endcase
end

//always @(posedge t_clk_if.HCLK or posedge t_clk_if.HRESET)
//begin
//  if (t_clk_if.HRESET)
//    reg_vsw_change_f <= 0;
//  else
//    reg_vsw_change_f <= reg_vsw_change;
//end


always @(ps or tmp_cnt)
begin
  case(ps)
  
  IDLE:
  begin
#0    stopin_timing_ctrl = 1'b1;
    lcdena_lcdm =0;
//    if(idle_cnt != 464/403) // make sure 2 things - register data should get filled via slave by this time & lcdfp should start with posedge of lineclk
    if(reg_vsw_change_f != reg_vsw_change && reg_vsw_change != 0)
    begin
      ns = V_VSW;
    end
    else
    begin
      ns = IDLE;
      lcdvd[23:0] = 0;
    end
  end
  V_VSW:
  begin
    stopin_timing_ctrl = 1'b1;
    if (vsw_cnt != ((lcd.reg_mem_map.LCD_TIMV.VSW+1)-1))
    begin
    lcdfp = 1;
    lcdena_lcdm =0;
    vsw_cnt = vsw_cnt + 1;
    ns = V_VSW;
    lcdvd[23:0] = 0;
    end
    else
    begin
      ns = V_VBP;
      vsw_cnt = 0;
    end
  end
  
  V_VBP:
  begin
    stopin_timing_ctrl = 1'b1;
    one_time_sync = 0;
    lcdena_lcdm =0;
    if (vbp_cnt != ((lcd.reg_mem_map.LCD_TIMV.VBP)-1))
    begin
      lcdfp = 0;
      vbp_cnt = vbp_cnt + 1;
      ns = V_VBP;
      lcdvd[23:0] =0;
      if(vbp_cnt == 2)
        one_time_sync = 1;
    end
    else
    begin
      vbp_cnt = 0;
      ns = H_HSW;
    end
  end
  
  H_HSW:
  begin
    stopin_timing_ctrl = 1'b1;
    lcdena_lcdm =0;
    if (hsw_cnt != ((lcd.reg_mem_map.LCD_TIMH.HSW+1)-1))
    begin
      lcdlp = 1;
      lcdvd[23:0] = 0; 
      hsw_cnt = hsw_cnt + 1;
      ns = H_HSW;
    end
    else
    begin
      hsw_cnt = 0;
      ns = H_HBP;
    end
  end
 
  H_HBP:
  begin
    stopin_timing_ctrl = 1'b1;
    lcdena_lcdm =0;
    if (hbp_cnt != ((lcd.reg_mem_map.LCD_TIMH.HBP+1)-1))
    begin
    lcdlp = 0;
    lcdvd[23:0] = 0;  
    hbp_cnt = hbp_cnt + 1;
    ns = H_HBP;
    end
    else
    begin
      ns = H_PANEL_DATA;
      hbp_cnt = 0;
    end
  end
  
  H_PANEL_DATA:
  begin
    lcdena_lcdm =1;
    if (h_panel_data_cnt != (((16*(lcd.reg_mem_map.LCD_TIMH.PPL+1))*((lcd.reg_mem_map.LCD_CFG.CLKDIV)+1))-1))
    begin
      if(h_panel_data_cnt == 0)
      begin
        stopin_timing_ctrl = 0;
        if (lcd.reg_mem_map.LCD_CTRL.LcdTFT ==0)
          lcdvd[23:0] = {8'b0,panel_data[15:0]}; 
        else if (lcd.reg_mem_map.LCD_CTRL.LcdTFT)
        begin
          lcdvd[23:0] = panel_data[23:0];
        end
      end
      else
      begin
        c_ounter = c_ounter + 1;
        if (c_ounter != ((lcd.reg_mem_map.LCD_CFG.CLKDIV)+1))
        begin
          stopin_timing_ctrl =1;
        end
        else 
        begin
          c_ounter = 0;
          stopin_timing_ctrl = 0;
          if (lcd.reg_mem_map.LCD_CTRL.LcdTFT ==0)
            lcdvd[23:0] = {8'b0,panel_data[15:0]}; 
          else if (lcd.reg_mem_map.LCD_CTRL.LcdTFT)
          begin
            lcdvd[23:0] = panel_data[23:0];
          end
        end
      end
      lcdlp = 0;
      h_panel_data_cnt = h_panel_data_cnt + 1;
      ns = H_PANEL_DATA;
    end
    else
    begin
      ns = H_HFP;
      h_panel_data_cnt = 0;
      c_ounter = 0;
    end
  end
    
  H_HFP:
  begin
    stopin_timing_ctrl = 1'b1;
    lcdena_lcdm =0;
    if (hfp_cnt != ((lcd.reg_mem_map.LCD_TIMH.HFP+1)-1))
    begin
      lcdlp = 0;
      lcdvd[23:0] = 0; 
      hfp_cnt = hfp_cnt + 1;
      ns = H_HFP;
    end
    else
    begin
      if (lpp_cnt != ((lcd.reg_mem_map.LCD_TIMV.LPP+1)-1))
      begin
        ns = H_HSW;
        lpp_cnt = lpp_cnt +1;
        hfp_cnt = 0;
      end 
      else
      begin       
        ns = V_VFP;
        hfp_cnt = 0;
        lpp_cnt = 0;
      end
    end
  end
  
  V_VFP:
  begin
    stopin_timing_ctrl = 1'b1;
    lcdena_lcdm =0;
    if (vfp_cnt != ((lcd.reg_mem_map.LCD_TIMV.VFP)-1))
    begin
      lcdfp = 0;
      vfp_cnt = vfp_cnt + 1;
      ns = V_VFP;
      lcdvd[23:0] =0;
    end
    else
    begin
      ns = V_VSW;
      vfp_cnt =0;
    end
  end
  endcase
end

endmodule
