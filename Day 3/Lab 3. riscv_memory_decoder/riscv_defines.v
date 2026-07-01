//--------------------------------------------------------------------
// Definitions
//--------------------------------------------------------------------

// ISA, ALU
`define ALU_ADD   4'd0		// Addition
`define ALU_SUB   4'd1		// Subtraction
`define ALU_AND   4'd2		// AND	
`define ALU_OR    4'd3		// OR	
`define ALU_XOR   4'd4		// XOR
`define ALU_SLT   4'd5		// Compare, Signed
`define ALU_SLTU  4'd6		// Compare, Unsigned
`define ALU_SLL   4'd7		// Shift Left Logical
`define ALU_SRL   4'd8		// Shift Right Logical
`define ALU_SRA   4'd9		// Shift Right Arithmetic
`define ALU_MULL  4'd10		// Multiplier Upper Half
`define ALU_MULH  4'd11		// Multiplier Upper Half
`define ALU_DIV   4'd12		// Divider, division
`define ALU_REM   4'd13		// Divider, quotient
`define ALU_NPC   4'd14		
`define ALU_AUIPC 4'd15		// Add Upper Imm to PC

// Branch, Jump and Link
`define  BR_NONE   3'd0
`define  BR_JUMP   3'd1
`define  BR_EQ     3'd2		//
`define  BR_NE     3'd3
`define  BR_LT     3'd4
`define  BR_GE     3'd5
`define  BR_LTU    3'd6
`define  BR_GEU    3'd7

`define  SIZE_BYTE 2'd0
`define  SIZE_HALF 2'd1
`define  SIZE_WORD 2'd2
