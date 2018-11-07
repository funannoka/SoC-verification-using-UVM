//
// This is My reference version of the lcd controller.
//

`include "lcd_master.sv"
`include "lcd_fifo.sv"
`include "pixelpipe.sv"
`include "gsxor.sv"


module lcd(AHBIF.AHBCLKS C, AHBIF.AHBM M, 
    AHBIF.AHBS S, MEMIF.F0 f0, MEMIF.F0 f1,RAM128IF.R0 cpal,
    RAM256IF.R0 crsr, LCDOUT.O0 lcdout
);

enum { IDLE,BUSY,NONSEQUENTIAL,SEQ } htrans_defs;
enum { OKAY,ERROR,RETRY,SPLIT } hresp_defs;

struct packed {
  logic [7:0] hbp,hfp,hsw;
  logic [5:0] ppl;
} lcd_timh;

struct packed {
  logic [7:0] vbp,vfp;
  logic [5:0] vsw;
  logic [9:0] lpp;
} lcd_timv;

struct packed {
  logic [4:0] pcd_hi;
  logic bcd;
  logic [9:0] cpl;
  logic reserved;
  logic ioe;
  logic ipc;
  logic ihs;
  logic ivs;
  logic [4:0] acb;
  logic clksel;
  logic [4:0] pcd_lo;
} lcd_pol;

logic lee;
logic [6:0] led;

struct packed {
  logic watermark;
  logic [1:0] reserved;
  logic [1:0] lcdvcomp;
  logic lcdpwr;
  logic bepo,bebo,bgr,lcddual,lcdmono8,lcdtft,lcdbw;
  logic [2:0] bpp;
  logic lcden;
} lcdctrl;

struct packed {
    logic [1:0] CsrNum;
    logic [2:0] unused1;
    logic CrsrOn;
} CRSR_CTRL;

struct packed {
    logic FrameSync;
    logic CrsrSize;
} CRSR_CFG;

struct packed {
    logic [7:0] Blue,Green,Red;
} CRSR_PAL0;

struct packed {
    logic [7:0] Blue,Green,Red;
} CRSR_PAL1;

struct packed {
    logic [9:0] CrsrY;
    logic [5:0] unused1;
    logic [9:0] CrsrX;
} CRSR_XY;

struct packed {
    logic [5:0] CrsrClipY;
    logic [1:0] unused1;
    logic [5:0] CrsrClipX;
} CRSR_CLIP;
 

logic [9:0] pcd;
assign pcd = { lcd_pol.pcd_hi, lcd_pol.pcd_lo };
logic [9:0] pcdcnt,pcdcnt_d,halfpcd;
logic pcdevent,pcdevent_d;

logic im_ready;
assign im_ready = 1;
assign S.HREADY = im_ready;

logic [31:0] saddr;
logic pw,pr;

logic [4:0] clkdiv;

logic [31:0] lcdupbase,lcdlpbase;
logic [31:0] lcdupcurr,lcdupcurr_d;
logic [31:0] lcdlpcurr,lcdlpcurr_d;

logic lcd_running;

assign lcd_running = lcdctrl.lcden;

logic [4:0] pixelclkcnt,pixelclkcnt_d;
logic pixelclkevent,pixelclkevent_d;
logic lcddclk,lcddclk_d;    // used for output...
logic pixelclk,pixelclk_d;

logic [7:0] hcntr,hcntr_d;
logic [3:0] pixel_group,pixel_group_d;
logic hs,hs_d;
logic hclkevent,hclkevent_d;
logic hblank,hblank_d;
typedef enum [1:0] { HSbp,HSsync,HSfp,HSline } HState;
HState chs,nhs;

logic [9:0] vcntr,vcntr_d;
logic vs,vs_d;
logic vclkevent,vclkevent_d;
logic vblank,vblank_d;
typedef enum [1:0] { VSbp,VSsync,VSfp,VSline } VState;
VState cvs,nvs;

logic Mfetch,Mdone;
logic [31:0] Mfaddr;
logic [4:0] Mfwords;
logic Mdstrobe;
logic [31:0] Mfdata;

//
// Some declares for the bus master items
//
typedef enum [2:0] { Pidle,Preq,Pend } Pstate;
Pstate cps,nps;

logic pushf0,pullf0,fullf0,emptyf0;
logic [31:0] wdataf0,rdataf0;
logic [5:0] cnt0;

