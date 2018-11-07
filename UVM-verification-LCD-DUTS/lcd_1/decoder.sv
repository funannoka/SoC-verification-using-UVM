module decoder_32(input clk,rst,en,input[31:0] data_in,input[4:0] sel,output reg data_out);

always@(*) begin 
  data_out = 0;

  if(en) begin 
  unique case(sel)

        5'b00000:data_out=data_in[0]; 
        5'b00001:data_out=data_in[1];
        5'b00010:data_out=data_in[2];
        5'b00011:data_out=data_in[3];
        5'b00100:data_out=data_in[4];
        5'b00101:data_out=data_in[5];
        5'b00110:data_out=data_in[6];
        5'b00111:data_out=data_in[7];
        5'b01000:data_out=data_in[8];
        5'b01001:data_out=data_in[9];
        5'b01010:data_out=data_in[10];
        5'b01011:data_out=data_in[11];
        5'b01100:data_out=data_in[12];
        5'b01101:data_out=data_in[13];
        5'b01110:data_out=data_in[14];
        5'b01111:data_out=data_in[15];
        5'b10000:data_out=data_in[16]; 
        5'b10001:data_out=data_in[17];
        5'b10010:data_out=data_in[18];
        5'b10011:data_out=data_in[19];
        5'b10100:data_out=data_in[20];
        5'b10101:data_out=data_in[21];
        5'b10110:data_out=data_in[22];
        5'b10111:data_out=data_in[23];
        5'b11000:data_out=data_in[24];
        5'b11001:data_out=data_in[25];
        5'b11010:data_out=data_in[26];
        5'b11011:data_out=data_in[27];
        5'b11100:data_out=data_in[28];
        5'b11101:data_out=data_in[29];
        5'b11110:data_out=data_in[30];
        5'b11111:data_out=data_in[31];
         
     endcase
  end 

end

endmodule
 
module decoder_16(input clk,rst,en,input[31:0] data_in,input[3:0] sel,output reg [1:0] data_out);

always@(*) begin 
  data_out = 0;

  if(en) begin 
  unique case(sel)

        4'b0000:data_out=data_in[1:0]; 
        4'b0001:data_out=data_in[3:2];
        4'b0010:data_out=data_in[5:4];
        4'b0011:data_out=data_in[7:6];
        4'b0100:data_out=data_in[9:8];
        4'b0101:data_out=data_in[11:10];
        4'b0110:data_out=data_in[13:12];
        4'b0111:data_out=data_in[15:14];
        4'b1000:data_out=data_in[17:16];
        4'b1001:data_out=data_in[19:18];
        4'b1010:data_out=data_in[21:20];
        4'b1011:data_out=data_in[23:22];
        4'b1100:data_out=data_in[25:24];
        4'b1101:data_out=data_in[27:26];
        4'b1110:data_out=data_in[29:28];
        4'b1111:data_out=data_in[31:30];
         
     endcase
  end 

end
endmodule

module decoder_8(input clk,rst,en,input[31:0] data_in,input[2:0] sel,output reg [3:0] data_out);

always@(*) begin 
  data_out = 0;

  if(en) begin 
  unique case(sel)

        3'b000:data_out=data_in[3:0]; 
        3'b001:data_out=data_in[7:4];
        3'b010:data_out=data_in[11:8];
        3'b011:data_out=data_in[15:12];
        3'b100:data_out=data_in[19:16];
        3'b101:data_out=data_in[23:20];
        3'b110:data_out=data_in[27:24];
        3'b111:data_out=data_in[31:28];
         
     endcase
  end 
 end
endmodule 

module decoder_4(input clk,rst,en,input[31:0] data_in,input[1:0] sel,output reg [7:0] data_out);

always@(*) begin 
  data_out = 0;

  if(en) begin 
  unique case(sel)

        2'b00:data_out=data_in[7:0]; 
        2'b01:data_out=data_in[15:8];
        2'b10:data_out=data_in[23:16];
        2'b11:data_out=data_in[31:24];
         
     endcase
  end 
 end
endmodule 

module decoder_2(input clk,rst,en,input[31:0] data_in,input  sel,output reg [15:0] data_out);

always@(*) begin 
  data_out = 0;

  if(en) begin 
  unique case(sel)

        1'b0:data_out=data_in[15:0]; 
        1'b1:data_out=data_in[31:16];
         
     endcase
  end 
 end
endmodule
