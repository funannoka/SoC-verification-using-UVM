module ram_palette (ram_d_out_temp,pal_raddr,pal_rdata, d_out_pix_ser, clk_if, stopin);

  output logic [23:0] ram_d_out_temp;
  input [23:0] d_out_pix_ser; //d_in
  input stopin;
  output logic [7:0] pal_raddr;
  input [15:0] pal_rdata;
  logic [31:0] rd_data;
  logic [1:0] ps, ns;
  logic [5:0] R,G,B,Y;
  
  parameter bpp_1  = 3'b000;
  parameter bpp_2  = 3'b001;
  parameter bpp_4  = 3'b010;
  parameter bpp_8  = 3'b011;
  parameter bpp_16  = 3'b100;
  parameter bpp_24  = 3'b101;
  parameter bpp_16_565  = 3'b110;
  parameter bpp_16_444  = 3'b111;
  AHBIF clk_if;

initial
begin
  ram_d_out_temp = 0;
end

always @ (posedge clk_if.HCLK or posedge clk_if.HRESET)
begin
  if(clk_if.HRESET)
  begin
    pal_raddr = 0;
  end
  else
  begin
    case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
    bpp_1:
      begin
        pal_raddr = {7'h00,d_out_pix_ser[0]};
    rd_data = pal_rdata;
      end   
    bpp_2:
      begin
        pal_raddr = {6'h00,d_out_pix_ser[1:0]};
    rd_data = pal_rdata;
      end
    bpp_4:
      begin
        pal_raddr = {4'h0,d_out_pix_ser[3:0]};
    rd_data = pal_rdata;
      end
    bpp_8:
      begin
        pal_raddr = {d_out_pix_ser[7:0]};
    rd_data = pal_rdata;
      end
    bpp_16:
      begin
        rd_data = d_out_pix_ser;
      end
    bpp_24:
      begin
        rd_data = d_out_pix_ser;
      end
    bpp_16_565:
      begin
        rd_data = d_out_pix_ser;
      end
    bpp_16_444:
      begin
        rd_data = d_out_pix_ser;
      end
    endcase
  end 
end   

always @(*)
 begin
  
  if(lcd.reg_mem_map.LCD_CTRL.LcdTFT==1)//TFT
  begin
    if(lcd.reg_mem_map.LCD_CTRL.BGR==0)//RGB
    begin  
      if(lcd.reg_mem_map.LCD_CTRL.LcdBpp == bpp_24)
      begin
        ram_d_out_temp = rd_data;
      end
      else if(lcd.reg_mem_map.LCD_CTRL.LcdBpp == bpp_16_565)
      begin
        R[4:0]= rd_data[4:0];
        G[5:0]= rd_data[10:5];
        B[4:0]= rd_data[15:11];
        ram_d_out_temp = {B[4:0],3'b000,G[5:0],2'b00,R[4:0],3'b000};
      end
      else if(lcd.reg_mem_map.LCD_CTRL.LcdBpp == bpp_16_444)
      begin
        R[3:0]= rd_data[3:0];
        G[3:0]= rd_data[7:4];
        B[3:0]= rd_data[11:8];
        ram_d_out_temp = {B[3:0],4'b0000,G[3:0],4'b0000,R[3:0],4'b0000};
      end
      else
      begin
        R[4:0]= rd_data[4:0];
        G[4:0]= rd_data[9:5];
        B[4:0]= rd_data[14:10];
        if(rd_data[15] == 1'b1)
          ram_d_out_temp = {B[4:0],3'b100,G[4:0],3'b100,R[4:0],3'b100};
        else
          ram_d_out_temp = {B[4:0],3'b000,G[4:0],3'b000,R[4:0],3'b000};
      end
    end
    else //BGR
    begin
      B[4:0]= rd_data[4:0];
      G[4:0]= rd_data[9:5];
      R[4:0]= rd_data[14:10];
      ram_d_out_temp = {3'b0,R[4:0],3'b0,G[4:0],3'b0,B[4:0]};
    end
  end
  else
  begin
    if(lcd.reg_mem_map.LCD_CTRL.LcdBW==0) //STN is color
    begin
      if(lcd.reg_mem_map.LCD_CTRL.BGR==0)//RGB
      begin
        R[4:1] = rd_data[4:1];
        G[4:1] = rd_data[9:6];
        B[4:1] = rd_data[14:11];
        ram_d_out_temp = {4'b0,B[4:1],4'b0,G[4:1],4'b0,R[4:1]};
      end
      else //BGR
      begin
        B[4:1] = rd_data[4:1];
        G[4:1] = rd_data[9:6];
        R[4:1] = rd_data[14:11];
        ram_d_out_temp = {4'b0,R[4:1],4'b0,G[4:1],4'b0,B[4:1]};
      end
    end
    else
    begin
      if(lcd.reg_mem_map.LCD_CTRL.LcdBW==1) //STN is monochrome
      begin
        Y[4:1] = rd_data[4:1];
        ram_d_out_temp = {20'b0,Y[4:1]};
      end
    end
  end
 end
endmodule
