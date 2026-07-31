// =================================================
// File name: dma2buf.v
// Author:    Nguyen, Xuan Truong
// Created:   2020.01.30
// Modified:  
// -------------------------------------------------
// Description:
// 
// 
// =================================================
`include "amba_ahb_h.v"
module dma2buf (
	//AHB transactor signals
	HREADY,
	HRESP,
	HRDATA,
	//output signals outgoing to the AHB lite
	out_HTRANS,
	out_HBURST,
	out_HSIZE,
	out_HPROT,
	out_HMASTLOCK,
	out_HADDR,
	out_HWRITE,
	out_HWDATA,
   //control signal
   start_dma,
   num_trans,
   start_addr,
   //Output
   data_o,
   data_vld_o,
   data_cnt_o,
   data_last_o,

   //Global signals
   clk,
   resetn
);
//------------------------------------------------------------------------------
// Parameter declarations
//------------------------------------------------------------------------------
   //AHB parameters
   parameter W_ADDR = 32;
   parameter W_DATA = 32;
      localparam WB_DATA = W_DATA/8; // = 4;
      localparam W_WB_DATA = $clog2(WB_DATA); 
   parameter DEF_HPROT = {`PROT_NOTCACHE, `PROT_UNBUF, `PROT_USER, `PROT_DATA};
   parameter MAX_TRANS = 1024; //Maximum number of transfers
   parameter BITS_TRANS = $clog2(MAX_TRANS);

   parameter USE_BURST_TYPE = `BURST_INCR16;
	parameter N_BURST_SIZE = 16;
		localparam W_BURST_SIZE = $clog2(N_BURST_SIZE);
   parameter BOUNDARY_1KB = 10; //clog2(1024)

//------------------------------------------------------------------------------
// Port declarations
//------------------------------------------------------------------------------
   //AHB transactor signals
	input HREADY;
	input [`W_RESP-1:0] HRESP;
	input [W_DATA-1:0] HRDATA;
	//output signals outgoing to the AHB lite
	output [`W_TRANS-1:0] out_HTRANS;
	output [`W_BURST-1:0] out_HBURST;
	output [`W_SIZE-1:0] out_HSIZE;
	output [`W_PROT-1:0] out_HPROT;
	output out_HMASTLOCK;
	output [W_ADDR-1:0] out_HADDR;
	output out_HWRITE;
	output [W_DATA-1:0] out_HWDATA;
   //control signals
   input start_dma; //Start the transfer
   input [BITS_TRANS-1:0] num_trans; //Number of word transfer
   input [W_ADDR-1:0] start_addr; //Base address of block transfer

   //output data
   output [W_DATA-1:0] data_o;
   output data_vld_o;
   output [BITS_TRANS-1:0] data_cnt_o; //counting the number of data output
   output data_last_o; //last output data of transfer

   input clk;
   input resetn;

//------------------------------------------------------------------------------
// Internal Signal declarations
//------------------------------------------------------------------------------
   //FSM
   //logic [3:0] state, next_state;
   
   localparam ST_IDLE = 0,
         ST_START = 1,
         ST_ADDR_PHASE = 2,
         ST_DATA_PHASE = 3;
   reg [1:0] state, next_state;

   reg [BITS_TRANS-1:0] data_cnt;
   reg data_cnt_inc, data_cnt_clr;
   reg [W_ADDR-1:0] req_addr;
   reg req_addr_inc;

   reg [`W_BURST-1:0] req_burst;
   reg [4:0] req_burst_size;
   reg [3:0] burst_cnt;  //Maximum is 16-beat burst
   reg burst_cnt_inc, burst_cnt_clr;
   reg ld_trans;
   wire trans_req_ready;  //unused
   wire done_beat;
   reg done_beat_d;
   wire done_trans;
	reg done_trans_d; //unused, same as done_beat
   reg [BITS_TRANS-1:0] num_trans_d;
   
   //Delayed AHB signals for better timing
   reg hreadyD;
   reg [W_DATA-1:0] hrdataD;
   wire gt_burst, gt_burst_div2, gt_burst_div4;

