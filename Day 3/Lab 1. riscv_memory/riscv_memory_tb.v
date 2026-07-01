`timescale 1ns/1ps


module riscv_memory_tb ();

	reg reset_i;
	reg clk_i;

	// Input instruction
	reg  [31:0] iaddr_i;
	reg  	       ird_i;
	reg [31:0] daddr_i;
	reg [31:0] dwdata_i;
	reg [1:0]   dsize_i;
	reg	      drd_i;
	reg 	      dwr_i;
	// Outputs
	wire [31:0] irdata_o;
	wire [31:0] drdata_o;

localparam
  SIZE_BYTE = 2'd0,
  SIZE_HALF = 2'd1,
  SIZE_WORD = 2'd2;
  
	// Memory module
	riscv_memory 
	u_memory (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.iaddr_i(iaddr_i),
		.ird_i(ird_i),
		.daddr_i(daddr_i),
		.dwdata_i(dwdata_i),
		.dsize_i(dsize_i),
		.drd_i(drd_i),
		.dwr_i(dwr_i),
		.irdata_o(irdata_o),
		.drdata_o(drdata_o)
	);



   // Clock and Reset
   parameter p=10;
   initial begin
   	clk_i = 1'b0;
   	forever #(p/2) clk_i = !clk_i;
   end

   // Test cases	
   initial
   begin:stimuli
		reset_i = 1'b0;	
		iaddr_i = 0;
		ird_i = 0;
		dsize_i=SIZE_WORD;
		#(4*p) reset_i = 1'b1;	

		#(4*p) 	iaddr_i = 32'h0;	
				ird_i = 1'b1;
		#(p)	ird_i = 1'b0;	
				$display("T=%03t ns: %h : %h\n",$realtime/1000, iaddr_i, irdata_o);
		#(4*p) 	iaddr_i = 32'h4;	
				ird_i = 1'b1;
		#(p)	ird_i = 1'b0;	
				$display("T=%03t ns: %h : %h\n",$realtime/1000, iaddr_i, irdata_o);
		#(4*p) 	iaddr_i = 32'h8;	
				ird_i = 1'b1;
		#(p)	ird_i = 1'b0;	
				$display("T=%03t ns: %h : %h\n",$realtime/1000, iaddr_i, irdata_o);
		#(4*p) 	iaddr_i = 32'hd;
				ird_i = 1'b1;
		#(p)	ird_i = 1'b0;	
				$display("T=%03t ns: %h : %h\n",$realtime/1000, iaddr_i, irdata_o);
		#(4*p) 	iaddr_i = 32'h10;
				ird_i = 1'b1;
		#(p)	ird_i = 1'b0;	
				$display("T=%03t ns: %h : %h\n",$realtime/1000, iaddr_i, irdata_o);
				
   end
endmodule

