/*typedef  struct packed{
reg [15:0] resv1;
reg         WATERMARK;
reg [1:0]   resv2;
reg [1:0]   LCDVCOMP;
reg         LCDPWR;
reg         BEPO;// big endian pixel order
reg         BEBO;// big endian byte order in memory
reg         BGR;// bgr if 1
reg         LCDDUAL;
reg         LCDMONO8;
reg         LCDTFT;
reg 	    LCDBW;
reg [2:0]   LCDBPP;// bits per pixel
reg         LCDEN;
} LCD_CTRL;*/

//typedef enum {LATCH,SERIAL} ps_state;

// code for TFT display
module pixel_serializer (input hclk,clk,lcdena_lcdm,rst,bepo,bebo,bgr,lcdtft,input [31:0] data_in_fifo,input[2:0] lcdbpp,output pull,output logic [23:0] lcddvd, input pixel_clk_phaseshift,output logic [7:0] addr_to_rpal,input [15:0] rpal_datain);
 
  reg [31:0] data_reg;
  reg [4:0] pixel_counter;
  reg [4:0] pixel_compare;
  reg [4:0] pixel_counter_swap,not_pixel_counter;
  //ps_state  cur_state,nxt_state;
  wire [1:0] data_out_bpp2_wire0;
  wire [1:0] data_out_bpp2_wire1;
  wire [1:0] data_out_bpp2_wire2;
  wire [3:0] data_out_bpp4_wire0;
  wire [3:0] data_out_bpp4_wire1;
  wire [3:0] data_out_bpp4_wire2;
  wire [7:0] data_out_bpp8_wire0;
  wire [7:0] data_out_bpp8_wire1;
  wire [7:0] data_out_bpp8_wire2;
  wire [15:0] data_out_bpp16_wire0;
  wire [15:0] data_out_bpp16_wire1;
  wire [15:0] data_out_bpp16_wire2;

  decoder_16 dec_16_bbp2_0(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter[4:1]),.data_out(data_out_bpp2_wire0),.en(1'b0));  
  decoder_16 dec_16_bbp2_1(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter_swap[4:1]),.data_out(data_out_bpp2_wire1),.en(1'b0));  
  decoder_16 dec_16_bbp2_2(.clk(clk),.rst(rst),.data_in(data_reg),.sel(not_pixel_counter[4:1]),.data_out(data_out_bpp2_wire2),.en(1'b0));  
 
  decoder_8 dec_8_bbp4_0(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter[4:2]),.data_out(data_out_bpp4_wire0),.en(1'b0));  
  decoder_8 dec_8_bbp4_1(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter_swap[4:2]),.data_out(data_out_bpp4_wire1),.en(1'b0));  
  decoder_8 dec_8_bbp4_2(.clk(clk),.rst(rst),.data_in(data_reg),.sel(not_pixel_counter[4:2]),.data_out(data_out_bpp4_wire2),.en(1'b0));  
 
  decoder_4 dec_4_bbp8_0(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter[4:3]),.data_out(data_out_bpp8_wire0),.en(1'b0));  
  decoder_4 dec_4_bbp8_1(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter_swap[4:3]),.data_out(data_out_bpp8_wire1),.en(1'b0));  
  decoder_4 dec_4_bbp8_2(.clk(clk),.rst(rst),.data_in(data_reg),.sel(not_pixel_counter[4:3]),.data_out(data_out_bpp8_wire2),.en(1'b0));  

  decoder_2 dec_2_bbp16_0(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter[4]),.data_out(data_out_bpp16_wire0),.en(1'b1));  
  decoder_2 dec_2_bbp16_1(.clk(clk),.rst(rst),.data_in(data_reg),.sel(pixel_counter_swap[4]),.data_out(data_out_bpp16_wire1),.en(1'b0));  
  decoder_2 dec_2_bbp16_2(.clk(clk),.rst(rst),.data_in(data_reg),.sel(not_pixel_counter[4]),.data_out(data_out_bpp16_wire2),.en(1'b0));  

  assign pull     = rst ? 0: (lcdena_lcdm ? ((pixel_counter==pixel_compare) & pixel_clk_phaseshift):0);
  //assign data_reg = rst ? 32'b0: ( lcdena_lcdm ? data_in_fifo : 0); //flop data reg
  //assign pull     = rst ? 0: (lcdena_lcdm ? ((pixel_counter==pixel_compare)):0);

 always @(posedge hclk or posedge rst) begin
   if(rst) begin 
     data_reg <= #1 0;
   end else begin 
              data_reg <= #1 data_in_fifo;
            end 
 end

  always @(posedge clk or posedge rst) begin 
    if(rst) begin 
        pixel_counter    <= #0 0;
    end else begin
         if(lcdena_lcdm) begin 
    unique  case(lcdbpp)
          
             3'b000:begin //1bpp
         	    pixel_counter <= #1 pixel_counter + 1; 
         	   end
             3'b001:begin //2bpp
         	    pixel_counter <= #1 pixel_counter + 2; 
         	   end
             3'b010:begin //4bpp
         	    pixel_counter <= #1 pixel_counter + 4; 
         	   end
             3'b011:begin //8bpp
         	    pixel_counter <= #1 pixel_counter + 8; 
         	   end
             3'b100:begin //16bpp
         	    pixel_counter <= #1 pixel_counter + 16; 
         	   end
             3'b101:begin //24bpp
         	    pixel_counter <= #1 0;
         	   end
             3'b110:begin //16bpp
         	    pixel_counter <= #1 pixel_counter + 16; 
         	   end
             3'b111:begin //12bpp
         	    pixel_counter <= #1 pixel_counter + 16; 
                    end
             
            endcase
           end         
             end 
  end 

// output from pixel serializer stage	
 always@(*) begin
 lcddvd = 0;
 //pixel_counter_swap = 0;
 pixel_counter_swap = {pixel_counter[4:3],~pixel_counter[2],~pixel_counter[1],~pixel_counter[0]};
 not_pixel_counter  = ~pixel_counter;
// LEB_LEP
if (lcdena_lcdm) begin
// case for byte order
unique case(lcdbpp)
 
    3'b000:begin//1 
            unique case({bebo,bepo})            
 	    2'b00:begin
                   lcddvd={
                           rpal_datain[14:10],   
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[9:5],
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[4:0],
                           rpal_datain[15],
                           2'b00
                          };

                  end
            2'b01:begin
                  lcddvd= {23'h0,data_reg[pixel_counter_swap ]}; //LBBP
                  end
            2'b11:lcddvd= {23'h0,data_reg[not_pixel_counter]}; //BBBP 						
            //2'b10:
            endcase
	   end
    3'b001:begin//2
            unique case({bebo,bepo})            
 	    2'b00:begin
                   lcddvd={
                           rpal_datain[14:10],   
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[9:5],
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[4:0],
                           rpal_datain[15],
                           2'b00
                          };
                  end
            2'b01:begin
                  lcddvd= data_out_bpp2_wire1;
                  end
            2'b11:lcddvd= data_out_bpp2_wire2;
            endcase
	   end
    3'b010:begin //4
            unique case({bebo,bepo})            
 	    2'b00:begin
                   lcddvd={
                           rpal_datain[14:10],   
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[9:5],
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[4:0],
                           rpal_datain[15],
                           2'b00
                          };
                  end
            2'b01:begin
                  lcddvd=data_out_bpp4_wire1;
                  end
            2'b11:lcddvd=data_out_bpp4_wire2;
            endcase
	   end
    3'b011:begin //8
            unique case({bebo,bepo})            
 	    2'b00:begin
                   lcddvd={
                           rpal_datain[14:10],   
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[9:5],
                           rpal_datain[15],
                           2'b00,
                           rpal_datain[4:0],
                           rpal_datain[15],
                           2'b00
                          };
                  end
            2'b01:begin
                  lcddvd=data_out_bpp8_wire1;
                  end
            2'b11:lcddvd=data_out_bpp8_wire2;
            endcase
	   end
    3'b100:begin//16
            unique case({bebo,bepo})            
 	    //2'b00:lcddvd=data_out_bpp16_wire0;
 	    2'b00: begin
                   lcddvd={
                           data_out_bpp16_wire0[14:10],   
                           data_out_bpp16_wire0[15],
                           2'b00,
                           data_out_bpp16_wire0[9:5],
                           data_out_bpp16_wire0[15],
                           2'b00,
                           data_out_bpp16_wire0[4:0],
                           data_out_bpp16_wire0[15],
                           2'b00
                           };
                   end
            2'b01:begin
                  lcddvd=data_out_bpp16_wire1;
		  end
            2'b11:lcddvd=data_out_bpp16_wire2;
            endcase
	   end
    3'b101:begin //24
	    lcddvd=data_reg[23:0]; 
	   end
    3'b110:begin //5:6:5
	    lcddvd=      {
                           data_out_bpp16_wire0[15:11],   
                           3'b000,
                           data_out_bpp16_wire0[10:5],
                           2'b00,
                           data_out_bpp16_wire0[4:0],
                           3'b000
                           };

	   end
    3'b111:begin //4:4:4
	    lcddvd=      {
                           data_out_bpp16_wire0[11:8],   
                           4'b0000,
                           data_out_bpp16_wire0[7:4],
                           4'b0000,
                           data_out_bpp16_wire0[3:0],
                           4'b0000
                           };
           end
    
   endcase
end

end //always@*

always @(*) begin 
      case(lcdbpp)
          
             3'b000:begin //1bpp
         	    pixel_compare = 31;
         	   end
             3'b001:begin //2bpp
         	    pixel_compare = 30; 
         	   end
             3'b010:begin //4bpp
         	    pixel_compare = 28; 
         	   end
             3'b011:begin //8bpp
         	    pixel_compare = 24; 
         	   end
             3'b100:begin //16bpp
         	    pixel_compare = 5'h10; 
         	   end
             3'b101:begin //24bpp
         	    pixel_compare = 0;
         	   end
             3'b110:begin //16bpp
         	    pixel_compare = 5'h10; 
         	   end
             3'b111:begin //12bpp
         	    pixel_compare = 5'h10; 
                    end
             
            endcase
end 

always @(*) begin 
      addr_to_rpal = 8'h0;
  if (lcdena_lcdm) begin
      case(lcdbpp)
             3'b000:begin //1bpp
                    addr_to_rpal  = data_reg[pixel_counter]; 
         	   end
             3'b001:begin //2bpp
                    addr_to_rpal  = {6'b000000,data_reg[pixel_counter+1],data_reg[pixel_counter]}; 
         	   end
             3'b010:begin //4bpp
                    addr_to_rpal  = {4'b00,data_reg[pixel_counter+3],data_reg[pixel_counter+2],data_reg[pixel_counter+1],data_reg[pixel_counter]}; 
         	   end
             3'b011:begin //8bpp
                    addr_to_rpal  = 
                                    {  
                                       data_reg[pixel_counter+7],
                                       data_reg[pixel_counter+6],
                                       data_reg[pixel_counter+5],
                                       data_reg[pixel_counter+4],
                                       data_reg[pixel_counter+3],
                                       data_reg[pixel_counter+2],
                                       data_reg[pixel_counter+1],
                                       data_reg[pixel_counter]
                                    }; 
         	   end
             3'b100:begin //16bpp
         	   end
             3'b101:begin //24bpp
         	   end
             3'b110:begin //16bpp
         	   end
             3'b111:begin //12bpp
                    end
      endcase       
    end
end 

endmodule 
