module mac_kern #(
parameter WI = 8, 
parameter N  = 16, 
parameter WN = $clog2(N),
parameter WO = 2*(WI+1) + WN)(
clk,
rstn,
is_conv3x3,			//0: 1x1, 1:3x3
vld_i, 
win, 
din, 
acc_o,
vld_o
);

localparam CONV3x3_DELAY 	= 9;
localparam CONV3x3_DELAY_W 	= 4;	
// Ports
input clk;
input rstn;
input is_conv3x3;			//0: 1x1, 1:3x3
input vld_i; 
input [N*WI-1:0] win; 
input [N*WI-1:0] din; 
output[WO+CONV3x3_DELAY_W:0] acc_o;
output  reg vld_o;

// Incoming signals from MACs
wire[WO-1:0] sub_acc_o;	
wire sub_vld_o;
// Delay signals
reg [WN+1:0] is_conv3x3_d;
reg [CONV3x3_DELAY:0] sub_vld_o_d;
reg [WO+CONV3x3_DELAY_W:0] psum;
reg [3:0] pix_idx;
//-------------------------------------------------
// Component: MAC
//-------------------------------------------------
// DUT
mac u_mac(
./*input 			*/clk(clk),
./*input 			*/rstn(rstn),
./*input 			*/vld_i(vld_i), 
./*input [N*WI-1:0] */win(win), 
./*input [N*WI-1:0] */din(din), 
./*output[WO-1:0] 	*/acc_o(sub_acc_o),
./*output reg 		*/vld_o(sub_vld_o)
);
//-------------------------------------------------
// Accumulation
//-------------------------------------------------
//{{{
always@(posedge clk, negedge rstn) begin
	if(~rstn) begin
		psum <= 0;
	end
	else begin
		if(sub_vld_o) begin
			/* insert your code */
			if(pix_idx == 0)
				psum <= $signed(sub_acc_o);
			else
				psum <= $signed(psum) + $signed(sub_acc_o);
			
		end
	end
end
//}}}

//-------------------------------------------------
//Output and Delay signals
//-------------------------------------------------
//{{{
always@(posedge clk, negedge rstn) begin
	if(~rstn) begin
		is_conv3x3_d <= 0;
		sub_vld_o_d <= 0;
	end
	else begin
		is_conv3x3_d <= {is_conv3x3_d[WN:0],is_conv3x3};
		sub_vld_o_d	 <= {sub_vld_o_d[CONV3x3_DELAY-1:0],sub_vld_o};
	end
end

assign acc_o = $signed(psum);

always@(posedge clk, negedge rstn) begin
	if(~rstn) begin
		vld_o <= 1'b0;
	end
	else begin
		if(~is_conv3x3_d[WN])	// conv1x1
			vld_o <= sub_vld_o;
		else begin				// conv3x3
			/* insert your code */
			if(pix_idx == 8)
				vld_o <= 1'b1;
			else
				vld_o <= 1'b0;
		end			
	end
end

// Counter for CONV3x3
//{{{
always@(posedge clk, negedge rstn) begin
	if(~rstn) begin
        pix_idx <= 0;
    end
	else begin
		if(is_conv3x3_d[WN] && sub_vld_o) begin
			if(pix_idx == 8)
				pix_idx <= 0;
			else
				pix_idx <= pix_idx + 1;			
		end
	end
end
//}}}
endmodule
