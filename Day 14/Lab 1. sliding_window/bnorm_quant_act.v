module bnorm_quant_act(
    clk,
    resetn,
    is_last_layer,
    scale,
    bias,
    act_shift,
    bias_shift,
    accum_in,
    accum_vld_in,
    accum_out,
    accum_vld_out
    );

// Parameter declarations
	parameter PARAM_BITS 	= 16;
	parameter WEIGHT_BITS 	= 8;
	parameter ACT_BITS		= 8;
	parameter DATA_BITS 	= 27;
	localparam N_DELAY = 4;
// Port declarations
    input clk;
    input resetn;
    input is_last_layer;
    input [PARAM_BITS-1:0] scale;
    input [PARAM_BITS-1:0] bias;
    input [2:0] act_shift;
    input [4:0] bias_shift;
    input [DATA_BITS-1:0] accum_in;
    input accum_vld_in;
    output [ACT_BITS-1:0] accum_out;
    output accum_vld_out;

// Internel port declarations
    reg [N_DELAY-1:0] accum_vld;

    reg [2:0] act_shift_r;
    reg [4:0] bias_shift_r;

    reg [PARAM_BITS-1:0] scale_r;
    reg [PARAM_BITS-1:0] bias_r;

    reg [DATA_BITS-1:0] accum_in_r;

    reg [DATA_BITS+PARAM_BITS-1:0] acc_mult;
    wire [DATA_BITS-1:0] acc_mult_shift; 
    wire [DATA_BITS-1:0] acc_mean_shift; 
    reg [DATA_BITS-1:0] acc_mean;
    wire signed [DATA_BITS-1:0] acc_quant;   
    wire signed [DATA_BITS-1:0] acc_relu;
    reg signed [ACT_BITS-1:0] accum_relu;
    reg [ACT_BITS-1:0] accum_final;

//-------------------------------------------------
// Batch normalization
//-------------------------------------------------
    always @(posedge clk)
    begin
        accum_in_r <= accum_in;
        act_shift_r <= act_shift;
        bias_shift_r <= bias_shift;
        scale_r <= scale;
        bias_r <= bias;
    end
    
    always @(posedge clk)
    begin
        acc_mult <= $signed(accum_in_r) * $signed(scale_r);
    end
   
//-------------------------------------------------
// Bias shift
//-------------------------------------------------
    bias_shifter #(
        .DATA_BITS (DATA_BITS+PARAM_BITS),
        .SHIFT_W (5)
    )
    u_bias_shift (
        .d_in (acc_mult),
        .n_shift (bias_shift_r),
        .d_out (acc_mult_shift)
    );

    always @(posedge clk) begin
        acc_mean <= $signed(acc_mult_shift) + $signed(bias_r);
    end

//-------------------------------------------------
// Activation Shift
//-------------------------------------------------
    act_shifter #(
        .DATA_BITS (DATA_BITS),
        .SHIFT_W (3)
    )
    u_act_shift (
        .d_in (acc_mean),
        .n_shift(act_shift_r),
        .d_out (acc_mean_shift)
    );

   // RELU
   assign acc_relu = $signed(~acc_mean_shift[DATA_BITS-1] ? acc_mean_shift : 'h0);   
   assign acc_quant = (~is_last_layer) ? acc_relu :acc_mean_shift; //linear    
   always @(posedge clk or negedge resetn)
     if(!resetn)  
		accum_relu <= 'h0;
    else begin
		// Clipping
		accum_relu <= (acc_quant > 255) ? 255 : acc_quant[ACT_BITS-1:0];
	end
											   
    // Linear (Last Layer)
    always @(posedge clk or negedge resetn)
        if(!resetn) accum_final <= 'h0;
        else        accum_final <= acc_quant;
//-------------------------------------------------
// Delays and valid signals	
//-------------------------------------------------    
    assign accum_out = is_last_layer ? accum_final : accum_relu;    
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn) accum_vld <= 'h0;
        else        accum_vld <= {accum_vld[N_DELAY-2:0], accum_vld_in};
    end 
    assign accum_vld_out = accum_vld[N_DELAY-1];

endmodule
