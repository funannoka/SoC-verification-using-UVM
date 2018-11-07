module pixel_ser (m_clk_if, din_pix_ser, actual_read_en, dout_pix_ser, fifo_empty, stopin,lcdfp,one_time_sync,v_sync);

  AHBIF m_clk_if;
  input [31:0] din_pix_ser;
  input fifo_empty, lcdfp,one_time_sync,v_sync;
  output logic actual_read_en;
  output logic [23:0] dout_pix_ser;

  logic [5:0] ps,ns;
  logic rd_en, one_time;
  logic read_en;
  logic tmp_cnt;
  logic [32:0] flag;
  input stopin;
  logic reset;

  parameter IDLE  = 6'b000000;
  parameter p0    = 6'b000001;
  parameter p1    = 6'b000010;
  parameter p2    = 6'b000011;
  parameter p3    = 6'b000100;
  parameter p4    = 6'b000101;
  parameter p5    = 6'b000110;
  parameter p6    = 6'b000111;
  parameter p7    = 6'b001000;
  parameter p8    = 6'b001001;
  parameter p9    = 6'b001010;
  parameter p10   = 6'b001011;
  parameter p11   = 6'b001100;
  parameter p12   = 6'b001101;
  parameter p13   = 6'b001110;
  parameter p14   = 6'b001111;
  parameter p15   = 6'b010000;
  parameter p16   = 6'b010001;
  parameter p17   = 6'b010010;
  parameter p18   = 6'b010011;
  parameter p19   = 6'b010100;
  parameter p20   = 6'b010101;
  parameter p21   = 6'b010110;
  parameter p22   = 6'b010111;
  parameter p23   = 6'b011000;
  parameter p24   = 6'b011001;
  parameter p25   = 6'b011010;
  parameter p26   = 6'b011011;
  parameter p27   = 6'b011100;
  parameter p28   = 6'b011101;
  parameter p29   = 6'b011110;
  parameter p30   = 6'b011111;
  parameter p31   = 6'b100000;
  parameter WAIT  = 6'b100001;

  parameter bpp_1  = 3'b000;
  parameter bpp_2  = 3'b001;
  parameter bpp_4  = 3'b010;
  parameter bpp_8  = 3'b011;
  parameter bpp_16 = 3'b100;
  parameter bpp_24 = 3'b101;
  parameter bpp_16_565 = 3'b110;
  parameter bpp_16_444 = 3'b111;
  logic i;
