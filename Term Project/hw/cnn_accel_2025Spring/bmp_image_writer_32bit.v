`timescale 1ns/1ps

//---------------------------------------------------------------
// [MODIFIED / NEW] Term Project 2026 Summer - Problem 1-3
// 32-bit BMP writer for sub-pixel (ESPCN) high-resolution output.
// Each valid beat provides 4 residual/HR pixels packed as:
//   din[ 7: 0] = ch0 -> HR (2*row  , 2*col  )
//   din[15: 8] = ch1 -> HR (2*row  , 2*col+1)
//   din[23:16] = ch2 -> HR (2*row+1, 2*col  )
//   din[31:24] = ch3 -> HR (2*row+1, 2*col+1)
// Input LR size is WIDTH x HEIGHT; output HR BMP is (2*WIDTH) x (2*HEIGHT).
//---------------------------------------------------------------
module bmp_image_writer_32bit
#(parameter WI = 32,
parameter BMP_HEADER_NUM = 54,
parameter WIDTH 	= 128,		// Low-resolution width
parameter HEIGHT 	= 128,		// Low-resolution height
parameter OUTFILE   = "./out/convout_hr.bmp")(
	input clk,
	input rstn,
	input [WI-1:0] din,
	input vld,
	output reg frame_done
);

// HR image parameters (2x upscale)
localparam HR_WIDTH  = WIDTH * 2;
localparam HR_HEIGHT = HEIGHT * 2;
localparam FRAME_SIZE_LR = WIDTH * HEIGHT;
localparam FRAME_SIZE_HR = HR_WIDTH * HR_HEIGHT;
localparam FRAME_SIZE_LR_W = $clog2(FRAME_SIZE_LR);
localparam FRAME_SIZE_HR_W = $clog2(FRAME_SIZE_HR);

reg [7:0] out_img[0:FRAME_SIZE_HR-1];
reg [FRAME_SIZE_LR_W-1:0] pixel_count;	// counts LR pixels received
reg [31:0] IW;
reg [31:0] IH;
reg [31:0] SZ;
reg [7:0] BMP_header [0 : BMP_HEADER_NUM - 1];
integer k;
integer fd;
integer i;
integer h, w;
integer row_lr, col_lr;
integer addr00, addr01, addr10, addr11;

//-------------------------------------------------
// Update the internal HR buffer (sub-pixel rearrange)
//-------------------------------------------------
always@(posedge clk, negedge rstn) begin
    if(!rstn) begin
        for(k=0;k<FRAME_SIZE_HR;k=k+1) begin
            out_img[k] <= 0;
        end
		pixel_count <= 0;
		frame_done <= 1'b0;
    end else begin
        if(vld) begin
			row_lr = pixel_count / WIDTH;
			col_lr = pixel_count % WIDTH;
			// flatten_sres channel placement
			addr00 = (2*row_lr    )*HR_WIDTH + (2*col_lr    );	// ch0
			addr01 = (2*row_lr    )*HR_WIDTH + (2*col_lr + 1);	// ch1
			addr10 = (2*row_lr + 1)*HR_WIDTH + (2*col_lr    );	// ch2
			addr11 = (2*row_lr + 1)*HR_WIDTH + (2*col_lr + 1);	// ch3

            out_img[addr00] <= din[ 7: 0];
            out_img[addr01] <= din[15: 8];
            out_img[addr10] <= din[23:16];
            out_img[addr11] <= din[31:24];

			if(pixel_count == FRAME_SIZE_LR-1) begin
				pixel_count <= 0;
				frame_done <= 1'b1;
			end
			else begin
				pixel_count <= pixel_count + 1;
			end
        end
    end
end

//-------------------------------------------------
// BMP header for HR image
//-------------------------------------------------
initial begin
	IW = HR_WIDTH;
	IH = HR_HEIGHT;
	SZ = FRAME_SIZE_HR * 3 + BMP_HEADER_NUM;	// 24-bit BMP
	BMP_header[ 0] = 66;
	BMP_header[ 1] = 77;
	BMP_header[ 2] = ((SZ & 32'h000000ff) >>  0);
	BMP_header[ 3] = ((SZ & 32'h0000ff00) >>  8);
	BMP_header[ 4] = ((SZ & 32'h00ff0000) >> 16);
	BMP_header[ 5] = ((SZ & 32'hff000000) >> 24);
	BMP_header[ 6] =  0;
	BMP_header[ 7] =  0;
	BMP_header[ 8] =  0;
	BMP_header[ 9] =  0;
	BMP_header[10] = 54;
	BMP_header[11] =  0;
	BMP_header[12] =  0;
	BMP_header[13] =  0;
	BMP_header[14] = 40;
	BMP_header[15] =  0;
	BMP_header[16] =  0;
	BMP_header[17] =  0;
	BMP_header[18] =  ((IW & 32'h000000ff) >>  0);
	BMP_header[19] =  ((IW & 32'h0000ff00) >>  8);
	BMP_header[20] =  ((IW & 32'h00ff0000) >> 16);
	BMP_header[21] =  ((IW & 32'hff000000) >> 24);
	BMP_header[22] =  ((IH & 32'h000000ff) >>  0);
	BMP_header[23] =  ((IH & 32'h0000ff00) >>  8);
	BMP_header[24] =  ((IH & 32'h00ff0000) >> 16);
	BMP_header[25] =  ((IH & 32'hff000000) >> 24);
	BMP_header[26] =  1;
	BMP_header[27] =  0;
	BMP_header[28] = 24;
	BMP_header[29] =  0;
	BMP_header[30] =  0;
	BMP_header[31] =  0;
	BMP_header[32] =  0;
	BMP_header[33] =  0;
	BMP_header[34] =  0;
	BMP_header[35] =  0;
	BMP_header[36] =  0;
	BMP_header[37] =  0;
	BMP_header[38] =  0;
	BMP_header[39] =  0;
	BMP_header[40] =  0;
	BMP_header[41] =  0;
	BMP_header[42] =  0;
	BMP_header[43] =  0;
	BMP_header[44] =  0;
	BMP_header[45] =  0;
	BMP_header[46] =  0;
	BMP_header[47] =  0;
	BMP_header[48] =  0;
	BMP_header[49] =  0;
	BMP_header[50] =  0;
	BMP_header[51] =  0;
	BMP_header[52] =  0;
	BMP_header[53] =  0;
end

initial begin
    fd = $fopen(OUTFILE, "wb+");
	h = 0;
	w = 0;
end

always@(frame_done) begin
    if(frame_done == 1'b1) begin
        for(i=0; i<BMP_HEADER_NUM; i=i+1) begin
            $fwrite(fd, "%c", BMP_header[i][7:0]);
        end
		for(h = 0; h < HR_HEIGHT; h = h + 1) begin
			for(w = 0; w < HR_WIDTH; w = w + 1) begin
				$fwrite(fd, "%c", out_img[(HR_HEIGHT-1-h)*HR_WIDTH + w][7:0]);
				$fwrite(fd, "%c", out_img[(HR_HEIGHT-1-h)*HR_WIDTH + w][7:0]);
				$fwrite(fd, "%c", out_img[(HR_HEIGHT-1-h)*HR_WIDTH + w][7:0]);
			end
		end
		$fclose(fd);
    end
end
endmodule