assign wdataf0 = Mfdata;
assign pushf0 = Mdstrobe;
logic  [5:0] ntf,ntf_d;
logic flush0=vclkevent;
logic acbiasx;
logic panelclk;
logic [3:0] frame;
logic [23:0] pdata;

assign lcdout.LCDFP = lcdctrl.lcden & lcdctrl.lcdpwr & (vs^lcd_pol.ivs);
assign lcdout.LCDLP = lcdctrl.lcden & lcdctrl.lcdpwr & (hs^lcd_pol.ihs);
assign lcdout.LCDPWR = lcdctrl.lcdpwr;
assign lcdout.LCDENA_LCDM = lcdctrl.lcden & lcdctrl.lcdpwr & ( (lcdctrl.lcdtft)?~(hblank | vblank):acbiasx);
assign lcdout.LCDDCLK= lcdctrl.lcden & lcdctrl.lcdpwr & ((lcd_pol.bcd)?pixelclk : panelclk);
assign lcdout.lcd_frame = frame;
assign lcdout.LCDVD = pdata;


lcd_fifo fifo0(C,pushf0,fullf0,wdataf0,pullf0,emptyf0,rdataf0,cnt0,flush0,f0);

lcd_master m0(C,M,Mfetch,Mdone,Mfaddr,Mfwords,
        Mdstrobe,Mfdata);

pixelpipe p0(C.HCLK,C.HRESET,vclkevent,hclkevent,
    hblank,vblank,pullf0,emptyf0,rdataf0,
    cpal.raddr,cpal.rdata,
    crsr.raddr,crsr.rdata,
    pcdevent,lcdctrl.bebo,lcdctrl.bepo,
    lcdctrl.bgr,lcdctrl.lcddual,lcdctrl.lcdmono8,
    lcdctrl.lcdtft,lcdctrl.lcdbw,lcdctrl.bpp,
    lcdctrl.lcden,
    frame,pdata,
    CRSR_CTRL,
    CRSR_CFG,
    CRSR_PAL0,
    CRSR_PAL1,
    CRSR_XY,
    CRSR_CLIP
    );
    

always @(*) begin
  nps=cps;
  Mfetch=0;
  lcdupcurr_d = lcdupcurr;
  Mfwords=4;
  ntf_d = ntf;
  flush0=0;
  case(cps)
    Pidle:
      begin
        if(vclkevent) begin
          nps = Preq;
          lcdupcurr_d = lcdupbase;
          flush0=1;
        end else if(cnt0 < 28) begin
          nps = Preq;
        end
      end
    Preq:
      begin
        Mfetch=1;
        Mfaddr = lcdupcurr;
        ntf_d = 32-cnt0;
        if(ntf_d > 8) ntf_d=8;
        Mfwords = ntf_d;
        nps=Pend;
      end
    Pend:
      begin
        Mfaddr = lcdupcurr;
        Mfwords = ntf;
        if(Mdone) begin
          nps=Pidle;
          lcdupcurr_d = lcdupcurr+Mfwords*4;
        end
      end
  endcase
end

always @(posedge(C.HCLK) or posedge(C.HRESET)) begin
  if(C.HRESET) begin
    cps <= Pidle;
    lcdupcurr <= 0;
    ntf <= 0;
  end else begin
    cps <= #1 nps;
    lcdupcurr <= #1 lcdupcurr_d;
    ntf <= #1 ntf_d;
  end
end
        
        
//
// The vertical counter(s)
//

always @(*) begin
  vblank_d = vblank;
  vclkevent_d=0;
  vs_d=vs;
  vcntr_d = vcntr;
  nvs=cvs;
  if(hclkevent) case(cvs)
    VSbp: begin
        vblank_d=1;
        if(vcntr[7:0] == lcd_timv.vbp) begin
          vcntr_d=0;
          nvs=VSsync;
          vs_d=1;
          vclkevent_d=1;
        end else begin
          vcntr_d=vcntr+1;
        end
      end
    VSsync: begin
        vblank_d=1;
        vs_d=1;
        if(vcntr[5:0] == lcd_timv.vsw) begin
          vcntr_d=0;
          nvs=VSfp;
          vs_d=0;
        end else begin
          vcntr_d=vcntr+1;
        end
      end
    VSfp: begin
        vblank_d=1;
        if(vcntr[7:0] == lcd_timv.vfp) begin
          vcntr_d=0;
          nvs=VSline;
          vblank_d =0;
        end else begin
          vcntr_d=vcntr+1;
        end    
      end
    VSline: begin
        vblank_d=0;
        vcntr_d=vcntr+1;
        if(vcntr==lcd_timv.lpp) begin
            vcntr_d=0;
            nvs=VSbp;
            vblank_d=1;
        end
      end
  endcase

