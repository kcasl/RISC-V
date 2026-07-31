`include "amba_ahb_h.v"
`include "map.v"
module cnn_accel #(
	parameter W_ADDR = 32,
	parameter W_DATA = 32,
	parameter WB_DATA = 4,
	parameter W_WB_DATA = 2,
	parameter DEF_HPROT = {`PROT_NOTCACHE, `PROT_UNBUF, `PROT_USER, `PROT_DATA},
	parameter WIDTH 	= 128,
	parameter HEIGHT 	= 128,
	parameter START_UP_DELAY = 200,
	parameter HSYNC_DELAY = 160,
	parameter INFILE    = "./img/butterfly_08bit.hex",
	parameter OUTFILE00   = "./out/convout_ch01.bmp",
	parameter OUTFILE01   = "./out/convout_ch02.bmp",
	parameter OUTFILE02   = "./out/convout_ch03.bmp",
	parameter OUTFILE03   = "./out/convout_ch04.bmp")
(
	//CLOCK
	HCLK,
	HRESETn,
	//input signals of control port(slave)
	sl_HREADY,
	sl_HSEL,
	sl_HTRANS,
	sl_HBURST,
	sl_HSIZE,
	sl_HADDR,
	sl_HWRITE,
	sl_HWDATA,
	//output signals of control port(slave)
	out_sl_HREADY,				
	out_sl_HRESP,
	out_sl_HRDATA,

	// Master port 1: Input image
	//AHB transactor signals
	HREADY,
	HRESP,
	HRDATA,
	//output signals outgoing to the AHB lite
	out_HTRANS,
	out_HBURST,
	out_HSIZE,
	out_HPROT,
	out_HMASTLOCK,
	out_HADDR,
	out_HWRITE,
	out_HWDATA		
);
//CLOCK
input HCLK;
input HRESETn;
//input signals of control port(slave)
input sl_HREADY;
input sl_HSEL;
input [`W_TRANS-1:0] sl_HTRANS;
input [`W_BURST-1:0] sl_HBURST;
input [`W_SIZE-1:0] sl_HSIZE;
input [W_ADDR-1:0] sl_HADDR;
input sl_HWRITE;
input [W_DATA-1:0] sl_HWDATA;
//output signals of control port(slave)
output out_sl_HREADY;				
output [`W_RESP-1:0] out_sl_HRESP;
output reg [W_DATA-1:0] out_sl_HRDATA;

