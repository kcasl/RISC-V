`timescale 1ns / 1ps

`include "riscv_defines.v"
module riscv_core_sim #(
  parameter     PC_SIZE  = 32,
  parameter     RESET_SP = 32'h0000
)(
  input         clk_i,		// Clock
  input         reset_i,	// Reset
  output        lock_o,		// Lock

  output [31:0] iaddr_o,	// Instruction from Memory
  input  [31:0] irdata_i,	// Instruction address
  output        ird_o,		// Read request

  output  [31:0] daddr_o,	// Read/Write address
  output  [31:0] dwdata_o,	// Write Data
  input   [31:0] drdata_i,	// Read data
  output   [1:0] dsize_o,
  output         drd_o,		// Write request
  output         dwr_o		// Read/Write Enable
);
//--------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------  
reg  branch_taken_w;
reg  [PC_SIZE-1:0] jump_addr_w;
reg  [PC_SIZE-1:0] if_pc_w;
reg  [PC_SIZE-1:0] if_pc_d;
wire [PC_SIZE-1:0] if_next_addr_w ;

wire [31:0]	ra_value_r;
wire [31:0]	rb_value_r;
wire [31:0] id_imm_w;		
wire [4:0]  id_rd_index_w;
wire [4:0]  id_ra_index_w;
wire [4:0]  id_rb_index_w;
wire [3:0]  id_alu_op_w;
wire [2:0]  id_branch_w;
wire [1:0]  id_mem_size_w;

//Flags
wire mulh_w;
wire mulhsu_w;
wire div_w;
wire rem_w;
wire sra_w;
wire srai_w;
wire alu_imm_w;
wire jal_w;
wire load_w;
wire store_w;
wire lbu_w;
wire lhu_w;
wire jalr_w;
wire id_illegal_w;

wire [PC_SIZE-1:0] if_opcode_w;

reg [ 3:0] alu_op;
reg [31:0] alu_a;
reg [31:0] alu_b;
wire[31:0] alu_p;
wire[ 4:0] flcnz;

reg  [4:0] rd_index_w;
reg [31:0] rd_value_w;
reg        rd_we_w;


//--------------------------------------------------------------------
// TODO: Instruction Fetch
//--------------------------------------------------------------------
always @ (posedge clk_i or negedge reset_i) begin
	if (~reset_i) begin
		if_pc_w <= RESET_SP;
		if_pc_d <= RESET_SP;
	end
	else begin
		if_pc_w <= if_next_addr_w;
		if_pc_d <= if_pc_w;
	end
end
assign iaddr_o = if_pc_w;
assign ird_o   = 1'b1;
assign lock_o  = 1'b0;
assign if_opcode_w = irdata_i;

//--------------------------------------------------------------------
// TODO: Branch, Jump and Link instructions
//--------------------------------------------------------------------
//{{{
/* TODO: ALU */
always@(*) begin
	alu_op = `ALU_ADD;
	alu_a = 32'h0;
	alu_b = 32'h0;
	
	// Insert your code
	//{{
	//alu_op = id_alu_op_w;
	//alu_a  = ra_value_r;
	//alu_b  = (alu_imm_w || jal_w || load_w || store_w) ? id_imm_w : rb_value_r;
	//}}
end
/* TODO: Branch, Jump and Link instructions */
always @ (*) begin
	branch_taken_w = 1'b0;
	jump_addr_w = 32'h0;
	case(id_branch_w)
		`BR_JUMP: begin
		end
		`BR_EQ: begin
		
		end
		`BR_NE: begin	
		// Insert your code
		//{{{		
		//}}}
		end
		`BR_LT: begin		
		// Insert your code
		//{{{		
			// Dummy Branch
			branch_taken_w = 1'b1;		
		//}}}		
		end
		`BR_GE: begin
		
		end
		`BR_LTU: begin
		
		end
		`BR_GEU: begin
		
		end
	endcase	
end
//}}}

