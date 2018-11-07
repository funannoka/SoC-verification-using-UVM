
`timescale 1ns/10ps
`include "lcd_registers.sv"
`include "lcd_mem_map.sv"
`include "ahb_master.sv"
`include "ahb_slave.sv"
`include "clk_gen.sv"
`include "timing_ctrl.sv"
`include "fifo.sv"
`include "pix_ser.sv"
`include "ram_palette.sv"


module lcd (AHBIF ahb_clk_intf, AHBIF ahb_m_intf, AHBIF ahb_s_intf ,MEMIF fifo0_if, MEMIF fifo1_if,RAM128IF cpal_if,RAM256IF crsr_if,LCDOUT lcdout);
  logic [31:0] store_rd_dt;
  logic wr_en_upper,wr_en_lower,fifo_watermark,fifo_empty_upper,fifo_empty_lower,fifo_watermark_lower,fifo_watermark_upper,rd_en_upper,rd_en_lower,LCDDCLK_full,line_clk;
  logic [31:0] data_out_upper,data_out_lower;
  logic [23:0] fifo_data_out, d_out_pix_ser, ram_d_out;
  logic [31:0] mem_add_rd,mem_add_wr,data_wr;
  logic [31:0] data_rd;
  logic stopin_timing_ctrl,one_time_sync;
  int rd_cnt;
  logic rd_en_pix;
  logic valid, validn, valid1, valid1n, valid2, valid2n, rd_en, pushout2; 
  logic stopin2, stopin3, pushout1, fifo_empty;
  logic [31:0] data_out_fifo_m, data_out_fifo_f, d_out_pix_ser_m, d_out_pix_ser_f;

  ahb_master ahb_m (.m_if(ahb_m_intf.AHBM),.m_clk_if(ahb_clk_intf.AHBCLKS),.store_rd_dt(store_rd_dt),.wr_en_upper(wr_en_upper), .wr_en_lower(wr_en_lower),.fifo_watermark(fifo_watermark),.v_sync(lcdout.LCDFP));

  ahb_slave ahb_s (.s_if(ahb_s_intf.AHBS),.s_clk_if(ahb_clk_intf.AHBCLKS),.mem_add_rd(mem_add_rd),.mem_add_wr(mem_add_wr),.data_wr(data_wr),.data_rd(data_rd));


  fifo upper_panel_fifo (.f_clk_if(ahb_clk_intf.AHBCLKS),.fifo_mem_if(fifo0_if.F0),.data_in(store_rd_dt), .wr_en(wr_en_upper), .rd_en(rd_en_upper), .data_out(data_out_upper), .fifo_empty(fifo_empty_upper),.fifo_watermark(fifo_watermark_upper), .v_sync(lcdout.LCDFP),.stopin(stopin3));

  fifo lower_panel_fifo (.f_clk_if(ahb_clk_intf.AHBCLKS),.fifo_mem_if(fifo1_if.F0),.data_in(store_rd_dt), .wr_en(wr_en_lower), .rd_en(rd_en_lower), .data_out(data_out_lower), .fifo_empty(fifo_empty_lower),.fifo_watermark(fifo_watermark_lower), .v_sync(lcdout.LCDFP),.stopin(stopin3));

  mem_map reg_mem_map (.mem_add_rd(mem_add_rd),.mem_add_wr(mem_add_wr),.HRDATA(data_rd),.HWDATA(data_wr),.HWRITE(ahb_s_intf.HWRITE),.pal_write(cpal_if.write),.pal_wdata(cpal_if.wdata),.pal_waddr(cpal_if.waddr));

  timing_ctrl time_ctrl (.t_clk_if(ahb_clk_intf.AHBCLKS),.LCDDCLK_full(LCDDCLK_full),.line_clk_in(line_clk),.panel_data(ram_d_out),.lcdout_if(lcdout.O0),.stopin_timing_ctrl(stopin_timing_ctrl),.one_time_sync(one_time_sync));

  clk_gen clock_gen (.LCDDCLK_full(LCDDCLK_full),.line_clk(line_clk),.c_clk_if(ahb_clk_intf.AHBCLKS));

  pixel_ser pixel_serial (.m_clk_if (ahb_clk_intf.AHBCLKS), .din_pix_ser(data_out_upper), .actual_read_en(rd_en_pix), .dout_pix_ser(d_out_pix_ser), .fifo_empty(fifo_empty), .stopin(stopin_timing_ctrl),.lcdfp(lcdout.LCDFP),.one_time_sync(one_time_sync),.v_sync(lcdout.LCDFP));
