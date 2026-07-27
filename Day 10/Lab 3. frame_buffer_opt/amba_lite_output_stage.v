`include "amba_ahb_h.v"
`include "amba_ahb_arbiter_h.v"

`define N_STATE 3
`define W_STATE 2

module amba_lite_output_stage #(
//ahb
//the number of masters, which can be up to 16
parameter N_MASTER=2,
//W_MASTER=ceil(log2(N_MASTER))
parameter W_MASTER=1,
//the width of address bus
parameter W_ADDR=32,
//the width of data bus
parameter W_DATA=32,
//the number of default master
parameter NUM_DEF_MASTER = 0,
parameter PRIORITY_SCHEME = `PRISC_ROUND_ROBIN,
parameter ROUND_ROBIN_SCHEME = `ROUND_ROBIN_SELECTED
)
(
		//Clock
		HCLK, HRESETn,
		//Input signals coming from all input stages
		ma_HSEL, ma_held_trans,
		ma_HTRANS, ma_HBURST, ma_HSIZE, ma_HPROT,
		ma_HMASTLOCK, ma_HADDR, ma_HWRITE, ma_HWDATA,
		//input signals coming from the slave
		sl_HREADY, sl_HRESP, sl_HRDATA,
		//Output signals to all input stages
		out_ma_active, out_ma_HREADY, out_ma_HRESP, out_ma_HRDATA,
		//output signals outgoing to the slave
		out_sl_HREADY, out_sl_HSEL,
		out_sl_HTRANS, out_sl_HBURST, out_sl_HSIZE, out_sl_HPROT,
		out_sl_HMASTLOCK, out_sl_HADDR, out_sl_HWRITE, out_sl_HWDATA,
		//for debugging
		q_state);


	//Clock
	input HCLK, HRESETn;
	//Input signals coming from all input stages
	//input [N_MASTER-1:0] ma_HREADY;
	input [N_MASTER-1:0] ma_HSEL;
	input [N_MASTER-1:0] ma_held_trans;
	input [N_MASTER*`W_TRANS-1:0] ma_HTRANS;
	input [N_MASTER*`W_BURST-1:0] ma_HBURST;
	input [N_MASTER*`W_SIZE-1:0] ma_HSIZE;
	input [N_MASTER*`W_PROT-1:0] ma_HPROT;
	input [N_MASTER-1:0] ma_HMASTLOCK;
	input [N_MASTER*W_ADDR-1:0] ma_HADDR;
	input [N_MASTER-1:0] ma_HWRITE;
	input [N_MASTER*W_DATA-1:0] ma_HWDATA;
	//input signals coming from the slave
	input sl_HREADY;
	input [`W_RESP-1:0] sl_HRESP;
	input [W_DATA-1:0] sl_HRDATA;
	//Output signals to all input stages
	output [N_MASTER-1:0] out_ma_active;
	output out_ma_HREADY;
	output [`W_RESP-1:0] out_ma_HRESP;
	output [W_DATA-1:0] out_ma_HRDATA;
	//output signals outgoing to the slave
	output reg out_sl_HREADY;
	output reg out_sl_HSEL;
	output reg [`W_TRANS-1:0] out_sl_HTRANS;
	output reg [`W_BURST-1:0] out_sl_HBURST;
	output reg [`W_SIZE-1:0] out_sl_HSIZE;
	output reg [`W_PROT-1:0] out_sl_HPROT;
	output reg out_sl_HMASTLOCK;
	output reg [W_ADDR-1:0] out_sl_HADDR;
	output reg out_sl_HWRITE;
	output reg [W_DATA-1:0] out_sl_HWDATA;
	
	//for debugging
	output [`W_STATE-1:0] q_state;

	wire [W_MASTER-1:0] HMASTER;
	reg [W_MASTER-1:0] q_HMASTER;
	wire [N_MASTER-1:0] ma_bus_req;
		assign ma_bus_req = ma_held_trans & ma_HSEL;
	//wire trans_progress;
	reg trans_progress;
	//amba_ahb_lite_arbiter_with_change_delay_and_no_burst_interrupt
	amba_ahb_lite_arbiter
		#(			//ahb
					.N_MASTER(N_MASTER), .W_MASTER(W_MASTER), .NUM_DEF_MASTER(NUM_DEF_MASTER),
					//priority scheme
					.PRIORITY_SCHEME(PRIORITY_SCHEME), .ROUND_ROBIN_SCHEME(ROUND_ROBIN_SCHEME))
		arbiter(	.HCLK(HCLK), .HRESETn(HRESETn),
					.ma_bus_req(ma_bus_req), .ma_HTRANS(ma_HTRANS),
					.ma_HBURST(ma_HBURST), .ma_HMASTLOCK(ma_HMASTLOCK),
					.HREADY(sl_HREADY),
					.out_ma_active(out_ma_active),
					.out_HMASTER(HMASTER),
					//.out_trans(trans_progress),
					.q_state(q_state));
	
	assign out_ma_HREADY = sl_HREADY;
	assign out_ma_HRESP = sl_HRESP;
	assign out_ma_HRDATA = sl_HRDATA;
	always @*
	begin
		out_sl_HREADY = trans_progress ? sl_HREADY : 1'b1;
		out_sl_HSEL = ma_bus_req[HMASTER];
		out_sl_HTRANS = ma_HTRANS[HMASTER*`W_TRANS+:`W_TRANS];
		out_sl_HBURST = ma_HBURST[HMASTER*`W_BURST+:`W_BURST];
		out_sl_HSIZE = ma_HSIZE[HMASTER*`W_SIZE+:`W_SIZE];
		out_sl_HPROT = ma_HPROT[HMASTER*`W_PROT+:`W_PROT];
		out_sl_HMASTLOCK = ma_HMASTLOCK[HMASTER];
		out_sl_HADDR = ma_HADDR[HMASTER*W_ADDR+:W_ADDR];
		out_sl_HWRITE = ma_HWRITE[HMASTER];
		out_sl_HWDATA = ma_HWDATA[q_HMASTER*W_DATA+:W_DATA];
	end
	
	always @(posedge HCLK or negedge HRESETn)
	begin
		if(~HRESETn)
		begin
			q_HMASTER <= NUM_DEF_MASTER;
			trans_progress <= 1'b0;
		end
		//else	//debugged on 2007.07.07
		else if(sl_HREADY)
		begin
			q_HMASTER <= HMASTER;
			trans_progress <= |out_sl_HTRANS;
		end
	end
endmodule
