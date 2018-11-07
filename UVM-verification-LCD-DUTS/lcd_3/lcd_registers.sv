typedef struct packed { //7.1
  logic [26:0] reserved;
  logic [4:0] CLKDIV;
} LCD_CFG_REG;

typedef struct packed { //7.2
  logic [7:0] HBP;
  logic [7:0] HFP;
  logic [7:0] HSW;
  logic [5:0] PPL;
  logic [1:0] reserved;
} LCD_TIMH_REG;

typedef struct packed { //7.3
  logic [7:0] VBP;
  logic [7:0] VFP;
  logic [5:0] VSW;
  logic [9:0] LPP;
} LCD_TIMV_REG;

typedef struct packed { //7.4
  logic [4:0] PCD_HI;
  logic BCD;
  logic [9:0] CPL;
  logic reserved;
  logic IOE;
  logic IPC;
  logic IHS;
  logic IVS;
  logic [4:0] ACB;
  logic CLKSEL;
  logic [4:0] PCD_LO;
} LCD_POL_REG;

typedef struct packed { //7.5
  logic [14:0] reserved;
  logic LEE;
  logic [8:0] reserved1;
  logic [6:0] LED;
} LCD_LE_REG;

typedef struct packed { //7.6
  logic [28:0] LCDUPBASE;
  logic [2:0] reserved;
  } LCD_UPBASE_REG;
  
typedef struct packed { //7.7
  logic [28:0] LCDLPBASE;
  logic [2:0] reserved;
} LCD_LPBASE_REG;

typedef struct packed { //7.8
  logic [14:0] reserved;
  logic WATERMARK;
  logic [1:0] reserved1;
  logic [1:0] LcdVComp;
  logic LcdPwr;
  logic BEPO;
  logic BEBO;
  logic BGR;
  logic LcdDual;
  logic LcdMono8;
  logic LcdTFT;
  logic LcdBW;
  logic [2:0] LcdBpp;
  logic LcdEn;
} LCD_CTRL_REG;

typedef struct packed { //7.9
  logic [26:0] reserved;
  logic BERIM;
  logic VCompIM;
  logic LNBUIM;
  logic FUFIM;
  logic reserved1;
} LCD_INTMSK_REG;

typedef struct packed { //7.10
  logic [26:0] reserved;
  logic BERRAW;
  logic VCompRIS;
  logic LNBURIS;
  logic FUFRIS;
  logic reserved1;
} LCD_INTRAW_REG;

typedef struct packed { //7.11
  logic [26:0] reserved;
  logic BERMIS;
  logic VCompMIS;
  logic LNBUMIS;
  logic FUFMIS;
  logic reserved1;
} LCD_INTSTAT_REG;

typedef struct packed { //7.12
  logic [26:0] reserved;
  logic BERIC;
  logic VCompIC;
  logic LNBUIC;
  logic FUFIC;
  logic reserved1;
} LCD_INTCLR_REG;

typedef struct packed { //7.13
  logic [31:0] LCDUPCURR;
} LCD_UPCURR_REG;

typedef struct packed { //7.14
  logic [31:0] LCDLPCURR;
} LCD_LPCURR_REG;

typedef struct packed { //7.15
  logic I;
  logic [4:0] B_5_0;//B[4:0]
  logic [4:0] G_5_0;
  logic [4:0] R_5_0;
  logic I1;
  logic [4:0] B_5_1;
  logic [4:0] G_5_1;
  logic [4:0] R_5_1;
} LCD_PAL_REG;

typedef struct packed { //7.16
  logic [31:0] CRSR_IMG;
} CRSR_IMG_REG;

typedef struct packed { //7.17
  logic [25:0] reserved;
  logic [1:0] CrsrNum_2;//CrsrNum[1:0]
  logic [2:0] reserved1;
  logic CrsrOn;
} CRSR_CTRL_REG;

typedef struct packed { //7.18
  logic [29:0] reserved;
  logic FrameSync;
  logic CrsrSize;
} CRSR_CFG_REG;

typedef struct packed { //7.19
  logic [7:0] reserved;
  logic [7:0] Blue;
  logic [7:0] Green;
  logic [7:0] Red;
} CRSR_PAL0_REG;

typedef struct packed { //7.20
  logic [7:0] reserved;
  logic [7:0] Blue;
  logic [7:0] Green;
  logic [7:0] Red;
} CRSR_PAL1_REG;

typedef struct packed { //7.21
  logic [5:0] reserved;
  logic [9:0] CrsrY;
  logic [5:0] reserved1;
  logic [9:0] CrsrX;
} CRSR_XY_REG;

typedef struct packed { //7.22
  logic [17:0] reserved;
  logic [5:0] CrsrClipY;
  logic [1:0] reserved1;
  logic [5:0] CrsrClipX;
} CRSR_CLIP_REG;

typedef struct packed { //7.23
  logic [30:0] reserved;
  logic CrsrIM;
} CRSR_INTMSK_REG;

typedef struct packed {  //7.24
  logic [30:0] reserved;
  logic CrsrIC;
} CRSR_INTCLR_REG;
  
typedef struct packed { //7.25
  logic [30:0] reserved;
  logic CrsrRIS;
} CRSR_INTRAW_REG;

typedef struct packed { //7.26
  logic [30:0] reserved;
  logic CrsrMIS;
} CRSR_INTSTAT_REG;

// Reg_name registeraddress value rd/wr_enable;
//mem[addr]=data;
