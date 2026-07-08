`timescale 1ns / 100ps
`include "amba_ahb_h.v"
`include "riscv_defines.v"
`include "map.v"

module top_system_tb;
// Inputs
reg HCLK;
reg HRESETn;

// Select signals
//reg sl_HSEL_alu;
//reg sl_HSEL_multiplier;
reg [3:0] alu_op_i;
reg [31:0] alu_a_i, alu_b_i;
reg [31:0] alu_p_o;
//---------------------------------------------------------------
// Components
//---------------------------------------------------------------
top_system u_top_system(      
	 .HRESETn(HRESETn)
	,.HCLK   (HCLK	 )
	//,.sl_HSEL_alu(sl_HSEL_alu  	)
	//,.sl_HSEL_multiplier(sl_HSEL_multiplier)
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
end
endmodule