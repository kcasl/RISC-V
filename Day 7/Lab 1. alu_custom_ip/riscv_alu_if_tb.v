`timescale 1ns / 100ps
//---------------------------------------------------------------
// Address mapping
//---------------------------------------------------------------
`define RISCV_ALU_BASE_ADDR             32'hE0000000 


`define RISCV_ALU_REG_ALU_OP_I	(`RISCV_ALU_BASE_ADDR + 32'h00)				//0x00
`define RISCV_ALU_REG_ALU_A_I	(`RISCV_ALU_BASE_ADDR + 32'h04)				//0x04
`define RISCV_ALU_REG_ALU_B_I	(`RISCV_ALU_BASE_ADDR + 32'h08)				//0x08
`define RISCV_ALU_REG_ALU_P_O 	(`RISCV_ALU_BASE_ADDR + 32'h0C)				//0x0c	==> READ ONLY'

`include "riscv_defines.v"
`include "amba_ahb_h.v"

module riscv_alu_if_tb;
// Inputs
reg HCLK;
reg HRESETn;

wire	[31:0]	w_RISC2AHB_mst_HRDATA      ;
wire	[1:0]	w_RISC2AHB_mst_HRESP       ;
wire		w_RISC2AHB_mst_HREADY      ;
wire	[31:0]	w_RISC2AHB_mst_HADDR       ;
wire	[31:0]	w_RISC2AHB_mst_HWDATA      ;
wire		w_RISC2AHB_mst_HWRITE      ;
wire	[2:0]	w_RISC2AHB_mst_HSIZE       ;
wire	[`W_BURST-1:0]	w_RISC2AHB_mst_HBURST      ;
wire	[1:0]	w_RISC2AHB_mst_HTRANS      ;

reg [3:0] alu_op_i;
reg [31:0] alu_a_i, alu_b_i;
reg [31:0] alu_p_o;
//---------------------------------------------------------------
// Master
//---------------------------------------------------------------

ahb_master u_riscv_dummy(      
	 .HRESETn		(HRESETn			)
	,.HCLK   		(HCLK				)
	,.i_HRDATA		(w_RISC2AHB_mst_HRDATA  	)
	,.i_HRESP 		(w_RISC2AHB_mst_HRESP   	)
	,.i_HREADY		(w_RISC2AHB_mst_HREADY  	)
	,.o_HADDR 		(w_RISC2AHB_mst_HADDR   	)
	,.o_HWDATA		(w_RISC2AHB_mst_HWDATA  	)
	,.o_HWRITE		(w_RISC2AHB_mst_HWRITE  	)
	,.o_HSIZE 		(w_RISC2AHB_mst_HSIZE   	)
	,.o_HBURST		(w_RISC2AHB_mst_HBURST  	)
	,.o_HTRANS		(w_RISC2AHB_mst_HTRANS  	)
	);
//---------------------------------------------------------------
// Slave
//---------------------------------------------------------------
riscv_alu_if u_riscv_alu_if (
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.sl_HREADY(1'b1), 
	.sl_HSEL(1'b1), 
	.sl_HTRANS(w_RISC2AHB_mst_HTRANS), 
	.sl_HBURST(w_RISC2AHB_mst_HBURST), 
	.sl_HSIZE(w_RISC2AHB_mst_HSIZE), 
	.sl_HADDR(w_RISC2AHB_mst_HADDR), 
	.sl_HWRITE(w_RISC2AHB_mst_HWRITE), 
	.sl_HWDATA(w_RISC2AHB_mst_HWDATA),
	.out_sl_HREADY(w_RISC2AHB_mst_HREADY), 
	.out_sl_HRESP(w_RISC2AHB_mst_HRESP), 
	.out_sl_HRDATA(w_RISC2AHB_mst_HRDATA) 
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
	alu_a_i = 0;
	alu_b_i = 0;
	alu_p_o = 0;
	alu_op_i = 0;
	HRESETn = 0;
	u_riscv_dummy.task_AHBinit();
	
	#(p/2) HRESETn = 1;
	alu_a_i = 0;
	alu_b_i = 0;
	alu_p_o = 0;
	
	#(8*p)
	       alu_a_i = 32'h0;
	       alu_b_i = 32'h0; 
	       alu_op_i = `ALU_SLT;		
	#(4*p) u_riscv_dummy.task_AHBwrite(`RISCV_ALU_REG_ALU_A_I, alu_a_i);	// Write the first operand
	#(4*p) u_riscv_dummy.task_AHBwrite(`RISCV_ALU_REG_ALU_B_I, alu_b_i);    // Write the second operand
	#(4*p) u_riscv_dummy.task_AHBwrite(`RISCV_ALU_REG_ALU_OP_I, alu_op_i);  // Write the operation
	#(4*p) u_riscv_dummy.task_AHBread(`RISCV_ALU_REG_ALU_P_O, alu_p_o);     // Read the result
	
	#(8*p)
	       alu_a_i = 32'h8;
	       alu_b_i = 32'h8; 
	       alu_op_i = `ALU_ADD;		
	#(4*p) u_riscv_dummy.task_AHBwrite(`RISCV_ALU_REG_ALU_A_I, alu_a_i);	// Write the first operand
	#(4*p) u_riscv_dummy.task_AHBwrite(`RISCV_ALU_REG_ALU_B_I, alu_b_i);	// Write the second operand
	#(4*p) u_riscv_dummy.task_AHBwrite(`RISCV_ALU_REG_ALU_OP_I, alu_op_i);	// Write the operation
	#(4*p) u_riscv_dummy.task_AHBread(`RISCV_ALU_REG_ALU_P_O, alu_p_o);		// Read the result
end


endmodule