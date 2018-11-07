module arbitrator (
input hclk,
input hreset,
AHBIF.AHBMin Q0_M,
AHBIF.AHBMin Q1_M,
AHBIF.AHBMin Q2_M,
AHBIF.AHBMin Q3_M,
AHBIF.AHBMin TB_M, 
AHBIF.AHBSout Q0_S,
AHBIF.AHBSout Q1_S,
AHBIF.AHBSout Q2_S,
AHBIF.AHBSout Q3_S,
AHBIF.AHBSout TB_S );
//         (Q0.HCLK,Q0.HRESET,Q0.AHBMin,Q1.AHBMin,Q2.AHBMin,Q3.AHBMin,TB.AHBMin,
//                  Q0.AHBSout,Q1.AHBSout,Q2.AHBSout,Q3.AHBSout,TB.AHBSout);
// (AHB.AHBCLKS ,AHB.AHBMin Q0,Q1,Q2,Q3,TB, AHB.AHBSout Q0,Q1,Q2,Q3 );

reg [4:0] mREQ,mGNT,mask,mGNT_1d,mGNT_2d;
//reg [6:0] s_cnt_l0,h_cnt_l0,timer;	
//reg [6:0] s_cnt_l1,h_cnt_l1;	
//reg [6:0] s_cnt_l2,h_cnt_l2;	
//reg [6:0] s_cnt_l3,h_cnt_l3;	
//reg [6:0] s_cnt_tb,h_cnt_tb;	
//reg [6:0] max_count[0:5];
//reg [6:0] cmp[0:5];
//reg [6:0] max_count_cmp;
//reg [4:0] max_sel,inv_max_sel;
//reg       refresh;
//reg [4:0] BUS_HSEL_1d,BUS_HSEL_2d;
reg	    BUS_HWRITE ; 
reg[31:0]   BUS_HADDR  ;
reg[1:0]    BUS_HTRANS ;
reg[2:0]    BUS_HSIZE  ;
reg[2:0]    BUS_HBURST ;
reg[31:0]   BUS_HWDATA ;
reg[4:0]    BUS_HSEL;
reg         BUS_HREADY;
reg[31:0]   BUS_HRDATA;
reg[1:0]    BUS_HRESP;

//////////////////////////////////////////////////////////////
///=====================================================//////
////////////Bidding system arb////////////////////////////////
//////////////////////////////////////////////////////////////
reg [6:0] bid_vector_d[0:3];
reg [3:0] fp_mask;
reg [3:0] bid_mask;
reg [6:0] nxt_bid_vector[0:3];
reg [6:0] credit_vector_d[0:3];
reg [6:0] nxt_credit_vector[0:3];
reg [6:0] bid_l0,bid_l1,bid_l2,bid_l3;
reg [6:0] credit_l0,credit_l1,credit_l2,credit_l3;
reg [6:0] nxt_bid_l0,nxt_bid_l1,nxt_bid_l2,nxt_bid_l3;
reg [6:0] winning_bid_d,max_bid_vector;
reg [3:0] winning_lcd; 
reg [4:0] gnt_hold_timer_d,gnt_hold_timer_nxt;
reg [6:0] comb_depth_l0,comb_depth_l1,comb_depth_l2,comb_depth_l3;
reg       arb_cycle_d,nxt_arb_cycle,credit_refresh,credit_refresh_l0,credit_refresh_l1,credit_refresh_l2,credit_refresh_l3;
 
enum reg [4:0] {TB=5'b10000,LCD0=5'b01000,LCD1=5'b00100,LCD2=5'b00010,LCD3=5'b00001,NO_GRANT=5'b00000} gnt_lcd_d,nxt_gnt_lcd;
enum reg [2:0] {BID_NORMAL=3'b001,BID_CRITICAL=3'b010,BID_SUPER_CRITICAL=3'b100,NO_BID=3'b000}     bid_severity_l0,bid_severity_l1,bid_severity_l2,bid_severity_l3;

