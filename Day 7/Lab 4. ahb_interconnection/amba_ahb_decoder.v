// =================================================
// File name: amba_ahb_decoder.v
// Author:    Eung Sub Kim
// Created:   Fri. Jan 11 2008
// Modified:  
// -------------------------------------------------
// Description:
// 
// tape out : 4100, 2008/11/22
// =================================================
`include "amba_ahb_h.v"
`include "amba_ahb_decoder_h.v"

module amba_ahb_decoder #(
//amba ahb
parameter N_SLAVE = 2,
parameter W_SLAVE = 1,
parameter W_ADDR = 32,
parameter NUM_DEF_SLAVE = 0,
//parameters for decoder
parameter ADDR_START_MAP = {32'h80000000, 32'h00000000},
parameter ADDR_END_MAP = {32'hF0000000, 32'h70000000},
parameter ADDR_MASK = {2{32'hf0000000}},
parameter ADDR_PREVILEGE_MAP = {2{`PROT_USER}},
parameter ADDR_RW_MAP = {2{`PROP_READ_WRITE}},
//decoder behavior option
parameter DEC_SEL_ACTION = `DEC_SEL_NO_SLAVE)
(
	HADDR, 
	HPROT, 
	HWRITE, 
	HSLAVE,
	HSEL
);	
	input [W_ADDR-1:0] HADDR;
	input [`W_PROT-1:0] HPROT;
	input HWRITE;
	output reg [W_SLAVE-1:0] HSLAVE;
	output reg [N_SLAVE-1:0] HSEL;
	
	function [W_SLAVE-1:0] MatchRange;
		input [W_ADDR-1:0] addr;
		input [`W_PROT-1:0] prot;
		input hwrite;
		reg [W_SLAVE:0] i;
		reg [W_ADDR-1:0] mask, base, ad_start, ad_end;
		reg prev, read, write;
	begin
		MatchRange = NUM_DEF_SLAVE;
		for(i=0;i<N_SLAVE;i=i+1)
		begin
			mask = ADDR_MASK[i*W_ADDR+:W_ADDR];
			base = addr & mask;
			ad_start = ADDR_START_MAP[i*W_ADDR+:W_ADDR] & mask;
			ad_end = ADDR_END_MAP[i*W_ADDR+:W_ADDR] & mask;
			prev = ADDR_PREVILEGE_MAP[i];
			{read, write} = ADDR_RW_MAP[i*`W_AD_READ_WRITE+:`W_AD_READ_WRITE];
			if((base >= ad_start) && (base <= ad_end)
			&& ((prot[`IX_PROT_PREVILEGED] != `PROT_USER) || (prev == `PROT_USER))
			&& ((hwrite && write) || (~hwrite && read)) )
				MatchRange = i;
		end
	end
	endfunction
	
	function [W_SLAVE-1:0] IsItMatched;
		input [W_ADDR-1:0] addr;
		input [`W_PROT-1:0] prot;
		input hwrite;
		reg [W_SLAVE:0] i;
		reg [W_ADDR-1:0] mask, base, ad_start, ad_end;
		reg prev, read, write;
	begin
		IsItMatched = 1'b0;
		for(i=0;i<N_SLAVE;i=i+1)
		begin
			mask = ADDR_MASK[i*W_ADDR+:W_ADDR];
			base = addr & mask;
			ad_start = ADDR_START_MAP[i*W_ADDR+:W_ADDR] & mask;
			ad_end = ADDR_END_MAP[i*W_ADDR+:W_ADDR] & mask;
			prev = ADDR_PREVILEGE_MAP[i];
			{read, write} = ADDR_RW_MAP[i*`W_AD_READ_WRITE+:`W_AD_READ_WRITE];
			if((base >= ad_start) && (base <= ad_end)
			&& ((prot[`IX_PROT_PREVILEGED] != `PROT_USER) || (prev == `PROT_USER))
			&& ((hwrite && write) || (~hwrite && read)) )
				IsItMatched = 1'b1;
		end
	end
	endfunction

	always @*
	begin:decoder
		HSLAVE <= MatchRange(HADDR, HPROT, HWRITE);
		if(IsItMatched(HADDR, HPROT, HWRITE) || (DEC_SEL_ACTION == `DEC_SEL_DEF_SLAVE))
			HSEL <= 1'b1 << HSLAVE;
		else
			HSEL <= 0;
	end
endmodule