end

//
// The horizontal counter(s)
//

always @(*) begin
  hblank_d = hblank;
  hclkevent_d=0;
  hs_d=hs;
  hcntr_d = hcntr;
  nhs=chs;
  pixel_group_d=pixel_group;
  if(pixelclkevent) case(chs)
    HSbp: begin
        hblank_d=1;
        if(hcntr == lcd_timh.hbp) begin
          hcntr_d=0;
          nhs=HSsync;
          hs_d=1;
          hclkevent_d=1;
        end else begin
          hcntr_d=hcntr+1;
        end
      end
    HSsync: begin
        hblank_d=1;
        hs_d=1;
        if(hcntr == lcd_timh.hsw) begin
          hcntr_d=0;
          nhs=HSfp;
          hs_d=0;
        end else begin
          hcntr_d=hcntr+1;
        end
      end
    HSfp: begin
        hblank_d=1;
        if(hcntr == lcd_timh.hfp) begin
          hcntr_d=0;
          nhs=HSline;
          hblank_d =0;
          pixel_group_d=0;
        end else begin
          hcntr_d=hcntr+1;
        end    
      end
    HSline: begin
        hblank_d=0;
        if(pixel_group==15) begin
          pixel_group_d=0;
          hcntr_d=hcntr+1;
          if(hcntr[5:0]==lcd_timh.ppl) begin
            hcntr_d=0;
            nhs=HSbp;
            hblank_d=1;
          end
        end else begin
          pixel_group_d=pixel_group+1;
        end
      end
  endcase

end

always @(posedge(C.HCLK) or posedge(C.HRESET)) begin
  if(C.HRESET) begin
    hcntr <= 0;
    chs <= HSbp;
    pixel_group <= 0;
    hs <= 0;
    hclkevent <= 0;
    hblank <= 0;
    vs <= 0;
    vcntr <= 0;
    cvs <= VSbp;
    vclkevent <= 0;
    vblank <= 0;
  end else begin
    pixel_group <= #1 pixel_group_d;
    hcntr <= #1 hcntr_d;
    chs <= #1 nhs;
    hs <= #1 hs_d;
    hclkevent <= #1 hclkevent_d;
    hblank <= #1 hblank_d;
    vcntr <= #1 vcntr_d;
    cvs <= #1 nvs;
    vs <= #1 vs_d;
    vclkevent <= #1 vclkevent_d;
    vblank <= #1 vblank_d;
  end
end



//
// The pixel clock stuff
//

always @(*) begin
  pixelclkevent_d=0;
  pixelclk_d=pixelclk;
  if(lcdctrl.lcden) begin
    if(pixelclkcnt == clkdiv) begin
      pixelclkevent_d = 1;
      pixelclkcnt_d=0;
//      pixelclk_d=1;
    end else begin
      pixelclkcnt_d=pixelclkcnt+1;
      if(pixelclkcnt > (clkdiv>>1)) pixelclk_d=1;
    end
    if(pixelclkcnt == 0) pixelclk_d=0;
  end else begin
    pixelclkcnt_d=0;
  end
end