///////////////////////////////////////////////////////////////
////=====================================================//////
////////////lcd state updates//////////////////////////////////
///////////////////////////////////////////////////////////////
always@(*) begin
 {bid_l0,bid_l1,bid_l2,bid_l3} = {bid_vector_d[0],bid_vector_d[1],bid_vector_d[2],bid_vector_d[3]};
 {nxt_bid_l0,nxt_bid_l1,nxt_bid_l2,nxt_bid_l3} = {nxt_bid_vector[0],nxt_bid_vector[1],nxt_bid_vector[2],nxt_bid_vector[3]};
 {credit_l0,credit_l1,credit_l2,credit_l3} = {credit_vector_d[0],credit_vector_d[1],credit_vector_d[2],credit_vector_d[3]};
end 

always @(posedge hclk or posedge hreset) begin
   if(hreset) begin
                 mREQ     <= #0 0;
                 gnt_lcd_d        <= #0 NO_GRANT;
                 bid_vector_d[0]  <= #0 3;                 
                 bid_vector_d[1]  <= #0 2;                 
                 bid_vector_d[2]  <= #0 1;                 
                 bid_vector_d[3]  <= #0 1; 
                 credit_vector_d[0]  <= #0 30;                 
                 credit_vector_d[1]  <= #0 20;                 
                 credit_vector_d[2]  <= #0 10;                 
                 credit_vector_d[3]  <= #0 10; 
                 winning_bid_d    <= #0 0;   
                 gnt_hold_timer_d   <= #0 0;             
                 arb_cycle_d        <= #0 0;
              end 
   else       begin
                 mREQ          <= #1 {TB_M.mHBUSREQ,Q0_M.mHBUSREQ,Q1_M.mHBUSREQ,Q2_M.mHBUSREQ,Q3_M.mHBUSREQ};
                 gnt_lcd_d     <= #1 nxt_gnt_lcd;
                 bid_vector_d[0] <= #1 nxt_bid_vector[0];                 
                 bid_vector_d[1] <= #1 nxt_bid_vector[1];                 
                 bid_vector_d[2] <= #1 nxt_bid_vector[2];                 
                 bid_vector_d[3] <= #1 nxt_bid_vector[3];                 
                 credit_vector_d[0] <= #1 nxt_credit_vector[0];                 
                 credit_vector_d[1] <= #1 nxt_credit_vector[1];                 
                 credit_vector_d[2] <= #1 nxt_credit_vector[2];                 
                 credit_vector_d[3] <= #1 nxt_credit_vector[3];                 
                 winning_bid_d    <= #1 max_bid_vector;                
                 gnt_hold_timer_d   <= #1 gnt_hold_timer_nxt;
                 arb_cycle_d        <= #1 nxt_arb_cycle;
	      end
end
///////////////////////////////////////////////////////////////////////////
////////////======================================/////////////////////////
////////////calculate nxt grant state /////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
always @(*) begin
   nxt_gnt_lcd = gnt_lcd_d;
   gnt_hold_timer_nxt = nxt_arb_cycle ? 0 : gnt_hold_timer_d + 1;
        if(nxt_arb_cycle) begin
            if(mREQ[4]) begin
              nxt_gnt_lcd = TB;
            end   
            else begin
                     casez(winning_lcd)
                       4'b???1: begin
                                nxt_gnt_lcd = LCD0; 
                                end
                       4'b??10: begin 
                                nxt_gnt_lcd = LCD1; 
                                end
                       4'b?100: begin 
                                nxt_gnt_lcd = LCD2; 
                                end
                       4'b1000: begin 
                                nxt_gnt_lcd = LCD3; 
                                end
                     endcase 
		 end
        end
