`timescale 1ns/1ps

module first_layer_tb;

// Image parameters
parameter BMP_HEADER_NUM = 54;
parameter WIDTH 	= 128;
parameter HEIGHT 	= 128;
parameter INFILE    = "./img/butterfly_08bit.hex";
parameter OUTFILE00   = "./out/convout_layer01_ch01.bmp";
parameter OUTFILE01   = "./out/convout_layer01_ch02.bmp";
parameter OUTFILE02   = "./out/convout_layer01_ch03.bmp";
parameter OUTFILE03   = "./out/convout_layer01_ch04.bmp";

parameter START_UP_DELAY = 100;
parameter HSYNC_DELAY = 160;


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


reg clk;
reg rstn;
reg is_last_layer;
reg [PARAM_BITS-1:0] scale[0:3];
reg [PARAM_BITS-1:0] bias[0:3];
reg [2:0] act_shift;
reg [4:0] bias_shift;
reg is_conv3x3;			//0: 1x1, 1:3x3
reg vld_i;
reg [N*WI-1:0] win[0:3];
reg [N*WI-1:0] din;
wire [ACT_BITS-1:0] acc_o[0:3];
wire vld_o[0:3];

localparam FRAME_SIZE = WIDTH * HEIGHT;
localparam FRAME_SIZE_W = $clog2(FRAME_SIZE);
reg [WI-1:0] in_img [0:FRAME_SIZE-1];	// Input image
wire frame_done[0:3];
integer row, col;

//-------------------------------------------------
// DUT: Convolution Kernels
//-------------------------------------------------
// Channel 00
conv_kern u_conv_kern_00(
./*input 				 */clk(clk),
./*input 				 */rstn(rstn),
./*input 				 */is_last_layer(is_last_layer),
./*input [PARAM_BITS-1:0]*/scale(scale[0]),
./*input [PARAM_BITS-1:0]*/bias(bias[0]),
./*input [2:0] 			 */act_shift(act_shift),
./*input [4:0] 			 */bias_shift(bias_shift),
./*input 				 */is_conv3x3(is_conv3x3),			//0: 1x1, 1:3x3
./*input 				 */vld_i(vld_i),
./*input [N*WI-1:0] 	 */win(win[0]),
./*input [N*WI-1:0] 	 */din(din),
./*output [ACT_BITS-1:0] */acc_o(acc_o[0]),
./*output 				 */vld_o(vld_o[0])
);

conv_kern u_conv_kern_01(
./*input 				 */clk(clk),
./*input 				 */rstn(rstn),
./*input 				 */is_last_layer(is_last_layer),
./*input [PARAM_BITS-1:0]*/scale(scale[1]),
./*input [PARAM_BITS-1:0]*/bias(bias[1]),
./*input [2:0] 			 */act_shift(act_shift),
./*input [4:0] 			 */bias_shift(bias_shift),
./*input 				 */is_conv3x3(is_conv3x3),			//0: 1x1, 1:3x3
./*input 				 */vld_i(vld_i),
./*input [N*WI-1:0] 	 */win(win[1]),
./*input [N*WI-1:0] 	 */din(din),
./*output [ACT_BITS-1:0] */acc_o(acc_o[1]),
./*output 				 */vld_o(vld_o[1])
);

conv_kern u_conv_kern_02(
./*input 				 */clk(clk),
./*input 				 */rstn(rstn),
./*input 				 */is_last_layer(is_last_layer),
./*input [PARAM_BITS-1:0]*/scale(scale[2]),
./*input [PARAM_BITS-1:0]*/bias(bias[2]),
./*input [2:0] 			 */act_shift(act_shift),
./*input [4:0] 			 */bias_shift(bias_shift),
./*input 				 */is_conv3x3(is_conv3x3),			//0: 1x1, 1:3x3
./*input 				 */vld_i(vld_i),
./*input [N*WI-1:0] 	 */win(win[2]),
./*input [N*WI-1:0] 	 */din(din),
./*output [ACT_BITS-1:0] */acc_o(acc_o[2]),
./*output 				 */vld_o(vld_o[2])
);

conv_kern u_conv_kern_03(
./*input 				 */clk(clk),
./*input 				 */rstn(rstn),
./*input 				 */is_last_layer(is_last_layer),
./*input [PARAM_BITS-1:0]*/scale(scale[3]),
./*input [PARAM_BITS-1:0]*/bias(bias[3]),
./*input [2:0] 			 */act_shift(act_shift),
./*input [4:0] 			 */bias_shift(bias_shift),
./*input 				 */is_conv3x3(is_conv3x3),			//0: 1x1, 1:3x3
./*input 				 */vld_i(vld_i),
./*input [N*WI-1:0] 	 */win(win[3]),
./*input [N*WI-1:0] 	 */din(din),
./*output [ACT_BITS-1:0] */acc_o(acc_o[3]),
./*output 				 */vld_o(vld_o[3])
);
//-------------------------------------------------
// Image Writer
//-------------------------------------------------
bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE00))
u_bmp_image_writer_00(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[0]),
./*input 			*/vld(vld_o[0]),
./*output reg 		*/frame_done(frame_done[0])
);

bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE01))
u_bmp_image_writer_01(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[1]),
./*input 			*/vld(vld_o[1]),
./*output reg 		*/frame_done(frame_done[1])
);

bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE02))
u_bmp_image_writer_02(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[2]),
./*input 			*/vld(vld_o[2]),
./*output reg 		*/frame_done(frame_done[2])
);

bmp_image_writer#(.WIDTH(WIDTH),.HEIGHT(HEIGHT),.OUTFILE(OUTFILE03))
u_bmp_image_writer_03(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input [WI-1:0] 	*/din(acc_o[3]),
./*input 			*/vld(vld_o[3]),
./*output reg 		*/frame_done(frame_done[3])
);
//-------------------------------------------------
// Test cases
//-------------------------------------------------
// Read the input file to memory
initial begin
	$readmemh(INFILE, in_img ,0,FRAME_SIZE-1);
end

// Clock
parameter CLK_PERIOD = 10;	//100MHz
initial begin
	clk = 1'b0;
	forever #(CLK_PERIOD/2) clk = ~clk;
end

// Test cases
initial begin
	rstn = 1'b0;			// Reset, low active
	vld_i = 1'b0;
	win[0] = 0;
	win[1] = 0;
	win[2] = 0;
	win[3] = 0;
	din = 0;
	is_conv3x3 = 1'b0;
	is_last_layer = 1'b0;
	scale[0] = 16'd95;
	scale[1] = 16'd103;
	scale[2] = 16'd364;
	scale[3] = 16'd170;
	bias[0] = 16'd46916;	//-18620
	bias[1] = 16'd8066;		//  8060
	bias[2] = 16'd370;		//   370
	bias[3] = 16'd65030;	//  -506	
	bias_shift = 9;
	act_shift = 7;
	#(4*CLK_PERIOD) rstn = 1'b1;

	// First layer, channel 00:
	win[0][0*WI+:WI] = 8'd142;
	win[0][1*WI+:WI] = 8'd151;
	win[0][2*WI+:WI] = 8'd215;
	win[0][3*WI+:WI] = 8'd127;
	win[0][4*WI+:WI] = 8'd163;
	win[0][5*WI+:WI] = 8'd205;
	win[0][6*WI+:WI] = 8'd229;
	win[0][7*WI+:WI] = 8'd255;
	win[0][8*WI+:WI] = 8'd113;
	
	// First layer, channel 01:
	win[1][0*WI+:WI] = 8'd69;
	win[1][1*WI+:WI] = 8'd181;
	win[1][2*WI+:WI] = 8'd209;
	win[1][3*WI+:WI] = 8'd19;
	win[1][4*WI+:WI] = 8'd128;
	win[1][5*WI+:WI] = 8'd95;
	win[1][6*WI+:WI] = 8'd221;
	win[1][7*WI+:WI] = 8'd121;
	win[1][8*WI+:WI] = 8'd8;

	// First layer, channel 02:
	win[2][0*WI+:WI] = 8'd13;
	win[2][1*WI+:WI] = 8'd244;
	win[2][2*WI+:WI] = 8'd255;
	win[2][3*WI+:WI] = 8'd241;
	win[2][4*WI+:WI] = 8'd127;
	win[2][5*WI+:WI] = 8'd240;
	win[2][6*WI+:WI] = 8'd252;
	win[2][7*WI+:WI] = 8'd237;
	win[2][8*WI+:WI] = 8'd1;

	// First layer, channel 03:
	win[3][0*WI+:WI] = 8'd69;
	win[3][1*WI+:WI] = 8'd135;
	win[3][2*WI+:WI] = 8'd235;
	win[3][3*WI+:WI] = 8'd128;
	win[3][4*WI+:WI] = 8'd32;
	win[3][5*WI+:WI] = 8'd90;
	win[3][6*WI+:WI] = 8'd48;
	win[3][7*WI+:WI] = 8'd52;
	win[3][8*WI+:WI] = 8'd211;	
	row = 0;
	col = 0;
	// Test case 1: test conv1x1
	is_conv3x3 = 1'b0;
	#(START_UP_DELAY*CLK_PERIOD)

	for(row = 0; row < HEIGHT; row = row + 1) begin
		for(col = 0; col < WIDTH; col = col + 1) begin			
				if (row == 0) begin
					if(col == 0) begin
						@(posedge clk) 		vld_i = 1'b1;
						/* Insert your code*/
						din[0*WI+:WI] = 8'd0;
						din[1*WI+:WI] = 8'd0;
						din[2*WI+:WI] = 8'd0;
						din[3*WI+:WI] = 8'd0;
						din[4*WI+:WI] = in_img[(row)*WIDTH + col];
						din[5*WI+:WI] = in_img[(row)*WIDTH + col + 1];
						din[6*WI+:WI] = 8'd0;
						din[7*WI+:WI] = in_img[(row + 1)*WIDTH + col];
						din[8*WI+:WI] = in_img[(row + 1)*WIDTH + col + 1];
					end
					else if (col == WIDTH-1) begin
						@(posedge clk) 		vld_i = 1'b1;
						/* Insert your code*/
						din[0*WI+:WI] = 8'd0;
						din[1*WI+:WI] = 8'd0;
						din[2*WI+:WI] = 8'd0;
						din[3*WI+:WI] = in_img[(row)*WIDTH + col - 1];
						din[4*WI+:WI] = in_img[(row)*WIDTH + col];
						din[5*WI+:WI] = 8'd0;
						din[6*WI+:WI] = in_img[(row + 1)*WIDTH + col - 1];
						din[7*WI+:WI] = in_img[(row + 1)*WIDTH + col];
						din[8*WI+:WI] = 8'd0;
					end
					else begin
						@(posedge clk) 		vld_i = 1'b1;
						din[0*WI+:WI] = 8'd0/*in_img[(row-1) * WIDTH + col-1]*/;
						din[1*WI+:WI] = 8'd0/*in_img[(row-1) * WIDTH + col  ]*/;
						din[2*WI+:WI] = 8'd0/*in_img[(row-1) * WIDTH + col+1]*/;
						din[3*WI+:WI] = in_img[(row  ) * WIDTH + col-1]		   ;
						din[4*WI+:WI] = in_img[(row  ) * WIDTH + col  ]		   ;
						din[5*WI+:WI] = in_img[(row  ) * WIDTH + col+1]		   ;
						din[6*WI+:WI] = in_img[(row+1) * WIDTH + col-1]		   ;
						din[7*WI+:WI] = in_img[(row+1) * WIDTH + col  ]		   ;
						din[8*WI+:WI] = in_img[(row+1) * WIDTH + col+1]		   ;
					end
				end
				else if (row == HEIGHT-1) begin
					if(col == 0) begin
						@(posedge clk) 		vld_i = 1'b1;
						/* Insert your code*/
						din[0*WI+:WI] = 8'd0;
						din[1*WI+:WI] = in_img[(row-1)*WIDTH + col];
						din[2*WI+:WI] = in_img[(row-1)*WIDTH + col+1];
						din[3*WI+:WI] = 8'd0;
						din[4*WI+:WI] = in_img[(row)*WIDTH + col];
						din[5*WI+:WI] = in_img[(row)*WIDTH + col+1];
						din[6*WI+:WI] = 8'd0;
						din[7*WI+:WI] = 8'd0;
						din[8*WI+:WI] = 8'd0;
					end
					else if (col == WIDTH-1) begin
						@(posedge clk) 		vld_i = 1'b1;
						/* Insert your code*/
						din[0*WI+:WI] = in_img[(row-1)*WIDTH + col-1];
						din[1*WI+:WI] = in_img[(row-1)*WIDTH + col];
						din[2*WI+:WI] = 8'd0;
						din[3*WI+:WI] = in_img[(row)*WIDTH + col-1];
						din[4*WI+:WI] = in_img[(row)*WIDTH + col];
						din[5*WI+:WI] = 8'd0;
						din[6*WI+:WI] = 8'd0;
						din[7*WI+:WI] = 8'd0;
						din[8*WI+:WI] = 8'd0;
					end
					else begin
						@(posedge clk) 		vld_i = 1'b1;
						din[0*WI+:WI] = in_img[(row-1) * WIDTH + col-1]        ;
						din[1*WI+:WI] = in_img[(row-1) * WIDTH + col  ]        ;
						din[2*WI+:WI] = in_img[(row-1) * WIDTH + col+1]        ;
						din[3*WI+:WI] = in_img[(row  ) * WIDTH + col-1]        ;
						din[4*WI+:WI] = in_img[(row  ) * WIDTH + col  ]        ;
						din[5*WI+:WI] = in_img[(row  ) * WIDTH + col+1]        ;
						din[6*WI+:WI] = 8'd0/*in_img[(row+1) * WIDTH + col-1]*/;
						din[7*WI+:WI] = 8'd0/*in_img[(row+1) * WIDTH + col  ]*/;
						din[8*WI+:WI] = 8'd0/*in_img[(row+1) * WIDTH + col+1]*/;
					end
				end
				else begin
					if(col == 0) begin
						@(posedge clk) 		vld_i = 1'b1;
						din[0*WI+:WI] = 8'd0/*in_img[(row-1) * WIDTH + col-1]*/	;
						din[1*WI+:WI] = in_img[(row-1) * WIDTH + col  ]			;
						din[2*WI+:WI] = in_img[(row-1) * WIDTH + col+1]			;
						din[3*WI+:WI] = 8'd0/*in_img[(row  ) * WIDTH + col-1]*/	;
						din[4*WI+:WI] = in_img[(row  ) * WIDTH + col  ]			;
						din[5*WI+:WI] = in_img[(row  ) * WIDTH + col+1]			;
						din[6*WI+:WI] = 8'd0/*in_img[(row+1) * WIDTH + col-1]*/ ;
						din[7*WI+:WI] = in_img[(row+1) * WIDTH + col  ]			;
						din[8*WI+:WI] = in_img[(row+1) * WIDTH + col+1]			;
					end
					else if (col == WIDTH-1) begin
						@(posedge clk) 		vld_i = 1'b1;
						din[0*WI+:WI] = in_img[(row-1) * WIDTH + col-1]			;
						din[1*WI+:WI] = in_img[(row-1) * WIDTH + col  ]			;
						din[2*WI+:WI] = 8'd0/*in_img[(row-1) * WIDTH + col+1]*/	;
						din[3*WI+:WI] = in_img[(row  ) * WIDTH + col-1]			;
						din[4*WI+:WI] = in_img[(row  ) * WIDTH + col  ]			;
						din[5*WI+:WI] = 8'd0/*in_img[(row  ) * WIDTH + col+1]*/	;
						din[6*WI+:WI] = in_img[(row+1) * WIDTH + col-1]			;
						din[7*WI+:WI] = in_img[(row+1) * WIDTH + col  ]			;
						din[8*WI+:WI] = 8'd0/*in_img[(row+1) * WIDTH + col+1]*/	;
					end
					else begin
						@(posedge clk) 		vld_i = 1'b1;
						/* Insert your code*/
						din[0*WI+:WI] = in_img[(row-1)*WIDTH + col-1];
						din[1*WI+:WI] = in_img[(row-1)*WIDTH + col];
						din[2*WI+:WI] = in_img[(row-1)*WIDTH + col+1];
						din[3*WI+:WI] = in_img[(row)*WIDTH + col-1];
						din[4*WI+:WI] = in_img[(row)*WIDTH + col];
						din[5*WI+:WI] = in_img[(row)*WIDTH + col+1];
						din[6*WI+:WI] = in_img[(row+1)*WIDTH + col-1];
						din[7*WI+:WI] = in_img[(row+1)*WIDTH + col];
						din[8*WI+:WI] = in_img[(row+1)*WIDTH + col+1];
					end
				end
			end
		@(posedge clk) 		vld_i = 1'b0;
		#(HSYNC_DELAY*CLK_PERIOD);
	end
end
//}}}
endmodule
