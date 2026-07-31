`include "amba_ahb_h.v"
module ahb_bram(
	//CLOCK
	HCLK,
	HRESETn,
	//input signals of control port(slave)
	HREADY,
	HSEL,
	HTRANS,
	HBURST,
	HSIZE,
	HADDR,
	HWRITE,
	HWDATA,
	//output signals of control port(slave)
	out_HREADY,				
	out_HRESP,
	out_HRDATA,
	// Memory interface
	sram_we,
	sram_en,
	sram_addr,
	sram_wdata,
	sram_rdata
);
//bus interface
parameter W_ADDR = 32;
parameter W_DATA = 32;
parameter WB_DATA = 4;
parameter W_WB_DATA = 2;
parameter N_WORD = 131072;
parameter W_WORD = $clog2(N_WORD);	
parameter EN_LOAD_INIT_FILE = 1'b1;
parameter INIT_FILE = "img/kodim03_32bit.hex";	
//CLOCK
input HCLK;
input HRESETn;
//input signals of control port(slave)
input HREADY;
input HSEL;
input [`W_TRANS-1:0] HTRANS;
input [`W_BURST-1:0] HBURST;
input [`W_SIZE-1:0] HSIZE;
input [W_ADDR-1:0] HADDR;
input HWRITE;
input [W_DATA-1:0] HWDATA;
//output signals of control port(slave)
output out_HREADY;				
output [`W_RESP-1:0] out_HRESP;
output [W_DATA-1:0] out_HRDATA;

// SRAM interface
output sram_en, sram_we;
output [W_WORD-1:0] sram_addr;
output [W_DATA-1:0] sram_wdata;
input  [W_DATA-1:0] sram_rdata;
//----------------------------------------------------------
//BRAM control
//----------------------------------------------------------
localparam N_STATE = 3;
localparam W_STATE = 2;
	localparam ST_INIT = 0;
	localparam ST_WRITE = 1;
	localparam ST_READ_WAIT = 2;
reg [W_STATE-1:0] q_state;
assign out_HRESP = `RESP_OKAY;
assign out_HREADY = (q_state == ST_READ_WAIT) ? 1'b0 : 1'b1;

wire en_ahb = HSEL && HREADY && ((HTRANS == `TRANS_NONSEQ) || (HTRANS == `TRANS_SEQ));
wire [W_WORD-1:0] bram_addr = HADDR[W_ADDR-1:W_WB_DATA];
reg [W_WORD-1:0] q_bram_addr;
	
always @(posedge HCLK or negedge HRESETn)
begin
	if(~HRESETn)
	begin
		q_state <= 0;
		q_bram_addr <= 0;
	end
	else begin
		case(q_state)
			ST_READ_WAIT:
				q_state <= ST_INIT;
			ST_WRITE:
				if(en_ahb & ~HWRITE)
					q_state <= ST_READ_WAIT;
				else
					q_state <= ST_INIT;
			default:	//ST_INIT:
				if(en_ahb & HWRITE)
				begin
					q_state <= ST_WRITE;
					q_bram_addr <= bram_addr;
				end
		endcase
	end
end

//----------------------------------------------------------
//Block RAM
//----------------------------------------------------------
//wire bram_WE = (q_state == ST_WRITE);
//wire bram_EN = bram_WE || ((q_state == ST_READ_WAIT) || (en_ahb && !HWRITE));
//wire [W_WORD-1:0] bram_ADDR = bram_WE ? q_bram_addr : bram_addr;
//
assign sram_we = (q_state == ST_WRITE);
assign sram_en = sram_we || ((q_state == ST_READ_WAIT) || (en_ahb && !HWRITE));
assign sram_addr = sram_we ? q_bram_addr : bram_addr;
assign sram_wdata = HWDATA;
assign out_HRDATA = sram_rdata;
//bram
//#(.W_DATA(W_DATA),
//.N_WORD(N_WORD),
//.W_WORD(W_WORD),
//.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
//.INIT_FILE(INIT_FILE))
//u_bram(
//	.clk(HCLK),
//	.en(bram_EN),
//	.addr(bram_ADDR),
//	.din(HWDATA),
//	.we(bram_WE),
//	.dout(out_HRDATA)
//);
endmodule
