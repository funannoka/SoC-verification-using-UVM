// This is a AHB MAster 

module ahb_master (m_if, m_clk_if, store_rd_dt, wr_en_upper, wr_en_lower, fifo_watermark,v_sync); 
parameter REQUEST       = 3'b000;
parameter GRANT         = 3'b001;
parameter ADDR_PH_1     = 3'b010;
parameter ADDR_DATA_PH  = 3'b011;
parameter IDLE_PH       = 3'b100; 
parameter IDLE_PH_V_SYNC= 3'b101;
AHBIF m_if;
AHBIF m_clk_if;
output logic [31:0] store_rd_dt;
output logic wr_en_upper,wr_en_lower;
input fifo_watermark,v_sync;
logic [2:0] ps, ns ;
int data_cnt,idle_cnt;
wire [31:0] m_addr_ctrl;  
logic [31:0] maddr,mupaddr,mlpaddr;
logic tmp_cnt,flag_grant;
int addr_cnt;
int reg_upbase_change, reg_upbase_change_f;
typedef enum logic [1:0] {OKAY=2'b00, ERROR,RETRY,SPLIT} resp;
typedef enum logic [1:0] {IDLE=2'b00, BUSY,NONSEQ,SEQ} trans;
typedef enum logic [2:0] {SINGLE=3'b000, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16} burst;
typedef enum logic [2:0] {bits_8 =3'b000,bits_16, bits_32, bits_64, bits_128, bits_256, bits_512, bits_1024} sizem;
typedef enum logic {READ=1'b0,WRITE} wr_rd;
assign reg_upbase_change = lcd.reg_mem_map.LCD_UPBASE;
//assign reg_upbase_change = lcd.reg_mem_map.CRSR_IMG[255];

always @(posedge m_clk_if.HCLK or posedge m_clk_if.HRESET)
begin
  if (m_clk_if.HRESET)
    reg_upbase_change_f <= 0;
  else
    reg_upbase_change_f <= reg_upbase_change;
end



always @ (ps or tmp_cnt)
begin 
  case(ps)
  
  REQUEST : 
  begin
//  if(idle_cnt != 464/403)
    if(reg_upbase_change_f != reg_upbase_change && reg_upbase_change != 0)
    begin
      ns = GRANT;
      flag_grant = 0;
//      m_if.mHBUSREQ = 1'b1;
    end
    else
    begin
      m_if.mHBUSREQ = 1'b0;
      ns = REQUEST;
    end
  end
  
  GRANT :
  begin
    wr_en_upper = 0;
    if(!v_sync)
    begin
      if(m_if.mHGRANT == 1'b1)
      begin
        m_if.mHBUSREQ = 1'b1;
//        m_if.mHBUSREQ = 1'b0;
        if(v_sync)
          ns = IDLE_PH_V_SYNC;
        else if(flag_grant == 1)
        begin
          ns = ADDR_DATA_PH;
          flag_grant = 0;
        end
        else
          ns = ADDR_PH_1;
      end
      else
      begin
        m_if.mHBUSREQ = 1'b1;
        ns = GRANT;
      end
    end
    else
    begin
      ns = IDLE_PH_V_SYNC;
      m_if.mHBUSREQ = 1'b0;
    end
  end 
  
  ADDR_PH_1 :
  
  begin
    if (m_if.mHGRANT == 1'b1)
    begin
      m_if.mHBUSREQ = 1'b1;
      m_if.mHADDR  = maddr;
      m_if.mHWRITE = READ;
      m_if.mHSIZE  = bits_32;
      m_if.mHBURST = SINGLE;
      m_if.mHTRANS = NONSEQ;
      if(v_sync)
        ns = IDLE_PH_V_SYNC;
      else
        ns = ADDR_DATA_PH;
    end
    else
      ns = GRANT ;
  end
  
  ADDR_DATA_PH :
  
  begin
#0    wr_en_upper = 0;
    wr_en_lower = 0;
    if (m_if.mHGRANT == 1'b1)
    begin
      m_if.mHBUSREQ = 1'b1;
      if (fifo_watermark == 1'b1)
      begin
        m_if.mHBUSREQ = 1'b0;
        ns = IDLE_PH;
        m_if.mHTRANS = IDLE;
        store_rd_dt = m_if.mHRDATA;
        wr_en_upper = 1;
      end
      else
      begin
        if(m_if.mHREADY == 1'b1)
         begin
           m_if.mHADDR  = maddr;
           m_if.mHWRITE = READ;
           m_if.mHSIZE  = bits_32;
           m_if.mHBURST = SINGLE;
           m_if.mHTRANS = NONSEQ;
           store_rd_dt = m_if.mHRDATA;
           data_cnt = data_cnt+1;
           if(lcd.reg_mem_map.LCD_CTRL.LcdDual)
           begin
             if(data_cnt %2 != 0)
               wr_en_upper = 1;
             else
               wr_en_lower = 1;
           end
           else
             wr_en_upper = 1;
         end
         ns = ADDR_DATA_PH;
      end
    end
    else
    begin
      ns = GRANT;
      flag_grant = 1;
    end
  end
  
  IDLE_PH : 
  
    begin
      wr_en_upper = 0;
      m_if.mHBUSREQ = 1'b0;
      if (fifo_watermark == 1'b1)
        ns = IDLE_PH;
      else if (m_if.mHGRANT == 1'b0)
        ns = GRANT;
      else if(v_sync)
        ns = IDLE_PH_V_SYNC;
      else if ( fifo_watermark == 1'b0 )
        ns = ADDR_DATA_PH;
      else
        ns = IDLE_PH;
    end

    IDLE_PH_V_SYNC : 
  
    begin
      if(v_sync)
      begin
        ns = IDLE_PH_V_SYNC;
        m_if.mHBUSREQ = 1'b0;
      end
      else if (m_if.mHGRANT == 1'b0)
        ns = GRANT;
      else if (!v_sync)
        ns = ADDR_PH_1;
    end

  
  endcase
end

always @ (posedge m_clk_if.HCLK or posedge m_clk_if.HRESET)
begin
  if(m_clk_if.HRESET)
  begin
    ps =  REQUEST;
    tmp_cnt = 0;
  end
  else
  begin
#0    ps = ns;
    tmp_cnt = tmp_cnt+1;
    if(v_sync)
      addr_cnt = 0;  
    if((ns == ADDR_PH_1 || ns == ADDR_DATA_PH) && !fifo_watermark && m_if.mHGRANT == 1'b1)
    begin
      addr_cnt = addr_cnt + 1;
      if(addr_cnt == 1 || addr_cnt == 2)
      begin
        if(lcd.reg_mem_map.LCD_CTRL.LcdDual)
        begin
          if((addr_cnt%2) != 0)
          begin
            maddr = lcd.reg_mem_map.LCD_UPBASE;
            mupaddr = maddr; 
          end
          else
          begin
            maddr = lcd.reg_mem_map.LCD_LPBASE;
            mlpaddr = maddr;
          end
        end
        else
        begin
          if(addr_cnt == 1)
          begin
            maddr = lcd.reg_mem_map.LCD_UPBASE;
            mupaddr = maddr;
          end
          else
          begin
            maddr = maddr+4;
            mupaddr = maddr;
          end
        end
      end
      else
      begin
        if(lcd.reg_mem_map.LCD_CTRL.LcdDual)
        begin
          if((addr_cnt % 2) != 0)
          begin
            maddr = mupaddr + 4;
            mupaddr = maddr;
          end
          else
          begin
            maddr = mlpaddr + 4;
            mlpaddr = maddr;
          end
        end
        else
        begin
          maddr = mupaddr + 4;
          mupaddr = maddr;
        end
      end
    end
  end
end


endmodule

