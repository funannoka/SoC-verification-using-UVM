`timescale 1ns/10ps

// `include "lcd.sv"

module arbitrator(input          HCLK,
                input            HRESET,
		AHBIF.AHBMin     master0, // master 0
		AHBIF.AHBMin     master1, // master 1
		AHBIF.AHBMin     master2, // master 2
		AHBIF.AHBMin     master3, // master 3
		AHBIF.AHBMin     tbmaster,
		AHBIF.AHBSout    slave0,
		AHBIF.AHBSout    slave1,
		AHBIF.AHBSout    slave2,
		AHBIF.AHBSout    slave3,
		AHBIF.AHBSout    tbslave
	);

	shortint bwcount; //for counting 100 cycles
	parameter TotBW = 100;      //total Bandwidth
	typedef struct {shortint unsigned m0;
                        shortint unsigned m1;
                        shortint unsigned m2;
                        shortint unsigned m3;
	}Bandwidth;
	
	Bandwidth      initBW = '{30,20,10,10};
	Bandwidth      availBW = '{30,20,10,10};
	//==============================
	//mux output to masters
	logic [31:0] mHRDATA_mxout;
// 	logic [31:0] ADDR_mxout;
	logic        mHREADY_mxout;
	logic [1:0]  mHRESP_mxout;
	//==============================
	//mux output to slaves
	logic [31:0] HADDR_mxout;  //
	logic        HWRITE_mxout;   //
	logic [1:0]  HTRANS_mxout;     // for Address & Control Mux
	logic [2:0]  HSIZE_mxout;    //
	logic [2:0]  HBURST_mxout; //
	logic [31:0] HWDATA_mxout; //for Write Data Mux
	logic [4:0]  rdatamux_sel,rdatamux_sel1; //select line for Read_Data Mux
	
	typedef enum bit {IDLE = 1'b0,ARBITRATION = 1'b1} StateMachine; //current state of the arbiter state machine
	StateMachine   state1, nextstate;
	typedef enum bit [2:0] {MASTER0,MASTER1,MASTER2,MASTER3,TBMASTER}SELECTEDMASTER; // master select
	SELECTEDMASTER   HMASTER, HMASTER1, HMASTER2, HMASTER3;
// 	bit nextstate;
	bit bus_granted;
