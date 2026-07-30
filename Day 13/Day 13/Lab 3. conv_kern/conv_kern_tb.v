`timescale 1ns/1ps

module conv_kern_tb;
parameter WI = 8;
parameter N  = 16; 
parameter WN = $clog2(N);
parameter WO = 2*(WI+1) + WN;
parameter PARAM_BITS 	= 16;
parameter WEIGHT_BITS 	= 8;
parameter ACT_BITS		= 8;
parameter DATA_BITS 	= WO;

localparam CONV3x3_DELAY 	= 9;
localparam CONV3x3_DELAY_W 	= 4;

reg clk;
reg rstn;
reg is_last_layer;
reg [PARAM_BITS-1:0] scale;
reg [PARAM_BITS-1:0] bias;
reg [2:0] act_shift;
reg [4:0] bias_shift;
reg is_conv3x3;			//0: 1x1, 1:3x3
reg vld_i; 
reg [N*WI-1:0] win; 
reg [N*WI-1:0] din; 
wire [ACT_BITS-1:0] acc_o;
wire vld_o;

// DUT
conv_kern u_conv_kern(
./*input 				 */clk(clk),
./*input 				 */rstn(rstn),
./*input 				 */is_last_layer(is_last_layer),
./*input [PARAM_BITS-1:0]*/scale(scale),
./*input [PARAM_BITS-1:0]*/bias(bias),
./*input [2:0] 			 */act_shift(act_shift),
./*input [4:0] 			 */bias_shift(bias_shift),
./*input 				 */is_conv3x3(is_conv3x3),			//0: 1x1, 1:3x3
./*input 				 */vld_i(vld_i), 
./*input [N*WI-1:0] 	 */win(win), 
./*input [N*WI-1:0] 	 */din(din),
./*output [ACT_BITS-1:0] */acc_o(acc_o),
./*output 				 */vld_o(vld_o)

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
	is_last_layer = 1'b0;
	scale = 16'd103;
	bias = 16'd8066;
	bias_shift = 9;
	act_shift = 7;	
	#(4*CLK_PERIOD) rstn = 1'b1;
	
	// First layer, channel 2:
	win[0*WI+:WI] = 8'd69;
	win[1*WI+:WI] = 8'd181;
	win[2*WI+:WI] = 8'd209;
	win[3*WI+:WI] = 8'd19;
	win[4*WI+:WI] = 8'd128;
	win[5*WI+:WI] = 8'd95;
	win[6*WI+:WI] = 8'd221;
	win[7*WI+:WI] = 8'd121;
	win[8*WI+:WI] = 8'd8;
	// Test case 1: test conv1x1
	is_conv3x3 = 1'b0;	
	#(4*CLK_PERIOD) 	
	@(posedge clk) 		
					vld_i = 1'b1;
					din[0*WI+:WI] = 8'd0;
					din[1*WI+:WI] = 8'd0;
					din[2*WI+:WI] = 8'd0;
					din[3*WI+:WI] = 8'd0;
					din[4*WI+:WI] = 8'd42;
					din[5*WI+:WI] = 8'd69;
					din[6*WI+:WI] = 8'd0;
					din[7*WI+:WI] = 8'd105;
					din[8*WI+:WI] = 8'd42;
	@(posedge clk) 	vld_i = 1'b1;
					din[0*WI+:WI] = 8'd0;
					din[1*WI+:WI] = 8'd0;
					din[2*WI+:WI] = 8'd0;
					din[3*WI+:WI] = 8'd42;
					din[4*WI+:WI] = 8'd69;
					din[5*WI+:WI] = 8'd91;
					din[6*WI+:WI] = 8'd105;
					din[7*WI+:WI] = 8'd42;
					din[8*WI+:WI] = 8'd56;
	@(posedge clk) 		vld_i = 1'b1;
					din[0*WI+:WI] = 8'd0;
					din[1*WI+:WI] = 8'd0;
					din[2*WI+:WI] = 8'd0;
					din[3*WI+:WI] = 8'd69;
					din[4*WI+:WI] = 8'd91;
					din[5*WI+:WI] = 8'd99;
					din[6*WI+:WI] = 8'd42;
					din[7*WI+:WI] = 8'd56;
					din[8*WI+:WI] = 8'd84;	
	@(posedge clk) 	vld_i = 1'b1;
					//din[0*WI+:WI] = /* Insert your code*/;
					//din[1*WI+:WI] = /* Insert your code*/;
					//din[2*WI+:WI] = /* Insert your code*/;
					//din[3*WI+:WI] = /* Insert your code*/;
					//din[4*WI+:WI] = /* Insert your code*/;
					//din[5*WI+:WI] = /* Insert your code*/;
					//din[6*WI+:WI] = /* Insert your code*/;
					//din[7*WI+:WI] = /* Insert your code*/;
					//din[8*WI+:WI] = /* Insert your code*/;	
	@(posedge clk) 	vld_i = 1'b1;
					//din[0*WI+:WI] = /* Insert your code*/;
					//din[1*WI+:WI] = /* Insert your code*/;
					//din[2*WI+:WI] = /* Insert your code*/;
					//din[3*WI+:WI] = /* Insert your code*/;
					//din[4*WI+:WI] = /* Insert your code*/;
					//din[5*WI+:WI] = /* Insert your code*/;
					//din[6*WI+:WI] = /* Insert your code*/;
					//din[7*WI+:WI] = /* Insert your code*/;
					//din[8*WI+:WI] = /* Insert your code*/;	
	@(posedge clk) 	vld_i = 1'b1;
					//din[0*WI+:WI] = /* Insert your code*/;
					//din[1*WI+:WI] = /* Insert your code*/;
					//din[2*WI+:WI] = /* Insert your code*/;
					//din[3*WI+:WI] = /* Insert your code*/;
					//din[4*WI+:WI] = /* Insert your code*/;
					//din[5*WI+:WI] = /* Insert your code*/;
					//din[6*WI+:WI] = /* Insert your code*/;
					//din[7*WI+:WI] = /* Insert your code*/;
					//din[8*WI+:WI] = /* Insert your code*/;							
	@(posedge clk) 		vld_i = 1'b0;
end

endmodule
