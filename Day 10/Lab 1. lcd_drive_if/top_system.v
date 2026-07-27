`include "amba_ahb_h.v"
`include "map.v"
	
module top_system #(
parameter W_ADDR=32,
parameter W_DATA=32,
parameter IMG_PIX_W = 8)(
// Inputs
input HCLK,
input HRESETn,
output out_valid,
output [IMG_PIX_W-1:0] out_r0, out_g0, out_b0, out_r1, out_g1, out_b1
);


wire	[31:0]	w_RISC2AHB_mst_HADDR       ;
wire	[31:0]	w_RISC2AHB_mst_HWDATA      ;
wire			w_RISC2AHB_mst_HWRITE      ;
wire	[2:0]	w_RISC2AHB_mst_HSIZE       ;
wire	[`W_BURST-1:0]	w_RISC2AHB_mst_HBURST      ;
wire	[1:0]	w_RISC2AHB_mst_HTRANS      ;

// Inputs for Master
wire 	[31:0]	w_RISC2AHB_mst_HRDATA      ;
wire 	[1:0]	w_RISC2AHB_mst_HRESP       ;
wire 		    w_RISC2AHB_mst_HREADY      ;

// ALU
wire	[31:0]	out_alu_sl_HRDATA      ;
wire	[1:0]	out_alu_sl_HRESP       ;
wire		    out_alu_sl_HREADY      ;
// Multiplier
wire	[31:0]	out_mul_sl_HRDATA      ;
wire	[1:0]	out_mul_sl_HRESP       ;
wire		    out_mul_sl_HREADY      ;
// Multiplier
wire	[31:0]	out_lcd_sl_HRDATA      ;
wire	[1:0]	out_lcd_sl_HRESP       ;
wire		    out_lcd_sl_HREADY      ;

//---------------------------------------------------------------
// Address Decoder: compute sl_HSEL_alu and sl_HSEL_multiplier from 
// w_RISC2AHB_mst_HRDATA
//---------------------------------------------------------------
/*
	RISC model	: master 1
	ALU			: slave 1
	MUL			: slave 2
	LCD			: slave 3
*/
parameter N_MASTER	=	1;
parameter W_MASTER	=	$clog2(N_MASTER); //GetBitWidth(N_MASTER);
parameter N_SLAVE	=	3;
parameter W_SLAVE	=	$clog2(N_SLAVE); //GetBitWidth(N_SLAVE);

parameter ADDR_START_MAP = {
		`RISCV_LCD_DRIVE_BASE_ADDR,			// 2
		`RISCV_MULTIPLIER_BASE_ADDR,		// 1
		`RISCV_ALU_BASE_ADDR				// 0
	};

parameter ADDR_END_MAP	 = {
		`RISCV_LCD_DRIVE_BASE_ADDR,			// 2
		`RISCV_MULTIPLIER_BASE_ADDR,		// 1
		`RISCV_ALU_BASE_ADDR				// 0
	};


parameter ADDR_MASK	= {
		`RISCV_MASK_LCD_DRIVE_BASE_ADDR,	// 2
		`RISCV_MASK_MULTIPLIER_BASE_ADDR,	// 1
		`RISCV_MASK_ALU_BASE_ADDR			// 0
	};
//}}}

