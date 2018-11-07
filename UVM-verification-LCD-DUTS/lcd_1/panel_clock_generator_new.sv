module clk_generator(input HCLK,rst,en,input LCD_CFG lcd_cfg,input LCD_POL lcd_pol,output LCDDCLK,output pixel_clk,output pixel_clk_phaseshift);

 
  reg [4:0] temp_count; // to divide clock
  reg [9:0] lcdd_count; // to divide clock
  reg [4:0] temp_count_phaseshift; // to divide clock

  reg rst_comb;
  
  always @(*) begin
    rst_comb = !en | rst;
  end

  // clk divider logic 
  always @(posedge HCLK or posedge rst_comb) begin
   if(rst_comb) begin 
    temp_count     <= #0 5'h1f;
    lcdd_count     <= #0 10'h3ff;
   end else begin
 

     if(temp_count == (lcd_cfg.CLKDIV)) begin
       temp_count <=  0; 
     end else begin 
       temp_count <=  temp_count + 1;
     end

     if(lcdd_count == ({lcd_pol.PCD_HI,lcd_pol.PCD_LO}+10'b1)) begin
       lcdd_count  <= #1 0; 
     end begin
          lcdd_count <= #1 lcdd_count + 1; 
         end
     end

  end 

always @(negedge HCLK or posedge rst_comb) begin 

   if(rst_comb) begin
    temp_count_phaseshift     <= #0 5'h1f;
   end else begin
 
     if(temp_count_phaseshift == (lcd_cfg.CLKDIV)) begin
       temp_count_phaseshift <=  0; 
     end else begin 
       temp_count_phaseshift <=  temp_count_phaseshift + 1;
     end

            end 
end
 
//wire phase180_pixel_clk;
//wire phase180_lcddclk;

//assign phase180_pixel_clk= rst ? 0 : temp_count==lcd_cfg.CLKDIV;
//assign phase180_lcddclk  = rst ? 0 : lcdd_count=={lcd_pol.PCD_HI,lcd_pol.PCD_LO}+10'b1;

 assign pixel_clk = (temp_count == 0);
 assign LCDDCLK   = pixel_clk;
 assign pixel_clk_phaseshift = (temp_count_phaseshift == 0);

endmodule
