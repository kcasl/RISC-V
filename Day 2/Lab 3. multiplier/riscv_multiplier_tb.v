`timescale 1ns/1ps
`include "riscv_defines.v"

module riscv_multiplier_tb;

// Signals
reg rstn;
reg clk;
reg [3:0] alu_op_i;
reg [31:0] alu_a_i, alu_b_i;
//wire [31:0] alu_p_o;
wire [63:0] alu_p_o;
wire ex_stall_mul_w;
reg a_signed, b_signed;

wire [63:0] alu_p_o_f;
wire ex_stall_mul_w_f;

//Fast multiplier: One cycle delay
riscv_multiplier_fast
u_riscv_multiplier_fast(
	./*input */clk_i(clk),
	./*input */rstn_i(rstn),
	./*input [3:0]  */id_alu_op_r(alu_op_i),
	./*input 		*/id_a_signed_r(a_signed),
	./*input 		*/id_b_signed_r(b_signed),
	./*input [31:0] */id_ra_value_r(alu_a_i),
	./*input [31:0] */id_rb_value_r(alu_b_i),
	./*output [63:0] */mul_res_w(alu_p_o_f),
	./*output 		*/ex_stall_mul_w(ex_stall_mul_w_f)
);

// Sequential multipler: 32 cycle delay
riscv_multiplier
u_riscv_multiplier(
	./*input */clk_i(clk),
	./*input */rstn_i(rstn),
	./*input [3:0]  */id_alu_op_r(alu_op_i),
	./*input 		*/id_a_signed_r(a_signed),
	./*input 		*/id_b_signed_r(b_signed),
	./*input [31:0] */id_ra_value_r(alu_a_i),
	./*input [31:0] */id_rb_value_r(alu_b_i),
	./*output [63:0] */mul_res_w(alu_p_o),
	./*output 		*/ex_stall_mul_w(ex_stall_mul_w)
);

	// Clock
    parameter p=10;
   initial
   begin
   	clk = 1'b0;
   	forever #(p/2) clk = !clk;
   end

   // Test cases
   initial
   begin
   	rstn = 1'b0;			// negedge reset on
	alu_a_i = 0;
	alu_b_i = 0;
	alu_op_i = 0;	
	a_signed = 0;
	b_signed = 0;
	alu_op_i = `ALU_ADD;	
	
   	#(4*p) rstn = 1'b1;	// negedge reset off
		alu_a_i = 0;
		alu_b_i = 0;
		alu_op_i = 0;
		a_signed = 0;
		b_signed = 0;
		alu_op_i = `ALU_ADD;
	
	#(2*p)
		a_signed = 0;
		b_signed = 0;
		alu_a_i = 32'h0000_0008;
		alu_b_i = 32'h0000_0008;	
	#(2*p)
		alu_op_i = `ALU_MULL;
		   
	#(p)
		alu_op_i = `ALU_ADD;
		   
	#(32*p)
		alu_a_i = 32'h0000_0007;
		alu_b_i = 32'h0000_0009;	
	#(2*p)
		alu_op_i = `ALU_MULL;
		   
	#(p)
		alu_op_i = `ALU_ADD;
   end
   
endmodule


