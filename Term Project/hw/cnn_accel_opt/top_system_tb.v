`timescale 1ns / 1ps
`include "amba_ahb_h.v"
`include "map.v"

// [OPT] Packed 4px/word input image
`define INPUTFILENAME		"./img/butterfly_32bit_reorder.hex"
module top_system_tb;
parameter W_ADDR=32;
parameter W_DATA=32;

// AHB signals			
localparam N_REGS = 21;
localparam W_REGS = $clog2(N_REGS);
parameter WB_DATA = 4;
parameter W_WB_DATA = 2;
	
parameter WIDTH 	= 128,
		HEIGHT 	= 128,		
		START_UP_DELAY = 420,	// [OPT] weights(144)+linebuf preload(256)+margin
		VSYNC_CYCLE	= 3,
		VSYNC_DELAY = 3,
		HSYNC_DELAY = 2,		// [OPT] was 160; line shift is 1-cycle (prefetch during DATA)
		FRAME_TRANS_DELAY = 200,
		FRAME_SIZE = WIDTH * HEIGHT;
localparam W_SIZE  = 12;					// Max 4K QHD (3840x1920).
localparam W_FRAME_SIZE  = 2 * W_SIZE + 1;	// Max 4K QHD (3840x1920).
localparam W_DELAY = 12;

// [OPT] External SRAM holds packed image (FRAME/4 words)
parameter N_WORD = WIDTH * HEIGHT / 4;
parameter W_WORD = $clog2(N_WORD);
parameter EN_LOAD_INIT_FILE = 1'b1;
parameter INIT_FILE = "img/butterfly_32bit_reorder.hex";

parameter Ti = 16;	// Each CONV kernel do 16 multipliers at the same time	
parameter To = 16;	// Run 16 CONV kernels at the same time
parameter N  = 16;
parameter N_LAYER 		= 3;
parameter N_CELL  		= 304;	// [OPT] real weight words
parameter N_CELL_PARAM	= N_LAYER * (To);
parameter W_CELL 		= $clog2(N_CELL);
parameter W_CELL_PARAM 	= $clog2(N_CELL_PARAM);	
// Inputs
reg HCLK;
reg HRESETn;

reg [W_SIZE-1 :0] 		q_width;
reg [W_SIZE-1 :0] 		q_height;
reg [W_DELAY-1:0] 		q_start_up_delay;
reg [W_DELAY-1:0] 		q_hsync_delay;
reg [W_FRAME_SIZE-1:0] 	q_frame_size;
reg [3:0]				q_layer_index;
reg 					q_layer_done;
reg [31:0]  q_layer_config;
reg [2:0] 	q_act_shift   [0:N_LAYER-1];
reg [4:0] 	q_bias_shift  [0:N_LAYER-1];
reg 	  	q_is_conv3x3  [0:N_LAYER-1];
reg 		q_is_first_layer;
reg 		q_is_last_layer;
reg         is_conv3x3;
reg [19:0] 	base_addr_weight;
reg [11:0] 	base_addr_param;

reg [W_DATA-1:0] rdata;
reg [W_ADDR-1:0] i;
reg image_load_done;
integer idx;

wire sram_en, sram_we;			
wire [W_WORD-1:0] sram_addr;
wire [W_DATA-1:0] sram_wdata;
wire [W_DATA-1:0] sram_rdata;
//---------------------------------------------------------------
// Top system
//---------------------------------------------------------------
top_system
u_top_system(      
	.HCLK(HCLK),
	.HRESETn(HRESETn),
	.sram_en(sram_en),
	.sram_we(sram_we),
	.sram_addr(sram_addr),
	.sram_wdata(sram_wdata),	
	.sram_rdata(sram_rdata)	
);
// SRAM 
bram
#(.W_DATA(W_DATA),
.N_WORD(N_WORD),
.W_WORD(W_WORD),
.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
.INIT_FILE(INIT_FILE))
u_memory(
	.clk(HCLK),
	.en(sram_en),
	.we(sram_we),
	.addr(sram_addr),
	.din(sram_wdata),	
	.dout(sram_rdata)
);
//---------------------------------------------------------------
// Test vectors
//---------------------------------------------------------------
// Clock
parameter p = 10;	//100MHz
initial begin
	HCLK = 1'b0;
	forever #(p/2) HCLK = ~HCLK;
end

