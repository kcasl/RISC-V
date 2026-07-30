`timescale 1ns/1ps

module mac_kern_tb;
parameter WI = 8;
parameter N  = 16;
parameter WN = $clog2(N);
parameter WO = 2*(WI+1) + WN;
localparam CONV3x3_DELAY 	= 9;
localparam CONV3x3_DELAY_W 	= 4;	
parameter W_DATA = 128;

parameter N_DELAY = 1;

reg clk;
reg rstn;
reg vld_i;
reg [WI*N-1:0] win; 
reg [WI*N-1:0] din; 
wire[WO+CONV3x3_DELAY_W:0] acc_o;
wire vld_o;

reg is_conv3x3;

// DUT
mac_kern u_mac_kern(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input 			*/is_conv3x3(is_conv3x3),
./*input 			*/vld_i(vld_i), 
./*input [N*WI-1:0] */win(win), 
./*input [N*WI-1:0] */din(din), 
./*output[WO-1:0] 	*/acc_o(acc_o),
./*output reg 		*/vld_o(vld_o)
);

// Clock
parameter CLK_PERIOD = 10;	//100MHz
initial begin
	clk = 1'b0;
	forever #(CLK_PERIOD/2) clk = ~clk;
end
 

// Test cases
initial begin
	rstn = 1'b0;			// Reset, low active
	vld_i = 1'b0;
	win = 0;
	din = 0;
	is_conv3x3 = 1'b0;
	
	#(4*CLK_PERIOD) rstn = 1'b1;
	
	//
	// Test case 1: test conv1x1
	is_conv3x3 = 1'b0;	
	@(posedge clk)
					vld_i = 1'b1;
					win = {16{8'd0 }};	//1
					din = {16{8'd1}};	//1
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	//1
					din = {16{8'd2}};	//2
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	//1
					din = {16{8'd3}};	//3	
	@(posedge clk)	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd4}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd5}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd6}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd7}};	
	@(posedge clk)	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd8}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd9}};	
	@(posedge clk)	
					vld_i = 1'b0;

	//-----------------------------------------------------
	// Test case 2: test conv3x3
	//-----------------------------------------------------
	#(4*CLK_PERIOD) 	
	@(posedge clk)	is_conv3x3 = 1'b1;
					vld_i = 1'b1;
					win = {16{8'd0 }};	//1
					din = {16{8'd1}};	//1
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	//1
					din = {16{8'd2}};	//2
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	//1
					din = {16{8'd3}};	//3	
	@(posedge clk)	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd4}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd5}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd6}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd7}};	
	@(posedge clk)	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd8}};	
	@(posedge clk) 	
					vld_i = 1'b1;
					win = {16{8'd0 }};	
					din = {16{8'd9}};	
	@(posedge clk)	
					vld_i = 1'b0;
end

endmodule
