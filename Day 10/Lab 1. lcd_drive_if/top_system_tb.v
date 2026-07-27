`timescale 1ns / 100ps
`include "amba_ahb_h.v"
`include "riscv_defines.v"
`include "map.v"
`timescale 1ns/1ns

`define INPUTFILENAME		"./img/kodim03.hex"
`define OUTPUTFILENAME		"./out/kodim03.bmp"
`define OUTPUTFILENAME_RCT	"./out/kodim03_ycbcr.bmp"	
module top_system_tb;
parameter W_ADDR=32;
parameter W_DATA=32;
parameter IMG_PIX_W = 8;

parameter WIDTH 	= 768,
		HEIGHT 	= 512,
		START_UP_DELAY = 100,
		VSYNC_CYCLE	= 3,
		VSYNC_DELAY = 3,
		HSYNC_DELAY = 160,
		FRAME_TRANS_DELAY = 200,
		DATA_COUNT = WIDTH * HEIGHT/2;
localparam W_SIZE  = 12;					// Max 4K QHD (3840x1920).
localparam W_FRAME_SIZE  = 2 * W_SIZE + 1;	// Max 4K QHD (3840x1920).
localparam W_DELAY = 12;		
// Inputs
reg HCLK;
reg HRESETn;

// Select signals
//reg sl_HSEL_alu;
//reg sl_HSEL_multiplier;
reg [3:0] alu_op_i;
reg [31:0] alu_a_i, alu_b_i;
reg [31:0] alu_p_o;

wire out_valid;
wire [IMG_PIX_W-1:0] out_r0, out_g0, out_b0, out_r1, out_g1, out_b1;

reg [W_SIZE-1 :0] q_width;
reg [W_SIZE-1 :0] q_height;
reg [W_DELAY-1:0] q_start_up_delay;
reg [W_DELAY-1:0] q_vsync_cycle;
reg [W_DELAY-1:0] q_vsync_delay;
reg [W_DELAY-1:0] q_hsync_delay;
reg [W_DELAY-1:0] q_frame_trans_delay;
reg [W_FRAME_SIZE-1:0] q_data_count;
reg q_br_mode;
reg [IMG_PIX_W-1:0] q_br_value;
reg q_start;
//---------------------------------------------------------------
// Components
//---------------------------------------------------------------
top_system u_top_system(      
	 .HRESETn(HRESETn)
	,.HCLK   (HCLK	 )
    ,/*output*/ .out_valid(out_valid)
    ,/*output [IMG_PIX_W-1:0]*/ .out_r0(out_r0)
    ,/*output [IMG_PIX_W-1:0]*/ .out_g0(out_g0)
    ,/*output [IMG_PIX_W-1:0]*/ .out_b0(out_b0)
    ,/*output [IMG_PIX_W-1:0]*/ .out_r1(out_r1)
    ,/*output [IMG_PIX_W-1:0]*/ .out_g1(out_g1)
    ,/*output [IMG_PIX_W-1:0]*/ .out_b1(out_b1)
	);

display_model #(.INFILE(`OUTPUTFILENAME))
u_display_model(
	./*input */HCLK(HCLK),
	./*input */HRESETn(HRESETn),
	./*input */RECON_VALID(out_valid),
    ./*input [7:0]  */DATA_RECON_R0(out_r0),
    ./*input [7:0]  */DATA_RECON_G0(out_g0),
    ./*input [7:0]  */DATA_RECON_B0(out_b0),
    ./*input [7:0]  */DATA_RECON_R1(out_r1),
    ./*input [7:0]  */DATA_RECON_G1(out_g1),
    ./*input [7:0]  */DATA_RECON_B1(out_b1),
	./*output 		*/DEC_DONE()
);	
	
//---------------------------------------------------------------
// Test vectors
//---------------------------------------------------------------
localparam p = 20;
initial begin
	HCLK = 0;
	forever #(p/2) HCLK = !HCLK;