//------------------------------------------------------------------------------
// Main body of code
//------------------------------------------------------------------------------
   //Decide the burst size
   //Burst size need to assure that the incrementing burst does not cross 1KB
   //boundary!
   generate
   if(N_BURST_SIZE == 16) begin: burst_16
      assign gt_burst = |num_trans[BITS_TRANS-1:W_BURST_SIZE];
      assign gt_burst_div2 = |num_trans[BITS_TRANS-1:W_BURST_SIZE-1];
      assign gt_burst_div4 = |num_trans[BITS_TRANS-1:W_BURST_SIZE-2];

      always @(posedge clk or negedge resetn) begin
         if(~resetn) begin
            req_burst <= `BURST_SINGLE;
            req_burst_size <= 1;
         end
         //For simplicity, assume that transfer is composed of bursts >=4 only
         else if(start_dma) begin
            //if(start_addr[BOUNDARY_1KB-1:2] + N_BURST_SIZE <= 9'h256) begin
            if(~(&start_addr[9:W_BURST_SIZE+2]) && gt_burst) begin
               req_burst <= USE_BURST_TYPE; //incr16
               req_burst_size <= N_BURST_SIZE;
            end
            else if(~(&start_addr[9:W_BURST_SIZE+1]) && 
                                           ~gt_burst && gt_burst_div2) begin
               req_burst <= USE_BURST_TYPE - 2; //incr8
               req_burst_size <= N_BURST_SIZE/2;
            end
            else if((&start_addr[9:W_BURST_SIZE]) &&
                                           ~gt_burst_div2 && gt_burst_div4) begin
               req_burst <= USE_BURST_TYPE - 4; //incr4
               req_burst_size <= N_BURST_SIZE/4;
            end
            else begin
               req_burst <= `BURST_SINGLE; 
               req_burst_size <= 1;
            end
         end
         else if(done_trans_d) begin //data_cnt always > 0 here
            //not 9'h255, does not work
            if((req_addr[9:2] + N_BURST_SIZE <= 255 || &req_addr[9:2]) && 
                                   (data_cnt + N_BURST_SIZE < num_trans_d)) begin
               req_burst <= USE_BURST_TYPE; //incr16
               req_burst_size <= N_BURST_SIZE;
            end
            else if((req_addr[9:2] + N_BURST_SIZE/2 <= 255) && 
                                   (data_cnt + N_BURST_SIZE/2 < num_trans_d)) begin
               req_burst <= USE_BURST_TYPE-2; //incr8
               req_burst_size <= N_BURST_SIZE/2;
            end
            else if((req_addr[9:2] + N_BURST_SIZE/4 <= 255) && 
                                   (data_cnt + N_BURST_SIZE/4 < num_trans_d)) begin
               req_burst <= USE_BURST_TYPE-4; //incr4
               req_burst_size <= N_BURST_SIZE/4;
            end
            else begin
               req_burst <= `BURST_SINGLE; 
               req_burst_size <= 1;
            end
         end
      end
   end
   else if(N_BURST_SIZE==8) begin: burst_8
      assign gt_burst = |num_trans[BITS_TRANS-1:W_BURST_SIZE];
      assign gt_burst_div2 = |num_trans[BITS_TRANS-1:W_BURST_SIZE-1];

      always @(posedge clk or negedge resetn) begin
         if(~resetn) begin
            req_burst <= `BURST_SINGLE;
            req_burst_size <= 1;
         end
         //For simplicity, assume that transfer is composed of bursts >=4 only
         else if(start_dma) begin
            //if(start_addr[BOUNDARY_1KB-1:2] + N_BURST_SIZE <= 9'h256) begin
            if(~(&start_addr[9:W_BURST_SIZE+2]) && gt_burst) begin
               req_burst <= USE_BURST_TYPE; //incr16
               req_burst_size <= N_BURST_SIZE;
            end
            else if(~(&start_addr[9:W_BURST_SIZE+1]) && 
                                           ~gt_burst && gt_burst_div2) begin
               req_burst <= USE_BURST_TYPE - 2; //incr8
               req_burst_size <= N_BURST_SIZE/2;
            end
            else begin
               req_burst <= `BURST_SINGLE; 
               req_burst_size <= 1;
            end
         end
         else if(done_trans_d) begin //data_cnt always > 0 here
            //not 9'h255, does not work
            if((req_addr[9:2] + N_BURST_SIZE <= 255 || &req_addr[9:2]) && 
                                   (data_cnt + N_BURST_SIZE < num_trans_d)) begin
               req_burst <= USE_BURST_TYPE; //incr16
               req_burst_size <= N_BURST_SIZE;
            end
            else if((req_addr[9:2] + N_BURST_SIZE/2 <= 255) && 
                                   (data_cnt + N_BURST_SIZE/2 < num_trans_d)) begin
               req_burst <= USE_BURST_TYPE-2; //incr8
               req_burst_size <= N_BURST_SIZE/2;
            end
            else begin
               req_burst <= `BURST_SINGLE; 
               req_burst_size <= 1;
            end
         end
      end
   end
   endgenerate

   //Latch the number of transfer
   always @(posedge clk or negedge resetn)
      if(!resetn) num_trans_d <= 'h0;
      else if(start_dma) num_trans_d <= num_trans;

   //Delay signals
   always @(posedge clk) hrdataD <= HRDATA;
   always @(posedge clk or negedge resetn)
      if(!resetn)    hreadyD <= 1'b0;
      else           hreadyD <= HREADY;

   always @(posedge clk or negedge resetn)
      if(!resetn) done_beat_d <= 1'b0;
      else        done_beat_d <= done_beat;

   always @(posedge clk or negedge resetn)
      if(!resetn) done_trans_d <= 1'b0;
      else        done_trans_d <= done_trans;
   //assign hrdataD = HRDATA;
   //assign hreadyD = HREADY;
   //assign done_beat_d = done_beat;
   //assign done_trans_d = done_trans;

   always @(posedge clk or negedge resetn)
      if(!resetn) data_cnt <= 0;
      else if(data_cnt_clr)   data_cnt <= 0;
      else if(data_cnt_inc)   data_cnt <= data_cnt + 1;

   always @(posedge clk or negedge resetn)
      if(!resetn) req_addr <= 'h0;
      else if(start_dma) req_addr <= start_addr;
      else if(req_addr_inc)   req_addr <= req_addr + 'h4;
      //else if(req_addr_inc)   req_addr <= req_addr + {req_burst_size,2'b0};

   always @(posedge clk or negedge resetn)
      if(!resetn) burst_cnt <= 'h0;
      else if(burst_cnt_clr) burst_cnt <= 'h0;
      else if(burst_cnt_inc) burst_cnt <= burst_cnt + 1;

   always @(posedge clk or negedge resetn)
      if(~resetn)
         state <= ST_IDLE;
      else state <= next_state;
   //FSM
   always@(*) begin
		next_state = state;
		ld_trans = 1'b0;
		req_addr_inc = 1'b0;
		data_cnt_inc = 1'b0;
		data_cnt_clr = 1'b0;
		burst_cnt_inc = 1'b0;
		burst_cnt_clr = 1'b0;
		case(state) 
		 default: next_state = ST_IDLE;
		 ST_IDLE: begin
			if(start_dma) begin
			   next_state = ST_ADDR_PHASE;
			end
		 end
		 ST_ADDR_PHASE: begin
			if(hreadyD) begin
			   ld_trans = 1'b1;
			   next_state = ST_DATA_PHASE;
			end
		 end
		 ST_DATA_PHASE: begin
			if(hreadyD && done_beat_d) begin
			   if(burst_cnt < req_burst_size-1) begin
				  burst_cnt_inc = 1'b1;
				  data_cnt_inc = 1'b1;
				  req_addr_inc = 1'b1;
			   end
			   else begin
				  burst_cnt_clr = 1'b1;
				  req_addr_inc = 1'b1;
				  if(data_cnt < num_trans_d-1) begin
					 data_cnt_inc = 1'b1;
					 next_state = ST_ADDR_PHASE;
				  end
				  else begin
					 data_cnt_clr = 1'b1;
					 next_state = ST_IDLE;
				  end
			   end
			end
		 end
		endcase
   end
   //output
   assign data_o = done_beat_d ? hrdataD : 'h0;
   assign data_vld_o = done_beat_d;
   assign data_cnt_o = data_cnt;
   assign data_last_o = data_cnt_clr;

   //---------------------------------------------------------------------------
	// ahb_lite_transactor
	//---------------------------------------------------------------------------
	ahb_lite_transactor #(	
	   .W_ADDR(W_ADDR), .W_DATA(W_DATA))
	u_ahb_trans(
      .HCLK(clk),
      .HRESETn(resetn),
      .HREADY(HREADY),
      .HRESP(HRESP),
      .HRDATA(HRDATA),
      .out_HTRANS(out_HTRANS),
      .out_HBURST(out_HBURST),
      .out_HSIZE(out_HSIZE),
      .out_HPROT(out_HPROT),
      .out_HMASTLOCK(out_HMASTLOCK),
      .out_HADDR(out_HADDR),
      .out_HWRITE(out_HWRITE),
      .out_HWDATA(out_HWDATA),
      .ld_trans(ld_trans),
      .last_trans(1'b0),
      //.in_req_burst(`BURST_SINGLE),
      .in_req_burst(req_burst),
      .in_req_size(`SIZE_WORD),
      .in_req_prot(DEF_HPROT),
      .in_req_lock(1'b0),
      .in_req_write(1'b0),
      .in_req_addr(req_addr),
      .in_req_wdata(0),
      .out_trans_req_ready(trans_req_ready),
      .out_done_beat(done_beat),
      .out_done_trans(done_trans),
      .out_resp_rdata()  // CtoR +
   );
	//------------------------------------------------------------------------
endmodule


