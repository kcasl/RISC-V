`include "amba_ahb_h.v"     
module ahb_master(
	 HRESETn
	,HCLK
	,i_HRDATA
	,i_HRESP
	,i_HREADY
	,o_HADDR
	,o_HWDATA
	,o_HWRITE
	,o_HSIZE
	,o_HBURST
	,o_HTRANS
	);


	input			HRESETn;
	input			HCLK;
	input	[31:0]	i_HRDATA;
	input	[1:0]	i_HRESP;
	input			i_HREADY;
	output	[31:0]	o_HADDR;
	output	[31:0]	o_HWDATA;
	output			o_HWRITE;
	output	[2:0]	o_HSIZE;
	output	[`W_BURST-1:0]	o_HBURST;
	output	[1:0]	o_HTRANS;

	wire		w_HREADY;	
	wire	[31:0]	w_HRDATA;	

	reg	[31:0]	o_HADDR ;
	reg	[31:0]	o_HWDATA;
	reg			o_HWRITE;
	reg	[2:0]	o_HSIZE;
	reg	[1:0]	o_HTRANS;
	reg	[`W_BURST-1:0]	o_HBURST;

//PARAMETER//
//integer	  i;
//parameter p		=	1;	//propagation delay???

parameter BUR_SINGLE	=	3'b000;
parameter BUR_INCR 		=	3'b001;
parameter BUR_WRAP4		=	3'b010;
parameter BUR_INCR4		=	3'b011;
parameter BUR_WRAP8		=	3'b100;
parameter BUR_INCR8		=	3'b101;
parameter BUR_WRAP16	=	3'b110;
parameter BUR_INCR16	=	3'b111;

parameter SZ_BYTE	=	3'b000;
parameter SZ_HALF	=	3'b001;
parameter SZ_WORD	=	3'b010;

parameter TRANS_IDLE	=	2'b00;
parameter TRANS_BUSY	=	2'b01;
parameter TRANS_NONSEQ 	=	2'b10;
parameter TRANS_SEQ		=	2'b11;

//----------------------------------------------------------
// Intialization
//----------------------------------------------------------
assign w_HREADY = i_HREADY;
assign w_HRDATA = i_HRDATA;
task task_AHBinit;
	begin
		@(negedge HRESETn);	//#p;
		o_HADDR 	= 32'h00000000;
		o_HWDATA 	= 32'h00000000;
		o_HWRITE 	= 1'b0;
		o_HSIZE 	= 3'b000;
		o_HBURST 	= 3'b000;
		o_HTRANS 	= 2'b00;
	end
endtask
//----------------------------------------------------------
// Write Operation
//----------------------------------------------------------
task task_AHBwrite;
	input	[31:0]	i_addr;
	input	[31:0]	i_wData;

	begin
		// Address phase			
		@(posedge HCLK);	//#p;
		while(!w_HREADY)	@(posedge HCLK);
		@(posedge HCLK);	//#p;

		o_HADDR		= i_addr;
		o_HTRANS	= TRANS_NONSEQ;
		o_HSIZE		= SZ_WORD;
		o_HBURST	= BUR_SINGLE;
		o_HWRITE	= 1'b1;

		// Data phase
		while(!w_HREADY)	@(posedge HCLK);
		@(posedge HCLK);	//#p;

		o_HADDR		=	32'h00000000;
		o_HWDATA	=	i_wData;
		o_HTRANS	=	2'b00;
		o_HSIZE		=	3'b000;
		o_HBURST	=	3'b000;
		o_HWRITE	=	1'b0;

		@(posedge HCLK);	//#p;
		while(!w_HREADY)	@(posedge HCLK)
		@(posedge HCLK);	//#p;
	
		o_HWDATA	=	32'h00000000;
	end
endtask

//----------------------------------------------------------
// Read Operation
//----------------------------------------------------------
task task_AHBread;
	input	[31:0]	i_addr;
	output	[31:0]	o_rData;

	begin
		@(posedge HCLK);	//#p;
		while(!w_HREADY)	@(posedge HCLK);
		@(posedge HCLK);	//#p;
											  
		o_HADDR		=	i_addr;
		o_HTRANS	=	TRANS_NONSEQ;
		o_HSIZE		=	SZ_WORD;
		o_HBURST	=	BUR_SINGLE;
		o_HWRITE	=	1'b0;
											  
		while(!w_HREADY)	@(posedge HCLK);
		@(posedge HCLK);	//#p;
											  
		o_HADDR		=	32'h00000000;
		o_HTRANS	=	2'b00;
		o_HSIZE		=	3'b000;
		o_HBURST	=	3'b000;
											  
		@(posedge HCLK);	//#p;
		while(!w_HREADY)	@(posedge HCLK);
		o_rData		=	w_HRDATA;
	end
endtask
	
task task_AHBwait;
	begin
		@(posedge HCLK);	//#p;
		while(!w_HREADY)		@(posedge HCLK);
	end
endtask

endmodule


