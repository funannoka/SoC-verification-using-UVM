//register interface
//`include "lcd.register.v"
interface REGISTERS;

	LCD_CFG 			reg0; //LCD Configuration and clocking control, 0xE01FC1B8
	LCD_TIMH 		reg1; //Horizontal Timing Control register, 0xFFE10000
	LCD_TIMV 		reg2; //Vertical Timing Control register, 0xFFE10004
	LCD_POL 			reg3; //Clock and Signal Polarity Control register, 0xFFE10008
	LCD_LE 			reg4; //Line End Control register, 0xFFE1000C
	LCD_UPBASE 		reg5; //Upper Panel Frame Base Address register, 0xFFE10010
	LCD_LPBASE 		reg6; //Lower Panel Frame Base Address register, 0xFFE10014
	LCD_CTRL 		reg7; //LCD Control register, 0xFFE10018 
	LCD_INTMSK 		reg8; //Interrupt Mask register, 0xFFE1001C
	LCD_INTRAW 		reg9; //Raw Interrupt Status register, 0xFFE10020
	LCD_INTSTAT 	reg10; //Masked Interrupt Status register, 0xFFE10024
	LCD_INTCLR 		reg11; //Interrupt Clear register, 0xFFE10028
	LCD_UPCURR		reg12; //Upper Panel Current Address Value register, 0xFFE1002C
	LCD_LPCURR 		reg13; //Lower Panel Current Address Value register, 0xFFE10030
//	LCD_PAL			reg14[0:127]; //256x16-bit Color Palette registers, 0xFFE10200 - 0xFFE103FC
//	CRSR_IMG			reg15[0:255]; //Cursor Image registers, 0xFFE10800 - 0xFFE10BFC
	CRSR_CRTL		reg16; //Cursor Control register, 0xFFE10C00
	CRSR_CFG 		reg17; //Cursor Configuration register, 0xFFE10C04
	CRSR_PAL0		reg18; //Cursor Palette register 0, 0xFFE10C08
	CRSR_PAL1		reg19; //Cursor Palette register 1, 0xFFE10C0C
	CRSR_XY 			reg20; //Cursor XY Position register, 0xFFE10C10
	CRSR_CLIP		reg21; //Cursor Clip Position register, 0xFFE10C14
	CRSR_INTMSK		reg22; //Cursor Interrupt Mask register, 0xFFE10C20
	CRSR_INTCLR 	reg23; //Cursor Interrupt Clear register, 0xFFE10C24
	CRSR_INTRAW 	reg24; //Cursor Raw Interrupt Status register, 0xFFE10C28
	CRSR_INTSTAT 	reg25; //Cursor Masked Interrupt Status register, 0xFFE10C2C
	
endinterface
