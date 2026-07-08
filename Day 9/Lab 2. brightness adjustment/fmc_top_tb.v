`timescale 1ns/1ns

`define INPUTFILENAME		"./img/kodim03.hex"
`define OUTPUTFILENAME		"./out/kodim03.bmp"
`define OUTPUTFILENAME_RCT	"./out/kodim03_ycbcr.bmp"
module fmc_top_tb
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

wire	br_mode;
wire [ IMG_PIX_W-1: 0] br_value;
wire [ IMG_PIX_W-1: 0] br_data_R0;
wire [ IMG_PIX_W-1: 0] br_data_G0;
wire [ IMG_PIX_W-1: 0] br_data_B0;
wire [ IMG_PIX_W-1: 0] br_data_R1;
wire [ IMG_PIX_W-1: 0] br_data_G1;
wire [ IMG_PIX_W-1: 0] br_data_B1;
wire	br_out_valid;

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

/* Insert your code here */
// Dummy 
assign br_mode = 1'b1;
assign br_value = 8'd0;
//{{{
//assign br_mode = ;	//1: brighter, 0: darker
//assign br_value = ;	//amount of adjustment
//}}}
brightness_adjustment 
#(.IMG_PIX_W(IMG_PIX_W),
  .WAVE_PIX_W(WAVE_PIX_W))
        u_brightness_adjustment
(  
    /*input*/ .clk(HCLK),
    /*input*/ .rst_n(HRESETn),
    /*input*/ .in_valid(hsync),
    /*input*/ .mode(br_mode),
    /*input [IMG_PIX_W-1:0]*/ .value(br_value),
    /*input [IMG_PIX_W-1:0]*/ .r0(data_R0), 
    /*input [IMG_PIX_W-1:0]*/ .g0(data_G0),
    /*input [IMG_PIX_W-1:0]*/ .b0(data_B0),
    /*input [IMG_PIX_W-1:0]*/ .r1(data_R1),
    /*input [IMG_PIX_W-1:0]*/ .g1(data_G1),
    /*input [IMG_PIX_W-1:0]*/ .b1(data_B1),
    /*output*/ .out_valid(br_out_valid),
    /*output [IMG_PIX_W-1:0]*/ .out_r0(br_data_R0),
    /*output [IMG_PIX_W-1:0]*/ .out_g0(br_data_G0),
    /*output [IMG_PIX_W-1:0]*/ .out_b0(br_data_B0),
    /*output [IMG_PIX_W-1:0]*/ .out_r1(br_data_R1),
    /*output [IMG_PIX_W-1:0]*/ .out_g1(br_data_G1),
    /*output [IMG_PIX_W-1:0]*/ .out_b1(br_data_B1)
);


/* connect sensor module to display module */
//assign recon_valid = hsync;
//assign recon_data_R0 = data_R0;
//assign recon_data_G0 = data_G0;
//assign recon_data_B0 = data_B0;
//assign recon_data_R1 = data_R1;
//assign recon_data_G1 = data_G1;
//assign recon_data_B1 = data_B1;


/* connect brightness adjustment module to display module*/
assign recon_valid = br_out_valid;
assign recon_data_R0 = br_data_R0;
assign recon_data_G0 = br_data_G0;
assign recon_data_B0 = br_data_B0;
assign recon_data_R1 = br_data_R1;
assign recon_data_G1 = br_data_G1;
assign recon_data_B1 = br_data_B1;

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

