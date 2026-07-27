
//---------------------------------------------------------------
// Base Address
//---------------------------------------------------------------
`define RISCV_ALU_BASE_ADDR         	32'hE000_0000 
`define RISCV_MULTIPLIER_BASE_ADDR		32'hE000_1000
`define RISCV_LCD_DRIVE_BASE_ADDR		32'hE100_0000
`define RISCV_LCD_DRIVE_IMG_OFFSET		32'h0010_0000
`define RISCV_MEMORY_BASE_ADDR			32'hE200_0000


`define RISCV_MASK_ALU_BASE_ADDR        32'hFFFF_F000 
`define RISCV_MASK_MULTIPLIER_BASE_ADDR	32'hFFFF_F000
`define RISCV_MASK_LCD_DRIVE_BASE_ADDR	32'hFF00_0000
`define RISCV_MASK_MEMORY_BASE_ADDR		32'hFF00_0000
`define RISCV_MASK_LCD_DRIVE_IMG		32'h00F0_0000
`define RISCV_MASK_LCD_DRIVE_IMG_ADDR	32'h000F_FFFF
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

//---------------------------------------------------------------
// LCD Drive
//---------------------------------------------------------------
`define LCD_DRIVE_WIDTH 			(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h00)
`define LCD_DRIVE_HEIGHT 			(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h04)
`define LCD_DRIVE_START_UP_DELAY	(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h08)
`define LCD_DRIVE_VSYNC_CYCLE		(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h0C)
`define LCD_DRIVE_VSYNC_DELAY		(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h10)
`define LCD_DRIVE_HSYNC_DELAY		(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h14)
`define LCD_DRIVE_FRAME_TRANS_DELAY	(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h18)
`define LCD_DRIVE_DATA_COUNT		(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h1C)
`define LCD_DRIVE_START				(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h20)
`define LCD_DRIVE_BR_MODE			(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h24)
`define LCD_DRIVE_BR_VALUE			(`RISCV_LCD_DRIVE_BASE_ADDR + 32'h28)
`define LCD_DRIVE_IMG_DATA			(`RISCV_LCD_DRIVE_BASE_ADDR + `RISCV_LCD_DRIVE_IMG_OFFSET)
