`timescale 1ns / 1ps
module mul_tb;
reg clk;
reg rstn;
reg [7:0] w, x;
wire[15:0] y;
//-------------------------------------------
// DUT: multiplier
//-------------------------------------------
mul u_mul(
./*input 	    */clk(clk), 
./*input [ 7:0] */w(w), 
./*input [ 7:0] */x(x), 
./*output[15:0] */y(y)
);

// Clock
parameter CLK_PERIOD = 10;	//100MHz
initial begin
	clk = 1'b1;
	forever #(CLK_PERIOD/2) clk = ~clk;
end
integer i;
// Test cases
initial begin
	rstn = 1'b0;			// Reset, low active	
	w = 0;
	x = 0;
	i = 0; 
	#(4*CLK_PERIOD) rstn = 1'b1;
	
	#(4*CLK_PERIOD) 
	for(i = 0; i<16; i=i+1) begin
        @(posedge clk) 		
           w <= 8'd4;
           x <= i;	
	end

	#(CLK_PERIOD) 
	@(posedge clk) 		
	   w <= 8'd0;
	   x <= 8'd0;	   		   
end
endmodule
