`timescale 1ns/1ps
module mac_tb;
parameter WI = 8;
parameter N  = 16;
parameter WN = $clog2(N);
parameter WO = 2*(WI+1) + WN;
reg clk;
reg rstn;
reg vld_i;
reg [WI*N-1:0] win; 
reg [WI*N-1:0] din; 
wire[WO-1:0] acc_o;
wire vld_o;

reg [WI-1:0] weight_block [0:N-1];
reg [WI-1:0] activation_block [0:N-1];
// DUT
mac u_mac(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input 			*/vld_i(vld_i), 
./*input [N*WI-1:0] */win(win), 
./*input [N*WI-1:0] */din(din), 
./*output[WO-1:0] 	*/acc_o(acc_o),
./*output reg 		*/vld_o(vld_o)
);

// Clock
parameter CLK_PERIOD = 10;	//100MHz
initial begin
	clk = 1'b1;
	forever #(CLK_PERIOD/2) clk = ~clk;
end

integer i;

// Data preparation
initial begin
	for(i = 0; i <N; i = i +1) begin
		activation_block[i] = i;
		weight_block[i] = 1;
	end
end

// Test cases
initial begin
	rstn = 1'b0;			// Reset, low active
	vld_i = 1'b0;
	win = 0;
	din = 0;
	
	#(4*CLK_PERIOD) rstn = 1'b1;
	
	//
	#(4*CLK_PERIOD)
	@(posedge clk) 		// Fixing the timing issue in waveform: Use a non-blocking assignment			
	for(i = 0; i < N; i = i+1) begin
		//@(posedge clk) 		// Fixing the timing issue in waveform
			vld_i <= 1'b1;
			win[(i*WI)+:WI] <= weight_block[i];
			din[(i*WI)+:WI] <= activation_block[i];
	end
	
	#(CLK_PERIOD)	
	@(posedge clk)	// Fixing the timing issue in waveform: Use a non-blocking assignment
		vld_i <= 1'b0;
		win <= 0;
		din <= 0;
end

endmodule
