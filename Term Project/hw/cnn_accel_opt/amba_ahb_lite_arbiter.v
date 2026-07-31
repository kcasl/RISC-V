//Burst interrupts are not allowed by this arbiter.
//It takes master one clock cycle delay to be changed.
//Only for the same master, back-to-back transfers are allowed.
//Lock and unspecified INCR transaction must be followed by IDLE cycle in order to avoid exclusive bus accesses by one master.

`include "amba_ahb_h.v"
`include "amba_ahb_arbiter_h.v"

module amba_ahb_lite_arbiter #(
//ahb_lite
parameter N_MASTER = 2,
parameter W_MASTER = 1,
parameter NUM_DEF_MASTER = 0,
parameter PRIORITY_SCHEME = `PRISC_ROUND_ROBIN,
parameter ROUND_ROBIN_SCHEME = `ROUND_ROBIN_SELECTED
)
(
	HCLK, HRESETn,
	ma_bus_req, ma_HTRANS, ma_HBURST, ma_HMASTLOCK,
	HREADY,
	out_ma_active,
	out_HMASTER,
	//for debugging
	q_state);	
	//clock
	input HCLK, HRESETn;
	//input signals from input stages
	input [N_MASTER-1:0] ma_bus_req;
	input [N_MASTER*`W_TRANS-1:0] ma_HTRANS;
	input [N_MASTER*`W_BURST-1:0] ma_HBURST;
	input [N_MASTER-1:0] ma_HMASTLOCK;
	//input signals from the output stage
	input HREADY;
	//output signal to the masters
	output reg [N_MASTER-1:0] out_ma_active;
	//output signals to the output stage
	output reg [W_MASTER-1:0] out_HMASTER;
	
	//for debugging
	//Main state machine
	localparam N_STATE = 4;
	localparam W_STATE = GetBitWidth(N_STATE);
		localparam ST_INIT = 0;
		localparam ST_FIXED_LENGTH_TRANSFER = 1;
		localparam ST_UNKNOWN_LENGTH_TRANSFER = 2;
	localparam W_CNT_BURST = `W_BURST + 1;
	output [W_STATE-1:0] q_state;
	
//---------------------------------------------------------------------------------------------
// Constant functions
//---------------------------------------------------------------------------------------------
	//return ceil(log2(num));
	function integer GetBitWidth(input integer num);
		integer nc_num;
	begin
		nc_num = num;
		if(nc_num > 0)
		begin
			GetBitWidth = 0;
			for(nc_num = nc_num - 1; nc_num>0; GetBitWidth=GetBitWidth+1)
				nc_num = nc_num >> 1;
		end
		else
			GetBitWidth = 1;
	end
	endfunction
//---------------------------------------------------------------------------------------------
	
`ifdef H264E_WA_USE_CUSTOMIZED_HBURST
	function [W_CNT_BURST-1:0] GetBurstLength;
		input [`W_BURST-1:0] burst;
	begin
		case (burst)
			`BURST_INCR2:	//Length = 2
				GetBurstLength = 1;
			`BURST_INCR3:	//Length = 3
				GetBurstLength = 2;
			`BURST_INCR4:	//Length = 4
				GetBurstLength = 3;
			`BURST_INCR8:	//Length = 8
				GetBurstLength = 7;
			`BURST_INCR9:	//Length = 9
				GetBurstLength = 8;
			`BURST_INCR16:	//Length = 16
				GetBurstLength = 15;
			`BURST_WRAP4:	//Length = 4
				GetBurstLength = 3;
			`BURST_WRAP8:	//Length = 8
				GetBurstLength = 7;
			`BURST_WRAP16:	//Length = 16
				GetBurstLength = 15;
			default:    // SINGLE, INCR should not enter here.
				GetBurstLength = 0;
		endcase
	end
	endfunction
`else //H264E_WA_USE_CUSTOMIZED_HBURST
	function [W_CNT_BURST-1:0] GetBurstLength;
		input [`W_BURST-1:0] burst;
	begin
		//GetBurstLength = (1 << (burst[`W_BURST-1:1]+1))-1;
		case(burst[`W_BURST-1:1])
			1: //4
				GetBurstLength = 3;
			2: //8
				GetBurstLength = 7;
			3: //16
				GetBurstLength = 15;
			default: //0
				GetBurstLength = 0;
		endcase
	end
	endfunction
`endif //H264E_WA_USE_CUSTOMIZED_HBURST
	
	//Main state machine
	reg [W_STATE-1:0] q_state, d_state;
	reg [W_CNT_BURST-1:0] q_cnt_burst, d_cnt_burst;
	reg q_HMASTLOCK, d_HMASTLOCK;
	
	//Master changer
	reg en_change_master;
	
	wire [`W_BURST-1:0] cur_ma_HBURST;
		assign cur_ma_HBURST = ma_HBURST[out_HMASTER*`W_BURST+:`W_BURST];
	wire [`W_TRANS-1:0] cur_ma_HTRANS;
		assign cur_ma_HTRANS = ma_HTRANS[out_HMASTER*`W_TRANS+:`W_TRANS];
	
	always @*
	begin
		en_change_master = 1'b0;
		d_state = q_state;
		d_cnt_burst = q_cnt_burst;
		d_HMASTLOCK = q_HMASTLOCK;
		case(q_state)
			ST_UNKNOWN_LENGTH_TRANSFER:
			begin
				if(cur_ma_HTRANS == `TRANS_IDLE)	//the end of this transaction
				begin
					d_state = ST_INIT;
					//if(|ma_bus_req)
					if(|(ma_bus_req & ~(1 << out_HMASTER)))
						en_change_master = ~q_HMASTLOCK;
				end
			end
			ST_FIXED_LENGTH_TRANSFER:
			begin
				if(cur_ma_HTRANS != `TRANS_BUSY)
				begin
					if((cur_ma_HTRANS == `TRANS_IDLE)					//burst interrupt
					|| (q_cnt_burst == GetBurstLength(cur_ma_HBURST)))	//the end of this transaction
					begin
						d_state = ST_INIT;
						d_cnt_burst = 0;
						if(|(ma_bus_req & ~(1 << out_HMASTER)))
							en_change_master = ~q_HMASTLOCK;
					end
					else
						d_cnt_burst = q_cnt_burst +1;
				end
			end
			default:	//ST_INIT:
			begin
				if(ma_bus_req[out_HMASTER])	//the start of a transaction
				begin
					d_HMASTLOCK = ma_HMASTLOCK[out_HMASTER];
					if(cur_ma_HBURST == `BURST_SINGLE)
					begin
						if(|(ma_bus_req & ~(1 << out_HMASTER)))
							en_change_master = ~ma_HMASTLOCK[out_HMASTER];
					end
					else if(cur_ma_HBURST == `BURST_INCR)
						d_state = ST_UNKNOWN_LENGTH_TRANSFER;
					else
					begin
						d_state = ST_FIXED_LENGTH_TRANSFER;
						d_cnt_burst = q_cnt_burst +1;
					end
				end
				else if(|ma_bus_req)
					en_change_master = 1'b1;
			end
		endcase
	end

//`define AMBA_AHB_LITE_ARBITER_PRIORITY_LOGIC_DIVISION 
`ifndef AMBA_AHB_LITE_ARBITER_PRIORITY_LOGIC_DIVISION	
	reg [W_MASTER-1:0] q_lowest_master;
	reg [W_MASTER-1:0] sel_master;
	always @*
	begin:master_changer_combi
		reg [W_MASTER-1:0] p;
		//sel_master = GetHighestPriorityMaster(out_HMASTER, q_lowest_master, ma_bus_req);
		sel_master = out_HMASTER;
		if(PRIORITY_SCHEME == `PRISC_STATIC)
			p = N_MASTER-1;
		else
			p = q_lowest_master;
		repeat(N_MASTER)
		begin
			if(ma_bus_req[p])
				sel_master = p;
			p = (p == 0) ? N_MASTER-1 : p-1;
		end
	end
	
	always @(posedge HCLK or negedge HRESETn)
	begin
		if(~HRESETn)
		begin
			//Main state machine
			q_state <= ST_INIT;
			q_cnt_burst <= 0;
			q_HMASTLOCK <= 1'b0;
			//Master changer
			out_HMASTER <= NUM_DEF_MASTER;
			out_ma_active <= (1 << NUM_DEF_MASTER);
			q_lowest_master <= NUM_DEF_MASTER;
		end
		else if(HREADY)
		begin
			//Main state machine
			q_state <= d_state;
			q_cnt_burst <= d_cnt_burst;
			q_HMASTLOCK <= d_HMASTLOCK;
			//Master changer
			if(en_change_master)
			begin:master_changer
				out_ma_active <= (1 << sel_master);
				out_HMASTER <= sel_master;
				if(PRIORITY_SCHEME == `PRISC_ROUND_ROBIN)
				begin
					if(ROUND_ROBIN_SCHEME == `ROUND_ROBIN_SELECTED)
						q_lowest_master <= sel_master;
					else
						q_lowest_master <= (q_lowest_master == N_MASTER-1) ? 0 : q_lowest_master + 1;
				end
			end
		end
	end
`else //AMBA_AHB_LITE_ARBITER_PRIORITY_LOGIC_DIVISION
	localparam N_HIGH_HALF_MASTER = (N_MASTER >> 1);
	localparam N_LOW_HALF_MASTER = N_MASTER-N_HIGH_HALF_MASTER;
	
	reg [W_MASTER-1:0] q_lowest_high_half_master, q_lowest_low_half_master;
	reg [W_MASTER-1:0] sel_master;
	reg [W_MASTER-1:0] high_half_sel_master, low_half_sel_master;
	reg high_req, low_req;
	reg q_lowest_division;
	always @*
	begin:master_changer_combi
		reg [W_MASTER-1:0] high_p, low_p;
		//Low half
		low_half_sel_master = 0;
		low_req = 1'b0;
		if(PRIORITY_SCHEME == `PRISC_STATIC)
			low_p = N_LOW_HALF_MASTER-1;
		else
			low_p = q_lowest_low_half_master;
		repeat(N_LOW_HALF_MASTER)
		begin
			if(ma_bus_req[low_p])
			begin
				low_half_sel_master = low_p;
				low_req = 1'b1;
			end
			low_p = (low_p == 0) ? N_LOW_HALF_MASTER-1 : low_p-1;
		end
		//high half
		high_half_sel_master = N_LOW_HALF_MASTER;
		high_req = 1'b0;
		if(PRIORITY_SCHEME == `PRISC_STATIC)
			high_p = N_MASTER-1;
		else
			high_p = q_lowest_high_half_master;
		repeat(N_HIGH_HALF_MASTER)
		begin
			if(ma_bus_req[high_p])
			begin
				high_half_sel_master = high_p;
				high_req = 1'b1;
			end
			high_p = (high_p == N_LOW_HALF_MASTER) ? N_MASTER-1 : high_p-1;
		end
		//select
		/*if(|ma_bus_req[N_LOW_HALF_MASTER-1:0])
			sel_master = low_half_sel_master;
		else
			sel_master = high_half_sel_master;*/
		
		//if(N_HIGH_HALF_MASTER)
		//begin
			if(q_lowest_division)
				//sel_master = (|ma_bus_req[N_LOW_HALF_MASTER-1:0]) ? low_half_sel_master : high_half_sel_master;
				sel_master = low_req ? low_half_sel_master : high_half_sel_master;
			else
				//sel_master = (|ma_bus_req[N_MASTER-1:N_LOW_HALF_MASTER]) ? high_half_sel_master : low_half_sel_master;
				sel_master = high_req ? high_half_sel_master : low_half_sel_master;
		//end
		//else
			//sel_master = low_half_sel_master;
	end
	
	always @(posedge HCLK or negedge HRESETn)
	begin
		if(~HRESETn)
		begin
			//Main state machine
			q_state <= ST_INIT;
			q_cnt_burst <= 0;
			q_HMASTLOCK <= 1'b0;
			//Master changer
			out_HMASTER <= NUM_DEF_MASTER;
			out_ma_active <= (1 << NUM_DEF_MASTER);
			q_lowest_low_half_master <= 0;
			q_lowest_high_half_master <= N_LOW_HALF_MASTER;
			q_lowest_division <= 1'b1;
		end
		else if(HREADY)
		begin
			//Main state machine
			q_state <= d_state;
			q_cnt_burst <= d_cnt_burst;
			q_HMASTLOCK <= d_HMASTLOCK;
			//Master changer
			if(en_change_master)
			begin:master_changer
				//Updating the registers of the master changer
				out_ma_active <= (1 << sel_master);
				out_HMASTER <= sel_master;
				if(PRIORITY_SCHEME == `PRISC_ROUND_ROBIN)
				begin
					if(N_HIGH_HALF_MASTER)
						q_lowest_division <= ~q_lowest_division;
					if(ROUND_ROBIN_SCHEME == `ROUND_ROBIN_SELECTED)
					begin
						q_lowest_low_half_master <= low_half_sel_master;
						q_lowest_high_half_master <= high_half_sel_master;
					end
					else
					begin
						q_lowest_low_half_master <= (q_lowest_low_half_master == N_LOW_HALF_MASTER-1) ? 0 : q_lowest_low_half_master + 1;
						q_lowest_high_half_master <= (q_lowest_high_half_master == N_HIGH_HALF_MASTER-1) ? 0 : q_lowest_high_half_master + 1;
					end
				end
			end
		end
	end
`endif //AMBA_AHB_LITE_ARBITER_PRIORITY_LOGIC_DIVISION
endmodule