end 
/////////////////////////////////////////////////////////////////////////////
///////////////////////////Credit update/////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
always @(*) begin
   //credit_refresh       = (credit_vector_d[0]==0) & (credit_vector_d[1]==0) & (credit_vector_d[2]==0) & (credit_vector_d[3]==0);
   credit_refresh       = (credit_refresh_l0) & (credit_refresh_l1) & (credit_refresh_l2) & (credit_refresh_l3);
   credit_refresh_l0     = bid_mask ? 1 : (credit_vector_d[0]==0); // check credit state only in active queues
   credit_refresh_l1     = bid_mask ? 1 : (credit_vector_d[1]==0); // check credit state only in active queues
   credit_refresh_l2     = bid_mask ? 1 : (credit_vector_d[2]==0); // check credit state only in active queues
   credit_refresh_l3     = bid_mask ? 1 : (credit_vector_d[3]==0); // check credit state only in active queues

   case(1)
	(credit_refresh): begin
                               nxt_credit_vector[0] = 30;
                               nxt_credit_vector[1] = 20;
                               nxt_credit_vector[2] = 10;
                               nxt_credit_vector[3] = 10;
		             end
	(nxt_arb_cycle): begin
                               nxt_credit_vector[0] = credit_vector_d[0] ;
                               nxt_credit_vector[1] = credit_vector_d[1] ;
                               nxt_credit_vector[2] = credit_vector_d[2] ;
                               nxt_credit_vector[3] = credit_vector_d[3] ;
                              case (nxt_gnt_lcd)
                               LCD0 :nxt_credit_vector[0] = credit_vector_d[0] - nxt_bid_vector[0];
                               LCD1 :nxt_credit_vector[1] = credit_vector_d[1] - nxt_bid_vector[1];
                               LCD2 :nxt_credit_vector[2] = credit_vector_d[2] - nxt_bid_vector[2];
                               LCD3 :nxt_credit_vector[3] = credit_vector_d[3] - nxt_bid_vector[3];
                              endcase 

		             end
        default            : begin
                               nxt_credit_vector[0] = credit_vector_d[0];
                               nxt_credit_vector[1] = credit_vector_d[1];
                               nxt_credit_vector[2] = credit_vector_d[2];
                               nxt_credit_vector[3] = credit_vector_d[3];
                             end
   endcase

end
///////////////////////////////////////////////////////////////////////////// 
/////////////////////////////////////////////////////////////////////////////
///////////////////////////Drive grants to interfaces////////////////////////
/////////////////////////////////////////////////////////////////////////////
assign TB_M.mHGRANT = (gnt_lcd_d==TB);
assign Q0_M.mHGRANT = (gnt_lcd_d==LCD0);
assign Q1_M.mHGRANT = (gnt_lcd_d==LCD1);
assign Q2_M.mHGRANT = (gnt_lcd_d==LCD2);
assign Q3_M.mHGRANT = (gnt_lcd_d==LCD3);
/////////////////////////////////////////////////////////////////////////////
/////////////nxt_arb_calculaion logic////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////
always @(*) begin
          nxt_arb_cycle      = (gnt_hold_timer_d==31);
   if(hreset) begin
          nxt_arb_cycle      = 0;
   end else begin
 
   case(gnt_lcd_d)
     TB: begin
          nxt_arb_cycle      = (gnt_hold_timer_d==31);
	 end
     LCD0: begin
          nxt_arb_cycle      = (gnt_hold_timer_d == 31)|(bid_severity_l0 == BID_NORMAL);
	   end
     LCD1: begin
          nxt_arb_cycle      = (gnt_hold_timer_d == 31)|(bid_severity_l1 == BID_NORMAL);
	   end
     LCD2: begin
          nxt_arb_cycle      = (gnt_hold_timer_d == 31)|(bid_severity_l2 == BID_NORMAL);
	   end
     LCD3: begin
          nxt_arb_cycle      = (gnt_hold_timer_d == 31)|(bid_severity_l3 == BID_NORMAL);
	   end

   endcase

  end
