`timescale 1ns / 1ps
//--------------------------------------------------------------------
// Program Counter
//--------------------------------------------------------------------
module riscv_pc #(parameter     PC_SIZE  = 32)
(
	input clk_i,						// Clock
	input reset_i,						// Reset
	input ird,							// Instruction Read request
	input branch_taken_w,				// Jump instruction
	input [PC_SIZE-1:0] jump_addr_w,	// Jump address
	output [PC_SIZE-1:0] if_next_addr_w	// Next instruction
);

reg [PC_SIZE-1:0] if_addr_r;
always @(posedge clk_i or negedge reset_i) begin
  if (~reset_i) begin
    if_addr_r <= 'h0;
  end
  else begin 
	  if (ird)
		if_addr_r <= if_next_addr_w + 'd4;
	  else if (branch_taken_w)
		if_addr_r <= jump_addr_w;
  end
end

assign if_next_addr_w = branch_taken_w ? jump_addr_w: if_addr_r;

endmodule

