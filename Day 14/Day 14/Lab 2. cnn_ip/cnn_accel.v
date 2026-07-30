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
	out_sl_HRDATA	
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
//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
parameter Ti = 16;	// Each CONV kernel do 16 multipliers at the same time	
parameter To = 4;	// Run 4 CONV kernels at the same time
//parameter To = 16;	// Run 16 CONV kernels at the same time

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
parameter N_DELAY 	= 1;	
parameter N_LAYER 		= 3;
parameter N_CELL  		= N_LAYER * (Ti*To*9)/N;
parameter N_CELL_PARAM	= N_LAYER * (To);
parameter W_CELL 		= $clog2(N_CELL);
parameter W_CELL_PARAM 	= $clog2(N_CELL_PARAM);	
			
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
// DMA for the input image
reg [31:0] 				q_input_pixel_data;
reg [FRAME_SIZE_W-1:0] 	q_input_pixel_addr;
reg 					q_input_image_load;
reg [W_ADDR-1:0] 		q_input_image_base_addr;
reg 					load_image_done = 0;
wire 					layer_done;
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
		q_bias_shift 			<= 5'd0;
		q_act_shift 			<= 3'd0;		
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
.o_end_frame(layer_done)
);

endmodule