end
///////////////////////////////////////////////////////////////////////////
////////////======================================/////////////////////////
////////////calculate nxt value to bid ////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
// normal bid  ---- bid normally , when urgency of bus is low.
// critical bid ---- bid well , when u see that u might run out of data in some time.
// super critical bid ---- u must go for a winning bid ,due to possiblity of system crash.
always @(*) begin
  comb_depth_l0  =/*tb_arb.Q0_depth;*/ top.l0.dma_logic.comb_depth;
  comb_depth_l1  =/*tb_arb.Q1_depth;*/ top.l1.dma_logic.comb_depth;
  comb_depth_l2  =/*tb_arb.Q2_depth;*/ top.l2.dma_logic.comb_depth;
  comb_depth_l3  =/*tb_arb.Q3_depth;*/ top.l3.dma_logic.comb_depth;
  fp_mask[0]     =/*tb_arb.Q0_fp; */ top.l0.time_ctrl.LCDFP;
  fp_mask[1]     =/*tb_arb.Q1_fp; */ top.l1.time_ctrl.LCDFP;
  fp_mask[2]     =/*tb_arb.Q2_fp; */ top.l2.time_ctrl.LCDFP;
  fp_mask[3]     =/*tb_arb.Q3_fp; */ top.l3.time_ctrl.LCDFP;

  //nxt_bid_vector[0] = bid_vector_d[0];
  //nxt_bid_vector[1] = bid_vector_d[1];
  //nxt_bid_vector[2] = bid_vector_d[2];
  //nxt_bid_vector[3] = bid_vector_d[3];

/////////////////////////////////////////////////////////////////////////////////
///////////// nxt bid logic//////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////
  case(1) 
   (comb_depth_l0>50):bid_severity_l0 = BID_SUPER_CRITICAL;  
   (comb_depth_l0>32):bid_severity_l0 = BID_CRITICAL;  
   default           :bid_severity_l0 = BID_NORMAL;  
  endcase

  case(bid_severity_l0) 
   BID_SUPER_CRITICAL:nxt_bid_vector[0] = ((credit_vector_d[0]>10)? 11: credit_vector_d[0]); 
   BID_CRITICAL      :nxt_bid_vector[0] = ((credit_vector_d[0]>6) ? 7: credit_vector_d[0]);   
   default           :nxt_bid_vector[0] = ((credit_vector_d[0]>2) ? 3: credit_vector_d[0]);    
  endcase

  case(1) 
   (comb_depth_l1>50):bid_severity_l1 = BID_SUPER_CRITICAL;  
   (comb_depth_l1>32):bid_severity_l1 = BID_CRITICAL;  
   default:bid_severity_l1 = BID_NORMAL;  
  endcase

  case(bid_severity_l1) 
   BID_SUPER_CRITICAL:nxt_bid_vector[1] = ((credit_vector_d[1]>9) ? 10: credit_vector_d[1]); 
   BID_CRITICAL      :nxt_bid_vector[1] = ((credit_vector_d[1]>5) ? 6:  credit_vector_d[1]);   
   default           :nxt_bid_vector[1] = ((credit_vector_d[1]>1) ? 2:  credit_vector_d[1]);    
  endcase

  case(1) 
   (comb_depth_l2>50):bid_severity_l2 = BID_SUPER_CRITICAL;  
   (comb_depth_l2>32):bid_severity_l2 = BID_CRITICAL;  
   default:bid_severity_l2 = BID_NORMAL;  
  endcase

  case(bid_severity_l2) 
   BID_SUPER_CRITICAL:nxt_bid_vector[2] = ((credit_vector_d[2]>8) ? 9:  credit_vector_d[2]); 
   BID_CRITICAL      :nxt_bid_vector[2] = ((credit_vector_d[2]>4) ? 5:  credit_vector_d[2]);   
   default           :nxt_bid_vector[2] = ((credit_vector_d[2]>0) ? 1:  credit_vector_d[2]);    
  endcase

  case(1) 
   (comb_depth_l3>50):bid_severity_l3 = BID_SUPER_CRITICAL;  
   (comb_depth_l3>32):bid_severity_l3 = BID_CRITICAL;  
   default:bid_severity_l3 = BID_NORMAL;  
  endcase

  case(bid_severity_l3) 
   BID_SUPER_CRITICAL:nxt_bid_vector[3] = ((credit_vector_d[3]>8) ? 9:  credit_vector_d[3]); 
   BID_CRITICAL      :nxt_bid_vector[3] = ((credit_vector_d[3]>4) ? 5:  credit_vector_d[3]);   
   default           :nxt_bid_vector[3] = ((credit_vector_d[3]>0) ? 1:  credit_vector_d[3]);    
  endcase