//
//
  ram_palette ramram (.ram_d_out_temp(ram_d_out), .pal_raddr(cpal_if.raddr), .pal_rdata(cpal_if.rdata), .d_out_pix_ser(d_out_pix_ser), .clk_if(ahb_clk_intf.AHBCLKS), .stopin(stopin_timing_ctrl));


//  assign validn = (~valid & pushout1) | (valid & pushout1 & ~stopin_timing_ctrl) | (valid & stopin_timing_ctrl);
//  assign stopin1 = valid & stopin_timing_ctrl;
//  assign pushout = valid & ~stopin_timing_ctrl;
//  assign d_out_pix_ser_m = stopin1 ? d_out_pix_ser_f : d_out_pix_ser;

//  assign valid1n = (~valid1 & rd_en_pix) | (valid1 & rd_en_pix & ~stopin1) | (valid1 & stopin1);
//  assign valid1n = (~valid1 & pushout2) | (valid1 & pushout2 & ~stopin1) | (valid1 & stopin1);
//  assign stopin2 = valid1 & stopin1;
  assign stopin2_rd_en = ~rd_en_pix;
//  assign pushout1 = valid1 & ~stopin1;
//  assign data_out_fifo_m = stopin2_rd_en ? data_out_fifo_f : data_out_upper;

  assign valid2n = (~valid2 & rd_en) | (valid2 & rd_en & ~stopin2_rd_en) | (valid2 & stopin2_rd_en);
  assign stopin3 = valid2 & stopin2_rd_en;
  assign pushout2 = valid2 & ~stopin2_rd_en;


  assign fifo_watermark = fifo_watermark_upper;
  assign fifo_empty = fifo_empty_upper;
  assign rd_en = rd_en_upper;


  initial
  begin
    rd_en_lower = 0;
    rd_en_upper = 0;
    rd_cnt = 0; 
//    valid1 = 0;
    valid2 = 0;
//    data_out_fifo_f = 0;
  end

  always @(ahb_clk_intf.HRESET or fifo_empty or stopin2_rd_en) begin
  begin
    if(ahb_clk_intf.HRESET)
    begin
      rd_en_upper = 0;
      rd_en_lower = 0;
    end
    else
    begin
      if(~fifo_empty && ~stopin2_rd_en)
      begin
        rd_cnt = rd_cnt + 1;
        if(lcd.reg_mem_map.LCD_CTRL.LcdDual)
        begin
          if(rd_cnt %2 != 0)
          begin
            rd_en_upper = 1;
          end
          else
          begin
            rd_en_lower = 1;
          end
        end
        else
        begin
          rd_en_upper = 1;
        end
      end
      else
      begin
        rd_en_upper = 0;
        rd_en_lower = 0;
      end
    end
  end
end
assign reset = ahb_clk_intf.HRESET || lcdout.LCDFP;
always @(posedge ahb_clk_intf.HCLK or posedge reset) begin
  if(reset) begin
//    data_out_fifo_f <= 0;
//    d_out_pix_ser_f <= 0;
//    valid <= 0;
//    valid1 <= 0;
    valid2 <= 0;
  end else begin
//    data_out_fifo_f <= data_out_fifo_m;
//    d_out_pix_ser_f <= d_out_pix_ser_m;
//    valid <= validn;
//    valid1 <= valid1n;
    valid2 <= valid2n;
  end
end


endmodule