//--------------------------------------------------------------------
// Write back
//--------------------------------------------------------------------
// Dummy data memory ports
assign  daddr_o = 32'h0;
assign  dwdata_o = 32'h0;
assign  dsize_o = `SIZE_WORD;
assign  drd_o = 1'b0;
assign  dwr_o = 1'b0;

// Dummy register file ports
always@(*) begin
	rd_index_w = 5'h0;
	rd_value_w = 32'h0;
	rd_we_w    = 1'b0;
	// Insert your code
	//{{{	
	//rd_index_w = id_rd_index_w;
	//rd_value_w = alu_p;
	//rd_we_w    = 1'b1;	
	//}}}	
end
//-----------------------------------------------------------------
// Program Counter
//-----------------------------------------------------------------
riscv_pc #(.RESET_SP(RESET_SP))
u_pc(
	./*input 		*/clk_i(clk_i),					
	./*input 		*/reset_i(reset_i),				
	./*input 		*/ird(ird_o),					
	./*input 		*/branch_taken_w(branch_taken_w),
	./*input [31:0] */jump_addr_w(jump_addr_w),		
	./*output [31:0]*/if_next_addr_w(if_next_addr_w)
);
//-----------------------------------------------------------------
// Decoder
//-----------------------------------------------------------------
riscv_decoder
u_decoder
(
	./*input  [31:0]*/if_opcode_w	(if_opcode_w	),
	./*output [31:0]*/id_imm_w		(id_imm_w		),
	./*output [4:0] */id_rd_index_w	(id_rd_index_w	),
	./*output [4:0] */id_ra_index_w	(id_ra_index_w	),
	./*output [4:0] */id_rb_index_w	(id_rb_index_w	),
	./*output [3:0] */id_alu_op_w	(id_alu_op_w	),
	./*output [2:0] */id_branch_w	(id_branch_w	),
	./*output [1:0] */id_mem_size_w	(id_mem_size_w	),
	./*output 		*/mulh_w		(mulh_w			),
	./*output 		*/mulhsu_w		(mulhsu_w		),
	./*output 		*/div_w			(div_w			),
	./*output 		*/rem_w			(rem_w			),
	./*output 		*/sra_w			(sra_w			),
	./*output 		*/srai_w		(srai_w			),
	./*output 		*/alu_imm_w		(alu_imm_w		),
	./*output 		*/jal_w			(jal_w			),
	./*output 		*/load_w		(load_w			),
	./*output 		*/store_w		(store_w		),
	./*output 		*/lbu_w			(lbu_w			),
	./*output 		*/lhu_w			(lhu_w			),
	./*output 		*/jalr_w		(jalr_w			),
	./*output 		*/id_illegal_w  (id_illegal_w  )
);
//-----------------------------------------------------------------
// Register File
//-----------------------------------------------------------------
riscv_regfile
u_regfile
(
     ./*input           */clk_i(clk_i)
    ,./*input           */rstn_i(reset_i)
    ,./*input  [  4:0]  */rd0_i(rd_index_w)
    ,./*input  [ 31:0]  */rd0_value_i(rd_value_w)
    ,./*input  [  4:0]  */ra0_i(id_ra_index_w)
    ,./*input  [  4:0]  */rb0_i(id_rb_index_w)
	,./*input   		*/wr(rd_we_w)    
    ,./*output [ 31:0]  */ra0_value_o(ra_value_r)
    ,./*output [ 31:0]  */rb0_value_o(rb_value_r)
);

//-----------------------------------------------------------------
// ALU
//-----------------------------------------------------------------
riscv_alu
u_alu
(
     ./*input  [  3:0]  */alu_op_i(alu_op)
    ,./*input  [ 31:0]  */alu_a_i(alu_a)
    ,./*input  [ 31:0]  */alu_b_i(alu_b)
    ,./*output [ 31:0]  */alu_p_o(alu_p)
	,./*output reg [4:0]*/flcnz(flcnz)
);
endmodule