end 
///////////////////////////////////////////////////////////////////////////
////////////======================================/////////////////////////
////////////calculate highest bid /////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
//reg  [6:0] max1_bid_vector;
reg  [6:0] max_bid_vector_stage[0:4];
reg  [6:0] max2_bid_vector;
integer i;

always @(*) begin
   bid_mask = { (!mREQ[3] | fp_mask[3] | (gnt_lcd_d==LCD3)|(nxt_bid_vector[3]==0)),
                (!mREQ[2] | fp_mask[2] | (gnt_lcd_d==LCD2)|(nxt_bid_vector[2]==0)),
                (!mREQ[1] | fp_mask[1] | (gnt_lcd_d==LCD1)|(nxt_bid_vector[1]==0)),
                (!mREQ[0] | fp_mask[0] | (gnt_lcd_d==LCD0)|(nxt_bid_vector[0]==0))  };

   max_bid_vector_stage[0]   = 0;
  for(i=0;i<4;i=i+1) begin
   max_bid_vector_stage[i+1] = bid_mask[i] ? max_bid_vector_stage[i] : ( max_bid_vector_stage[i] > nxt_bid_vector[i] ? max_bid_vector_stage[i] : nxt_bid_vector[i]);
  end 
  //max1_bid_vector = (bid_vector_d[0]>bid_vector_d[1])      ? bid_vector_d[0]   : bid_vector_d[1];
  //max2_bid_vector = (bid_vector_d[2]>bid_vector_d[3])      ? bid_vector_d[2]   : bid_vector_d[3];
  //max_bid_vector  = (max1_bid_vector> max2_bid_vector) ? max1_bid_vector : max2_bid_vector;
  max_bid_vector  = max_bid_vector_stage[4]; 
  
  winning_lcd[0]  = (nxt_bid_vector[0]==max_bid_vector) & !bid_mask[0];
  winning_lcd[1]  = (nxt_bid_vector[1]==max_bid_vector) & !bid_mask[1];
  winning_lcd[2]  = (nxt_bid_vector[2]==max_bid_vector) & !bid_mask[2];
  winning_lcd[3]  = (nxt_bid_vector[3]==max_bid_vector) & !bid_mask[3];
  
end 
///////////////////////////////////////////////////////////////////////////


