// =================================================
// File name: ahb_lite_interconnect.v
// Author:    Eung Sub Kim
// Created:   Fri. Jan 11 2008
// Modified:  
// -------------------------------------------------
// Description:
// 
// tape out : 4100, 2008/11/22
// =================================================
`include "amba_ahb_h.v"
`include "amba_ahb_arbiter_h.v"
`include "amba_ahb_decoder_h.v"

`define W_MA_STATE 2
`define W_SL_STATE 2

module ahb_lite_interconnect #(
//parameters specified by user for AHB
//the number of masters, which can be up to 16
parameter N_MASTER=4,
//W_MASTER=ceil(log2(N_MASTER))
parameter W_MASTER=2,
//the number of slaves
parameter N_SLAVE=4,
//W_SLAVE=ceil(log2(N_SLAVE))
parameter W_SLAVE=2,
//the width of address bus
parameter W_ADDR=32,
//the width of data bus
parameter W_DATA=32,
//the number of byte of AHB data bus width
//WB_P_DATA=W_DATA/8
parameter WB_DATA=4,
//W_WB_DATA=ceil(log2(WB_DATA))
parameter W_WB_DATA=2,

//the number of default master
parameter NUM_DEF_MASTER = 0,
//the number of default slave
parameter NUM_DEF_SLAVE = 0,
// Arbiter
parameter PRIORITY_SCHEME = `PRISC_ROUND_ROBIN,
parameter ROUND_ROBIN_SCHEME = `ROUND_ROBIN_SELECTED,
// Decoder
//parameters for decoder
parameter ADDR_START_MAP = {32'h80000000, 32'h00000000},
parameter ADDR_END_MAP = {32'hF0000000, 32'h70000000},
parameter ADDR_MASK = {2{32'hf0000000}},
parameter ADDR_PREVILEGE_MAP = {2{`PROT_USER}},
parameter ADDR_RW_MAP = {2{`PROP_READ_WRITE}},
//decoder behavior option
parameter DEC_SEL_ACTION = `DEC_SEL_NO_SLAVE
)
(
		//Clock
		HCLK, HRESETn,
		//Input signals coming from masters
		ma_HREADY, ma_HSEL, 
		ma_HTRANS, ma_HBURST, ma_HSIZE, ma_HPROT,
		ma_HMASTLOCK, ma_HADDR, ma_HWRITE, ma_HWDATA,
		//input signals coming from slaves
		sl_HREADY, sl_HRESP, sl_HRDATA,
		//Output signals outgoing to masters
		out_ma_HREADY, out_ma_HRESP, out_ma_HRDATA,
		//output signals outgoing to slaves
		out_sl_HREADY, out_sl_HSEL,
		out_sl_HTRANS, out_sl_HBURST, out_sl_HSIZE, out_sl_HPROT,
		out_sl_HMASTLOCK, out_sl_HADDR, out_sl_HWRITE, out_sl_HWDATA,
		//for debugging
		int_ma_q_state, int_sl_q_state,
		int_sl_active, int_ma_active,
		int_ma_held_trans,
		int_ma_HTRANS,
		int_sl_HREADY
		);	
	//Clock
	input HCLK, HRESETn;
	//Input signals coming from masters
	input [N_MASTER-1:0] ma_HREADY;
	input [N_MASTER-1:0] ma_HSEL;
	input [N_MASTER*`W_TRANS-1:0] ma_HTRANS;
	input [N_MASTER*`W_BURST-1:0] ma_HBURST;
	input [N_MASTER*`W_SIZE-1:0] ma_HSIZE;
	input [N_MASTER*`W_PROT-1:0] ma_HPROT;
	input [N_MASTER-1:0] ma_HMASTLOCK;
	input [N_MASTER*W_ADDR-1:0] ma_HADDR;
	input [N_MASTER-1:0] ma_HWRITE;
	input [N_MASTER*W_DATA-1:0] ma_HWDATA;
	//input signals coming from slaves
	input [N_SLAVE-1:0] sl_HREADY;
	input [N_SLAVE*`W_RESP-1:0] sl_HRESP;
	input [N_SLAVE*W_DATA-1:0] sl_HRDATA;
	//Output signals outgoing to masters
	output [N_MASTER-1:0] out_ma_HREADY;
	output [N_MASTER*`W_RESP-1:0] out_ma_HRESP;
	output [N_MASTER*W_DATA-1:0] out_ma_HRDATA;
	//output signals outgoing to slaves
	output [N_SLAVE-1:0] out_sl_HREADY;
	output [N_SLAVE-1:0] out_sl_HSEL;
	output [N_SLAVE*`W_TRANS-1:0] out_sl_HTRANS;
	output [N_SLAVE*`W_BURST-1:0] out_sl_HBURST;
	output [N_SLAVE*`W_SIZE-1:0] out_sl_HSIZE;
	output [N_SLAVE*`W_PROT-1:0] out_sl_HPROT;
	output [N_SLAVE-1:0] out_sl_HMASTLOCK;
	output [N_SLAVE*W_ADDR-1:0] out_sl_HADDR;
	output [N_SLAVE-1:0] out_sl_HWRITE;
	output [N_SLAVE*W_DATA-1:0] out_sl_HWDATA;
	
	//for debugging
	output [N_MASTER*`W_MA_STATE-1:0] int_ma_q_state;
	output [N_SLAVE*`W_SL_STATE-1:0] int_sl_q_state;
	output [N_SLAVE*N_MASTER-1:0] int_sl_active;
	output [N_MASTER*N_SLAVE-1:0] int_ma_active;
	output [N_MASTER-1:0] int_ma_held_trans;
	output [N_MASTER*`W_TRANS-1:0] int_ma_HTRANS;
	output [N_SLAVE-1:0] int_sl_HREADY;

	//signals used to copy output signals of slaves to each master
	wire [N_SLAVE-1:0] int_sl_HREADY;
	wire [N_SLAVE*`W_RESP-1:0] int_sl_HRESP;
	wire [N_SLAVE*W_DATA-1:0] int_sl_HRDATA;
	//signals used to copy output signals of masters to each slaves
	wire [N_MASTER-1:0] int_ma_held_trans;
	wire [N_MASTER*`W_TRANS-1:0] int_ma_HTRANS;
	wire [N_MASTER*`W_BURST-1:0] int_ma_HBURST;
	wire [N_MASTER*`W_SIZE-1:0] int_ma_HSIZE;
	wire [N_MASTER*`W_PROT-1:0] int_ma_HPROT;
	wire [N_MASTER-1:0] int_ma_HMASTLOCK;
	wire [N_MASTER*W_ADDR-1:0] int_ma_HADDR;
	wire [N_MASTER-1:0] int_ma_HWRITE;
	wire [N_MASTER*W_DATA-1:0] int_ma_HWDATA;
	
	//for debugging
	wire [N_MASTER*`W_MA_STATE-1:0] int_ma_q_state;
	wire [N_SLAVE*`W_SL_STATE-1:0] int_sl_q_state;
	
	//cross (transpose reflection)
		//active signal
			//active signals according to each master generted by each slave
			wire [N_SLAVE*N_MASTER-1:0] int_sl_active;
			//active signals applied to each master
			wire [N_MASTER*N_SLAVE-1:0] int_ma_active;
				assign int_ma_active = ConvSl2Ma_Active(int_sl_active);
			function [N_MASTER*N_SLAVE-1:0] ConvSl2Ma_Active;
				input [N_SLAVE*N_MASTER-1:0] sl_active;
				reg [W_MASTER:0] i;
				reg [W_SLAVE:0] j;
			begin
				for(i=0;i<N_MASTER;i=i+1)
					for(j=0;j<N_SLAVE;j=j+1)
						ConvSl2Ma_Active[i*N_SLAVE+j] = sl_active[j*N_MASTER+i];
			end
			endfunction
		//sel signal
			//sel signals according to each slave generated by each master
			wire [N_MASTER*N_SLAVE-1:0] int_ma_HSEL;
			//sel signals applied to each slave
			wire [N_SLAVE*N_MASTER-1:0] int_sl_HSEL;
				assign int_sl_HSEL = ConvMa2Sl_Sel(int_ma_HSEL);
			function [N_SLAVE*N_MASTER-1:0] ConvMa2Sl_Sel;
				input [N_MASTER*N_SLAVE-1:0] ma_HSEL;
				reg [W_SLAVE:0] i;
				reg [W_MASTER:0] j;
			begin
				for(i=0;i<N_SLAVE;i=i+1)
					for(j=0;j<N_MASTER;j=j+1)
						ConvMa2Sl_Sel[i*N_MASTER+j] = ma_HSEL[j*N_SLAVE+i];
			end
			endfunction
		
	
	ahb_lite_input_stage
		#(	//amba_ahb_lite
			.N_SLAVE(N_SLAVE), .W_SLAVE(W_SLAVE),
			.W_ADDR(W_ADDR), .W_DATA(W_DATA),
			.WB_DATA(WB_DATA), .W_WB_DATA(W_WB_DATA),
			.NUM_DEF_SLAVE(NUM_DEF_SLAVE),
			//amba_ahb_decoder
			.ADDR_START_MAP(ADDR_START_MAP),
			.ADDR_END_MAP(ADDR_END_MAP),
			.ADDR_MASK(ADDR_MASK),
			.ADDR_PREVILEGE_MAP(ADDR_PREVILEGE_MAP),
			.ADDR_RW_MAP(ADDR_RW_MAP),
			.DEC_SEL_ACTION(DEC_SEL_ACTION))
		input_stage[N_MASTER-1:0](
			//Clock
			.HCLK(HCLK), .HRESETn(HRESETn),
			//Input signals coming from the master
			.ma_HREADY(ma_HREADY), .ma_HSEL(ma_HSEL),
			.ma_HTRANS(ma_HTRANS), .ma_HBURST(ma_HBURST), .ma_HSIZE(ma_HSIZE),
			.ma_HPROT(ma_HPROT), .ma_HMASTLOCK(ma_HMASTLOCK), .ma_HADDR(ma_HADDR),
			.ma_HWRITE(ma_HWRITE), .ma_HWDATA(ma_HWDATA),
			//input signals coming from all output stages
			.sl_active(int_ma_active), .sl_HREADY(int_sl_HREADY),
			.sl_HRESP(int_sl_HRESP), .sl_HRDATA(int_sl_HRDATA),
			//Output signals to the master
			.out_ma_HREADY(out_ma_HREADY), .out_ma_HRESP(out_ma_HRESP), .out_ma_HRDATA(out_ma_HRDATA),
			//output signals outgoing to output stages
			.out_sl_HTRANS(int_ma_HTRANS), .out_sl_HBURST(int_ma_HBURST),
			.out_sl_HSIZE(int_ma_HSIZE),
			.out_sl_HPROT(int_ma_HPROT), .out_sl_HMASTLOCK(int_ma_HMASTLOCK),
			.out_sl_HADDR(int_ma_HADDR), .out_sl_HWRITE(int_ma_HWRITE),
			.out_sl_HWDATA(int_ma_HWDATA),
			.out_sl_HSEL(int_ma_HSEL), .out_held_trans(int_ma_held_trans),
			//for debugging
			.q_state(int_ma_q_state));
			
	amba_lite_output_stage
		#(	//amba_ahb
			.N_MASTER(N_MASTER), .W_MASTER(W_MASTER), 
			.W_ADDR(W_ADDR), .W_DATA(W_DATA),
			.NUM_DEF_MASTER(NUM_DEF_MASTER),
			//amba_ahb_arbiter
			.PRIORITY_SCHEME(PRIORITY_SCHEME), .ROUND_ROBIN_SCHEME(ROUND_ROBIN_SCHEME))
		output_stage[N_SLAVE-1:0](
			//Clock
			.HCLK(HCLK), .HRESETn(HRESETn),
			//Input signals coming from all input stages
			.ma_HSEL(int_sl_HSEL), .ma_held_trans(int_ma_held_trans),
			.ma_HTRANS(int_ma_HTRANS), .ma_HBURST(int_ma_HBURST),
			.ma_HSIZE(int_ma_HSIZE), .ma_HPROT(int_ma_HPROT),
			.ma_HMASTLOCK(int_ma_HMASTLOCK), .ma_HADDR(int_ma_HADDR),
			.ma_HWRITE(int_ma_HWRITE), .ma_HWDATA(int_ma_HWDATA),
			//input signals coming from the slave
			.sl_HREADY(sl_HREADY), .sl_HRESP(sl_HRESP), .sl_HRDATA(sl_HRDATA),
			//Output signals to all input stages
			.out_ma_active(int_sl_active), .out_ma_HREADY(int_sl_HREADY),
			.out_ma_HRESP(int_sl_HRESP), .out_ma_HRDATA(int_sl_HRDATA),
			//output signals outgoing to the slave
			.out_sl_HREADY(out_sl_HREADY), .out_sl_HSEL(out_sl_HSEL),
			.out_sl_HTRANS(out_sl_HTRANS), .out_sl_HBURST(out_sl_HBURST),
			.out_sl_HSIZE(out_sl_HSIZE), .out_sl_HPROT(out_sl_HPROT),
			.out_sl_HMASTLOCK(out_sl_HMASTLOCK), .out_sl_HADDR(out_sl_HADDR),
			.out_sl_HWRITE(out_sl_HWRITE), .out_sl_HWDATA(out_sl_HWDATA),
			//for debugging
			.q_state(int_sl_q_state));
endmodule