wire	[N_MASTER-1:0]             w_AHB_IC_ma_HREADY        ;
wire	[N_MASTER-1:0]             w_AHB_IC_ma_HSEL          ;
wire	[N_MASTER*2-1:0]           w_AHB_IC_ma_HTRANS        ;
wire	[N_MASTER*`W_BURST-1:0]    w_AHB_IC_ma_HBURST        ;
wire	[N_MASTER*3-1:0]           w_AHB_IC_ma_HSIZE         ;
wire	[N_MASTER*4-1:0]           w_AHB_IC_ma_HPROT         ;
wire	[N_MASTER-1:0]             w_AHB_IC_ma_HMASTLOCK     ;
wire	[N_MASTER*W_ADDR-1:0]      w_AHB_IC_ma_HADDR         ;
wire	[N_MASTER-1:0]             w_AHB_IC_ma_HWRITE        ;
wire	[N_MASTER*W_DATA-1:0]      w_AHB_IC_ma_HWDATA        ;
wire	[N_MASTER-1:0]             w_AHB_IC_out_ma_HREADY    ;
wire	[N_MASTER*2-1:0]           w_AHB_IC_out_ma_HRESP     ;
wire	[N_MASTER*W_DATA-1:0]      w_AHB_IC_out_ma_HRDATA    ;

wire	[N_SLAVE-1:0]              w_AHB_IC_out_sl_HREADY    ;
wire	[N_SLAVE-1:0]              w_AHB_IC_out_sl_HSEL      ;
wire	[N_SLAVE*2-1:0]            w_AHB_IC_out_sl_HTRANS    ;
wire	[N_SLAVE*`W_BURST-1:0]     w_AHB_IC_out_sl_HBURST    ;
wire	[N_SLAVE*3-1:0]            w_AHB_IC_out_sl_HSIZE     ;
wire	[N_SLAVE*4-1:0]            w_AHB_IC_out_sl_HPROT     ;
wire	[N_SLAVE-1:0]              w_AHB_IC_out_sl_HMASTLOCK ;
wire	[N_SLAVE*W_ADDR-1:0]       w_AHB_IC_out_sl_HADDR     ;
wire	[N_SLAVE-1:0]              w_AHB_IC_out_sl_HWRITE    ;
wire	[N_SLAVE*W_DATA-1:0]       w_AHB_IC_out_sl_HWDATA    ;
wire	[N_SLAVE-1:0]              w_AHB_IC_sl_HREADY        ;
wire	[N_SLAVE*2-1:0]            w_AHB_IC_sl_HRESP         ;
wire	[N_SLAVE*W_DATA-1:0]       w_AHB_IC_sl_HRDATA        ;
 

wire alu_sl_HSEL;
wire [31:0] alu_sl_HADDR;
wire [1:0] alu_sl_HTRANS;
wire [`W_BURST-1:0] alu_sl_HBURST;
wire [2:0] alu_sl_HSIZE;
wire [3:0] alu_sl_HPROT;
wire alu_sl_HWRITE;
wire [31:0] alu_sl_HWDATA;
wire alu_sl_HREADY;

wire mul_sl_HSEL;
wire [31:0] mul_sl_HADDR;
wire [1:0] mul_sl_HTRANS;
wire [`W_BURST-1:0] mul_sl_HBURST;
wire [2:0] mul_sl_HSIZE;
wire [3:0] mul_sl_HPROT;
wire mul_sl_HWRITE;
wire [31:0] mul_sl_HWDATA;
wire mul_sl_HREADY;