//  initial 
//  begin
//    one_time = 1'b0;
//  end

  assign reset = m_clk_if.HRESET || v_sync;

  always @(posedge m_clk_if.HCLK or posedge reset)
  begin
    if(reset)
    begin
      one_time = 1'b0;
      i = 1;
    end
    else
    begin
      if(one_time_sync)
      begin
        if(i == 1)
        begin
          one_time = 1'b1;
          i = 0;
        end
        else
        begin
          one_time = 1'b0;
        end
      end
    end
  end

  always @(posedge m_clk_if.HCLK or posedge m_clk_if.HRESET)
  begin
    if (m_clk_if.HRESET)
      rd_en = 1'b0;
    else if(read_en)
      rd_en = 1'b1; 
    else
      rd_en = 1'b0;
  end

  initial
  begin
    tmp_cnt = 1'b0;
  end

  always @(posedge m_clk_if.HCLK or posedge m_clk_if.HRESET)
  begin
    if(m_clk_if.HRESET)
    begin
      ps <= WAIT;
    end
    else
    begin
        ps <= ns;
        tmp_cnt <= tmp_cnt + 1;
    end
  end

  always @(ps or tmp_cnt or stopin)
  begin
    case(ps)
    IDLE:
    begin 
      if(!stopin || rd_en)
      begin
        if(!m_clk_if.HRESET && !fifo_empty)
        begin
          read_en = 1'b0;
          actual_read_en = 1'b0;
          ns = p0;
        end
        else 
        begin
          ns = IDLE;
        end
      end
      else 
      begin
        flag = 33'h000000001;
        ns = WAIT;
        actual_read_en = 1'b0;
      end
    end 
    
    p0:
    begin 
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[0];    ns = p1; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[1:0];  ns = p1; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[3:0];  ns = p1; end
          bpp_8:  begin dout_pix_ser[7:0]  = din_pix_ser[7:0];  ns = p1; end
          bpp_16: begin dout_pix_ser[15:0] = din_pix_ser[15:0]; ns = p1; end
          bpp_24: begin dout_pix_ser[23:0] = din_pix_ser[23:0]; ns = WAIT; flag = 33'h000000002; end
          bpp_16_565: begin dout_pix_ser[15:0] = din_pix_ser[15:0]; ns = p1; end
          bpp_16_444: begin dout_pix_ser[15:0] = din_pix_ser[15:0]; ns = p1; end
        endcase
      end
      else 
      begin
        flag = 33'h000000002;
        ns = WAIT;
      end
    end 
  
    p1:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[1];    ns = p2; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[3:2];  ns = p2; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[7:4];  ns = p2; end
          bpp_8:  begin dout_pix_ser[7:0]  = din_pix_ser[15:8]; ns = p2; end
          bpp_16: begin dout_pix_ser[15:0] = din_pix_ser[31:16];ns = WAIT; flag = 33'h000000002; end
          bpp_16_565: begin dout_pix_ser[15:0] = din_pix_ser[31:16];ns = WAIT; flag = 33'h000000002; end
          bpp_16_444: begin dout_pix_ser[15:0] = din_pix_ser[31:16];ns = WAIT; flag = 33'h000000002; end
        endcase
      end  
      else 
      begin
        flag = 33'h000000004;
        ns = WAIT;
      end
    end 
    
    p2:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[2];    ns = p3; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[5:4];  ns = p3; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[11:8]; ns = p3; end
          bpp_8:  begin dout_pix_ser[7:0]  = din_pix_ser[23:16];ns = p3; end
        endcase
      end
      else 
      begin
        flag = 33'h000000008;
        ns = WAIT;
        end
    end 
    
    p3:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[3];    ns = p4; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[7:6];  ns = p4; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[15:12];ns = p4; end
          bpp_8:  begin dout_pix_ser[7:0]  = din_pix_ser[31:24];ns = WAIT; flag = 33'h000000002; end
        endcase
      end
      else 
      begin
        flag = 33'h000000010;
        ns = WAIT;
      end
    end 
    
    p4:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[4];    ns = p5; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[9:8];  ns = p5; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[19:16];ns = p5; end
        endcase
      end
      else 
      begin
        flag = 33'h000000020;
        ns = WAIT;
      end
    end 
    
    p5:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[5];    ns = p6; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[11:10];ns = p6; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[23:20];ns = p6; end
        endcase
      end
      else 
      begin
        flag = 33'h000000040;
        ns = WAIT;
      end
    end 
    
    p6:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[6];    ns = p7; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[13:12];ns = p7; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[27:24];ns = p7; end
        endcase
      end  
      else 
      begin
        flag = 33'h000000080;
        ns = WAIT;
      end
    end 
    
    p7:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[7];    ns = p8; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[15:14];ns = p8; end
          bpp_4:  begin dout_pix_ser[3:0]  = din_pix_ser[31:28];ns = WAIT; flag = 33'h000000002; end
        endcase
      end  
      else 
      begin
        flag = 33'h000000100;
        ns = WAIT;
      end
    end 
    
    p8:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[8];    ns = p9; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[17:16];ns = p9; end
        endcase
      end  
      else 
      begin
        flag = 33'h000000200;
        ns = WAIT;
      end
    end 
    
    p9:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[9];    ns = p10; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[19:18];ns = p10; end
        endcase
      end  
      else 
      begin
        flag = 33'h000000400;
        ns = WAIT;
      end
    end 
    
    p10:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[10];   ns = p11; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[21:20];ns = p11; end
        endcase
      end  
      else 
      begin
        flag = 33'h000000800;
        ns = WAIT;
      end
    end 
    
    p11:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[11];   ns = p12; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[23:22];ns = p12; end
        endcase
      end  
      else 
      begin
        flag = 33'h000001000;
        ns = WAIT;
      end
    end 
    
    p12:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[12];   ns = p13; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[25:24];ns = p13; end
        endcase
      end  
      else 
      begin
        flag = 33'h000002000;
        ns = WAIT;
      end
    end 
    
    p13:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[13];   ns = p14; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[27:26];ns = p14; end
        endcase
      end  
      else 
      begin
        flag = 33'h000004000;
        ns = WAIT;
      end
    end 
    
    p14:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[14];   ns = p15; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[29:28];ns = p15; end
        endcase
      end  
      else 
      begin
        flag = 33'h000008000;
        ns = WAIT;
      end
    end 
    
    p15:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[15];   ns = p16; end
          bpp_2:  begin dout_pix_ser[1:0]  = din_pix_ser[31:30];ns = WAIT; flag = 33'h000000002; end
        endcase
      end  
      else 
      begin
        flag = 33'h000010000;
        ns = WAIT;
      end
    end 
    
    p16:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[16];  ns = p17; end
        endcase
      end  
      else 
      begin
        flag = 33'h000020000;
        ns = WAIT;
      end
    end 
    
    p17:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[17];   ns = p18; end
        endcase
      end  
      else 
      begin
        flag = 33'h000040000;
        ns = WAIT;
      end
    end 
    
    p18:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[18];   ns = p19; end
        endcase
      end  
      else 
      begin
        flag = 33'h000080000;
        ns = WAIT;
      end
    end 
    
    p19:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[19];   ns = p20; end
        endcase
      end  
      else 
      begin
        flag = 33'h000100000;
        ns = WAIT;
      end
    end 
    
    p20:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[20];   ns = p21; end
        endcase
      end  
      else 
      begin
        flag = 33'h000200000;
        ns = WAIT;
      end
    end 
    
    p21:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[21];   ns = p22; end
        endcase
      end  
      else 
      begin
        flag = 33'h000400000;
        ns = WAIT;
      end
    end 
    
    p22:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[22];   ns = p23; end
        endcase
      end  
      else 
      begin
        flag = 33'h000800000;
        ns = WAIT;
      end
    end 
    
    p23:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[23];   ns = p24; end
        endcase
      end  
      else 
      begin
        flag = 33'h001000000;
        ns = WAIT;
      end
    end 
    
    p24:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[24];   ns = p25; end
        endcase
      end  
      else 
      begin
        flag = 33'h002000000;
        ns = WAIT;
      end
    end 
    
    p25:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[25];   ns = p26; end
        endcase
      end  
      else 
      begin
        flag = 33'h004000000;
        ns = WAIT;
      end
    end 
    
    p26:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[26];   ns = p27; end
        endcase
      end  
      else 
      begin
        flag = 33'h008000000;
        ns = WAIT;
      end
    end 
    
    p27:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[27];   ns = p28; end
        endcase
      end  
      else 
      begin
        flag = 33'h010000000;
        ns = WAIT;
      end
    end 
    
    p28:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[28];   ns = p29; end
        endcase
      end  
      else 
      begin
        flag = 33'h020000000;
        ns = WAIT;
      end
    end 
    
    p29:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[29];   ns = p30; end
        endcase
      end  
      else 
      begin
        flag = 33'h040000000;
        ns = WAIT;
      end
    end 
    
    p30:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[30];   ns = p31; end
        endcase
      end  
      else 
      begin
        flag = 33'h080000000;
        ns = WAIT;
      end
    end 
    
    p31:
    begin
      if(!stopin || rd_en)
      begin
        read_en = 1'b0;
          actual_read_en = 1'b0;
        case(lcd.reg_mem_map.LCD_CTRL.LcdBpp)
          bpp_1:  begin dout_pix_ser[0]    = din_pix_ser[31]; ns = WAIT; flag = 33'h000000002  ; end
        endcase
      end  
      else 
      begin
        flag = 33'h100000000;
        ns = WAIT;
      end
    end 
    
    WAIT:
    begin
