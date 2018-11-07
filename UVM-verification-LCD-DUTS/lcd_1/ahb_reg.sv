

//typedef struct packed{

typedef struct packed{ 

  reg   [26:0] UNUSED;
  reg    [4:0] CLKDIV;        
                  
} LCD_CFG;                    

typedef struct packed{ 

  reg   [7:0] HBP;          
  reg   [7:0] HFP;          
  reg   [7:0] HSW;          
  reg   [5:0] PPL;          
  reg   [1:0] UNUSED;

} LCD_TIMH;                   


typedef struct packed{

  reg   [7:0] VBP;          
  reg   [7:0] VFP;          
  reg   [5:0] VSW;          
  reg   [9:0] LPP;          

}LCD_TIMV;                    

typedef struct packed{

  reg   [4:0] PCD_HI;       
  reg         BCD;          
  reg   [9:0] CPL;          
  reg         UNUSED;
  reg         IOE;          
  reg         IPC;          
  reg         IHS;          
  reg         IVS;          
  reg   [4:0] ACB;          
  reg         CLKSEL;       
  reg   [4:0] PCD_LO;       

}LCD_POL;                     

typedef struct packed{

  reg   [14:0] UNUSED_le0;
  reg          LEE;          
  reg   [8: 0] UNUSED_le1;
  reg   [6: 0] LED;          

}LCD_LE;                      

typedef struct packed{

  reg   [28: 0] LCDUPBASE;    
  reg   [ 2: 0] UNUSED;

}LCD_UPBASE;                  

typedef struct packed{

  reg   [28: 0] LCDLPBASE;     
  reg   [ 2: 0] UNUSED;

}LCD_LPBASE;                  

typedef struct packed{

  reg   [14:0] UNUSED_0;
  reg          WATERMARK;    
  reg   [1:0] UNUSED_1;
  reg   [1:0] LCDVCOMP;     
  reg         LCDPWR;       
  reg         BEPO;         
  reg         BEBO;         
  reg         BGR;          
  reg         LCDDUAL;      
  reg         LCDMONO8;     
  reg         LCDTFT;       
  reg         LCDBW;        
  reg   [2:0] LCDBPP;      
  reg         LCDEN;        

}LCD_CTRL;                    

typedef struct packed {

  reg   [26:0] UNUSED_0;
  reg          BERIM;        
  reg          VCOMPIM;      
  reg          LNBUIM;       
  reg          FUFIM;        
  reg          UNUSED_1;

}LCD_INTMSK;                  
	
typedef struct packed {

  reg   [26: 0] UNUSED_0;
  reg    BERRAW;       
  reg    VCOMPRIS;     
  reg    LNBURIS;      
  reg    FUFRIS;       
  reg    UNUSED_1;

}LCD_INTRAW;                  

typedef struct packed {


  reg   [26:0] UNUSED_0;
  reg    BERMIS;       
  reg    VCOMPMIS;     
  reg    LNBUMIS;      
  reg    FUFMIS;       
  reg    UNUSED_1;

}LCD_INTSTAT;                 

typedef struct packed {

  reg   [26: 0] UNUSED_0;
  reg    BERIC;       
  reg    VCOMPIC;     
  reg    LNBUIC;      
  reg    FUFIC;       
  reg    UNUSED_1;

}LCD_INTCLR;                  

typedef struct packed {

  reg   [31:0] LCDUPCURR;     

}LCD_UPCURR;                  

typedef struct packed {

  reg   [31:0] LCDLPCURR;     

}LCD_LPCURR;                  

typedef struct packed {

  reg    I_UNUSED_LN;
  reg   [4:0] B_LN;         
  reg   [4:0] G_LN;         
  reg   [4:0] R_LN;         
  reg    I_UNUSED_HN;
  reg   [ 4: 0] B_HN;         
  reg   [ 4: 0] G_HN;         
  reg   [ 4: 0] R_HN;         

}LCD_PAL;                     

typedef struct packed {

  reg   [31:0] CRSR_IMG;      

}CRSR_IMG;                    

typedef struct packed {

  reg   [25: 0] UNUSED_0;
  reg   [ 1: 0] CRSRNUM;      
  reg   [ 2: 0] UNUSED_1;
  reg    CRSRON;       

}CRSR_CTRL;                   

typedef struct packed {

  reg   [29: 0] UNUSED;
  reg    FRAMESYNC;    
  reg    CRSRSIZE;     

}CRSR_CFG;                    

typedef struct packed {

  reg   [ 7: 0] UNUSED;
  reg   [ 7: 0] BLUE;         
  reg   [ 7: 0] GREEN;        
  reg   [ 7: 0] RED;          

}CRSR_PAL0;                   

typedef struct packed {

  reg   [ 7: 0] UNUSED;
  reg   [ 7: 0] BLUE;         
  reg   [ 7: 0] GREEN;        
  reg   [ 7: 0] RED;          

}CRSR_PAL1;                   

typedef struct packed {

  reg   [ 5: 0] UNUSED_0;
  reg   [ 9: 0] CRSRY;        
  reg   [ 5: 0] UNUSED_1;
  reg   [ 9: 0] CRSRX;        

}CRSR_XY;                     

typedef struct packed {

  reg   [17: 0] UNUSED_0;
  reg   [ 5: 0] CRSRCLIPY;    
  reg   [ 1: 0] UNUSED_1;
  reg   [ 5: 0] CRSRCLIPX;    

}CRSR_CLIP;                   
	
typedef struct packed {

  reg   [30: 0] UNUSED;
  reg    CRSRIM;       

}CRSR_INTMSK;                 

typedef struct packed {

  reg   [30: 0] UNUSED;
  reg    CRSRIC;       

}CRSR_INTCLR;                 

typedef struct packed {

  reg   [30: 0] UNUSED;
  reg    CRSRRIS;      

}CRSR_INTRAW;                 

typedef struct packed {

  reg   [30: 0] UNUSED;
  reg   CRSRMIS;      

}CRSR_INTSTAT;                


//} LCD_CTRL_reg;
