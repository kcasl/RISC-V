// =================================================
// File name: camera_interface.v
// Author:    Nguyen, Xuan Truong
// Created:   2020.01.30
// Modified:  
// -------------------------------------------------
// Description: 
// 
// 
// =================================================
`include "amba_ahb_h.v"

module ahb_lite_transactor(
	//clock
	HCLK,
	HRESETn,
	//input signals coming from the AHB lite
	HREADY,
	HRESP,
	HRDATA,
	//transaction request
	ld_trans,
	last_trans,				//used in case of unspecified burst mode, and for early burst termination
	in_req_burst,
	in_req_size,
	in_req_prot,
	in_req_lock,
	in_req_addr,
	in_req_write,
	in_req_wdata,
	//output signals outgoing to the AHB lite
	out_HTRANS,
	out_HBURST,
	out_HSIZE,
	out_HPROT,
	out_HMASTLOCK,
	out_HADDR,
	out_HWRITE,
	out_HWDATA,
	//transaction status signals
	out_trans_req_ready,	//a transaction request is accepted only when this signal is high.
	out_done_beat,			//indicating the finish of a transfer(beat); a transaction is composed of beats.
	out_done_trans,			//indicating the finish of a transaction
	out_resp_rdata
	);
	//the width of address bus
	parameter W_ADDR=32;
	//the width of data bus
	parameter W_DATA=32;
		
	parameter TRACE_FILE_NAME = "transactor.dat";
	parameter F_LOG_TRANS = 0;
	parameter F_DISPLAY_CONSOLE = 0;
	parameter F_LOG_TRANS_TIME = 0;
	
	//the width of address adder(that of local address)
	parameter W_VALID_LOCAL_ADDR = `W_MAX_LOCAL_ADDR;
	
	//clock
	input HCLK;
	input HRESETn;
	//input signals coming from the AHB lite
	input HREADY;
	input [`W_RESP-1:0] HRESP;
	input [W_DATA-1:0] HRDATA;
	//transaction request
	input ld_trans;
	input last_trans;					//used in case of unspecified burst mode, and for early burst termination
	input [`W_BURST-1:0] in_req_burst;
	input [`W_SIZE-1:0] in_req_size;
	input [`W_PROT-1:0] in_req_prot;
	input in_req_lock;
	input [W_ADDR-1:0] in_req_addr;
	input in_req_write;
	input [W_DATA-1:0] in_req_wdata;
	//output signals outgoing to the AHB lite
	output reg [`W_TRANS-1:0] out_HTRANS;
	output reg [`W_BURST-1:0] out_HBURST;
	output reg [`W_SIZE-1:0] out_HSIZE;
	output reg [`W_PROT-1:0] out_HPROT;
	output reg out_HMASTLOCK;
	output reg [W_ADDR-1:0] out_HADDR;
	output reg out_HWRITE;
	output [W_DATA-1:0] out_HWDATA;
	//transaction status signals
	output reg out_trans_req_ready;	//a transaction request is accepted only when this signal is high.
	output reg out_done_beat;		//indicating the finish of a transfer(beat); a transaction is composed of beats.
	output reg out_done_trans;		//indicating the finish of a transaction
	output [W_DATA-1:0] out_resp_rdata;
		assign out_resp_rdata = HRDATA;
		assign out_HWDATA = in_req_wdata;
		
	reg [`W_BURST-1:0] q_HBURST;
	reg [`W_SIZE-1:0] q_HSIZE;
	reg [`W_PROT-1:0] q_HPROT;
	reg q_HMASTLOCK;
	reg [W_ADDR-1:0] q_HADDR, d_HADDR;
	reg q_HWRITE;
	localparam W_CNT_BURST = 4;
	reg [W_CNT_BURST-1:0] q_cnt_burst, d_cnt_burst;
	localparam N_STATE = 3;
	localparam W_STATE = 2;
		localparam ST_INIT = 0;
		localparam ST_NORMAL = 1;
		localparam ST_INCR = 2;
	reg [W_STATE-1:0] q_state, d_state;

	function [W_VALID_LOCAL_ADDR-1:0] GetNextAddr;
		input [W_VALID_LOCAL_ADDR-1:0] cur_addr;
		input [`W_SIZE-1:0] size;
		input [`W_BURST-1:0] burst;
	begin
		if(burst[0])	//incremental
			GetNextAddr = cur_addr + (1 << size);
		else
		begin
			GetNextAddr = cur_addr;
			case(burst[`W_BURST-1:1])
				1:	//4 beats
					GetNextAddr[size+:2] = GetNextAddr[size+:2]+1;
				2:	//8 beats
					GetNextAddr[size+:3] = GetNextAddr[size+:3]+1;
				3:	//16 beats
					GetNextAddr[size+:4] = GetNextAddr[size+:4]+1;
			endcase
		end
	end
	endfunction
	
	always @*
	begin
		d_state = q_state;
		d_cnt_burst = q_cnt_burst;
		d_HADDR = q_HADDR;
		out_HBURST = q_HBURST;
		out_HSIZE = q_HSIZE;
		out_HWRITE = q_HWRITE;
		out_HADDR = q_HADDR;
		out_HPROT = q_HPROT;
		out_HMASTLOCK = q_HMASTLOCK;
		out_HTRANS = `TRANS_IDLE;
		out_trans_req_ready = 1'b1;
		out_done_beat = 1'b0;
		out_done_trans = 1'b0;
		case(q_state)
			ST_INCR:
			begin
				out_HTRANS = `TRANS_SEQ;
				//d_HADDR = q_HADDR + (1 << q_HSIZE);
				d_HADDR[W_VALID_LOCAL_ADDR-1:0] = q_HADDR[W_VALID_LOCAL_ADDR-1:0] + (1 << q_HSIZE);
				out_done_beat = HREADY;
				out_trans_req_ready = 1'b0;
				if(last_trans)
				begin:last_incr_beat
					d_state = ST_NORMAL;
				end
			end
			default: //ST_INIT, ST_NORMAL:
			begin
				if(q_cnt_burst)
				begin
					out_HTRANS = `TRANS_SEQ;
					//d_HADDR = q_HADDR + (1 << q_HSIZE);
					//d_HADDR = GetNextAddr(q_HADDR, q_HSIZE, q_HBURST);		//Modified by eskim on 2009-04-08
					d_HADDR[W_ADDR-1:W_VALID_LOCAL_ADDR] = q_HADDR[W_ADDR-1:W_VALID_LOCAL_ADDR];
					d_HADDR[W_VALID_LOCAL_ADDR-1:0] = GetNextAddr(q_HADDR[W_VALID_LOCAL_ADDR-1:0], q_HSIZE, q_HBURST);
					if(last_trans)
						d_cnt_burst = 0;
					else
						d_cnt_burst = q_cnt_burst - 1;
					out_done_beat = HREADY;
					out_trans_req_ready = 1'b0;
				end
				else
				begin
					if(ld_trans)
					begin
						out_HTRANS = `TRANS_NONSEQ;
						out_HBURST = in_req_burst;
						out_HSIZE = in_req_size;
						out_HWRITE = in_req_write;
						out_HADDR = in_req_addr;
						//d_HADDR = in_req_addr + (1 << in_req_size);
						d_HADDR[W_ADDR-1:W_VALID_LOCAL_ADDR] = in_req_addr[W_ADDR-1:W_VALID_LOCAL_ADDR];
						d_HADDR[W_VALID_LOCAL_ADDR-1:0] = in_req_addr[W_VALID_LOCAL_ADDR-1:0] + (1 << in_req_size);
						out_HPROT = in_req_prot;
						out_HMASTLOCK = in_req_lock;
						if(in_req_burst[`W_BURST-1:1]) begin    // FIXME
							d_cnt_burst = (2 << in_req_burst[`W_BURST-1:1])-1;
						end else
							d_cnt_burst = 0;

						if(in_req_burst == `BURST_INCR)
							d_state = ST_INCR;
						else
							d_state = ST_NORMAL;
					end
					else
						d_state = ST_INIT;
					if(q_state == ST_NORMAL)
					begin
						out_done_trans = HREADY;
						out_done_beat = HREADY;
						out_trans_req_ready = HREADY;
						//an IDLE cycle should be included in the last transfer in case of the lock transfer
						if(q_HMASTLOCK)
						begin
							out_HTRANS = `TRANS_IDLE;
							out_trans_req_ready = 1'b0;
							d_state = ST_INIT;
							d_cnt_burst = 0;
						end
					end 
				end
			end
		endcase
	end
	
	always @(posedge HCLK or negedge HRESETn)
	begin
		if(~HRESETn)
		begin
			q_state <= 0;
			q_cnt_burst <= 0;
			q_HBURST <= 0;
			q_HSIZE <= 0;
			q_HWRITE <= 1'b0;
			q_HADDR <= 0;
			q_HPROT <= 0;
			q_HMASTLOCK <= 1'b0;
		end
		else if(HREADY)
		begin
			q_state <= d_state;
			q_cnt_burst <= d_cnt_burst;
			q_HBURST <= out_HBURST;
			q_HSIZE <= out_HSIZE;
			q_HWRITE <= out_HWRITE;
			q_HADDR <= d_HADDR;
			q_HPROT <= out_HPROT;
			q_HMASTLOCK <= out_HMASTLOCK;
		end
	end
endmodule
