`timescale 1ns/1ps

`define CLOCK_PERIOD 10	//100MHz
module counter_tb;

reg clk;
reg [5:0] din;
reg ena;
wire oflag;
wire [5:0] cnt;   // added for waveform

// Counter design under test
counter 
u_counter(.clk(clk), 
		.din(din), 
		.ena(ena), 
		.oflag(oflag));

assign cnt = u_counter.cnt;   // added for waveform

// Clock
initial begin
   clk = 0;
   forever #(`CLOCK_PERIOD/2) clk = ~clk;
end

// Test case
initial begin
	din = 6'd0;
	ena = 1'd0;
	
	
	// Count from 8 to 0
	#(`CLOCK_PERIOD * 5) @(posedge clk)	// Wait 5 cycles and set counter inputs 
						din = 6'd8;		
						ena = 1'd1;	
	#(`CLOCK_PERIOD) 	@(posedge clk) 		
						ena = 1'd0;
							
	// Count from 16 to 0
	#(`CLOCK_PERIOD * 16) @(posedge clk) // Wait 16 cycles and then set counter inputs 
						din = 6'd16;		
						ena = 1'd1;	
	#(`CLOCK_PERIOD) 	@(posedge clk) 
						ena = 1'd0;										
end

endmodule