#0        if(stopin && !one_time)
        begin
          ns=WAIT;
          if(fifo_empty)
            flag=2;
          actual_read_en = 1'b0;
        end
        else if (!stopin || one_time)
        begin
          read_en = 1'b1;
          actual_read_en = 1'b0;
        case(flag)
          33'h000000001:     begin flag=0; ns=IDLE;  end    
          33'h000000002:     begin actual_read_en = 1'b1; flag=0; ns=p0;  end
          33'h000000004:     begin flag=0; ns=p1;  end
          33'h000000008:     begin flag=0; ns=p2;  end
          33'h000000010:     begin flag=0; ns=p3;  end
          33'h000000020:     begin flag=0; ns=p4;  end  
          33'h000000040:     begin flag=0; ns=p5;  end
          33'h000000080:     begin flag=0; ns=p6;  end
          33'h000000100:     begin flag=0; ns=p7;  end
          33'h000000200:     begin flag=0; ns=p8;  end
          33'h000000400:     begin flag=0; ns=p9;  end
          33'h000000800:     begin flag=0; ns=p10; end
          33'h000001000:     begin flag=0; ns=p11; end
          33'h000002000:     begin flag=0; ns=p12; end
          33'h000004000:     begin flag=0; ns=p13; end
          33'h000008000:     begin flag=0; ns=p14; end   
          33'h000010000:     begin flag=0; ns=p15; end
          33'h000020000:     begin flag=0; ns=p16; end
          33'h000040000:     begin flag=0; ns=p17; end  
          33'h000080000:     begin flag=0; ns=p18; end
          33'h000100000:     begin flag=0; ns=p19; end    
          33'h000200000:     begin flag=0; ns=p20; end   
          33'h000400000:     begin flag=0; ns=p21; end   
          33'h000800000:     begin flag=0; ns=p22; end  
          33'h001000000:     begin flag=0; ns=p23; end
          33'h002000000:     begin flag=0; ns=p24; end
          33'h004000000:     begin flag=0; ns=p25; end
          33'h008000000:     begin flag=0; ns=p26; end
          33'h010000000:     begin flag=0; ns=p27; end 
          33'h020000000:     begin flag=0; ns=p28; end
          33'h040000000:     begin flag=0; ns=p29; end
          33'h080000000:     begin flag=0; ns=p30; end 
          33'h100000000:     begin flag=0; ns=p31; end 
        endcase
        end
    end
  endcase
 end
 endmodule
