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
	//Output pixel
	out_pixel,
	out_valid
);
//CLOCK
input 	HCLK;
input 	HRESETn;
//input signals of control port(slave)
input 					sl_HREADY;
input 					sl_HSEL;
input [`W_TRANS-1	:0] sl_HTRANS;
input [`W_BURST-1	:0] sl_HBURST;
input [`W_SIZE-1	:0] sl_HSIZE;
input [W_ADDR-1		:0] sl_HADDR;
input 					sl_HWRITE;
input [W_DATA-1		:0] sl_HWDATA;
//output signals of control port(slave)
output 					out_sl_HREADY;				
output [`W_RESP-1   :0] out_sl_HRESP;
output reg [W_DATA-1:0] out_sl_HRDATA;
output     [31      :0] out_pixel;
output 					out_valid;
//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
parameter Ti = 16;	// Each CONV kernel do 16 multipliers at the same time	
//parameter To = 4;	// Run 4 CONV kernels at the same time
parameter To = 16;	// Run 16 CONV kernels at the same time

parameter WI 				= 8;
parameter N  				= 16;
parameter WN 				= $clog2(N);
parameter WO 				= 2*(WI+1) + WN;
parameter PARAM_BITS 		= 16;
parameter WEIGHT_BITS 		= 8;
parameter ACT_BITS			= 8;
parameter DATA_BITS 		= WO;
localparam CONV3x3_DELAY 	= 9;
localparam CONV3x3_DELAY_W 	= 4;

localparam FRAME_SIZE 		= WIDTH * HEIGHT;
localparam FRAME_SIZE_W 	= $clog2(FRAME_SIZE);
localparam W_SIZE  			= 12;					// Max 4K QHD (3840x1920).
localparam W_FRAME_SIZE  	= 2 * W_SIZE + 1;	// Max 4K QHD (3840x1920).
localparam W_DELAY 			= 12;

// Block ram for weights
parameter N_DELAY 			= 1;	
parameter N_LAYER 			= 3;
parameter N_CELL  			= N_LAYER * (Ti*To*9)/N;
parameter N_CELL_PARAM		= N_LAYER * (To);
parameter W_CELL 			= $clog2(N_CELL);
parameter W_CELL_PARAM 		= $clog2(N_CELL_PARAM);	

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
reg 					load_image_done = 0;
wire 					end_frame;

// Convolutional signals
reg [WI-1:0] in_img [0:FRAME_SIZE-1];	// Input image
reg [Ti*WI-1:0] win[0:To-1];			// Weight
reg [Ti*WI-1:0] din;					// Input block data
reg vld_i;								// Input valid signal
wire [ACT_BITS-1:0] acc_o[0:To-1];		// Output block data
wire vld_o[0:To-1];						// Output valid signal
reg [PARAM_BITS-1:0] scale[0:To-1];		// Scales (Batch normalization)
reg [PARAM_BITS-1:0] bias[0:To-1];		// Biases
//wire frame_done[0:3];

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
integer ch_idx;


reg [FRAME_SIZE_W-1:0] pixel_count;
reg layer_done;
reg out_buff_sel;
// Clock and reset
wire clk, rstn;
assign clk = HCLK;
assign rstn = HRESETn;

