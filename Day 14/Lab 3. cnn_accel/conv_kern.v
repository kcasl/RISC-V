module conv_kern(
clk,
rstn,
is_last_layer,
scale,
bias,
act_shift,
bias_shift,
is_conv3x3,			//0: 1x1, 1:3x3
vld_i, 
win, 
din, 
acc_o,
vld_o
);
parameter WI = 8;
parameter N  = 16; 
parameter WN = $clog2(N);
parameter WO = 2*(WI+1) + WN;
parameter PARAM_BITS 	= 16;
parameter WEIGHT_BITS 	= 8;
parameter ACT_BITS		= 8;

localparam CONV3x3_DELAY 	= 9;
localparam CONV3x3_DELAY_W 	= 4;	
parameter DATA_BITS 	= WO + CONV3x3_DELAY_W+1;
// Ports
input clk;
input rstn;
input is_last_layer;
input [PARAM_BITS-1:0] scale;
input [PARAM_BITS-1:0] bias;
input [2:0] act_shift;
input [4:0] bias_shift;
input is_conv3x3;			//0: 1x1, 1:3x3
input vld_i; 
input [N*WI-1:0] win; 
input [N*WI-1:0] din; 
output [ACT_BITS-1:0] acc_o;
output vld_o;

// Incoming signals from MACs
wire[DATA_BITS-1:0]  mac_kern_acc_o;
wire  				mac_kern_acc_vld_o;
//-------------------------------------------------
// Component: MAC
//-------------------------------------------------
// DUT
mac_kern u_mac_kern(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input 			*/is_conv3x3(is_conv3x3),
./*input 			*/vld_i(vld_i), 
./*input [N*WI-1:0] */win(win), 
./*input [N*WI-1:0] */din(din), 
./*output[WO-1:0] 	*/acc_o(mac_kern_acc_o),
./*output reg 		*/vld_o(mac_kern_acc_vld_o)
);
//-------------------------------------------------
// Component: Batch-normalization, Activation quantization
//-------------------------------------------------
bnorm_quant_act #(.DATA_BITS(DATA_BITS))
u_bnorm_quant_act
(
./*input 				 */clk(clk),
./*input 				 */resetn(rstn),
./*input 				 */is_last_layer(is_last_layer),
./*input [PARAM_BITS-1:0]*/scale(scale),
./*input [PARAM_BITS-1:0]*/bias(bias),
./*input [2:0] 			 */act_shift(act_shift),
./*input [4:0] 			 */bias_shift(bias_shift),
./*input [DATA_BITS-1:0] */accum_in(mac_kern_acc_o),
./*input 				 */accum_vld_in(mac_kern_acc_vld_o),
./*output [ACT_BITS-1:0] */accum_out(acc_o),
./*output 				 */accum_vld_out(vld_o)
);
endmodule
