module mac #(
parameter WI = 8, 
parameter N  = 16, 
parameter WN = $clog2(N),
parameter WO = 2*WI + WN)(
input clk,
input rstn,
input vld_i, 
input [N*WI-1:0] win, 
input [N*WI-1:0] din, 
output[WO+1:0] acc_o,
output  vld_o
);

reg [WN:0] vld_d;
wire[2*WI+1:0] y0[0:N-1];	// 16 outputs of multipliers
reg [2*WI+2:0] y1[0:N/2-1];	// 8  outputs of adders (level 1)
reg [2*WI+3:0] y2[0:N/4-1];	// 4  outputs of adders (level 2)
reg [2*WI+4:0] y3[0:N/8-1];	// 2  outputs of adders (level 3)
reg [2*WI+5:0] y4         ;	// 1  output  of adders (level 4)

reg [N*(WI+1)-1:0] weight;
reg [N*(WI+1)-1:0] activation;

integer i;
//-------------------------------------------------
// Components: Array of multipliers
//-------------------------------------------------
always@(posedge clk, negedge rstn) begin
	if(~rstn) begin
		weight 		<= 0;
		activation 	<= 0;
	end
	else begin
		for(i = 0; i < N; i=i+1) begin
			weight[i*(WI+1)+:(WI+1)] 		<= $signed($signed({win[( i*WI)+:WI],1'b0})+1);
			activation[i*(WI+1)+:(WI+1)] 	<= $signed({1'b0,din[ i*WI+:WI]});
		end		
	end
end
mul #(.WI(WI+1)) u_mul_00(.w(weight[( 0*(WI+1))+:(WI+1)]),.x(activation[( 0*(WI+1))+:(WI+1)]),.y(y0[ 0]));
mul #(.WI(WI+1)) u_mul_01(.w(weight[( 1*(WI+1))+:(WI+1)]),.x(activation[( 1*(WI+1))+:(WI+1)]),.y(y0[ 1]));
mul #(.WI(WI+1)) u_mul_02(.w(weight[( 2*(WI+1))+:(WI+1)]),.x(activation[( 2*(WI+1))+:(WI+1)]),.y(y0[ 2]));
mul #(.WI(WI+1)) u_mul_03(.w(weight[( 3*(WI+1))+:(WI+1)]),.x(activation[( 3*(WI+1))+:(WI+1)]),.y(y0[ 3]));
mul #(.WI(WI+1)) u_mul_04(.w(weight[( 4*(WI+1))+:(WI+1)]),.x(activation[( 4*(WI+1))+:(WI+1)]),.y(y0[ 4]));
mul #(.WI(WI+1)) u_mul_05(.w(weight[( 5*(WI+1))+:(WI+1)]),.x(activation[( 5*(WI+1))+:(WI+1)]),.y(y0[ 5]));
mul #(.WI(WI+1)) u_mul_06(.w(weight[( 6*(WI+1))+:(WI+1)]),.x(activation[( 6*(WI+1))+:(WI+1)]),.y(y0[ 6]));
mul #(.WI(WI+1)) u_mul_07(.w(weight[( 7*(WI+1))+:(WI+1)]),.x(activation[( 7*(WI+1))+:(WI+1)]),.y(y0[ 7]));
mul #(.WI(WI+1)) u_mul_08(.w(weight[( 8*(WI+1))+:(WI+1)]),.x(activation[( 8*(WI+1))+:(WI+1)]),.y(y0[ 8]));
mul #(.WI(WI+1)) u_mul_09(.w(weight[( 9*(WI+1))+:(WI+1)]),.x(activation[( 9*(WI+1))+:(WI+1)]),.y(y0[ 9]));
mul #(.WI(WI+1)) u_mul_10(.w(weight[(10*(WI+1))+:(WI+1)]),.x(activation[(10*(WI+1))+:(WI+1)]),.y(y0[10]));
mul #(.WI(WI+1)) u_mul_11(.w(weight[(11*(WI+1))+:(WI+1)]),.x(activation[(11*(WI+1))+:(WI+1)]),.y(y0[11]));
mul #(.WI(WI+1)) u_mul_12(.w(weight[(12*(WI+1))+:(WI+1)]),.x(activation[(12*(WI+1))+:(WI+1)]),.y(y0[12]));
mul #(.WI(WI+1)) u_mul_13(.w(weight[(13*(WI+1))+:(WI+1)]),.x(activation[(13*(WI+1))+:(WI+1)]),.y(y0[13]));
/* insert your code */
mul #(.WI(WI+1)) u_mul_14(.w(weight[(14*(WI+1))+:(WI+1)]),.x(activation[(14*(WI+1))+:(WI+1)]),.y(y0[14]));
mul #(.WI(WI+1)) u_mul_15(.w(weight[(15*(WI+1))+:(WI+1)]),.x(activation[(15*(WI+1))+:(WI+1)]),.y(y0[15]));

//-------------------------------------------------
// Hierarchical Adder
//-------------------------------------------------

always@(posedge clk, negedge rstn) begin
	if(~rstn) begin
		for(i = 0; i < N/2; i=i+1) begin
			y1[i] <= 0;
		end
		for( i = 0; i < N/4; i=i+1) begin
			y2[i] <= 0;
		end
		for( i = 0; i < N/8; i=i+1) begin
			y3[i] <= 0;
		end
		y4 <=0;
	end
	else begin
		// Level 1
		y1[0] <= $signed(y0[ 0]) + $signed(y0[ 1]);
		y1[1] <= $signed(y0[ 2]) + $signed(y0[ 3]);
		y1[2] <= $signed(y0[ 4]) + $signed(y0[ 5]);
		y1[3] <= $signed(y0[ 6]) + $signed(y0[ 7]);
		y1[4] <= $signed(y0[ 8]) + $signed(y0[ 9]);
		y1[5] <= $signed(y0[10]) + $signed(y0[11]);
		y1[6] <= $signed(y0[12]) + $signed(y0[13]);
		y1[7] <= $signed(y0[14]) + $signed(y0[15]);
		// Level 2
		y2[0] <= $signed(y1[0]) + $signed(y1[ 1]);
		y2[1] <= $signed(y1[2]) + $signed(y1[ 3]);
		y2[2] <= $signed(y1[4]) + $signed(y1[ 5]);
		y2[3] <= $signed(y1[6]) + $signed(y1[ 7]);
		/* insert your code */
		// Level 3
		y3[0] <= $signed(y2[0]) + $signed(y2[ 1]);
		y3[1] <= $signed(y2[2]) + $signed(y2[ 3]);

		// Level 4
		/* insert your code */
		y4    <= $signed(y3[0]) + $signed(y3[ 1]);
	end
end

//-------------------------------------------------
//Output and Delay signals
//-------------------------------------------------
always@(posedge clk, negedge rstn) begin
	if(~rstn) begin
		vld_d <= 0;
	end
	else begin
		/* insert your code */
		vld_d <= {vld_d[WN-1:0],vld_i};

	end
end
assign vld_o = vld_d[WN];
assign acc_o = $signed(y4);

endmodule
