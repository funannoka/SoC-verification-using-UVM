//register struct definition

typedef struct packed {
logic [31:5] reserved;
logic [4:0] CLKDIV;
} LCD_CFG;

typedef struct packed {
logic [31:24] HBP;
logic [23:16] HFP;
logic [15:8] HSW;
logic [7:2] PPL;
logic [1:0] reserved;
} LCD_TIMH;

typedef struct packed {
logic [31:24] VBP;
logic [23:16] VFP;
logic [15:10] VSW;
logic [9:0] LPP;
} LCD_TIMV;

typedef struct packed {
logic [31:27] PCD_HI;
logic BCD;
logic [25:16] CPL;
logic reserved;
logic IOE;
logic IPC;
logic IHS;
logic IVS;
logic [10:6] ACB;
logic CLKSEL;
logic [4:0] PCD_LO;
} LCD_POL;

typedef struct packed {
logic [31:17] reserved1;
logic LEE;
logic [15:7] reserved2;
logic [6:0] LED;
} LCD_LE;

typedef struct packed {
logic [31:3] LCDUPBASE;
logic [2:0] reserved;
} LCD_UPBASE;

typedef struct packed {
logic [31:3] LCDLPBASE;
logic [2:0] reserved;
} LCD_LPBASE;

typedef struct packed {
logic [31:17] reserved1;
logic WATERMARK;
logic [15:14] reserved2;
logic [13:12] LcdVComp;
logic LcdPwr;
logic BEPO;
logic BEBO;
logic BGR;
logic LcdDual;
logic LcdMono8;
logic LcdTFT;
logic LcdBW;
logic [3:1] LcdBpp;
logic LcdEn;
} LCD_CTRL;

typedef struct packed {
logic [31:5] reserved1;
logic BERIM;
logic VCompIM;
logic LNBUIM;
logic FUFIM;
logic reserved2;
} LCD_INTMSK;

typedef struct packed {
logic [31:5] reserved1;
logic BERRAW;
logic VCompRIS;
logic LNBURIS;
logic FUFRIS;
logic reserved2;
} LCD_INTRAW;

typedef struct packed {
logic [31:5] reserved1;
logic BERMIS;
logic VCompMIS;
logic LNBUMIS;
logic FUFMIS;
logic reserved2;
} LCD_INTSTAT;

typedef struct packed {
logic [31:5] reserved1;
logic BERIC;
logic VCompIC;
logic LNBUIC;
logic FUFIC;
logic reserved2;
} LCD_INTCLR;

typedef struct packed {
logic [31:0] LCDUPCURR;
} LCD_UPCURR;

typedef struct packed {
logic [31:0] LCDLPCURR;
} LCD_LPCURR;

typedef struct packed {
logic I1;
logic [30:26] B1;
logic [25:21] G1;
logic [20:16] R1;
logic I0;
logic [14:10] B0;
logic [9:5] G0;
logic [4:0] R0;
} LCD_PAL;

typedef struct packed {
logic [31:0] CRSR_IMG;
} CRSR_IMG;

typedef struct packed {
logic [31:6] reserved1;
logic [5:4] CrsrNum;
logic [3:1] reserved2;
logic CrsrOn;
} CRSR_CRTL;

typedef struct packed {
logic [31:2] reserved;
logic FrameSync;
logic CrsrSize;
} CRSR_CFG;

typedef struct packed {
logic [31:24] reserved;
logic [23:16] Blue;
logic [15:8] Green;
logic [7:0] Red;
} CRSR_PAL0;

typedef struct packed {
logic [31:24] reserved;
logic [23:16] Blue;
logic [15:8] Green;
logic [7:0] Red;
} CRSR_PAL1;

typedef struct packed {
logic [31:26] reserved1;
logic [25:16] CrsrY;
logic [15:10] reserved2;
logic [9:0] CrsrX;
} CRSR_XY;

typedef struct packed {
logic [31:14] reserved1;
logic [13:8] CrsrClipY;
logic [7:6] reserved2;
logic [5:0] CrsrClipX;
} CRSR_CLIP;

typedef struct packed {
logic [31:1] reserved;
logic CrsrIM;
} CRSR_INTMSK;

typedef struct packed {
logic [31:1] reserved;
logic CrsrIC;
} CRSR_INTCLR;

typedef struct packed {
logic [31:1] reserved;
logic CrsrRIS;
} CRSR_INTRAW;

typedef struct packed {
logic [31:1] reserved;
logic CrsrMIS;
} CRSR_INTSTAT;


