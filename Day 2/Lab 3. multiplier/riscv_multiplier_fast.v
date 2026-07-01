`include "riscv_defines.v"
//`define USE_NATIVE_MULTIPLIER 1
//-------------------------------------------------------------------------------------------------------
//**** module description begins with “module modulename”
//    : this file descripts the function of module
//-------------------------------------------------------------------------------------------------------

module riscv_multiplier_fast(

//-------------------------------------------------------------------------------------------------------
// **** Input / output ports definition
//     : module input/output could be connected to the other module
//     : Input controlled by designer testbench for simulation.
//     : output monitored by testbench for funtional verification.
//     : clock, reset for synchronous function
//-------------------------------------------------------------------------------------------------------

	input clk_i,
	input rstn_i,
	input [3:0] id_alu_op_r,
	input id_a_signed_r,
	input id_b_signed_r,
	input [31:0] id_ra_value_r, // 32bits multiplicand registser a
	input [31:0] id_rb_value_r, // 32bits multiplier register b
	output [63:0] mul_res_w,	// 64bits multiplier out
	output ex_stall_mul_w
);
	// Signed
	wire mul_negative_w;
	wire [31:0] mul_a_w;
	wire [31:0] mul_b_w;

	assign mul_negative_w = (id_a_signed_r && id_ra_value_r[31]) ^ (id_b_signed_r && id_rb_value_r[31]);
	assign mul_a_w = (id_a_signed_r && id_ra_value_r[31]) ? -id_ra_value_r : id_ra_value_r;
	assign mul_b_w = (id_b_signed_r && id_rb_value_r[31]) ? -id_rb_value_r : id_rb_value_r;

	// Multiplier
	//-------------------------------------------------------------------------------------------------------
	//*** Dedicated multiplier circuit use
	//-------------------------------------------------------------------------------------------------------
	wire [63:0] mul_opa_a_w;
	wire [63:0] mul_opa_b_w;

	assign  mul_opa_a_w = { {32{id_a_signed_r & id_ra_value_r[31]}}, id_ra_value_r };
	assign  mul_opa_b_w = { {32{id_b_signed_r & id_rb_value_r[31]}}, id_rb_value_r };
	assign  mul_res_w = mul_opa_a_w * mul_opa_b_w; 		
	assign  ex_stall_mul_w = 1'b0;

//-------------------------------------------------------------------------------------------------------
//**** module description ends with “endmodule”
//-------------------------------------------------------------------------------------------------------
endmodule

