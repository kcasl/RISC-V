`include "amba_ahb_h.v"
`include "amba_ahb_arbiter_h.v"
`include "amba_ahb_decoder_h.v"

`define N_STATE 3
`define W_STATE 2
	`define ST_INIT 0
	`define ST_WAIT 1
	`define ST_TRANSFER 2

module ahb_lite_input_stage #(
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
parameter DEC_SEL_ACTION = `DEC_SEL_NO_SLAVE)
(
	//Clock
	HCLK, HRESETn,
	//Input signals coming from the master
	ma_HREADY, ma_HSEL, ma_HTRANS, ma_HBURST, ma_HSIZE,
	ma_HPROT, ma_HMASTLOCK, ma_HADDR, ma_HWRITE, ma_HWDATA,
	//input signals coming from all output stages
	sl_active, sl_HREADY, sl_HRESP, sl_HRDATA,
	//Output signals to the master
	out_ma_HREADY, out_ma_HRESP, out_ma_HRDATA,
	//output signals outgoing to output stages
	out_sl_HTRANS, out_sl_HBURST, out_sl_HSIZE,
	out_sl_HPROT, out_sl_HMASTLOCK, out_sl_HADDR, out_sl_HWRITE,
	out_sl_HWDATA, out_sl_HSEL, out_held_trans,
	//for debugging
	q_state
);

	parameter DEF_HPROT = {`PROT_NOTCACHE, `PROT_UNBUF, `PROT_USER, `PROT_DATA};
	//Clock
	input HCLK, HRESETn;
	//Input signals coming from the master
	input ma_HREADY;
	input ma_HSEL;
	input [`W_TRANS-1:0] ma_HTRANS;
	input [`W_BURST-1:0] ma_HBURST;
	input [`W_SIZE-1:0] ma_HSIZE;
	input [`W_PROT-1:0] ma_HPROT;
	input ma_HMASTLOCK;
	input [W_ADDR-1:0] ma_HADDR;
	input ma_HWRITE;
	input [W_DATA-1:0] ma_HWDATA;
	//input signals coming from all output stages
	input [N_SLAVE-1:0] sl_active;
	input [N_SLAVE-1:0] sl_HREADY;
	input [N_SLAVE*`W_RESP-1:0] sl_HRESP;
	input [N_SLAVE*W_DATA-1:0] sl_HRDATA;
	//Output signals to the master
	output reg out_ma_HREADY;
	output reg [`W_RESP-1:0] out_ma_HRESP;
	output reg [W_DATA-1:0] out_ma_HRDATA;
	//output signals outgoing to output stages
	output reg [`W_TRANS-1:0] out_sl_HTRANS;
	output reg [`W_BURST-1:0] out_sl_HBURST;
	output reg [`W_SIZE-1:0] out_sl_HSIZE;
	output reg [`W_PROT-1:0] out_sl_HPROT;
	output reg out_sl_HMASTLOCK;
	output reg [W_ADDR-1:0] out_sl_HADDR;
	output reg out_sl_HWRITE;
	output [W_DATA-1:0] out_sl_HWDATA;
	output [N_SLAVE-1:0] out_sl_HSEL;
	output reg out_held_trans;
	
	//for debugging
	output [`W_STATE-1:0] q_state;
	
	assign out_sl_HWDATA = ma_HWDATA;
	//---------------------------------------------------------------------------
	//Address decoder & mux in the slave side
	//---------------------------------------------------------------------------
	wire [W_SLAVE-1:0] sl_HSLAVE;
	amba_ahb_decoder
		#(	//amba_ahb
				.N_SLAVE(N_SLAVE), .W_SLAVE(W_SLAVE),
				.W_ADDR(W_ADDR), .NUM_DEF_SLAVE(NUM_DEF_SLAVE),
				//amba_decoder
				.ADDR_START_MAP(ADDR_START_MAP),
				.ADDR_END_MAP(ADDR_END_MAP),
				.ADDR_MASK(ADDR_MASK),
				.ADDR_PREVILEGE_MAP(ADDR_PREVILEGE_MAP),
				.ADDR_RW_MAP(ADDR_RW_MAP),
				.DEC_SEL_ACTION(DEC_SEL_ACTION))
		decoder(.HADDR(out_sl_HADDR), .HPROT(out_sl_HPROT), .HWRITE(out_sl_HWRITE),
				.HSLAVE(sl_HSLAVE), .HSEL(out_sl_HSEL));
				
	reg selected_active;
	reg [W_SLAVE-1:0] q_sl_HSLAVE, d_sl_HSLAVE;
	always @*
	begin
		selected_active = sl_active[sl_HSLAVE];
		out_ma_HRDATA = sl_HRDATA[q_sl_HSLAVE*W_DATA+:W_DATA];
	end
		
	//---------------------------------------------------------------------------
	//Input stage
	//---------------------------------------------------------------------------
	reg [`W_STATE-1:0] q_state, d_state;
	reg ld_trans;
	reg [`W_TRANS-1:0] q_ma_HTRANS;
	reg [`W_BURST-1:0] q_ma_HBURST;
	reg [`W_SIZE-1:0] q_ma_HSIZE;
	reg [`W_PROT-1:0] q_ma_HPROT;
	reg q_ma_HMASTLOCK;
	reg [W_ADDR-1:0] q_ma_HADDR;
	reg q_ma_HWRITE;
	always @*
	begin
		d_state = q_state;
		d_sl_HSLAVE = q_sl_HSLAVE;
		ld_trans = 1'b0;
		case(q_state)
			`ST_TRANSFER:
			begin
				out_ma_HREADY = sl_HREADY[q_sl_HSLAVE];
				out_ma_HRESP = sl_HRESP[q_sl_HSLAVE*`W_RESP+:`W_RESP];
				if(sl_HREADY[q_sl_HSLAVE])
					d_sl_HSLAVE = sl_HSLAVE;
				out_sl_HSIZE = ma_HSIZE;
				out_sl_HPROT = ma_HPROT;
				out_sl_HMASTLOCK = ma_HMASTLOCK;
				out_sl_HADDR = ma_HADDR;
				out_sl_HWRITE = ma_HWRITE;
				out_sl_HTRANS = ma_HTRANS;
				out_sl_HBURST = ma_HBURST;
				/* //modified to meet timing
				if(ma_HSEL && sl_HREADY[q_sl_HSLAVE] && ((ma_HTRANS == `TRANS_NONSEQ) || (ma_HTRANS == `TRANS_SEQ)))
				//if(ma_HSEL && ((ma_HTRANS == `TRANS_NONSEQ) || (ma_HTRANS == `TRANS_SEQ)))
				begin
					out_held_trans = 1'b1;
					if(!selected_active)
					begin
						ld_trans = 1'b1;
						d_state = `ST_WAIT;
					end
				end
				else if(sl_HREADY[q_sl_HSLAVE])
				begin
					out_held_trans = 1'b0;
					d_state = `ST_INIT;
				end
				else
					out_held_trans = 1'b0;*/
				if(ma_HSEL && ((ma_HTRANS == `TRANS_NONSEQ) || (ma_HTRANS == `TRANS_SEQ)))
				begin
					out_held_trans = 1'b1;
					if(!selected_active && sl_HREADY[q_sl_HSLAVE])
					begin
						ld_trans = 1'b1;
						d_state = `ST_WAIT;
					end
				end
				else
				begin
					out_held_trans = 1'b0;
					if(sl_HREADY[q_sl_HSLAVE])
						d_state = `ST_INIT;
				end
			end
			`ST_WAIT:
			begin
				out_ma_HREADY = 1'b0;
				out_ma_HRESP = `RESP_OKAY;
				out_sl_HSIZE = q_ma_HSIZE;
				out_sl_HPROT = q_ma_HPROT;
				out_sl_HMASTLOCK = q_ma_HMASTLOCK;
				out_sl_HADDR = q_ma_HADDR;
				out_sl_HWRITE = q_ma_HWRITE;
				out_sl_HTRANS = q_ma_HTRANS;
				out_sl_HBURST = q_ma_HBURST;
				d_sl_HSLAVE = sl_HSLAVE;
				out_held_trans = 1'b1;
				//debugged on 2007.07.07
				//if(selected_active)
				if(selected_active && sl_HREADY[q_sl_HSLAVE])
					d_state = `ST_TRANSFER;
			end
			default: //`ST_INIT:
			begin
				out_ma_HREADY = 1'b1;
				out_ma_HRESP = `RESP_OKAY;
				out_sl_HSIZE = ma_HSIZE;
				out_sl_HPROT = ma_HPROT;
				out_sl_HMASTLOCK = ma_HMASTLOCK;
				out_sl_HADDR = ma_HADDR;
				out_sl_HWRITE = ma_HWRITE;
				out_sl_HTRANS = ma_HTRANS;
				out_sl_HBURST = ma_HBURST;
				d_sl_HSLAVE = sl_HSLAVE;
				if(ma_HSEL && ma_HREADY && ((ma_HTRANS == `TRANS_NONSEQ) || (ma_HTRANS == `TRANS_SEQ)))
				begin
					out_held_trans = 1'b1;
					if(selected_active)
					begin
						d_state = `ST_TRANSFER;
					end
					else
					begin
						ld_trans = 1'b1;
						d_state = `ST_WAIT;
					end
				end
				else
					out_held_trans = 1'b0;
			end
		endcase
	end
	
	always @(posedge HCLK or negedge HRESETn)
	begin
		if(~HRESETn)
		begin
			q_state <= 0;
			q_sl_HSLAVE <= 0;
			q_ma_HSIZE <= `SIZE_WORD;
			q_ma_HPROT <= DEF_HPROT;
			q_ma_HMASTLOCK <= 1'b0;
			q_ma_HADDR <= 0;
			q_ma_HWRITE <= 1'b0;
			q_ma_HTRANS <= `TRANS_IDLE;
			q_ma_HBURST <= `BURST_SINGLE;
		end
		else
		begin
			q_state <= d_state;
			q_sl_HSLAVE <= d_sl_HSLAVE;
			if(ld_trans)
			begin
				q_ma_HSIZE <= ma_HSIZE;
				q_ma_HPROT <= ma_HPROT;
				q_ma_HMASTLOCK <= ma_HMASTLOCK;
				q_ma_HADDR <= ma_HADDR;
				q_ma_HWRITE <= ma_HWRITE;
				q_ma_HTRANS <= ma_HTRANS;
				q_ma_HBURST <= ma_HBURST;
			end
		end
	end
endmodule
	
