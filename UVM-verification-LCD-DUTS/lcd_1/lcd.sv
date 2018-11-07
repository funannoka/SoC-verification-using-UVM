`include "ahb_reg.sv"
`include "master.sv"
`include "slave.sv"
`include "dma_fifo.sv"
`include "dma_fifo_ctrl_logic.sv"
//`include "timing_control_edit.sv"
`include "timing_control_sm.sv"
`include "panel_clock_generator_new.sv"
`include "pixel_serializer_edit.sv"
`include "decoder.sv"

module lcd( AHBIF.AHBCLKS clock,AHBIF.AHBM master,AHBIF.AHBS slave,MEMIF memif0,
MEMIF memif1,RAM128IF cpal,RAM256IF crsr,LCDOUT lcdoutif
);

LCD_CFG    lcd_reg0;
LCD_TIMH    lcd_reg1;
LCD_TIMV    lcd_reg2;
LCD_POL     lcd_reg3;
LCD_LE      lcd_reg4;
LCD_UPBASE  lcd_reg5;
LCD_LPBASE  lcd_reg6;
LCD_CTRL    lcd_reg7;
LCD_INTMSK  lcd_reg8;
LCD_INTRAW  lcd_reg9;
LCD_INTSTAT lcd_reg10;
LCD_INTCLR  lcd_reg11;
LCD_UPCURR  lcd_reg12;
LCD_LPCURR  lcd_reg13;
CRSR_CTRL   lcd_reg14;
CRSR_CFG    lcd_reg15;
CRSR_PAL0   lcd_reg16;
CRSR_PAL1   lcd_reg17;
CRSR_XY     lcd_reg18;
CRSR_CLIP   lcd_reg19;
CRSR_INTMSK lcd_reg20;
CRSR_INTCLR lcd_reg21;
CRSR_INTRAW lcd_reg22;
CRSR_INTSTAT lcd_reg23;

//lcd l(Q.AHBCLKS, Q.AHBM, Q.AHBS, R.F0, S.F0,cpal.R0,crsr.R0,lcdout.O0);
wire [31:0]   rdata_rpal_slave;
wire          write_slave_rampal; 
wire [31:0]   data_slave_rampal; 
wire [7:0]    addr_slave_rampal; 

LCD_slave LCD_slave_inst ( 
.HCLK(clock.HCLK),
.HRESET(clock.HRESET),
.HSEL(slave.HSEL),
.HADDR(slave.HADDR),
.HWDATA(slave.HWDATA),
.HWRITE(slave.HWRITE),
.HTRANS(slave.HTRANS),
.HSIZE(slave.HSIZE),
.HBURST(slave.HBURST),
.HRDATA(slave.HRDATA),
.HREADY(slave.HREADY),
.HRESP(slave.HRESP),
.lcd_cfg     (lcd_reg0),
.lcd_timh    (lcd_reg1),
.lcd_timv    (lcd_reg2),
.lcd_pol     (lcd_reg3),
.lcd_le      (lcd_reg4),
.lcd_upbase  (lcd_reg5),
.lcd_lpbase  (lcd_reg6),
.lcd_ctrl    (lcd_reg7),
.lcd_intmsk  (lcd_reg8),
.lcd_intraw  (lcd_reg9),
.lcd_intstat (lcd_reg10),
.lcd_intclr  (lcd_reg11),
.lcd_upcurr  (lcd_reg12),
.lcd_lpcurr  (lcd_reg13),
.crsr_ctrl   (lcd_reg14),
.crsr_cfg    (lcd_reg15),
.crsr_pal0   (lcd_reg16),
.crsr_pal1   (lcd_reg17),
.crsr_xy     (lcd_reg18),
.crsr_clip   (lcd_reg19),
.crsr_intmsk (lcd_reg20),
.crsr_intclr (lcd_reg21),
.crsr_intraw (lcd_reg22),
.crsr_intstat(lcd_reg23),
.rdata_rpal_slave  (rdata_rpal_slave  ),
.write_slave_rampal(write_slave_rampal), 
.data_slave_rampal (data_slave_rampal ), 
.addr_slave_rampal (addr_slave_rampal ) 
);


wire fifofull;
wire [31:0] data_from_ahbmaster;

