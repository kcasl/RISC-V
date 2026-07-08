`timescale 1ns/1ns

`define INPUTFILENAME		"./img/kodim03.hex"
`define OUTPUTFILENAME		"./out/kodim03.bmp"
`define OUTPUTFILENAME_RCT	"./out/kodim03_ycbcr.bmp"
module fmc_rct_top_tb
#(
    parameter  IMG_PIX_W  =  8,
               WAVE_PIX_W = 10,
               SIZE       = 64
);

//-------------------------------------------------
// Internal Signals
//-------------------------------------------------
//{{{
reg HCLK, HRESETn;
wire          vsync;
wire          hsync;
//reg           hsync_d;
wire [ IMG_PIX_W-1: 0] data_R0;
wire [ IMG_PIX_W-1: 0] data_G0;
wire [ IMG_PIX_W-1: 0] data_B0;
wire [ IMG_PIX_W-1: 0] data_R1;
wire [ IMG_PIX_W-1: 0] data_G1;
wire [ IMG_PIX_W-1: 0] data_B1;

wire 					rct_o_valid;
wire [WAVE_PIX_W-1 : 0] rct_dout_y0;
wire [WAVE_PIX_W-1 : 0] rct_dout_y1;
wire [WAVE_PIX_W-1 : 0] rct_dout_cb;
wire [WAVE_PIX_W-1 : 0] rct_dout_cr;

wire [IMG_PIX_W-1 : 0] recon_data_R0;  
wire [IMG_PIX_W-1 : 0] recon_data_G0; 
wire [IMG_PIX_W-1 : 0] recon_data_B0; 
wire [IMG_PIX_W-1 : 0] recon_data_R1; 
wire [IMG_PIX_W-1 : 0] recon_data_G1; 
wire [IMG_PIX_W-1 : 0] recon_data_B1; 

wire recon_valid;

//wire [31 : 0] out_spiht;
//wire 		  mem_enable;
//wire 		  mem_rwmode;
//wire          out_enable;
//wire          enc_done;
//wire          dec_done;
//wire [31 : 0] ram_out;
//wire [16:0] mem_addr;
//wire recon_valid;
//wire [1:0] comp_ratio = `COMP_RATIO;
//-------------------------------------------------
// Components
//-------------------------------------------------

sensor_model 
#(.INFILE(`INPUTFILENAME))
	u_sensor_model 
( //{{{
    .HCLK	                (HCLK    ),
    .HRESETn	            (HRESETn ),
    .VSYNC	                (vsync   ),
    .HSYNC	                (hsync   ),
    .DATA_R0	            (data_R0 ),
    .DATA_G0	            (data_G0 ),
    .DATA_B0	            (data_B0 ),
    .DATA_R1	            (data_R1 ),
    .DATA_G1	            (data_G1 ),
    .DATA_B1	            (data_B1 ),
	.ctrl_done				(enc_done)
); //}}}

//{{{
forward_rct u_forward_rct ( //{{{ 
    /* input*/.clk           (HCLK       ),
    /* input*/.rst_n       	 (HRESETn    ),
    /* input*/.in_valid      (hsync      ),
    /* input*/.r0            (data_R0    ),
    /* input*/.g0            (data_G0    ),
    /* input*/.b0            (data_B0    ), 
    /* input*/.r1            (data_R1    ), 
    /* input*/.g1            (data_G1    ),
    /* input*/.b1            (data_B1    ), 
    /*output*/.out_valid     (rct_o_valid),
    /*output*/.y0            (rct_dout_y0),
    /*output*/.y1            (rct_dout_y1), 
    /*output*/.cb0           (rct_dout_cb),
    /*output*/.cr0           (rct_dout_cr)
); //}}}

inverse_rct u_inverse_rct 
(
    ./*input */clk(HCLK),
    ./*input */rst_n(HRESETn),
    ./*input */in_valid(rct_o_valid),
    ./*input signed [WAVE_PIX_W-1:0] */y0 (rct_dout_y0),
	./*input signed [WAVE_PIX_W-1:0] */cb0(rct_dout_cb),
	./*input signed [WAVE_PIX_W-1:0] */cr0(rct_dout_cr), 
    ./*input signed [WAVE_PIX_W-1:0] */y1 (rct_dout_y1),
	./*input signed [WAVE_PIX_W-1:0] */cb1(rct_dout_cb),
	./*input signed [WAVE_PIX_W-1:0] */cr1(rct_dout_cr), 
    ./*output reg */out_valid(recon_valid),
    ./*output [IMG_PIX_W-1:0] */r0(recon_data_R0),
	./*output [IMG_PIX_W-1:0] */g0(recon_data_G0),
	./*output [IMG_PIX_W-1:0] */b0(recon_data_B0),
    ./*output [IMG_PIX_W-1:0] */r1(recon_data_R1),
	./*output [IMG_PIX_W-1:0] */g1(recon_data_G1),
	./*output [IMG_PIX_W-1:0] */b1(recon_data_B1)
);

//assign recon_valid = hsync;
//assign recon_data_R0 = data_R0;
//assign recon_data_G0 = data_G0;
//assign recon_data_B0 = data_B0;
//assign recon_data_R1 = data_R1;
//assign recon_data_G1 = data_G1;
//assign recon_data_B1 = data_B1;
display_model 
#(.INFILE(`OUTPUTFILENAME))
	u_display_model
(
	./*input */HCLK(HCLK),
	./*input */HRESETn(HRESETn),
	./*input */RECON_VALID(recon_valid),
    ./*input [7:0]  */DATA_RECON_R0(recon_data_R0),
    ./*input [7:0]  */DATA_RECON_G0(recon_data_G0),
    ./*input [7:0]  */DATA_RECON_B0(recon_data_B0),
    ./*input [7:0]  */DATA_RECON_R1(recon_data_R1),
    ./*input [7:0]  */DATA_RECON_G1(recon_data_G1),
    ./*input [7:0]  */DATA_RECON_B1(recon_data_B1),
	./*output 		*/DEC_DONE()
);	
display_model 
#(.INFILE(`OUTPUTFILENAME_RCT))
  u_display_model_2
(
  ./*input */HCLK(HCLK),
  ./*input */HRESETn(HRESETn),
  ./*input */RECON_VALID(rct_o_valid),
    ./*input [7:0]  */DATA_RECON_R0(rct_dout_y0),
    ./*input [7:0]  */DATA_RECON_G0(rct_dout_cb),
    ./*input [7:0]  */DATA_RECON_B0(rct_dout_cr),
    ./*input [7:0]  */DATA_RECON_R1(rct_dout_y1),
    ./*input [7:0]  */DATA_RECON_G1(rct_dout_cb),
    ./*input [7:0]  */DATA_RECON_B1(rct_dout_cr),
  ./*output 		*/DEC_DONE()
);	
//}}}

//-------------------------------------------------
// Test Vectors
//-------------------------------------------------
//{{{
initial begin 
    HCLK = 0;
    forever #10 HCLK = ~HCLK;
end

initial begin
    HRESETn     = 0;
    #25 HRESETn = 1;
end
//}}}

endmodule