/*
assign TB_M.mHGRANT = mGNT[4];
assign Q0_M.mHGRANT = mGNT[3];
assign Q1_M.mHGRANT = mGNT[2];
assign Q2_M.mHGRANT = mGNT[1];
assign Q3_M.mHGRANT = mGNT[0];
always @(posedge hclk or posedge hreset) begin 
   if(hreset) begin 
      mREQ     <= #0 0;
      mGNT_1d  <= #0 0;
      mGNT_2d  <= #0 0;
      timer    <= #0 100;
      mask     <= #0 5'b00000;
      BUS_HSEL_1d <= #0 0;
      BUS_HSEL_2d <= #0 0;
   end else begin 
      mREQ     <= #1 {TB_M.mHBUSREQ,Q0_M.mHBUSREQ,Q1_M.mHBUSREQ,Q2_M.mHBUSREQ,Q3_M.mHBUSREQ};
      //timer <= #1 refresh ? 100 : ((mGNT == 5'h0) ? timer : timer - 1);
      timer    <= #1 refresh ? 100 : (timer - 1);
      mask     <= #1 {Q3_M.mHBUSREQ,Q2_M.mHBUSREQ,Q1_M.mHBUSREQ,Q0_M.mHBUSREQ,TB_M.mHBUSREQ};
      mGNT_1d  <= #1 mGNT;
      mGNT_2d  <= #1 mGNT_1d;
      BUS_HSEL_1d <= #1 BUS_HSEL;
      BUS_HSEL_2d <= #1 BUS_HSEL_1d; 
            end
end 


always @(posedge hclk or posedge hreset) begin 
  if(hreset) begin
 s_cnt_l0 <= #0 30;	
 s_cnt_l1 <= #0 20;	
 s_cnt_l2 <= #0 10;	
 s_cnt_l3 <= #0 10;	
 s_cnt_tb <= #0 30;	
 h_cnt_l0 <= #0 0;	
 h_cnt_l1 <= #0 0;	
 h_cnt_l2 <= #0 0;	
 h_cnt_l3 <= #0 0;	
 h_cnt_tb <= #0 0;	
	     end else begin
                        if (!refresh) begin
			 case(mGNT)
				5'b10000: begin 
                                              	s_cnt_tb <= #1 s_cnt_tb -1; 
                                          end
				5'b01000: begin 
  					      	s_cnt_l0 <= #1 s_cnt_l0 -1; 
					  end
				5'b00100: begin 
						s_cnt_l1 <= #1 s_cnt_l1 -1; 
					  end
				5'b00010: begin 
						s_cnt_l2 <= #1 s_cnt_l2 -1;
					  end
				5'b00001: begin 
						s_cnt_l3 <= #1 s_cnt_l3 -1;
					  end 
                         endcase
                        end else begin
                                    s_cnt_l0 <= #1 30;	
                                    s_cnt_l1 <= #1 20;	
                                    s_cnt_l2 <= #1 10;	
                                    s_cnt_l3 <= #1 10;	
                                    s_cnt_tb <= #1 30;	
				 end
                      end
end 

integer i;
// update mask
always @(*) begin 
  max_count[0] = 0;
  //max_sel      = 0;
  for(i=0;i<5;i=i+1) begin 
     //max_sel [i]    = (cmp[i]>max_count[i]) ? (1<<i): 
   if(mREQ[i]) begin
     case(i)
        4: cmp[i] = s_cnt_tb;
        3: cmp[i] = s_cnt_l0;
        2: cmp[i] = s_cnt_l1;
        1: cmp[i] = s_cnt_l2;
        0: cmp[i] = s_cnt_l3;
           
     endcase
              max_count[i+1] = (cmp[i]>max_count[i]) ? cmp[i] : max_count[i];
              //max_sel[i]     = (cmp[i]>max_count[i]) ? 1 : 0;
   end else begin
              max_count[i+1] = max_count[i];
	    end
     //$display("time:%t cmp[%0d]=%0d max_count[%0d]=%0d",$time,i,cmp[i],i+1,max_count[i+1]);
  end
   
     max_count_cmp = max_count[5]; 
     //$display("time:%t max_count_cmp=%0d",$time,max_count_cmp);
end
*/
/*always @(*) begin
   refresh = hreset ? 5'b0 : (timer==1);
   //max_sel = hreset ? 5'b0 : {(max_count_cmp==s_cnt_tb),(max_count_cmp==s_cnt_l0),(max_count_cmp==s_cnt_l1),(max_count_cmp==s_cnt_l2),(max_count_cmp==s_cnt_l3)};
   //max_sel = hreset|(max_count_cmp==0) ? 5'b0 : ({(max_count_cmp==s_cnt_l3),(max_count_cmp==s_cnt_l2),(max_count_cmp==s_cnt_l1),(max_count_cmp==s_cnt_l0),(max_count_cmp==s_cnt_tb)} & mask) ;
     max_sel = hreset ? 0 : (mREQ[4] ? 5'b00001 : 0);
   inv_max_sel = {max_sel[0],max_sel[1],max_sel[2],max_sel[3],max_sel[4]};
end

always @(*) begin
   mGNT = 5'b0;
   casez(max_sel) 
   //casez(5'b00001) 

    5'b1????: mGNT = 5'b00001;
    5'b01???: mGNT = 5'b00010;
    5'b001??: mGNT = 5'b00100;
    5'b0001?: mGNT = 5'b01000;
    5'b00001: mGNT = 5'b10000;

   endcase

end*/

//property gnt_vld @(posedge hclk) 
     
//endproperty
/////////////////////////////////////////////////////////////////////
//===============================================================//// 
// singal on common AHB bus from granted master to slave

