module clk_gen (LCDDCLK_full,line_clk,c_clk_if);
output logic LCDDCLK_full,line_clk; 
AHBIF c_clk_if;

int counter,line_counter, total_counter, total_lcddclk_counter, total_lcddclk_counter_f, line_counter_f;

assign total_lcddclk_counter = ((lcd.reg_mem_map.LCD_CFG.CLKDIV)+1);
always @(posedge c_clk_if.HCLK or posedge c_clk_if.HRESET)
begin
  if (c_clk_if.HRESET)
  begin
    LCDDCLK_full = 0;
    counter = 0;
  end
  if(total_lcddclk_counter_f != total_lcddclk_counter)
    counter = 0;
  counter =counter + 1;
  if (counter <= (total_lcddclk_counter - ((counter/2)+1)))
    LCDDCLK_full = 1'b1;
  else if(counter == total_lcddclk_counter)
  begin
    counter = 0;
    LCDDCLK_full = 1'b0;
  end
  else
    LCDDCLK_full = 1'b0;
end

assign total_counter = (((lcd.reg_mem_map.LCD_TIMH.HSW+1) + (lcd.reg_mem_map.LCD_TIMH.HBP+1) + (16*(lcd.reg_mem_map.LCD_TIMH.PPL+1)*((lcd.reg_mem_map.LCD_CFG.CLKDIV)+1)) + (lcd.reg_mem_map.LCD_TIMH.HFP+1))) ;

always @(posedge c_clk_if.HCLK or posedge c_clk_if.HRESET)
begin
  if (c_clk_if.HRESET)
  begin
    line_clk = 0;
    line_counter = 0;
  end
  if(total_lcddclk_counter_f != total_lcddclk_counter)
    line_counter = 0;
  line_counter = line_counter + 1;
  if (line_counter <= (total_counter - ((line_counter/2)+1)))
    line_clk <= 1'b1;
  else if(line_counter == total_counter)
  begin
    line_counter <= 0;
    line_clk <= 1'b0;
  end
  else
    line_clk <= 1'b0;
end



always @(posedge c_clk_if.HCLK or posedge c_clk_if.HRESET)
begin
  if (c_clk_if.HRESET)
  begin
    total_lcddclk_counter_f <= 0;
    line_counter_f <= 0;
  end
  else
  begin
    total_lcddclk_counter_f <= total_lcddclk_counter;
    line_counter_f <= line_counter;
  end
end




endmodule