// Boundary-checking flags
wire is_first_row;
wire is_last_row ;
wire is_first_col;
wire is_last_col ;
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
					//q_is_first_layer 	<= /*Insert your code*/;
					//q_is_last_layer	<= /*Insert your code*/;
					//q_is_conv3x3		<= /*Insert your code*/;
					//q_act_type		<= /*Insert your code*/;
					//q_layer_index		<= /*Insert your code*/;
					//q_bias_shift		<= /*Insert your code*/;
					//q_act_shift		<= /*Insert your code*/;
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
.clk				(clk				),
.rstn				(rstn				),
// Inputs
.q_is_conv3x3		(q_is_conv3x3		),
.q_width			(q_width			),
.q_height			(q_height			),
.q_start_up_delay	(q_start_up_delay	),
.q_hsync_delay		(q_hsync_delay		),
.q_frame_size		(q_frame_size		),
.q_start			(q_start			),
//output
.o_ctrl_vsync_run	(ctrl_vsync_run		),
.o_ctrl_vsync_cnt	(ctrl_vsync_cnt		),
.o_ctrl_hsync_run	(ctrl_hsync_run		),
.o_ctrl_hsync_cnt	(ctrl_hsync_cnt		),
.o_ctrl_data_run	(ctrl_data_run		),
.o_row				(row				),
.o_col				(col				),
.o_data_count		(data_count			),
.o_end_frame		(end_frame		    ),
.o_pix_idx			(pix_idx			)
);

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
				weight_buf_addr = ctrl_vsync_cnt[W_CELL-1:0];
			end
		end
		else begin				// Conv3x3
			// Insert your code
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
			//param_buf_en   = /*Insert your code*/;
			//param_buf_we   = /*Insert your code*/;
			//param_buf_addr = /*Insert your code*/;
	  
		end
	end
