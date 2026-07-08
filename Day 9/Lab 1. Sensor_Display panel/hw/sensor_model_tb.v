`timescale 1ns/1ns

`define INPUTFILENAME		"./img/kodim03.hex"
`define OUTPUTFILENAME		"./out/kodim03.bmp"
`define OUTPUTFILENAME_RCT		"./out/kodim03_ycbcr.bmp"
module sensor_model_tb
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

