`timescale 1ns / 1ps

module riscv_core #(
  parameter     PC_SIZE  = 32,
  parameter     RESET_SP = 32'h1000
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

`include "riscv_defines.v"

localparam
  ST_RESET     = 2'd0,
  ST_LOW       = 2'd1,
  ST_HIGH      = 2'd2,
  ST_UNALIGNED = 2'd3;
  
//--------------------------------------------------------------------
// Signals
//--------------------------------------------------------------------  
reg branch_taken_w;
reg [PC_SIZE-1:0] jump_addr_w;
wire id_bubble_w;
wire id_ready_w ; 
wire id_exec_w  ;
wire if_lo_is_rv_w ;
wire if_lo_is_rvc_w;
wire if_hi_is_rv_w ;
wire if_hi_is_rvc_w;
wire [PC_SIZE-1:0] if_next_addr_w ;
reg        id_lock_r;
wire [PC_SIZE-1:0] if_next_pc_w;
wire ex_bubble_w;
wire ex_ready_w;
wire ex_stall_w;
wire mem_stall_w;
//wire sh_request_w;
//wire mul_request_w;
//wire div_request_w; 
//wire ex_stall_div_w;
reg mem_stall_r;

reg [PC_SIZE-1:0] if_pc_r;
wire if_rv_w;
wire if_valid_w;
wire ird_request_w;
wire [31:0] if_rv_op_w;
wire [15:0] if_rvc_op_w;
wire [31:0] if_rvc_dec_w;
wire [31:0] if_opcode_w;
reg [PC_SIZE-1:0] id_pc_r;

reg  [4:0] id_rd_index_r;
reg [31:0] id_ra_value_r;
reg [31:0] id_rb_value_r;
wire [31:0]ra_value_r;
wire [31:0]rb_value_r;
reg [31:0] id_imm_r;
reg        id_a_signed_r;
reg        id_b_signed_r;
reg        id_op_imm_r;
reg  [3:0] id_alu_op_r;
reg        id_mem_rd_r;
reg        id_mem_wr_r;
reg        id_mem_signed_r;
reg  [1:0] id_mem_size_r;
reg  [2:0] id_branch_r;
reg        id_reg_jump_r;

reg  [4:0] ex_rd_index_r;
reg [31:0] ex_alu_res_r;
reg [31:0] ex_mem_data_r;
reg        ex_mem_rd_r;
reg        ex_mem_wr_r;
reg        ex_mem_signed_r;
reg  [1:0] ex_mem_size_r;

wire [31:0] id_imm_w;		
wire [4:0] id_rd_index_w;
wire [4:0] id_ra_index_w;
wire [4:0] id_rb_index_w;
wire [3:0] id_alu_op_w;
wire [2:0] id_branch_w;
wire [1:0] id_mem_size_w;
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

wire [31:0] alu_opb_w;
wire        adder_sub_w;
wire [31:0] adder_opa_w;
wire [31:0] adder_opb_w;
wire [31:0] ex_alu_res_w;
wire [31:0] adder_out_w;
wire [4:0]  flcnz;
wire        adder_cin_w;
wire        adder_c_w;
wire        adder_n_w;
wire        adder_v_w;
wire mem_access_w;
wire [31:0] mem_rdata_w;
wire  [4:0] rd_index_w;
wire [31:0] rd_value_w;
wire        rd_we_w;