end
// one-cycle delay
always@(posedge clk, negedge rstn)begin
    if(~rstn) begin
		weight_buf_en_d   <= 1'b0;
		weight_buf_addr_d <= {W_CELL{1'b0}};	
		param_buf_en_d 	  <= 1'b0;
		param_buf_addr_d  <= {W_CELL{1'b0}};
	end
	else begin		
		weight_buf_en_d   <= weight_buf_en; 
		weight_buf_addr_d <= weight_buf_addr;
		param_buf_en_d 	  <= param_buf_en;	 
		param_buf_addr_d  <= param_buf_addr;
	end
end


always@(posedge clk, negedge rstn)begin
    if(~rstn) begin
		for(ch_idx = 0; ch_idx <To; ch_idx=ch_idx+1) begin
			win[ch_idx]  <= {(Ti*WI){1'b0}};
			bias[ch_idx] <= {PARAM_BITS{1'b0}};
			scale[ch_idx] <= {PARAM_BITS{1'b0}};
		end
	end
	else begin
		// Weight  
		if(weight_buf_en_d)
			win[weight_buf_addr_d] <= weight_buf_dout;
		// Scale/bias
		/*Insert your code*/
		
	end
end
// Weight buffer
spram #(.INIT_FILE("input_data/all_conv_weights.hex"),
		.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
		.W_DATA(Ti*WI),.W_WORD(W_CELL),.N_WORD(N_CELL))
u_buf_weight(
    .clk (clk            	 ), // Clock input
    .en  (weight_buf_en  	 ), // RAM enable (select)
    .addr(weight_buf_addr	 ), // Address input(word addressing)
    .din (/*unused*/     	 ), // Data input
    .we  (weight_buf_we  	 ), // Write enable
    .dout(weight_buf_dout	 )  // Data output
);
// Bias buffer
spram #(.INIT_FILE(/*Insert your code*/),
		.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
		.W_DATA(/*Insert your code*/),.W_WORD(W_CELL_PARAM),.N_WORD(N_CELL_PARAM))
u_buf_bias(
    .clk (clk                ), // Clock input
    .en  (param_buf_en       ), // RAM enable (select)
    .addr(param_buf_addr     ), // Address input(word addressing)
    .din (/*unused*/         ), // Data input
    .we  (param_buf_we       ), // Write enable
    .dout(param_buf_dout_bias)  // Data output
);
// Scale buffer
spram #(.INIT_FILE(/*Insert your code*/),
		.EN_LOAD_INIT_FILE(EN_LOAD_INIT_FILE),
		.W_DATA(/*Insert your code*/),.W_WORD(W_CELL_PARAM),.N_WORD(N_CELL_PARAM))
u_buf_scale(
    .clk (clk                 ), // Clock input
    .en  (/*Insert your code*/), // RAM enable (select)
    .addr(/*Insert your code*/), // Address input(word addressing)
    .din (/*unused*/          ), // Data input
    .we  (/*Insert your code*/), // Write enable
    .dout(/*Insert your code*/)  // Data output
);
//-------------------------------------------------------------------------------
// Input feature buffer
//-------------------------------------------------------------------------------
initial begin
	$readmemh(INFILE, in_img ,0,FRAME_SIZE-1);
end

// Boundary-checking flags
assign is_first_row = (row == 0			)?1'b1:1'b0;
assign is_last_row  = (row == q_height-1)?1'b1:1'b0;
assign is_first_col = (col == 0			)?1'b1:1'b0;
assign is_last_col  = (col == q_width-1	)?1'b1:1'b0;

always@(*) begin	
	vld_i  = 0;
	din    = 0;
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
	end
	else begin
		vld_i = ctrl_data_run;	//Dummy
	end
end

//-------------------------------------------------------------------------------																			 
// Computing units
//-------------------------------------------------------------------------------
generate
    genvar i;
    for (i=0; i<To; i=i+1) begin: u_conv_kern
		conv_kern u_conv_kern(
			./*input 				 */clk			(clk			),
			./*input 				 */rstn			(rstn			),
			./*input 				 */is_last_layer(q_is_last_layer),
			./*input [PARAM_BITS-1:0]*/scale		(scale[i]		),
			./*input [PARAM_BITS-1:0]*/bias			(bias[i]		),
			./*input [2:0] 			 */act_shift	(q_act_shift	),
			./*input [4:0] 			 */bias_shift	(q_bias_shift	),
			./*input 				 */is_conv3x3	(q_is_conv3x3	),			//0: 1x1, 1:3x3
			./*input 				 */vld_i		(vld_i			),
			./*input [N*WI-1:0] 	 */win			(win[i]			),
			./*input [N*WI-1:0] 	 */din			(din			),
			./*output [ACT_BITS-1:0] */acc_o		(acc_o[i]		),
			./*output 				 */vld_o		(vld_o[i]		)
		);	
    end
endgenerate

//-------------------------------------------------
// Output buffers.
//-------------------------------------------------
wire [ACT_BITS*To-1:0] all_acc_o = {
	acc_o[15], acc_o[14], acc_o[13], acc_o[12], 
	acc_o[11], acc_o[10], acc_o[ 9], acc_o[ 8],
	acc_o[ 7], acc_o[ 6], acc_o[ 5], acc_o[ 4],
	acc_o[ 3], acc_o[ 2], acc_o[ 1], acc_o[ 0]
};
dpram #(.W_DATA(To*ACT_BITS), .W_WORD(FRAME_SIZE_W),.N_WORD(FRAME_SIZE))
u_fmap_buff_01(
   .clk   (clk   					 ),
   .ena   ((!out_buff_sel) & vld_o[0]), 
   .wea   ((!out_buff_sel) & vld_o[0]), 
   .addra (pixel_count 				 ), 
   .enb   (/*OPEN*/ 				 ),	
   .addrb (/*OPEN*/ 				 ), 
   .dia   (all_acc_o				 ), 
   .dob   (/*OPEN*/ 				 )  
);

dpram #(.W_DATA(To*ACT_BITS), .W_WORD(FRAME_SIZE_W),.N_WORD(FRAME_SIZE))
u_fmap_buff_02(
   .clk   (clk   				    ),
   .ena   (out_buff_sel & vld_o[0]  ), 
   .wea   (out_buff_sel & vld_o[0]  ), 
   .addra (pixel_count              ), 
   .enb   (/*OPEN*/                 ),	
   .addrb (/*OPEN*/                 ), 
   .dia   (all_acc_o                ), 
   .dob   (/*OPEN*/                 )  
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

//-------------------------------------------------------------------------------
// Outputs
//-------------------------------------------------------------------------------	
assign out_pixel = {acc_o[3],acc_o[2],acc_o[1],acc_o[0]};
assign out_valid = vld_o[0];
						
endmodule