LCD_master LCD_master_inst (
.HCLK(clock.HCLK),
.HRESET(clock.HRESET),
.HGRANT(master.mHGRANT),
.HREADY(master.mHREADY),
.HRDATA(master.mHRDATA),
.HRESP(master.mHRESP),
.lcd_en_i(lcd_reg7.LCDEN),
//.HWDATA(master.mHWDATA),
.HADDR(master.mHADDR),
.HBUSREQ(master.mHBUSREQ),
.HWRITE(master.mHWRITE),
.HTRANS(master.mHTRANS),
.HBURST(master.mHBURST),
.HSIZE(master.mHSIZE),
.lcd_upbase(lcd_reg5),
.FIFO_full(fifofull),
.fifo_push(fifo_push),
.valid(lcd_reg7.LCDEN),
.dma_req_in(dma_req_from_fifo),
.FIFO_data(data_from_ahbmaster),
.fp_pulse (fp_pulse)
);

wire pixel_clk,lcddclk,lcdena_lcdm;
reg [9:0] x_count,y_count;
reg pixel_disp_on;

//Timing controller
timing_control time_ctrl
( .pixel_clk(pixel_clk),
  .rst(clock.HRESET),
//  .lcddclk(lcddclk),
  .cclk(clock.HCLK),
  .lcd_timh(lcd_reg1/*32'h0304080c*/ ),
  .lcd_timv(lcd_reg2),
  .lcd_en(lcd_reg7.LCDEN),
  .lcd_pwr(lcd_reg7.LCDPWR),
  .LCDPWR(lcdoutif.LCDPWR),
  .LCDDCLK(lcdoutif.LCDDCLK),
  .LCDFP(lcdoutif.LCDFP),
  .LCDLE(lcdoutif.LCDLE),
  .LCDLP(lcdoutif.LCDLP),
  //.LCDVD(lcdoutif.LCDVD),
  .LCDENA_LCDM(lcdoutif.LCDENA_LCDM),
  .x_count(x_count),
  .y_count(y_count),
  .pixel_disp_on(pixel_disp_on),
  .Lcdena_lcdm(lcdena_lcdm),
  .lcd_le      (lcd_reg4),
  .fp_pulse    (fp_pulse)
);


//clock divider circuit 
clk_generator clk_div(
.HCLK   (clock.HCLK),
.rst    (clock.HRESET),
.lcd_cfg(lcd_reg0/* 32'h0000_0003 */),
.lcd_pol(lcd_reg3),
.LCDDCLK(lcddclk),
.pixel_clk(pixel_clk),
.en(lcd_reg7.LCDEN),
.pixel_clk_phaseshift    (pixel_clk_phaseshift)
);

wire pull_from_pixelserial;
wire [31:0] data_out;

dma_fifo_ctrl_logic dma_logic
(
 .clk(clock.HCLK),
 .rst(clock.HRESET),
 .push(fifo_push),
 .pull(pull_from_pixelserial),
 .data_in(data_from_ahbmaster),
 .lcd_ctrl(lcd_reg7),
 .data_out(data_out),
 .fifofull(fifofull),
 .mem_if0(memif0),
 .mem_if1(memif1),
 .dma_req(dma_req_from_fifo),
 .fp_pulse    (fp_pulse)
 );

wire [23:0] lcddvd_ps_out;
wire [7:0]  addr_to_rpal; 
wire [15:0] rpal_datain;

pixel_serializer PS (
.clk(pixel_clk), 
.hclk(clock.HCLK),
.rst(clock.HRESET),
.bepo(1'b0),
.bebo(1'b0),
.bgr (1'b0),
.lcdtft(lcd_reg7.LCDTFT),
.data_in_fifo(data_out),
.lcdbpp (lcd_reg7.LCDBPP)                    ,
.pull   (pull_from_pixelserial),
.lcddvd (lcddvd_ps_out),
.lcdena_lcdm (lcdena_lcdm),
.pixel_clk_phaseshift    (pixel_clk_phaseshift),
.addr_to_rpal(addr_to_rpal),
.rpal_datain(rpal_datain)
 );



assign lcdoutif.LCDVD = lcddvd_ps_out;

 
assign cpal.write     = write_slave_rampal;
assign cpal.waddr     = addr_slave_rampal;
assign cpal.wdata     = data_slave_rampal;
assign cpal.raddr     = addr_to_rpal;
assign cpal.raddr1    = write_slave_rampal ? 8'b0 : addr_slave_rampal;
assign rpal_datain    =  cpal.rdata;
assign rdata_rpal_slave     =  cpal.rdata1;

endmodule
