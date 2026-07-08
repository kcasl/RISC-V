
//---------------------------------------------------------------
// Base Address
//---------------------------------------------------------------
`define RISCV_ALU_BASE_ADDR         32'hE0000000 
`define RISCV_MULTIPLIER_BASE_ADDR	32'hE0001000

//---------------------------------------------------------------
// ALU
//---------------------------------------------------------------
`define RISCV_REG_ALU_OP_I	(`RISCV_ALU_BASE_ADDR + 32'h00)				//0x00
`define RISCV_REG_ALU_A_I	(`RISCV_ALU_BASE_ADDR + 32'h04)				//0x04
`define RISCV_REG_ALU_B_I	(`RISCV_ALU_BASE_ADDR + 32'h08)				//0x08
`define RISCV_REG_ALU_P_O 	(`RISCV_ALU_BASE_ADDR + 32'h0C)				//0x0c	

//---------------------------------------------------------------
// Multipler
//---------------------------------------------------------------
`define RISCV_REG_MUL_OP_I		(`RISCV_MULTIPLIER_BASE_ADDR + 32'h00)
`define RISCV_REG_MUL_A_I		(`RISCV_MULTIPLIER_BASE_ADDR + 32'h04)
`define RISCV_REG_MUL_B_I		(`RISCV_MULTIPLIER_BASE_ADDR + 32'h08)
`define RISCV_REG_MUL_A_SIGNED	(`RISCV_MULTIPLIER_BASE_ADDR + 32'h0C)
`define RISCV_REG_MUL_B_SIGNED	(`RISCV_MULTIPLIER_BASE_ADDR + 32'h10)
`define RISCV_REG_MUL_P_O_LOW	(`RISCV_MULTIPLIER_BASE_ADDR + 32'h14)
`define RISCV_REG_MUL_P_O_HIGH	(`RISCV_MULTIPLIER_BASE_ADDR + 32'h18)
`define RISCV_REG_MUL_STALL_W	(`RISCV_MULTIPLIER_BASE_ADDR + 32'h1C)