always @(*) begin
  pcdcnt_d = pcdcnt;
  pcdevent_d = 0;
  lcddclk_d = lcddclk;
  halfpcd = {1'b0,pcd[9:1]};
  if(lcdctrl.lcden) begin
    if(vs) begin
      pcdcnt_d=0;
      lcddclk_d=0;
    end else begin
      if(lcd_pol.bcd) begin
        lcddclk_d = pixelclkevent_d;
        pcdevent_d = pixelclkevent_d;
      end else begin
        if(halfpcd<pcdcnt) lcddclk_d=1;
        if(pcdcnt==0)  lcddclk_d=0;
        if(pcdcnt==0) pcdevent_d=1;
        pcdcnt_d = pcdcnt+1;
        if(pcdcnt>pcd) begin
          pcdcnt_d=0;
        end
      end
    end
  end else begin
    pcdcnt_d = 0;
    lcddclk_d = 0;
  end

end

always @(posedge(C.HCLK) or posedge(C.HRESET)) begin
  if(C.HRESET) begin
    pixelclkcnt<= 0;
    pixelclkevent <= 0;
    pixelclk <= 0;
    pcdcnt <= 0;
    pcdevent <= 0;
    lcddclk <= 0;
    end else begin
    pixelclkcnt<= #1 pixelclkcnt_d;
    pixelclkevent <= #1 pixelclkevent_d;
    pixelclk <= #1 pixelclk_d;
    pcdcnt <= #1 pcdcnt_d;
    pcdevent <= #1 pcdevent_d;
    lcddclk <= #1 lcddclk_d;
  end
end

//
// This logic responds to the slave interface
//
always @(*) begin
  S.HRDATA = 32'h1234567;
  case(saddr[11:0])
    12'h1b8: S.HRDATA = { 27'b0, clkdiv };
    12'h000: S.HRDATA = { lcd_timh, 2'b0 };
    12'h004: S.HRDATA = lcd_timv;
    12'h008: S.HRDATA = lcd_pol;
    12'h00c: S.HRDATA = { 15'b0,lee,9'b0,led };
    12'h010: S.HRDATA = lcdupbase;
    12'h014: S.HRDATA = lcdlpbase;
    12'h018: S.HRDATA = lcdctrl;

    12'h02c: S.HRDATA = lcdupcurr;
    12'h030: S.HRDATA = lcdlpcurr;
    12'hc00: S.HRDATA = CRSR_CTRL;
    12'hc04: S.HRDATA = CRSR_CFG;
    12'hc08: S.HRDATA = CRSR_PAL0;
    12'hc0c: S.HRDATA = CRSR_PAL1;
    12'hc10: S.HRDATA = CRSR_XY;
  endcase

end

always @(posedge(C.HCLK) or posedge(C.HRESET)) begin
  if(C.HRESET) begin
    saddr <= 0;
    pw <= 0;
    pr <= 0;
    clkdiv <= 0;
    lcd_timh <= 0;
    lcd_timv <= 0;
    lcd_pol <= 0;
    lee <= 0;
    led <= 0;
    lcdupbase <= 0;
    lcdlpbase <= 0;
    lcdctrl <= 0;
    CRSR_CTRL <= 0;
    CRSR_PAL0 <= 0;
    CRSR_PAL1 <= 0;
    CRSR_XY <= 0;
    CRSR_CLIP <= 0;
  end else begin
    
    if(S.HSEL && S.HTRANS[1]) begin
      saddr <= #1 S.HADDR;
    end
    if(im_ready && S.HSEL && S.HTRANS[1]) begin
      pw <= #1 (S.HWRITE);
      pr <= #1 ~(S.HWRITE);
    end else begin
      pw <= #1 0;
      pr <= #1 0;
    end
    if(pw) begin
      case( saddr[11:0] ) inside
        12'h1b8: clkdiv <=  #1 S.HWDATA[4:0];
        12'h000: lcd_timh <= #1 S.HWDATA[31:2];
        12'h004: lcd_timv <= #1 S.HWDATA;
        12'h008: lcd_pol <= #1  S.HWDATA;
        12'h00c: begin
                    lee <= #1 S.HWDATA[16];
                    led <= #1 S.HWDATA[6:0];
                 end
        12'h010: lcdupbase <= #1 { S.HWDATA[31:3],3'b0 };
        12'h014: lcdlpbase <= #1 { S.HWDATA[31:3],3'b0 };
        12'h018: lcdctrl <= #1 S.HWDATA[16:0];
        12'hc00: CRSR_CTRL <= #1 {S.HWDATA[5:4],3'b0,S.HWDATA[0]};
        12'hc04: CRSR_CFG <= #1 S.HWDATA;
        12'hc08: CRSR_PAL0 <= #1 S.HWDATA;
        12'hc0c: CRSR_PAL1 <= #1 S.HWDATA;
        12'hc10: CRSR_XY <= #1 S.HWDATA;
        
      endcase
    end
  end

end

always @(*) begin
  cpal.write = 0;
  if(pw && (saddr[11:0] >= 12'h200 && saddr[11:0] <= 12'h3fc)) begin
    cpal.write = 1;
  end
end
assign cpal.wdata = S.HWDATA;
assign cpal.waddr = saddr[8:2];

always @(*) begin
  crsr.write=0;
  if(pw && (saddr[11:0] >= 12'h800 && saddr[11:0] <= 12'hbfc)) begin
    crsr.write=1;
  end
end
assign crsr.wdata = S.HWDATA;
assign crsr.waddr = saddr[9:2];






endmodule : lcd