// 	logic burstcnt;
	logic [31:0] slave_addr;
	//=======================================================================================
	assign bus_granted = (master0.mHGRANT) | (master1.mHGRANT) | (master2.mHGRANT) | (master3.mHGRANT) | (tbmaster.mHGRANT);

        assign HMASTER = tbmaster.mHGRANT ? TBMASTER :
                         master0.mHGRANT  ? MASTER0  :
                         master1.mHGRANT  ? MASTER1  :
                         master2.mHGRANT  ? MASTER2  :
                         master3.mHGRANT  ? MASTER3  : SELECTEDMASTER'(3'bz);
        
	always @(*)
	begin
			if(state1==IDLE) begin
                                tbmaster.mHGRANT = 1'b1;
                                master0.mHGRANT  = 1'b0;
                                master1.mHGRANT  = 1'b0;
                                master2.mHGRANT  = 1'b0;
                                master3.mHGRANT  = 1'b0;
                        end
                        
			else
			begin
				if(tbmaster.mHBUSREQ) begin
					tbmaster.mHGRANT= 1'b1;
					master0.mHGRANT = 1'b0;
					master1.mHGRANT = 1'b0;
					master2.mHGRANT = 1'b0;
					master3.mHGRANT = 1'b0;
				end
				else if(master0.mHBUSREQ && availBW.m0>0) begin
					master0.mHGRANT = 1'b1;
					master1.mHGRANT = 1'b0;
					master2.mHGRANT = 1'b0;
					master3.mHGRANT = 1'b0;
					tbmaster.mHGRANT= 1'b0;
				end
				else if(master1.mHBUSREQ && availBW.m1>0) begin
					master1.mHGRANT = 1'b1;
					master0.mHGRANT = 1'b0;
					master2.mHGRANT = 1'b0;
					master3.mHGRANT = 1'b0;
					tbmaster.mHGRANT= 1'b0;
				end
				else if(master2.mHBUSREQ && availBW.m2>0) begin
					master2.mHGRANT = 1'b1;
					master0.mHGRANT = 1'b0;
					master1.mHGRANT = 1'b0;
					master3.mHGRANT = 1'b0;
					tbmaster.mHGRANT= 1'b0;
				end
				else if(master3.mHBUSREQ && availBW.m3>0) begin
					master3.mHGRANT = 1'b1;
					master0.mHGRANT = 1'b0;
					master1.mHGRANT = 1'b0;
					master2.mHGRANT = 1'b0;
					tbmaster.mHGRANT= 1'b0;
				end
				else begin

					if(master0.mHGRANT==1'b1 && availBW.m0==0)begin
						tbmaster.mHGRANT = 1'b1;
						master0.mHGRANT  = 1'b0;
					end 
					else if(master1.mHGRANT==1'b1 && availBW.m1==0)begin
						tbmaster.mHGRANT = 1'b1;
						master1.mHGRANT  = 1'b0;
					end
					else if(master2.mHGRANT==1'b1 && availBW.m2==0)begin
						tbmaster.mHGRANT = 1'b1;
						master2.mHGRANT  = 1'b0;
					end 
					else if(master3.mHGRANT==1'b1 && availBW.m3==0)begin
						tbmaster.mHGRANT = 1'b1;
						master3.mHGRANT  = 1'b0;
					end 
					else begin
						master3.mHGRANT = master3.mHGRANT;
					end
				end
			end //arbitration state if block
	end
	//=================================================
	always @(posedge (HCLK) or posedge (HRESET))
	begin // to maintain the bandwidth counters
		if (HRESET)
		begin
			bwcount    <= #1 0;
			availBW.m0 <= #1 initBW.m0;
			availBW.m1 <= #1 initBW.m1;
			availBW.m2 <= #1 initBW.m2;
			availBW.m3 <= #1 initBW.m3;
		end
		else
		begin
			if(bwcount==100)begin
				bwcount    <= #1 0;
				availBW.m0 <= #1 initBW.m0;
                                availBW.m1 <= #1 initBW.m1;
                                availBW.m2 <= #1 initBW.m2;
                                availBW.m3 <= #1 initBW.m3;
			end
			else bwcount <= #1 bwcount + 1;
			
			if(master0.mHGRANT) availBW.m0 <= #1 availBW.m0 - 1;
                        if(master1.mHGRANT) availBW.m1 <= #1 availBW.m1 - 1;
                        if(master2.mHGRANT) availBW.m2 <= #1 availBW.m2 - 1;
                        if(master3.mHGRANT) availBW.m3 <= #1 availBW.m3 - 1;
                end
        end
	//=================================================
	// State Machine for Arbiter
	//=================================================

	always_comb
	begin
		case(state1) 
                    IDLE: if((master0.mHBUSREQ) || (master1.mHBUSREQ) || (master2.mHBUSREQ) || (master3.mHBUSREQ) || (tbmaster.mHBUSREQ)) 
                            nextstate = ARBITRATION;
                    ///////////////////////////////////////////////////////////////
                    
                    ARBITRATION:begin
                                if((master0.mHBUSREQ) || (master1.mHBUSREQ) || (master2.mHBUSREQ) || (master3.mHBUSREQ) || (tbmaster.mHBUSREQ))
                                        nextstate = ARBITRATION;
                                else   nextstate = IDLE;
                                end
		endcase
	end

        always @(posedge (HCLK) or posedge (HRESET))
        begin
                if (HRESET) state1 <= #1 IDLE;
                else        state1 <= #1 nextstate;

        end
        //==========================================================

        ////////////////////////assuming the master has been granted
        always @(posedge (HCLK) or posedge (HRESET))
        begin
                if (HRESET) begin
                    slave_addr <= #1 '0;
                    HMASTER1   <= #1 TBMASTER;
                    HMASTER2   <= #1 HMASTER1;
                    HMASTER3   <= #1 HMASTER2;
                end
                else
                HMASTER1 <= #1 HMASTER;
                HMASTER2 <= #1 HMASTER1;
                HMASTER3 <= #1 HMASTER2;
                case(HMASTER)
                        MASTER0 : slave_addr <= #1 master0.mHADDR;
                        MASTER1 : slave_addr <= #1 master1.mHADDR;
                        MASTER2 : slave_addr <= #1 master2.mHADDR;
                        MASTER3 : slave_addr <= #1 master3.mHADDR;
                        TBMASTER: slave_addr <= #1 tbmaster.mHADDR;
                endcase
        end
        /////////////////////////////////////////////////////////////////////

        //===================================================================
        //                      Address Space for slaves
        //                 Hex                           Decimal
        //===================================================================
        //0 : 32'hE01F_C1B8 , 32'hFFE1_0000  ->  3760177592 , 4292935680
        //1 : 32'hE11F_C1B8 , 32'hFEE1_0000  ->  3776954808 , 4276158464
        //2 : 32'hE21F_C1B8 , 32'hFDE1_0000  ->  3793732024 , 4259381248
        //3 : 32'hE31F_C1B8 , 32'hFCE1_0000  ->  3810509240 , 4242604032
        //===================================================================
        //============================================================================================
        //                          Decoder for selecting HSEL
        //============================================================================================
        assign slave0.HSEL = ((slave_addr[31:16]==16'hE01F) || (slave_addr[31:16]==16'hFFE1)) ? 1 : 0;
        assign slave1.HSEL = ((slave_addr[31:16]==16'hE11F) || (slave_addr[31:16]==16'hFEE1)) ? 1 : 0;
        assign slave2.HSEL = ((slave_addr[31:16]==16'hE21F) || (slave_addr[31:16]==16'hFDE1)) ? 1 : 0;
        assign slave3.HSEL = ((slave_addr[31:16]==16'hE31F) || (slave_addr[31:16]==16'hFCE1)) ? 1 : 0;
        assign tbslave.HSEL= (!slave0.HSEL)&&(!slave1.HSEL)&&(!slave2.HSEL)&&(!slave3.HSEL)   ? 1 : 0;
        //============================================================================================
        //==========================================================================
        always_comb
        begin
                case(HMASTER1)
                        MASTER0 :begin
                                HADDR_mxout  = master0.mHADDR;
                                HWRITE_mxout = master0.mHWRITE;
                                HTRANS_mxout = master0.mHTRANS;
                                HSIZE_mxout  = master0.mHSIZE;
                                HBURST_mxout = master0.mHBURST;
                        end
                        MASTER1 :begin
                                HADDR_mxout  = master1.mHADDR;
                                HWRITE_mxout = master1.mHWRITE;
                                HTRANS_mxout = master1.mHTRANS;
                                HSIZE_mxout  = master1.mHSIZE;
                                HBURST_mxout = master1.mHBURST;
                        end
                        MASTER2 :begin
                                HADDR_mxout  = master2.mHADDR;
                                HWRITE_mxout = master2.mHWRITE;
                                HTRANS_mxout = master2.mHTRANS;
                                HSIZE_mxout  = master2.mHSIZE;
                                HBURST_mxout = master2.mHBURST;
                        end
                        MASTER3 :begin
                                HADDR_mxout  = master3.mHADDR;
                                HWRITE_mxout = master3.mHWRITE;
                                HTRANS_mxout = master3.mHTRANS;
                                HSIZE_mxout  = master3.mHSIZE;
                                HBURST_mxout = master3.mHBURST;
                        end
                        TBMASTER:begin
                                HADDR_mxout  = tbmaster.mHADDR;
                                HWRITE_mxout = tbmaster.mHWRITE;
                                HTRANS_mxout = tbmaster.mHTRANS;
                                HSIZE_mxout  = tbmaster.mHSIZE;
                                HBURST_mxout = tbmaster.mHBURST;
                        end
                endcase
                case(HMASTER2) // WRITE DATA MUX
                        MASTER0 :HWDATA_mxout = master0.mHWDATA;
                        MASTER1 :HWDATA_mxout = master1.mHWDATA;
                        MASTER2 :HWDATA_mxout = master2.mHWDATA;
                        MASTER3 :HWDATA_mxout = master3.mHWDATA;
                        TBMASTER:HWDATA_mxout = tbmaster.mHWDATA;
                endcase
        end // Address,Control & Write_Data Mux
        // connecting mux outputs to slaves
        assign slave0.HADDR  = HADDR_mxout;
        assign slave1.HADDR  = HADDR_mxout;
        assign slave2.HADDR  = HADDR_mxout;
        assign slave3.HADDR  = HADDR_mxout;
        assign tbslave.HADDR = HADDR_mxout;

        assign slave0.HWRITE  = HWRITE_mxout;
        assign slave1.HWRITE  = HWRITE_mxout;
        assign slave2.HWRITE  = HWRITE_mxout;
        assign slave3.HWRITE  = HWRITE_mxout;
        assign tbslave.HWRITE = HWRITE_mxout;

        assign slave0.HTRANS  = HTRANS_mxout;
        assign slave1.HTRANS  = HTRANS_mxout;
        assign slave2.HTRANS  = HTRANS_mxout;
        assign slave3.HTRANS  = HTRANS_mxout;
        assign tbslave.HTRANS = HTRANS_mxout;

        assign slave0.HSIZE  = HSIZE_mxout;
        assign slave1.HSIZE  = HSIZE_mxout;
        assign slave2.HSIZE  = HSIZE_mxout;
        assign slave3.HSIZE  = HSIZE_mxout;
        assign tbslave.HSIZE = HSIZE_mxout;

        assign slave0.HBURST  = HBURST_mxout;
        assign slave1.HBURST  = HBURST_mxout;
        assign slave2.HBURST  = HBURST_mxout;
        assign slave3.HBURST  = HBURST_mxout;
        assign tbslave.HBURST = HBURST_mxout;

        assign slave0.HWDATA  = HWDATA_mxout;
        assign slave1.HWDATA  = HWDATA_mxout;
        assign slave2.HWDATA  = HWDATA_mxout;
        assign slave3.HWDATA  = HWDATA_mxout;
        assign tbslave.HWDATA = HWDATA_mxout;
        //Address,Control & Write_Data Mux finished
        //==========================================================================


        //==========================================================================
        // Read_Data Mux (mHRDATA,mHREADY,mHRESP)
        //==========================================================================
        assign rdatamux_sel = {tbslave.HSEL,slave3.HSEL,slave2.HSEL,slave1.HSEL,slave0.HSEL};
        
//         assign rdatamux_sel = {mxseltb,mxsel3,mxsel2,mxsel1,mxsel0};
        always @(posedge (HCLK) or posedge (HRESET))
            if(HRESET) rdatamux_sel1 <= #1 1'b0;
            else       rdatamux_sel1 <= #1 rdatamux_sel;
            
        always_comb
        begin
                if(HMASTER3)
                case(rdatamux_sel)
                        5'b00001 :begin
                                mHRDATA_mxout = slave0.HRDATA;
                                mHREADY_mxout = slave0.HREADY;
                                mHRESP_mxout  = slave0.HRESP;
                        end
                        5'b00010 :begin
                                mHRDATA_mxout = slave1.HRDATA;
                                mHREADY_mxout = slave1.HREADY;
                                mHRESP_mxout  = slave1.HRESP;
                        end
                        5'b00100 :begin
                                mHRDATA_mxout = slave2.HRDATA;
                                mHREADY_mxout = slave2.HREADY;
                                mHRESP_mxout  = slave2.HRESP;
                        end
                        5'b01000 :begin
                                mHRDATA_mxout = slave3.HRDATA;
                                mHREADY_mxout = slave3.HREADY;
                                mHRESP_mxout  = slave3.HRESP;
                        end
                        5'b10000 :begin
                                mHRDATA_mxout = tbslave.HRDATA;
                                mHREADY_mxout = tbslave.HREADY;
                                mHRESP_mxout  = tbslave.HRESP;
                        end
                        5'b00000 :begin
                                $display("==================\nNo slave selected\n==================");
                        end
                endcase
        end // Read_Data Mux
        // connecting mux outputs to masters
        assign master0.mHRDATA  = mHRDATA_mxout;
        assign master1.mHRDATA  = mHRDATA_mxout;
        assign master2.mHRDATA  = mHRDATA_mxout;
        assign master3.mHRDATA  = mHRDATA_mxout;
        assign tbmaster.mHRDATA = mHRDATA_mxout;

        assign master0.mHREADY  = mHREADY_mxout;
        assign master1.mHREADY  = mHREADY_mxout;
        assign master2.mHREADY  = mHREADY_mxout;
        assign master3.mHREADY  = mHREADY_mxout;
        assign tbmaster.mHREADY = mHREADY_mxout;

        assign master0.mHRESP  = mHRESP_mxout;
        assign master1.mHRESP  = mHRESP_mxout;
        assign master2.mHRESP  = mHRESP_mxout;
        assign master3.mHRESP  = mHRESP_mxout;
        assign tbmaster.mHRESP = mHRESP_mxout;
        // Read_Data Mux over
        //==========================================================================


endmodule