always @(*) begin
                {TB_S.HSEL,Q0_S.HSEL,Q1_S.HSEL,Q2_S.HSEL,Q3_S.HSEL} = BUS_HSEL;

		Q0_S.HWRITE = BUS_HWRITE; 
                Q0_S.HADDR  = BUS_HADDR;
                Q0_S.HTRANS = BUS_HTRANS;
                Q0_S.HSIZE  = BUS_HSIZE;
                Q0_S.HBURST = BUS_HBURST;
                Q0_S.HWDATA = BUS_HWDATA;
		
                Q1_S.HWRITE = BUS_HWRITE; 
                Q1_S.HADDR  = BUS_HADDR;
                Q1_S.HTRANS = BUS_HTRANS;
                Q1_S.HSIZE  = BUS_HSIZE;
                Q1_S.HBURST = BUS_HBURST;
                Q1_S.HWDATA = BUS_HWDATA;
                
                Q2_S.HWRITE = BUS_HWRITE; 
                Q2_S.HADDR  = BUS_HADDR;
                Q2_S.HTRANS = BUS_HTRANS;
                Q2_S.HSIZE  = BUS_HSIZE;
                Q2_S.HBURST = BUS_HBURST;
                Q2_S.HWDATA = BUS_HWDATA;

                Q3_S.HWRITE = BUS_HWRITE; 
                Q3_S.HADDR  = BUS_HADDR;
                Q3_S.HTRANS = BUS_HTRANS;
                Q3_S.HSIZE  = BUS_HSIZE;
                Q3_S.HBURST = BUS_HBURST;
                Q3_S.HWDATA = BUS_HWDATA;

                TB_S.HWRITE = BUS_HWRITE; 
                TB_S.HADDR  = BUS_HADDR;
                TB_S.HTRANS = BUS_HTRANS;
                TB_S.HSIZE  = BUS_HSIZE;
                TB_S.HBURST = BUS_HBURST;
                TB_S.HWDATA = BUS_HWDATA;

                Q0_M.mHRESP  =BUS_HRESP;
                Q0_M.mHRDATA =BUS_HRDATA;
                Q0_M.mHREADY =BUS_HREADY;

                Q1_M.mHRESP  =BUS_HRESP;
                Q1_M.mHRDATA =BUS_HRDATA;
                Q1_M.mHREADY =BUS_HREADY;

                Q2_M.mHRESP  =BUS_HRESP;
                Q2_M.mHRDATA =BUS_HRDATA;
                Q2_M.mHREADY =BUS_HREADY;

                Q3_M.mHRESP  =BUS_HRESP;
                Q3_M.mHRDATA =BUS_HRDATA;
                Q3_M.mHREADY =BUS_HREADY;

                TB_M.mHRESP  =BUS_HRESP;
                TB_M.mHRDATA =BUS_HRDATA;
                TB_M.mHREADY =BUS_HREADY;

end