reg   [1:0] if_state_r;
reg  [15:0] if_buf_r;
wire id_hazard_w; 
wire ex_hazard_w; 
wire hazard_w;    
//--------------------------------------------------------------------
// State machine
//--------------------------------------------------------------------
always @(posedge clk_i or negedge reset_i) begin
  if (~reset_i) begin
    if_state_r <= ST_RESET;
    if_buf_r <= 16'h0;
  end 
  else begin 
	if (branch_taken_w) begin
		if_state_r <= jump_addr_w[1] ? ST_HIGH : ST_LOW;
	end 
	else if (id_exec_w) begin 
		case (if_state_r)
			ST_RESET: begin
			  if_state_r <= ST_LOW;
			end

			ST_LOW: begin
			  if (if_lo_is_rvc_w && if_hi_is_rvc_w) begin
				if_state_r <= ST_HIGH;
			  end else if (if_lo_is_rvc_w && if_hi_is_rv_w) begin
				if_state_r <= ST_UNALIGNED;
				if_buf_r <= irdata_i[31:16];
			  end
			end

			ST_HIGH: begin
			  if (if_hi_is_rv_w) begin // Only possible after a branch
				if_state_r <= ST_UNALIGNED;
				if_buf_r <= irdata_i[31:16];
			  end else begin
				if_state_r <= ST_LOW;
			  end
			end

			ST_UNALIGNED: begin
			  if (if_hi_is_rv_w)
				if_buf_r <= irdata_i[31:16];
			  else
				if_state_r <= ST_HIGH;
			end
		endcase
	end
  end 
end
//--------------------------------------------------------------------
// Instruction Fetch
//--------------------------------------------------------------------
assign ird_request_w =
    (ST_RESET == if_state_r) ||
    (ST_HIGH == if_state_r) ||
    (ST_LOW == if_state_r && if_lo_is_rv_w) ||
    (ST_LOW == if_state_r && if_hi_is_rv_w && if_lo_is_rvc_w) ||
    (ST_UNALIGNED == if_state_r && if_hi_is_rv_w);

assign iaddr_o = if_next_addr_w;
assign ird_o   = branch_taken_w || (ird_request_w && id_exec_w);
assign lock_o  = id_lock_r;