initial begin
	// Initialize Inputs
	HRESETn = 0;
	q_width 			= WIDTH;
	q_height 			= HEIGHT;
	q_start_up_delay 	= START_UP_DELAY;
	q_hsync_delay 		= HSYNC_DELAY;
	q_frame_size 		= FRAME_SIZE;
	q_layer_index		= 4'd0;
	q_layer_done		= 1'b0;
	q_is_first_layer	= 1'b0;
	q_is_last_layer		= 1'b0;
	q_layer_config		= 32'h0;
	is_conv3x3          = 0;
	// Define Network's parameters
	q_bias_shift[0] = 9 ; q_act_shift[0] = 7; q_is_conv3x3[0] = 0;
	q_bias_shift[1] = 17; q_act_shift[1] = 7; q_is_conv3x3[1] = 1;
	q_bias_shift[2] = 17; q_act_shift[2] = 7; q_is_conv3x3[2] = 1;
	// Loop/Layer index
	idx = 0;
	
	// Weight/bias/Scale base addresses
	base_addr_weight 	= 0;
	base_addr_param		= 0;	
	
	// Initialize RISCV dummy core
	u_top_system.u_riscv_dummy.task_AHBinit();
	
	// Memory
	rdata = 0;
	i = 0;
	image_load_done = 0;
		
	#(p/2) HRESETn = 1;	
	//*******************************************************************************************************
	// Slow loading
	// 1. CPU reads data in Memory
	// 2. CPU stores data to the input buffer of the CNN accelerator
	//*******************************************************************************************************	
	//#(8*p) 	
	//// Load data to the frame buffer of LCD drive
	//for(i = 0; i < WIDTH * HEIGHT; i=i+1) begin
	//	#(4*p) @(posedge HCLK) u_top_system.u_riscv_dummy.task_AHBread( `RISCV_MEMORY_BASE_ADDR + 4*i, rdata );     // Read from SRAM
	//	#(4*p) @(posedge HCLK) u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_INPUT_IMAGE	+ (i << (WB_DATA + W_REGS)), rdata );	
	//end	
	//$display("T=%03t ns: SLOW loading the image by CPU is DONE!!!\n", $realtime/1000);		
	
	//*******************************************************************************************************
	// FAST loading: CPU enables CNN Accelerator to become a bus Master
	//*******************************************************************************************************
	#(100*p) 	
	#(4*p) @(posedge HCLK) u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_INPUT_IMAGE_BASE, `RISCV_MEMORY_BASE_ADDR);	
	#(4*p) @(posedge HCLK) u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_INPUT_IMAGE_LOAD, 1);	// Start loading the input
	#(4*p) @(posedge HCLK) u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_INPUT_IMAGE_LOAD, 0);	
	
	while(!image_load_done) begin
		#(128*p) @(posedge HCLK)  u_top_system.u_riscv_dummy.task_AHBread(`CNN_ACCEL_INPUT_IMAGE_LOAD,image_load_done);
	end
	$display("T=%03t ns: FAST loading the image by DMA is DONE!!!\n", $realtime/1000);		
	
	//*******************************************************************************************************
	// CNN Accelerator configuration
	//*******************************************************************************************************	
	#(100*p) 	
	#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_FRAME_SIZE	, q_frame_size 		);
	#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_WIDTH_HEIGHT, {q_height&16'hFFFF,q_width&16'hFFFF});
	#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_DELAY_PARAMS, {q_hsync_delay,q_start_up_delay});	
			
	//*******************************************************************************************************
	// Loop
	//*******************************************************************************************************
	//idx = 0; 	// Layer 1
	for(idx = 0; idx <N_LAYER; idx=idx+1) begin
		q_layer_index 		= idx;
		q_is_last_layer 	= (idx == N_LAYER-1)?1'b1:1'b0;
		q_is_first_layer	= (idx == 0) ? 1'b1: 1'b0;
		is_conv3x3          = q_is_conv3x3[idx];
		// L1: short VSYNC (16 weights). L2/L3: weights(144)+3-line preload(384)
		q_start_up_delay	= q_is_first_layer ? 12'd160 : 12'd420;
		q_hsync_delay		= 12'd2;
		q_layer_config 		= {q_act_shift[idx], q_bias_shift[idx], q_layer_index, q_is_last_layer, is_conv3x3, q_is_last_layer, q_is_first_layer};			
		#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_DELAY_PARAMS, {q_hsync_delay,q_start_up_delay});
		#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_BASE_ADDRESS, {base_addr_param&12'hFFF,base_addr_weight&20'hFFFFF});		
		#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_LAYER_CONFIG, q_layer_config);				
		// Start a frame
		#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_LAYER_START	, 1'b1 );	
		#(4*p) @(posedge HCLK) 	u_top_system.u_riscv_dummy.task_AHBwrite(`CNN_ACCEL_LAYER_START	, 1'b0 );
		
		// Polling
		while(!q_layer_done) begin
			#(128*p) @(posedge HCLK)  u_top_system.u_riscv_dummy.task_AHBread(`CNN_ACCEL_LAYER_DONE,q_layer_done);
		end
		#(128*p) @(posedge HCLK) $display("T=%03t ns: Layer %0d done!!!\n", $realtime/1000, idx+1);
		// Reset q_layer_done 
		q_layer_done = 0;
		
		// Update the base addresses
		if(q_is_conv3x3[idx]) begin
			base_addr_weight 	= base_addr_weight 	+ (Ti*To*9)/N;
			base_addr_param		= base_addr_param 	+ To;			
		end
		else begin
			base_addr_weight 	= base_addr_weight 	+ To;
			base_addr_param		= base_addr_param 	+ To;		
		end
	
	end

	// [OPT] Report end-to-end time for S_overall (t0=3930us, s0=4280Kbits)
	#(128*p) @(posedge HCLK) begin
		$display("========================================");
		$display("OPT DONE: t = %0d us (sim time %0t)", $realtime/1000, $realtime);
		$display("Buffer s (Kbits) = 128(in)+2048(fmap)+48(linebuf)+16(lb_next)+39(w)+1.5(p) ~= 2280.5");
		$display("S_overall = (3930/t)*(4280/s); see OPT_RESULTS.txt");
		$display("========================================");
	end
	#(128*p) @(posedge HCLK) $stop;
end


endmodule