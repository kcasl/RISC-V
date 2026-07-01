module riscv_decoder_tb;
reg rst;
reg clk;

// Input instruction
reg  [31:0] if_opcode_w;
// Outputs
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

riscv_decoder
u_decoder
(
./*input  [31:0]*/ if_opcode_w(if_opcode_w),
./*output [31:0]*/ id_imm_w(id_imm_w),
./*output [4:0] */id_rd_index_w(id_rd_index_w),
./*output [4:0] */id_ra_index_w(id_ra_index_w),
./*output [4:0] */id_rb_index_w(id_rb_index_w),
./*output [3:0] */id_alu_op_w(id_alu_op_w),
./*output [2:0] */id_branch_w(id_branch_w),
./*output [1:0] */id_mem_size_w(id_mem_size_w),
//Flags
./*output */mulh_w(mulh_w),
./*output */mulhsu_w(mulhsu_w),
./*output */div_w(div_w),
./*output */rem_w(rem_w),
./*output */sra_w(sra_w),
./*output */srai_w(srai_w),
./*output */alu_imm_w(alu_imm_w),
./*output */jal_w(jal_w),
./*output */load_w(load_w),
./*output */store_w(store_w),
./*output */lbu_w(lbu_w),
./*output */lhu_w(lhu_w),
./*output */jalr_w(jalr_w),
./*output */id_illegal_w(id_illegal_w)
);

parameter p=10;

initial
begin
clk = 1'b0;
forever #(p/2) clk = !clk;
end

initial
begin
rst = 1'b0;		// negedge reset on
if_opcode_w = 0;
#(4*p) rst = 1'b1;	// negedge reset off
/*
C:
for (int i = 0;i < 10;i++) {
    // Repeated code goes here.
}

Assembly:
# t0 = 0
li      t0, 0
li      t2, 10
loop_head:
bge     t0, t2, loop_end
# Repeated code goes here
addi    t0, t0, 1
loop_end:

// Venus
0x00000293	addi x5 x0 0	li t0, 0
0x00a00393	addi x7 x0 10	li t2, 10
0x0072d463	bge x5 x7 8	bge t0, t2, loop_end
0x00128293	addi x5 x5 1	addi t0, t0, 1
*/
	#(4*p) if_opcode_w = 32'h00000293;
	#(4*p) if_opcode_w = 32'h00a00393;
	#(4*p) if_opcode_w = 32'h0072d463;
	#(4*p) if_opcode_w = 32'h00128293;
	#(4*p) if_opcode_w = 32'h0;
end
endmodule