end
initial begin
	// Initialize Inputs
	HCLK = 0;
	HRESETn = 0;
	alu_a_i = 0;
	alu_b_i = 0;
	alu_p_o = 0;	
	alu_op_i = 0;
	
	q_width 			= WIDTH;
	q_height 			= HEIGHT;
	q_start_up_delay 	= START_UP_DELAY;
	q_vsync_cycle 		= VSYNC_CYCLE;
	q_vsync_delay 		= VSYNC_DELAY;
	q_hsync_delay 		= HSYNC_DELAY;
	q_frame_trans_delay = FRAME_TRANS_DELAY;
	q_data_count 		= DATA_COUNT;
	q_start 			= 1'b1;
	q_br_mode			<= 1'b1;
	q_br_value			<= 8'h50;		
	u_top_system.u_riscv_dummy.task_AHBinit();
	
	#(p/2) HRESETn = 1;
	alu_a_i = 0;
	alu_b_i = 0;
	alu_p_o = 0;
	// No slave is selected.
	//sl_HSEL_alu = 1'b0;
	//sl_HSEL_multiplier = 1'b0;
	
	#(8*p) 
		//sl_HSEL_alu = 1'b1;
		//sl_HSEL_multiplier = 1'b0;	
	#(8*p) 
	       alu_a_i = 32'h0;
	       alu_b_i = 32'h0; 
	       alu_op_i = `ALU_SLT;		
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_ALU_A_I, alu_a_i);	// Write the first operand
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_ALU_B_I, alu_b_i);    // Write the second operand
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_ALU_OP_I, alu_op_i);  // Write the operation
	#(4*p) u_top_system.u_riscv_dummy.task_AHBread (`RISCV_REG_ALU_P_O, alu_p_o);     // Read the result
	
	#(8*p)
	       alu_a_i = 32'h8;
	       alu_b_i = 32'h8; 
	       alu_op_i = `ALU_ADD;		
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_ALU_A_I, alu_a_i);	// Write the first operand
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_ALU_B_I, alu_b_i);	// Write the second operand
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_ALU_OP_I, alu_op_i);	// Write the operation
	#(4*p) u_top_system.u_riscv_dummy.task_AHBread( `RISCV_REG_ALU_P_O, alu_p_o);	// Read the result
	
	
	#(8*p) 
		//sl_HSEL_alu = 1'b0;
		//sl_HSEL_multiplier = 1'b1;	
	#(8*p) 
	       alu_a_i = 32'h7;
	       alu_b_i = 32'h9; 
	       alu_op_i = `ALU_MULL;		
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_MUL_A_I, alu_a_i     );	 // Write the first operand
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_MUL_B_I, alu_b_i     );    // Write the second operand
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_MUL_A_SIGNED, alu_a_i);	 // Write the first operand
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_MUL_B_SIGNED, alu_b_i);    // Write the second operand	
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`RISCV_REG_MUL_OP_I, alu_op_i   );    // Write the operation
	#(4*p) u_top_system.u_riscv_dummy.task_AHBread( `RISCV_REG_MUL_P_O_LOW, alu_p_o );     // Read the result
	
	#(8*p) 	
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_WIDTH 			, q_width 			);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_HEIGHT 			, q_height 			);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_START_UP_DELAY	, q_start_up_delay 	);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_VSYNC_CYCLE		, q_vsync_cycle 	);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_VSYNC_DELAY		, q_vsync_delay 	);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBread( `LCD_DRIVE_HSYNC_DELAY		, q_hsync_delay 	);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_FRAME_TRANS_DELAY, q_frame_trans_delay);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_DATA_COUNT		, q_data_count 		);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_BR_MODE			, q_br_mode);
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_BR_VALUE			, q_br_value 		);	
	// Start a frame
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_START			, 1'b1 		);	
	#(4*p) u_top_system.u_riscv_dummy.task_AHBwrite(`LCD_DRIVE_START			, 1'b0 		);	
	

end
endmodule