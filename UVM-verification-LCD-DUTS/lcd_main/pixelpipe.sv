//
// This is a simple pixel pipeline
//
`protect
module pixelpipe(input clk, input rst, input vevent,input hevent,
    input hblank,input vblank,
    output logic pull, input logic fifoempty, input logic [31:0] rdata,
    output logic [7:0] paladdr,input logic [15:0] paldata,
    output logic [7:0] curaddr,input logic [31:0] curdata,
    input logic pcdevent,input logic bebo, input logic bepo,
    input logic bgr, input logic lcddual, input logic lcdmono8,
    input logic lcdtft, input logic lcdbw, input logic [2:0] lcdbpp,
    input logic lcden,
    output logic [3:0] frame,
    output logic [23:0] pdata_out,
    input struct packed {
      logic [1:0] CsrNum;
      logic [2:0] unused1;
      logic CrsrOn;
    } CRSR_CTRL,
    input struct packed {
      logic FrameSync;
      logic CrsrSize;
    } CRSR_CFG,
    input struct packed {
      logic [7:0] Blue,Green,Red;
    } CRSR_PAL0,
    input struct packed {
      logic [7:0] Blue,Green,Red;
     } CRSR_PAL1,
    input struct packed {
      logic [9:0] CrsrY;
      logic [5:0] unused1;
      logic [9:0] CrsrX;
    } CRSR_XY,
    input struct packed {
      logic [5:0] CrsrClipY;
      logic [1:0] unused1;
      logic [5:0] CrsrClipX;
    } CRSR_CLIP
  );

reg [31:0] plat0,plat0_d;
logic pop;                    // take a pixel
logic PPpush,PPstop;          // a pixel push and stop mechanism
logic [23:0] PPdata,pdatamap;         // the pushed pixel data (Depends on the pixel mode)
logic [5:0] PPpos,PPpos_d;      // a pixel position counter for the mux
logic [9:0] hcnt,hcnt_d,vcnt,vcnt_d;
logic [19:0] gscnt;
logic PPv,PPv_d;
logic [3:0] frame0,frame0_d; // with blanking, no need to pipeline...
logic [3:0] frame0a;         // handles the positional wrapping
logic PPsv,PPsv_d;

logic CUpushin,CUstopin,CUpushout,CUstopout;
logic [23:0] CUdin,CUdout,CUdout_d;
logic CUv,CUv_d,CUcsub;

logic PLpushin,PLstopin,PLpushout,PLstopout;
logic [23:0] PLin,PLout,PLout_d;
logic PLcsub;       // cursor substitution here...
logic PLv,PLv_d;

logic [3:0] xv1, xv0_r;

logic GSv,GSv_d;
logic [23:0] GSin,GSout,GSout_d;
logic GSpushin,GSpushout,GSstopin,GSstopout;

logic PKv,PKv_d;
logic [23:0] PKin,PKout,PKout_d;
logic PKpushin,PKpushout,PKstopin,PKstopout;

logic OUv,OUv_d;
logic [23:0] OUin,OUout,OUout_d;
logic OUpushin,OUpushout,OUstopin,OUstopout;



// This is a simple pipeline
//
//  PP Pixel picker from fifo
//  CU Cursor
//  PL Palette
//  GS Grey scaler
//  PK Packer
//  OU Output Unit
//






assign gscnt={vcnt,hcnt};

gsxor g0(gscnt,xv0_r);

assign frame=frame0;
assign xv1=xv0_r;

always @(*) begin
  frame0a=frame0;
  case(xv1)
    0:  frame0a=frame0;
    1:  frame0a={ frame0[3],frame0[1],frame0[2],frame0[0]};
    2:  frame0a={ frame0[0],frame0[1],frame0[2],frame0[3]};
    3:  frame0a={ frame0[1],frame0[0],frame0[2],frame0[3]};
    4:  frame0a={ frame0[2],frame0[0],frame0[1],frame0[3]};
    5:  frame0a={ frame0[2],frame0[0],frame0[3],frame0[1]};
    6:  frame0a={ frame0[0],frame0[3],frame0[2],frame0[1]};
    7:  frame0a={ frame0[0],frame0[3],frame0[1],frame0[2]};
    8:  frame0a={ frame0[2],frame0[1],frame0[0],frame0[3]};
    9:  frame0a={ frame0[0],frame0[2],frame0[3],frame0[1]};
    10: frame0a={ frame0[2],frame0[1],frame0[3],frame0[0]};
    11: frame0a={ frame0[1],frame0[0],frame0[3],frame0[2]};
    12: frame0a={ frame0[1],frame0[2],frame0[0],frame0[3]};
    13: frame0a={ frame0[1],frame0[2],frame0[3],frame0[0]};
    14: frame0a={ frame0[3],frame0[0],frame0[1],frame0[2]};
    15: frame0a={ frame0[3],frame0[0],frame0[2],frame0[1]};
  
  endcase
end

//
//
// The pixel output
// Just a place holder for now
//
assign OUpushin = PKpushout;
assign OUstopin = (hblank|vblank)|!pcdevent;
assign OUin = PKout;

assign pdata_out = (hblank|vblank)?0:OUout;

always @(*) begin
  OUout_d = OUout;
  OUv_d = OUv;
  OUpushout = OUv;
  OUstopout = OUpushout & OUstopin;
  if(vevent) begin
    OUv_d=0;    // flush pipe
  end else begin
    if(OUv) begin
      if(!OUstopin) begin
        OUv_d = OUpushin;
        OUout_d = OUin;
      end
    end else begin
      OUv_d = OUpushin;
      OUout_d = OUin;
    end
  end
end


always @(posedge(clk) or posedge(rst)) begin
  if(rst) begin
    OUv <= 0;
    OUout <= 0;
  end else begin
    OUv <= #1 OUv_d;
    OUout <= #1 OUout_d;
  end
end

//
//
// The pixel packer
// Just a place holder for now
//
assign PKpushin = GSpushout;
assign PKstopin = OUstopout;
assign PKin = GSout;

always @(*) begin
  PKout_d = PKout;
  PKv_d = PKv;
  PKpushout = PKv;
  PKstopout = PKpushout & PKstopin;
  if(vevent) begin
    PKv_d=0;    // flush pipe
  end else begin
    if(PKv) begin
      if(!PKstopin) begin
        PKv_d = PKpushin;
        PKout_d = PKin;
      end
    end else begin
      PKv_d = PKpushin;
      PKout_d = PKin;
    end
  end
end


always @(posedge(clk) or posedge(rst)) begin
  if(rst) begin
    PKv <= 0;
    PKout <= 0;
  end else begin
    PKv <= #1 PKv_d;
    PKout <= #1 PKout_d;
  end
end

//
//
// This is a place holder for the grey scaler
//
//
assign GSpushin = CUpushout;
assign GSstopin = PKstopout;
assign GSin = CUdout;

always @(*) begin
  GSv_d = GSv;
  GSout_d = GSout;
  GSpushout = GSv;
  GSstopout = GSv & GSstopin;
  if(vevent) begin
    GSv_d=0;
  end else begin
    if(GSv) begin
      if(!GSstopin) begin
        GSv_d = GSpushin;
        GSout_d = GSin;
      end
    end else begin
      GSv_d = GSpushin;
      GSout_d = GSin;
    end
  end
end

always @(posedge(clk) or posedge(rst)) begin
  if(rst) begin
    GSv <= 0;
    GSout <= 0;
  end else begin
    GSv <= #1 GSv_d;
    GSout <= #1 GSout_d;
  end
end


always @(*) begin
  hcnt_d = hcnt;
  vcnt_d = vcnt;
  frame0_d = frame0;
  if(vevent) begin
    vcnt_d=0;
    hcnt_d=0;
    frame0_d = (frame0<<1)^((frame0[3])?3:0);
  end else if(hevent) begin
    hcnt_d=0;
    if( !(vblank) ) vcnt_d=vcnt+1;
  end else if((CUpushout && !CUstopin)) begin
    hcnt_d=hcnt+1;
  end
  
  
end

always @(posedge(clk) or posedge(rst)) begin
  if(rst) begin
    hcnt <= 0;
    vcnt <= 0;
    frame0 <= 1;
  end else begin
    hcnt <= #1 hcnt_d;
    vcnt <= #1 vcnt_d;
    frame0 <= #1 frame0_d;
  end
end



//
//
// This is a place holder for the palette stage
//
//
assign PLpushin = PPpush;
assign PLin = PPdata;
assign PLstopin=GSstopout;
logic [23:0] rd,r16,crd;

always @(*) begin
  PLv_d = PLv;
  PLout_d = PLout;
  PLpushout = PLv;
  PLstopout = PLv & PLstopin;
  paladdr = PLin[7:0];
  case(lcdbpp)
    0,1,2,3: begin
         pdatamap = paldata;
       end
    4,5,6,7: pdatamap = PLin;  
  endcase
  r16=pdatamap;  
  case(lcdbpp) 
    0,1,2,3,4: begin  
         rd = {r16[14:10],r16[15],2'b0,  
               r16[9:5],r16[15],2'b0,  
               r16[4:0],r16[15],2'b0};  
       end  
    6: begin  
         rd ={r16[15:11],3'b0,  
              r16[10:5],2'b0,  
              r16[4:0],3'b0};  
       end
    5: rd=PLin;
    7: begin  
         rd={r16[11:8],4'b0,  
             r16[7:4],4'b0,  
             r16[3:0],4'b0};  
       end  
  endcase  
  
  crd = rd;

  if(vevent) begin
    PLv_d=0;
  end else begin
    if(PLv && ! PLstopin) begin
      PLv_d = PLpushin;
      PLout_d = crd;
    end else if(PLv) begin
      // Just hold here
    end else begin
      PLv_d = PLpushin;
      PLout_d = crd;
    end
  end

end

always @(posedge(clk) or posedge(rst) ) begin
  if(rst) begin
    PLv <= 0;
    PLout <= 0;
  end else begin
    PLv <= #1 PLv_d;
    PLout <= #1 PLout_d;
  end
end

//
// This is the cursor stage...
//
assign CUstopin = PLstopout;
assign CUpushin = PLpushout;
assign PPstop = CUstopout;
assign CUdin = PLout;
always @(*) begin
  CUv_d = CUv;
  CUdout_d = CUdout;
  CUstopout=0;
  CUpushout = CUv;
  CUstopout = CUv & CUstopin;
  CUcsub=0;
  if(vevent) begin
    CUv_d=0;
  end else begin
    if(CUpushin) begin
      if( CUv && CUstopin) begin
        // hold
      end else begin
        CUv_d=CUpushin;
        CUdout_d = CUdin;
        if(1) begin
        
        end
      end
    end else begin
      if(CUv && !CUstopin) begin
        CUv_d=0;
      end
    end
  end
end

always @(posedge(clk) or posedge(rst)) begin
  if(rst) begin
    CUv <= 0;
    CUdout <= 0;
    
  end else begin
    CUv <= #1 CUv_d;
    CUdout <= #1 CUdout_d;
  end
end



//
// This is the pixel picker state...
//

function [4:0] ppsmap();
  begin
    case({bebo,bepo})
      0: ppsmap=PPpos;
      1: ppsmap=PPpos^5'h7;
      2: ppsmap=PPpos;
      3: ppsmap=~PPpos;    
    endcase
  end
endfunction : ppsmap

function [23:0] get2bit();
  reg [4:0] samt;
  begin
    case ({bebo,bepo})
      0: samt = PPpos*2;
      1: samt = (PPpos^3)*2;
      2: samt = PPpos*2;
      3: samt = (~PPpos)*2;
    endcase
    get2bit = (plat0 >> samt)&24'h3;
  end
endfunction : get2bit

function [23:0] get4bit();
  reg [4:0] samt;
  begin
    case({bebo,bepo})
      0: samt = PPpos*4;
      1: samt = (PPpos^1)*4;
      2: samt = PPpos*4;
      3: samt = (~PPpos)*4;
    endcase
    get4bit = (plat0 >> samt)&24'hf;
  end
endfunction : get4bit

function [23:0] get8bit();
  reg [4:0] samt;
  begin
    case({bebo,bepo})
      0,1,2: samt = PPpos*8;
      3: samt = (~PPpos)*8;
    endcase
    get8bit = (plat0 >> samt)&24'hff;
  end
endfunction : get8bit

function [23:0] get16bit();
  logic [15:0] r16;
  logic [23:0] rd;
  begin
    r16= (PPpos[0]^bebo)?plat0[31:16]:plat0[15:0];
    get16bit = r16;
  end
endfunction : get16bit

always @(*) begin
  PPpush=0;
  pop=0;
  PPpos_d=PPpos;
  PPdata=0;
  PPsv_d = PPsv;
  if(vevent) begin
    PPsv_d=0;
    PPpos_d=0;
  end else if(PPv) begin
    PPpush=1;
    if(!PPstop) begin
      PPsv_d=PPv;
    end
    case(lcdbpp)
      0: begin      // 1bpp
           PPdata = plat0[ppsmap()];
           if(!PPstop) begin
             PPpos_d=PPpos+1;
             if(PPpos_d[4:0]==0) pop=1;
           end
         end
      1: begin      // 2bpp
           PPdata = get2bit();
           if(!PPstop) begin
             PPpos_d=PPpos+1;
             if(PPpos_d[4]) begin
               pop=1;
               PPpos_d=0;
             end
           end
         end
      2: begin      // 4bpp
           PPdata = get4bit();
           if(!PPstop) begin
             PPpos_d=PPpos+1;
             if(PPpos_d[3]) begin
               pop=1;
               PPpos_d=0;
             end
           end
         end
      3: begin      // 8bpp
           PPdata = get8bit();
           if(!PPstop) begin
             PPpos_d=PPpos+1;
             if(PPpos_d[2]) begin
               pop=1;
               PPpos_d=0;
             end
           end
         end
      4,6,7: begin  // 16 bpp
           PPdata=get16bit();
           if(!PPstop) begin
             PPpos_d=PPpos+1;
             if(PPpos_d[1]) begin
               pop=1;
               PPpos_d=0;
             end
           end
         end
      5: begin  // 32bpp
           PPdata=plat0;
           if(!PPstop) begin
             pop=1;
             PPpos_d=0;
           end
         end
    endcase
  end
end


//
// The funnel shifter platform
//
//
always @(*) begin
  PPv_d = PPv;
  plat0_d = plat0;
  pull = 0;
  if(vevent) begin
    PPv_d = 0;
    plat0_d=0;
  end else if(pop) begin
    PPv_d=!fifoempty;
    plat0_d=rdata;
    pull=1;
  end else begin
    if( !PPv ) begin
      pull = 1;
      plat0_d=rdata;
      PPv_d = !fifoempty;
    end
  end
end

always @(posedge(clk) or posedge(rst)) begin
  if(rst) begin
    PPv <= 0;
    PPsv <= 0;
    plat0 <= 0;
    PPpos <= 0;
  end else begin
    PPv <= #1 PPv_d;
    plat0 <= #1 plat0_d;
    PPpos <= #1 PPpos_d;
    PPsv <= #1 PPsv_d;
  end
end



endmodule : pixelpipe
`endprotect