// ctrl and addr mux from master to slave, one cycle after providing the grant to master
// access to data bus will be one clock cycle delayed
// address and control mux
// also HSEL signals are distributed 
always @(*) begin
		BUS_HWRITE = 0; 
                BUS_HADDR  = 0;
                BUS_HTRANS = 0; 
                BUS_HSIZE  = 0; 
                BUS_HBURST = 0; 
                BUS_HSEL   = 5'h0;
  //case(mGNT_1d)
  //case(mGNT)
  case(gnt_lcd_d)
    5'b00001: begin
		BUS_HWRITE = Q3_M.mHWRITE; 
                BUS_HADDR  = Q3_M.mHADDR;
                BUS_HTRANS = Q3_M.mHTRANS;
                BUS_HSIZE  = Q3_M.mHSIZE;
                BUS_HBURST = Q3_M.mHBURST;
                BUS_HSEL   = 5'h10;
		end
    5'b00010: begin
		BUS_HWRITE = Q2_M.mHWRITE; 
                BUS_HADDR  = Q2_M.mHADDR;
                BUS_HTRANS = Q2_M.mHTRANS;
                BUS_HSIZE  = Q2_M.mHSIZE;
                BUS_HBURST = Q2_M.mHBURST;
                BUS_HSEL   = 5'h10;
		end
    5'b00100: begin
		BUS_HWRITE = Q1_M.mHWRITE; 
                BUS_HADDR  = Q1_M.mHADDR;
                BUS_HTRANS = Q1_M.mHTRANS;
                BUS_HSIZE  = Q1_M.mHSIZE;
                BUS_HBURST = Q1_M.mHBURST;
                BUS_HSEL   = 5'h10;
		end
    5'b01000: begin
		BUS_HWRITE = Q0_M.mHWRITE; 
                BUS_HADDR  = Q0_M.mHADDR;
                BUS_HTRANS = Q0_M.mHTRANS;
                BUS_HSIZE  = Q0_M.mHSIZE;
                BUS_HBURST = Q0_M.mHBURST;
                BUS_HSEL   = 5'h10;
		
		end
    5'b10000: begin
		BUS_HWRITE = TB_M.mHWRITE; 
                BUS_HADDR  = TB_M.mHADDR;
                BUS_HTRANS = TB_M.mHTRANS;
                BUS_HSIZE  = TB_M.mHSIZE;
                BUS_HBURST = TB_M.mHBURST;
                	
		// when tb is master select appro slave select	
                case(BUS_HADDR[31:24])
                  8'hE0,8'hFF:   BUS_HSEL = 5'h08;
                  8'hE1,8'hFE:   BUS_HSEL = 5'h04; 
                  8'hE2,8'hFD:   BUS_HSEL = 5'h02;  
                  8'hE3,8'hFC:   BUS_HSEL = 5'h01;   
                  default    :   BUS_HSEL = 5'h00;   
                endcase 

		end
      
  endcase
end

// access to data bus two clock cycle delayed than that of grant
// Write data mux
always @(*) begin
 BUS_HWDATA = 0;
// case(mGNT_2d) 
// case(mGNT) 
  case(gnt_lcd_d)
   5'b00001: begin
                BUS_HWDATA = Q3_M.mHWDATA;
	       end 
   5'b00010: begin 
                BUS_HWDATA = Q2_M.mHWDATA;
               end 
   5'b00100: begin
                BUS_HWDATA = Q1_M.mHWDATA;
               end
   5'b01000: begin
                BUS_HWDATA = Q0_M.mHWDATA;
               end
   5'b10000: begin
                BUS_HWDATA = TB_M.mHWDATA;
               end
 endcase
end

// read data and hresp mux coming from slave and going to master
always @(*) begin 
          BUS_HREADY= 0;
          BUS_HRDATA= 0;
          BUS_HRESP = 0;
//  case(BUS_HSEL_2d) 
  case(BUS_HSEL) 
    5'b00001: begin
                  BUS_HREADY= Q3_S.HREADY;
                  BUS_HRDATA= Q3_S.HRDATA;
                  BUS_HRESP = Q3_S.HRESP;
		end
    5'b00010: begin
                  BUS_HREADY= Q2_S.HREADY;
                  BUS_HRDATA= Q2_S.HRDATA;
                  BUS_HRESP = Q2_S.HRESP;
		end
    5'b00100: begin
                  BUS_HREADY= Q1_S.HREADY;
                  BUS_HRDATA= Q1_S.HRDATA;
                  BUS_HRESP = Q1_S.HRESP;
		end
    5'b01000: begin
                  BUS_HREADY= Q0_S.HREADY;
                  BUS_HRDATA= Q0_S.HRDATA;
                  BUS_HRESP = Q0_S.HRESP;
		end
    5'b10000: begin
                  BUS_HREADY= TB_S.HREADY;
                  BUS_HRDATA= TB_S.HRDATA;
                  BUS_HRESP = TB_S.HRESP;
		end
  endcase  
end
//////////////////////////////////////////////////////////////////////////////////////
///==============================================================================/////
//////////////////////////////////////////////////////////////////////////////////////
endmodule