// Master: Input image
//AHB transactor signals
input HREADY;
input [`W_RESP-1:0] HRESP;
input [W_DATA-1:0] HRDATA;
//output signals outgoing to the AHB lite
output [`W_TRANS-1:0] out_HTRANS;
output [`W_BURST-1:0] out_HBURST;
output [`W_SIZE-1:0] out_HSIZE;
output [`W_PROT-1:0] out_HPROT;
output out_HMASTLOCK;
output [W_ADDR-1:0] out_HADDR;
output out_HWRITE;
output [W_DATA-1:0] out_HWDATA;
//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
parameter Ti = 16;	// Each CONV kernel do 16 multipliers at the same time	
//parameter To = 4;	// Run 4 CONV kernels at the same time
parameter To = 16;	// Run 16 CONV kernels at the same time

parameter WI = 8;
parameter N  = 16;
parameter WN = $clog2(N);
parameter WO = 2*(WI+1) + WN;
parameter PARAM_BITS 	= 16;
parameter WEIGHT_BITS 	= 8;
parameter ACT_BITS		= 8;
parameter DATA_BITS 	= WO;
localparam CONV3x3_DELAY 	= 9;
localparam CONV3x3_DELAY_W 	= 4;

localparam FRAME_SIZE = WIDTH * HEIGHT;
localparam FRAME_SIZE_W = $clog2(FRAME_SIZE);
localparam W_SIZE  = 12;					// Max 4K QHD (3840x1920).
localparam W_FRAME_SIZE  = 2 * W_SIZE + 1;	// Max 4K QHD (3840x1920).
localparam W_DELAY = 12;

// Block ram for weights
parameter N_DELAY 	    = 1;		
// [MODIFIED] Term Project 2026 Summer - Problem 1-4b
// 2025Spring network has 8 CONV layers (Table I).
// Hint: only changing N_LAYER is enough for buffer sizing
// (oversized weight buffer is acceptable).
parameter N_LAYER 		= 8;
parameter N_CELL  		= N_LAYER * (Ti*To*9)/N;
parameter N_CELL_PARAM	= N_LAYER * (To);
parameter W_CELL 		= $clog2(N_CELL);
parameter W_CELL_PARAM 	= $clog2(N_CELL_PARAM);	
parameter EN_LOAD_INIT_FILE = 1'b1; // Initialize weights, scales, biases from files			
// AHB signals			
localparam N_REGS = 10;
localparam W_REGS = $clog2(N_REGS);
localparam CNN_ACCEL_FRAME_SIZE			= 0;	// WIDTH * HEIGHT
localparam CNN_ACCEL_WIDTH_HEIGHT		= 1;	// 0:15 -> WIDTH, 16:31: HEIGHT
localparam CNN_ACCEL_DELAY_PARAMS		= 2;	// 0~11: start_up, 12~23: hsync, 24~31: reserve
localparam CNN_ACCEL_BASE_ADDRESS		= 3;	// 0~19: weight; 20~31: param (scale/bias)
localparam CNN_ACCEL_LAYER_CONFIG		= 4;	// 0: is_first_layer, 1: q_is_last_layer, 2: is_conv3x3, 3: act_type (0:ReLU, 1:Linear)
												// 4~7: layer_index, 8~12: bias_shift, 13~15: act_shift
												// 16~31: Reserved											
localparam CNN_ACCEL_INPUT_IMAGE		= 5;											
localparam CNN_ACCEL_INPUT_IMAGE_BASE 	= 6;	// DMA: Base address for the input image. 
localparam CNN_ACCEL_INPUT_IMAGE_LOAD 	= 7;	// DMA: Start
localparam CNN_ACCEL_LAYER_START		= 8;	// Start
localparam CNN_ACCEL_LAYER_DONE			= 9;	// Done


// Configuration registers 
reg [W_REGS-1:0] 		q_sel_sl_reg;
reg 					q_ld_sl_reg;
reg [W_SIZE-1 :0] 		q_width;
reg [W_SIZE-1 :0] 		q_height;
reg [W_DELAY-1:0] 		q_start_up_delay;
reg [W_DELAY-1:0] 		q_hsync_delay;
reg [W_FRAME_SIZE-1:0] 	q_frame_size;
reg [3:0] 	q_layer_index;
reg 		q_is_first_layer;
reg 		q_is_last_layer;
reg 		q_start;
reg 		q_act_type;				// 0: RELU, 1: Linear
reg 		q_is_conv3x3;			// 1: 3x3 conv, 0: 1x1 conv 
reg [ 2:0] 	q_act_shift;			// Activation shift
reg [ 4:0] 	q_bias_shift;			// Bias Shift (before adding a bias)
reg [19:0] 	q_base_addr_weight;
reg [11:0] 	q_base_addr_param;
reg 		q_layer_done;
// Signals for sliding windows and FSM
wire 					ctrl_vsync_run;
wire [W_DELAY-1:0]		ctrl_vsync_cnt;
wire 					ctrl_hsync_run;
wire [W_DELAY-1:0]		ctrl_hsync_cnt;
wire 					ctrl_data_run;
wire [W_SIZE-1:0] 		row;
wire [W_SIZE-1:0] 		col;
wire [W_FRAME_SIZE-1:0] data_count;
wire [3:0] pix_idx;
// DMA for the input image
reg [31:0] 				q_input_pixel_data;
reg [FRAME_SIZE_W-1:0] 	q_input_pixel_addr;
reg 					q_input_image_load;
reg [W_ADDR-1:0] 		q_input_image_base_addr;
reg 					load_image_done;
wire 					end_frame;

// Convolutional signals
reg [WI-1:0] in_img [0:FRAME_SIZE-1];// Input image
reg [FRAME_SIZE_W-1:0] in_pixel_count;
//{{{
parameter MAX_TRANS = 1024; //Maximum number of transfers
parameter BITS_TRANS = $clog2(MAX_TRANS);
localparam ST_IMG_IDLE 			= 0,
		ST_IMG_LINE_DATA_LOAD 	= 1,
		ST_IMG_LINE_DATA_WAIT 	= 2,
		ST_IMG_DONE				= 3;
		
reg [1:0]   c_state_dma, n_state_dma;
wire [W_DATA-1:0]		data_o_ld;
wire					data_vld_o_ld;
wire					data_last_o_ld;
reg [W_ADDR-1:0]		start_addr_ld;
reg [W_SIZE-1:0]		start_line_ld;
reg 					start_dma_ld;
reg	[BITS_TRANS-1:0]	num_trans_ld;
wire[BITS_TRANS-1:0]	data_cnt_o; 		//counting the number of data output
//}}}

reg [9*To*Ti*WI-1:0] 	win_buf;	 // Weight registers
reg [To*Ti*WI-1:0] win;				 // Weight
reg [Ti*WI-1:0] din;				 // Input block data
reg vld_i;							 // Input valid signal
wire[To*ACT_BITS-1:0] acc_o;		 // Output block data
wire[To-1:0] vld_o;					 // Output valid signal
reg [To*PARAM_BITS-1:0] scale;		 // Scales (Batch normalization)
reg [To*PARAM_BITS-1:0] bias;		 // Biases
wire frame_done[0:3];

// Weight/bias/scale buffer's signals
// weight
reg 			     weight_buf_en; 	   // primary enable
reg 			     weight_buf_en_d; 	   // primary enable
reg 			     weight_buf_we; 	   // primary synchronous write enable
reg [W_CELL-1:0]     weight_buf_addr;      // address for read/write
reg [W_CELL-1:0]     weight_buf_addr_d;	   // 1-cycle delay address
wire[Ti*WI-1:0]      weight_buf_dout;      // Output for weights
// bias/scale
reg 			       param_buf_en; 	     // primary enable
reg 			       param_buf_en_d; 	     // primary enable
reg 			       param_buf_we; 	     // primary synchronous write enable
reg [W_CELL_PARAM-1:0] param_buf_addr;   	 // address for read/write
reg [W_CELL_PARAM-1:0] param_buf_addr_d;	 // 1-cycle delay address
wire[PARAM_BITS-1:0]   param_buf_dout_bias;  // Output for biases
wire[PARAM_BITS-1:0]   param_buf_dout_scale; // Output for scales

// Feature map buffers
reg [FRAME_SIZE_W-1:0] 	fmap_buf_addrb;
reg 					fmap_buf_enb01;
reg 					fmap_buf_enb02;
wire[To*ACT_BITS-1:0]  	fmap_buf_dob01;
wire[To*ACT_BITS-1:0]  	fmap_buf_dob02;
reg [FRAME_SIZE_W-1:0] pixel_count;
reg layer_done;
reg out_buff_sel;

// Boundary-checking flags
wire is_first_row;
wire is_last_row ;
wire is_first_col;
wire is_last_col ;
// One-cycle delay signals
reg ctrl_data_run_d;
reg [3:0] pix_idx_d;
reg is_first_row_d;
reg is_last_row_d ;
reg is_first_col_d;
reg is_last_col_d ;

// Clock and reset
wire clk, rstn;
assign clk = HCLK;
assign rstn = HRESETn;
//----------------------------------------------------------
// Decode Stage: Address Phase
//----------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin
	if(~HRESETn)
	begin
		//control
		q_sel_sl_reg <= 0;
		q_ld_sl_reg <= 1'b0;
		q_input_pixel_addr <= 0;
	end	
	else begin
		if(sl_HSEL && sl_HREADY && ((sl_HTRANS == `TRANS_NONSEQ) || (sl_HTRANS == `TRANS_SEQ)))
		begin
			q_sel_sl_reg 		<= sl_HADDR[W_REGS+W_WB_DATA-1:W_WB_DATA];
			q_ld_sl_reg 		<= sl_HWRITE;
			q_input_pixel_addr 	<= sl_HADDR[(2+FRAME_SIZE_W+W_REGS+W_WB_DATA-1):(2+W_REGS+W_WB_DATA)];	// 4-byte data => 2 bits
		end
		else begin
			q_ld_sl_reg <= 1'b0;
		end
	end
end	
//----------------------------------------------------------
// Decode Stage: Data Phase
//----------------------------------------------------------
always @(posedge HCLK or negedge HRESETn)
begin
	if(!HRESETn)
	begin
		//control
		q_width 				<= WIDTH;
		q_height 				<= HEIGHT;
		q_start_up_delay 		<= START_UP_DELAY;
		q_hsync_delay 			<= HSYNC_DELAY;		
		q_frame_size 			<= FRAME_SIZE;
		q_start 				<= 1'b0;
		q_act_type				<= 2'b0;
		q_layer_index			<= 4'd0;		
		q_is_conv3x3	  		<= 1'b0;
		q_is_first_layer		<= 1'b0;
		q_is_last_layer			<= 1'b0;
		q_bias_shift 			<= 9;
		q_act_shift 			<= 7;		
		q_base_addr_weight  	<= 0;
		q_base_addr_param    	<= 0;		
		q_layer_done			<= 1'b0;
		q_input_pixel_data		<= 0;
		q_input_image_load		<= 0;
		q_input_image_base_addr	<= 0;		
	end 
	else begin
		//data-transfer state(data phase)
		if(q_ld_sl_reg)
		begin
			case(q_sel_sl_reg)
				CNN_ACCEL_FRAME_SIZE: 	q_frame_size <= sl_HWDATA[W_FRAME_SIZE-1 :0];
				CNN_ACCEL_WIDTH_HEIGHT: begin 
					q_width 	<= sl_HWDATA[W_SIZE-1 :0];
					q_height 	<= sl_HWDATA[(W_SIZE+16-1):16];
				end
				CNN_ACCEL_DELAY_PARAMS: begin
					q_start_up_delay 	<= sl_HWDATA[W_DELAY-1 :0];
					q_hsync_delay	 	<= sl_HWDATA[2*W_DELAY-1:W_DELAY];
				end
				CNN_ACCEL_BASE_ADDRESS: begin
					q_base_addr_weight  <= sl_HWDATA[19: 0];
					q_base_addr_param	<= sl_HWDATA[31:20];
				end
				CNN_ACCEL_LAYER_CONFIG: begin
					q_is_first_layer 	<= sl_HWDATA[0];
					q_is_last_layer		<= sl_HWDATA[1];
					q_is_conv3x3		<= sl_HWDATA[2];
					q_act_type			<= sl_HWDATA[3];
					q_layer_index		<= sl_HWDATA[7:4];
					q_bias_shift		<= sl_HWDATA[12:8];
					q_act_shift			<= sl_HWDATA[15:13];
				end
				CNN_ACCEL_INPUT_IMAGE: 		q_input_pixel_data <= sl_HWDATA;				
				CNN_ACCEL_INPUT_IMAGE_BASE: q_input_image_base_addr <= sl_HWDATA;
				CNN_ACCEL_INPUT_IMAGE_LOAD: q_input_image_load <= sl_HWDATA[0];
				CNN_ACCEL_LAYER_START: 	q_start <= sl_HWDATA[0];	
				CNN_ACCEL_LAYER_DONE: 	q_layer_done <= sl_HWDATA[0];			
			endcase
		end
	end
end

assign out_sl_HREADY = 1'b1;
assign out_sl_HRESP = `RESP_OKAY;
always @*
begin:rdata	
	case(q_sel_sl_reg)
		CNN_ACCEL_FRAME_SIZE: 		out_sl_HRDATA = q_frame_size;
		CNN_ACCEL_WIDTH_HEIGHT: 	out_sl_HRDATA = {q_height &16'hFFFF,q_width &16'hFFFF};
		CNN_ACCEL_DELAY_PARAMS: 	out_sl_HRDATA = {q_hsync_delay,q_start_up_delay};
		CNN_ACCEL_BASE_ADDRESS: 	out_sl_HRDATA = {q_base_addr_param & 12'hFFF, q_base_addr_weight & 20'hFFFFF};
		CNN_ACCEL_LAYER_CONFIG: 	out_sl_HRDATA = {q_act_shift, q_bias_shift, q_layer_index, q_act_type, q_is_conv3x3, q_is_last_layer, q_is_first_layer};
		CNN_ACCEL_INPUT_IMAGE: 		out_sl_HRDATA = q_input_pixel_data;			
		CNN_ACCEL_INPUT_IMAGE_BASE: out_sl_HRDATA = q_input_image_base_addr;		
		CNN_ACCEL_INPUT_IMAGE_LOAD: out_sl_HRDATA = load_image_done;
		CNN_ACCEL_LAYER_START:  	out_sl_HRDATA = q_start;
		CNN_ACCEL_LAYER_DONE: 		out_sl_HRDATA = layer_done;	
		default: out_sl_HRDATA = 32'h0;
	endcase
end
//-------------------------------------------------
// FSM
//-------------------------------------------------
cnn_fsm u_cnn_fsm (
.clk(clk),
.rstn(rstn),
// Inputs
.q_is_conv3x3(q_is_conv3x3),
.q_width(q_width),
.q_height(q_height),
.q_start_up_delay(q_start_up_delay),
.q_hsync_delay(q_hsync_delay),
.q_frame_size(q_frame_size),
.q_start(q_start),
//output
.o_ctrl_vsync_run(ctrl_vsync_run),
.o_ctrl_vsync_cnt(ctrl_vsync_cnt),
.o_ctrl_hsync_run(ctrl_hsync_run),
.o_ctrl_hsync_cnt(ctrl_hsync_cnt),
.o_ctrl_data_run(ctrl_data_run),
.o_row(row),
.o_col(col),
.o_data_count(data_count),
.o_end_frame(end_frame),
.o_pix_idx(pix_idx)
);

//-------------------------------------------------------------------------------
// Input feature buffer
//-------------------------------------------------------------------------------
//initial begin
//	$readmemh(INFILE, in_img ,0,FRAME_SIZE-1);
//end
integer k;
always@(posedge clk, negedge rstn)begin
    if(~rstn) begin	
		in_pixel_count <= 0;
	end
	else begin
		if(data_vld_o_ld) begin
			// [FILLED] Input feature buffer address counter
			if(in_pixel_count == q_frame_size-1)
				in_pixel_count <= 0;
			else 
				in_pixel_count <= in_pixel_count + 1;
		end
	end
end
			
always@(posedge clk, negedge rstn)begin
    if(~rstn) begin	
		for(k = 0; k < FRAME_SIZE; k=k+1) begin
			in_img[k] <= 8'd0;			
		end
	end
	else begin
		if(data_vld_o_ld) begin
			// [FILLED] Store DMA-loaded LR input pixel into on-chip buffer
			in_img[in_pixel_count] <= data_o_ld[7:0];
		end
	end
end

//-------------------------------------------------------------------------------
// DMA for loading the input image
//-------------------------------------------------------------------------------
always@(posedge clk, negedge rstn)begin
    if(~rstn) 	
		c_state_dma <= ST_IMG_IDLE;  
	else begin
		c_state_dma <= n_state_dma;
	end
end

always @(*) begin: dma2buf_fsm
	n_state_dma = c_state_dma;
	case(c_state_dma)
		ST_IMG_IDLE: begin
			if(q_input_image_load)
				n_state_dma = ST_IMG_LINE_DATA_LOAD;
			else 
				n_state_dma = ST_IMG_IDLE;
		end
		ST_IMG_LINE_DATA_LOAD: begin
			n_state_dma = ST_IMG_LINE_DATA_WAIT;	
		end
		ST_IMG_LINE_DATA_WAIT: begin
			if(data_last_o_ld) begin	
				if(start_line_ld == q_height-1)
					n_state_dma = ST_IMG_DONE;
				else 
					n_state_dma = ST_IMG_LINE_DATA_LOAD;
			end
			else
				n_state_dma = ST_IMG_LINE_DATA_WAIT;
		end
		ST_IMG_DONE:
			n_state_dma = ST_IMG_IDLE;	
		default:
			n_state_dma = ST_IMG_IDLE;	
	endcase
end

// Sending a request
always @(*) begin	
	start_dma_ld = 1'b0;
	num_trans_ld = q_width;	
	if(c_state_dma == ST_IMG_LINE_DATA_LOAD) begin	
		start_dma_ld = 1'b1;
	end
end 

// Update request address and line counter
always@(posedge clk, negedge rstn)begin
    if(~rstn) begin	
		start_addr_ld 	<= 0;
		start_line_ld 	<= 0;
		load_image_done <= 0;
	end
	else begin
		if(q_ld_sl_reg && q_sel_sl_reg == CNN_ACCEL_INPUT_IMAGE_LOAD) begin // Reset signals
			start_line_ld 	<= 0;
			start_addr_ld 	<= q_input_image_base_addr;
			load_image_done <= 0;
		end
		else begin
			if(data_last_o_ld) begin	// End of loading a line
				if(start_line_ld == q_height-1) begin	// Last line
					start_line_ld <= 0;
					start_addr_ld <= q_input_image_base_addr;
					load_image_done <= 1'b1;
				end
				else begin	// Normal line
					start_line_ld <= start_line_ld + 1;
					start_addr_ld <= start_addr_ld + {q_width,2'b00};
				end
			end
		end
	end
end

 dma2buf
 u_dma2buf (
	//input bus signals
	.HREADY(HREADY),
	.HRESP (HRESP),
	.HRDATA(HRDATA),
	// output bus signals
	.out_HADDR	(out_HADDR),
	.out_HWDATA	(out_HWDATA),
	.out_HWRITE	(out_HWRITE),
	.out_HSIZE	(out_HSIZE),
	.out_HBURST	(out_HBURST),
	.out_HTRANS	(out_HTRANS),
	.out_HMASTLOCK(out_HMASTLOCK),
	.out_HPROT(out_HPROT),	
	// input from a buffer controller
	.start_dma  (start_dma_ld),
	.num_trans  (num_trans_ld),
	.start_addr (start_addr_ld),
	// output to a buffer
	.data_o		(data_o_ld),
	.data_vld_o	(data_vld_o_ld),
	.data_last_o(data_last_o_ld),
	.data_cnt_o(data_cnt_o),
	// global signals
	.clk   (HCLK),
	.resetn(HRESETn)
);

////-------------------------------------------------------------------------------
//// Dummy layer done
////-------------------------------------------------------------------------------
//always@(posedge HCLK, negedge HRESETn)
//begin
//    if(~HRESETn) begin
//		layer_done <= 1'b0;
//    end
//	else begin
//		if(q_start)
//			layer_done <= 0;
//		else if(end_frame)
//			layer_done <= 1;
//	end
//end
//
////-------------------------------------------------
//// Image Writer
////-------------------------------------------------
//// synopsys translate_off
////wire write_image_by_cpu_done;
//wire write_image_by_dma_done;
////bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE("out/input_image_by_cpu.bmp"))
////u_bmp_image_writer_00(
////./*input 			*/clk(clk),
////./*input 			*/rstn(rstn),
////./*input [WI-1:0] 	*/din(sl_HWDATA[7:0]),
////./*input 			*/vld(q_ld_sl_reg && (q_sel_sl_reg == CNN_ACCEL_INPUT_IMAGE)),
////./*output reg 		*/frame_done(write_image_by_cpu_done)
////);
//
//bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE("out/input_image_by_dma.bmp"))
//u_bmp_image_writer_01(
//./*input 			*/clk(clk),
//./*input 			*/rstn(rstn),
//./*input [WI-1:0] 	*/din(data_o_ld[7:0]),
//./*input 			*/vld(data_vld_o_ld),
//./*output reg 		*/frame_done(write_image_by_dma_done)
//);
//// synopsys translate_on

//-------------------------------------------------------------------------------
// Generate vld_i, din, win
//-------------------------------------------------------------------------------
always@(*) begin
	fmap_buf_addrb = 0;
	fmap_buf_enb01 = 0;
	fmap_buf_enb02 = 0;
	if(!q_is_first_layer) begin
		fmap_buf_enb01 =  out_buff_sel & ctrl_data_run;
		fmap_buf_enb02 = !out_buff_sel & ctrl_data_run;	
		if(q_is_conv3x3) begin
			case(pix_idx) 
				4'd0: fmap_buf_addrb = (is_first_row | is_first_col)? data_count: (data_count - q_width - 1);
				4'd1: fmap_buf_addrb = (is_first_row               )? data_count: (data_count - q_width    );
				4'd2: fmap_buf_addrb = (is_first_row | is_last_col )? data_count: (data_count - q_width + 1);
				4'd3: fmap_buf_addrb = (			   is_first_col)? data_count: (data_count           - 1);
				4'd4: fmap_buf_addrb = 								         	   data_count               ;		
				4'd5: fmap_buf_addrb = (               is_last_col )? data_count: (data_count           + 1);
				4'd6: fmap_buf_addrb = (is_last_row  | is_first_col)? data_count: (data_count + q_width - 1);
				4'd7: fmap_buf_addrb = (is_last_row  		       )? data_count: (data_count + q_width    );
				4'd8: fmap_buf_addrb = (is_last_row  | is_last_col )? data_count: (data_count + q_width + 1);		
				default: begin
				end			
			endcase
		end
		else begin
			fmap_buf_addrb = data_count;
		end
	end
end

assign is_first_row = (row==0)?1'b1:1'b0;
assign is_last_row  = (row==q_height-1)?1'b1:1'b0;
assign is_first_col = (col==0)?1'b1:1'b0;
assign is_last_col  = (col==q_width-1)?1'b1:1'b0;

always@(posedge clk, negedge rstn)begin
    if(~rstn) begin
		is_first_row_d  <= 1'b0; 
		is_last_row_d  	<= 1'b0; 
		is_first_col_d 	<= 1'b0; 
		is_last_col_d  	<= 1'b0; 
		ctrl_data_run_d <= 1'b0;
		pix_idx_d		<= 4'd0;
	end
	else begin
		is_first_row_d  <= is_first_row; 
		is_last_row_d  	<= is_last_row; 
		is_first_col_d 	<= is_first_col; 
		is_last_col_d  	<= is_last_col; 	
		ctrl_data_run_d <= ctrl_data_run;
		pix_idx_d       <= pix_idx;
	end
end
always@(*) begin	
	vld_i  = 0;
	din    = 0;
	win    = 0;
	// First layer
	if(q_is_first_layer) begin
		vld_i = ctrl_data_run;
		din[0*WI+:WI] = (is_first_row | is_first_col)? 8'd0: in_img[data_count - q_width - 1];
		din[1*WI+:WI] = (is_first_row               )? 8'd0: in_img[data_count - q_width    ];
		din[2*WI+:WI] = (is_first_row | is_last_col )? 8'd0: in_img[data_count - q_width + 1];
		din[3*WI+:WI] = (				is_first_col)? 8'd0: in_img[data_count           - 1];
		din[4*WI+:WI] = 								     in_img[data_count              ];
		din[5*WI+:WI] = (               is_last_col )? 8'd0: in_img[data_count           + 1];
		din[6*WI+:WI] = (is_last_row  | is_first_col)? 8'd0: in_img[data_count + q_width - 1];
		din[7*WI+:WI] = (is_last_row  		        )? 8'd0: in_img[data_count + q_width    ];
		din[8*WI+:WI] = (is_last_row  | is_last_col )? 8'd0: in_img[data_count + q_width + 1];		
		win   = win_buf[0+:To*Ti*WI];
	end
	else begin
		vld_i = ctrl_data_run_d;
		if(ctrl_data_run_d) begin
			if(q_is_conv3x3) begin		// CONV3x3					
				if(out_buff_sel) begin
					case(pix_idx_d) 
						4'd0: din = (is_first_row_d | is_first_col_d)? 'd0: fmap_buf_dob01;
						4'd1: din = (is_first_row_d                 )? 'd0: fmap_buf_dob01;
						4'd2: din = (is_first_row_d | is_last_col_d )? 'd0: fmap_buf_dob01;
						4'd3: din = (				  is_first_col_d)? 'd0: fmap_buf_dob01;
						4'd4: din = 								        fmap_buf_dob01;		
						4'd5: din = (                 is_last_col_d )? 'd0: fmap_buf_dob01;
						4'd6: din = (is_last_row_d  | is_first_col_d)? 'd0: fmap_buf_dob01;
						4'd7: din = (is_last_row_d  		        )? 'd0: fmap_buf_dob01;
						4'd8: din = (is_last_row_d  | is_last_col_d )? 'd0: fmap_buf_dob01;
						default: begin
						end			
					endcase
				end 
				else begin
					case(pix_idx_d) 
						4'd0: din = (is_first_row_d | is_first_col_d)? 'd0: fmap_buf_dob02;
						4'd1: din = (is_first_row_d                 )? 'd0: fmap_buf_dob02;
						4'd2: din = (is_first_row_d | is_last_col_d )? 'd0: fmap_buf_dob02;
						4'd3: din = (				  is_first_col_d)? 'd0: fmap_buf_dob02;
						4'd4: din = 								        fmap_buf_dob02;		
						4'd5: din = (                 is_last_col_d )? 'd0: fmap_buf_dob02;
						4'd6: din = (is_last_row_d  | is_first_col_d)? 'd0: fmap_buf_dob02;
						4'd7: din = (is_last_row_d  		        )? 'd0: fmap_buf_dob02;
						4'd8: din = (is_last_row_d  | is_last_col_d )? 'd0: fmap_buf_dob02;
						default: begin
						end			
					endcase			
				end
				win = win_buf[pix_idx_d*(To*Ti*WI)+:(To*Ti*WI)];
			end
			else begin					// CONV1x1
				din = out_buff_sel ? fmap_buf_dob01 : fmap_buf_dob02;
				win = win_buf[0+:To*Ti*WI];
			end
		end
	end
end
//-------------------------------------------------------------------------------
// Weights, biases, scales 
//-------------------------------------------------------------------------------
// Weight
always@(*) begin
	weight_buf_en   = 1'b0;
	weight_buf_we   = 1'b0;
	weight_buf_addr = {W_CELL{1'b0}};
	if(ctrl_vsync_run) begin
		if(!q_is_conv3x3) begin	// Conv1x1
			if(ctrl_vsync_cnt < To) begin
				weight_buf_en   = 1'b1;
				weight_buf_we   = 1'b0;
				weight_buf_addr = q_base_addr_weight + ctrl_vsync_cnt[W_CELL-1:0];
			end
		end
		else begin 				// Conv3x3
			if(ctrl_vsync_cnt < To*9) begin
				weight_buf_en   = 1'b1;
				weight_buf_we   = 1'b0;
				weight_buf_addr = q_base_addr_weight + ctrl_vsync_cnt[W_CELL-1:0];
			end
		end 
	end
end

// Scale/bias
always@(*) begin
	param_buf_en   = 1'b0;
	param_buf_we   = 1'b0;
	param_buf_addr = {W_CELL{1'b0}};
	if(ctrl_vsync_run) begin
		if(ctrl_vsync_cnt < To) begin
			param_buf_en   = 1'b1;
			param_buf_we   = 1'b0;
			param_buf_addr = q_base_addr_param + ctrl_vsync_cnt[W_CELL-1:0];
		end
	end
end

// One-cycle delay
always@(posedge clk, negedge rstn)begin
    if(~rstn) begin
		weight_buf_en_d   <= 1'b0;
		weight_buf_addr_d <= {W_CELL{1'b0}};	
		param_buf_en_d 	  <= 1'b0;
		param_buf_addr_d  <= {W_CELL{1'b0}};
	end
	else begin		
		weight_buf_en_d   <= weight_buf_en; 
		weight_buf_addr_d <= weight_buf_addr - q_base_addr_weight;
		param_buf_en_d 	  <= param_buf_en;	 
		param_buf_addr_d  <= param_buf_addr  - q_base_addr_param;
	end
end

// Update weight/bias/scale buffers
always@(posedge clk, negedge rstn)begin
    if(~rstn) begin
		win_buf <= {(9*To*Ti*WI){1'b0}};
		bias    <= {(To*PARAM_BITS){1'b0}};
		scale   <= {(To*PARAM_BITS){1'b0}};
	end
	else begin
		// Weight
		if(weight_buf_en_d)
			win_buf[(weight_buf_addr_d*Ti*WI)+:(Ti*WI)] <= weight_buf_dout;
		// Bias/scale
		if(param_buf_en_d) begin
			bias [(param_buf_addr_d*PARAM_BITS)+:PARAM_BITS] <= param_buf_dout_bias;
			scale[(param_buf_addr_d*PARAM_BITS)+:PARAM_BITS] <= param_buf_dout_scale;
		end
	end
end

// Weight buffer
spram #(.INIT_FILE("input_data/all_conv_weights.hex"),
		.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
		.W_DATA(Ti*WI),.W_WORD(W_CELL),.N_WORD(N_CELL))
u_buf_weight(
    .clk (clk            ), 
    .en  (weight_buf_en  ), 
    .addr(weight_buf_addr), 
    .din (/*unused*/     ), 
    .we  (weight_buf_we  ), 
    .dout(weight_buf_dout)  
);
// Bias buffer
spram #(.INIT_FILE("input_data/all_conv_biases.hex"),
		.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
		.W_DATA(PARAM_BITS),.W_WORD(W_CELL_PARAM),.N_WORD(N_CELL_PARAM))
u_buf_bias(
    .clk (clk                ), 
    .en  (param_buf_en       ), 
    .addr(param_buf_addr     ), 
    .din (/*unused*/         ), 
    .we  (param_buf_we       ), 
    .dout(param_buf_dout_bias)  
);
// Scale buffer
spram #(.INIT_FILE("input_data/all_conv_scales.hex"),
		.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
		.W_DATA(PARAM_BITS),.W_WORD(W_CELL_PARAM),.N_WORD(N_CELL_PARAM))
u_buf_scale(
    .clk (clk                 ), 
    .en  (param_buf_en        ), 
    .addr(param_buf_addr      ), 
    .din (/*unused*/          ), 
    .we  (param_buf_we        ), 
    .dout(param_buf_dout_scale)  
);
//-------------------------------------------------------------------------------
// Computing units
//-------------------------------------------------------------------------------
generate
    genvar i;
    for (i=0; i<To; i=i+1) begin: u_conv_kern
		conv_kern u_conv_kern(
		./*input 				 */clk(clk),
		./*input 				 */rstn(rstn),
		./*input 				 */is_last_layer(q_is_last_layer),
		./*input [PARAM_BITS-1:0]*/scale(scale[(i*PARAM_BITS)+:PARAM_BITS]),
		./*input [PARAM_BITS-1:0]*/bias(bias[(i*PARAM_BITS)+:PARAM_BITS]),
		./*input [2:0] 			 */act_shift(q_act_shift),
		./*input [4:0] 			 */bias_shift(q_bias_shift),
		./*input 				 */is_conv3x3(q_is_conv3x3),			//0: 1x1, 1:3x3
		./*input 				 */vld_i(vld_i),
		./*input [N*WI-1:0] 	 */win(win[(i*Ti*WI)+:(Ti*WI)]),
		./*input [N*WI-1:0] 	 */din(din),
		./*output [ACT_BITS-1:0] */acc_o(acc_o[(i*ACT_BITS)+:ACT_BITS]),
		./*output 				 */vld_o(vld_o[i])
		);	
    end
endgenerate

//-------------------------------------------------
// Output buffers.
//-------------------------------------------------
dpram #(.W_DATA(To*ACT_BITS), .W_WORD(FRAME_SIZE_W),.N_WORD(FRAME_SIZE))
u_fmap_buff_01(
   .clk   (clk   ),
   .ena   ((!out_buff_sel) & vld_o[0]), 
   .wea   ((!out_buff_sel) & vld_o[0]), 
   .addra (pixel_count   ), 
   .enb   (fmap_buf_enb01),	
   .addrb (fmap_buf_addrb), 
   .dia   (acc_o         ), 
   .dob   (fmap_buf_dob01)  
);

dpram #(.W_DATA(To*ACT_BITS), .W_WORD(FRAME_SIZE_W),.N_WORD(FRAME_SIZE))
u_fmap_buff_02(
   .clk   (clk   ),
   .ena   (out_buff_sel & vld_o[0]), 
   .wea   (out_buff_sel & vld_o[0]), 
   .addra (pixel_count   ), 
   .enb   (fmap_buf_enb02),	
   .addrb (fmap_buf_addrb), 
   .dia   (acc_o         ), 
   .dob   (fmap_buf_dob02)  
);
//-------------------------------------------------
// Update the output buffers.
//-------------------------------------------------
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
		pixel_count <= 0;
		layer_done <= 0;
		out_buff_sel <= 1'b0;
    end else begin
		if(q_start) begin
			pixel_count <= 0;
			layer_done <= 0;			
		end
		else begin
			if(vld_o[0]) begin
				if(pixel_count == q_frame_size-1) begin
					pixel_count <= 0;
					layer_done <= 1'b1;
					out_buff_sel <= !out_buff_sel;
				end
				else begin
					pixel_count <= pixel_count + 1;
				end
			end
		end
    end
end

//---------------------------------------------------------------
// [MODIFIED / NEW] Term Project 2026 Summer - Problem 1-3
// Sub-pixel layer (sr_flat + lp_sres) — synthesizable RTL
//  - Last CONV produces 4 residual pixels (ch0..ch3)
//  - Each is added with the corresponding LR input (NN upsample)
//  - Pack 4 HR pixels into 32-bit word for the HR BMP writer
//---------------------------------------------------------------
wire signed [7:0] res_ch0 = $signed(acc_o[0*ACT_BITS+:ACT_BITS]);
wire signed [7:0] res_ch1 = $signed(acc_o[1*ACT_BITS+:ACT_BITS]);
wire signed [7:0] res_ch2 = $signed(acc_o[2*ACT_BITS+:ACT_BITS]);
wire signed [7:0] res_ch3 = $signed(acc_o[3*ACT_BITS+:ACT_BITS]);
wire [7:0]        lr_pix  = in_img[pixel_count];

wire signed [8:0] sum_ch0 = res_ch0 + $signed({1'b0, lr_pix});
wire signed [8:0] sum_ch1 = res_ch1 + $signed({1'b0, lr_pix});
wire signed [8:0] sum_ch2 = res_ch2 + $signed({1'b0, lr_pix});
wire signed [8:0] sum_ch3 = res_ch3 + $signed({1'b0, lr_pix});

// Clip to 8-bit unsigned range [0,255]
wire [7:0] hr_ch0 = (sum_ch0 < 0) ? 8'd0 : (sum_ch0 > 9'sd255) ? 8'd255 : sum_ch0[7:0];
wire [7:0] hr_ch1 = (sum_ch1 < 0) ? 8'd0 : (sum_ch1 > 9'sd255) ? 8'd255 : sum_ch1[7:0];
wire [7:0] hr_ch2 = (sum_ch2 < 0) ? 8'd0 : (sum_ch2 > 9'sd255) ? 8'd255 : sum_ch2[7:0];
wire [7:0] hr_ch3 = (sum_ch3 < 0) ? 8'd0 : (sum_ch3 > 9'sd255) ? 8'd255 : sum_ch3[7:0];

wire [31:0] hr_pixel_32b = {hr_ch3, hr_ch2, hr_ch1, hr_ch0};

//-------------------------------------------------
// Image Writer (simulation only)
//-------------------------------------------------
// synopsys translate_off
wire hr_frame_done;

bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE00))
u_bmp_image_writer_00(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[0*ACT_BITS+:ACT_BITS]),
./*input 			*/vld(vld_o[0] && q_is_last_layer),
./*output reg 		*/frame_done(frame_done[0])
);

bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE01))
u_bmp_image_writer_01(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[1*ACT_BITS+:ACT_BITS]),
./*input 			*/vld(vld_o[1] && q_is_last_layer),
./*output reg 		*/frame_done(frame_done[1])
);

bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE02))
u_bmp_image_writer_02(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[2*ACT_BITS+:ACT_BITS]),
./*input 			*/vld(vld_o[2] && q_is_last_layer),
./*output reg 		*/frame_done(frame_done[2])
);

bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE03))
u_bmp_image_writer_03(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[3*ACT_BITS+:ACT_BITS]),
./*input 			*/vld(vld_o[3] && q_is_last_layer),
./*output reg 		*/frame_done(frame_done[3])
);

// [NEW] 32-bit BMP writer -> 256x256 high-resolution image
bmp_image_writer_32bit#(
	.WIDTH(WIDTH),
	.HEIGHT(HEIGHT),
	.OUTFILE("./out/convout_hr.bmp")
) u_bmp_image_writer_hr (
	.clk(clk),
	.rstn(rstn),
	.din(hr_pixel_32b),
	.vld(vld_o[0] && q_is_last_layer),
	.frame_done(hr_frame_done)
);

// Debugging file logging (Fig. 1-2)
// [CHECK] Disabled to speed up simulation. Uncomment for early CONV-layer debug.
/*
integer fp_output_L01;
integer fp_output_L02;
integer fp_output_L03;

integer idx;
always @(posedge clk or negedge rstn) begin
	if(~rstn) begin
		fp_output_L01 = $fopen("out/conv_output_L01.txt", "w");
		fp_output_L02 = $fopen("out/conv_output_L02.txt", "w");
		fp_output_L03 = $fopen("out/conv_output_L03.txt", "w");
		idx <= 0;
	end
	else begin
		if(q_start) begin
			case(q_layer_index)
				3'd0: fp_output_L01 = $fopen("out/conv_output_L01.txt", "w");
				3'd1: fp_output_L02 = $fopen("out/conv_output_L02.txt", "w");
				3'd2: fp_output_L03 = $fopen("out/conv_output_L03.txt", "w");
			endcase		
		end 		
		else if(vld_o[0]) begin
			for(idx = To*ACT_BITS/4-1; idx >= 0; idx=idx-1) begin
				if(idx == 0) begin
					case(q_layer_index)
						3'd0: $fwrite(fp_output_L01,"%01h\n", acc_o[idx*4+:4]);
						3'd1: $fwrite(fp_output_L02,"%01h\n", acc_o[idx*4+:4]);
						3'd2: $fwrite(fp_output_L03,"%01h\n", acc_o[idx*4+:4]);
					endcase
				end	
				else begin
					case(q_layer_index)
						3'd0: $fwrite(fp_output_L01,"%01h", acc_o[idx*4+:4]);
						3'd1: $fwrite(fp_output_L02,"%01h", acc_o[idx*4+:4]);
						3'd2: $fwrite(fp_output_L03,"%01h", acc_o[idx*4+:4]);
					endcase					
				end
			end
			if(pixel_count == q_frame_size-1) begin
				case(q_layer_index)			
					3'd0: $fclose(fp_output_L01);
					3'd1: $fclose(fp_output_L02);
					3'd2: $fclose(fp_output_L03);		
				endcase								
			end
		end
	end
end
*/
// synopsys translate_on				
endmodule
