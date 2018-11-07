module fifo #(parameter fifo_width = 32, parameter fifo_depth = 32) (data_in, wr_en,rd_en, data_out, f_clk_if, fifo_mem_if, fifo_empty,fifo_watermark,stopin,v_sync);

  input [fifo_width-1:0] data_in;
  input wr_en,rd_en,stopin,v_sync;  
  output [fifo_width-1:0] data_out;
  output fifo_empty,fifo_watermark;
  logic [4:0] wr_ptr, rd_ptr; 
  logic [31:0] wr_cnt, rd_cnt;
  logic reset;
  AHBIF f_clk_if;
  MEMIF fifo_mem_if;

  assign reset = f_clk_if.HRESET || v_sync;
  assign data_out = fifo_mem_if.f0_rdata;

  always @(posedge f_clk_if.HCLK or posedge reset)
  begin
    if (reset)
    begin
      wr_ptr = 5'b0;
      wr_cnt = 5'b00000;
      fifo_mem_if.f0_waddr = 0;
      fifo_mem_if.f0_write = 0;
      fifo_mem_if.f0_wdata = 0;
    end
    else
    begin
      if(wr_en)
//      if(wr_en && !fifo_watermark)
      begin
        fifo_mem_if.f0_wdata = data_in;
        fifo_mem_if.f0_waddr = wr_ptr;
        fifo_mem_if.f0_write = 1'b1;
        wr_cnt = wr_cnt + 1;
        wr_ptr = wr_ptr + 1;
      end
      else
        fifo_mem_if.f0_write = 0;
    end
  end
  
  always @(posedge rd_en or posedge reset)
  begin
    if(reset)
    begin
      rd_ptr = 0;
      rd_cnt = 1;
      fifo_mem_if.f0_raddr = -1;
    end
    else
    begin
      if(rd_en && !stopin )
      begin
        if(rd_cnt <= wr_cnt) 
        begin
          fifo_mem_if.f0_raddr = rd_ptr;
          rd_cnt = rd_cnt + 1;
          rd_ptr = rd_ptr + 1;
        end
      end
    end
  end
  assign fifo_empty = rd_en ? ((rd_cnt == wr_cnt) ? 1'b1 :1'b0 ) : ((rd_cnt == wr_cnt + 1) ? 1'b1 : 1'b0);
  assign fifo_watermark = ((wr_cnt - (rd_cnt-1)) >= 28) ? 1'b1 : 1'b0;
  
endmodule