assign if_lo_is_rv_w  = (2'b11 == irdata_i[1:0]);
assign if_lo_is_rvc_w = !if_lo_is_rv_w;
assign if_hi_is_rv_w  = (2'b11 == irdata_i[17:16]);
assign if_hi_is_rvc_w = !if_hi_is_rv_w;

assign if_rv_w    = (ST_UNALIGNED == if_state_r) || (ST_LOW == if_state_r && if_lo_is_rv_w);
assign if_valid_w = !((ST_RESET == if_state_r) || (ST_HIGH == if_state_r && if_hi_is_rv_w));
assign if_rv_op_w  = (ST_UNALIGNED == if_state_r) ? { irdata_i[15:0], if_buf_r } : irdata_i;
assign if_rvc_op_w = (ST_HIGH == if_state_r) ? irdata_i[31:16] : irdata_i[15:0];


always @(posedge clk_i or negedge reset_i) begin
  if (~reset_i) begin 
    if_pc_r <= 'h0;
  end 
  else begin
	if (branch_taken_w)
		if_pc_r <= jump_addr_w;
	else if (if_valid_w && id_exec_w)
		if_pc_r <= if_next_pc_w;
  end
end

assign if_next_pc_w = if_pc_r + (if_rv_w ? 'd4 : 'd2);
assign if_rvc_dec_w = 32'h0;
assign if_opcode_w = if_rv_w ? if_rv_op_w : if_rvc_dec_w;

//--------------------------------------------------------------------
// Hazard detection
//--------------------------------------------------------------------
assign id_hazard_w = (id_rd_index_r != 5'd0) && (id_ra_index_w == id_rd_index_r || id_rb_index_w == id_rd_index_r);
assign ex_hazard_w = (ex_rd_index_r != 5'd0) && (id_ra_index_w == ex_rd_index_r || id_rb_index_w == ex_rd_index_r);
assign hazard_w    = id_hazard_w || ex_hazard_w;

//--------------------------------------------------------------------
// Decoder: Pipeline registers
//--------------------------------------------------------------------

assign id_bubble_w = (~reset_i) || ((branch_taken_w || hazard_w || !if_valid_w) && id_ready_w);
assign id_ready_w  = !ex_stall_w && !mem_stall_w && !id_lock_r;
assign id_exec_w   = id_ready_w && !hazard_w;

always @(posedge clk_i or negedge reset_i) begin
  if(~reset_i) begin
	id_pc_r         <= 'h0;
	id_rd_index_r   <= 5'd0;
	id_imm_r        <= 32'h0;
	id_a_signed_r   <= 1'b0;
	id_b_signed_r   <= 1'b0;
	id_op_imm_r     <= 1'b0;
	id_alu_op_r     <= `ALU_ADD;
	id_mem_rd_r     <= 1'b0;
	id_mem_wr_r     <= 1'b0;
	id_mem_signed_r <= 1'b0;
	id_mem_size_r   <= `SIZE_WORD;
	id_branch_r     <= `BR_NONE;
	id_reg_jump_r   <= 1'b0;
	id_lock_r       <= 1'b0;  
	id_ra_value_r   <= 32'h0;
	id_rb_value_r   <= 32'h0;	
  end 
  else begin
	  if (id_bubble_w) begin
		id_pc_r         <= 'h0;
		id_rd_index_r   <= 5'd0;
		id_imm_r        <= 32'h0;
		id_a_signed_r   <= 1'b0;
		id_b_signed_r   <= 1'b0;
		id_op_imm_r     <= 1'b0;
		id_alu_op_r     <= `ALU_ADD;
		id_mem_rd_r     <= 1'b0;
		id_mem_wr_r     <= 1'b0;
		id_mem_signed_r <= 1'b0;
		id_mem_size_r   <= `SIZE_WORD;
		id_branch_r     <= `BR_NONE;
		id_reg_jump_r   <= 1'b0;
		id_lock_r       <= 1'b0;
	  end else if (id_ready_w) begin
		id_pc_r         <= if_pc_r;
		id_rd_index_r   <= id_rd_index_w;
		id_imm_r        <= id_imm_w;
		id_a_signed_r   <= mulh_w || mulhsu_w || div_w || rem_w || sra_w || srai_w;
		id_b_signed_r   <= mulh_w || div_w || rem_w;
		id_op_imm_r     <= alu_imm_w || jal_w || load_w || store_w;
		id_alu_op_r     <= id_alu_op_w;
		id_mem_rd_r     <= load_w;
		id_mem_wr_r     <= store_w;
		id_mem_signed_r <= !lbu_w && !lhu_w;
		id_mem_size_r   <= id_mem_size_w;
		id_branch_r     <= id_branch_w;
		id_reg_jump_r   <= jalr_w;
		id_ra_value_r   <= ra_value_r;
		id_rb_value_r   <= rb_value_r;
		id_lock_r       <= id_illegal_w;
	  end
  end
end

//--------------------------------------------------------------------
// Execution
//--------------------------------------------------------------------
assign alu_opb_w 	= id_op_imm_r ? id_imm_r : id_rb_value_r;
assign adder_sub_w 	= (`ALU_SUB == id_alu_op_r || `ALU_SLT == id_alu_op_r || `ALU_SLTU == id_alu_op_r);
assign adder_opa_w 	= id_ra_value_r;
assign adder_opb_w 	= adder_sub_w ? ~alu_opb_w : alu_opb_w;
assign adder_cin_w 	= adder_sub_w ? 1'b1 : 1'b0;
assign { adder_c_w, adder_out_w } = { 1'b0, adder_opa_w } + { 1'b0, adder_opb_w } + adder_cin_w;
assign adder_n_w = adder_out_w[31];
assign adder_v_w = (adder_opa_w[31] == adder_opb_w[31] && adder_out_w[31] != adder_opb_w[31]);
assign adder_z_w = (32'h0 == adder_out_w);

/* Branch, Jump and Link instructions */
always @ (*) begin
	branch_taken_w = 1'b0;
	jump_addr_w = 32'h0;
	
	jump_addr_w = (id_reg_jump_r ? id_ra_value_r : id_pc_r) + id_imm_r;
	case(id_branch_r)
		`BR_JUMP: begin
			branch_taken_w = 1'b1;
		end
		`BR_EQ: begin
			branch_taken_w = adder_z_w;
		end
		`BR_NE: begin	
			/*Insert your code*/
		end
		`BR_LT: begin		
			branch_taken_w = (adder_n_w != adder_v_w);
		end
		`BR_GE: begin
			/*Insert your code*/
		end
		`BR_LTU: begin
			branch_taken_w = !adder_c_w;
		end
		`BR_GEU: begin
			branch_taken_w = adder_c_w;
		end
	endcase	
end

//Pipeline registers
assign  ex_stall_w = 1'b0;
assign  ex_bubble_w = (~reset_i) || (ex_stall_w && !mem_stall_w);
assign  ex_ready_w  = !mem_stall_w;

always @(posedge clk_i or negedge reset_i) begin
	if(~reset_i) begin
		ex_rd_index_r 	<= 5'd2; // SP
		ex_alu_res_r  	<= RESET_SP;
		ex_mem_data_r   <= 32'h0;
		ex_mem_rd_r     <= 1'b0;
		ex_mem_wr_r     <= 1'b0;
		ex_mem_signed_r <= 1'b0;
		ex_mem_size_r   <= `SIZE_WORD;	
	end
	else begin 
	  if (ex_bubble_w) begin
		if (~reset_i) begin
		  ex_rd_index_r <= 5'd2; // SP
		  ex_alu_res_r  <= RESET_SP;
		end else begin
		  ex_rd_index_r <= 5'd0;
		  ex_alu_res_r  <= 32'h0;
		end
		ex_mem_data_r   <= 32'h0;
		ex_mem_rd_r     <= 1'b0;
		ex_mem_wr_r     <= 1'b0;
		ex_mem_signed_r <= 1'b0;
		ex_mem_size_r   <= `SIZE_WORD;
	  end else if (ex_ready_w) begin
		ex_rd_index_r   <= id_rd_index_r;
		ex_alu_res_r    <= ex_alu_res_w;
		ex_mem_data_r   <= id_rb_value_r;
		ex_mem_rd_r     <= id_mem_rd_r;
		ex_mem_wr_r     <= id_mem_wr_r;
		ex_mem_signed_r <= id_mem_signed_r;
		ex_mem_size_r   <= id_mem_size_r;
	  end
  end
end

//--------------------------------------------------------------------
// Memory
//--------------------------------------------------------------------
assign daddr_o  = ex_alu_res_r;
assign dwdata_o = ex_mem_data_r;
assign dsize_o  = ex_mem_size_r;
assign drd_o    = ex_mem_rd_r && (mem_stall_r == 1'b0);
assign dwr_o    = ex_mem_wr_r && (mem_stall_r == 1'b0);

assign mem_rdata_w =
  (`SIZE_BYTE == ex_mem_size_r) ? { {24{ex_mem_signed_r & drdata_i[7]}}, drdata_i[7:0] } :
  (`SIZE_HALF == ex_mem_size_r) ? { {16{ex_mem_signed_r & drdata_i[15]}}, drdata_i[15:0] } : drdata_i;


always @(posedge clk_i) begin
  if (~reset_i)
    mem_stall_r <= 1'b0;
  else
    mem_stall_r <= mem_stall_w;
end

assign mem_access_w = (ex_mem_rd_r || ex_mem_wr_r);
assign mem_stall_w  = mem_stall_r ? 1'b0 : mem_access_w;

//--------------------------------------------------------------------
// Write back
//--------------------------------------------------------------------
assign  rd_index_w = ex_rd_index_r;
assign  rd_value_w = mem_access_w ? mem_rdata_w : ex_alu_res_r;
assign  rd_we_w    = (ex_rd_index_r != 5'd0) && (mem_stall_w == 1'b0);

//-----------------------------------------------------------------
// Program Counter
//-----------------------------------------------------------------
riscv_pc u_pc(
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
     ./*input           */clk_i  (clk_i)
    ,./*input           */rstn_i (reset_i)
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
     ./*input  [  3:0]  */alu_op_i(id_alu_op_r)
    ,./*input  [ 31:0]  */alu_a_i(adder_opa_w)
    ,./*input  [ 31:0]  */alu_b_i(adder_opb_w)
    ,./*output [ 31:0]  */alu_p_o(ex_alu_res_w)
	,./*output reg [4:0]*/flcnz(flcnz)
);
endmodule

