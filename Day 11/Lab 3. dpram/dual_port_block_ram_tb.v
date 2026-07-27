`timescale 1ns / 100ps

module dual_port_block_ram_tb;

parameter IN_PIXEL_W = 8;
parameter IN_PIXEL_NUM = 16;

parameter W_DATA = 128;
parameter N_CELL = 2192;
parameter W_CELL = $clog2(N_CELL);
parameter FILENAME = "simSR.hex";
parameter N_DELAY = 1;

reg clk;   				// clock input
reg ena; 				// primary enable
reg wea   ; 			// primary synchronous write enable
reg [W_CELL-1:0] addra;	// address for read/write
reg enb;				// read port enable
reg [W_CELL-1:0] addrb;	// address for read
reg [W_DATA-1:0] dia;	// primary data input
wire [W_DATA-1:0] dob;	// primary data output

reg [IN_PIXEL_W-1:0] weight_store [0:IN_PIXEL_NUM-1];
reg [IN_PIXEL_W:0]	 weight [0:IN_PIXEL_NUM-1];

//-----------------------------------------------------
// Component
//-----------------------------------------------------
dual_port_block_ram #(.FILENAME(FILENAME), .W_DATA(W_DATA), .W_CELL(W_CELL),.N_CELL(N_CELL))
u_dual_port_block_ram(
   .clk   (clk   ),
   .ena   (ena   ), 
   .wea   (wea   ), 
   .addra (addra ), 
   .enb   (enb   ),	
   .addrb (addrb ), 
   .dia   (dia   ), 
   .dob   (dob   )  
);

// Clock
parameter CLOCK_PERIOD = 10; 	//100MHz
initial begin
	clk = 1'b0;
	forever #(CLOCK_PERIOD/2) clk = ~clk;
end

integer i;

// load 16 conv. filters of layer 1 from dual_port_block_ram
initial begin
	
	// initialization
	ena = 0; 			
	wea = 0  ; 			
	addra = 0;
	enb = 0; 				
	addrb  = 0;
	dia   = 0;
	
	// set signal for dual_port_block_ram access
	//for(/* Insert your code */) begin
	//	#(4*CLOCK_PERIOD) 	enb = 1'b1;
	//						/* Insert your code */
	//	#(CLOCK_PERIOD) 	enb = 1'b0;					
	//end

end

//-----------------------------------------------------
// Visualize stored weights and weights
//-----------------------------------------------------
integer j;

always@(posedge clk) begin
	if(enb) begin
		// TODO: set 'weight_store' and 'weight'
		/* Insert your code */
		
		/********************/
	end
end

endmodule
