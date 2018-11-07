// This is AHB Slave
module ahb_slave (s_if,s_clk_if,mem_add_rd,mem_add_wr,data_wr,data_rd);
  parameter IDLE_PH       = 2'b00;
  parameter WAIT          = 2'b01;
  parameter ADDR_RD_PH    = 2'b10;
  parameter ADDR_WR_RD_PH = 2'b11;
  AHBIF s_if;
  AHBIF s_clk_if;
  logic [31:0] local_addrs;
  logic [2:0] ps, ns;
  logic flag;
  output logic [31:0] mem_add_rd,mem_add_wr,data_wr;
  input [31:0] data_rd;
  logic [1:0] local_trans;
  

  typedef enum logic [1:0] {OKAY=2'b00, ERROR,RETRY,SPLIT} resp;
  typedef enum logic [1:0] {IDLE=2'b00, BUSY,NONSEQ,SEQ} trans;
  typedef enum logic [2:0] {SINGLE=3'b000, INCR, WRAP4, INCR4, WRAP8, INCR8, WRAP16, INCR16} burst;
  typedef enum logic [2:0] {bits_8 =3'b000,bits_16, bits_32, bits_64, bits_128, bits_256, bits_512, bits_1024} sizem;
  typedef enum logic {READ=1'b0,WRITE} wr_rd;

  always @(ps or flag)
  begin
    case(ps)
      IDLE_PH:
        begin
          if (s_if.HSEL == 1'b1)
            if(s_if.HWRITE == WRITE)
            begin
              local_addrs = s_if.HADDR;
              local_trans = s_if.HTRANS;
              s_if.HREADY = 1'b1;
              s_if.HRESP = OKAY;
              ns = ADDR_WR_RD_PH;
            end
            else
              ns = ADDR_RD_PH;
          else
            ns = IDLE_PH;
        end
        
      WAIT:
          ns = ADDR_RD_PH;
        
      ADDR_RD_PH:
      begin
        if(s_if.HWRITE==READ)
        begin
          s_if.HREADY = 1'b1;
          s_if.HRESP = OKAY;
          mem_add_rd = s_if.HADDR;    //drive HRDATA memory of the address demanded by the master... HRDATA = mem[addr];
          s_if.HRDATA = data_rd;
          ns= ADDR_RD_PH;
        end
      end
      
      ADDR_WR_RD_PH: 
      begin

        if(local_trans == NONSEQ || local_trans == SEQ)
        begin
        data_wr = s_if.HWDATA;
        mem_add_wr = local_addrs; //store HWDATA to addressed memory location
        end

        if (s_if.HSEL == 1'b1)
        begin
          if(s_if.HWRITE == WRITE)
          begin
            if(s_if.HADDR == 0)//0 represents invalid and read-ony addresses
            begin
              if(s_if.HRESP==ERROR)
              begin
                s_if.HREADY=1'b1;
                s_if.HRESP=ERROR;
                ns=WAIT;
              end
              else
              begin
                s_if.HREADY = 1'b0;
                s_if.HRESP = ERROR;
                ns=ADDR_WR_RD_PH;
              end
            end
            else
            begin
              ns=ADDR_WR_RD_PH;
              local_addrs = s_if.HADDR; //store new local adress
              local_trans = s_if.HTRANS;
              s_if.HREADY = 1'b1;
              s_if.HRESP = OKAY;
              
              if(s_if.HWRITE==READ)
              begin
                mem_add_rd = s_if.HADDR;    //drive HRDATA memory of the address demanded by the master... HRDATA = mem[addr];
                s_if.HRDATA = data_rd;
              end
            end
          end
        end
        else
          ns = IDLE_PH;
      end
    endcase
  end
  
  always @(posedge s_clk_if.HCLK or posedge s_clk_if.HRESET)
  begin
   if(s_clk_if.HRESET)
   begin
    ps <=  IDLE_PH;
    flag <= 0;
   end
  else
  begin
    ps <= ns;
    flag <= flag + 1;
  end
  end
endmodule