wire lcd_sl_HSEL;
wire [31:0] lcd_sl_HADDR;
wire [1:0] lcd_sl_HTRANS;
wire [`W_BURST-1:0] lcd_sl_HBURST;
wire [2:0] lcd_sl_HSIZE;
wire [3:0] lcd_sl_HPROT;
wire lcd_sl_HWRITE;
wire [31:0] lcd_sl_HWDATA;
wire lcd_sl_HREADY;

//---------------------------------------------------------------
//	AHB Masters
//---------------------------------------------------------------
// 0. RISCmodel
assign	w_AHB_IC_ma_HREADY	 [0]					=	1'b1					;
assign	w_AHB_IC_ma_HSEL	 [0]					=	|w_RISC2AHB_mst_HTRANS	;
assign	w_AHB_IC_ma_HTRANS	 [0*2+:2]				=	w_RISC2AHB_mst_HTRANS	;
assign	w_AHB_IC_ma_HBURST	 [0*`W_BURST+:`W_BURST]	=	w_RISC2AHB_mst_HBURST	;
assign	w_AHB_IC_ma_HSIZE	 [0*3+:3]				=	w_RISC2AHB_mst_HSIZE	;
assign	w_AHB_IC_ma_HPROT	 [0*4+:4]				=	4'h0					;
assign	w_AHB_IC_ma_HMASTLOCK[0]					=	|w_RISC2AHB_mst_HTRANS	;
assign	w_AHB_IC_ma_HADDR	 [0*32+:32]				=	w_RISC2AHB_mst_HADDR	;
assign	w_AHB_IC_ma_HWRITE	 [0]		   			=	w_RISC2AHB_mst_HWRITE	;
assign	w_AHB_IC_ma_HWDATA	 [0*32+:32]				=	w_RISC2AHB_mst_HWDATA	;
assign	w_RISC2AHB_mst_HREADY			   			=	w_AHB_IC_out_ma_HREADY	[0];
assign	w_RISC2AHB_mst_HRESP			      		=	w_AHB_IC_out_ma_HRESP	[0];
assign	w_RISC2AHB_mst_HRDATA			   			=	w_AHB_IC_out_ma_HRDATA	[0*32+:32]	;

//---------------------------------------------------------------
//	AHB Slaves
//---------------------------------------------------------------
//  1. AHB2ALU
assign	alu_sl_HSEL						=	w_AHB_IC_out_sl_HSEL	[0]		;
assign	alu_sl_HADDR					=	w_AHB_IC_out_sl_HADDR	[0*32+:32]	;
assign	alu_sl_HTRANS					=	w_AHB_IC_out_sl_HTRANS	[0*2+:2]	;
assign  alu_sl_HBURST					=	w_AHB_IC_out_sl_HBURST	[0*`W_BURST+:`W_BURST]	;
assign	alu_sl_HSIZE					=	w_AHB_IC_out_sl_HSIZE	[0*3+:3]	;
assign	alu_sl_HPROT					=	w_AHB_IC_out_sl_HPROT	[0*4+:4]	;
assign	alu_sl_HWRITE					=	w_AHB_IC_out_sl_HWRITE	[0]		;
assign	alu_sl_HWDATA					=	w_AHB_IC_out_sl_HWDATA	[31:0]	;
assign	alu_sl_HREADY					=	w_AHB_IC_out_sl_HREADY	[0]		;
assign	w_AHB_IC_sl_HREADY	[0]			=	out_alu_sl_HREADY;
assign	w_AHB_IC_sl_HRESP	[0*2+:2]	=	out_alu_sl_HRESP;
assign	w_AHB_IC_sl_HRDATA	[0*32+:32]	=	out_alu_sl_HRDATA;


//  2. AHB2MULTIPLIER
assign	mul_sl_HSEL						=	w_AHB_IC_out_sl_HSEL	[1]		;
assign	mul_sl_HADDR					=	w_AHB_IC_out_sl_HADDR	[1*32+:32]	;
assign	mul_sl_HTRANS					=	w_AHB_IC_out_sl_HTRANS	[1*2+:2]	;
assign  mul_sl_HBURST					=	w_AHB_IC_out_sl_HBURST	[1*`W_BURST+:`W_BURST]	;
assign	mul_sl_HSIZE					=	w_AHB_IC_out_sl_HSIZE	[1*3+:3]	;
assign	mul_sl_HPROT					=	w_AHB_IC_out_sl_HPROT	[1*4+:4]	;
assign	mul_sl_HWRITE					=	w_AHB_IC_out_sl_HWRITE	[1]		;
assign	mul_sl_HWDATA					=	w_AHB_IC_out_sl_HWDATA	[63:32]	;
assign	mul_sl_HREADY					=	w_AHB_IC_out_sl_HREADY	[1]		;
assign	w_AHB_IC_sl_HREADY	[1]			=	out_mul_sl_HREADY;
assign	w_AHB_IC_sl_HRESP	[1*2+:2]	=	out_mul_sl_HRESP;
assign	w_AHB_IC_sl_HRDATA	[1*32+:32]	=	out_mul_sl_HRDATA;

//  3. AHB2LCDDRIVE
//assign	lcd_sl_HSEL			=	/*Insert your code*/;
//assign	lcd_sl_HADDR		=	/*Insert your code*/;
//assign	lcd_sl_HTRANS		=	/*Insert your code*/;
//assign  lcd_sl_HBURST		=	/*Insert your code*/;
//assign	lcd_sl_HSIZE		=	/*Insert your code*/;
//assign	lcd_sl_HPROT		=	/*Insert your code*/;
//assign	lcd_sl_HWRITE		=	/*Insert your code*/;
//assign	lcd_sl_HWDATA		=	/*Insert your code*/;
//assign	lcd_sl_HREADY		=	/*Insert your code*/;
//assign	/*Insert your code*/=	out_lcd_sl_HREADY;
//assign	/*Insert your code*/=	out_lcd_sl_HRESP;
//assign	/*Insert your code*/=	out_lcd_sl_HRDATA;

//---------------------------------------------------------------
// Components
//---------------------------------------------------------------
// RISC-V
ahb_master u_riscv_dummy(      
	 .HRESETn		(HRESETn			)
	,.HCLK   		(HCLK				)
	,.i_HRDATA		(w_RISC2AHB_mst_HRDATA )
	,.i_HRESP 		(w_RISC2AHB_mst_HRESP  )
	,.i_HREADY		(w_RISC2AHB_mst_HREADY )
	,.o_HADDR 		(w_RISC2AHB_mst_HADDR  )
	,.o_HWDATA		(w_RISC2AHB_mst_HWDATA )
	,.o_HWRITE		(w_RISC2AHB_mst_HWRITE )
	,.o_HSIZE 		(w_RISC2AHB_mst_HSIZE  )
	,.o_HBURST		(w_RISC2AHB_mst_HBURST )
	,.o_HTRANS		(w_RISC2AHB_mst_HTRANS )
	);

// ALU
riscv_alu_if u_riscv_alu_if (
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.sl_HREADY(alu_sl_HREADY), 
	.sl_HSEL(alu_sl_HSEL), 
	.sl_HTRANS(alu_sl_HTRANS), 
	.sl_HBURST(alu_sl_HBURST), 
	.sl_HSIZE(alu_sl_HSIZE), 
	.sl_HADDR(alu_sl_HADDR), 
	.sl_HWRITE(alu_sl_HWRITE), 
	.sl_HWDATA(alu_sl_HWDATA),
	.out_sl_HREADY(out_alu_sl_HREADY), 
	.out_sl_HRESP( out_alu_sl_HRESP), 
	.out_sl_HRDATA(out_alu_sl_HRDATA) 
	);

// Multiplier
riscv_multiplier_if u_riscv_multiplier_if (
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.sl_HREADY(mul_sl_HREADY), 
	.sl_HSEL(mul_sl_HSEL), 
	.sl_HTRANS(mul_sl_HTRANS), 
	.sl_HBURST(mul_sl_HBURST), 
	.sl_HSIZE(mul_sl_HSIZE), 
	.sl_HADDR(mul_sl_HADDR), 
	.sl_HWRITE(mul_sl_HWRITE), 
	.sl_HWDATA(mul_sl_HWDATA),
	.out_sl_HREADY(out_mul_sl_HREADY), 
	.out_sl_HRESP( out_mul_sl_HRESP), 
	.out_sl_HRDATA(out_mul_sl_HRDATA)		
	);
	
// LCD Drive
lcd_drive_if u_lcd_drive_if (
	.HCLK(HCLK), 
	.HRESETn(HRESETn), 
	.sl_HREADY(lcd_sl_HREADY), 
	.sl_HSEL(lcd_sl_HSEL), 
	.sl_HTRANS(lcd_sl_HTRANS), 
	.sl_HBURST(lcd_sl_HBURST), 
	.sl_HSIZE(lcd_sl_HSIZE), 
	.sl_HADDR(lcd_sl_HADDR), 
	.sl_HWRITE(lcd_sl_HWRITE), 
	.sl_HWDATA(lcd_sl_HWDATA),
	.out_sl_HREADY(out_lcd_sl_HREADY), 
	.out_sl_HRESP( out_lcd_sl_HRESP), 
	.out_sl_HRDATA(out_lcd_sl_HRDATA),
    .out_valid(out_valid),
    .out_r0(out_r0),
    .out_g0(out_g0),
    .out_b0(out_b0),
    .out_r1(out_r1),
    .out_g1(out_g1),
    .out_b1(out_b1)		
	);	
//---------------------------------------------------------------
// AHB Interconnect
//---------------------------------------------------------------
ahb_lite_interconnect
#( //amba_ahb parameter // {{{
.N_MASTER               (N_MASTER),
.W_MASTER               (W_MASTER),
.N_SLAVE                (N_SLAVE),
.W_SLAVE                (W_SLAVE),
.W_ADDR                 (32),
.W_DATA                 (32),
.WB_DATA                (4),
.W_WB_DATA              (2),
.NUM_DEF_MASTER         (0),//the number of default master
.NUM_DEF_SLAVE          (0),//the number of default slave
//amba_ahb_arbiter_h    
.PRIORITY_SCHEME        (1),//amba arbiter 
.ROUND_ROBIN_SCHEME     (0),
//amba_ahb_decoder_h    
.ADDR_START_MAP         (ADDR_START_MAP),
.ADDR_END_MAP           (ADDR_END_MAP),
.ADDR_MASK              (ADDR_MASK),
.ADDR_PREVILEGE_MAP   (5'b0000), //{N_SLVE{1'b0}} width is number of slave
.ADDR_RW_MAP          (8'b11111111),
.DEC_SEL_ACTION       (1'b1)
)
u_ahb_lite_interconnect(
	 ./*input                             */HCLK             (HCLK				)
	,./*input                             */HRESETn          (HRESETn			)
	,./*input  [N_MASTER-1:0]             */ma_HREADY        (w_AHB_IC_ma_HREADY        )
	,./*input  [N_MASTER-1:0]             */ma_HSEL          (w_AHB_IC_ma_HSEL          )
	,./*input  [N_MASTER*2-1:0]           */ma_HTRANS        (w_AHB_IC_ma_HTRANS        )
	,./*input  [N_MASTER*3-1:0]           */ma_HBURST        (w_AHB_IC_ma_HBURST        )
	,./*input  [N_MASTER*3-1:0]           */ma_HSIZE         (w_AHB_IC_ma_HSIZE         )
	,./*input  [N_MASTER*4-1:0]           */ma_HPROT         (w_AHB_IC_ma_HPROT         )
	,./*input  [N_MASTER-1:0]             */ma_HMASTLOCK     (w_AHB_IC_ma_HMASTLOCK     )
	,./*input  [N_MASTER*W_ADDR-1:0]      */ma_HADDR         (w_AHB_IC_ma_HADDR         )
	,./*input  [N_MASTER-1:0]             */ma_HWRITE        (w_AHB_IC_ma_HWRITE        )
	,./*input  [N_MASTER*W_DATA-1:0]      */ma_HWDATA        (w_AHB_IC_ma_HWDATA        )
	,./*output [N_MASTER-1:0]             */out_ma_HREADY    (w_AHB_IC_out_ma_HREADY    )
	,./*output [N_MASTER*2-1:0]           */out_ma_HRESP     (w_AHB_IC_out_ma_HRESP     )
	,./*output [N_MASTER*W_DATA-1:0]      */out_ma_HRDATA    (w_AHB_IC_out_ma_HRDATA    )
	                                                                                    	
	,./*output [N_SLAVE-1:0]              */out_sl_HREADY    (w_AHB_IC_out_sl_HREADY    )
	,./*output [N_SLAVE-1:0]              */out_sl_HSEL      (w_AHB_IC_out_sl_HSEL      )
	,./*output [N_SLAVE*2-1:0]            */out_sl_HTRANS    (w_AHB_IC_out_sl_HTRANS    )
	,./*output [N_SLAVE*3-1:0]            */out_sl_HBURST    (w_AHB_IC_out_sl_HBURST    )
	,./*output [N_SLAVE*3-1:0]            */out_sl_HSIZE     (w_AHB_IC_out_sl_HSIZE     )
	,./*output [N_SLAVE*4-1:0]            */out_sl_HPROT     (w_AHB_IC_out_sl_HPROT     )
	,./*output [N_SLAVE-1:0]              */out_sl_HMASTLOCK (w_AHB_IC_out_sl_HMASTLOCK )
	,./*output [N_SLAVE*W_ADDR-1:0]       */out_sl_HADDR     (w_AHB_IC_out_sl_HADDR     )
	,./*output [N_SLAVE-1:0]              */out_sl_HWRITE    (w_AHB_IC_out_sl_HWRITE    )
	,./*output [N_SLAVE*W_DATA-1:0]       */out_sl_HWDATA    (w_AHB_IC_out_sl_HWDATA    )
	,./*input  [N_SLAVE-1:0]              */sl_HREADY        (w_AHB_IC_sl_HREADY       	)
	,./*input  [N_SLAVE*2-1:0]            */sl_HRESP         (w_AHB_IC_sl_HRESP         )
	,./*input  [N_SLAVE*W_DATA-1:0]       */sl_HRDATA        (w_AHB_IC_sl_HRDATA        )
	,./*output [N_MASTER*`W_MA_STATE-1:0] */int_ma_q_state   (/*OPEN for debugging    */) 	
	,./*output [N_SLAVE*`W_SL_STATE-1:0]  */int_sl_q_state   (/*OPEN for debugging    */) 		
	,./*output [N_SLAVE*N_MASTER-1:0] 	  */int_sl_active	 (/*OPEN for debugging    */) 		
	,./*output [N_MASTER*N_SLAVE-1:0] 	  */int_ma_active	 (/*OPEN for debugging    */) 		
	,./*output [N_MASTER-1:0] 			  */int_ma_held_trans(/*OPEN for debugging    */) 	
	,./*output [N_MASTER*`W_TRANS-1:0] 	  */int_ma_HTRANS    (/*OPEN for debugging    */) 	
	,./*output [N_SLAVE-1:0] 			  */int_sl_HREADY    (/*OPEN for debugging    */) 	
); // }}}

endmodule